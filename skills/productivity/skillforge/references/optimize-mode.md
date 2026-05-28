# Optimize mode — take an existing skill to V2

Make a working skill **measurably better at the outcome it exists to produce** — not just better packaged. A tidy refactor that doesn't move the outcome is not a V2. This is the ce-optimize discipline (define a metric, experiment, keep what wins) applied to a skill's *output*.

## When to use
The skill already exists and fires correctly, but you suspect its *output* could be stronger — better decisions, fewer misses, sharper writing, more reliable results. Not for fixing a broken trigger (that's a quality fix) or creating something new (that's `forge`).

## The loop

### 1. Define the outcome + how to measure it
State, in one sentence, what *great* output from this skill looks like — the real-world result, not "well-structured." Then pick a measurement you can actually run:
- **LLM-as-judge rubric** (3–5 weighted dimensions scored 1–5) — default for subjective outputs (memos, reviews, research). Same hard-vs-judge decision `ce-optimize` makes: use judge when a human would have to *read* the output to say it's better.
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
Research the skill's **domain** for state-of-the-art techniques and evidence that would improve the outcome metric from step 1. Use `librarian-deep-research` (searches the vault + Exa/Tavily/web in parallel and saves the brief back to the vault, so each skill's research compounds).

- Frame the query around the *outcome*, not the skill: for a review skill, "what techniques catch the most real defects"; for a memo skill, "what makes decision memos change decisions"; for a debate skill, "latest multi-agent deliberation methods that beat single-pass."
- Extract only **concrete, evidence-backed changes**: a new procedure step, a heuristic, a better default, a failure mode to guard. Each candidate change should name the source and the outcome dimension it targets.
- Skip findings that are interesting but don't move the metric.

### 5. Synthesize V2
Fold the winning candidate changes + the quality fixes into the skill. Then:
- Add a `## Changelog` section: `## V2 (YYYY-MM-DD)` with one line per change — *what changed, why, and the evidence/source*. A reader must be able to trace every V2 change to either a quality rule or a research finding.
- Keep the line budget; push new detail into `references/` rather than bloating SKILL.md (more context isn't better — auto-bloat degrades agents).
- Preserve the skill's voice and triggers; optimize the procedure, don't rewrite the identity.

### 6. Verify — measure V2 vs V1 on a benchmark
Score **both** V1 and V2 against a **benchmark — a small held-out set of real tasks, not a single example.** One or two cases is an anecdote; the loop will overfit to it. Aim for ~10–20 representative tasks covering the shapes the skill actually faces (evo's SealQA run used 20). Score blind where possible (a judge that doesn't know which output is V1 vs V2).
- **Apply the gates first** (step 2): discard any V2 that fails a gate or the no-cheating audit, even if it scored higher.
- Keep only changes that move the metric on the held-out tasks. If a research-inspired change scores worse, drop it and note why in the changelog.
- If V2 doesn't beat V1 overall, it isn't a V2 — iterate (back to step 4) or revert. Shipping a "V2" that didn't measurably improve is the failure this mode prevents.
- Record the V1→V2 delta in the changelog (e.g. "judge 3.8 → 4.8 across 20 tasks; biggest gain: risk-surfacing").

## Going heavy — when to delegate (don't rebuild the loop)
The steps above are the lightweight, single-skill path: one V2, hand-run, fast. When you want serious optimization — many hypotheses, parallel experiments, a real benchmark run for hours — **don't rebuild that machinery here.** Hand off:
- **`ce-optimize`** (installed CE skill) — point its spec at the skill file as `scope.mutable`, your benchmark as the metric, your gates as `degenerate_gates`. It runs parallel worktree experiments, keeps only gated winners, persists every result to disk, and converges on a plateau. This optimize mode *is* ce-optimize's discipline scoped to one skill; for the full loop, drive ce-optimize directly.
- **`evo`** (open source, evo-hq.com) — purpose-built to optimize a whole Skills *directory* against a benchmark, with parallel exploration, tree search (keep + merge specialists), and a built-in no-cheating auditor. Spike it when you want all of `~/.claude/skills/` tuned, not one skill.

What stays unique to skillforge and is worth doing by hand: the **outcome-research** hypothesis source (step 4) and the **skill-quality audit** (step 3) — neither ce-optimize nor evo does those; they optimize against a metric but won't go read the domain's state of the art for you.

## Output
- The V2 skill (same dir; old version recoverable via git).
- A `## Changelog` entry with the evidence trail and the measured delta.
- The research brief saved in the vault (via librarian-deep-research), linked from the changelog.

## Gotchas
- **Tidying ≠ optimizing.** If your V2 diff is all formatting and frontmatter, you skipped step 4 (outcome research).
- **Unmeasured "improvements" regress.** Without step 6 you can't tell a real gain from a plausible-sounding one — and research-sourced ideas are exactly the plausible-sounding kind. Measure on a benchmark.
- **No gates → gamed metric.** The step-2 no-cheating audit is not optional. A judge score that jumped because the skill learned to flatter the rubric (or quietly narrowed its own scope) is a regression wearing a win's clothing.
- **A benchmark of one is an anecdote.** A single test case overfits. Use a held-out set; this is the difference between the council-review A/B (one question — suggestive) and a real verification (evo's 20).
- **Don't bulk-add research.** Fold in the 2–4 changes that move the metric, not every finding. A longer skill is usually a worse skill.
- **One skill at a time** for the hand-run path. For many skills or a long run, that's the signal to delegate to ce-optimize/evo, not to grind manually.

## Lineage
This mode = the metric-driven optimization discipline of **`ce-optimize`** (CE plugin) and **`evo`** ([alokbishoyi97, evo-hq.com](https://x.com/alokbishoyi97/status/2059610305408462898) — parallel exploration, tree search, gates, no-cheating auditor), scoped to a single skill and fronted with an outcome-research hypothesis source. See vault: [[alok-bishoyi-evo-autoresearch-skills]].
