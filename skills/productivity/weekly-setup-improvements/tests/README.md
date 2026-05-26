# weekly-setup-improvements — Eval harness

**Level:** Prompt-only (writes one report file). Behavioral testing requires a fixture folder with 7 days of seeded activity plus a recorded expected report — moderate fixture cost, deferred. This harness asserts the design contract: 6 phases, 5 analysis lenses, 5 report sections, quality bar, portability, and the 3-skill cap intact in SKILL.md.

## What's asserted

- All 6 phases present (SCOPE → SURVEY → READ → ANALYZE → WRITE → PRESENT)
- All 5 analysis lenses (Repetition, Manual effort, Drift, Bloat, Wins)
- All 5 report sections (Context File Updates, New Skill Ideas, Workflow Gaps, Files to Clean Up, What's Working)
- Quality Bar section present, with hedge phrases (`consider`, `perhaps`) explicitly called out
- 3-skill cap stated and reinforced in "What NOT to Do"
- **Portability:** no `/Users/<name>/` or `/home/<name>/` hardcoded paths
- **Cross-platform:** uses `--since=` git flag; `date -v` only ever mentioned as banned, never used as a command
- Canonical output filename (`weekly-setup-improvements.md`) and archive-by-date pattern present
- Sibling skill awareness (`/vault-audit`, `/claude-md-audit` referenced)
- Anti-diary rule ("Do not write a session log") present
- README, LICENSE, CLAUDE.md all shipped

## Run

```bash
bash tests/eval.sh
```

Exit 0 = contract intact. Exit 1 = regression.

## What this does NOT test

- Whether the report actually surfaces the right patterns at runtime
- Whether the 3-skill cap is enforced in practice (vs just stated)
- Whether hedge phrases never sneak into actual generated output
- Whether prior-report archiving works correctly across timezone boundaries
- Whether the `compound-engineering:ce-sessions` optional path degrades gracefully

Those need a fixture folder + an expected report. When a real run produces output worth freezing as baseline, copy it into `tests/fixtures/golden/` and add a diff assertion.

## Extending

- Every time a real run produces a hedge phrase or an unjustified skill suggestion, add an assertion that would have caught it.
- New report sections → add to the section-present checks.
- Platform-specific bugs → add portability assertions.
