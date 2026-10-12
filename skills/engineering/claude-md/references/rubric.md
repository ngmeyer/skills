# The 10-rule rubric (improve mode)

Ten checks, each backed by a primary source. Every recommendation cites the rule.
Budget numbers live in SKILL.md's Budgets section — this file never restates them.

| # | Rule | Source |
|---|---|---|
| R1 | **Length within the line budget** (see SKILL.md → Budgets). Longer reduces adherence. | Anthropic — [How Claude remembers your project](https://code.claude.com/docs/en/memory) |
| R2 | **Removability test on every line.** | Anthropic — [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices) |
| R3 | **Specificity: instructions concrete enough to verify.** No "be a senior engineer." | Anthropic — Memory docs |
| R4 | **Emphasis on load-bearing rules.** `IMPORTANT:` / `YOU MUST` / `NEVER`. Use sparingly — if every rule is IMPORTANT, none are. | Anthropic — Best Practices |
| R5 | **Markdown structure: headers + bullets.** Not dense paragraphs. | Anthropic — Memory docs |
| R6 | **5 canonical sections present** (Commands, Architecture, Rules, Workflow, Out-of-scope). | Community consensus + Anthropic `/init` template |
| R7 | **Hard Rules section ≤15 items.** Beyond that, rules drop. | Community (zodchiii thread, 1.3M views) |
| R8 | **3-tier hierarchy used correctly.** Across files: global rules in the user-level `CLAUDE.md`, project in `./CLAUDE.md` (git), personal in `./CLAUDE.local.md` (gitignored). No duplication across tiers. Within a file: order by priority — hard non-negotiables at top, context-dependent rules middle, references/conveniences bottom. The instruction budget compresses lower-priority items first. | Anthropic — Best Practices; Fraser (Medium, May 2026) |
| R9 | **Path-scoped rules in `.claude/rules/*.md`** when instructions only apply to certain files. | Anthropic — Advanced Patterns PDF |
| R10 | **No content auto memory will capture, and no standard-tool documentation.** Don't waste lines on stack details Claude figures out from `package.json`, nor on standard tools Claude already knows (`git`, `gh`, `npm`, `pnpm`, `bun`, `cargo`, `python`, `node`, `tsc`, `eslint`, `prettier`, `make`). Document only custom wrappers or non-obvious project-specific invocations. | Community + Anthropic auto-memory docs; Fraser (Medium, May 2026) |

## The 5 canonical sections (R6 detail)

A CLAUDE.md scoring well on R6 contains these sections. Suggest creating any that are missing:

1. **`## Project`** (1–2 lines: what this is, who uses it)
2. **`## Stack`** (1–3 lines: framework, language, deployment target)
3. **`## Commands`** (Build / Dev / Test single / Test all / Lint / Type check — short, exact)
4. **`## Architecture`** (folder → purpose mapping; not full directory listing)
5. **`## Rules`** (under 15 items; negative rules count; emphasis on the load-bearing one)
6. **`## Workflow`** (how the user wants Claude to approach tasks: minimal changes, ask vs act, commit conventions)
7. **`## Out of scope`** (files/integrations Claude should not touch)

## What NOT to include (anti-patterns)

- Personality instructions ("be a senior engineer")
- Code-formatter rules the linter already handles
- Duplicate rules across tiers
- `@-imports` of full README / huge docs (they enter the context window at launch)
- Anything Claude learns on its own via auto memory
- **Auto-generated bulk.** Never `/init`-and-forget or paste an LLM-generated context file. Controlled study: a *curated* context file gives ~+4pp task quality at ~20% token overhead, but an *auto-generated* one **reduces** task success ~0.5–2% while raising cost 20–23%. Curate ruthlessly; more context is not better. (arXiv 2026, AGENTS.md efficiency study.)
