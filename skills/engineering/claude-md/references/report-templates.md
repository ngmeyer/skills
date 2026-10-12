# Output templates

## Improve mode — Phase I-3 change formats

**Deletions** (lines failing R2 or R10):
```
- DELETE line N: "[content]"
  Reason: [R2 — would Claude actually make a mistake without this?]
  OR: [R10 — auto memory captures this from package.json]
```

**Additions** (missing canonical sections per R6):
```
+ ADD section "## [Section Name]" with:
  [proposed content based on actual project — read package.json, README, .git/config]
```

**Rewrites** (specificity R3 + emphasis R4):
```
~ REPLACE line N: "[vague content]"
  WITH: "[concrete, verifiable rewrite]"
  Reason: [R3: was vague | R4: high-impact rule needs IMPORTANT prefix]
```

## Improve mode — Phase I-4 proposal

```markdown
## CLAUDE.md Improvement Proposal

**File:** [path]
**Current size:** N lines (R1 line budget: see SKILL.md → Budgets)
**Rubric pass rate:** M of 10

### Summary
- DELETE: K lines
- ADD: L sections
- REWRITE: J lines
- Net change: ±N lines (final: M lines)

### Proposed Diff
[full diff with reasons]

Apply these changes? (yes / partial / no)
```

## Audit mode — Phase A-6 report

Output grouped by severity, per project. Counts are exact, from the scan — never estimated.

```
# CLAUDE.md Audit Report — <timestamp>

## Summary
- 6 CLAUDE.md files scanned
- 1 P0 LEAK (acme-web)
- 2 projects with drift (data-pipeline, saas-app)
- 0 over budget
- 3 projects clean

---

## acme-web 🔴 P0 LEAK
**File:** <projects-root>/acme-web/CLAUDE.md (142 instructions)

### Leaks (P0 — rotate before any other work)
- Line 38: `AUTH_SECRET=...` (value redacted in report)
  - Fix: replace with `The AUTH_SECRET env var is required; see .env.example`
  - Rotate the secret in production, then `git filter-repo --path CLAUDE.md --invert-paths`

### Drift
- Line 52: claims SMTP — code uses the vendor's REST client (src/lib/email.ts:4)
  - Fix: change to "<vendor> REST API"

### Duplicates
- "## Email" heading appears at lines 50 and 89
```
