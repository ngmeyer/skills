# Scoring, gating, validation — the engine

This is what turns four piles of reviewer output into a trustworthy report. Severity says how
bad a finding is *if real*; **confidence** says how sure it's real; the **gate** decides what
surfaces; **dedup + promotion** merges corroboration; the **validator wave** removes the
orchestrator's own bias. Adapted from CE's `ce-code-review` pipeline and Anthropic's
`security-review` confidence discipline.

---

## The two axes

### Severity (impact, if the finding is real)
- **P0** — exploitable vuln, data loss/corruption, or breakage of a public contract.
- **P1** — serious bug or a refactor smell with active harm (duplicated logic already disagreeing,
  a 1000+-line file gaining substantial code, a missing index on a hot path).
- **P2** — real but contained; worth fixing, not urgent.
- **P3** — minor / discretionary.

### Confidence (how sure the finding is real) — five anchors
Each anchor is a **behavior you performed**, not a vibe:
- **100** — verifiable from the code alone; you traced the full path and there is no plausible guard.
- **75** — you named a **concrete observable consequence** and traced the path, but one branch
  (a caller, a config) is unconfirmed.
- **50** — verified narrowly / advisory; plausible but you could not reach the whole path, or it
  depends on a runtime condition you can't see.
- **25 / 0** — speculative or pattern-matched. **Suppress silently** (don't even emit).

Anchor and severity are **independent**. A SQL injection you can only half-prove is **P0 × 50**.
A confirmed but trivial style issue is **P3 × 100**.

---

## The gate (apply after synthesis, before the report)

1. **Suppress everything below confidence 75** —
   **EXCEPTION: a P0 at confidence ≥50 survives.** Critical-but-uncertain must never be silently
   dropped; it goes to the validator wave (which either confirms it or rejects it with evidence).
2. **Per-lane asymmetry** (cost-of-miss differs by lane):
   - **Security — lower bar.** File a confidence-50 security finding at **P0** so it survives.
     The cost of missing a real vuln dwarfs the cost of a false alarm the validator will catch.
   - **Performance — higher bar.** **Suppress** speculative / premature-optimization findings
     rather than routing them through 50. A false perf finding wastes engineering time on
     optimization that wasn't needed.
   - **Correctness / Refactoring — standard bar** (75, P0-at-50 exception).
3. **Soft-bucket, don't drop, the weak survivors.** A P2/P3 that clears the bar but is advisory
   goes to a **`residual risks` / `advisory`** tier in the report — not a primary table, not the
   trash. Keeps the four main tables high-signal without losing the note.

### Effort dial (`--effort`, default `medium`)
- **`low` / `medium`** — report **high-confidence only** (≥75). Fewer, surer findings. Validate
  P0/P1.
- **`high` / `max`** — widen recall: surface gated-50s for human triage, and run the validator
  wave on P2 as well. Use when the user wants thoroughness over a short report.

---

## Dedup + agreement promotion (Phase 2)

Four reviewers overlap. Before the gate:

1. **Fingerprint** each finding: `normalize(file) + line_bucket(line, ±3) + normalize(title)`.
   - `normalize(file)` — repo-relative path, lowercased.
   - `line_bucket(line, ±3)` — group lines within 3 of each other (reviewers cite slightly
     different lines for the same issue).
   - `normalize(title)` — lowercase, strip punctuation, collapse whitespace.
2. **Merge** findings that share a fingerprint into one (keep the richest evidence, union the lanes).
3. **Agreement promotion** — when **2+ independent lanes** flag the same fingerprint, raise the
   merged finding's confidence **one step** (50→75, 75→100). Independent corroboration is real
   evidence; a cross-tenant authz bug seen by both security and correctness is surer than either
   alone. Do **not** promote two findings from the *same* lane (that's not independence).

---

## The independent validator wave (Phase 3) — replaces self-recheck

**Why not self-recheck:** the orchestrator synthesized these findings, so re-reading them catches
a wrong *fact* but not its own *bias* — it already decided they're real. Independence is the point.

**Protocol:**
- For **every surviving P0 and P1**, spawn **one fresh validator `Agent` per finding** (a single
  batched validator pattern-matches across findings and recreates the bias). The validator gets
  the finding + the file path, **no commitment** to the verdict: *"False positives are common; do
  not feel pressure to confirm. Read the path cold and report what you find."*
- The validator returns **confirm / downgrade / reject**, each with its **own** `file:line`
  evidence — not a restatement of the original.
- **Confirm** → keep (optionally bump confidence). **Downgrade** → lower severity/confidence per
  the validator's evidence. **Reject** → drop, but record it in an internal "considered and
  rejected" note so the same false positive isn't re-raised next run.

**Degraded-keep on validator failure** (crash/timeout, *not* a reject):
- **P0/P1 are KEPT and marked "degraded — unvalidated."** A transient infrastructure failure must
  never silently remove a critical finding.
- P2/P3 drop (conservative) if their validator failed.

---

## Model-tiering (set in Phase 0)

| Lane | Model | Why |
|------|-------|-----|
| Security | session model | highest miss-cost; needs the strongest reasoning |
| Correctness | session model | subtle logic bugs reward depth |
| Performance | mid-tier | mechanical checks; ~3–4× cheaper |
| Refactoring | mid-tier | taxonomy-driven; tooling does the proving |
| Validators (P0/P1) | session model | the final gate on the highest-stakes findings |

Tiering cuts audit cost on an Opus session without weakening the lanes where a miss is expensive.

---

## Settled-precedents table (suppress these as not-findings)

Each row is a question reviewers re-litigate every run; the precedent settles it. **If a finding
relies on the left column, it is not a finding** (unless the right column's condition is violated).

| Pattern | Precedent |
|---|---|
| UUID / opaque token in a URL | Assumed unguessable; not "IDOR via guessable ID" on its own. |
| Environment variable value | Trusted config, not untrusted input. |
| React/Vue/Angular rendered text | Auto-escaped → XSS-safe **unless** `dangerouslySetInnerHTML` / `v-html` / `bypassSecurityTrustHtml`. |
| Client-side validation/auth "missing" | The **backend** is the authority; client checks are UX, not a security finding. |
| Outdated dependency with a CVE | Note only — not a P0 unless a **reachable call path** uses the vulnerable API. |
| `Promise.all` "missing" | Not a finding if the operations are actually **dependent**. |
| Theoretical race / DoS / resource exhaustion | Excluded unless a concrete, reachable trigger is shown. |
| Open redirect / log spoofing / prototype pollution | Excluded unless a concrete exploit path is traced. |
| Defense-in-depth ("add a second layer") | Not a finding when the first layer already holds. |
| Dead code "by grep" | Not proven dead until real tooling clears barrel files / dynamic imports / framework exports. |
| Cold-path micro-optimization | Startup / migration / admin-tool perf doesn't matter — suppress. |
| Lint-ownable style nit | Suppress — findings must not duplicate the linter. |

This table is the same idea as the per-lane do-NOT-flag lists in
[reviewer-lanes.md](reviewer-lanes.md), pulled together as a quick reference the synthesizer
applies at the gate.
