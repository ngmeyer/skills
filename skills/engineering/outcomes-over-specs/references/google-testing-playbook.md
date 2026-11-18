# Google testing engineering — the playbook behind `outcomes-over-specs`

Distilled from *Software Engineering at Google* (Winters, Manshreck, Wright, eds.), the Google Testing Blog, and Google's CI research. This is the "right engineering process" the skill embodies. Use it to set test altitude, judge a gate's trustworthiness, and keep an agentic loop honest.

## 1. Size vs scope — two orthogonal axes

The book separates **size** (resources a test may use) from **scope** (how much code it validates). They are independent.

- **Small** — one process, one thread, one machine; no real I/O, no sleeps, no network. Fast and deterministic. *"Small tests are restricted to one thread, one process, one machine."*
- **Medium** — multiple interacting units in a faked or local environment (e.g. a local DB). Slower, less deterministic.
- **Large** — the real production environment, real (not faked) resources. Slow, flakiest.

**Scope** = unit / integration / end-to-end (how much code). A small test is *usually* unit-scoped, but the axes don't have to line up. **Default to small-size tests** — they are the fast, reliable bulk of a gate.

## 2. The pyramid — shape, not law

- **Book target: ~80/15/5** — *"80% of our tests being narrow-scoped unit tests ... 15% medium-scoped integration tests ... 5% end-to-end tests."*
- **Wacker's blog: ~70/20/10** (*Just Say No to More End-to-End Tests*, 2015). Both are real Google sources; treat the exact ratio as an order-of-magnitude target — *"the exact mix will be different for each team, but in general, it should retain that pyramid shape."*
- **Anti-pattern — the "ice-cream cone":** many slow, flaky e2e tests over few unit tests. *"Such suites tend to be slow, unreliable, and difficult to work with."* Large tests *"should not be viewed as a primary method for catching bugs"* — they are sanity checks. Evaluate a strategy not by how it *finds* bugs but by how it lets developers *fix and prevent* them.

## 3. Hermetic tests — the determinism requirement

*"Hermetic tests are tests run against a test environment ... entirely self-contained (no external dependencies like production backends)."* Two properties: **determinism** (same code in → same result, every run) and **isolation**. All tests *"should strive to be hermetic"* — even filesystem access should use an in-memory fake. Known nondeterminism sources to kill: **system time, random number generation, race conditions, test ordering, shared mutable state.**

## 4. Flakiness — endemic, and the discipline that contains it

Google's own numbers (Micco CI research): about **1.5% of all test runs** report flaky, **~16% of tests** have *some* flakiness, and **~84% of pass→fail transitions involve a flaky test.** Flakiness is the tax on large/non-hermetic tests.

**Discipline: quarantine, don't retry.** Google *"monitors the flakiness of tests and if the flakiness is too high, it automatically quarantines the test"* — removing it from the critical gate and filing a bug. For an agentic loop this is the single most important rule: **retry-until-green rewards non-determinism; quarantine-and-fix removes it.** Track quarantine count as a trust signal.

## 5. Ownership — the Beyoncé Rule

*"If you liked it, then you shoulda put a test on it."* Operationally: *"If a product experiences outages ... but the issue wasn't surfaced by tests in our CI system, it is not the fault of the infrastructure change."* The burden is on whoever wants a behavior protected to encode it as a CI test. Testing is owned by the engineers who write the code, enforced at code review — *"every change is expected to include both the feature code and tests"* — not by a separate QA org. For an agent: the agent that builds the behavior also writes the test that protects it.

## 6. Test Certified — the maturity ladder (rungs for an autonomous loop)

Google's historical 5-level program that built the testing culture, useful as **verifiable rungs** for ramping an autonomous loop instead of unleashing it on a whole repo:

- **L1** — set up coverage instrumentation; track it.
- **L2** — policy: no commits without tests; smoke-test the build.
- **L3** — test all non-trivial new code; classify tests by size.
- **L4** — sustained: total coverage gating, no untested releases.
- **L5** — high coverage as a steady state; testing is reflexive.

Give the loop a current rung and a verifiable promotion criterion rather than "test everything."

## 7. Coverage ≠ behavior — use mutation testing

Line/branch coverage measures *what ran*, not *what was checked*. A suite with 100% coverage and `assert response is not None` catches almost nothing. **Mutation testing** is the behavior signal: programmatically perturb the code (flip a conditional, change a constant, weaken a return) and confirm a test fails. A *surviving mutant* is a hole in the gate. The loop's hardening phase should chase mutation-resistance, not a coverage %.

## 8. Agentic-loop guardrails (where naive agent testing goes wrong)

Mapping the above onto an AI agent that writes + runs tests:

1. **Write the test red-first** — agents tend to write code then a test that already passes; that test asserts the implementation, not the outcome. Red-first proves the test bites.
2. **Quarantine, don't retry** — agents love to re-run a flaky test until it's green. Forbid it.
3. **Mutation over coverage** — agents hit coverage targets with weak assertions; require a regression-catch check.
4. **Altitude discipline** — agents over-produce slow e2e tests (easiest to write); push assertions down the pyramid.
5. **Maturity rungs** — don't unleash on the whole repo; ramp via verifiable Test-Certified-style criteria.
6. **A trust/flake budget** — track the gate's flake rate and quarantine count so the loop knows when its own suite has stopped being trustworthy.

## Sources

- *Software Engineering at Google* — ch. 11 (Testing Overview), ch. 12 (Unit Testing), ch. 14 (Larger Testing), ch. 23 (CI). Free at abseil.io/resources/swe-book.
- Simon Stewart, *Test Sizes* (Google Testing Blog, 2010-12). (Note: the size taxonomy is Stewart's; Mike **Wacker** wrote *Just Say No to More End-to-End Tests*, 2015 — source of 70/20/10.)
- John Micco, *Flaky Tests at Google and How We Mitigate Them* (Google Testing Blog / research.google).
- Mike Bland, on the Testing Grouplet and Test Certified.
- Mutation testing: general practice (e.g. mutmut/PIT/Stryker), used here as the behavior-vs-coverage check.
