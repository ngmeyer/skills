# claude-md — Eval harness

**Level:** Prompt-only (writes via surgical Edit only after user approval; audit reports without writing). Behavioral testing requires fixture CLAUDE.md files + LLM-as-judge against expected diff outputs and audit reports — moderate fixture cost, deferred. This harness asserts the design contract for BOTH modes: improve (5 phases, 10-rule rubric, 5 canonical sections, anti-auto-apply) and audit (7 phases, secret-scan-first, drift categories, leak-rotation-by-user invariant).

## What's asserted

- Mode Dispatch section present; both `improve` and `audit` invocations documented
- All 5 improve phases (SCOPE → MEASURE → PROPOSE → PRESENT → APPLY)
- All 10 rubric rules (R1 through R10)
- All 5 canonical sections referenced (Project, Stack, Commands, Architecture, Rules, Workflow, Out of scope)
- All 7 audit phases (DISCOVER → SECRET SCAN → DRIFT → DUPLICATES → BUDGET → REPORT → OFFER FIXES)
- 5 secret patterns named (AUTH_SECRET, sk_live_, sk-ant-, postgres, JWT)
- 6 drift categories (MCP servers, API routes, Cron jobs, Env vars, External services, Directory structure)
- Anthropic primary sources cited (code.claude.com memory + best-practices)
- Removability test cited (the universal pruning rule)
- Strunk lineage acknowledged (the upstream principle behind removability)
- Anti-auto-apply invariant present (both modes)
- Leak-rotation-by-user invariant present (audit mode)
- Anti-pattern list includes Personality instructions, auto-memory overlap, Duplicate rules
- Quality Bar section present, with hedge phrases (`consider`, `perhaps`, `you might want to`) explicitly banned
- Sibling skills referenced (`/init`, `ce-compound-refresh`)
- **Portability:** no `/Users/<name>/` or `/home/<name>/` hardcoded paths
- README, LICENSE, CLAUDE.md all shipped

## Run

```bash
bash tests/eval.sh
```

Exit 0 = contract intact. Exit 1 = regression.

## What this does NOT test

- Whether the rubric scoring produces correct measurements at runtime
- Whether secret patterns actually catch real leaks (vs false positives on env-var documentation)
- Whether drift detection correctly cross-references against package.json / source code
- Whether Phase 5 / Phase A-7 user-approval gates actually fire before any write
- Whether the "no" reply genuinely produces no file modifications
- Whether mode auto-detection picks correctly between improve and audit

Those need fixture CLAUDE.md files + recorded baseline outputs. When a real run produces output worth freezing, copy input + expected output into `tests/fixtures/golden/` and add a diff assertion.

## Extending

- Every time a real run produces a bad recommendation or false-positive leak, add an assertion that would have caught it.
- New Anthropic guidance → update the rubric and add a citation assertion.
- New secret patterns leaked in production → add to the secret-pattern list and assert.
- Platform-specific bugs → add portability assertions.
