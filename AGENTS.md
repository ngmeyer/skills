# AGENTS.md

Canonical instructions for any coding agent working in this repo (`ngmeyer/skills`), a published library of agent skills. It ships through the [skills.sh](https://skills.sh) installer (`npx skills add ngmeyer/skills`), which targets Claude Code, Codex, Cursor, Grok and many other agents, and through a Claude Code plugin marketplace. `CLAUDE.md` only imports this file; edit here.

## Layout

- `skills/<category>/<name>/SKILL.md`: one skill per directory (`engineering`, `productivity`).
- `references/` (loaded on demand), `scripts/` (deterministic helpers), `tests/eval.sh` + `tests/README.md` (structural eval). No `README.md` inside a skill dir.
- `.claude-plugin/plugin.json`: the canonical list of what ships. Don't hardcode a count here; it drifts.

## Adding or editing a skill

1. Author with `skillforge` (frontmatter, progressive disclosure, Gotchas).
2. Frontmatter is `name` + `description`, description ≤1,024 chars. Push detail into `references/`.
3. Keep agent-specific paths (e.g. `~/.claude/...`) out of a skill's core unless it declares the harness it targets.
4. Add `tests/eval.sh`, then add the path to `plugin.json`.
5. Once it has a real outcome to measure, optimize with `skillforge optimize <skill>` and record the V1→V2 delta in its `## Changelog`.

## Public-repo hygiene

Every commit to `main` is public. No hardcoded user paths, private project names, business metrics, or secrets in any skill, changelog, or example. Genericize. Each eval's self-containment guard is the leak gate.

## Releasing: pushing to `main` is production

A push updates skills.sh and the marketplace and notifies downstream consumers. Run the affected evals to 0 failures first, stage only shipping files, and batch related changes. Detail: [docs/topics/releasing.md](docs/topics/releasing.md).

## Don't

- List a non-shipped skill in `plugin.json`.
- Add a skill sourced elsewhere without clearing license/attribution.
- Create hard cross-skill dependencies; a soft reference to a sibling skill that degrades gracefully is fine.

## Budget

This file is always loaded, so it is capped by `scripts/lint-agents-md.sh`. Overflow goes to `docs/topics/`, linked from here.
