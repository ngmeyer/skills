# Six Pager

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-Skill-blueviolet?logo=anthropic)](https://claude.ai/code)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey)]()

A Claude Code skill that generates Amazon-style decision documents — narrative 6-pagers and PRFAQs (Press Release + FAQs) — with an embedded prose audit grounded in Strunk & White and Anthropic's removability test.

The format Amazon has used since 2004, when Bezos banned PowerPoint and required every meeting to open with a written narrative.

## Why This Exists

Three independent traditions converge on a single principle: **writing is the thinking instrument, not the documentation of it.**

- **Bezos (2004):** *"There is no way to write a six-page narratively structured memo and not have clear thinking."*
- **Strunk (1918):** *"Omit needless words. Vigorous writing is concise."*
- **Anthropic:** *"For every line, ask: If I removed this, would Claude make a mistake? If not, remove it."*

Same rule, three scales — line, sentence, instruction. This skill applies all three.

## Two Modes

```
/six-pager memo    → 6-page narrative memo (decisions, strategy, status)
/six-pager prfaq   → Press Release + External FAQ + Internal FAQ (launches)
```

Auto-detect: if input contains "launch" / "ship" / "announce" / "new product" → suggests prfaq. Otherwise → memo.

## Install

```bash
git clone https://github.com/ngmeyer/six-pager.git
cd six-pager

# Global install (available in all projects)
mkdir -p ~/.claude/skills/six-pager
cp SKILL.md ~/.claude/skills/six-pager/SKILL.md

# Or per-project install
mkdir -p .claude/skills/six-pager
cp SKILL.md .claude/skills/six-pager/SKILL.md
```

Use it in Claude Code:

```
/six-pager Should we migrate the API to cursor-based pagination?
/six-pager memo docs/q3-strategy-draft.md
/six-pager prfaq Acme AI assistant public launch
/six-pager --silent-read docs/pagination-decision.md    # generates margin questions
/six-pager --strunk-only docs/draft.md                  # audit only, no new structure
```

Trigger phrases: *six pager*, *6-pager*, *amazon memo*, *narrative memo*, *PRFAQ*, *press release*, *work backwards*, *decision memo*, *strategy doc*, *launch document*.

## The 6-Pager Structure (memo mode)

| Section | Length | Purpose |
|---|---|---|
| Introduction | ~0.5 pg | Document purpose, audience, ask |
| Goals | ~0.5 pg | Specific, measurable outcomes |
| Tenets | ~0.5 pg | Principles this proposal optimizes for (no qualifiers) |
| State of the Business | ~1.5 pg | Current data, named systems, concrete numbers |
| Lessons Learned | ~1 pg | What past attempts taught (specific events) |
| Strategic Priorities | ~2 pg | Recommended action, milestones, owners |
| Appendix | unlimited | Visuals, alt analyses, supporting data |

Hard cap: sections 1–6 fit in 6 pages of 11pt body text.

## The PRFAQ Structure (prfaq mode)

```
1. Press Release (~1 pg)
   - Customer-facing, benefit-led, dated for launch day
   - Headline + sub-headline + lede + problem + solution + quotes + CTA

2. External FAQ (~1 pg)
   - What journalists / customers would ask
   - Differentiation, pricing, availability, what it doesn't do

3. Internal FAQ (~1-2 pg)
   - What leadership would ask
   - Why now? Success metrics? Failure mode? What would kill this?
```

Work backwards — write the press release first. **The PRFAQ test:** if you can't write a credible press release, the product doesn't exist yet.

## The Prose Audit

Every document gets a Strunk + Anthropic audit. Findings categorized:

| Check | Rule | What it catches |
|---|---|---|
| Passive voice | Strunk R14 | "It was decided" → "We decided" |
| Vague language | Strunk R16 | "improvements" without a number |
| Needless words | Strunk R17 + Anthropic | "in order to" → "to" |
| Qualifiers | E.B. White | "rather," "very," "somewhat" — flag for deletion |
| Parallel construction | Strunk R19 | Inconsistent grammatical form in lists |
| Sentence-length monotony | Strunk R18 | 4+ same-length sentences in a row |
| Hedged Tenets | Bezos canon | "We try to" / "We strive to" — cut or rewrite |
| Removability | Anthropic | Paragraph that doesn't change reader's decision → cut |

## Flags

| Flag | Effect |
|---|---|
| `--silent-read` | After generation, produce an annotated version with 2-4 margin questions per section — simulates the 20-30 minute Amazon meeting silent-read |
| `--strunk-only` | Skip structural generation; treat input as existing draft and run only the prose audit |

## When to Use This vs Sibling Skills

| Skill | Use For |
|---|---|
| **`/six-pager memo`** | Decisions, strategy, status, "should we?" with stakes |
| **`/six-pager prfaq`** | Product / feature / launch ideas where customer outcome is the question |
| `/article-draft` | Long-form article in your voice |
| `/human-writing` | Voice / anti-AI-tells / banned-words audit (any prose) |
| `/council-review` | Open question with multiple valid answers (deliberation, not generation) |
| `/adversarial-review` | Stress-test a finished six-pager (or any artifact) |

**Natural pairing:** generate with `/six-pager`, stress-test with `/adversarial-review`, deliberate the recommendation with `/council-review`. Full Amazon-style decision pipeline.

## Quality Bar

A six-pager passes if **every** check is true:
- Page count ≤ 6 (memo) or correct sub-document length (prfaq)
- Every Goal has a number or verifiable outcome
- Every Tenet is a declarative commitment with no qualifiers
- State of Business cites ≥5 specific numbers / named systems / dated facts per page
- Strategic Priorities name at least one owner per priority
- Strunk audit: zero critical findings
- "What would cause us to kill this?" (PRFAQ Internal FAQ) has a real, specific answer — not "if performance suffers"

## What It Won't Do

- Exceed 6 pages. The constraint IS the value.
- Generate fake numbers. If a Goal needs a metric and the user hasn't supplied one, the skill asks.
- Hedge Tenets. A Tenet with "try to" is not a Tenet.
- Skip the audit. Prose discipline is not optional.
- Auto-save. Always confirms where to write.
- Generate prose articles. Use `/article-draft` or `/human-writing` instead.

## References

- Bryar & Carr — *Working Backwards: Insights, Stories, and Secrets from Inside Amazon* (St. Martin's Press, 2021)
- Strunk & White — *The Elements of Style*, 4th edition (Pearson Allyn & Bacon, 2000)
- Tufte — *The Cognitive Style of PowerPoint* (2003)
- [Anthropic — Claude Code Best Practices](https://code.claude.com/docs/en/best-practices) — the removability test
- [Slab — How Bezos Turned Narrative Into Amazon's Competitive Advantage](https://slab.com/blog/jeff-bezos-writing-management-strategy/)

## Credits

- Format: Amazon's 6-pager and PRFAQ practice, established 2004
- Prose discipline: Strunk & White (1918, 1959, 2000)
- Removability test: Anthropic Claude Code documentation
- Skill by: **Neal Meyer**

## License

MIT
