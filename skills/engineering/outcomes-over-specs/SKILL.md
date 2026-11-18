---
name: outcomes-over-specs
description: >
  Outcome-first, test-driven development for agentic coding with MANDATORY
  independence: you approve the outcome, an independent agent writes the test gate
  from that outcome (never the implementer), and a separate agent drives the code to
  green without being allowed to touch the tests. Gate on behavior (mutation-resistant),
  not on a spec or a PRD. Two modes — new behavior (acceptance tests) and changing
  existing code (characterize current behavior FIRST, so every regression surfaces as a
  labeled test instead of going unnoticed). Embodies Google's testing engineering
  (pyramid, size vs scope, hermetic, quarantine-not-retry). Use when: 'TDD this',
  'build/change this test-first', 'outcomes over specs', 'the code is fast but off the
  tracks', 'don't let the agent grade its own work', 'change this without regressions'.
  NOT a code-review pass and NOT spec authoring — it drives the build with an
  independently-written test gate as the source of truth.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "Task"]
argument-hint: "<feature, bug, or change to build/fix> [--strict] [--mutation]"
---

# /outcomes-over-specs — TDD over the PRD, with independence

Drive a change to a verifiable outcome where the **test gate is written by a different agent than the one writing the code.** That separation is the whole point — it is what makes the tests worth trusting.

## Why this works

Agentic coding is fast but drifts off-outcome because the agent optimizes for *"looks done / spec satisfied,"* not *"behaves correctly."* The deepest version: when **one agent distills the outcome, writes the tests, and writes the code**, it can be internally consistent and still wrong — it writes a test that encodes the behavior it *intends* to produce, then drives that to green. *"Tests pass"* collapses to *"the agent agrees with itself"* — the same hole as a review persona's *"looks good to me."* Correctness was never anchored outside the implementer.

The fix is **independence**, applied twice:
- **You** approve the outcome (the acceptance criteria, or the list of behaviors a change may alter) before any code exists — the human-anchored definition of correct.
- **A separate agent writes the gate** from that approved outcome; **the implementer never authors or edits it.** The implementer's only job is to make an independently-written gate pass.

This is TDD/ATDD scaled to agents, aligned with where software engineering moved — at Google *"every change is expected to include both the feature code and tests,"* reviewers block changes without them, and the pyramid keeps the gate fast. Full distillation: [references/google-testing-playbook.md](references/google-testing-playbook.md).

## The non-negotiable invariant

**The agent that writes the code never writes or edits the test gate.** If the implementer can weaken a test to pass, independence is gone and you are back to self-agreement. The orchestrator enforces this: after the implementer runs, the test files are diffed and **any change is surfaced for your review, never auto-accepted.**

## Two modes (detected in Phase 0)

| | New behavior (greenfield) | Change existing code (brownfield) |
|---|---|---|
| **Oracle** | your approved acceptance criteria | the observed *current* behavior |
| **Gate** | acceptance tests, red-first | characterization tests, pinned *before* the change |
| **Independent of** | the implementation (tests predate it) | the change (behavior pinned before touching) |

## The loop

### Phase 0 — Frame & approve the outcome (you)
Detect the mode (does the target code already exist?). Distill the request — and any PRD, which is *context, not the gate* — into observable criteria ("given X, when Y, then Z"; numbers and states, not adjectives). **Stop and get your approval** before any test or code. This is the one moment where wrong is cheap to fix.

### Phase 1 — Independent test-author (a separate agent)
Spawn a **test-author subagent** that writes the gate from the *approved outcome only* — it does **not** write product code.
- **Mode A (new):** acceptance tests at the right altitude (pyramid: unit-heavy, hermetic, size ≠ scope). Run them and confirm **red** — a test green before the code tests nothing.
- **Mode B (change):** first **recover what *why* you can** (git blame/log, existing tests, comments, ADRs) and **flag the fences you can't explain** (Chesterton's Fence — you can't tell which behaviors are load-bearing if you don't know why they're there). Then **characterize the current behavior** with a wide net — especially the surprising paths — and run it **green against today's code.** The change has not happened yet; the existing code is the oracle.

### Phase 2 — Independent implementer (a different agent)
Spawn an **implementer subagent** that receives the gate as **fixed and read-only** and drives the code to green against *real test runs*.
- It may **not** modify the test files. "I believe this is correct" is not a passing test.
- **Mode B:** after the change, surface **every characterization test that flipped** → you label each: *intended change* (update the test on purpose) or *regression* (fix the code). Nothing flips silently — every regression is **realized**, not unnoticed.

### Phase 3 — Verify independence + behavior
- **Independence check** — diff the test files: confirm the implementer didn't touch the gate. Any edit is a violation → surface it, don't accept it.
- **Behavior check** — mutation/regression probe: plant a fault (flip a conditional, change a constant, weaken a return) and confirm a test fails. Surviving mutants are holes in the gate. `--mutation` runs a full mutation-framework pass.
- **Flake discipline** — quarantine flaky tests; **never retry-until-green** (that rewards non-determinism instead of fixing it).

### Phase 4 — Gate + record
Done = gate **green** + **implementer never touched the gate** + **mutation-resistant** + (Mode B) **every flip labeled.** Record the outcome→test traceability (a line per criterion → the test that proves it) so the proof can't be silently deleted. `--strict` refuses to report success if any criterion lacks a passing, mutation-checked test.

**Going heavy:** for a large surface, escalate to a `/workflow` that runs author → implement → verify per behavior in parallel — same independence invariant, one outcome per lane.

## Test altitude (Google pyramid) — quick rules
- **Size ≠ scope.** Prefer **small-size** tests (one process, no real I/O, hermetic, fast) — the reliable bulk of the gate.
- **Shape ~80/15/5** unit/integration/e2e (order-of-magnitude, not law). Anti-pattern: the **ice-cream cone** (many slow, flaky e2e tests). e2e are sanity checks, not the primary bug-catcher.
- Full detail + sources + Test-Certified rungs: [references/google-testing-playbook.md](references/google-testing-playbook.md).

## When NOT to use this
Spikes and exploratory prototypes, throwaway code, pure styling/copy tweaks with no behavioral contract. Outcome-first pays off when behavior matters and regressions are expensive; it is overhead while you're still *discovering* what to build. Spike first, then outcome-first the keeper.

## Composing with Compound Engineering (optional, not required)
Self-contained — runs with `Task` + `Write`/`Edit`/`Bash`. If you run the CE plugin, the **implementer** subagent can be `ce-work`, and `ce-testing-reviewer` / `ce-code-review` can review *after* green (review complements the gate; it never replaces it). Never a hard dependency.

## Gotchas
- **The implementer never writes or edits the gate.** The core invariant. Collapse the roles and you've rebuilt the self-agreement loop the skill exists to break.
- **The spec is not the gate.** A PRD/"looks done" is satisfiable superficially; only an independently-written, behavior-checking test means done.
- **Tests go red first / characterize before you touch.** A test green before the code (or before the change) proves nothing.
- **Brownfield: every flipped characterization test gets *labeled*** — intended-change or regression — never silently updated to make the suite green.
- **Never retry-until-green on a flake.** Quarantine and fix the non-determinism.
- **Coverage is not behavior.** Mutation-resistance is the signal, not line %.
- **No ice-cream cone.** Push assertions down to fast hermetic unit tests.

## Changelog

### V1.1 (2026-05-31) — independence made mandatory + two modes
- **Independence is no longer optional** (v1 had it behind a flag). The test-author and the implementer are **always separate agents**, and the implementer **may never edit the gate** — that separation is what makes the tests trustworthy. The orchestrator diffs the test files to enforce it.
- **Two modes** — greenfield (acceptance tests, red-first) and **brownfield (characterize current behavior first)**. Added after the insight that the *why* of existing code is usually missing, so small tweaks cause *unrealized* regressions; pinning behavior before touching makes every regression a **labeled, realized** test.
- Added a "when NOT to use this" section (no TDD dogma on spikes/throwaway/styling).

### V1 (2026-05-31)
Forged from the AI-native gap analysis: agentic coding produces plausible-but-off outcomes; review/spec-driven approaches don't gate on behavior. Embodies *Software Engineering at Google* testing practice as an outcome-first build loop. **Not yet outcome-verified** — pending validation on a real task (a production E2E suite) per skillforge's iterate-then-extract; the changelog will record V1.1→V2 once measured.

## References
- [references/google-testing-playbook.md](references/google-testing-playbook.md) — Google's testing engineering distilled (pyramid, size/scope, hermetic, flakiness + quarantine, Beyoncé Rule, Test Certified, mutation testing), with sources.

## Testing
Prompt-only skill; `tests/eval.sh` asserts the design contract (mandatory independence / implementer-never-edits-gate, both modes, characterize-first, human approval gate, mutation-not-coverage, quarantine-not-retry, self-containment). Behavioral validation is the iterate-then-extract pilot: run it on a real task, confirm the independent gate catches what a self-graded loop would have shipped, and fold the winning shape into V2.
