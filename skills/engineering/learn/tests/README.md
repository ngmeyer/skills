# learn — Eval harness

**Level:** Compound (opens a repo PR; may archive spec files). Lesson-quality is LLM judgment and is not auto-graded yet.

## What's asserted
- Frontmatter: `name`, `description` (<=1024 chars, has `Use when:`), `metadata.owner`.
- Design contract: Inputs/Procedure/Verification/Gotchas sections; merged-check, draft-only, never-merge, never-commit-to-default; all references present.
- Portability: SKILL.md <=250 lines and <=16k bytes, no bare `---` in body, no harness-specific tokens (`~/.claude`, `.cursor/`, `allowed-tools`, `gh pr`, ...), no internal names.
- Behavioral: `scripts/verify.sh` against a scratch repo with a rebase-merged 3-commit PR — happy path, `BASE` default warning, >=2-folder delete rule (rejects `specs`, `specs/`, globs, `..`, non-spec paths), dangling links, default-branch guard, AGENTS.md budget, unmerged SHA.

## Run
`bash tests/eval.sh` (needs git; no network). Exit 0 = pass.
