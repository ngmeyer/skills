# Harness notes (keep harness specifics here, not in SKILL.md)
| need | Claude Code | Cursor | Grok Bot | any |
|---|---|---|---|---|
| install | `.claude/skills/learn/` or plugin | `.cursor/skills/learn/` or rule pointing at SKILL.md | box skill dir / Skills | read SKILL.md as a prompt |
| PR metadata + comments | `gh pr view <n> --json body,comments,reviews,files` | same via terminal, or GitHub MCP | GitHub MCP (`get_pull_request`, `list_pull_request_comments`) | REST `GET /repos/{o}/{r}/pulls/{n}` |
| open draft PR | `gh pr create --draft` | `gh` or GitHub MCP | GitHub MCP `create_pull_request` (draft) — needs user approval | push branch, open in UI |
| run verify.sh | Bash | terminal | Shell on box | bash |
| trigger post-merge | hook/manual `/learn` | manual or background agent | routine on merge or manual | GitHub Action on `pull_request: closed && merged` that posts "run learn" comment |
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

The `project: <repo root>` first line this skill accepts is **this skill's own
convention**, not any harness's output. It works on any plain-text file because a human
typed it there. Do not tell a user to "export with the project header" — there is no such
export.

**Verification status.** The Claude Code shapes above were checked by sampling real memory
dirs. The Cursor and Grok Bot rows were checked by reading files and documentation only —
neither skill has been loaded in a live Cursor or Grok session. Treat those two rows as
untested until someone runs them.

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

A per-project **agent memory directory** (the `from-memories` inputs above) is a different
store with a different owner: it lives under the user's home agent directory, is keyed by
an encoded absolute path, and is read-only to this skill. The tray is in the repo's git
dir and is this skill's to write.

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
| `state` | `captured` (what capture writes) \| `proposed` (a promoted entry) |
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
