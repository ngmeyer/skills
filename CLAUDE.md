# CLAUDE.md

This repo is a published library of agent skills (`ngmeyer/skills`). It is distributed via [skills.sh](https://skills.sh) (`npx skills add ngmeyer/skills`) and as a Claude Code plugin marketplace (`/plugin marketplace add ngmeyer/skills`).

## Layout

- `skills/<category>/<name>/SKILL.md` — one skill per directory. Shipping categories: `engineering`, `productivity`.
- `skills/<category>/<name>/references/` — progressive-disclosure depth, loaded on demand.
- `skills/<category>/<name>/scripts/` — deterministic helpers (sort, validate, format) the model shouldn't reason through.
- `skills/<category>/<name>/tests/eval.sh` — structural eval asserting the SKILL.md's design contract; runs in CI on every commit.
- `.claude-plugin/plugin.json` — lists the shipped skills + marketplace metadata (description, version, author).

Only ship-ready skills appear in `plugin.json`. The repo currently ships 9 skills; new candidates incubate in a separate workspace until validated.

## Adding or editing a skill

1. Author with the `skillforge` skill (it enforces frontmatter, progressive disclosure, mandatory Gotchas).
2. Frontmatter is `name` + `description` (Matt-Pocock convention). Keep SKILL.md under Anthropic's 500-line bar; push detail into `references/`.
3. Add `tests/eval.sh` with structural assertions (heading shape, anti-pattern checks, portability — see existing skills for the pattern).
4. Add the path to `.claude-plugin/plugin.json`.
5. Optimize to V2 with `skillforge optimize <skill>` once it has a real outcome to measure; record the V1→V2 delta in the skill's `## Changelog`.

## Public-repo hygiene

Every commit to `main` is public. No skill may contain:

- Hardcoded user paths (`/Users/<name>`, `/Volumes/...`, `~/.claude/projects/...`). Use `$HOME`, `~`, or placeholders.
- Private project names, internal product/repo references, or business metrics in examples.
- Secrets, secret locations, or credentials of any kind.

Generic, reusable examples only. When in doubt, genericize.

## Don't

- Don't list a non-shipped skill in `plugin.json`.
- Don't add a skill sourced from someone else without clearing license/attribution.
- Don't create cross-skill dependencies — a shipped skill must work standalone in a clean install of just this repo.
