---
date: 2026-04-13
topic: council-review-improvements
focus: Make council-review a best-in-class publishable Claude Code skill
---

# Ideation: Council Review Skill Improvements

## Codebase Context

Council Review is a Claude Code slash command skill (single markdown file) that implements Karpathy's LLM Council pattern. It spawns 5 AI advisors in parallel (Contrarian, First Principles, Expansionist, Outsider, Executor), runs anonymous peer review, then synthesizes a verdict via a Chairman agent. 11 total sub-agent calls. Currently 3 files: README.md, council-review.md, LICENSE.

**Key research findings that shaped filtering:**
- ICLR 2025 (DMAD): Forcing distinct *reasoning methods* (not just angles) is the highest-impact improvement for same-model councils
- "Can LLMs Really Debate?" (ICLR 2025): Majority pressure suppresses independent correction — anonymization is critical, do NOT remove it
- Disagreement analysis research: Distinguishing "value tension" from "error catch" is the most valuable signal in synthesis
- agent-council (yogirk): Competing repo adds `/council-revisit` and grounded deliberation patterns
- Skill ecosystem: Should migrate to SKILL.md directory format and submit to Anthropic marketplace

## Ranked Ideas

### 1. Reasoning Method Diversity (from DMAD research)

**Description:** Each advisor gets a specific *reasoning method*, not just an angle. The Contrarian uses inversion ("assume this ships and fails — trace backward"). First Principles uses decomposition ("break into atomic claims, challenge each"). The Expansionist uses analogy ("what adjacent domain solved this differently?"). The Outsider uses naive questioning ("explain like I just joined"). The Executor uses dependency graphing ("what blocks what?"). This addresses the core weakness of same-model councils: without method diversity, personas share the same reasoning patterns and converge.

**Rationale:** ICLR 2025 DMAD paper shows forcing distinct reasoning approaches outperforms standard multi-agent debate in fewer rounds. This is the single highest-impact change based on published research.

**Downsides:** Longer advisor prompts. Slightly more opinionated about how each role thinks.

**Confidence:** 92%

**Complexity:** Low — pure prompt change, no structural modification

**Status:** Unexplored

---

### 2. Adversarial Execution Mode

**Description:** Instead of 5 balanced advisors, assign 2 as mandatory advocates (argue FOR the proposal), 2 as mandatory skeptics (argue AGAINST), and 1 as neutral analyst. This forces genuine conflict regardless of whether the proposal is actually good or bad. The chairman synthesizes from structured opposition, not lukewarm balanced perspectives.

**Rationale:** Defeats the most common failure mode: advisors converging on polite consensus. Mandatory opposition ensures the proposal gets genuinely stress-tested. Zero implementation cost — pure prompt change.

**Downsides:** May feel artificial for open-ended questions that aren't proposals. Works best for "should we do X?" decisions.

**Confidence:** 88%

**Complexity:** Low — prompt restructuring only

**Status:** Unexplored

---

### 3. Disagreement Classification in Chairman Synthesis

**Description:** Add a section to the chairman's output that explicitly classifies each disagreement as either a "value tension" (legitimate tradeoff, both sides valid, depends on priorities) or an "error catch" (one advisor found a real flaw the others missed). This distinction changes what the user does with the verdict: value tensions require judgment calls; error catches require fixes.

**Rationale:** Disagreement analysis research shows this is the most valuable signal in multi-agent synthesis. Current "Where the Council Clashes" section flattens all disagreement into one bucket.

**Downsides:** Chairman may misclassify some tensions. Adds ~30 words to output.

**Confidence:** 90%

**Complexity:** Low — chairman prompt addition

**Status:** Unexplored

---

### 4. Dissent Preservation ("What You Lose")

**Description:** Chairman explicitly states "If you ignore the minority view, you accept this risk: [specific downside]." Forces the synthesis to preserve the strongest minority argument as a named tradeoff, not a footnote. The user can then make an informed choice rather than blindly following the majority.

**Rationale:** Most consensus-seeking tools suppress minority views. The council's value comes from surfacing them. Making the cost of ignoring dissent explicit is the highest-value prompt addition.

**Downsides:** None meaningful. Pure prompt improvement.

**Confidence:** 95%

**Complexity:** Low — prompt addition

**Status:** Unexplored

---

### 5. Quick/Lite Mode (`--quick`)

**Description:** Support a `--quick` flag that runs 3 advisors (Contrarian, Executor, Outsider) + skip peer review + direct chairman synthesis. 4 calls instead of 11. For routine decisions where full council is overkill but you still want structured multi-perspective thinking.

**Rationale:** The 11-call cost is the primary adoption barrier. A lite mode encourages more frequent use on lower-stakes decisions, building the habit of structured review.

**Downsides:** Loses the peer review step (the "what did ALL five miss?" question). Reduced perspective coverage.

**Confidence:** 85%

**Complexity:** Low — flag detection + conditional prompt paths

**Status:** Unexplored

---

### 6. Auto-Context Gathering

**Description:** Before framing the question, the skill automatically reads project README, CLAUDE.md, recent git log, and any referenced files. Injects salient context into each advisor's prompt. Eliminates the manual "paste your context" friction that makes generic councils give generic advice.

**Rationale:** Context-blind councils produce context-blind verdicts. The skill already instructs "scan for relevant context" but doesn't specify *what* to read. Making this explicit and automatic is a high-leverage improvement.

**Downsides:** Adds ~5 seconds to startup. May inject irrelevant context for non-code questions.

**Confidence:** 82%

**Complexity:** Low-Medium — requires specifying file reading patterns

**Status:** Unexplored

---

### 7. Verification Playbook

**Description:** Chairman's "Do This First" section expands to include 2-3 concrete verification steps: "How will you know if this recommendation was right? Check X after Y days. Measure Z." Closes the gap between verdict and action.

**Rationale:** Councils that produce recommendations without verification criteria are advice theater. Adding "how to check if we were right" makes the verdict falsifiable and actionable.

**Downsides:** Verification steps may be generic for abstract decisions. Most useful for technical/code decisions.

**Confidence:** 80%

**Complexity:** Low — chairman prompt addition

**Status:** Unexplored

---

### Honorable Mentions (kept but lower priority)

**8. Custom Advisor Swap** — Let users define custom advisors via `--advisors="Security,Legal,..."`. High leverage for domain reuse but adds argument parsing complexity. Score: 21/25.

**9. Domain-Specific Advisor Profiles** — Detect input type (PR/plan/question) and auto-select relevant advisor preset. Improves relevance but requires maintaining multiple preset definitions. Score: 21/25.

**10. Confidence Scoring** — Advisors append confidence levels (1-5) to responses; chairman weights accordingly. Adds quantitative signal but may be noisy. Score: 21/25.

**11. Consensus Short-Circuit** — If 4+ advisors agree, skip peer review. Saves calls but loses the "what did ALL miss?" signal. Score: 19/25.

**12. Scope Validation** — Pre-flight check: "Is this question trivial?" Saves tokens on misuse. Score: 19/25.

## Rejection Summary

| # | Idea | Reason Rejected |
|---|------|-----------------|
| 1 | Council Memory / Decision Log | Requires persistent storage across sessions; scope creep toward a platform |
| 2 | Streaming/Progressive Results | Not controllable from a markdown skill file; runtime/UI concern |
| 3 | Multi-Round Debate | Doubles agent calls (22+); introduces groupthink risk that defeats independence |
| 4 | Context-Aware Weighting | Covered by Confidence Scoring and Domain Profiles |
| 5 | Remove Anonymization | Research confirms anonymization prevents authority bias — removing it makes the skill worse |
| 6 | Session-Aware Follow-ups | Session memory not controllable from a markdown skill |
| 7 | Advisor Challenges Mode | Requires interactive REPL; different product than a slash command |
| 8 | Temporal Advisor | Vague persona; output indistinguishable from Expansionist |
| 9 | Recursive Sub-Council | Unbounded agent explosion; chairman exists to synthesize disagreement |
| 10 | Cross-Project Linkage | Requires external state; not implementable in stateless skill |
| 11 | Async Council | Requires scheduling/persistence infrastructure |
| 12 | Outcome Feedback Loop | Requires structured database; product roadmap item, not skill feature |
| 13 | Deeper Chain-of-Thought | Model selection not controllable from skill file; contradicts Compressed Output |
| 14 | User as Hidden Advisor | Interactive pause in autonomous flow; if user knows, they'd say it upfront |
| 15 | Compressed Advisor Output | Merged into Reasoning Method Diversity (structured output is part of method specification) |
| 16 | Transcript Persistence | Low novelty; deferred until demand proven |

## Session Log
- 2026-04-13: Initial ideation — 40 candidates generated across 5 frames, adversarial filtering applied, cross-referenced with deep research (ICLR 2025 DMAD, disagreement analysis, competing implementations). 7 primary survivors + 5 honorable mentions.
