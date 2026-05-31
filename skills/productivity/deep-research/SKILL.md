---
name: deep-research
description: >
  Multi-source deep research that produces a cited, confidence-scored brief.
  Searches across Exa, Tavily, and web in parallel; extracts atomic claims with
  quote-grounded citations, scores confidence by independent-source count,
  surfaces contradictions, and verifies key claims before delivering. Works with
  zero API keys (WebSearch fallback), improves with each provider added.
  Use when: 'research this', 'deep research', 'investigate', 'what do we know
  about', 'find out about', 'look into', or any open-ended research question.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Bash", "Agent", "WebFetch", "WebSearch", "mcp__claude_ai_Tavily__tavily_search", "mcp__claude_ai_Tavily__tavily_extract", "mcp__claude_ai_Tavily__tavily_research", "mcp__claude_ai_Exa__web_search_exa", "mcp__claude_ai_Exa__web_fetch_exa"]
argument-hint: "<topic or question> [--quick] [--deep] [--agent] [--save path/to/output.md]"
---

# Deep Research — Multi-Source Research with Cross-Referencing

Research any topic across multiple search providers simultaneously. Produces a confidence-scored research brief with quote-grounded citations, cross-referenced findings, an evidence matrix, surfaced contradictions, and a verification pass that re-checks the load-bearing claims before they reach you.

## Core Design

**Three phases with an interactive planning step.** Complexity lives in search quality, faithful grounding, and honest calibration — not pipeline overhead.

```
PLAN (interactive) → DISCOVER (parallel) → SYNTHESIZE (claims → matrix → brief) → VERIFY (--deep: chain-of-verification)
```

**The brief is only as good as its weakest claim.** Two failure modes sink a research brief: a citation that points at the wrong claim (or a source that doesn't exist), and false confidence from sources that only *look* independent. The procedure below is built to prevent both — quote-grounded citations, independence-aware confidence, and a verification pass that re-checks claims with the draft hidden.

**Graceful degradation.** Works with zero API keys using Claude's built-in WebSearch. Each additional provider (Tavily, Exa) adds coverage without changing the workflow.

| Provider | Best At | Requires |
|----------|---------|----------|
| WebSearch | General queries, broad coverage | Nothing (built-in) |
| Tavily | Structured retrieval, recent events, RAG-native output | Tavily MCP connected |
| Exa | Semantic/conceptual search, academic content, "find similar" | Exa MCP connected |

> **Provider names vary.** The `allowed-tools` list names the Tavily/Exa MCP tools as exposed by the claude.ai connectors. If your Tavily/Exa MCP is connected under different tool names, the skill still works — it detects providers by trying them (Phase 1) and falls back to WebSearch. No provider is required.

## Modes

| Mode | Flag | Sources | Verify | Best For |
|------|------|---------|----------|----------|
| **Quick** | `--quick` | 3-5 | Grounding audit | Fast answers, gut-checks |
| **Standard** (default) | none | 8-15 | Grounding audit | Most research questions |
| **Deep** | `--deep` | 15-30 | Full chain-of-verification + loop-back | High-stakes, publishable research |
| **Agent** | `--agent` | Standard | Grounding audit | Autonomous, non-interactive |

Combine flags: `--deep --save docs/research/topic.md`

## Arguments

- **Argument 1 (required):** Research topic or question
- **`--quick`:** Fast mode, fewer sources, grounding audit only
- **`--deep`:** Thorough mode, more sources, full chain-of-verification with loop-back
- **`--agent`:** Non-interactive, saves report without asking, exits cleanly
- **`--save <path>`:** Write the research brief to this file path

---

## Procedure

### Phase 0: Frame the Research

Parse flags from `$ARGUMENTS`. Remove flags, remainder is the research topic.

**Classify the query type:**

| Type | Signal | Affects Search Strategy |
|------|--------|------------------------|
| **Factual** | "What is...", "When did...", "How does..." | Prioritize authoritative/primary sources, verify facts |
| **Comparative** | "X vs Y", "compare", "difference between" | Run parallel searches for each entity |
| **Exploratory** | "What's happening with...", "state of..." | Cast wide net, prioritize recency |
| **Forecasting** | "Will...", "future of...", "predictions" | Include prediction markets, expert opinions, flag uncertainty |

**Generate 2-4 search perspectives** (STORM pattern — the highest-impact coverage lever, more than adding providers). For "state of AI agents in 2026", generate:
- Technical: "AI agent frameworks architectures 2026"
- Market: "AI agent companies funding revenue 2026"
- Practitioner: "AI agent developer experience pain points 2026"
- Contrarian: "AI agent limitations failures overhyped 2026"

Each perspective becomes a parallel search query **and a coverage checkbox** — Phase 1 isn't done until every perspective is answered or proven unanswerable.

### Phase 0b: Research Plan (interactive, skip in --quick and --agent)

Before searching, present a structured plan for approval — the single most impactful quality lever.

```
## Research Plan: [Topic]

I'll investigate these angles:
1. [Subtopic A] — [what we're looking for, which perspective]
2. [Subtopic B] — [what we're looking for]
3. [Subtopic C] — [contrasting viewpoint or edge case]
4. [Subtopic D] — [practical/applied angle]

Estimated: [N] sources across [available providers].

Adjust this plan or say "go" to start.
```

The user can add/remove subtopics, refine scope, or approve. Each approved subtopic becomes a search perspective. In `--quick`/`--agent`: skip the plan, use auto-generated perspectives.

### Phase 1: DISCOVER — Parallel Multi-Source Search

**Detect available providers** by attempting each tool. If a call fails with "not available," fall back gracefully.

**Search strategy by provider:**

```
For each search perspective (2-4 queries):
  WebSearch (always available): search, then WebFetch top 2-3 for full content
  Tavily (if available): tavily_search depth="advanced", tavily_extract on best URLs
  Exa (if available): web_search_exa for semantic matches, web_fetch_exa on top results
  Deduplicate by URL across providers.
```

**Source targets by mode:** Quick 3-5 unique · Standard 8-15 · Deep 15-30.

**For each source, capture:** URL · Title · Author · **Date** (critical — see staleness) · Source type (`academic`/`news`/`blog`/`official`/`social`/`forum`) · **Tier** (`primary`/`secondary`/`unknown`) · Full content or relevant excerpt.

**Credibility via SIFT lateral reading** (not a per-source CRAAP score — checklist scoring causes overload and underperforms lateral reading):
- **Investigate** the source in one line — who published it, what's their stake.
- **Find** corroboration — does ≥1 *independent* source confirm the key claim?
- **Trace** any statistic/quote to its primary origin and cite *that*, not the outlet that repeated it.
- Tag each source `primary | secondary | unknown`. Prefer primary > reputable secondary > unknown.

**Gap-driven loop (avoid redundant and premature search).** After each round, write a one-line ledger: **Known / Unknown / Contradicted**. Generate next queries only for Unknown/Contradicted. Keep a list of already-issued queries and never repeat one. **Stop when** (a) every perspective is answered at ≥MEDIUM confidence or marked unanswerable, AND (b) the last round surfaced no origin-new sources. (Standard: ≤2 rounds; Deep: ≤4.)

**Write-after-every-search rule:** after each batch, write a brief progress note. Prevents agent loops and ensures partial results survive context compaction.

### Phase 2: SYNTHESIZE — Claims, Matrix, Brief

Process all sources in a synthesis pass. Build structure *before* prose.

**Step 2a: Assign IDs and extract atomic claims (with quote spans)**

Assign each source an ID (`S1`, `S2`, …). For each source, extract discrete *atomic* claims — one subject-predicate-value each. A sentence that is mostly true but carries one unsupported rider must be split so the rider can be dropped.
- YES: "Tavily was acquired by Nebius in February 2026" `[S3]`
- NO: "Tavily is a popular search tool" (vague, not falsifiable)

**Each claim must carry a verbatim quote span** (≤25 words, in quotation marks) from the source that supports it, plus the source's date. If you cannot produce a real supporting quote from a source you actually fetched, you may not assert the claim. Each finding gets an ID (`F1`, `F2`, …).

> **Never validate a citation from memory.** A claim's cite is only valid if you fetched that source this run and it contains the quote span. Don't reason about whether a cite "looks right" — match the quote against fetched content. (Memory-based citation validation has ~16% recall; re-checking against the source is the only reliable method.)

**Step 2b: Coreference pass — group related claims.** Merge claims that describe the same phenomenon under different terms, and **record the aliases in the Terminology Map** (two sources naming one mechanism differently is a finding, not two findings); keep meaningfully-different claims separate.

**Step 2c: Independence grouping (before scoring confidence).** Two sources are *independent* only if they have distinct origins. Sources that cite the same study/press release, quote identical wording, or syndicate one wire story count as **one** source for confidence. Assign each supporting source to an independence group; confidence stacks on *groups*, not raw source count. This defeats false triangulation — the most common way a brief earns unearned confidence.

**Step 2d: Score confidence (rubric, not a vibe).**

| Confidence | Criteria | Marker |
|------------|----------|--------|
| **High** | ≥2 *independent origin groups* agree, no unresolved contradiction | (none) |
| **Medium** | 1 high-tier source, or multiple same-origin/low-tier | *(medium confidence)* |
| **Low** | single low-tier source, or model inference not directly stated | *(unverified)* |
| **Conflicting** | independent sources directly disagree | *(sources conflict — see Evidence Matrix)* |

**Abstain rather than hedge.** If no claim on a sub-question reaches MEDIUM, write *"Evidence insufficient — [what's missing]"* for that sub-question. Do not promote a LOW claim to a finding to avoid a gap.

**Step 2e: Build the evidence matrix — then write *from* it.** Build the claims×sources table before any prose. Write the brief by reading **down** claims (what's multiply-supported, what's lonely, where conflicts sit) — not **across** sources (a list). Every High-confidence claim must have ≥2 independent supporting cells.

**Step 2f: Write the brief.** Separate **Sourced** lines (every line cited `[S#]`) from **Analysis** (your own synthesis/inference, explicitly marked). No Analysis claim appears in Key Findings or the summary without a hedge. Stamp dates; add a **staleness flag** if the newest source predates a margin that matters for a fast-moving topic.

```markdown
# Research Brief: [Topic]

*[N] sources across [providers]. [Date]. Mode: [quick/standard/deep].*
*Staleness: newest source dated [YYYY-MM]; developments after that are not captured.*

## Key Findings

### F1: [Atomic claim as title]
[1-3 sentence synthesis, each factual sentence cited [S1], [S3]. Quote span on load-bearing claims.]
**Confidence:** High (≥2 independent origins) | **Cross-refs:** Extends F2. Contradicts F4 on [dimension].
[When a claim rests on one origin echoed by several outlets, say so in prose — "rests on a single company statement repeated by [S1][S2][S3]" — rather than counting them.]

[5-10 findings standard, 3-5 quick, 10-15 deep]

## Evidence Matrix
| Finding | S1 | S2 | S3 | S4 | S5 |
|---------|:--:|:--:|:--:|:--:|:--:|
| F1 | + | | + | | + |
*Legend: + supports, - contradicts, blank = not addressed*

## Analysis
[2-4 paragraphs. What the findings MEAN together, not a re-list. Flag where evidence is strong vs thin. Reference findings by ID. This section is your reasoning — marked as such, not a sourced fact.]

## Contradictions & Tensions
[Cluster sources by their answer. If clusters disagree, present BOTH — don't pick silently:]
> **F2 vs F3:** [S2] (secondary, 2025-03) claims X; [S5] (primary, 2026-01) found the opposite. Higher-tier + more recent leans F3, but flagged.

## Terminology Map
[Include ONLY when sources name the same concept differently — omit otherwise. From Step 2b.]
| Canonical term | Also called (by source) |
|---|---|
| [term] | "[alt1]" [S1], "[alt2]" [S3] |

## Knowledge Gaps
> **[Gap]** No source addressed [question].
> **[Gap]** All sources predate [date] — no data on [recent development].

## Sources
| ID | Title | Author | Date | Tier | Type | Cited by |
|----|-------|--------|------|------|------|----------|
| S1 | [title](url) | [author] | [date] | primary | academic | F1, F2 |
```

### Phase 3: VERIFY

**Always (every mode) — grounding audit.** One pass whose only job is to check each cited claim *against its quote span*: (a) does the source actually say this? (b) is any number/date/name altered? (c) is any Key-Finding or summary claim unsupported by the matrix? Fix or downgrade each mismatch. This is a grounding check, **not** a reasoning rewrite — do not ask the model to "improve" reasoning it can't externally check (introspective self-critique is neutral-to-harmful for factuality).

**Deep mode — Chain-of-Verification (factored).** For the 5-10 highest-stakes claims (numbers, dates, named findings, causal claims):
1. Generate a standalone verification question for each.
2. **Answer it in a fresh pass with the draft claim hidden** — re-query the sources (or the web) from scratch. *Critically:* never verify a claim while its original sentence is in view; re-reading the draft makes the model re-affirm its own error. The isolation is the mechanism.
3. Where the fresh answer disagrees with the draft, correct the draft to match the re-verified evidence, or downgrade the claim to *(contested)*.
4. **Loop-back:** if verification exposes 1-3 specific gaps, run targeted delta-queries (Phase 1, gaps only), integrate, re-score. Maximum 1 loop-back.

### Phase 4: DELIVER

**Show key findings inline in chat** — the user shouldn't need to open a file. Present the top 5-7 findings with confidence markers and independent-group counts.

**Save the full brief** if `--save` or `--agent`:
- Default path: `docs/research/YYYY-MM-DD-[topic-slug].md`; custom via `--save`. Create dirs as needed.
- **`--agent` mode:** save, print the path, exit. No questions.
- **Interactive:** show findings, then ask — "Save this brief?" · "Research deeper on any finding?" · "Done"

---

## Fallback Behavior

| Scenario | Behavior |
|----------|----------|
| No Tavily, no Exa | WebSearch + WebFetch only. Flag: "Limited to web search — connect Tavily or Exa MCP for broader coverage" |
| No WebSearch available | Use only Tavily/Exa. If neither available, use training knowledge only and flag EVERY claim as *(unverified — no search tools; model knowledge may be stale)* |
| Search returns <3 results | Flag: "Limited results. Consider broadening the query or checking search connectivity." |
| Only the model's memory supports a claim | Treat memory as **stale by default**. Any current-state claim (who holds a role, latest version, current price) needs a dated source. Label memory-only claims *(unverified — model knowledge, treat as stale)*. |
| Source content too long | Summarize key sections, cite the section, keep the quote span exact |

## Gotchas

- **Never validate a citation from memory.** Re-fetch and string-match the quote span. A cite that "looks right" is how fabricated and wrong-claim citations survive. (CiteGuard/CiteAudit: memory-validation recall ~16%.)
- **Don't count syndicated sources as independent.** Five outlets running the same wire story is one source. Group by origin before stacking confidence, or you manufacture false triangulation.
- **Don't consensus-wash contradictions.** If independent sources disagree, surface both with tiers and dates. Averaging them into a false middle is worse than reporting the conflict.
- **Don't emit a CRAAP score per source.** Checklist scoring is cognitive-overload theater that underperforms lateral reading. Use SIFT: investigate, corroborate, trace to origin.
- **Don't run an introspective "critique and rewrite" pass.** Self-critique with no external signal is neutral-to-harmful for factuality. The verify pass must re-check claims against sources (grounding/CoVe), not re-reason.
- **No 30-page reports.** 1-3 pages. Depth comes from claim quality and independence, not word count.
- **No confidence theater.** Don't tag everything High — High requires ≥2 *independent origin groups*. One source, however authoritative, caps at Medium.
- **No unsourced facts in findings.** Synthesis and Analysis can be uncited (they're your reasoning, marked as such); facts need a `[S#]` and a quote span.
- **No search loops.** Write-after-every-search + the Known/Unknown/Contradicted ledger + no-repeat-queries. Max 1 loop-back in deep mode.
- **No provider shaming.** Work with what's available; note when broader coverage would help. Don't tell users to buy API keys.

## Changelog

### V2 (2026-05-30) — faithful grounding + honest calibration

Optimized via `skillforge optimize`. Outcome target: a brief a knowledgeable reader would *trust and act on* — accurately triangulated, honestly calibrated, every fact cited to a real source. Each change is evidence-tied and targets a rubric dimension (source quality, citation discipline, contradiction honesty, synthesis, actionability).

- **Quote-grounded citations** — load-bearing claims carry a ≤25-word verbatim quote span; no quote, no assertion. Catches the "cited the right paper, wrong claim" failure. (OpenAI Deep Research passage-pinning; ["According to…" prompting](https://arxiv.org/pdf/2305.13252); [AGREE, NAACL 2024](https://aclanthology.org/2024.naacl-long.346.pdf).)
- **Source-independence grouping (Step 2c)** — confidence stacks on independent *origin groups*, not raw source count; syndicated/same-origin sources collapse to one. Defeats false triangulation, which generic "cite multiple sources" advice misses. (Nguyen, [Echo Chambers & Epistemic Bubbles](https://philarchive.org/archive/NGUECA); triangulation journalism practice.)
- **Chain-of-Verification, factored (Phase 3)** — replaces the old introspective self-review. Re-verify top claims in a fresh pass with the draft hidden; correct or downgrade on mismatch. The isolation is load-bearing — verifying with the draft in view just re-affirms the error. (Dhuliawala et al., [CoVe](https://arxiv.org/abs/2309.11495), factored variant: FactScore 0.647→0.692. External-signal critique only: [CRITIC](https://arxiv.org/abs/2305.11738), [Self-RAG](https://arxiv.org/abs/2310.11511); [LLMs Cannot Self-Correct Reasoning Yet](https://arxiv.org/abs/2310.01798).)
- **Sourced vs Analysis separation** + per-sentence `[S#]` — structurally stops unsupported inference from masquerading as a sourced fact. (AGREE; [Google grounding](https://research.google/blog/effective-large-language-model-adaptation-for-improved-grounding/).)
- **Staleness discipline** — treat model memory as stale by default; current-state claims need a dated source; staleness flag on the brief. (["Dated Data": effective cutoff trails reported cutoff](https://arxiv.org/pdf/2403.12958).)
- **SIFT lateral reading, not a CRAAP score** — tag primary/secondary/unknown, corroborate laterally, trace to origin. Dropped CRAAP-as-emitted-score (cognitive-overload failure mode that underperforms lateral reading). (Caulfield, [SIFT](https://hapgood.us/2019/06/19/sift-the-four-moves/); [ACRL CRAAP critique](https://crln.acrl.org/index.php/crlnews/article/view/26634/34553).)
- **Evidence matrix as synthesis backbone** — build the claims×sources matrix *before* prose; write by reading down claims; High needs ≥2 independent cells; abstain ("Evidence insufficient") instead of reporting low-confidence findings. (Claim-graph verification, [ClaimVer](https://arxiv.org/abs/2403.09724); abstention, [DeepSearchQA](https://arxiv.org/html/2601.20975v1).)

**Verification.** Blind same-judge A/B on 6 source-fixed fixtures (each planting one trap: false triangulation, genuine contradiction, single-source abstention, mis-grounded inference + terminology collision, staleness, mixed independence/gap), 5-dim rubric scored /25. Holding sources constant isolates the synthesis/calibration/faithfulness layers these changes target; search-layer changes (gap-loop, coverage-stop) are reasoned, not measured.

- **V2 beat V1 23.5 vs 22.0, winning 5 of 6 fixtures.** Train/validation split: tuning subset +2.25; **held-out validation a tie (23.5 each) — no regression, no clear validation win.** So the gain is real but modest, concentrated in the traps V2's levers target.
- The loop caught a regression honestly: an earlier V2 draft *lost* (−0.5) because the template consolidation had dropped V1's Terminology Map. It was restored, and the re-test flipped the result — the discipline working as intended.
- Caveat: judge scores drift across instances, so only within-run A/B deltas are used; N=6 is a small benchmark; source-fixed design doesn't exercise the search-layer changes.

## Credits

Skill by: Neal Meyer
- Multi-perspective search: Stanford [STORM](https://arxiv.org/pdf/2402.14207)
- Critique loop-back: 199-biotechnologies/claude-deep-research-skill
- Write-after-every-search anti-loop: altmbr/claude-research-skill
- **(V2) Quote-grounded attribution:** [AGREE, NAACL 2024](https://aclanthology.org/2024.naacl-long.346.pdf); ["According to…" prompting](https://arxiv.org/pdf/2305.13252)
- **(V2) Chain-of-Verification (factored):** Dhuliawala et al., [CoVe](https://arxiv.org/abs/2309.11495)
- **(V2) Source independence / false triangulation:** Nguyen, [Echo Chambers & Epistemic Bubbles](https://philarchive.org/archive/NGUECA)
- **(V2) Staleness / knowledge cutoffs:** [Dated Data](https://arxiv.org/pdf/2403.12958)
- **(V2) Source credibility (SIFT, not CRAAP):** Caulfield, [SIFT — The Four Moves](https://hapgood.us/2019/06/19/sift-the-four-moves/)
- **(V2) External-signal self-correction:** [CRITIC](https://arxiv.org/abs/2305.11738); [Self-RAG](https://arxiv.org/abs/2310.11511)
