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
