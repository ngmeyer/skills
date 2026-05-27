# Optimize mode — take an existing skill to V2

Make a working skill **measurably better at the outcome it exists to produce** — not just better packaged. A tidy refactor that doesn't move the outcome is not a V2. This is the ce-optimize discipline (define a metric, experiment, keep what wins) applied to a skill's *output*.

## When to use
The skill already exists and fires correctly, but you suspect its *output* could be stronger — better decisions, fewer misses, sharper writing, more reliable results. Not for fixing a broken trigger (that's a quality fix) or creating something new (that's `forge`).

## The loop

### 1. Define the outcome + how to measure it
State, in one sentence, what *great* output from this skill looks like — the real-world result, not "well-structured." Then pick a measurement you can actually run:
- **LLM-as-judge rubric** (3–5 weighted dimensions scored 1–5) — default for subjective outputs (memos, reviews, research).
- **Hard gates** (pass/fail checks) — for outputs with objective requirements.
- **Before/after on a real task** — run the skill on a genuine recent example, score V1's output now as the baseline.

No metric → no optimize. "Seems better" is not a result. Write the rubric down before changing anything.

### 2. Quality audit (necessary, not sufficient)
Run the `forge` Review Checklist against the current skill: description-as-router, line budget, progressive disclosure, **Gotchas built from real failures**, anti-patterns, 3-stage testing. Note fixes — but remember these improve *reliability/packaging*, not the *outcome ceiling*. Don't stop here; that's the trap this mode exists to escape.

### 3. Outcome research (the part that raises the ceiling)
Research the skill's **domain** for state-of-the-art techniques and evidence that would improve the outcome metric from step 1. Use `librarian-deep-research` (searches the vault + Exa/Tavily/web in parallel and saves the brief back to the vault, so each skill's research compounds).

- Frame the query around the *outcome*, not the skill: for a review skill, "what techniques catch the most real defects"; for a memo skill, "what makes decision memos change decisions"; for a debate skill, "latest multi-agent deliberation methods that beat single-pass."
- Extract only **concrete, evidence-backed changes**: a new procedure step, a heuristic, a better default, a failure mode to guard. Each candidate change should name the source and the outcome dimension it targets.
- Skip findings that are interesting but don't move the metric.

### 4. Synthesize V2
Fold the winning candidate changes + the quality fixes into the skill. Then:
- Add a `## Changelog` section: `## V2 (YYYY-MM-DD)` with one line per change — *what changed, why, and the evidence/source*. A reader must be able to trace every V2 change to either a quality rule or a research finding.
- Keep the line budget; push new detail into `references/` rather than bloating SKILL.md (more context isn't better — auto-bloat degrades agents).
- Preserve the skill's voice and triggers; optimize the procedure, don't rewrite the identity.

### 5. Verify — measure V2 vs V1
Run the step-1 task on **both** V1 and V2; score both against the rubric/gates.
- Keep only the changes that move the metric. If a research-inspired change scores worse, drop it and note why in the changelog.
- If V2 doesn't beat V1 overall, it isn't a V2 — iterate (back to 3) or revert. Shipping a "V2" that didn't measurably improve is the failure this mode prevents.
- Record the V1→V2 delta in the changelog (e.g. "judge score 3.4 → 4.2; biggest gain: completeness").

## Output
- The V2 skill (same dir; old version recoverable via git).
- A `## Changelog` entry with the evidence trail and the measured delta.
- The research brief saved in the vault (via librarian-deep-research), linked from the changelog.

## Gotchas
- **Tidying ≠ optimizing.** If your V2 diff is all formatting and frontmatter, you skipped step 3.
- **Unmeasured "improvements" regress.** Without step 5 you can't tell a real gain from a plausible-sounding one — and research-sourced ideas are exactly the plausible-sounding kind. Measure.
- **Don't bulk-add research.** Fold in the 2–4 changes that move the metric, not every finding. A longer skill is usually a worse skill.
- **One skill at a time.** Optimize + verify a single skill before batching others, so the metric attribution stays clean.
