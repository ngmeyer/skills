# adversarial-review — Eval harness

**Level:** Prompt-only (writes one report at most). Behavioral testing requires fixture artifacts + LLM-as-judge against recorded baselines — moderate fixture cost, deferred. This harness asserts the design contract: 6 phases, 5 attack vectors, 3 severity tiers, mandatory output sections, sibling-skill distinction, anti-fluff invariants, and research positioning.

## What's asserted

- All 6 phases present (SCOPE → READ → ATTACK → TRIAGE → PRESENT → SAVE)
- All 5 attack-vector flags (`--security`, `--logic`, `--user`, `--scale`, `--quick`)
- All 3 severity tiers (CRITICAL / IMPORTANT / NIT)
- Mandatory output sections: "What I Could Not Break" and "What This Review Did NOT Cover"
- Sibling-skill distinction (`/council-review` referenced, open-question redirect rule documented)
- Anti-fluff invariants ("do not be balanced", "do not pad findings", "do not speculate without an example")
- Research positioning (M3MADBench citation for adversarial-vs-collaborative distinction; Codex precedent)
- **Portability:** no `/Users/<name>/` or `/home/<name>/` hardcoded paths
- README, LICENSE, CLAUDE.md all shipped

## Run

```bash
bash tests/eval.sh
```

Exit 0 = contract intact. Exit 1 = regression.

## What this does NOT test

- Whether the skill actually finds CRITICAL bugs at runtime (vs nits)
- Whether the triage ranking is calibrated (likelihood × blast radius)
- Whether "What I Could Not Break" is substantive vs perfunctory
- Whether the open-question redirect actually fires correctly on input
- Whether the five attack vectors produce non-overlapping findings

Those need fixture artifacts (a known PR with known flaws + an expected-findings baseline). When a real run produces output worth freezing as baseline, copy it into `tests/fixtures/golden/` and add a diff assertion.

## Extending

- Every time a real run misses a CRITICAL flaw the skill should have caught, add a fixture + assertion.
- New attack vectors → add to the flag-presence checks.
- Platform-specific bugs → add portability assertions.
