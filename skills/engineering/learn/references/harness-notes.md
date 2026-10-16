# Harness notes (keep harness specifics here, not in SKILL.md)
| need | Claude Code | Cursor | Grok Bot | any |
|---|---|---|---|---|
| install | `.claude/skills/learn/` or plugin | `.cursor/skills/learn/` or rule pointing at SKILL.md | skill on the box is fine to *read*; tray verbs must target the user clone (below) | read SKILL.md as a prompt |
| PR metadata + comments | `gh pr view <n> --json body,comments,reviews,files` | same via terminal, or GitHub MCP | GitHub MCP: `get_pull_request`; review comments `list_pull_request_comments`; issue-level PR comments `list_issue_comments` | REST `GET /repos/{o}/{r}/pulls/{n}` |
| open draft PR | `gh pr create --draft` | `gh` or GitHub MCP | GitHub MCP `create_pull_request` (draft) — needs user approval | push branch, open in UI |
| run verify.sh | Bash | terminal | Shell on box (tests) or machineId Shell on user clone (tray) | bash |
| trigger post-merge | hook/manual `/learn` | manual or background agent | manual (no verified merge routine yet) | GitHub Action on `pull_request: closed && merged` that posts "run learn" comment |
| capture tray | same clone's `.git/learn-tray` | same clone/git-common-dir as Claude → **same tray** | **MUST** run capture/list/promote via local-execution Shell (`machineId`) against the user's working clone — never against a box-only checkout | `tray-path.sh` |
Claude Code: CLAUDE.md should `@AGENTS.md`-import so lessons load deterministically.
Cursor: rules in `.cursor/rules/*.mdc` that point to topics count as context — grep them in dedupe.

## Memory locations for `from-memories` (read-only inputs)
| harness | global | per project | notes |
|---|---|---|---|
| Claude Code | `~/.claude/CLAUDE.md` | `~/.claude/projects/<encoded-abs-path>/memory/*.md` (+ `MEMORY.md` index), repo `CLAUDE.md`, `CLAUDE.local.md` | encoded path = absolute repo path with each non-alphanumeric char → `-`; `CLAUDE.local.md` is personal by convention → Not for repo. See the two shapes and the namespace rule below. |
| Cursor | User Rules (Settings → Rules; copy out as text) | `.cursor/rules/*.mdc`, legacy `.cursorrules`; Memories (Settings → Rules → Memories, export as text) | rules already in the repo are dedupe targets, not imports, unless the user names them |
| Grok Bot | short sentences held server-side; the user pastes them in as plain text | none — there is no per-project store | **global unless the user names the repo.** See below. |
| any | user-named `.md`/`.txt` | a hand-added `project: <repo root>` first line (also `repo:`/`path:`) | map by path, then by that header; else global |

### Grok Bot has no export format
Its memory is not files on disk: it is short sentences kept off the user's machine, with
no header and no envelope. So there is nothing to parse and no project scoping to read —
pasted Grok memory is **global** until the user says which repo a line belongs to, and
the agent may only *suggest* a repo for a line, never assign one.

For `from-memories` on Grok Bot there is still **no file export**. The agent uses
RecallMemory / UpdateMemory facts the user (or the agent, with approval) pastes as plain
text. Those facts are user-scoped and stay **global until the user names a repo**.

The `project: <repo root>` first line this skill accepts is **this skill's own
convention**, not any harness's output. It works on any plain-text file because a human
typed it there. Do not tell a user to "export with the project header" — there is no such
export.

**Verification status.** The Claude Code shapes above were checked by sampling real memory
dirs. Cursor and Grok Bot memory *locations* were checked by reading files and
documentation; Grok Bot tray sharing with the user clone was hand-verified 2026-10-15
(see *Grok Bot parity* below).

### Claude Code: one fact per file, not a bullet list
A memory dir there is usually **one fact per file** with YAML frontmatter and a prose body — no bullets at all:
```
---
name: <kebab-slug>
description: <the one-line fact; this is the lesson>
metadata:
  type: user | feedback | project | reference
---
<prose>  **Why:** …  **How to apply:** …  links as [[other-memory]]
```
So **read `description` as the candidate**, not the bullets. `type:` sits at the top level in older files and under `metadata:` in newer ones; accept both. Route by type: `feedback`/`reference` are the durable ones and the best AGENTS.md material, `project` is mostly status that fails the *recurs* gate, `user` is personal — the whole file is Not for repo, body included.

`MEMORY.md` is an **index** of `- [Title](file.md) — hook` pointers, not content. Triaging it yields titles, not lessons: read it to find the files, then import from the files. Bullet-shaped memories still exist (hand-written files, other harnesses), so handle both shapes.

### One repo can have more than one namespace
The namespace is an encoded *path*, not a repo identity, so a repo reachable by two absolute paths (a moved checkout, a mirror, a symlinked working dir) has two memory dirs, and a **parent** directory that is not itself a repo can hold a legitimate namespace full of repo-scoped lessons. Pass every path the repo is reachable by; files under the other paths map to `global` and their lessons are silently dropped. `ls ~/.claude/projects | grep <repo-basename>` finds the aliases. A genuine split is `session-recover`'s job, not this skill's — fix it there first, then import.

## Where the capture tray lives (same answer in every harness)

A session that produces no merge captures its lessons into a **tray in the repository's
shared git directory** — outside the working tree and outside version control. Resolve it
only through `scripts/tray-path.sh`; never build the path by hand.

| what | where | how |
|---|---|---|
| tray dir | `<git-common-dir>/learn-tray/` | `tray-path.sh` |
| one entry | `learn-tray/entry-<YYYYMMDD>-<id>.md` (date = capture date) | `tray-path.sh entry <id>` |
| tray log | `learn-tray/tray-log.md` | `tray-path.sh log` |
| counting entries | match the `entry-` prefix instead of listing the directory, so the log is never counted as an entry | |

The script asks git for the common dir in **absolute** form. The relative form is `.git`
in a main working tree, `../../.git` from a subdirectory of it, and a path into the main
checkout from a linked worktree — three strings for one repository, so a relative answer
splits the tray and each session sees only its own half. Prefix-matching the working-tree
root (what `memory-triage.sh` does to map memory *files*, for different reasons) has that
bug too, plus a symlink one: it is not the precedent to copy here.

Consequences worth knowing: every working tree sharing the git directory — a
subdirectory, a symlinked checkout, a linked worktree — reads and writes one tray, so an
entry captured in a worktree is still there after `git worktree remove` and
`git worktree prune`. The tray is created lazily by the first capture, never at install,
so a repo that has never captured has no tray. It is untracked, so it never shows in
`git status` and survives `git clean`. Deleting the clone deletes the tray with it —
promotion, not the tray, is what makes a lesson durable. Outside a repository there is no
tray and resolution fails rather than writing somewhere arbitrary.

### Grok Bot: tray verbs must hit the user clone
Grok Bot's default Shell runs on a **box** with its own filesystem. A box-only clone of
the repo has a different `.git` (and therefore a different `learn-tray`) from the clone
Cursor or Claude uses on the user's machine. Captures written only on the box are
**invisible** to those agents and disappear when the box is reset.

So for Grok Bot, `capture` / `list` / `reject` / `promote` / `propose` **MUST** run
through local-execution Shell with the user's `machineId`, `cd`'d into the user's working
clone (the same path Cursor opens). Never treat a box checkout as the tray host.

Cursor and Claude share one tray when they share one clone / `git-common-dir` (e.g. both
on ALIEN-NEAL at `~/src/<repo>`).

A per-project **agent memory directory** (the `from-memories` inputs above) is a different
store with a different owner: it lives under the user's home agent directory, is keyed by
an encoded absolute path, and is read-only to this skill. The tray is in the repo's git
dir and is this skill's to write.

## Running the tray verbs (plain shell, every harness)

Every step is a plain command. **A harness hook is an optional accelerant, never a
requirement:** nothing here needs a harness API, an MCP server, an env var or a forge CLI,
and a human at a prompt runs the same commands an agent does. Run them from anywhere
inside the repository — the tray is resolved from the git directory, not from the cwd.

| verb | command | prints on stdout |
|---|---|---|
| capture | `scripts/tray.sh capture --track <decision\|checkable\|standing> --claim "<one line>" --evidence "<one line>" --path <repo-relative> [--path ...] [--accepted true\|false]` | the path it wrote, one line |
| list | `scripts/tray.sh list` | one block per entry — `entry <id>  age=<n>d  track=…  state=…`, then `claim:`, then one `path:` line per match path — followed by one line per entry this listing expired |
| reject | `scripts/tray.sh reject <id> --reason "<why>"` | one line naming the entry removed |
| sweep | `scripts/tray.sh sweep --no-matches` \| `--matched <id> [--matched <id>]...` | nothing |
| promote | `scripts/tray.sh promote --event <merge\|decision-acceptance> [--confirms <id>]... [--contradicts <id>="<what the default branch says instead>"]... [--as <id>=<track>]... [--budget <words>] [--instruction-file <path>]` | one routing line per entry — `promote` / `staged` / `excluded` / `held` — each `promote` followed by the `line:` it would add, then a count and the next step |
| propose | `scripts/tray.sh propose <id> [<id>...] --branch <head branch> --pr <reference>` | one line per entry marked |

Exit 0 is success; any refusal is non-zero with a `learn: …` line on stderr and no change
on disk. Reading the tray with `cat` and `ls` instead is fine — the entries are Markdown —
but resolve the directory through `scripts/tray-path.sh`, never by hand.

- **`list` is one of the three expiry runners** (capture, list, promotion). It prints
  first and sweeps second, so an entry past the window is reported *and then* reaped in the
  same listing: the operator reads what was removed rather than finding it gone. It is the
  only runner that fires in a repository nobody is capturing into, which is the only reason
  a forgotten tray does not grow forever.
- **`list` scans every entry it reads** and reports findings masked. The capture-time scan
  binds only `capture`, so an entry written as a plain file — by a human, or by an agent
  that printf'd it — never passed one. A finding on read **deletes nothing**; it tells you
  to rotate the credential and then reject the entry.
- **`reject` is the only deliberate deletion.** A lesson a promotion's filter declines is
  "not yet" and stays listable; rejecting it is permanent, which is why `--reason` is
  required and lands in the log.
- **The tray log is append-only and shared.** More than one verb writes to it and the verb
  is what distinguishes the writer: the sweep writes `expired`, `reject` writes
  `rejected`, reconciliation writes `consumed`. So `grep ' expired id=' <log>` counts
  expiries and nothing else, and the same holds for each of the others. A new writer takes
  its own word, never another's, and adds no header line that another writer's grep would
  match. The one field a caller controls — a rejection's reason, a consumption's pull
  request reference — is checked against the other verbs' greps before the line is written.

### Grok Bot parity — hand-verified tray share (KTD12)

Claude Code parity is **machine-verified**: `tests/eval.sh` produces one tray-and-
instruction-file state three ways — by the verbs, by hand, and with a stream editor — and
fails unless every check on it returns an identical exit code and identical output; it
then runs the verbs a second time under `env -i` with only `PATH`, `HOME` and `TZ`, with
no forge CLI on `PATH`, and fails unless that output matches the run made with harness
environment variables set. Grok Bot has no such runner here; tray-share evidence is the
manual procedure and checklist below.

- status: hand-verified
- procedure last run by hand: 2026-10-15
- record last reviewed: 2026-10-15
- answered question: does Grok Bot's shell share a git directory with the user's clone?
  **Only when Shell targets that clone via `machineId`.** A box-only checkout is a
  different repository (box checkout `.git` ≠ user-clone `.git`); its tray is
  invisible to Cursor/Claude on the user machine and dies with the box. Local-execution
  Shell against the user clone shares `git-common-dir` / `learn-tray` with Cursor on the
  same clone.

#### Manual parity checklist (actually run) — 2026-10-15 PT
Repo: ALIEN-NEAL WSL `nealme` `~/src/skills` (WSL user clone) on `forge/learn-skill`.
Throwaway claims only; both entries rejected before leaving.

| step | where | result |
|---|---|---|
| 1. `git rev-parse --path-format=absolute --git-common-dir` | ALIEN-NEAL clone | `~/src/skills/.git` |
| 1b. same via Grok `machineId` Shell into that clone | box → ALIEN-NEAL | **identical** common-dir |
| 1c. box-only clone contrast | separate box checkout of the same GitHub repo | its own `.git/learn-tray` — **different tray** |
| 2. `tray.sh capture` (checkable throwaway) | ALIEN-NEAL | wrote `entry-20261015-0ee299ce.md`; frontmatter matched schema |
| 3. `tray.sh list` | ALIEN-NEAL | showed id, age=0d, track, state, claim, path |
| 3b. capture + list via `machineId` (standing throwaway) | box → ALIEN-NEAL | id `9db4bd75` listed in the **same** tray Cursor would see |
| 4. `tray.sh reject` both ids | ALIEN-NEAL | removed; tray-log recorded reasons; list empty |
| 5–6. promote → draft PR → propose → merge/consume | — | **not run** this pass (throwaway reject path only) |

Full promote/PR/consume path remains optional follow-up; tray **share** with Cursor is
confirmed for capture/list/reject when Grok uses machineId against the user clone.

The longer procedure (for a real lesson you intend to keep):

1. Via `machineId` Shell, `cd` into the **user** clone and record
   `git rev-parse --path-format=absolute --git-common-dir`. Compare with a local Cursor
   terminal in the same clone — they must match. A box-only path must not be used.
2. `scripts/tray.sh capture --track checkable --claim "<one line>" --evidence "<one line>"
   --path <repo-relative path>` — it prints one path. `cat` that path and check the
   frontmatter against *What a tray entry contains* below.
3. `scripts/tray.sh list` — the entry appears with its id, age, track, state, claim and
   match paths. Confirm the same `list` from a Cursor/Claude session on that clone.
4. `scripts/tray.sh promote --event merge --confirms <id>` — one routing line, with the
   `line:` it would add and where.
5. Apply that line **verbatim**, commit, push the branch, open **one draft pull request**
   (the web UI is fine; there is no CLI requirement), then
   `scripts/tray.sh propose <id> --branch <head branch> --pr <reference>`.
6. After the pull request merges and its head branch is deleted, run `scripts/tray.sh
   list` once more: the entry is gone and the tray log records it as `consumed`.

It passes if steps 2–3 (and 4/6 when run) print what the same steps print in another
harness on the same repository state — identical but for the id, the date and the
repository path — and if nothing in the run needed a harness API, an MCP server, an
environment variable or a forge CLI beyond plain Shell. It fails if capture was aimed at
a box-only clone.

## Promotion: the routing table

Every promotion event evaluates **every** entry — the track selects the gate, not the
trigger — and **evidence resolves before the track routes**.

| track | evidence | merge event | decision-acceptance event |
|---|---|---|---|
| `checkable` | resolves, confirms | promote | promote — the gate is a condition, not an event |
| `checkable` | unresolvable | re-anchor against the entry's paths; if that fails, surface and leave staged | same |
| `checkable` | resolves, contradicts | surface the contradiction by name, leave staged | same |
| `decision` | not evaluated — exempt | leave staged unless acceptance is recorded | promote as a decision-record draft |
| `decision` | later contradicted by the repo adopting the alternative | leave staged — still exempt from the evidence step | promote; the adopted alternative is the lesson, and it is the most valuable entry in the tray |
| `standing` | skipped entirely | promote to `docs/topics/`, flagged **asserted** | same |
| any | `state: proposed`, head branch still on the remote | leave proposed, clock frozen | same |
| any | `state: proposed`, head branch gone | claim in the default branch → consumed; absent → back to `captured`, clock untouched | same |

**TODO 0.4.1 — proposed-entry expiry:** docs say the clock is frozen while `proposed`, but
age is still derived from the capture-date filename. A promotion PR open longer than the
8-week window that then returns to `captured` (reviewer trim) can be reaped in the same
`list`/`sweep` run. Fix by preserving age-at-propose on demotion (or equivalent); do not
half-fix. Not addressed in 0.4.0.

- **Why that order.** `standing` skips the evidence step and `decision` is exempt from it.
  Route first and an entry whose evidence just failed can be re-routed onto one of them
  and promoted on the strength of the step that refused it — so `--as` is **refused** for
  such an entry, not merely disclosed. `--as` on an entry the evidence step cleared is
  honoured and shown in the report as `track=checkable->standing`.
- **Promotion writes nothing.** It prints the routing and the line it would add; the
  session applies the lines, re-runs `redact-scan.sh` on the staged diff, commits, opens
  **one draft pull request it never merges**, and records it with `propose`.
- **The instruction file's word budget is the normal obstacle, not the exception.** An
  always-loaded file sits at its limit, so assume a lesson does not fit: it goes to
  `docs/topics/` and the report and PR body say so, with the count. Nothing is silently
  dropped and the budget is never silently blown. `--budget` overrides the 400-word
  fallback — the repo's own lint wins.
- **A secret found at promotion excludes that entry alone**, by id, masked, with a
  rotate-the-credential instruction. The rest of the batch promotes; aborting it all would
  let one poisoned entry block every later lesson indefinitely.
- **Reconciliation runs on all three runners** (capture, `list`, `promote`), because
  `state: proposed` is exempt from expiry and an entry nothing reconciles is exempt
  forever. The signal is git alone — `git ls-remote --heads` for the recorded head branch,
  then the claim's presence in the default branch — so it works with no forge tooling. A
  signal it cannot get (no recorded branch, an unreachable remote) leaves the entry
  exactly as it is: consumption deletes, so it never guesses. **Apply the `line:` the
  promotion printed, verbatim** — the claim in it is what reconciliation later looks for in
  the default branch, so a reworded line reads as a trimmed one and the entry comes back to
  `captured` instead of being consumed. That direction is the safe one (a second promotion
  attempt, never a deletion), but it is avoidable. Consumption takes its own
  word in the tray log, `consumed`, so it inflates neither the expiry nor the rejection
  count.

## What a tray entry contains

One entry is one Markdown file with YAML frontmatter — the same frontmatter-plus-prose
shape as a one-fact memory file. Capture it with
`scripts/tray.sh capture --track <t> --claim "<one line>" --evidence "<one line>"
--path <repo-relative path> [--path ...] [--accepted true|false]`, which prints the path
it wrote. Every field below is required and is refused at **write** time if missing, not
at promotion, where the capturing session is gone and the gap can no longer be filled.

| field | what it holds |
|---|---|
| `id` | 8 hex chars, also in the filename — which is what makes two captures in the same second collision-free, so it is never derived from the clock |
| `claim` | the lesson, one line |
| `evidence` | the content citation behind the claim, one line. A commit identifier is never evidence on its own: a squash-merge leaves a branch commit unreachable from the default branch as a matter of routine |
| `paths` | repo-relative paths the claim is about, in order, **with no line numbers** — paths are the match key and survive edits, line numbers are evidence and do not |
| `captured_on` | the capture date, read back out of the filename so the two can never disagree |
| `track` | `decision` \| `checkable` \| `standing` |
| `state` | `captured` (what capture writes) \| `proposed` (a promoted entry, written by `propose` together with `pr_branch` and `pr_ref` — the only signal reconciliation has) |
| `verified` | always `false` at capture: nothing has re-checked the claim yet |
| `accepted` | `decision` track only — whether the decision was accepted, because nothing else in the system records that |

Free text is a double-quoted YAML scalar (backslash and quote escaped) and the rest is
bare, so `sed -n 's/^claim: //p'` plus an unquote is a sufficient reader. Anything after
the closing `---` is free prose a reader may ignore. **No harness API is involved:**
another agent can produce a valid entry with `printf` and the filename from
`tray-path.sh entry <id>`.

**The track is a routing hint, not a verification claim.** It says where the lesson
should go; it never asserts the lesson is true (that is what `verified: false` is for),
and the promoting session may override it as long as it discloses the override. Pick
`decision` when the lesson settles a choice against a rejected alternative; else
`checkable` when the claim can be resolved against the default branch; else `standing`.
The capturing session picks, so that two sessions filing one lesson do not file it two
different ways and get opposite outcomes.

**A secret blocks the write; it is never redacted into the entry.** A tray file is never
in a pull request and never staged, so neither review nor a pre-commit scan would ever
see it, and a transcript-borne credential would otherwise sit inside the repository,
readable by every later agent, for the whole expiry window. `scripts/redact-scan.sh` runs
on the entry text before anything is created — a finding is reported masked and nothing
is written, not even the tray, because a redacted entry is evidence of nothing.
