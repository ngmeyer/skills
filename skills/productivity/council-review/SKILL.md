---
name: council-review
description: "Run any question, plan, PR, or code through a Diverse Multi-Agent Debate (DMAD) council of 5 AI advisors with distinct reasoning methods. Advisors collaborate, peer-review each other anonymously, and a chairman synthesizes a verdict. Empirically outperforms adversarial debate (M3MADBench 2026, DMAD ICLR 2025). Use when: 'council this', 'run the council', 'council review', 'pressure-test this', 'stress-test this', 'war room this', or when facing a genuine decision with stakes and tradeoffs."
argument-hint: "[question, file path, PR number, or GitHub URL] [--quick] [--adaptive] [--confidence] [--measure-diversity] [--jury]"
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
- **A true devil's advocate is the only reliable disagreement-inducer (V2).** Across techniques for breaking consensus in multi-agent LLM teams, *only* a dedicated devil's advocate attacking the emerging answer produces genuine disagreement — soft role-framing and "please dissent" instructions test statistically indistinguishable from baseline. An LLM devil's advocate that challenges the recommendation measurably raises group decision accuracy (OpenReview 2026; IUI 2024). V2 adds this as a mandatory pass against the *consensus* — one devil's advocate vs the converged answer, not a standing advocates/skeptics split.
- **Sycophancy collapses councils into premature consensus (V2).** LLMs defer — to each other and to the answer implied by the framing — which can drop a council below single-agent accuracy (Peacemaker-or-Troublemaker 2026; CONSENSAGENT). V2 adds a sycophancy guardrail to advisor + peer prompts and a structured independent-assessment step (Kahneman's Mediating Assessments Protocol, 2019) so the chairman judges key attributes separately *before* the holistic call.

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
| `--jury` | **(V2)** Replace the single chairman with a 3-judge jury, ideally across different model families. Each judge synthesizes independently; a brief reconciliation step merges them. For close calls and high-stakes verdicts where single-judge reliability isn't enough (jury-of-judges / PoLL). |

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
- If `--jury` is present: use a 3-judge jury at synthesis (Step 4)
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
- **Do not defer to any answer the framing seems to expect.** Reason from your method to wherever it actually leads; if that's against the apparent expected answer, say so plainly. Hedging toward the obvious answer is the failure this council exists to prevent.
- End with your single strongest recommendation.
```

> **(V2) Sycophancy guardrail.** The bolded rule above is load-bearing: documented multi-agent failure is advisors converging by deference, not reasoning. Keep it in every advisor prompt.

**Advisor-specific instructions (include the reasoning method):**

- **Contrarian:** "Your method is INVERSION. Assume this shipped exactly as proposed — and failed. Work backward: what was the cause of failure? What looked safe but broke under pressure? What's the failure mode nobody is discussing? Show your inversion chain."
- **First Principles:** "Your method is DECOMPOSITION. Break this into its atomic claims and assumptions. List them. Challenge each one: is this actually true? Is it necessary? What would change if this assumption were wrong? Show which assumptions are load-bearing."
- **Expansionist:** "Your method is ANALOGY. What adjacent domain, product, or technology solved a similar problem differently? What would someone with 10x ambition do here? Where is this thinking too small? Name specific analogues and what they'd suggest."
- **Outsider:** "Your method is NAIVE QUESTIONING. You have zero context about this project. Based purely on what you see here, list every point that requires insider knowledge to understand. What's confusing? What jargon is unexplained? What would you ask if you just joined the team? If you can't follow the reasoning, say so."
- **Executor:** "Your method is DEPENDENCY GRAPHING + OUTSIDE VIEW. Map the dependencies: what blocks what? What's the critical path? What's the first thing that must happen, and what can't start until it finishes? What takes 5 minutes but everyone will forget? Then take the OUTSIDE VIEW (V2): name the base rate — how have *similar* efforts actually turned out, not how this one is planned to? Flag where the plan's estimates show optimism bias against that reference class. Show the execution sequence."

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
4. **(V2)** Where these responses agree, is the agreement genuine — or could it be conformity to a shared framing? Flag any consensus that looks like deference rather than independent reasoning.

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

### Step 3.7: Devil's Advocate vs the Consensus (V2 — mandatory)

This is the single highest-leverage V2 addition. The evidence is unambiguous: soft contrarian framing at the *start* (the Contrarian advisor) is statistically indistinguishable from baseline at inducing real disagreement — only a dedicated devil's advocate attacking the *emerging* answer works, and it measurably raises decision accuracy.

1. From the advisor responses + peer review, identify the **emerging consensus answer** in one sentence (what is the council drifting toward recommending?). If there is genuinely no emerging answer yet, note that and skip to Step 4.
2. Spawn **one** Devil's Advocate agent. Use a **strong model** (not `haiku`) — this agent must be sharp. Its prompt:

   ```
   The council is converging on this answer:
   ---
   [emerging consensus answer, stated plainly]
   ---
   To this question:
   ---
   [framed question]
   ---

   Your job is to make the strongest possible case that this answer is WRONG.
   Not "here are some risks" — argue that following it is a mistake.
   - What does the consensus overlook that, if true, flips the decision?
   - Construct the concrete scenario in which this answer fails badly.
   - What evidence would the council need to see to abandon this answer — and is it actually present, or assumed?
   Steelman the opposite of the consensus. 200 words max. End with: the ONE thing that, if the council can't rebut it, should change the verdict.
   ```

3. Feed the Devil's Advocate output to the chairman alongside everything else. This is not a 2-vs-2 advocates/skeptics structure from the start; it's one sharp attack on the *converged* answer, which is the configuration the research singles out.

`--quick` mode: still run the Devil's Advocate (it's the cheapest high-value addition — 1 call). It is the one step `--quick` must not skip.

### Step 4: Chairman Synthesis

One agent gets everything: the original question, all 5 advisor responses (de-anonymized with names and reasoning methods), all 5 peer reviews, **the Devil's Advocate's attack on the consensus (V2)**, the diversity score (if `--measure-diversity`), and confidence ratings (if `--confidence`). Use the best available model for this (default — do not specify a lightweight model).

**(V2) Mediating Assessments first.** Before writing the recommendation, the chairman names 3–5 **independent** key attributes the decision turns on (e.g. for an architecture call: reversibility, blast radius, time-to-first-value, team familiarity) and scores each *separately* against the evidence — without yet forming the overall verdict. Only after the independent assessments does the chairman synthesize the holistic call. This fights coherence bias (locking onto an early answer and bending every attribute to fit it). Kahneman/Lovallo/Sibony, Mediating Assessments Protocol (2019).

**(V2) `--jury`:** instead of one chairman, run **3** chairmen — ideally across different model families — each performing the full synthesis independently (including Mediating Assessments). Then a short reconciliation pass surfaces where the three judges agree (high-confidence verdict) and where they diverge (flag as a genuine close call). Use for high-stakes or close-call decisions where single-judge reliability isn't enough.

**Default synthesis (majority-aware):** the chairman weighs convergence across advisors and peer-review signals, and must explicitly rebut or concede the Devil's Advocate's strongest point.

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

### Mediating Assessments  *(V2)*
[The 3–5 independent attributes the decision turns on, each scored separately against the evidence — stated BEFORE the recommendation so the reader sees the inputs to the judgment, not just the conclusion.]

### Devil's Advocate — and the Council's Answer  *(V2)*
[The strongest case that the emerging answer is wrong (from Step 3.7), and the chairman's explicit rebuttal or concession. If the Devil's Advocate's one key point can't be rebutted, the verdict must change to reflect it.]

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

**How to verify:** [2-3 concrete checks to confirm the recommendation was right. What should you measure? What should you look for after N days/weeks? **(V2)** Include the outside-view check: what's the base rate for efforts like this, and what early signal would tell you you're tracking worse than the reference class?]
```

### Step 5: Present Results

Show the chairman's verdict directly in chat. Then provide the full transcript in a collapsible section or separate file if the user wants it.

---

## Lite Mode (`--quick`)

When `--quick` is passed, run a streamlined council:

1. **3 advisors only:** Contrarian, Executor, Outsider (the three most action-oriented perspectives)
2. **No peer review** — skip Step 3 entirely
3. **Devil's Advocate (V2) still runs** — Step 3.7 is the one cheap step `--quick` must not skip
4. **Chairman synthesis** from 3 responses + the Devil's Advocate attack
5. **Same output format** but faster (5 agent calls instead of 12)
6. **Compatible with `--confidence` and `--measure-diversity`** but not with `--adaptive` (multi-round costs more than the savings).

Use for routine decisions, quick gut-checks, or when time matters more than exhaustive coverage.

## Cost Budget

| Mode | Agent Calls | Best For |
|------|-------------|----------|
| Full (default) | **12** (5 advisors + 5 reviewers + 1 devil's advocate + 1 chairman) | High-stakes decisions |
| Quick (`--quick`) | **5** (3 advisors + 1 devil's advocate + 1 chairman) | Routine decisions, gut-checks |
| Adaptive (`--adaptive`) | **7 to 27** (5 advisors × N rounds + 5 reviewers + devil's advocate + chairman, N ≤ 5 with early stop) | Open questions where convergence cost matters |
| Confidence (`--confidence`) | **12** (same as full, slightly longer prompts) | Decisions where calibrated certainty matters |
| Measure-diversity (`--measure-diversity`) | **12** (adds a synchronous overlap-scoring step, no extra agent calls) | Verifying consensus is real, not theatrical |
| Jury (`--jury`) | **+2** (3 chairmen instead of 1, ideally diverse models) | Close calls / high-stakes verdict reliability |

Flags compose: `--adaptive --confidence --measure-diversity` together = up to 26 calls + diversity scoring + confidence weighting.

Fast models for volume, good model for synthesis. The chairman's reasoning quality is what matters most.

## Gotchas

- **Always parallel spawn advisors.** Sequential lets earlier responses contaminate later ones.
- **Always anonymize for peer review.** Reviewers defer to "The Contrarian" or "First Principles" if they see the label. Shuffle the letters.
- **Chairman can override majority.** Quality of reasoning > vote count. If the Contrarian found a real flaw that everyone else missed, the chairman should side with them.
- **Don't council trivial questions.** The pre-flight check should catch these. If one right answer exists, just answer it.
- **Context is critical.** Generic input = generic output. The auto-context step reads project files so advisors aren't flying blind.
- **Same-model limitation.** This skill uses persona/method diversity (different reasoning methods on the same model), not model diversity (Karpathy's original used different LLMs). For the highest-stakes decisions, consider getting a second opinion from a different model family — or use `--measure-diversity` to verify the council didn't converge prematurely.
- **Collaborative beats adversarial for open questions.** M3MADBench 2026: adversarial debate underperforms collaborative debate across all modalities. For stress-testing a *known artifact* (PR, draft, spec), reach for the separate `/adversarial-review` skill — different operation, different input.
- **Confidence calibration is only as good as the model's calibration.** Low-confidence dissent should still be taken seriously when the dissenter's reasoning is concrete and the majority's is vague.
- **(V2) The Contrarian is NOT the Devil's Advocate.** The Contrarian inverts at the *start* (soft framing — tests baseline-equivalent at inducing real disagreement). The Step 3.7 Devil's Advocate attacks the *converged* answer — that's the configuration the evidence singles out. Never drop Step 3.7 to save a call; it's the highest-leverage step in the skill.
- **(V2) Mediating Assessments come BEFORE the recommendation.** If the chairman writes the verdict first and back-fills the attribute scores, it has recreated the coherence bias the protocol exists to prevent. Score the attributes independently, then synthesize.
- **(V2) `--jury` only helps if the judges differ.** Three runs of the same model is mostly theater. Use different model families, or at minimum independent contexts; treat 3-of-3 agreement as the real signal and any split as a genuine close call.

## Changelog

### V2.1 (2026-05-27)
Removed the deprecated `--adversarial` mode entirely (flag, mode section, cost row, parse step). It contradicted the M3MADBench evidence, was superseded by V2's mandatory Devil's-Advocate-vs-consensus step, and caused real "isn't this the same as `/adversarial-review`?" confusion. The two skills stay cleanly separated: **council-review** = open decisions (with a built-in devil's advocate); **`/adversarial-review`** = stress-test a finished artifact. The "collaborative beats adversarial" evidence and the cross-link to `/adversarial-review` are kept.

### V2 (2026-05-26)

Optimized via `skillforge optimize`. Outcome-research brief: the V2 outcome-research brief. Each change is tied to evidence and targets the *decision outcome*, not packaging:

- **Mandatory Devil's Advocate (Step 3.7)** attacking the *emerging consensus* — the one configuration shown to reliably induce genuine disagreement and raise accuracy (OpenReview 2026; IUI 2024). The Contrarian's start-of-debate inversion is soft framing and tests baseline-equivalent.
- **Sycophancy guardrail** in advisor + peer prompts; new peer-review question separating genuine agreement from conformity (Peacemaker-or-Troublemaker 2026; CONSENSAGENT).
- **Mediating Assessments** in chairman synthesis — score 3–5 independent attributes before the holistic call, fighting coherence bias (Kahneman/Lovallo/Sibony 2019).
- **Outside-view / base-rate** check in the Executor + "How to verify" (reference-class forecasting; Kahneman/Tversky, Flyvbjerg).
- **`--jury`** — 3 diverse-model chairmen for close calls (jury-of-judges / PoLL).

**Verification.** Two passes. (1) Structured single-model eval on "monolith → microservices?": V1 3.2 → V2 4.6. (2) **Independent A/B (2026-05-27):** real separate-process agents (`claude -p`) on "seed startup → adopt Kubernetes?", advisors held constant across arms to isolate the chairman-layer change, scored by a **blind** judge (didn't know which verdict was which; V1 shown first to avoid order bias): **V1 3.8 → V2 4.8** (Decisiveness, Insight, Calibration, Actionability, Risk-surfacing). Biggest gains: Risk-surfacing 3→5 and Calibration 3→4. The judge's stated reasons for V2's win named exactly the V2 mechanisms — base-rate/outside-view, the Devil's-Advocate rebuttal, and independent attribute scoring. The advisor-layer changes (sycophancy guardrail, outside-view prompt) were held constant in this A/B and remain validated only by reasoning.

## Credits

- Original concept: **Andrej Karpathy** ([LLM Council](https://github.com/karpathy/llm-council))
- Claude Code adaptation: **Ole Lehmann** ([@itsolelehmann](https://x.com/itsolelehmann))
- Reasoning method diversity: **DMAD** ([ICLR 2025](https://openreview.net/forum?id=t6QHYUOQL7))
- Collaborative > adversarial empirical evidence: **M3MADBench** ([arXiv 2601.02854](https://arxiv.org/pdf/2601.02854), 2026)
- Confidence-modulated debate protocol: **Demystifying MAD** ([arXiv 2601.19921](https://arxiv.org/pdf/2601.19921), 2026)
- KS-statistic adaptive stopping: **rachittshah/llmcouncil** (S2 MAD implementation)
- Diversity-footprint verification approach: **Counsel** ([Same model, same blind spots](https://counsel.getmason.io/research/model-bindings))
- **(V2) Devil's advocate as the only reliable disagreement-inducer:** [Inducing Disagreement in Multi-Agent LLM Executive Teams (OpenReview 2026)](https://openreview.net/forum?id=mxBmj5LYU2); [LLM-Powered Devil's Advocate (IUI 2024)](https://dl.acm.org/doi/10.1145/3640543.3645199)
- **(V2) Sycophancy / premature consensus:** [Peacemaker or Troublemaker (2026)](https://arxiv.org/pdf/2509.23055); [CONSENSAGENT (ACL 2025)](https://aclanthology.org/2025.findings-acl.1141/)
- **(V2) Mediating Assessments Protocol:** Kahneman, Lovallo & Sibony, [A Structured Approach to Strategic Decisions (MIT SMR, 2019)](https://sloanreview.mit.edu/article/a-structured-approach-to-strategic-decisions)
- **(V2) Outside view / reference-class forecasting:** Kahneman & Tversky; [Flyvbjerg](https://en.wikipedia.org/wiki/Reference_class_forecasting)
- **(V2) Jury-of-judges:** [LLM-as-Judge best practices 2026](https://futureagi.com/blog/llm-as-judge-best-practices-2026) (PoLL-style panels)
- V2 optimize pass + outcome research: the V2 outcome-research brief
- Skill by: **Neal Meyer**
