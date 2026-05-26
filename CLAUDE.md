# CLAUDE.md

This repo is a published library of agent skills (`ngmeyer/skills`). It is distributed via skills.sh and as a Claude Code plugin marketplace.

## Layout

- `skills/<category>/<name>/SKILL.md` — one skill per directory. Categories: `engineering`, `productivity`, `in-progress` (not shipped), `misc`, `personal`, `deprecated`.
- `.claude-plugin/plugin.json` — lists the shipped skills. **Only ship-ready skills go here.** `in-progress/`, `personal/`, and `deprecated/` are excluded.
- `references/`, `scripts/` inside a skill are loaded on demand (progressive disclosure).

## Adding or editing a skill

1. Author with the `skillforge` skill (it enforces frontmatter, progressive disclosure, gotchas).
2. New skills start in `skills/in-progress/<name>/`. Promote to `engineering`/`productivity` only when finalized, and add the path to `plugin.json`.
3. Frontmatter is exactly `name` + `description` (Matt-Pocock convention). Keep SKILL.md tight; push detail into `references/`.

## Before making the repo public (or before any public push)

This repo is **public** once flipped. Run the scrub gate first — no skill may contain:
- Hardcoded user paths (`/Users/<name>`, `/Volumes/...`), personal vault names, or `~/.claude/projects/...` user-specific dirs (genericize to `$HOME`/`~` or placeholders).
- Private project names (e.g. internal product/repo names) or business metrics in examples.
- Secrets or secret-locations.

Generic, reusable examples only. When in doubt, genericize.

## Don't

- Don't list an `in-progress`/`personal` skill in `plugin.json`.
- Don't add a skill sourced from someone else (license/attribution) without clearing it.
