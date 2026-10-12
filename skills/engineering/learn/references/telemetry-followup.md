# Suggested follow-up: review-pass telemetry

**Status: suggestion, not a finding.** These come from a single scored code-review pass
(one PR, one reviewer agent) plus the research it cited. n = 1. Nothing here has been
measured across repos, so treat it as a shape worth trying and discard any item that does
not survive contact with a second real review. Not part of `learn` v0.1; each item is a
separate PR against the review skills, plus one hook here.

1. **adversarial-review, council-review:** closing `## Telemetry` block — `pass_started_at`, `first_finding_at` (ISO), table `id | severity | outcome | decided_by`, outcome ∈ accepted/fixed/dismissed_fp/deferred/unaddressed (default unaddressed). Enables TTFF, precision proxy, FP rate.
2. **adversarial-review (+ council CRITICAL path):** CRITICAL invalid unless Trigger + What breaks + `[reproduced]` or `[not-reproduced: reason]`; only `[reproduced]` counts toward validated rate. Add eval assert.
3. **Simplification/over-engineering review skills** (not in this repo): two labeled lines `loc_delta`/`deps_removed` and `correctness_bugs: none|N (defer to adversarial)` + `applied_vs_estimated`.
4. **learn hook (closes escape-rate gap):** when learn runs on a merge, read any review-pass Telemetry blocks linked to the PR and set final outcomes (fixed if the finding's file:line changed in the merge, else deferred/dismissed with reason); record post-merge defects later attributed to this PR as escapes. Write to `docs/review-telemetry/<pr>.md` only if the repo opted in.

Before building any of it, note the obvious trap: a telemetry block is context that loads
on every pass, so it has to earn its lines the same way a lesson does.
