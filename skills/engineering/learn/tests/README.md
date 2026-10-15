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

## Lazy expiry and the tray log
`scripts/tray.sh sweep` and the sweep wired into `capture`, against scratch repos whose
trays are built with `printf` at chosen ages (`date -v` on BSD, `date -d` on GNU; a host
with neither fails `mkentry` instead of quietly dating every entry today, which would make
every "expires" assertion pass for the wrong reason). Asserts:
- **AE5** — an unmatched entry past the eight-week window is removed, and the removal is
  logged as one line naming id, age and reason
  (`- <swept> expired id=<id> age=<days>d captured=<date> reason=unmatched-for-more-than-56-days`);
  one removal produces exactly one line; the lesson never reaches the durable store;
- the **ordering** (KTD5), as a differential pair rather than prose: the same entry, at the
  same age, on the same clock, survives `sweep --matched <id>` and is reaped by
  `sweep --no-matches`. The matched set is what decides, so pruning is downstream of
  matching. Stating it is mandatory — `sweep` with neither flag exits non-zero and removes
  nothing, so a caller that has not settled matching cannot reap by accident;
- an entry inside the window is untouched, including at **56 days exactly** (the edge is
  inside: an entry survives the full eight weeks);
- **KTD4** — a `proposed` entry past the window is not reaped and not logged;
- `capture` is a runner: an ordinary capture expires the stale entry it found, still prints
  exactly one path, exits 0, and does not reap the entry it just wrote;
- with no tray, the sweep is a no-op that creates nothing — not the tray, not the log
  (otherwise AE12's "nothing written, not even the tray" dies);
- after a long silence one sweep catches up on every overdue entry at once (3 removed, 3
  kept), the survivors are **byte-identical** afterwards, and the log is appended, not
  rewritten.

Each assertion that would hold on an untouched tray ("still there", "not logged", "printed
one path") is anchored on the removal having actually happened, because a missing `sweep`
verb satisfies all of them for free: two of these were written, run, and seen passing green
against no implementation at all before being anchored.

Mutants run and seen red, each caught by the assertion it was aimed at: prune ignoring the
matched set, the matched-set declaration made optional, an inclusive boundary (`-ge`), a
three-week window, no window at all, no `proposed` exemption, removal without logging,
logging without removal, a sweep that creates the tray instead of returning early, 30-day
months in the age arithmetic, `capture` not sweeping, a sweep that reports on stdout (it
corrupts capture's one-line output), a log rewritten instead of appended, an id logged with
the filename date still attached, and a sweep that annotates the entries it keeps (caught by
byte-identity alone, with the kept count still correct). **Not independently covered:** the
AE5 "never reaches the durable store" assertion — no plausible mutant of a sweep that only
deletes tray files can write to `AGENTS.md` or `docs/topics/`, so it is killed by its anchor
rather than on its own.

The first green run also found a real bug: the log's header restated the line format, and a
`grep` counting removals counted the header as one. The header no longer names the fields —
the format is documented in the script's EXPIRY note instead.
