# learn — Eval harness

**Level:** Compound (opens a repo PR; may archive spec files). Lesson-quality is LLM judgment and is not auto-graded yet.

## What's asserted
- Frontmatter: `name`, `description` (<=1024 chars, has `Use when:`), `metadata.owner`.
- Design contract: Inputs/Procedure/Verification/Gotchas sections; merged-check, draft-only, never-merge, never-commit-to-default; all references present.
- Portability: SKILL.md <=250 lines and <=16k bytes, no bare `---` in body, no harness-specific tokens (`~/.claude`, `.cursor/`, `allowed-tools`, `gh pr`, ...), no internal names.
- Behavioral: `scripts/verify.sh` against a scratch repo with a rebase-merged 3-commit PR — happy path, `BASE` default warning, >=2-folder delete rule (rejects `specs`, `specs/`, globs, `..`, non-spec paths), dangling links, default-branch guard, AGENTS.md budget, unmerged SHA.

## Run
`bash tests/eval.sh` (needs git; no network). Exit 0 = pass.

## from-memories (v0.2)
Fixtures: `tests/fixtures/repo` (AGENTS.md + docs/topics + one real path) and `tests/fixtures/memories` (project memory, global memory, Grok-style export). The eval lays them out as a Claude-style `~/.claude` tree in a temp dir and asserts:
- map: encoded project dir → repo, global file → global, `project:` header export → repo;
- triage: durable → CANDIDATE, missing path → STALE, AGENTS.md and docs/topics repeats → DUPLICATE, personal and global → NOT-FOR-REPO;
- redact: a runtime-built GitHub token + email file is BLOCKED, masked, contributes no candidates; AWS key, password assignment, phone block; example.com / 555-01xx allowed; committed fixtures are clean;
- source memory tree is byte-identical afterwards (read-only).
No token-shaped string is committed; the secret is assembled at test time.

## Tray path resolution
`scripts/tray-path.sh` against a scratch repo with a subdirectory, a linked worktree and a
symlink to the main tree. Asserts one **byte-identical absolute** tray path from all four
(equality alone would also hold for two empty strings, so each comparison demands a
non-empty absolute path); the contract filenames `entry-<YYYYMMDD>-<id>.md` and
`tray-log.md`; that resolution creates nothing; that an `entry-` prefix count ignores the
log; that an entry written in a worktree is readable from the main tree and survives
`git worktree remove` + `prune`; and that outside a repository it exits non-zero naming
the cause with no path on stdout.

Both ways of getting this wrong were run as mutants and seen red: resolving the common dir
in relative form fails the subdir/symlink/worktree assertions, and prefix-matching the
working-tree root fails the worktree one and prints a bogus path outside a repo.

## Capture verb and entry schema
`scripts/tray.sh capture` against scratch repos that each have a durable store
(`AGENTS.md` + `docs/topics/`) and one real source path. Asserts:
- **AE1** — one no-merge capture leaves exactly one tray entry, marked `verified: false`
  and `state: captured`, creates the tray lazily, and changes nothing durable: the working
  tree stays clean and the lesson appears in neither `docs/topics/` nor the instruction
  file. Each "changed nothing" assertion also demands the entry exist, because both hold
  trivially when no capture happened at all;
- **AE12** — a credential in the evidence text aborts the capture, reports the finding
  masked, and leaves no tray at all (the scan runs before anything is created). Each of
  the three asserts demands the deliberate abort report, so a crash or a missing script
  cannot read as "aborted correctly" — exit 127 and silence satisfy a bare `rc -ne 0`, and
  did, on the first red run;
- rejected at **write** time, not at promotion: a missing `--claim`/`--evidence`/`--path`/
  `--track`, a track outside `decision|checkable|standing`, a path with a line number
  (KTD3) or an absolute one, `--track decision` without `--accepted`, and `--accepted` on
  a track that cannot carry it;
- 3 captures back to back produce 3 distinct files and 3 new entries, none overwriting
  another, and each file's `id` matches its filename — so the id cannot come from the clock;
- round-trip: a claim containing quotes, a colon, a `#` and a backslash reads back
  byte-identical through a plain `sed` reader, with every path in order and every required
  field non-empty;
- a hand-written entry (`printf` only, no harness API) reads back through that same reader
  and carries the same field keys in the same order as a captured one.

Mutants run and seen red: a clock-derived id (same-second collisions), scanning only the
claim instead of the whole entry text (AE12 x3), creating the tray before the scan (AE12's
no-file assert), dropping the line-number rule, deferring the required-field checks to
promotion, emitting the claim as a bare YAML scalar, taking `captured_on` from a second
clock call, dropping `accepted` from a decision entry, keeping the tray in the working tree
(AE1), writing `verified: true`, accepting any track, and regenerating the id for the body
so filename and field disagree. **Not covered:** dropping the exclusive create
(`set -C`) — nothing fails, because the id is random and there is no way to force a
collision without an id-injection flag that was not built.
