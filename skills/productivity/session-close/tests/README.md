# session-close — Eval harness

**Level:** Compound (writes to memory files via section-aware LLM merge).
Behavioral testing requires a recorded session transcript + expected memory
diff — moderate fixture cost, deferred. This harness asserts the design
contract: 7 phases, three-gate filter, REPLACE/MERGE-LIST/PRESERVE strategies,
portability rules, and event classification all intact in SKILL.md.

## What's asserted

- All 7 phases present in SKILL.md (IDENTIFY → READ → EXTRACT → RECONCILE → PRESENT → INDEX → CLEANUP)
- Three-gate filter (Durability, Specificity, Retrieval) named
- All three merge strategies named (REPLACE, MERGE-LIST, PRESERVE)
- Core principle "state reconciliation" present + anti-pattern ("session logging" / "session dump") called out
- Never-write-without-approval invariant present
- **Portability:** no `/Users/<name>/` or `/home/<name>/` hardcoded paths
- **Cross-platform:** uses portable `--since=` git flag, not macOS-only `date -v`
- Dynamic memory path pattern (`~/.claude/projects/...`) documented
- Event classification (DECISION, STATUS_CHANGE, DISCOVERY) present
- Fixture memory file exists with Status + Backlog sections
- README and LICENSE shipped

## Run

```bash
bash tests/eval.sh
```

Exit 0 = contract intact. Exit 1 = regression.

## What this does NOT test

- Whether the skill actually classifies events correctly at runtime
- Whether REPLACE truly replaces vs accidentally appends
- Whether MERGE-LIST deduplicates correctly
- Whether Phase 5 diff preview always fires before writes

Those need a recorded session + expected diff pair. When you run a real
`/session-close` that produces an output worth freezing as baseline, copy it
into `tests/fixtures/golden/` and add a diff assertion.

## Extending

- Every time a real session-close invocation produces a wrong merge, add an
  assertion that would have caught it.
- New memory section names (e.g., "Open Questions") → add to the merge-strategy
  matching tests.
- Platform-specific bugs → add portability assertions.
