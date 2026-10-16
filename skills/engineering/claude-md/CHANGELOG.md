# claude-md changelog

History lives here, not in `SKILL.md` — a changelog is loaded on every invoke and
changes no behavior.

## V3 (2026-10-11)
Split into `references/` so the always-loaded body stays a map (411 → map-sized body).
Moved out: the R1–R10 rubric and canonical sections (`references/rubric.md`), the
high-impact-lines menu (`references/high-impact-lines.md`), audit phase detail
(`references/audit-checks.md`), output templates (`references/report-templates.md`), and
all citations (`references/sources.md`).

Also: one `Budgets` definition replacing three restated numbers across two different
metrics (line budget vs. instruction count), with the always-loaded figures explicitly
scoped so a `SKILL.md` limit is never borrowed from a `CLAUDE.md` one. Added
`metadata.owner`. `tests/eval.sh` now asserts against the skill (SKILL.md + references)
rather than pinning every rule into one file.

## V2 (2026-05-27)
Optimized via `skillforge optimize` (outcome research on AI-native repo / AGENTS.md best practices).
- **AGENTS.md support** — audit/improve the cross-agent standard, not just CLAUDE.md; flag CLAUDE.md/AGENTS.md duplication and recommend one-source-of-truth.
- **"Never auto-generate" anti-pattern** with the controlled-study evidence (curated +4pp vs auto-generated −0.5–2% / +20–23% cost). Strengthens the existing trim-not-add doctrine.
- Outcome target: the skill now improves the file that actually changes agent behavior across harnesses, and actively prevents the bloat that degrades it.
