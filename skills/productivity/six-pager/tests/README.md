# six-pager — Eval harness

**Level:** Prompt-only (writes a document at most, only after user-confirmed save). Behavioral testing requires fixture topics + LLM-as-judge against expected document structure and audit findings — moderate fixture cost, deferred. This harness asserts the design contract: 6 phases, 2 modes, 6 canonical memo sections, 3 PRFAQ sub-documents, prose-audit checks, sibling awareness, three-tradition citation, hard-cap and Tenets-discipline invariants.

## What's asserted

- All 6 phases (SCOPE → DRAFT → CONSTRAIN → AUDIT → PRESENT → SAVE)
- Both modes documented (`memo` and `prfaq`)
- All 6+1 canonical memo sections (Introduction, Goals, Tenets, State of Business, Lessons Learned, Strategic Priorities, Appendix)
- All 3 PRFAQ sub-documents (Press Release, External FAQ, Internal FAQ)
- 8 prose-audit checks (Passive voice, Vague language, Needless words, Qualifiers, Parallel construction, Topic sentence, Overstatement, Removability)
- All 3 traditions cited by name (Bezos, Strunk, Anthropic) plus canonical sources (Working Backwards, Elements of Style, removability test)
- Shipped sibling skills referenced (`/council-review`, `/adversarial-review`)
- Anti-fake-numbers invariant present
- Hard 6-page cap stated; "constraint IS the value" framing present
- Tenets-no-qualifiers rule present; hedge-detection invariant present
- PRFAQ "what would cause us to kill this?" question present; "work backwards" principle stated
- Quality Bar section present
- Both optional flags documented (`--silent-read`, `--strunk-only`)
- **Portability:** no `/Users/<name>/` or `/home/<name>/` hardcoded paths
- README, LICENSE, CLAUDE.md all shipped

## Run

```bash
bash tests/eval.sh
```

Exit 0 = contract intact. Exit 1 = regression.

## What this does NOT test

- Whether the generated 6-pager actually fits in 6 pages at runtime
- Whether the prose audit catches the right issues at runtime
- Whether the Tenets section actually rejects hedges
- Whether `--silent-read` produces useful margin questions
- Whether the PRFAQ "what kills this" answer is real or hand-waved
- Whether mode auto-detection picks correctly between memo and prfaq

Those need fixture topics + recorded baselines. When a real run produces output worth freezing, copy the input + expected document into `tests/fixtures/golden/` and add a diff assertion.

## Extending

- Every time a real run produces a fake-numbers placeholder, add an assertion that would have caught it.
- New audit checks → extend the audit-check loop.
- New canonical sections (if Amazon's practice evolves) → update the section assertions.
- Platform-specific bugs → add portability assertions.
