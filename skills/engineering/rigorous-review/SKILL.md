---
name: rigorous-review
description: >
  Audit a web codebase for security, performance, correctness, and refactoring
  improvements WITHOUT changing any outward-facing behavior. Fans out parallel
  read-only reviewers, scores findings on two axes (severity × confidence),
  suppresses predictable false positives, validates survivors with an INDEPENDENT
  wave (not self-recheck), classifies safe vs. gated, and writes a report. Applies
  only behavior-preserving fixes, and only on request. Use when: 'rigorous review',
  'hardening audit', 'security and performance audit', 'internal audit', 'harden the
  codebase', 'audit for security/perf/refactoring', 'tech-debt audit', 'review this
  codebase without changing behavior'.
user-invocable: true
allowed-tools: ["Read", "Grep", "Glob", "Bash", "Agent", "Write", "Edit"]
argument-hint: "[path to scope] [--effort low|medium|high|max] [apply-safe]"
---

# /rigorous-review

Investigate a codebase for **security**, **performance**, **correctness**, and
**refactoring** improvements under one hard constraint: **no observable change to any
outward-facing page or API.** Rendered HTML of public routes, URL structure, JSON
response shapes, auth flows, and admin UI behavior must all be byte-for-byte equivalent
for *legitimate* callers after any fix.

The deliverable is a **report**. Fixes are applied only when the user asks, and only the
ones classified `safe`.

## Core principles

1. **Verify before reporting.** Every finding is read end to end (route → helper → query;
   for security, **trace the data from its entry point to the dangerous sink**) and cited
   with `file:line` + a code quote. Lead the evidence with the **observable consequence** —
   what a user, attacker, or operator experiences — not the code structure. No findings
   from names or assumptions.
2. **Two scoring axes, then a gate.** Every finding carries a **severity** (P0–P3, impact)
   *and* a **confidence** (0/25/50/75/100, how sure you are). They are independent — a real
   exploit you can only half-prove is *P0 × 50*, not a P2. The gate (below) decides what
   surfaces. This is the single biggest signal-to-noise lever in the skill.
3. **Suppress predictable false positives.** A noisy audit gets ignored. Before emitting any
   finding, check it against the **do-NOT-flag lists and settled-precedents table**
   ([references/scoring-gating-validation.md](references/scoring-gating-validation.md)).
   "Already handled by middleware / the framework / a parallel handler" is the most common
   miss — check callers before flagging.
4. **Safe vs. gated is load-bearing.** It protects the "no outward-facing change" guarantee.
   - `safe` — behavior-preserving for legitimate callers; no schema change, no infra.
     **Authorization fixes are `safe`**: rejecting an *unauthorized* caller is the intent,
     not a regression. Same for a guard legitimate callers already satisfy.
   - `gated` — any risk of observable change, a schema/migration change, a data-semantics
     change, or new infra. Report-only; never apply silently.
5. **Production is read-only.** No migrations, no `drizzle-kit push`, no script runs against
   prod, no destructive commands. Schema/index recommendations go in the report only.
6. **Surgical.** Don't "improve" adjacent code, comments, or formatting beyond a fix.

## The gate (how severity × confidence decides what surfaces)

Apply **after** synthesis, **before** the report:

- **Suppress anything below confidence 75** — *except* a **P0 at confidence ≥50 survives**
  (critical-but-uncertain must never be silently dropped; it goes to the validator wave).
- **Per-lane asymmetry** — the cost of a miss differs by lane, so the bar does too:
  - **Security: lower bar.** A security finding at confidence 50 is typically filed **P0**
    so it survives the gate. Missing a real vuln costs more than a false alarm.
  - **Performance: higher bar.** Suppress speculative/premature-optimization findings rather
    than routing them through 50. A false perf finding wastes engineering time.
  - Correctness and refactoring use the standard bar.
- **Effort dial** (`--effort`, default `medium`): `low`/`medium` report
  **high-confidence only** (≥75) — fewer, surer findings. `high`/`max` widen recall (surface
  gated-50s for triage, run the validator wave on more findings). Match depth to the request.

Full anchor definitions, the dedup fingerprint, agreement promotion, the validator-wave
protocol, and the precedents table: **[references/scoring-gating-validation.md](references/scoring-gating-validation.md)**.

## Procedure

### Phase 0: Orient (cheap, before fan-out)

1. Identify the stack and the **authorization model**. Critically: **is there a
   `middleware.ts` / central auth layer, or does each route/action guard itself?** State the
   answer up front — it changes how the security pass reads every endpoint.
   (`grep -r "middleware"` at the app root; check the framework's auth entry points.)
2. Inventory the surface: public routes, admin routes, API routes, server actions/RPC, and
   DB-touching scripts. A read-only `Explore` agent is good for this. **Produce a finding for
   any surface element with no corresponding guard** (the attack-surface-inventory rule).
3. Note project invariants from `CLAUDE.md`/`AGENTS.md` (tenancy scoping, PII rules, money/
   units conventions). Pass these verbatim to reviewers as "violating this is a P0."
4. **Pick the effort level** (default `medium`) and **assign model tiers**: the **security**
   and **correctness** reviewers inherit the session model (high-stakes, miss-cost high); the
   **performance** and **refactoring** reviewers may run a mid-tier model (~3–4× cheaper, no
   quality loss on lower-stakes lanes). State the assignment.

### Phase 1: Fan out four parallel reviewers

Dispatch four `Agent`s in one message (`run_in_background: true`), each **READ-ONLY**, each
told to: verify every finding against the full code path, score it on **both axes**, classify
`safe`/`gated`, and **apply its lane's do-NOT-flag list before emitting.** Each returns
findings (`id`, severity, confidence, title, `file:line`, evidence quote + observable
consequence, fix sketch, class, lane) plus a short inventory with a one-word verdict per item.

The four lanes, with full checklists in **[references/reviewer-lanes.md](references/reviewer-lanes.md)**:

- **Security** *(session model; lower bar)* — authorization on every mutation and admin read
  (session check **and** tenant/ownership check against the *target* resource); server
  actions/RPC audited as real endpoints; **mandatory secrets scan** of git-tracked files;
  taint-trace untrusted input to sinks; **SSRF, insecure deserialization, CSRF, dangerous
  sinks** (`dangerouslySetInnerHTML`, `exec` interpolation, `eval`/`new Function`); map each
  finding to **OWASP Top 10:2025 + CWE**.
- **Performance** *(mid-tier; higher bar)* — query count per render (N+1, sequential awaits →
  `Promise.all`/join — **confirm the loop is real first**); missing indexes (`gated`);
  over-fetching; **Core Web Vitals** (LCP/INP/CLS, image/font, barrel imports, RSC
  serialization); **serverless traps** (in-process caches broken across invocations, ephemeral
  FS writes, unauthenticated cron). Project impact at 10×/100×/1000× data volume.
- **Correctness** *(session model; standard bar)* — off-by-one and boundary/pagination
  (exact-multiple-of-page-size); null/undefined propagating to `"undefined"`/`NaN`;
  **error-masking fallbacks** (empty array instead of propagating a failed query); TOCTOU and
  half-updated state; race conditions.
- **Refactoring** *(mid-tier; standard bar)* — dead code **proven with real tooling**
  (`knip`/`ts-prune`/`ruff F401`/`ast-grep`, accounting for barrel files, dynamic `import()`,
  framework exports — not bare grep); drift-prone duplication (**P1 if the copies already
  disagree**); **Fowler 5-family smell taxonomy**; the **Deletion Test** and **two-adapter
  seam rule** (don't recommend a single-use abstraction); TS type-safety
  (`noUncheckedIndexedAccess`, Result-vs-throw, discriminated unions). Deletion recs are `gated`.

Plus an **API-contract check** that guards the core invariant directly (additive-vs-mutative,
silent-semantics-change like "`count` used to include deleted rows, now it doesn't"):
**[references/behavior-preservation.md](references/behavior-preservation.md)**.

### Phase 2: Synthesize (dedup + promote + gate)

Do **not** just concatenate the four outputs. In order:
1. **Dedup** by fingerprint `normalize(file) + line_bucket(line, ±3) + normalize(title)` — the
   same bug flagged by two lanes is one finding, not two.
2. **Agreement promotion** — when 2+ lanes flag the same fingerprint, raise its confidence one
   step (50→75, 75→100). Independent corroboration is evidence.
3. **Apply the gate** (above): drop sub-75 except P0-at-50; honor per-lane asymmetry and the
   effort dial. Weak P2/P3 survivors go to a `residual risks` / `advisory` tier in the
   report, not the main tables.

### Phase 3: Independent validator wave (replaces self-recheck)

Do **not** re-verify your own synthesis — the orchestrator that merged the findings is not an
independent second opinion (it catches a wrong fact but not its own bias). Instead, for **every
surviving P0 and P1**, spawn a **fresh** validator `Agent` with **no commitment to the
finding** ("False positives are common; do not feel pressure to confirm"). One validator per
finding (a single batched validator recreates the bias). The validator reads the code path
cold and returns confirm / downgrade / reject with its own evidence.
- **Degraded-keep on crash:** if a *validator* fails to return (vs. rejects), P2/P3 drop
  (conservative) but **P0/P1 are kept and marked "degraded — unvalidated"** — a transient
  failure must never silently remove a critical finding.
- At `low`/`medium` effort, validate P0/P1; at `high`/`max`, also validate P2.

### Phase 4: Write the report

Write to `docs/audits/YYYY-MM-DD-rigorous-review.md`:
- A **TL;DR** of the few things that actually matter, with a recommended order.
- **Four findings tables** (security / performance / correctness / refactoring), each row:
  id, severity, **confidence**, title, file:line, class, OWASP/CWE (security only).
- An **advisory / residual-risks** tier for the soft-bucketed P2/P3 survivors.
- A **"verified clean"** section — what was checked and found safe, so nobody re-audits it.
- A **recommended execution order**: secrets/credential rotation and unauthenticated-write
  closures first, then safe perf wins, then gated items (with approval), then maintainability.
- An explicit note that **no production data was touched and no fixes were applied.**

### Phase 5: Apply safe fixes — only if asked

If the user passes `apply-safe` (or asks afterward):
- Apply **only** `safe` findings, **highest-confidence first**. One commit per concern,
  conventional message. Never push.
- After each fix, run the **behavior-preservation verifier**: infer the user story the changed
  code serves and walk it boundary-by-boundary (request → handler → data → response),
  confirming the observable result is unchanged for a legitimate caller.
  **Stop at the first broken boundary.** Tests passing is necessary, not sufficient — the
  verifier proves the *flow*. Protocol: [references/behavior-preservation.md](references/behavior-preservation.md).
- Run the project's test command and build after each; both must pass before the next.
- Never apply a `gated` item. If a "safe" fix turns out to risk observable change once you're
  in the code, **stop and re-classify it as gated.**
- Recommend landing security fixes on their own focused branch.

## Gotchas / lessons baked in

- **A finding without a confidence is half a finding.** Severity says how bad *if real*;
  confidence says how sure it's real. Reporting a speculative P0 as if verified is how audits
  lose trust — and dropping an uncertain P0 is how they miss the breach. The gate needs both.
- **The secrets scan is not optional and is easy to miss.** In testing, the dedicated security
  pass missed a committed DB credential a different reviewer caught by luck. A committed secret
  is P0 and needs **rotation**, not just deletion — it's in git history.
- **Self-recheck is not validation.** The orchestrator synthesized the findings, so re-reading
  them confirms its own bias. The independent validator wave (Phase 3) is the fix; don't skip
  it back to a self-pass to save agents.
- **Check callers before flagging.** The top false positive is "missing guard / validation"
  on code already guarded by middleware, a framework default, or a parallel handler. The
  do-NOT-flag list exists because reviewers emit these constantly.
- **State the auth model in Phase 0.** Reviewers otherwise waste effort rediscovering that
  there's no central middleware and every endpoint self-guards.
- **Don't let a "refactor" change data.** When duplicated transforms already disagree, picking
  one semantic *is* a data decision — `gated`, not a quiet cleanup. Same for any API-contract
  shift.
- **Dead-code-by-grep lies.** Barrel files, dynamic imports, and framework route exports make
  a symbol look unused when it isn't. Prove deletion with real tooling, and deletion is `gated`.
- **Scope:** an optional path arg narrows the audit; default is the whole app. Match reviewer
  depth to scope and to `--effort`.

## Changelog

### V1 (2026-06-10)
First release of `rigorous-review`. Distilled from a working prototype (`internal-hardening-audit`)
that was forged by running it for real on two production web codebases (Fable/Opus — good
results; it surfaced a committed DB credential the dedicated security pass had missed), then
hardened with a 3-agent research synthesis across CE reviewer agents, the built-in
`code-review`/`security-review`, Vercel skills, Anthropic `security-review`, Matt Pocock's
architecture skill, OWASP Top 10:2025, Fowler smells, and Core Web Vitals. The design, each piece
traceable to a source:
- **Two scoring axes + a gate** (CE `ce-code-review` 5-anchor confidence; Anthropic's ≥0.8
  report threshold) — severity alone can't express "critical but unverified"; the gate is the
  main precision lever (suppress <75 except P0-at-50).
- **Do-NOT-flag lists + settled-precedents table** (Anthropic's 18 excludes; CE's false-positive
  catalog) — the highest-yield single addition for signal-to-noise.
- **Independent validator wave, not self-recheck** (CE: the synthesizer can't be its own unbiased
  checker) — fresh agent per P0/P1, degraded-keep on crash.
- **Cross-reviewer dedup (fingerprint) + agreement promotion** (CE merge pipeline) — parallel
  reviewers corroborate instead of double-listing.
- **Per-lane threshold asymmetry** (CE security-lower / perf-higher) — a flat bar under-reports
  security and over-reports premature optimization.
- **Four lanes** — security, performance, refactoring, and **correctness** (off-by-one, null
  propagation, error-masking, TOCTOU, races); the built-in `code-review` and Anthropic both
  centre correctness.
- **API-contract / behavior-preservation check** — guards the core invariant directly
  (additive-vs-mutative, silent-semantics-change).
- **Coverage** — security: SSRF (OWASP A01), insecure deserialization, CSRF, dangerous-sink
  watchlist, OWASP-2025/CWE tags. Perf: Core Web Vitals, image/font, barrel imports, RSC
  serialization, serverless cache/FS/cron. Refactor: real dead-code tooling
  (knip/ts-prune/ast-grep), Fowler 5-family taxonomy, Pocock Deletion Test + two-adapter seam
  rule, TS type-safety.
- **Process layer** — effort dial (precision↔recall), model-tiering (security+correctness =
  session model, perf+refactor = mid-tier), Phase-5 behavior-preservation verifier.
- Heavy checklists live in `references/` to keep SKILL.md lean.

Empirical precision/recall validation is pending the next real audit run.

## References
- [references/reviewer-lanes.md](references/reviewer-lanes.md) — full per-lane checklists
  (security / performance / correctness / refactoring) + each lane's do-NOT-flag list.
- [references/scoring-gating-validation.md](references/scoring-gating-validation.md) —
  confidence anchors, the gate, per-lane asymmetry, dedup fingerprint, agreement promotion,
  validator-wave protocol, degraded-keep, settled-precedents table, effort dial, model-tiering.
- [references/behavior-preservation.md](references/behavior-preservation.md) — API-contract
  additive-vs-mutative + silent-semantics-change check, and the Phase-5 boundary-walk verifier.

## Testing
`tests/eval.sh` asserts the design contract structurally (two axes + gate, P0-at-50 exception,
suppression lists, independent validator wave, dedup + promotion, four lanes incl. correctness,
API-contract check, OWASP/CWE + SSRF/deserialization, Core Web Vitals, real dead-code tooling,
effort dial, model-tiering, behavior-preservation verifier, prod-read-only, safe-vs-gated).
Behavioral validation is the next real audit run (re-audit the same codebases and compare
finding precision/recall against the prototype baseline).
