# Suggested follow-up: review-pass telemetry

**Status: sound method, one data point.** The metric definitions come from a reusable
scorecard grounded in published software-engineering literature — Bacchelli & Bird
(ICSE 2013) on what review actually produces; Czerwonka, Greiler & Tilford (ICSE SEIP
2015), who found only ~15% of reviewer comments indicate a possible defect; Sadowski et
al. (ICSE-SEIP 2018) on review latency across ~9M Google changes, as the industry analog
for time-to-first-finding; Johnson et al. (ICSE 2013) on false positives blocking
adoption of defect finders; and NIST SP 500-326 (SATE V) for precision/recall
methodology. The definitions are worth adopting.

What is **not** established is any number for *these* skills. The scorecard was filled
once, against one PR, and it honestly marks precision, recall, FP rate, TTFF and escape
rate all **TBD** for want of outcome tags and timestamps — which is exactly the gap the
items below close. So: build the instrumentation, and do not quote a rate until it has
been measured more than once. Published figures are methodology grounding, never targets.

Not part of `learn` v0.1; each item is a separate PR against the review skills, plus one
hook here.

1. **adversarial-review, council-review:** closing `## Telemetry` block — `pass_started_at`, `first_finding_at` (ISO), table `id | severity | outcome | decided_by`, outcome ∈ accepted/fixed/dismissed_fp/deferred/unaddressed (default unaddressed). Enables TTFF, precision proxy, FP rate.
2. **adversarial-review (+ council CRITICAL path):** CRITICAL invalid unless Trigger + What breaks + `[reproduced]` or `[not-reproduced: reason]`; only `[reproduced]` counts toward validated rate. Add eval assert.
3. **Simplification/over-engineering review skills** (not in this repo): two labeled lines `loc_delta`/`deps_removed` and `correctness_bugs: none|N (defer to adversarial)` + `applied_vs_estimated`.
4. **learn hook (closes escape-rate gap):** when learn runs on a merge, read any review-pass Telemetry blocks linked to the PR and set final outcomes (fixed if the finding's file:line changed in the merge, else deferred/dismissed with reason); record post-merge defects later attributed to this PR as escapes. Write to `docs/review-telemetry/<pr>.md` only if the repo opted in.

Before building any of it, note the obvious trap: a telemetry block is context that loads
on every pass, so it has to earn its lines the same way a lesson does.
