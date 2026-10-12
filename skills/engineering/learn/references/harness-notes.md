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
