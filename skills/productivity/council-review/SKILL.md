---
name: council-review
description: "Run any question, plan, PR, or code through a Diverse Multi-Agent Debate (DMAD) council of 5 AI advisors with distinct reasoning methods. Advisors collaborate, peer-review each other anonymously, and a chairman synthesizes a verdict. Empirically outperforms adversarial debate (M3MADBench 2026, DMAD ICLR 2025). Use when: 'council this', 'run the council', 'council review', 'pressure-test this', 'stress-test this', 'war room this', or when facing a genuine decision with stakes and tradeoffs."
argument-hint: "[question, file path, PR number, or GitHub URL] [--quick] [--adaptive] [--confidence] [--measure-diversity] [--adversarial (deprecated)]"
---

# Council Review

Run any question, plan, or code through 5 independent advisors who use **distinct reasoning methods**, collaborate to refine answers, peer-review each other anonymously, and synthesize a verdict you can trust.

This skill implements the **Diverse Multi-Agent Debate (DMAD)** pattern. It is collaborative, not adversarial: agents seek truth through diversity of reasoning, not by arguing opposing positions.

## Why This Works (Research Backing)

- **Method diversity beats single-method debate.** DMAD (ICLR 2025) shows that agents using distinct reasoning methods reliably outperform homogeneous councils — diverse medium-capacity models can beat GPT-4 on GSM-8K (91% vs 82%) when each agent applies a different reasoning approach.
- **Collaborative debate beats adversarial debate.** M3MADBench (2026) shows that across all modalities, collaborative DMAD outperforms adversarial Div-MAD "by a substantial margin." Adversarial paradigms introduce divergent noise; for **open questions, plans, and decisions**, collaborative deliberation is the right tool.
- **Anonymous peer review prevents provider bias.** Universal across the literature — reviewers defer to role names if visible, so peer-review responses must be shuffled.
- **Confidence calibration breaks the martingale ceiling.** Vanilla MAD often underperforms simple majority vote; confidence-modulated updates ("Demystifying MAD" 2026) systematically drift the council toward correct answers.
- **Adaptive stopping cuts cost.** KS-statistic convergence detection (S2 MAD via llmcouncil) reports up to 94.5% cost reduction on convergent questions.

For stress-testing a known artifact (PR, draft, spec), use the separate `/adversarial-review` skill instead — single-critic adversarial probing is the right tool there.

## When to Use

The council is for questions where **being wrong is expensive**.

**Good for:** Architecture decisions, implementation plans, PR reviews, product decisions, migration strategies, API design, naming, pricing, scope decisions
**Bad for:** Factual lookups, writing tasks, simple yes/no, anything with one obvious right answer
**Use a different tool:** Single-critic stress test of an existing artifact → `/adversarial-review`

## Flags

| Flag | Effect |
|------|--------|
| `--quick` | Lite mode: 3 advisors + chairman, no peer review (4 calls instead of 11) |
| `--adaptive` | KS-statistic adaptive stopping. Run multi-round debate; halt when response distributions converge below epsilon for two consecutive rounds. Up to 94.5% cost cut on convergent questions. |
| `--confidence` | Confidence-modulated synthesis. Each advisor rates own confidence (1–10) and rates each peer's confidence. Chairman synthesis is confidence-weighted, not majority-vote. Surfaces low-confidence consensus as a yellow flag. |
| `--measure-diversity` | After advisors respond, score reasoning-footprint overlap across the responses. Report when the council agreed despite different reasoning methods — that's a signal the consensus may be theatrical. |
| `--adversarial` | **DEPRECATED.** 2 advocates FOR + 2 skeptics AGAINST + 1 neutral. Retained for backward compatibility but contradicts M3MADBench evidence. Prefer `/adversarial-review` for single-critic stress tests. |

Flags compose: `/council-review --adaptive --confidence "Should we adopt GraphQL?"` runs convergence-stopped, confidence-weighted deliberation.

## The Five Advisors

| # | Advisor | Angle | Reasoning Method | Catches |
|---|---------|-------|------------------|---------|
| 1 | **The Contrarian** | What will fail? | **Inversion** — assume it shipped and failed, trace backward to the cause | "Sounds great but..." gaps you skip when excited |
| 2 | **First Principles Thinker** | What are we actually solving? | **Decomposition** — break into atomic claims, challenge each one | "You're optimizing the wrong variable" |
| 3 | **The Expansionist** | What upside are we missing? | **Analogy** — what adjacent domain solved this differently? | "You're thinking too small" |
| 4 | **The Outsider** | Zero context, fresh eyes only | **Naive questioning** — explain like you just joined; flag anything that requires insider knowledge to make sense | Curse of knowledge blind spots |
| 5 | **The Executor** | What do you do Monday morning? | **Dependency graphing** — what blocks what? What's the critical path? | Brilliant plans with no actionable first step |

**Natural tensions:** Contrarian vs Expansionist (downside vs upside), First Principles vs Executor (rethink vs ship it), Outsider keeps everyone honest.

The five reasoning methods are not interchangeable angles — each is a different *cognitive operation*. This is the DMAD lever: same model, different reasoning.

---

## Execution Flow

### Step 0: Pre-flight

<pre_flight>

**Parse flags from `$ARGUMENTS`:**
- If `--quick` is present: use Lite Mode (see below)
- If `--adaptive` is present: enable KS-statistic adaptive stopping (Step 3.5)
- If `--confidence` is present: enable confidence-modulated synthesis (Steps 2 and 4)
- If `--measure-diversity` is present: enable diversity verification (Step 2.5)
- If `--adversarial` is present: use Adversarial Mode (deprecated, see below)
- Remove flags from the input before classifying

**Scope validation:** Before convening the council, assess whether the input actually warrants it. If the question is purely factual, has one obvious right answer, or has no meaningful tradeoff, say so directly: "This doesn't need a council — [direct answer]. Use `/council-review` for decisions with genuine stakes and tradeoffs." Do not spawn agents for trivial questions.

**Classify the remaining input:**

1. **PR** — Numeric value, or URL containing `/pull/`. Fetch PR diff and description via `gh pr view`.
2. **File path** — String ending in a file extension or pointing to an existing file. Read the file contents.
3. **Plan/Decision/Question** — Everything else. Use as-is.

For PRs and files, read the actual content and include it in the framed question. Don't just pass a URL — advisors need the substance.

</pre_flight>

### Step 1: Gather Context and Frame

**Auto-context gathering** — before framing, read these project files (skip any that don't exist):
- `README.md` — what the project does
- `CLAUDE.md` or `AGENTS.md` — conventions, architecture, patterns
- Recent git log (`git log --oneline -10`) — what's been happening
- Any files the user referenced or that relate to the topic
- PR diff and description if reviewing a PR

Reframe the raw input as a clear, neutral prompt:

```
QUESTION:
[Core decision, plan, or code being reviewed]

CONTEXT:
[Key context from project files: what the project does, constraints, recent changes, stakes]

WHAT'S AT STAKE:
[Why this matters — cost of getting it wrong]
```

Don't add your own opinion. Don't steer toward an answer. If too vague, ask ONE clarifying question before proceeding.

### Step 2: Convene the Council (5 agents in parallel)

Launch all 5 advisors **simultaneously** using the Agent tool. Each advisor runs in parallel. Use a lightweight model (`haiku`) for advisors — they're doing focused analysis, not complex reasoning.

**CRITICAL: Launch all 5 in a single message with 5 Agent tool calls.** Sequential execution lets earlier responses bleed into later ones and defeats the purpose.

Each advisor gets this prompt:

```
You are [ADVISOR NAME] on an LLM Council reviewing a decision.

Your angle: [ADVISOR ANGLE]
Your reasoning method: [ADVISOR REASONING METHOD — see table above]

A user has brought this to the council:
---
[framed question from Step 1]
---

Apply your assigned reasoning method rigorously. Don't just state opinions — show your work using your method.

Rules:
- 150-300 words. No preamble. Straight into your analysis.
- Name specific risks, opportunities, or issues — not vague concerns.
- If reviewing code: cite specific files, functions, or patterns.
- If reviewing a plan: point to specific steps, gaps, or sequencing issues.
- End with your single strongest recommendation.
```

**Advisor-specific instructions (include the reasoning method):**

- **Contrarian:** "Your method is INVERSION. Assume this shipped exactly as proposed — and failed. Work backward: what was the cause of failure? What looked safe but broke under pressure? What's the failure mode nobody is discussing? Show your inversion chain."
- **First Principles:** "Your method is DECOMPOSITION. Break this into its atomic claims and assumptions. List them. Challenge each one: is this actually true? Is it necessary? What would change if this assumption were wrong? Show which assumptions are load-bearing."
- **Expansionist:** "Your method is ANALOGY. What adjacent domain, product, or technology solved a similar problem differently? What would someone with 10x ambition do here? Where is this thinking too small? Name specific analogues and what they'd suggest."
- **Outsider:** "Your method is NAIVE QUESTIONING. You have zero context about this project. Based purely on what you see here, list every point that requires insider knowledge to understand. What's confusing? What jargon is unexplained? What would you ask if you just joined the team? If you can't follow the reasoning, say so."
- **Executor:** "Your method is DEPENDENCY GRAPHING. Map the dependencies: what blocks what? What's the critical path? What's the first thing that must happen, and what can't start until it finishes? What takes 5 minutes but everyone will forget? Show the execution sequence."

**If `--confidence` is enabled, append to every advisor prompt:**

```
After your analysis, end with:
CONFIDENCE: [1-10]
RATIONALE: [one sentence — what would change your confidence up or down?]
```

This produces calibrated self-assessments the chairman will weight in synthesis.

### Step 2.5: Diversity Verification (`--measure-diversity` only)

After all 5 advisor responses are collected and before peer review, score the **reasoning footprint overlap**:

1. Extract the load-bearing claims from each response (top 3-5 per advisor).
2. Compute pairwise overlap: how many claims appear in 2+ responses with the same conclusion?
3. Report a single diversity score:
   - **High diversity (< 30% overlap)** — advisors genuinely thought differently. Trust the consensus.
   - **Medium diversity (30-60% overlap)** — partial alignment. Note shared assumptions in the verdict.
   - **Low diversity (> 60% overlap)** — advisors converged on the same reasoning despite different methods. **Flag as theatrical consensus** — the chairman should treat this as a single advisor's opinion.

This catches "five advisors said yes" when actually one prompt-priming pattern dominated.

### Step 3: Anonymous Peer Review (5 agents in parallel)

Collect all 5 advisor responses. **Randomize the mapping** — Advisor 1 should NOT always be Response A. Then launch 5 reviewer agents in parallel (use `haiku`).

Each reviewer sees all 5 anonymized responses:

```
You are reviewing the outputs of an LLM Council. Five advisors independently answered:

---
[framed question]
---

**Response A:** [randomized advisor response]
**Response B:** [randomized advisor response]
**Response C:** [randomized advisor response]
**Response D:** [randomized advisor response]
**Response E:** [randomized advisor response]

Answer these three questions. Be specific. Reference responses by letter.

1. Which response is strongest? Why? (one sentence)
2. Which has the biggest blind spot? What is it missing? (one sentence)
3. What did ALL five responses miss that the council should consider? (This is the most valuable question — think hard.)

Keep under 150 words. Be direct. No preamble.
```

**If `--confidence` is enabled, append a fourth question:**

```
4. Rate your confidence in your answers above (1-10). What would change it?
```

### Step 3.5: Adaptive Stopping (`--adaptive` only)

If `--adaptive` is enabled, the council operates over multiple rounds rather than the single advisor → review → chairman flow. After each round:

1. Collect all advisor responses for the round (5 responses).
2. Compute the **Kolmogorov-Smirnov statistic** comparing the response distributions to the prior round's responses. Use a coarse fingerprint — for each response, extract the set of distinct claims, then compute Jaccard-style distance across rounds.
3. If the distribution shift drops below epsilon (default: 0.1) for two consecutive rounds, **stop** and proceed to chairman synthesis.
4. Otherwise, run another advisor round, feeding each advisor the prior round's responses and asking them to update.
5. Maximum 5 rounds — hard cap to prevent runaway cost.

When `--adaptive` triggers early stopping, the chairman receives the final-round responses plus a one-line note: "Council converged after N rounds (KS shift below epsilon)."

When fixed-mode is used (no `--adaptive`), proceed directly to Step 3 peer review after one advisor round.

### Step 4: Chairman Synthesis

One agent gets everything: the original question, all 5 advisor responses (de-anonymized with names and reasoning methods), all 5 peer reviews, the diversity score (if `--measure-diversity`), and confidence ratings (if `--confidence`). Use the best available model for this (default — do not specify a lightweight model).

**Default synthesis (majority-aware):** the chairman weighs convergence across advisors and peer-review signals.

**Confidence-modulated synthesis (`--confidence`):** the chairman weights each advisor's contribution by their self-rated confidence × peer-rated confidence. Low-confidence majorities are flagged in the verdict; high-confidence dissent is preserved with extra weight.

**Diversity-aware synthesis (`--measure-diversity`):** if the diversity score is Low, the chairman explicitly notes "the council converged on shared assumptions, not independent reasoning" in the verdict and downgrades confidence in the recommendation.

The chairman produces exactly this structure:

```
## Council Verdict: [Topic — 5 words max]

### Where the Council Agrees
[Points where multiple advisors converged independently — these are high-confidence signals]

### Where the Council Clashes

For each disagreement, classify it:

**[Value Tension]** — Both sides are valid; the right choice depends on priorities.
[Present both sides clearly. Name the tradeoff.]

**[Error Catch]** — One advisor found a real flaw the others missed.
[Name the flaw, who caught it, and why it matters.]

### Blind Spots Revealed
[Things only the peer review caught — the "what did ALL five miss?" answers]

### Confidence Profile  *(only with --confidence)*
[Which advisors were confident vs hedging? Where did peer-rated confidence diverge from self-rated? What does the confidence pattern tell us?]

### Diversity Check  *(only with --measure-diversity)*
[Diversity score and what it means for the verdict's reliability.]

### Recommendation
[Clear, actionable recommendation. Not "it depends." Not "consider both options." A real answer with reasoning. The chairman CAN disagree with the majority if the dissenter's reasoning is strongest, OR if confidence/diversity signals undermine the apparent consensus.]

### What You Lose
[If you follow this recommendation, what does the strongest dissenting voice say you're giving up? Name the specific risk or missed opportunity. This is NOT a hedge — it's informed consent.]

### Do This First
[Single concrete next step. Not a list. Not three options. One thing to do right now.]

**How to verify:** [2-3 concrete checks to confirm the recommendation was right. What should you measure? What should you look for after N days/weeks?]
```

### Step 5: Present Results

Show the chairman's verdict directly in chat. Then provide the full transcript in a collapsible section or separate file if the user wants it.

---

## Lite Mode (`--quick`)

When `--quick` is passed, run a streamlined council:

1. **3 advisors only:** Contrarian, Executor, Outsider (the three most action-oriented perspectives)
2. **No peer review** — skip Step 3 entirely
3. **Chairman synthesis** from 3 responses instead of 5
4. **Same output format** but faster (4 agent calls instead of 11)
5. **Compatible with `--confidence` and `--measure-diversity`** but not with `--adaptive` (multi-round costs more than the savings).

Use for routine decisions, quick gut-checks, or when time matters more than exhaustive coverage.

## Adversarial Mode (`--adversarial`) — DEPRECATED

> **Deprecation note:** Empirical evidence (M3MADBench 2026) shows adversarial multi-agent debate underperforms collaborative DMAD on open questions, plans, and decisions. This mode is retained for backward compatibility, but for new use cases, prefer:
> - **Default council (collaborative DMAD)** — for open decisions, plans, and "what should we do?" questions.
> - **`/adversarial-review` skill** — for stress-testing a *known artifact* (a written PR, draft, or spec) with single-critic adversarial probing. Distinct workflow.

When `--adversarial` is passed, restructure the advisor roles:

1. **2 Advocates** — Argue FOR the proposal regardless of personal opinion. Find every reason this is a good idea. Steel-man it.
2. **2 Skeptics** — Argue AGAINST the proposal regardless of personal opinion. Find every reason this will fail. Red-team it.
3. **1 Neutral Analyst** — No agenda. Evaluate the quality of arguments on both sides. Note which side has stronger evidence.

Peer review and chairman synthesis proceed as normal. The chairman explicitly notes which side made stronger arguments and why.

---

## Cost Budget

| Mode | Agent Calls | Best For |
|------|-------------|----------|
| Full (default) | **11** (5 advisors + 5 reviewers + 1 chairman) | High-stakes decisions |
| Quick (`--quick`) | **4** (3 advisors + 1 chairman) | Routine decisions, gut-checks |
| Adaptive (`--adaptive`) | **6 to 26** (5 advisors × N rounds + 5 reviewers + 1 chairman, N ≤ 5 with early stop) | Open questions where convergence cost matters |
| Confidence (`--confidence`) | **11** (same as full, slightly longer prompts) | Decisions where calibrated certainty matters |
| Measure-diversity (`--measure-diversity`) | **11** (adds a synchronous overlap-scoring step, no extra agent calls) | Verifying consensus is real, not theatrical |
| Adversarial (`--adversarial`) — deprecated | **11** | Backward compatibility |

Flags compose: `--adaptive --confidence --measure-diversity` together = up to 26 calls + diversity scoring + confidence weighting.

Fast models for volume, good model for synthesis. The chairman's reasoning quality is what matters most.

## Gotchas

- **Always parallel spawn advisors.** Sequential lets earlier responses contaminate later ones.
- **Always anonymize for peer review.** Reviewers defer to "The Contrarian" or "First Principles" if they see the label. Shuffle the letters.
- **Chairman can override majority.** Quality of reasoning > vote count. If the Contrarian found a real flaw that everyone else missed, the chairman should side with them.
- **Don't council trivial questions.** The pre-flight check should catch these. If one right answer exists, just answer it.
- **Context is critical.** Generic input = generic output. The auto-context step reads project files so advisors aren't flying blind.
- **Same-model limitation.** This skill uses persona/method diversity (different reasoning methods on the same model), not model diversity (Karpathy's original used different LLMs). For the highest-stakes decisions, consider getting a second opinion from a different model family — or use `--measure-diversity` to verify the council didn't converge prematurely.
- **Collaborative beats adversarial for open questions.** M3MADBench 2026: adversarial debate underperforms collaborative debate across all modalities. Reach for `--adversarial` only for backward compatibility; reach for `/adversarial-review` for stress-testing a known artifact.
- **Confidence calibration is only as good as the model's calibration.** Low-confidence dissent should still be taken seriously when the dissenter's reasoning is concrete and the majority's is vague.

## Credits

- Original concept: **Andrej Karpathy** ([LLM Council](https://github.com/karpathy/llm-council))
- Claude Code adaptation: **Ole Lehmann** ([@itsolelehmann](https://x.com/itsolelehmann))
- Reasoning method diversity: **DMAD** ([ICLR 2025](https://openreview.net/forum?id=t6QHYUOQL7))
- Collaborative > adversarial empirical evidence: **M3MADBench** ([arXiv 2601.02854](https://arxiv.org/pdf/2601.02854), 2026)
- Confidence-modulated debate protocol: **Demystifying MAD** ([arXiv 2601.19921](https://arxiv.org/pdf/2601.19921), 2026)
- KS-statistic adaptive stopping: **rachittshah/llmcouncil** (S2 MAD implementation)
- Diversity-footprint verification approach: **Counsel** ([Same model, same blind spots](https://counsel.getmason.io/research/model-bindings))
- Skill by: **Neal Meyer**
