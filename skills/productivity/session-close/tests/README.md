# session-close — Eval harness

**Level:** Compound (writes to memory files via section-aware LLM merge).
Behavioral testing requires a recorded session transcript + expected memory
diff — moderate fixture cost, deferred. This harness asserts the design
contract: 9 phases, three-gate filter, REPLACE/MERGE-LIST/PRESERVE strategies,
portability rules, event classification, and the V3 After Action Review.

## What's asserted

- All 9 phases present in SKILL.md (IDENTIFY → READ → EXTRACT → **AAR** → RECONCILE → PRESENT → INDEX → CLAUDE.md AUDIT → CLEANUP)
- No stale `Phase 7` cross-references left over from the V2.1 numbering
- Three-gate filter (Durability, Specificity, Retrieval) named
- All three merge strategies named (REPLACE, MERGE-LIST, PRESERVE)
- Core principle "state reconciliation" present + anti-pattern ("session logging" / "session dump") called out
- Never-write-without-approval invariant present
- **Portability:** no `/Users/<name>/` or `/home/<name>/` hardcoded paths
- **Cross-platform:** uses portable `--since=` git flag, not macOS-only `date -v`
- Dynamic memory path pattern (`~/.claude/projects/...`) documented
- Event classification (DECISION, STATUS_CHANGE, DISCOVERY, **DEAD_END**) present
- Fixture memory file exists with Status + Backlog sections

### V3 — After Action Review

The AAR assertions exist because each one guards a documented failure mode, not
because the phase has parts:

- **Four questions present** — the delta between intent and actual is the phase's
  entire reason to exist. Lose a question and it degenerates into a summary.
- **Blameless framing** (`mechanism`, `never the actor`) — blame in either
  direction ends the analysis before it produces an actionable change.
- **Bounded output** — cap on Improve items, "zero is valid," and the
  AAR-theater anti-pattern. Without these the AAR becomes the session dump the
  whole skill exists to prevent.
- **Four-check promotion gate** + merge-not-append — an ungated path to
  `CLAUDE.md` measurably degrades agent success (see the changelog's sources).
  All four checks must be named.
- **Closure loop** — `PROCESS:`/`DEAD-END:` tags, Phase 2 carry-forward, and the
  three outcomes (Recurred / Resolved / Zombie). Without cross-session state the
  AAR re-raises the same item forever. Plus a guard that gate-failed items are
  retained, never silently dropped.
- **Per-project scope** — a real defect caught by the V3 held-out benchmark: a
  multi-repo session would otherwise blur two unrelated deltas into one.
- **Progressive disclosure** — playbook exists, is linked, SKILL.md ≤ 500 lines.

## Run

```bash
bash tests/eval.sh
```

Exit 0 = contract intact. Exit 1 = regression.

## What this does NOT test

- Whether the skill actually classifies events correctly at runtime
- Whether REPLACE truly replaces vs accidentally appends
- Whether MERGE-LIST deduplicates correctly
- Whether Phase 6 diff preview always fires before writes
- Whether the AAR picks the *right* Q3 mechanism, or correctly refuses to
  promote a taste call — the V3 benchmark measured this by hand (10 transcripts,
  5 held out; see the changelog), but it isn't automated here

Those need a recorded session + expected diff pair. When you run a real
`/session-close` that produces an output worth freezing as baseline, copy it
into `tests/fixtures/golden/` and add a diff assertion.

## Extending

- Every time a real session-close invocation produces a wrong merge, add an
  assertion that would have caught it.
- New memory section names (e.g., "Open Questions") → add to the merge-strategy
  matching tests.
- Platform-specific bugs → add portability assertions.
