# CLAUDE.md

This repo is a published library of agent skills (`ngmeyer/skills`). It is distributed via [skills.sh](https://skills.sh) (`npx skills add ngmeyer/skills`) and as a Claude Code plugin marketplace (`/plugin marketplace add ngmeyer/skills`).

## Layout

- `skills/<category>/<name>/SKILL.md` — one skill per directory. Shipping categories: `engineering`, `productivity`.
- `skills/<category>/<name>/references/` — progressive-disclosure depth, loaded on demand.
- `skills/<category>/<name>/scripts/` — deterministic helpers (sort, validate, format) the model shouldn't reason through.
- `skills/<category>/<name>/tests/eval.sh` — structural eval asserting the SKILL.md's design contract. There is no CI — run it manually before pushing (see Releasing).
- A skill dir holds only `SKILL.md` (+ optional `references/`/`scripts/`) and `tests/` (with `tests/README.md` documenting the eval). No root `README.md` inside a skill dir — `SKILL.md` is the doc.
- `.claude-plugin/plugin.json` — lists the shipped skills + marketplace metadata (description, version, author).

Only ship-ready skills appear in `plugin.json` — that file is the canonical list of what ships (don't hardcode a count here; it drifts). New candidates incubate in a separate workspace until validated.

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

**Before pushing, grep for leaks** — internal project names, real product/repo references, and secrets. Each skill's `tests/eval.sh` carries a self-containment guard that fails on the internal names you actually use; running the eval (see Releasing) is the gate. A skill that mentions a real internal project in an example, a changelog, or a validation note is a leak — genericize it ("a production web codebase," not the project's name).

## Releasing — pushing to `main` is production

Pushing to GitHub `main` publishes immediately: it updates the skills.sh package and the plugin marketplace, and **downstream consumers (incl. Vercel installs) are notified on every push.** Treat each push as a production release.

- **Test before you push.** Run the affected skill's `tests/eval.sh` and confirm **0 failures** first. There is no CI — the eval is the gate, and you are it.
- **Never push** a red eval, a WIP change, or an unscoped working tree. Stage only the files that ship.
- **Batch** related changes into one push; every push pings consumers, so avoid noise.
- A docs-only change (this file, README) is still a production push — same discipline, lower risk.

## Don't

- Don't list a non-shipped skill in `plugin.json`.
- Don't add a skill sourced from someone else without clearing license/attribution.
- Don't create **hard** cross-skill dependencies — a shipped skill must still function in a clean install of just this repo. A **soft, graceful-degradation** reference to a sibling skill that ships in this same repo is fine (e.g. `session-close` offers a `claude-md` audit if it's installed, and skips cleanly if not).
