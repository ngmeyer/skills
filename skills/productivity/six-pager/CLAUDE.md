# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

Six Pager is a Claude Code skill that generates Amazon-style decision documents (narrative 6-pagers and PRFAQs) with an embedded Strunk + Anthropic prose audit. Two modes: `memo` for decisions, `prfaq` for launches. Sibling to `/article-draft` (long-form article voice), `/human-writing` (style audit), `/council-review` (deliberation), `/adversarial-review` (stress test).

**Repo:** github.com/ngmeyer/six-pager
**Author:** Neal Meyer

## File Structure

```
six-pager/
├── SKILL.md      # The executable skill — this IS the product
├── README.md     # GitHub-facing documentation
├── LICENSE       # MIT
├── CLAUDE.md     # This file
└── tests/
    ├── eval.sh         # Structural eval (asserts SKILL.md design contract)
    ├── README.md       # What's tested vs deferred
    └── fixtures/       # Sample drafts for future runtime tests
```

## Architecture

This is a **prompt-only skill** — no runtime code, no dependencies. The entire product is `SKILL.md`.

### 6-Phase Execution

```
Phase 1: SCOPE     — classify input (topic, file, paste); pick mode (memo|prfaq); confirm
Phase 2: DRAFT     — generate canonical structure (6 sections OR press release + 2 FAQs)
Phase 3: CONSTRAIN — measure page count; propose cuts if over budget
Phase 4: AUDIT     — Strunk + Anthropic prose audit, structured findings
Phase 5: PRESENT   — show document + audit; ask for fix application
Phase 6: SAVE      — write to disk after user confirms path
```

### Key Design Decisions

- **Three traditions converge on one principle.** Bezos's "narrative forces clarity," Strunk's "omit needless words," and Anthropic's removability test are the same rule at three scales. The skill cites all three explicitly.
- **Hard 6-page cap is non-negotiable.** The constraint IS the value. Skill warns and proposes cuts; never silently truncates.
- **No fake numbers.** If a Goal needs a metric and the user hasn't supplied one, ask. Generic placeholders are unacceptable.
- **Tenets are unhedged commitments.** "We try to optimize for X" → "We optimize for X" or cut. Strunk's "avoid qualifiers" reminder applied to Bezos's tenet discipline.
- **PRFAQ tests product existence.** If you can't write a credible press release, the product doesn't exist yet — not in the form that matters.
- **Audit is mandatory.** Phase 4 is not optional. The whole point is prose discipline + structure together, not one or the other.
- **Sibling-aware.** Cites /council-review, /adversarial-review, /article-draft, /human-writing as natural pairings. The "decision pipeline" is generate → stress-test → deliberate.

### Distinction from sibling skills

| Skill | When | Mode |
|---|---|---|
| `/six-pager memo` | Decisions, strategy | Format generation |
| `/six-pager prfaq` | Launches | Format generation |
| `/article-draft` | Long-form articles | Voice generation |
| `/human-writing` | Any prose | Style audit |
| `/council-review` | Open questions | Multi-agent deliberation |
| `/adversarial-review` | Finished artifacts | Single-critic stress test |

### Portability Requirements

- **No hardcoded user paths.** Use `$INPUT`, `$HOME`, `$1`. Never `/Users/<name>/...`.
- **Cross-platform.** Pure bash + python3 for any math (page-count estimation). No `date -v` or `date -d`.
- **Graceful skip.** If input is unclassifiable, ask the user instead of guessing.

## Editing Guidelines

- **SKILL.md is the product.** Changes to SKILL.md change behavior for all users.
- **Prompt changes are code changes.** The 6 phases, 2 modes, 8 audit checks, and Quality Bar items are load-bearing — test before shipping.
- **Don't add runtime dependencies.** Must remain a single markdown file.
- **Cite the three traditions for every audit rule.** Bezos, Strunk, or Anthropic — every check has a source.
- **Keep the 6-section memo structure verbatim.** Introduction / Goals / Tenets / State of Business / Lessons Learned / Strategic Priorities + Appendix. This is the Amazon canonical structure; don't drift.

## Testing

Run the structural eval:

```bash
bash tests/eval.sh
```

To verify behavior end-to-end:

1. Real decision: `/six-pager Should we migrate the API to cursor-based pagination?` — verify 6 sections, page count ≤ 6, audit run
2. Launch idea: `/six-pager prfaq Acme AI assistant public launch` — verify PR + 2 FAQs, "what kills this?" has real answer
3. Existing draft: `/six-pager --strunk-only docs/draft.md` — verify only audit fires, no new structure
4. Annotated mode: `/six-pager --silent-read decision.md` — verify margin questions per section

## Commit Style

Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`
