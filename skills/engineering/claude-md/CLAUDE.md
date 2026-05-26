# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

`/claude-md` is a Claude Code skill that combines two modes for CLAUDE.md file management:
- **audit** — multi-file hygiene scan (drift, secrets, duplicates, budget)
- **improve** — single-file structural rewrite (10-rule rubric, surgical Edits)

Replaces the older standalone `claude-md-audit` and `claude-md-improve` skills (consolidated 2026-04-29).

**Repo:** github.com/ngmeyer/claude-md
**Author:** Neal Meyer

## File Structure

```
claude-md/
├── SKILL.md      # The executable skill — this IS the product
├── README.md     # GitHub-facing documentation
├── LICENSE       # MIT
├── CLAUDE.md     # This file
└── tests/
    ├── eval.sh         # Structural eval (asserts BOTH modes' contracts)
    ├── README.md       # What's tested vs deferred
    └── fixtures/       # Sample CLAUDE.md files for future runtime tests
```

## Architecture

This is a **prompt-only skill** — no runtime code, no dependencies. The entire product is `SKILL.md`.

### Mode Dispatch

```
/claude-md (no args)            → auto-detect:
                                    cwd has ./CLAUDE.md?  → improve mode
                                    no local file?        → audit all
/claude-md improve [path]       → improve mode (single file)
/claude-md audit [scope|path]   → audit mode (multi-file or single)
```

### Improve Mode (5 phases, 10-rule rubric)

```
Phase I-1: SCOPE    — resolve target file, read siblings for tier-duplication
Phase I-2: MEASURE  — 10-rule rubric scorecard with line-level evidence
Phase I-3: PROPOSE  — structured diff (deletions, additions, rewrites)
Phase I-4: PRESENT  — summary + diff, await yes/partial/no
Phase I-5: APPLY    — surgical Edit-tool changes, one at a time
```

### Audit Mode (7 phases + hook-candidate sub-phase)

```
Phase A-1: DISCOVER          — find all CLAUDE.md files under your projects roots (e.g. ~/Projects)
Phase A-2: SECRET SCAN       — P0 leaks (ALWAYS first; interrupts other audit)
Phase A-3: DRIFT DETECTION   — claimed facts vs real code
Phase A-4: DUPLICATES        — heading + paragraph repetition
Phase A-5: BUDGET + RATIO    — instruction count + descriptive vs prescriptive
Phase A-5.5: HOOK CANDIDATES — flag deterministic-sounding rules for hook conversion
Phase A-6: REPORT            — grouped by severity, per project
Phase A-7: OFFER FIXES       — interactive; never auto-apply leak fixes
```

### Key Design Decisions

- **Single skill, explicit modes.** Replaces two near-neighbor skills with one entry in the trigger registry. Reduces ambiguity.
- **Removability test as the unifying principle.** Audit flags violations; improve proposes their removal. Same diagnostic, different scale. Genealogy: Strunk Rule 17 → Anthropic Best Practices.
- **P0 LEAK detection ALWAYS first in audit mode.** A secret in CLAUDE.md is a durable git-history leak; everything else waits until that's flagged.
- **No auto-apply.** Both modes always present for approval. Surgical Edits, never whole-file Write. Audit never auto-applies leak fixes (those require secret rotation + git-history scrub the user must drive).
- **Reads project data to ground suggestions.** `package.json`, `pyproject.toml`, `Cargo.toml`, `Gemfile`, `README.md` — generic placeholders are unacceptable.
- **Anthropic-source-grounded.** Every rubric rule cites a primary source (mostly code.claude.com/docs).

### Distinction from sibling skills

| Skill | When |
|---|---|
| `/claude-md improve` | One file, structural rewrite |
| `/claude-md audit` | Many files, hygiene scan |
| `/init` (Anthropic built-in) | Greenfield generation |
| `compound-engineering:ce-compound-refresh` | Same spirit, different target — `docs/solutions/` |

### Portability Requirements

- **No hardcoded user paths.** Use `$TARGET`, `$HOME`, `$1`. Never `/Users/<name>/...` or `/home/<name>/...`.
- **Cross-platform.** Pure bash + standard Unix tools. No `date -v` or `date -d`.
- **Graceful skip.** If sibling files don't exist, skip with a note.

## Editing Guidelines

- **SKILL.md is the product.** Changes to SKILL.md change behavior for all users.
- **Prompt changes are code changes.** The 10-rule rubric, the 5 canonical sections, the 7 audit phases, and the secret-pattern list are load-bearing — test before shipping.
- **Don't add runtime dependencies.** Must remain a single markdown file.
- **Keep the rubric ≤10 rules.** More than that crosses into noise. If a new best practice emerges, replace a weaker rule, don't append.
- **Cite sources for every rule.** No "common knowledge" rules — if there's no source, don't include it.
- **Both modes must remain mode-aware.** A change to improve mode shouldn't break audit and vice versa.

## Testing

Run the structural eval:

```bash
bash tests/eval.sh
```

To verify behavior end-to-end:

1. Improve: `/claude-md improve` in any project — verify rubric scorecard cites every R1–R10, every change cites its rule, "no" reply writes nothing
2. Audit: `/claude-md audit all` — verify P0 LEAK section appears first when leaks present, drift findings cite specific code locations
3. Auto-detect: `/claude-md` in a project with CLAUDE.md → improve runs; in `~/` → audit runs
4. Mode override: `/claude-md audit ./CLAUDE.md` → single-file audit

## Commit Style

Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`
