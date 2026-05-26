# Claude.md

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-Skill-blueviolet?logo=anthropic)](https://claude.ai/code)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey)]()

All-in-one Claude Code skill for CLAUDE.md files. Two modes:

- **`audit`** — find drift, leaked secrets, duplicates, instruction-budget bloat across all CLAUDE.md files
- **`improve`** — measure one CLAUDE.md against Anthropic's best practices and propose concrete rewrite diffs

Same skill, same trigger registry slot, same core principle (Anthropic's removability test). Replaces the older standalone `claude-md-audit` and `claude-md-improve`.

## Why This Exists

CLAUDE.md files rot in two ways: they accumulate stale claims (drift) and they accumulate noise (low-impact lines). Anthropic's diagnostic for both: *"For every line, ask: If I removed this, would Claude make a mistake? If not, remove it."* Audit mode finds violations across many files; improve mode rewrites one file against the full rubric. Same diagnostic, different scale.

A second invariant: CLAUDE.md is in git. Pasted secrets are durable leaks. Both modes treat secret-leak detection as P0.

## Mode Dispatch

| Invocation | Mode |
|---|---|
| `/claude-md` (no args, in a project with `./CLAUDE.md`) | auto → improve |
| `/claude-md` (no args, no local file) | auto → audit all |
| `/claude-md improve [path]` | improve (single file) |
| `/claude-md audit [project\|all\|path]` | audit (multi-file) |

## Install

```bash
git clone https://github.com/ngmeyer/claude-md.git
cd claude-md

# Global install (available in all projects)
mkdir -p ~/.claude/skills/claude-md
cp SKILL.md ~/.claude/skills/claude-md/SKILL.md
```

Use it:

```
/claude-md                                 # auto-detect
/claude-md improve                         # improve cwd's CLAUDE.md
/claude-md improve ~/.claude/CLAUDE.md     # improve global file
/claude-md audit                           # audit all
/claude-md audit saas-app                  # audit one project
/claude-md audit /path/to/CLAUDE.md        # audit one file
```

Trigger phrases: *audit claude.md*, *check claude md drift*, *lint CLAUDE.md*, *refresh instructions*, *improve CLAUDE.md*, *restructure CLAUDE.md*, *tune CLAUDE.md*, *is my CLAUDE.md good*, *CLAUDE.md is too long*.

## Improve Mode — The 10-Rule Rubric

| # | Rule | Source |
|---|---|---|
| R1 | Length under 200 lines | [Anthropic Memory docs](https://code.claude.com/docs/en/memory) |
| R2 | Removability test on every line | [Anthropic Best Practices](https://code.claude.com/docs/en/best-practices) |
| R3 | Specificity — concrete enough to verify | Anthropic |
| R4 | Emphasis on load-bearing rules (`IMPORTANT:` / `YOU MUST` / `NEVER`) | Anthropic |
| R5 | Markdown structure (headers + bullets, not paragraphs) | Anthropic |
| R6 | 5 canonical sections present | Community + Anthropic `/init` |
| R7 | Hard Rules section ≤ 15 items | Community |
| R8 | 3-tier hierarchy used correctly | Anthropic |
| R9 | Path-scoped rules in `.claude/rules/*.md` | Anthropic Advanced Patterns |
| R10 | No content auto memory will capture | Anthropic |

Output is a structured diff (deletions / additions / rewrites) with each change citing its rule. Surgical Edits applied only after `yes` / `partial` / `no` user choice.

## Audit Mode — 7-Phase Hygiene Scan

```
Phase A-1: DISCOVER          → find all CLAUDE.md files
Phase A-2: SECRET SCAN       → P0 leaks (always first)
Phase A-3: DRIFT DETECTION   → claimed facts vs real code
Phase A-4: DUPLICATES        → headings / paragraphs
Phase A-5: BUDGET + RATIO    → instruction count + descriptive vs prescriptive
Phase A-6: REPORT            → grouped by severity, per project
Phase A-7: OFFER FIXES       → interactive, never auto-apply leaks
```

Output:

```
# CLAUDE.md Audit Report

## Summary
- 6 files scanned, 1 P0 LEAK, 2 with drift, 3 clean

## acme-web 🔴 P0 LEAK
- Line 38: AUTH_SECRET= (rotate + scrub history)

## data-pipeline 🟠 DRIFT
- Line 52: claims "Brevo SMTP", code uses REST → fix
```

## What It Won't Do

- Auto-apply. Always presents for approval first.
- Rewrite the whole file. Surgical Edits only — preserves voice and detail.
- Flag perfectly fine lines. The removability test must actually fail.
- Rotate secrets or scrub git history. Reports the leak and the remediation; you drive the rotation.
- Invent project context. Reads `package.json` / `pyproject.toml` / `Cargo.toml` / `Gemfile` / `README.md` to ground suggestions.
- Auto-split into `.claude/rules/`. Suggests it; you decide.
- Enforce a specific voice across repos. Each repo's voice is respected.

## Sibling Skills

| Skill | Use For |
|---|---|
| **`/claude-md improve`** | One file, structural rewrite for best-practice alignment |
| **`/claude-md audit`** | Many files, hygiene / drift / secret scan |
| `/init` (Anthropic built-in) | Generate a starter CLAUDE.md from current project state |
| `compound-engineering:ce-compound-refresh` | Same spirit, different target — refreshes `docs/solutions/` |

## References

- [Anthropic — How Claude remembers your project](https://code.claude.com/docs/en/memory)
- [Anthropic — Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)
- [Anthropic — How Anthropic teams use Claude Code (PDF)](https://www-cdn.anthropic.com/58284b19e702b49db9302d5b6f135ad8871e7658.pdf)
- [HumanLayer — Writing a Good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md)
- [zodchiii — The CLAUDE.md File That 10x'd My Output](https://x.com/zodchiii/status/2048683276194185640)
- Strunk & White — *The Elements of Style* (Rule 17, "Omit needless words" — upstream principle behind Anthropic's removability test)

## Credits

- Audit mode: drift / secret / hygiene patterns evolved from real-world portfolio audits (multiple projects with drifted CLAUDE.md; occasionally a leaked secret)
- Improve mode: rubric grounded in Anthropic's official Claude Code best-practice documentation; 5-canonical-section pattern formalized by zodchiii's viral thread
- Removability test: Anthropic Claude Code documentation, lineage to Strunk & White Rule 17
- Skill by: **Neal Meyer**

## License

MIT
