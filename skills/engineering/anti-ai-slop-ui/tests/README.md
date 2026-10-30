# anti-ai-slop-ui — Eval harness

**Level:** Contract + arithmetic. Pins the contract in `SKILL.md`, the catalog (T01-T23, style weights summing to 99, the four proof tells), and the slop math. It parses the weights out of `references/tells.md`, then recomputes every derived number in `tests/fixtures/example-slop.json` (ids, priority scores, tiers, slop score, band, summary, order) and validates it against the shared schema owned by `ux-review`.

Run `bash tests/eval.sh` (set `PYTHON=` to an interpreter with `jsonschema`). Exit 0 = contract intact. `SKIP` is not a pass.

**Private-name scan:** same contract as `ux-review` (`tests/private-terms.local`, gitignored, or `UX_PRIVATE_TERMS`).

**Not tested:** whether the weights separate human-made from template pages (calibrate them on your own controls before gating on `slop_score`), and whether a real run finds the tells. Keep any private baseline outside the repo.
