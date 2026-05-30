# CONTEXT.md

The design philosophy behind these skills. (Read this before adding one.)

## What a skill is here

A skill is a small, self-contained instruction set an agent loads on demand. One directory, one `SKILL.md`, optional `references/` and `scripts/`. It should be readable in a minute and forkable without understanding the rest of the library.

## Principles

- **Small and composable over frameworks.** No skill should try to own your whole workflow. Sharp tools, then get out of the way.
- **Model- and agent-agnostic.** Skills target the `SKILL.md` standard; they work across Claude Code, Codex, and others. Avoid hard dependencies on one harness where a portable approach exists.
- **Progressive disclosure.** SKILL.md stays tight; depth lives in `references/`. Helper `scripts/` do deterministic work the model shouldn't reason through.
- **Curate, don't generate.** Hand-written, specific instructions beat auto-generated bulk — auto-generated context measurably degrades agents. Every line should earn its place (removability test).
- **Examples must be generic.** This is a public repo. Examples teach the pattern without leaking a real project, path, or metric.

## Naming

No personal/product prefix (no `nm-*`). The brand lives in the repo and README, not in every command — the way Matt Pocock's library does it, not the way `ce-*` does. Command names stay short and typed-often-friendly.

Conventions:
- **Verb-led for actions** (`deep-research`, `repo-handoff`, `fill-gaps`, `skills-cleanup`), **noun for capabilities/artifacts** (`six-pager`, `council-review`).
- **Family stems** group related skills (`review`, `repo-*`, `session-*`) so the set reads as a coherent library.
- **No `claude`/`anthropic` in names** (Anthropic skill rule). Descriptive over clever; a newcomer should guess what it does from the name.

## Categories

- `engineering` — code-facing skills (review, repo hygiene, recovery).
- `productivity` — thinking/process skills (decisions, memos, memory, self-audit).

New categories get added when they earn at least two skills. The shipping set is whatever's listed in `.claude-plugin/plugin.json`.
