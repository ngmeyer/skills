# Behavior preservation — the API-contract check and the boundary-walk verifier

The skill's whole premise is **no observable change to any outward-facing page or API for
legitimate callers.** Two mechanisms enforce it: a **contract check** during review (catch the
"safe" fix that quietly changes a response), and a **boundary-walk verifier** after each applied
fix (prove the real flow still behaves). Both are on-mission; neither existed in V1.

---

## A. The API-contract check (Phase 1, every lane that touches an endpoint or shared transform)

A refactor or perf fix that changes *what a caller receives* breaks the guarantee even if every
test still passes. Classify every change to a route, response builder, serializer, or shared
transform as **additive** or **subtractive/mutative**:

- **Additive (safe)** — a new optional field, a new endpoint, a new accepted input that defaults
  to old behavior. No existing caller observes a difference.
- **Subtractive / mutative (gated or reject)** — removing/renaming a field, changing a type
  (`number` → `string`), changing a default, changing sort order, changing pagination size,
  changing an error shape. An existing caller **will** observe this.

### Silent-semantics-change — the dangerous middle
The response *shape* is identical but the *meaning* shifted. These pass schema checks and most
tests, and are exactly what a fast "safe cleanup" introduces:
- `count` used to include soft-deleted rows; the refactor filters them → the number changes.
- A list used to be ordered by `created_at`; the rewrite relies on the DB's default order.
- A monetary field silently switches cents ↔ dollars during a "tidy."
- A timestamp's timezone normalization moves during a date-handling refactor.
- An empty result used to mean `[]`; now it means `null` (or vice-versa).
- A boolean's default flips because the new code reads a different column.

**Rule:** any change where an existing caller could receive a *different value for the same input*
is **gated**, never a quiet `safe` cleanup. When in doubt, diff the actual response for a fixed
input before and after — don't reason about it abstractly.

Map contract findings to the report's refactoring/correctness tables and flag them `gated` with a
one-line "what a caller sees change" note.

---

## B. The boundary-walk verifier (Phase 5, after each applied `safe` fix)

"Tests pass" is necessary, not sufficient — tests may not cover the exact flow the fix touched.
After applying a `safe` fix, **prove the flow** before moving to the next fix.

### Procedure
1. **Infer the user story** the changed code serves — "a logged-in member loads their dashboard
   and sees their own teams." One sentence; it defines what *observable* means here.
2. **Walk the boundaries** the request crosses, gathering evidence at each:
   `request → route/middleware → handler → data layer → response → (rendered output)`.
   At each boundary, confirm the observable result for a **legitimate** caller is unchanged:
   same status, same response shape **and values**, same redirect, same rendered content.
3. **Stop at the first broken boundary.** Don't keep walking past a regression to "see if it
   recovers" — the first observable divergence is the finding. Re-classify the fix as `gated`,
   revert it, and report.
4. **Two-consecutive-silent-layers rule:** if two boundaries in a row yield no useful signal
   (you can't observe what crosses them), flag the **observability gap** — you can't claim the
   flow is preserved through a section you can't see.

### What counts as evidence
- An actual run (the project's dev server / test harness) hitting the path, or
- A test that exercises the specific boundary, or
- A traced read of the code path with the concrete before/after values named.

A "safe" fix that can't produce boundary evidence for its own flow is **not safe** — downgrade it
to `gated` and leave it in the report for human review rather than applying it.

### Authorization fixes are the intended exception
Tightening auth **will** change the observable result *for an unauthorized caller* (they now get a
403). That is the **intent**, not a regression — the verifier walks the **legitimate** caller's
story, which must be unchanged. Confirm a legitimate caller still passes; confirm the previously
over-permissioned caller is now correctly rejected.
