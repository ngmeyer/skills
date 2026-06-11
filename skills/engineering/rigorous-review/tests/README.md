# rigorous-review — Eval harness

**Level:** Prompt-only (writes one report; optionally applies safe fixes on request). Behavioral
testing needs fixture codebases with seeded findings + a recorded precision/recall baseline —
moderate fixture cost, deferred to the first real audit run. This harness asserts the **design
contract**: the scoring engine, the four lanes, the behavior-preservation guarantee, and the
load-bearing invariants.

## What's asserted

- **Identity** — behavior-preserving ("no observable change", byte-for-byte for legitimate
  callers), report-first deliverable, production read-only, safe-vs-gated, authorization-fixes-are-safe
- **Two axes + gate** — severity P0–P3 × confidence 0/25/50/75/100, independent; suppress <75
  with the **P0-at-50 exception**; per-lane asymmetry (security lower bar / performance higher bar)
- **Noise control** — do-NOT-flag lists + settled-precedents table; "check callers before flagging"
- **Synthesis** — fingerprint dedup (`line_bucket`) + agreement promotion on 2+ lanes
- **Independent validator wave** — fresh agent per finding, no commitment, degraded-keep on crash,
  and a guard that the V1 self-recheck phrasing did **not** survive
- **Four lanes** incl. **correctness** (error-masking, TOCTOU detail checked in the reference)
- **Behavior-preservation** — API-contract additive-vs-mutative + silent-semantics-change; the
  Phase-5 boundary-walk verifier (stop at first broken boundary)
- **Coverage** — SSRF / insecure deserialization / OWASP-2025 (security), Core Web Vitals /
  serverless (perf), real dead-code tooling / Fowler / two-adapter seam (refactor)
- **Process layer** — effort dial (precision↔recall), model-tiering
- **Phases 0–5** present, fan-out precedes validation
- **Convention** — Gotchas, V1 changelog, the three `references/` files exist, no root README
  (house format: `SKILL.md` + `tests/`), SKILL.md ≤ 500 lines

## Run

```bash
bash tests/eval.sh
```

Exit 0 = contract intact. Exit 1 = regression.

## What this does NOT test

- Whether a real run actually finds the real P0s (vs. noise) — precision/recall
- Whether the confidence anchors are calibrated, or the suppression lists actually fire
- Whether the independent validator wave kills the false positives it should
- Whether `safe` vs `gated` is classified correctly at runtime — the whole behavior-preservation
  guarantee
- Whether an applied "safe" fix truly left the observable flow unchanged

Those need fixture codebases (a repo with known seeded findings + an expected-findings baseline).
When the first real audit produces output worth freezing, drop it under `tests/fixtures/golden/`
and add a diff assertion. This is the pending empirical validation noted in the SKILL.md changelog.

## Extending

- Every time a real run misses a finding it should have caught, add a fixture + assertion.
- New lanes or coverage checks → add to the lane/coverage presence checks.
- New engine mechanics → assert them structurally so a future edit can't silently drop them.
