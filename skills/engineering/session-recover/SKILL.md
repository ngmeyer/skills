---
name: session-recover
description: >
  Recover lost Claude Code session context by merging duplicate project
  directories. Finds session/memory dirs under ~/.claude/projects/ that
  point at the same logical project from different cwd-encoded paths
  (e.g. /mnt/work/foo vs ~/Projects/foo cwd produces two separate
  namespaces). Unifies memory into the canonical dir, archives orphaned
  jsonl transcripts, and captures the lesson as a feedback memory so
  the split doesn't repeat. Use when: 'merge sessions', 'recover lost
  context', 'fix duplicate session dirs', 'session memory split',
  'memory dir is empty but I added things', 'two project dirs',
  'recover legacy memories from before a folder move', 'stale orphan
  memory namespace', or any time you find a populated memory dir at the
  "wrong" path and an empty one at the canonical path.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob"]
argument-hint: "[optional: project name token, e.g. 'myapp' or 'api' — used to grep for candidate dup dirs]"
---

# /session-recover — Manually merge duplicate Claude Code project directories

Claude Code stores per-project session transcripts and persistent memory under `~/.claude/projects/{encoded-cwd}/`. The encoded cwd is the absolute path with every non-alphanumeric character replaced by `-`. Two different cwd paths that point at the same logical project (a real directory + its symlink mirror, an external-mount path + a `~/Projects/` shortcut, a Linux user moving from `/home/me` to `/Users/me`, etc.) produce **two completely separate namespaces** — separate session lists in `/resume`, separate memory dirs, no cross-visibility.

This skill cleans that up: detect the duplicates, unify the memory into the canonical location, archive the orphan transcripts, and capture the lesson so future sessions don't re-create the split.

## When this skill applies

- You opened a session and the memory dir is empty, but you remember adding entries in past sessions
- `claude --resume` shows fewer sessions than you expect
- You find two `~/.claude/projects/-*-foo/` directories whose trailing tokens match
- Cross-session memory references in conversation don't resolve (`[[some-memory]]` links to nothing)
- A grep for the project name across `~/.claude/projects/` returns multiple matches

If none of the above hold, the skill has nothing to do — exit early and tell the user.

## Core principle

**The canonical path is the one Claude Code's current system prompt tells you it is.** When the harness starts a session it announces:
> You have a persistent, file-based memory system at `/Users/me/.claude/projects/{ENCODED}/memory/`

That's the **winner**. Everything else with a similar trailing token is a **loser candidate**. The user can override if they actually want a different path canonical, but default to what the harness chose.

## Procedure

### Phase 1 — IDENTIFY: find duplicate project dirs

Use the optional argument as a project-name token. If omitted, infer from cwd's trailing component (`basename "$PWD"`) or the conversation.

```bash
bash ~/.claude/skills/session-recover/scripts/inventory.sh <project-token>
```

The script lists every `~/.claude/projects/*<token>*/` directory with:
- jsonl session file count + total size + newest-file mtime
- memory dir entry count
- whether the encoded path appears to be Lexar (`Volumes-Lexar`), home-Projects (`Users-.*-Projects`), or something else

Stop and ask the user if:
- Only one match exists → no duplicates → exit
- Three or more matches exist → confirm which is canonical before proceeding
- The candidates have wildly different jsonl mtimes (e.g. one was active last week, another was active today) → confirm the user wants both folded together

### Phase 2 — IDENTIFY: pick the winner

Default: the path mentioned in the current session's system prompt under "persistent, file-based memory system at …".

If that path isn't a duplicate-dir candidate (e.g. user is invoking this skill from outside the project), ask the user which one they want canonical. Usually it's the path they actually `cd` into when starting work, or the path called out as "canonical" in any project-level CLAUDE.md.

### Phase 3 — MERGE memory

For each **loser**, move its memory contents into the winner. **Always `mv`, never `cp`**, so the loser's memory dir empties out and stops being a competing source of truth.

```bash
WINNER=~/.claude/projects/<canonical-encoded-path>
LOSER=~/.claude/projects/<loser-encoded-path>

mkdir -p "$WINNER/memory"
mv "$LOSER/memory/"* "$WINNER/memory/" 2>/dev/null
rmdir "$LOSER/memory" 2>/dev/null
```

**Conflict handling:** if both sides have a file with the same name (most commonly `MEMORY.md`), do **not** clobber. Read both, write a unified version into the winner by hand, delete the loser's copy after. This usually only affects `MEMORY.md` (the index file).

### Phase 4 — ARCHIVE jsonl transcripts

Move the loser's jsonl session files and any per-session subdirs to `~/.claude/archive/`. **Don't `rm`** — archive is reversible, deletion isn't.

```bash
ARCHIVE_DIR=~/.claude/archive/$(basename "$LOSER")
mkdir -p "$ARCHIVE_DIR"
mv "$LOSER"/*.jsonl "$ARCHIVE_DIR/" 2>/dev/null
# Also archive any UUID subdirs (per-session checkpoint dirs)
for d in "$LOSER"/[0-9a-f]*-[0-9a-f]*/; do
    [ -d "$d" ] && mv "$d" "$ARCHIVE_DIR/"
done
rmdir "$LOSER" 2>/dev/null
```

If `rmdir "$LOSER"` fails because the directory isn't empty, list what's still there and ask the user — there's usually a stray file (`.DS_Store`, a non-standard subdir) that needs explicit handling.

### Phase 5 — CAPTURE the lesson as memory

Write a `feedback`-type memory entry into the winner's memory dir so a future session knows the dual-cwd hazard exists for this project:

```markdown
---
name: dual-cwd-memory-split-{project}
description: Memory dir is path-derived from cwd. Two cwd paths for the same project produced separate memory namespaces; merged YYYY-MM-DD.
metadata:
  type: feedback
---

The {project} project is reachable via:
- `{canonical-cwd-path}` — canonical
- `{loser-cwd-path}` — symlink/mirror/alias

These produce separate `~/.claude/projects/-*/` namespaces. Memory was merged into the canonical path on YYYY-MM-DD; jsonl transcripts archived to `~/.claude/archive/{loser-encoded}/`.

**How to apply:** always `cd` into `{canonical-cwd-path}` before `claude`. If a future session lands at the other path and finds an empty memory dir, re-run /session-recover before doing real work.
```

Then add a one-line pointer to `MEMORY.md` in the winner's memory dir:
```
- [Dual-cwd memory split](feedback_dual_cwd_memory_split_{project}.md) — memory namespaces merged YYYY-MM-DD; cd into the canonical path
```

### Phase 6 — VERIFY

```bash
ls "$WINNER/memory/" | wc -l   # entry count, should be sum of both sides minus dedup
ls "$LOSER" 2>/dev/null         # should report "No such file or directory"
ls ~/.claude/archive/$(basename "$LOSER")/  # archived jsonls + dirs
```

**(V2) Reconciliation gate — prove nothing was lost.** Before declaring success, reconcile the counts: capture `winner_before` and `loser_count` in Phase 3 *before* moving, then assert `winner_after == winner_before + loser_count − dedup_count`, where `dedup_count` is the number of same-name files you hand-merged. If the arithmetic doesn't close, **STOP** and show the discrepancy — a missing file means a silent loss, which is the one outcome this skill must never produce. Only report success once the count reconciles (or the user accepts a documented dedup).

Report the final state to the user as a 3-row table, including the reconciliation line (`winner_before + loser − dedup = winner_after`).

### Phase 7 — SUGGEST /compact

Claude Code's `/compact` slash command folds the running session into a clean summary. After a merge the current conversation contains a lot of "found this, moved that" detail that won't be useful later. Tell the user to run `/compact` (you can't invoke it yourself — it's a user-level command).

## Variant: legacy orphan memory (assess, don't blind-merge)

Phases 3–4 above assume the loser is a **live mirror** of the *same* current work — so moving its memory into the winner is safe. But sometimes the orphan is a **legacy namespace from before a project folder moved** (e.g. the project was at `/Users/me/Projects/foo` for months, then moved to `/Volumes/Drive/Projects/foo`). Then the orphan's memory is *old* — pre-move status, done backlogs, superseded facts. **Blind-merging it into the canonical dir re-pollutes current memory with stale content.** Detect this when the orphan's memory mtimes are weeks older than the canonical dir's, or the orphan's `MEMORY.md` describes a clearly earlier project state.

In that case, replace Phase 3's `mv`-everything with a **per-file assessment**:

1. **Read every orphaned memory file.** Classify each (verify claims against the *current* repo/code — files move, features ship, facts drift):
   - **KEEPER → repo**: a decision, gotcha, or product idea a remote agent/collaborator needs that ISN'T already in the repo (`docs/`, `CLAUDE.md`) or canonical memory. → write it into the repo (ADR under `docs/decisions/`, a `docs/` knowledge doc, or an ideas backlog).
   - **KEEPER → local**: still-valid behavior guidance ("don't do X, it's already handled"). → copy into the canonical memory dir + index it.
   - **SECRET-LOCATION**: anything naming where a token/credential lives, or env→environment maps. → fold into the canonical secrets-inventory memory. **Never commit, even to a private repo.**
   - **STALE**: superseded status, finished backlogs, old audits. → archive.
2. **Recover** the keepers to their destinations (repo or canonical memory); **reconcile** secret-locations into the local inventory.
3. **Archive** the stale orphan files to an `_archived-pre-migration/` subfolder inside the orphan memory dir — **don't delete**, don't merge into canonical.
4. **Tombstone** the orphan's `MEMORY.md`: replace it with a note that this is the orphaned `<old-path>` mirror, the canonical namespace + repo are the source of truth, and the files were archived. This stops a future session opened from the old path from trusting stale content.
5. **Report** a table: orphaned file → verdict → action. Call out any genuinely valuable recovered item prominently — that's the payoff (e.g. a parked product idea that never made it into a backlog).

Skip Phases 4 (transcript archive — leave legacy transcripts alone unless asked) and 5 (the dual-cwd feedback memory is still worth writing in the canonical dir so the split doesn't recur).

## What this skill does NOT do

- **Does not merge two jsonl transcripts into a single session.** That's not possible — Claude Code has no merge operation. The skill keeps the active session's transcript and archives the others.
- **Does not edit code, CLAUDE.md, or plan docs** unless the user explicitly asks for that as a follow-up. Memory-and-jsonls only. If the project has a stale plan/status doc that should reflect the merge, the user can ask you to update it after the skill runs.
- **Does not delete anything.** Archive is reversible; `rm` is not.
- **Does not run on every invocation.** If Phase 1 finds zero duplicates, exit early and say so. Don't manufacture work.

## Gotchas

1. **`mv` vs `cp`:** always `mv`. If you `cp` and forget to delete the source, the loser's memory dir keeps drifting as future sessions land there and write new entries. Deletion at the source is what stops the bleed.

2. **MEMORY.md merge collision:** the index file usually exists in both. Don't `mv` blindly — `mv -n` will keep the loser's copy as a sibling and you'll end up with two indexes. Read both, hand-merge, delete loser's copy.

3. **Per-session UUID subdirs:** Claude Code creates `<uuid>/` checkpoint dirs alongside `<uuid>.jsonl` files. These are mostly resumable-session state. Archive them along with the jsonl; don't leave orphans.

4. **`rmdir "$LOSER"` failing:** usually a `.DS_Store` on macOS or a stray `todos/` dir. List the contents before retrying; don't `rm -rf` reflexively.

5. **The current session might be in the loser dir.** If the user opened a session from the non-canonical cwd, the current `.jsonl` is being written to the loser. Don't archive it mid-conversation — the running session's writes will fail. Either tell the user to `/exit` first, or skip the current session's jsonl and archive the rest.

6. **Cross-project name collisions:** if two project names share a token (e.g. `api` and `api-gateway`), the inventory script will return both. Always show the user the full candidate list and confirm before moving anything.

7. **Don't try to be clever about "which transcript is more recent."** That's a merge-content question, not a merge-state question. The skill's job is to unify the memory namespace; the active session's transcript stays where it is.

## Changelog

### V2 (2026-05-27)
Optimized via `skillforge optimize`. **Honest note:** external outcome research was thin — this is a procedural skill for one specific Claude Code mechanism, with no meaningful state-of-the-art to mine. The genuine outcome to protect is *zero memory loss on merge*, so the V2 change is a safety hardening, not a research import:
- **Reconciliation gate (Phase 6)** — assert `winner_after == winner_before + loser − dedup`; STOP on any mismatch. Turns "looks done" into "provably lost nothing." Pairs with the existing archive-never-delete rule (the merge is already reversible).
- No outcome-research-driven additions were forced (the agent-memory three-layer model is already reflected in the legacy-orphan variant's repo/local/secret routing).

## See also

- `references/merge-example.md` — sanitized end-to-end walkthrough of a dual-cwd merge.
- `scripts/inventory.sh` — the Phase 1 helper.
- The legacy-orphan variant recovers keepers *into the repo* (ADRs, docs, ideas backlog) for the repo-side migration; this skill handles the namespace cleanup + tombstone.
