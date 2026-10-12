# High-impact lines that compound

A menu to draw from when a file is genuinely *missing* a scope-control or safety rule.
**Subject to the trim-not-add caveat in SKILL.md:** on an already-aligned Claude Code
target scoring 9–10/10, do not bulk-add these — Claude Code's system prompt already
encodes most of them, and layering regresses quality (Augment Code, April 2026). Add the
one or two that close a real, observed gap; skip the rest.

## Scope & safety (highest leverage — prevent expensive, hard-to-revert mistakes)

- `Only modify files, functions, and lines directly related to the current task. Do not refactor, rename, or reformat anything I did not ask you to change. Note other issues at the end; don't touch them.`
- `Before any change that significantly alters existing content (rewriting sections, restructuring, changing tone): stop, describe what you're about to change and why, wait for confirmation.`
- `Before deleting a file, overwriting code, dropping records, or removing dependencies: stop, list what will be affected, ask for explicit confirmation in the current message. "You mentioned this earlier" is not confirmation.`
- `Production hard-stops requiring in-session confirmation: deploys/pushes, migrations or schema changes, outbound API calls, any command with irreversible side effects.` *(If a stop must hold 100% of the time, a PreToolUse hook is the real enforcement — CLAUDE.md compliance ceilings around 80%.)*
- `After any coding task, end with: files changed, one-line summary per file, files intentionally not touched, follow-up needed.`
- `NEVER commit .env files or secrets`
- `NEVER run git push --force without explicit confirmation`

## Workflow

- `IMPORTANT: run type check after every code change`
- `Make minimal changes, don't refactor unrelated code`
- `Create separate commits per logical change, not one giant commit`
- `When unsure between two approaches, explain both and let me choose`
- `For architecture decisions or non-trivial features: work through the problem step by step before writing code. Show reasoning and where you're uncertain, then implement.`

## Communication

Lowest marginal value on Claude Code — its system prompt already does most of this; add
only if you observe the specific failure.

- `Match response length to task complexity. Don't pad with restatements of the question or closing summaries.`
- `If uncertain about a fact, statistic, date, or technical detail, say so explicitly rather than filling the gap with plausible-sounding content.`

## Sourcing caveat

Wording sourced from the Karpathy-derived rule compilations (Fraser, May 2026; "Dep"
thread, May 2026). Their headline stats ("65% → 94% accuracy", per-developer dollar
figures, star counts) are illustrative marketing, not measured results — cite the *rule
wording*, not the numbers.
