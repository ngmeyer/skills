---
name: six-pager
description: >
  Generate decision memos and product launch documents in Amazon's narrative style.
  Two modes: `memo` produces a 6-page narrative memo (Introduction, Goals, Tenets, State of
  Business, Lessons Learned, Strategic Priorities + unlimited appendix); `prfaq` produces a
  Press Release + External FAQ + Internal FAQ for product launches (work backwards from launch).
  Enforces Strunk's prose rules (active voice, concrete language, omit needless words, no
  qualifiers, parallel construction, topic-sentence paragraphs, no overstatement) and Anthropic's
  removability discipline at the line level.
  Use when: 'six pager', '6-pager', 'amazon memo', 'narrative memo', 'PRFAQ', 'press release',
  'work backwards', 'decision memo', 'strategy doc', 'launch document', 'silent read doc',
  before any decision big enough to warrant the week-long writing process.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep"]
argument-hint: "[topic, draft, or file path] [memo|prfaq] [--silent-read] [--strunk-only]"
---

# /six-pager -- Amazon-style Narrative Memo and PRFAQ

Generate decision documents in the format Amazon has used since June 9, 2004 — when Bezos banned PowerPoint and required every meeting to open with a written narrative.

This skill produces the document. It does not replace the discipline. The original Amazon practice takes a week (draft → review → set aside → edit → final). The skill compresses the structure but preserves the prose-quality bar.

## Why This Works

Three independent traditions converge on a single principle: **writing is the thinking instrument, not the documentation of it.**

- **Bezos (Amazon, 2004):** *"There is no way to write a six-page narratively structured memo and not have clear thinking."*
- **Strunk (1918, restated by E.B. White 1959):** *"Vigorous writing is concise. A sentence should contain no unnecessary words, a paragraph no unnecessary sentences, for the same reason that a drawing should have no unnecessary lines and a machine no unnecessary parts."* (Rule 17)
- **Anthropic ([Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)):** *"For every line, ask: If I removed this, would Claude make a mistake? If not, remove it."*

Same rule, three scales: line, sentence, instruction. This skill enforces all three.

## When to Use This vs Sibling Skills

| Skill | Use For | Mode |
|---|---|---|
| **`/six-pager memo`** | Decisions, strategy, status, "should we?" with stakes | Narrative memo, 6 sections, hard 6-page cap |
| **`/six-pager prfaq`** | Product / feature / launch ideas where customer outcome is the question | Press release + 2 FAQs, work backwards from launch |
| a long-form writing/voice skill | Prose essays, narrative, sensory writing | Long-form drafting, not decision-doc structure |
| `/council-review` | Open question with multiple valid answers | Multi-agent deliberation, not document generation |
| `/adversarial-review` | Stress-test a finished artifact (including a six-pager!) | Single-critic attack mode |

**Natural pairing:** Generate the document with `/six-pager`, then stress-test with `/adversarial-review`, then deliberate the recommendation with `/council-review`. That's the full Amazon-style decision pipeline.

## Arguments

- **Argument 1 (required):** The topic, draft, or file path. One of:
  - A short topic statement: `"Should we migrate the API to cursor-based pagination?"`
  - A path to an existing draft: `docs/pagination-decision-draft.md`
  - A pasted block of context
- **Mode flag (optional):** `memo` (default for decisions) or `prfaq` (for launches). If omitted, the skill auto-classifies and asks to confirm.
- **`--silent-read`:** Adds a 20-30 minute "silent read" simulation to the output — produces an annotated version with margin questions a senior reviewer would write.
- **`--strunk-only`:** Skips structural generation; treats the input as an existing draft and runs only the Strunk + Anthropic prose audit. Useful for cleaning up an in-flight document.

## Procedure

### Phase 1: SCOPE

1. Parse flags from `$ARGUMENTS`.
2. Classify the input:
   - **Topic** — short statement, no draft. Generate from scratch.
   - **File path** — existing draft. Read it; treat as starting point.
   - **Pasted text** — treat as starting context.
3. If mode flag is missing:
   - Auto-classify: input contains "launch" / "ship" / "announce" / "new product" / "release" → suggest `prfaq`. Otherwise → suggest `memo`.
   - Confirm with the user before proceeding.
4. Confirm scope back to the user in one sentence: *"Producing [memo|prfaq] for [topic]. [Optional: --silent-read enabled.]"*

### Phase 2: DRAFT

#### Mode: `memo` (6-pager)

Generate the six canonical sections. Each section has a specific purpose and a strict prose discipline:

1. **Introduction (~0.5 page)** — What is this document? Who is the audience? What is the ask? Frame the decision in one paragraph.
2. **Goals (~0.5 page)** — Specific, measurable outcomes. Each goal must be verifiable. Numbers required where possible.
3. **Tenets (~0.5 page)** — The principles this proposal optimizes for. **No qualifiers** (per Strunk's "avoid leeches" reminder). Tenets are unhedged commitments. Format: `1. [Tenet name]: [single declarative sentence].`
4. **State of the Business (~1.5 pages)** — Current data. Honest. Concrete numbers, named systems, dated facts. **Apply Strunk Rule 16** (definite, specific, concrete) ruthlessly.
5. **Lessons Learned (~1 page)** — What did past attempts teach? What is different this time? Each lesson cites a specific past event or experiment, not abstract principles.
6. **Strategic Priorities (~2 pages)** — The recommended action and rationale. Specific milestones, owners, timelines.
7. **Appendix (unlimited)** — Visuals, supporting data, alternative analyses considered and rejected (with reasons).

**(V2) Premortem (required in Strategic Priorities or the Appendix).** Assume it is 12 months later and this decision *failed*. Write the 3 most likely causes, working backward from the failure. This is forward-looking risk-finding that "Lessons Learned" (backward-looking) structurally misses — Kahneman's single highest-value decision technique, and it pairs with the verification: each premortem cause should map to a thing you'll monitor. Not generic "risks" — concrete failure scenarios.

**Hard constraint:** sections 1-6 combined must fit in 6 pages of 11pt body text. The skill renders a page count and warns if over.

#### Mode: `prfaq` (Press Release + FAQs)

Generate three sub-documents. **Work backwards** — write the press release first, as if the product already shipped.

1. **Press Release (~1 page)** — Customer-facing language. Benefit-led. Dated for the (hypothetical) launch day. Format follows Amazon's internal PR conventions:
   - Headline (one line, customer-outcome-oriented)
   - Sub-headline (one line, who-it's-for + key-benefit)
   - Lede paragraph (city, date, "Today X announced Y...")
   - Problem paragraph (what was hard before this product existed)
   - Solution paragraph (how the product solves the problem)
   - Customer quote (fictional but realistic)
   - Internal quote (from the team, on why this matters)
   - Call to action / availability
2. **External FAQ (~1 page)** — Questions a journalist or customer would ask:
   - What is this?
   - How is it different from [obvious alternative]?
   - How much does it cost?
   - When can I get it?
   - What does it not do?
3. **Internal FAQ (~1-2 pages)** — Questions Amazon-style leadership would ask:
   - Why now?
   - What does success look like? (specific metrics, specific dates)
   - What are the dependencies?
   - What is the failure mode?
   - What are we choosing not to build?
   - What would cause us to kill this?

**The PRFAQ test:** if you can't write a credible press release, the product doesn't exist yet — not in the form that matters.

### Phase 3: CONSTRAIN

After Phase 2 produces a draft, measure it:

```bash
# rough page count: assume 450 words/page at 11pt
WORDS=$(wc -w < draft.md)
PAGES=$(echo "scale=1; $WORDS / 450" | bc)
```

If over budget:
- For `memo`: identify the longest section, propose 30pct cuts that preserve load-bearing content
- For `prfaq`: identify whichever FAQ sub-section ran long; propose merging or trimming questions

Never silently truncate. Always show the user what's being proposed for cuts and why.

### Phase 4: AUDIT (Strunk + Anthropic)

Run the prose-quality audit on the draft. Each finding cites the rule:

| Check | Rule | Action |
|---|---|---|
| **Passive voice** | Strunk R14 | Flag every passive construction; suggest active rewrite |
| **Vague language** | Strunk R16 | Flag every "improvements," "various," "some," "many" without a number; demand specificity |
| **Needless words** | Strunk R17 + Anthropic removability | Flag wordy phrases ("in order to" → "to"; "due to the fact that" → "because") |
| **Qualifiers** | E.B. White's "leeches" reminder | Flag every "rather," "very," "little," "pretty," "quite," "somewhat" — propose deletion |
| **Parallel construction** | Strunk R19 | Flag inconsistent grammatical forms in lists / tenets / goals |
| **Sentence-length monotony** | Strunk R18 | Flag stretches of 4+ sentences within 5 words of each other; propose variation |
| **Topic sentence** | Strunk R13 | Flag any paragraph that buries its claim under setup. Lead each paragraph with its point — one paragraph = one step in the argument. The core narrative-memo discipline |
| **Overstatement** | E.B. White, *do not overstate* | Flag carefree superlatives and unhedged hype ("massive," "revolutionary," "huge," "game-changing"). A single one puts the reader on guard and taints the rest — demand the number or cut |
| **Tenets with hedges** | Bezos canon | Tenets are commitments. "We try to optimize for X" → "We optimize for X" or cut |
| **Removability test** | Anthropic | For each paragraph: would removing it cause the reader to make a wrong decision? If not, cut. |

Produce a structured audit report:
```
## Prose Audit (Strunk + Anthropic)

**Findings:** N critical, M important, K nit

### Critical (block the document)
- Line 23: passive voice in Strategic Priorities ("It was decided that...") → "We decided to..."
- Line 47: vague Goal ("improve performance") → demand a number
- Tenet 3 hedges ("We strive to be customer-obsessed") → cut "strive to" or cut the tenet

### Important (fix in next pass)
- 4 sentences in a row of 18-22 words in State of Business → vary
- Parallel-form break in Goals: 3 noun-phrase goals + 1 verb-phrase goal
- State of Business ¶2 buries its claim in the final sentence → lead the paragraph with it
- Overstatement in Introduction ("a massive, game-changing opportunity") → name the number or cut

### Nit
- "in order to" appears 3 times → "to"
- "various improvements" → name them or cut
```

### Phase 5: PRESENT

Show the user:
1. Final document (or draft with audit annotations if `--silent-read`)
2. Page count vs budget
3. Audit summary (count of critical/important/nit findings)
4. Side-by-side: original draft vs proposed rewrites for any audit findings

Ask: **"Apply the audit fixes? (yes / partial / no)"**

If yes: apply fixes in place (surgical Edits if input was a file; show new full document otherwise).
If partial: walk through each fix individually.
If no: deliver the unaudited draft with a note that audit was skipped.

### Phase 6: SAVE

Default save path: alongside the input file (if file input) or `<cwd>/six-pager-<topic-slug>-<YYYY-MM-DD>.md`.

If `--silent-read` was used, also produce `<same-name>-annotated.md` with margin questions in HTML comments or callout blocks.

## The Silent-Read Simulation (`--silent-read`)

The original Amazon meeting protocol: distribute the document at the start of the meeting (NOT pre-read), 20-30 minutes of silent reading with pens out, then discussion anchored to specific page/line annotations.

When `--silent-read` is enabled, after generating the document the skill simulates the silent read by producing a second pass:

For each section, generate 2-4 questions a senior reviewer would write in the margin. Examples:
- *"How confident is the 23pct number? Is this measured or estimated?"*
- *"Tenet 2 contradicts Tenet 4 — which wins when they conflict?"*
- *"Lesson Learned #3 says the prior attempt failed because of X. What evidence?"*
- *"Strategic Priority #1 has no owner named."*

This catches the "writer thinks it's clear; reader doesn't" failure mode before the actual meeting.

## Quality Bar

A six-pager passes if **every** check is true. Otherwise iterate.

- Page count ≤ 6 (memo) or correct sub-document length (prfaq)
- Every Goal has a number or specific verifiable outcome
- Every Tenet is a declarative commitment with no qualifiers
- State of Business cites at least 5 specific numbers / named systems / dated facts per page
- Strategic Priorities name at least one owner per priority
- Strunk audit: zero critical findings (passive voice, vague Goals, hedged Tenets); important findings acceptable with rationale
- The "what would cause us to kill this?" question (PRFAQ Internal FAQ) has a real, specific answer — not "if performance suffers"

## Gotchas

- **Do not exceed 6 pages.** The constraint IS the value. If it doesn't fit, the thinking isn't done.
- **Do not pad State of Business with backstory.** Current data only. History belongs in Lessons Learned.
- **Do not hedge Tenets.** A Tenet with "try to" or "strive to" is not a Tenet.
- **Do not generate fake numbers.** If the Goal needs a metric and the user hasn't supplied one, ask. Generic placeholders ("X%") are not acceptable.
- **Do not confuse Goals with Tenets.** Goals are outcomes (measurable). Tenets are principles (commitments). Both are needed; conflating them muddles thinking.
- **Do not skip the audit.** Phase 4 is not optional. The whole point is prose discipline plus structure.
- **Do not auto-save.** Phase 6 confirms with the user where to write.
- **Do not invoke this for prose articles.** Use a dedicated long-form writing/voice skill instead — this skill is for decision docs, not essays.

## Changelog

### V2 (2026-05-27)
Optimized via `skillforge optimize` (outcome research: decision-memo efficacy + decision science). six-pager was already strong; this is a focused, non-duplicative add:
- **Required premortem** in memo mode — forward-looking "assume it failed, why?" failure analysis, each cause tied to a verification signal. Closes the gap that "Lessons Learned" (backward-looking) leaves open. Kahneman's highest-value decision technique; same decision-science line that informed council-review V2.
- Outcome target: memos that surface the killer risk *before* the decision, not after. Sources: Kahneman (premortem); Amazon narrative practice (silent read, customer-back); grounded in the same decision-science line (premortem, mediating assessments).

## References

**Bezos / Amazon canon:**
- Bryar, Colin & Carr, Bill — *Working Backwards: Insights, Stories, and Secrets from Inside Amazon* (St. Martin's Press, 2021) — canonical book
- [Slab — How Jeff Bezos Turned Narrative into Amazon's Competitive Advantage](https://slab.com/blog/jeff-bezos-writing-management-strategy/)
- [Maestra — How to Write an Amazon 6-Pager (with Template)](https://maestra.ai/blogs/how-to-write-an-amazon-6-pager)
- [Anecdote — What might Amazon's 6 page narrative structure look like?](https://www.anecdote.com/2018/05/amazons-six-page-narrative-structure/)

**Strunk & White canon:**
- Strunk, William Jr. & White, E.B. — *The Elements of Style*, 4th edition (Pearson Allyn & Bacon, 2000)
- Public-domain text of Strunk's 1918 original: [Bartleby — The Elements of Style](https://www.bartleby.com/141/)

**Anthropic prose-discipline:**
- [Anthropic — Claude Code Best Practices](https://code.claude.com/docs/en/best-practices) — the removability test

**Cognitive-style background:**
- Tufte, Edward — *The Cognitive Style of PowerPoint* (2003) — the case against bullet-points

## Testing

This is a prompt-only skill. The shipped `tests/eval.sh` asserts the structural contract. To verify behavior end-to-end:

1. Pick a real decision: `"/six-pager Should we migrate the API to cursor-based pagination?"` (memo mode)
2. Verify all 6 sections generated, page count ≤ 6, audit run with findings
3. Pick a launch idea: `"/six-pager prfaq Acme AI assistant public launch"` (PRFAQ mode)
4. Verify press release + 2 FAQs generated, "what would cause us to kill this?" has a real answer
5. Run `--strunk-only` on an existing draft: verify only the audit fires, no new structure generated
6. Run `--silent-read`: verify margin questions are produced for each section
