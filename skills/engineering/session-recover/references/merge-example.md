# Reference example — duplicate project-dir merge

Sanitized walkthrough of a dual-cwd merge. Generic project (`acme-api`); expect your specifics to differ.

## Symptom

Mid-conversation in a session opened from `/mnt/work/acme-api/`, tried to read project memory entries that "should be there" — found the dir empty:

```
$ ls ~/.claude/projects/-mnt-work-acme-api/memory/
(empty)
```

But a sibling dir under a different encoded path had everything:

```
$ ls ~/.claude/projects/-Users-me-Projects-acme-api/memory/ | wc -l
22
```

Same project, two cwd paths (`/mnt/work/acme-api` vs `~/Projects/acme-api` — the latter is a home-dir symlink mirror of the canonical mount), two namespaces.

## Phase 1 — Inventory

```
$ bash ~/.claude/skills/session-recover/scripts/inventory.sh acme-api

Found 3 candidate dirs matching 'acme-api':

PATH                                                          JSONL   TOTAL_BYTES         NEWEST_MTIME    MEM  CLASS
----                                                          -----   -----------         ------------    ---  -----
-Users-me-Projects-acme-api-web                                   1        618787     2026-04-19_18:48      -  ~/Projects mirror
-mnt-work-acme-api                                                2      22633824     2026-05-15_17:15     26  external/secondary drive
-mnt-work-acme-api-worker                                         1          3214     2026-05-10_08:00      -  external/secondary drive
```

Three candidates surfaced. The bottom two (`-web` and `-worker`) are subdir-scoped sessions from when the user `cd`'d into `web/` or `worker/` directly — those are SEPARATE projects from the `acme-api` workspace and should be left alone, not merged.

The one to merge: `-Users-me-Projects-acme-api` — same logical project as `-mnt-work-acme-api` via the symlink mirror.

## Phase 2 — Pick winner

Current session's system prompt said:
> You have a persistent, file-based memory system at `~/.claude/projects/-mnt-work-acme-api/memory/`

So the mount-encoded dir is canonical. Loser = `-Users-me-Projects-acme-api`.

## Phase 3 — Merge memory

```bash
WINNER=~/.claude/projects/-mnt-work-acme-api
LOSER=~/.claude/projects/-Users-me-Projects-acme-api

mv "$LOSER/memory/"* "$WINNER/memory/"
rmdir "$LOSER/memory"
```

22 memory files moved. No conflicts (winner's memory dir was empty — easy case).

## Phase 4 — Archive jsonls

```bash
ARCHIVE=~/.claude/archive/-Users-me-Projects-acme-api
mkdir -p "$ARCHIVE"
mv "$LOSER"/*.jsonl "$LOSER"/5f1edf0a-789b-404b-8fc2-ebf1791ea9f2 "$LOSER"/d893cdad-e5dd-480c-9ea2-002bf360d660 "$ARCHIVE/"
rmdir "$LOSER"
```

Two `*.jsonl` files plus their per-session UUID subdirs moved. Old project dir empty → removed.

## Phase 5 — Capture lesson

Wrote a `feedback`-type memory into the winner's memory dir explaining:
- The two cwd paths
- Which is canonical
- When the merge happened
- "always `cd` into the canonical mount path before `claude`"

Added a one-line index pointer to `MEMORY.md` in the winner's memory dir.

## Phase 6 — Verify

```
$ ls ~/.claude/projects/-mnt-work-acme-api/memory/ | wc -l
26                                            # was 22 from loser + 4 fresh entries this session

$ ls ~/.claude/projects/-Users-me-Projects-acme-api 2>&1
ls: ...: No such file or directory            # gone

$ ls ~/.claude/archive/-Users-me-Projects-acme-api/
5f1edf0a-...jsonl  5f1edf0a-.../  d893cdad-...jsonl  d893cdad-.../
```

## Phase 7 — /compact

Run `/compact` to fold the merge details into the session summary.

## What surprised me

- **One side had 22 entries, the other had zero** — that's the easy case. If both sides had been populated I would have had to hand-merge `MEMORY.md` (the index file) since `mv` would have refused to clobber.

- **The inventory script found `-web` and `-worker` candidates that look like duplicates but aren't.** They're from sessions opened in subdirectories of the workspace, a legitimate use of the workspace structure. Don't merge subdir-scoped sessions into the workspace dir; they're separate projects to Claude Code.

- **The "wrong-path" memory dir was months old.** Sessions had been silently writing memory to it for a long time. No one noticed because every session that opened from the wrong cwd found a populated memory dir and assumed it was authoritative. The split only became visible when a session opened from the canonical cwd and found an empty dir. That's the failure mode the captured-lesson memory entry exists to prevent.
