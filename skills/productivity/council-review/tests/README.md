# council-review — Eval harness

**Level:** Compound (orchestrates 11 parallel agent calls in full mode).
Compound skills can't be unit-tested for behavior. This harness locks in the
**design contract** — SKILL.md must still name every advisor, mode, and step
its README and CLAUDE.md claim. Drift here means the advertised behavior no
longer matches the implementation.

## What's asserted

- All 5 advisor personas named in SKILL.md (Contrarian, First Principles, Expansionist, Outsider, Executor)
- All 5 DMAD reasoning methods named (Inversion, Decomposition, Analogy, Naive questioning, Dependency graphing)
- Both mode flags documented (`--quick`, `--adversarial`)
- All 6 execution steps present (Step 0 through Step 5)
- Anonymization invariant present (non-negotiable per CLAUDE.md)
- Scope validation guard present
- README names the skill and documents install
- LICENSE file shipped

## Run

```bash
bash tests/eval.sh
```

Exit 0 = contract intact. Exit 1 = regression in the advertised contract.

## What this does NOT test

- Whether 5 advisor agents actually spawn (no runtime invocation)
- Whether peer review is truly anonymized at runtime
- Whether the chairman synthesis is high quality
- Whether disagreement classification fires correctly

Those are **behavioral** properties that need LLM-as-judge against recorded
golden runs. Deferred until baseline data exists.

## Extending

- If a future PR adds a 6th advisor, add it to the advisor assertions.
- If a mode flag is renamed, update the eval.
- Every recorded real-world miss should produce a new assertion here.
