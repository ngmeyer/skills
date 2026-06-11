# Reviewer lanes — full checklists + per-lane do-NOT-flag lists

Four read-only reviewers run in parallel (Phase 1). Each verifies every finding against the
full code path, scores it on **both axes** (severity P0–P3 × confidence 0/25/50/75/100),
classifies `safe`/`gated`, and **applies its do-NOT-flag list before emitting**. Lead each
finding's evidence with the **observable consequence**, not the code structure.

Model tiers: **security** and **correctness** inherit the session model; **performance** and
**refactoring** may run a mid-tier model.

---

## 1. Security *(session model · lower bar — file confidence-50 at P0)*

**Method: attacker mindset, not a checklist.** Read the code and ask "how would I break this?",
then trace whether the code stops you. The unit of evidence is a **taint trace from entry point
→ dangerous sink**.

Cover:
- **Authorization on every mutation and admin read.** Two questions, both required: (a) is there
  a session check? (b) is the session's tenant/ownership checked against the *target* resource,
  not just "any logged-in user"? **Cross-tenant authz gaps are top priority** (OWASP A01).
  Every capability needs a named actor — "the system allows editing settings" → *who?*
- **Server actions / RPC are real endpoints.** Their IDs ship in the client bundle — obscurity
  is not a guard. Audit them like routes.
- **Secrets scan (mandatory, do not skip).** Grep **git-tracked** files for connection strings,
  API keys, tokens: `postgres://`, `mysql://`, `npg_`, `sk-`, `AKIA`, `ghp_`, `-----BEGIN`,
  `Bearer `, `client_secret`. A committed credential is **P0** and needs **rotation**, not just
  deletion — it's in history. Cross-check `git ls-files` to confirm tracked vs. local-only.
- **Injection via taint trace** — raw/interpolated SQL, NoSQL operators from user input, command
  injection. Confirm the sink is reached by untrusted input *without* parameterization/escaping.
- **SSRF** — user-controlled URL reaching a server-side HTTP client (`fetch`/`axios`/`requests`)
  with no allowlist. (Now folded into **OWASP A01:2025**.)
- **Insecure deserialization** — `pickle`/`Marshal`/`unserialize`/`yaml.load`/`JSON.parse` of
  attacker-controlled content that can execute or instantiate → RCE.
- **CSRF** on state-changing operations that rely on ambient cookies without a token/SameSite.
- **Dangerous-sink watchlist** — `dangerouslySetInnerHTML`, `v-html`, `child_process.exec`/`execSync`
  with string interpolation, `eval`/`new Function`, `vm`, dynamic `require`/`import()` of a
  user-controlled path.
- **Untrusted parsing** — uploads, zip/archive (zip-slip, path traversal, decompression bombs,
  size caps), missing rate limits / brute-forceable codes, invite/token binding + expiry,
  cookie attributes (`HttpOnly`/`Secure`/`SameSite`), fail-**closed** secret handling.
- **Comparative analysis** — learn the project's *existing* sanitization/validation pattern first,
  then flag the endpoint that **deviates** from the house norm. The inconsistent handler is the
  bug more often than the absent one.

**Tag every finding with OWASP Top 10:2025 + a CWE id.** New/changed 2025 categories worth
knowing: **A01 Broken Access Control (now absorbs SSRF)**, **A03 Software Supply Chain Failures**,
**A10 Mishandling of Exceptional Conditions (failing open / improper error handling)**.

**Per-finding output adds an `Exploit Scenario` line** — the concrete attack path, one sentence.

### Security — do NOT flag
- Defense-in-depth on already-protected code (a second escape layer on already-parameterized SQL).
- Theoretical / physical-access / "attacker already has root" scenarios.
- HTTP-in-dev-config, localhost-only bindings.
- Generic "consider adding rate limiting / CSP / a WAF" with **no specific exploitable finding**.
- Client-side JS "missing an auth check" — the **backend** is responsible; client checks are UX.
- Env vars treated as untrusted input — they're trusted config.
- React/Angular/Vue auto-escaped output assumed XSS-vulnerable — it's safe **unless**
  `dangerouslySetInnerHTML` / `bypassSecurityTrustHtml` / `v-html`.
- UUIDs/opaque tokens assumed guessable.
- Outdated-dependency CVEs with no reachable call path in this code (supply-chain note ≠ exploit).

---

## 2. Performance *(mid-tier · higher bar — suppress speculative)*

Cover:
- **Query count per render** — N+1 and sequential `await`s that could be `Promise.all` or one join,
  *especially* on serverless HTTP DB drivers where each query is a round trip. **Confirm the loop
  is real first**: count iterations against expected data size — a loop over 3 config items is not
  an N+1.
- **Missing/mismatched indexes** — compare declared indexes against actual WHERE/ORDER BY/JOIN on
  the largest tables. **Index changes are `gated`** (lock duration, write cost).
- **Over-fetching** — `select *` on wide tables, fetch-all-then-filter-in-JS, full-history pulls
  where a SQL aggregate would do.
- **Request-level memoization gaps** — same lookup re-queried within one render tree (`React.cache()`
  / per-request dedup).
- **Core Web Vitals (the web in "web codebase"):**
  - **LCP** — hero image has `priority`/`fetchpriority="high"` and is *not* lazy-loaded; `next/image`
    over `<img>`; preconnect to critical origins.
  - **CLS** — every image/embed has explicit `width`/`height`; `next/font` (self-hosted, zero-CLS)
    over external font loaders; reserved space for dynamic content.
  - **INP** — long-task yielding (`scheduler.yield()`), `{ passive: true }` on scroll/touch
    listeners, `content-visibility: auto` / virtualization for long lists, derive state during
    render rather than in effects.
- **Bundle** — barrel-file imports that pull a whole module, heavy libs (PDF/spreadsheet/parsers)
  that should be dynamic `import()`, third-party scripts that should `async`/`defer` and load after
  hydration, server-weight deps leaking into client components.
- **RSC boundary** — minimize data serialized across server→client; no non-serializable props.
- **Serverless traps** — in-process caches (`LRUCache`/`NodeCache`) are **broken** (process memory
  not shared across invocations) → flag, recommend a shared/region cache; local FS writes are
  **ephemeral** (correctness bug); `setTimeout`/`setInterval`/polling in a handler hits limits.
- **Algorithmic hotspots** in import/transform/loops; **project impact at 10×/100×/1000×** current
  data volume — a finding that only bites at scale is still a finding, but labelled as such.

### Performance — do NOT flag
- Micro-optimizations in **cold paths** — startup, migration scripts, admin tools that run rarely.
- Speculative "this could be faster" with no measured or reasoned hot path.
- Premature `Promise.all` on operations that are actually dependent.
- Re-implementing what the framework/runtime already optimizes (e.g. fighting the bundler).

---

## 3. Correctness *(session model · standard bar)*

The lane V1 lacked entirely. Mentally execute the code with boundary values.

Cover:
- **Off-by-one / boundary** — slice bounds, inclusive vs. exclusive ranges, pagination that drops
  the final page "when the total is an exact multiple of page size."
- **Null/undefined propagation** — values that reach a template as the literal string
  `"undefined"`/`"null"`, or arithmetic that yields `NaN` and silently corrupts a total.
- **Error-masking fallbacks** — `catch` that returns `[]`/`{}`/`0` instead of propagating, so the
  caller reads "no results" when the truth is "the query failed." Directly a hardening issue
  (silent data-integrity loss).
- **TOCTOU** — check-then-act with a gap (existence check before write; balance check before debit);
  state transitions that can leave a record half-updated.
- **Race conditions** — concurrent sessions, uniqueness constraints enforced only in app code,
  read-modify-write without a transaction or lock.
- **Type-boundary corruption** — implicit coercions at API/DB boundaries (string `"0"` truthy,
  date parsing by locale, number precision).

### Correctness — do NOT flag
- Defensive null checks that are unreachable given upstream invariants (trace the caller first).
- "Could throw" on inputs the type system already excludes.
- Re-stating what the code obviously does without a concrete failing input.

---

## 4. Refactoring *(mid-tier · standard bar)*

Cover:
- **Dead code — proven with real tooling, not bare grep.** Use `knip` / `ts-prune` /
  `tsc --noUnusedLocals` / `ruff F401` / `ast-grep`, and account for **barrel files, dynamic
  `import()`, and framework route/page exports** (a Next.js page export looks unreferenced but
  is the entry point). Deletion recommendations are **`gated`**.
- **Drift-prone duplication** — the same transform/rule reimplemented in N places. **Check whether
  the copies already disagree — that's a P1, not a style nit.** Compare `scripts/` against
  `src/lib/` for parallel implementations. Tool-assist with `jscpd --min-tokens 50`.
- **Fowler's 5-family smell taxonomy** (use as the systematic checklist):
  - *Bloaters* — long method/class, primitive obsession, data clumps, long parameter list.
  - *Change preventers* — divergent change, **shotgun surgery**, parallel hierarchies.
  - *Dispensables* — dead code, duplication, **speculative generality**.
  - *Couplers* — feature envy, inappropriate intimacy, message chains, middle man.
  - *OO abusers* — refused bequest, switch-on-type where polymorphism fits.
- **Complexity moved, not removed** (highest-priority refactor smell) — a "refactor" that spreads
  the same logic across more files without reducing the concepts a reader must hold. File crossing
  **1000 lines** = P1.
- **The Deletion Test** (Pocock) — imagine deleting the module. If complexity vanishes, it was a
  pass-through; if complexity reappears across N callers, it was earning its keep.
- **The two-adapter seam rule** (Pocock) — one adapter = a hypothetical seam; **two adapters = a
  real seam.** Don't recommend an interface/abstraction for a single implementor (it adds a layer
  and risks behavior change — anti-mission here).
- **TS type-safety** — new `any`/`@ts-ignore`/unchecked `as`; enable/respect
  `noUncheckedIndexedAccess` (unchecked array/object index = latent bug); prefer **Result types**
  over throwing for *expected* failures; explicit return types on module-level functions;
  **discriminated unions** to model state instead of optional-field bags / boolean flags.
- **TODO/FIXME/HACK/XXX** debt sweep; architectural-layer violations (cross-layer deps bypassing an
  abstraction); convention drift across routes (error shapes, auth boilerplate, naming at boundaries).

Every refactor `suggested_fix` needs a **concrete reframe** — what to delete, split, or move — not
"consider refactoring."

### Refactoring — do NOT flag
- An abstraction that exists for testability (check `git blame`/intent before recommending removal).
- Single-use "speculative" code that the roadmap clearly needs next (check comments/commits).
- Style/lint nits a linter already owns — findings must not duplicate linter output.
- "Extract this" where the extraction adds a layer for one caller (fails the two-adapter rule).
- Over-simplification: every simplification has an opposite failure mode — confirm you're not
  removing a guard that exists for a reason.
