# Optimize mode — take an existing skill to V2

Make a working skill **measurably better at the outcome it exists to produce** — not just better packaged. A tidy refactor that doesn't move the outcome is not a V2. This is metric-driven optimization — define a measurable "better", experiment, keep only what wins — applied to a skill's *output*.

## When to use
The skill already exists and fires correctly, but you suspect its *output* could be stronger — better decisions, fewer misses, sharper writing, more reliable results. Not for fixing a broken trigger (that's a quality fix) or creating something new (that's `forge`).

## The loop

### 1. Define the outcome + how to measure it
State, in one sentence, what *great* output from this skill looks like — the real-world result, not "well-structured." Then pick a measurement you can actually run:
- **LLM-as-judge rubric** (3–5 weighted dimensions scored 1–5) — default for subjective outputs (memos, reviews, research). The hard-vs-judge call: use a judge when a human would have to *read* the output to say it's better.
- **Hard metric** (a number with a clear direction) — for outputs with objective targets.

No metric → no optimize. "Seems better" is not a result. Write the rubric down before changing anything.

### 2. Set the gates (the anti-gaming step)
A metric alone gets gamed — the loop finds a way to score high while the output gets worse. Define **gates**: pass/fail checks that discard a candidate *even if it scores best*. (This is the lesson from evo/`ce-optimize`: "without gates, optimization loops find ways to game the metric.")
- **Degenerate gates** — catch obviously broken results (empty output, the skill deleted half its procedure, output is one line). Cheap; run first.
- **No-cheating audit** — verify the V2 didn't smuggle the rubric's answers into the skill, hard-code the test case, or win by narrowing scope. An accepted change that only passes by teaching to the test is a fail.
- **Held-out check** — reserve part of your benchmark (see step 5) the changes were *not* tuned against.

A change that fails any gate is discarded regardless of score.

### 3. Quality audit (necessary, not sufficient)
Run the `forge` Review Checklist against the current skill: description-as-router, line budget, progressive disclosure, **Gotchas built from real failures**, anti-patterns, 3-stage testing. Note fixes — but remember these improve *reliability/packaging*, not the *outcome ceiling*. Don't stop here; that's the trap this mode exists to escape.

### 4. Outcome research (the part that raises the ceiling)
Research the skill's **domain** for state-of-the-art techniques and evidence that would improve the outcome metric from step 1. Do a multi-source web search (and, if you happen to run a vault-integrated research skill, let it compound there — optional, not required).

- Frame the query around the *outcome*, not the skill: for a review skill, "what techniques catch the most real defects"; for a memo skill, "what makes decision memos change decisions"; for a debate skill, "latest multi-agent deliberation methods that beat single-pass."
- Extract only **concrete, evidence-backed changes**: a new procedure step, a heuristic, a better default, a failure mode to guard. Each candidate change should name the source and the outcome dimension it targets.
- Skip findings that are interesting but don't move the metric.

### 5. Synthesize V2
Fold the winning candidate changes + the quality fixes into the skill. Then:
- Add a `## Changelog` section: `## V2 (YYYY-MM-DD)` with one line per change — *what changed, why, and the evidence/source*. A reader must be able to trace every V2 change to either a quality rule or a research finding.
- Keep the line budget; push new detail into `references/` rather than bloating SKILL.md (more context isn't better — auto-bloat degrades agents).
- Preserve the skill's voice and triggers; optimize the procedure, don't rewrite the identity.

### 6. Verify — measure V2 vs V1 on a benchmark, with a train/val split
Score **both** V1 and V2 against a **benchmark — a small held-out set of real tasks, not a single example.** Aim for ~10–20 representative tasks covering the shapes the skill actually faces (evo's SealQA run used 20). Score blind where possible (a judge that doesn't know which output is V1 vs V2).

**Split it.** Divide the benchmark in two: a **tuning subset** (the cases your changes may have implicitly overfit to as you iterated) and a **validation subset** (never seen by the change process — the real win condition). Score V2 on validation. If validation regresses while tuning improves, the change overfit; drop it. This is SkillOpt's discipline applied to a hand-run loop, and it catches the most common false-win: a "better" skill that learned the test rather than the task.
- **Apply the gates first** (step 2): discard any V2 that fails a gate or the no-cheating audit, even if it scored higher.
- Keep only changes that move the metric on the held-out tasks. If a research-inspired change scores worse, drop it and note why in the changelog.
- If V2 doesn't beat V1 overall, it isn't a V2 — iterate (back to step 4) or revert. Shipping a "V2" that didn't measurably improve is the failure this mode prevents.
- Record the V1→V2 delta in the changelog (e.g. "judge 3.8 → 4.8 across 20 tasks; biggest gain: risk-surfacing").

## Going heavy — optional external escalation
The steps above are self-contained: one V2, hand-run, fast, no other tooling required. Honestly, the hand-run is "one epoch, batch of one." When you want serious optimization — many hypotheses, parallel experiments, a benchmark run for hours, a paper-grade verification — and you have a dedicated optimization tool installed, escalate to it. Three that fit, all **external to this skill** (install separately):
- **`ce-optimize`** (the Compound Engineering plugin) — point its spec at the skill file as `scope.mutable`, your benchmark as the metric, your gates as `degenerate_gates`; it runs parallel worktree experiments inside Claude Code, keeps only gated winners, and converges. Best for in-session workflow integration.
- **`evo`** (open source, evo-hq.com) — optimizes a whole skills *directory* against a benchmark with parallel exploration, tree search (keep + merge specialists), and a no-cheating auditor. Best for an elegant architecture across a skill set.
- **SkillOpt** (Microsoft, MIT, [arxiv 2605.23904](https://arxiv.org/abs/2605.23904)) — trains markdown skills NN-style: **epochs, mini-batches, learning rate, validation gates**, with `best_skill.md` as the running champion. Ships with standardized benchmarks (SearchQA, ALFWorld, DocVQA, SpreadsheetBench, OfficeQA) and a published paper. Best for benchmark-driven rigor.

If you don't have any of them, the loop above is complete on its own. What this skill uniquely adds (and a generic optimizer won't): the **outcome-research** hypothesis source (step 4) and the **skill-quality audit** (step 3).

## Output
- The V2 skill (same dir; old version recoverable via git).
- A `## Changelog` entry with the evidence trail and the measured delta.
- The research brief saved alongside the skill (or in your knowledge base), linked from the changelog.

## Gotchas
- **Tidying ≠ optimizing.** If your V2 diff is all formatting and frontmatter, you skipped step 4 (outcome research).
- **Unmeasured "improvements" regress.** Without step 6 you can't tell a real gain from a plausible-sounding one — and research-sourced ideas are exactly the plausible-sounding kind. Measure on a benchmark.
- **No gates → gamed metric.** The step-2 no-cheating audit is not optional. A judge score that jumped because the skill learned to flatter the rubric (or quietly narrowed its own scope) is a regression wearing a win's clothing.
- **A benchmark of one is an anecdote.** A single test case overfits. Use a held-out set; this is the difference between the council-review A/B (one question — suggestive) and a real verification (evo's 20).
- **Don't bulk-add research.** Fold in the 2–4 changes that move the metric, not every finding. A longer skill is usually a worse skill.
- **One skill at a time** for the hand-run path. For many skills or a long run, that's the signal to delegate to ce-optimize/evo, not to grind manually.

## Lineage
This mode adapts the metric-driven optimization discipline of three converging lines of work — scoped to a single skill and fronted with an outcome-research hypothesis source the others don't do:
- **Compound Engineering `ce-optimize`** — spec + gates + parallel worktree experiments + persistence.
- **`evo`** ([alokbishoyi97](https://x.com/alokbishoyi97/status/2059610305408462898), evo-hq.com) — parallel exploration, tree search, gates, no-cheating auditor.
- **Microsoft SkillOpt** ([arxiv 2605.23904](https://arxiv.org/abs/2605.23904)) — NN-style training (epochs / batches / validation gates) on standardized benchmarks; the source of the train/val-split discipline in step 6.
