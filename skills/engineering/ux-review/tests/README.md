# ux-review — Eval harness

**Level:** Contract + arithmetic. The review is model-written, so this pins what a model will not hold on its own: the contract in `SKILL.md`, catalog completeness (30 laws, H1-H10, every WCAG and platform key the example uses), the schema, and the scoring math. It recomputes every derived number in `references/example-page.json` (ids, priority scores, tiers, item scores, section %, overall %, grade cap, summary, order) and fails if the example and the rules disagree.

Run `bash tests/eval.sh` (set `PYTHON=` to an interpreter with `jsonschema` for full schema validation). Exit 0 = contract intact. `SKIP` is not a pass.

**Private-name scan.** The repo is public, so the list of names that must never appear is not committed (a published denylist is itself the leak). Put one term per line in `tests/private-terms.local` (gitignored), or point `UX_PRIVATE_TERMS` at a file. Hits are reported by file, never by term. `UX_PRIVATE_TERMS` set but missing = FAIL.

**Not tested:** whether a real run finds what a human reviewer would, whether severity and confidence are calibrated across runs, whether the loop stops at the right iteration. Those need captured targets and a frozen expected-findings baseline; keep any private one outside the repo.
