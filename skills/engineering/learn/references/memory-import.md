# from-memories: importing agent memory into repos

## Inputs (read-only)
Any mix of: Claude Code global/project instruction files and per-project memory dirs, Cursor rules/memories, Grok Bot memory exports (plain text), or any `.md`/`.txt` the user names. Paths per harness: harness-notes.md. Memories are **never** edited, moved, or deleted by this mode.

## 1. Redact gate (blocking)
`scripts/redact-scan.sh <files>` flags: provider tokens (GitHub, OpenAI-style `sk-`, Slack, AWS `AKIA`, Google `AIza`, JWTs, PEM private keys), `key|secret|token|password = value` assignments, credentials in URLs, emails (except example.com/noreply), phone numbers (except 555-01xx).
- Any hit → the **whole file** is excluded from this run, reported masked (`BLOCK <kind> <file>:<line>`), and the user is told to clean or rotate. Why whole file: a memory that held one secret often holds context around it.
- Re-run on the staged diff before every commit (`git diff --cached | scripts/redact-scan.sh -`). A hit aborts the commit.
- False positive? The user edits the memory or the lesson text; do not add a bypass flag.

## 2. Map to repo or global
`scripts/memory-triage.sh map <repo roots...> -- <files...>` assigns a file to a repo when:
- it lives inside the repo (project instruction file, `.cursor/rules/*`, an export saved in the repo), or
- its directory name is the repo's absolute path with every non-alphanumeric char replaced by `-` (Claude Code project memory), or
- a plain-text export starts with `project: <repo root>` (or `repo:`/`path:`).
Otherwise → `global`. Global files are never committed; the agent may *suggest* a repo for a specific line, but only the user can move it.

## 3. Triage per line (bullets `- ` / `* `)
| class | rule | destination |
|---|---|---|
| BLOCKED-SECRET | redact hit | blocked list (masked) |
| NOT-FOR-REPO | file is global, or line is personal (`I prefer`, `my editor/shell/machine`, home paths) | Not-for-repo list |
| STALE | names a repo-relative path in backticks that no longer exists | dropped; listed as "prune after merge" |
| DUPLICATE | ≥80% of its significant words appear on one line of AGENTS.md/CLAUDE.md/docs/topics/.cursor/rules/docs/decisions | dropped; cite the existing line |
| CANDIDATE | none of the above | apply lesson-filter.md (recurs, non-obvious, actionable, verified) |
The script is a conservative pre-pass. The agent must still (a) confirm each STALE against the code (a path may have moved, not died), (b) read each DUPLICATE match (same words ≠ same rule; a contradiction becomes an EDIT, not a skip), and (c) reject candidates that are status, history, or one-off facts.

## 4. Batching
- One branch + draft PR per repo; ≤ `--max-lessons` (default 5) lessons per PR. Overflow → `learn/memories-<YYYY-MM-DD>-2`, `-3`, … each a separate draft PR, ordered by cross-cutting impact (AGENTS.md landmines first).
- Before opening batch n+1, rebase on default and re-run dedupe: batch n may already cover it.

## 5. PR body additions (on top of pr-template.md)
```
## Source memories
| file (path shown relative to $HOME, never absolute) | harness | lines used |
## Not for repo (not committed; shown here only as counts)
global: N · personal: M
## Safe to prune after merge (user action; not done by this PR)
| memory file:line | reason (imported as lesson #k / stale / duplicate of AGENTS.md:L) |
## Redaction
redact-scan on staged diff: CLEAN
```
Never paste Not-for-repo content or blocked lines into the PR body — counts only.

## 6. Prune report
After the PR merges, list memory lines that are now redundant (imported, duplicate, stale) so the user (or session-close) can prune them. This mode never deletes them.
