---
name: claude-md
description: >
  All-in-one skill for CLAUDE.md files. Two modes: `audit` finds drift (claimed facts no longer
  matching code), leaked secrets, duplicates, instruction-budget bloat, and prescriptive-vs-descriptive
  imbalance across all CLAUDE.md files in your projects. `improve` measures one CLAUDE.md against
  Anthropic's official best practices (200-line budget, removability test, emphasis tuning, 3-tier
  hierarchy) plus community-validated guidance, then proposes concrete rewrite diffs applied only
  after user approval. Default behavior auto-detects: in a project with a CLAUDE.md → improve mode;
  otherwise → audit all.
  Use when: 'audit claude.md', 'check claude md drift', 'lint CLAUDE.md', 'claude md audit',
  'refresh instructions', 'improve CLAUDE.md', 'restructure CLAUDE.md', 'tune CLAUDE.md',
  'apply CLAUDE.md best practices', 'is my CLAUDE.md good', 'CLAUDE.md is too long',
  'rebalance CLAUDE.md', or quarterly as a hygiene check.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep"]
argument-hint: "[improve|audit] [project name | 'all' | path to CLAUDE.md] — defaults to auto-detect"
---

# /claude-md -- Audit and Improve CLAUDE.md Files

> **Naming exception (documented):** skillforge's checklist forbids `claude` or `anthropic` in a skill name. This skill is a deliberate exception: it operates on the literal `CLAUDE.md` artifact, so the precision of the name is the value. Treat this as the only such exception in the library.

Two modes, one skill. **Audit** finds problems across many CLAUDE.md files (hygiene). **Improve** rewrites one file against best-practice rubric (structure). Both ground in the same core principle.

## Core Principle

> **The removability test:** "For every line in CLAUDE.md, ask — *if I removed this, would Claude make a mistake?* If not, remove it."
> — Anthropic, [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)

This is the unifying rule. Audit mode flags lines that fail the test as drift / waste / duplicates. Improve mode proposes their removal. Same diagnostic, different scale.

A second invariant cuts across both modes: **CLAUDE.md is tracked in git and visible to every agent that opens the repo.** Pasted secrets are durable leaks. Both modes treat secret-leak detection as a P0 finding.

## Mode Dispatch

| Invocation | Mode | What runs |
|---|---|---|
| `/claude-md` (no args, in a project with `./CLAUDE.md`) | auto → improve | Improve the local CLAUDE.md |
| `/claude-md` (no args, no local file) | auto → audit | Scan all CLAUDE.md files under your projects roots (e.g. `~/Projects`) |
| `/claude-md improve [path]` | improve | Single-file structural rewrite (10-rule rubric) |
| `/claude-md audit [project\|all\|path]` | audit | Hygiene scan: secrets P0, drift, duplicates, budget |

If both modes would apply (e.g., `/claude-md improve` in a folder with no CLAUDE.md), the skill asks for clarification.

### Also applies to `AGENTS.md` (V2)

`AGENTS.md` is the cross-agent standard (Linux Foundation / Agentic AI Foundation; read by Codex, Cursor, Gemini, Copilot, and 30+ tools). Everything here — the rubric, the secret scan, drift detection, the budget — applies to `AGENTS.md` identically. When both exist, audit both and flag duplication: the right pattern is **one source of truth** (`AGENTS.md`) with `CLAUDE.md` as a thin alias/`@import`, not two drifting files. Treat a repo's nearest-scoped `AGENTS.md` (monorepos nest them) the same way.

---

## Improve Mode

Measure one CLAUDE.md against Anthropic's official best practices + community-validated guidance, then propose concrete rewrite diffs. Apply only after user approval.

**One empirical caveat (Claude Code specifically).** When the target file is short (<100 lines) and already aligned with Karpathy-style rules, *adding* more rules can regress Claude Code quality. Augment Code (April 2026) tested Karpathy rules across Auggie, Claude Code, and Codex on 40 OpenClaw PRs: speed and cost improved on all three (−3% to −8% on duration and tool calls), but Claude Code quality dropped 0.07 overall (correctness −0.07, completeness −0.06, code reuse −0.05). Auggie and Codex were stable. Their hypothesis: Claude Code's system prompt already encodes similar constraints; further layering reduces exploration. When the rubric scores 9/10 or 10/10 on a Claude Code target, the default recommendation is trim, not add.

### The Rubric

Ten checks, each backed by a primary source. Every recommendation cites the rule.

| # | Rule | Source |
|---|---|---|
| R1 | **Length under 200 lines.** Longer reduces adherence. | Anthropic — [How Claude remembers your project](https://code.claude.com/docs/en/memory) |
| R2 | **Removability test on every line.** | Anthropic — [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices) |
| R3 | **Specificity: instructions concrete enough to verify.** No "be a senior engineer." | Anthropic — Memory docs |
| R4 | **Emphasis on load-bearing rules.** `IMPORTANT:` / `YOU MUST` / `NEVER`. Use sparingly — if every rule is IMPORTANT, none are. | Anthropic — Best Practices |
| R5 | **Markdown structure: headers + bullets.** Not dense paragraphs. | Anthropic — Memory docs |
| R6 | **5 canonical sections present** (Commands, Architecture, Rules, Workflow, Out-of-scope). | Community consensus + Anthropic `/init` template |
| R7 | **Hard Rules section ≤15 items.** Beyond that, rules drop. | Community (zodchiii thread, 1.3M views) |
| R8 | **3-tier hierarchy used correctly.** Across files: global rules in `~/.claude/CLAUDE.md`, project in `./CLAUDE.md` (git), personal in `./CLAUDE.local.md` (gitignored). No duplication across tiers. Within a file: order by priority — hard non-negotiables at top, context-dependent rules middle, references/conveniences bottom. The instruction budget compresses lower-priority items first. | Anthropic — Best Practices; Fraser (Medium, May 2026) |
| R9 | **Path-scoped rules in `.claude/rules/*.md`** when instructions only apply to certain files. | Anthropic — Advanced Patterns PDF |
| R10 | **No content auto memory will capture, and no standard-tool documentation.** Don't waste lines on stack details Claude figures out from `package.json`, nor on standard tools Claude already knows (`git`, `gh`, `npm`, `pnpm`, `bun`, `cargo`, `python`, `node`, `tsc`, `eslint`, `prettier`, `make`). Document only custom wrappers or non-obvious project-specific invocations. | Community + Anthropic auto-memory docs; Fraser (Medium, May 2026) |

### Improve Mode Procedure

#### Phase I-1: SCOPE

1. Resolve the target file. If multiple candidates exist, list them and ask.
2. Read the file in full. Note size (lines, characters).
3. Read sibling files for cross-tier duplication detection:
   - `~/.claude/CLAUDE.md` (if improving a project file)
   - `./CLAUDE.local.md` (if present)
   - `./.claude/rules/*.md` (path-scoping in use?)

#### Phase I-2: MEASURE

Run the 10-rule rubric programmatically where possible:

```bash
LINES=$(wc -l < "$TARGET")                                   # R1
grep -c -iE 'IMPORTANT|YOU MUST|NEVER' "$TARGET"             # R4
grep -c '^#' "$TARGET"                                       # R5
# R10: cross-reference against package.json / pyproject.toml / Cargo.toml / etc.
```

Produce a per-rule scorecard with line-level evidence.

#### Phase I-3: PROPOSE

Three categories of change:

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

#### Phase I-4: PRESENT

```markdown
## CLAUDE.md Improvement Proposal

**File:** [path]
**Current size:** N lines (R1 budget: 200)
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

#### Phase I-5: APPLY

Use the `Edit` tool for surgical changes — never overwrite the whole file with `Write`. Apply one change at a time. After all changes:
1. Re-measure: print new size, new rubric pass rate.
2. Suggest: "Run `/claude-md audit` afterward to verify no drift introduced."
3. If the file now has obvious path-scoped subsections, suggest splitting them into `.claude/rules/<topic>.md` (R9).

### The 5 Canonical Sections (R6 detail)

A CLAUDE.md scoring well on R6 contains these sections. Suggest creating any that are missing:

1. **`## Project`** (1–2 lines: what this is, who uses it)
2. **`## Stack`** (1–3 lines: framework, language, deployment target)
3. **`## Commands`** (Build / Dev / Test single / Test all / Lint / Type check — short, exact)
4. **`## Architecture`** (folder → purpose mapping; not full directory listing)
5. **`## Rules`** (under 15 items; negative rules count; emphasis on the load-bearing one)
6. **`## Workflow`** (how the user wants Claude to approach tasks: minimal changes, ask vs act, commit conventions)
7. **`## Out of scope`** (files/integrations Claude should not touch)

### High-Impact Lines That Compound

A menu to draw from when a file is genuinely *missing* a scope-control or safety rule. **Subject to the trim-not-add caveat above:** on an already-aligned Claude Code target scoring 9–10/10, do not bulk-add these — Claude Code's system prompt already encodes most of them, and layering regresses quality (Augment Code, April 2026). Add the one or two that close a real, observed gap; skip the rest.

**Scope & safety (highest leverage — prevent expensive, hard-to-revert mistakes):**

- `Only modify files, functions, and lines directly related to the current task. Do not refactor, rename, or reformat anything I did not ask you to change. Note other issues at the end; don't touch them.`
- `Before any change that significantly alters existing content (rewriting sections, restructuring, changing tone): stop, describe what you're about to change and why, wait for confirmation.`
- `Before deleting a file, overwriting code, dropping records, or removing dependencies: stop, list what will be affected, ask for explicit confirmation in the current message. "You mentioned this earlier" is not confirmation.`
- `Production hard-stops requiring in-session confirmation: deploys/pushes, migrations or schema changes, outbound API calls, any command with irreversible side effects.` *(If a stop must hold 100% of the time, a PreToolUse hook is the real enforcement — CLAUDE.md compliance ceilings around 80%.)*
- `After any coding task, end with: files changed, one-line summary per file, files intentionally not touched, follow-up needed.`
- `NEVER commit .env files or secrets`
- `NEVER run git push --force without explicit confirmation`

**Workflow:**

- `IMPORTANT: run type check after every code change`
- `Make minimal changes, don't refactor unrelated code`
- `Create separate commits per logical change, not one giant commit`
- `When unsure between two approaches, explain both and let me choose`
- `For architecture decisions or non-trivial features: work through the problem step by step before writing code. Show reasoning and where you're uncertain, then implement.`

**Communication (lowest marginal value on Claude Code — its system prompt already does most of this; add only if you observe the specific failure):**

- `Match response length to task complexity. Don't pad with restatements of the question or closing summaries.`
- `If uncertain about a fact, statistic, date, or technical detail, say so explicitly rather than filling the gap with plausible-sounding content.`

Wording sourced from the Karpathy-derived rule compilations (Fraser, May 2026; "Dep" thread, May 2026). Their headline stats ("65% → 94% accuracy", per-developer dollar figures, star counts) are illustrative marketing, not measured results — cite the *rule wording*, not the numbers.

### What NOT to Include (anti-patterns)

- Personality instructions ("be a senior engineer")
- Code-formatter rules the linter already handles
- Duplicate rules across tiers
- `@-imports` of full README / huge docs (they enter the context window at launch)
- Anything Claude learns on its own via auto memory
- **(V2) Auto-generated bulk.** Never `/init`-and-forget or paste an LLM-generated context file. Controlled study: a *curated* context file gives ~+4pp task quality at ~20% token overhead, but an *auto-generated* one **reduces** task success ~0.5–2% while raising cost 20–23%. Curate ruthlessly; more context is not better. (arXiv 2026, AGENTS.md efficiency study.)

---

## Audit Mode

Lint and audit CLAUDE.md files across all projects. Flags drift (claimed facts no longer matching code), leaked secrets, duplicate blocks, descriptive-vs-prescriptive line balance, and files approaching the 150-200 instruction budget.

CLAUDE.md files rot. In practice, a portfolio audit will routinely surface several projects with drifted CLAUDE.md — and occasionally one with a leaked secret. This mode catches both shapes in one pass.

### Audit Mode Procedure

#### Phase A-1: DISCOVER

1. Find every `CLAUDE.md` under your projects roots (adjust to where you keep code, e.g. `~/Projects`, `~/work`):
   ```bash
   find ~/Projects ~/work -name 'CLAUDE.md' \
     -not -path '*/node_modules/*' -not -path '*/.venv/*' -not -path '*/vendor/*' 2>/dev/null
   ```
2. For each file, note the owning project and size (line count).

#### Phase A-2: SECRET SCAN (ALWAYS RUN FIRST)

For each CLAUDE.md, grep for high-confidence secret patterns. **This phase runs before any other audit because a leak is a P0 finding that interrupts the rest of the flow.**

Patterns to flag:
- `(?i)(secret|token|api[_-]?key|password)\s*[:=]\s*['"]\S{8,}['"]`
- `(?i)auth[_-]?secret\s*[:=]\s*\S{8,}`
- Base64-ish JWT prefixes: `eyJ[A-Za-z0-9_-]{10,}`
- URLs with embedded credentials: `https?://[^:/\s]+:[^@\s]+@`
- Stripe/OpenAI/Anthropic key prefixes: `sk_live_`, `sk_test_`, `pk_live_`, `sk-ant-`, `sk-proj-`
- Supabase/Neon connection strings: `postgres(ql)?://[^:]+:[^@]+@`

**If any match:** mark file 🔴 P0 LEAK. Report the line, pattern matched, required remediation: rotate the secret in source system, edit CLAUDE.md to reference env var names only, scrub git history (`git filter-repo --path CLAUDE.md --invert-paths` or BFG).

#### Phase A-3: DRIFT DETECTION

For each claim CLAUDE.md makes, verify against real code:

1. **MCP servers** — diff against `settings.json` / `.mcp.json` / `mcp.json`
2. **API routes** — grep for routes named in CLAUDE.md; verify each exists in `src/app/api/` or routes file
3. **Cron jobs** — count asserted vs actual `*/cron*` files / `vercel.json` crons / `wrangler.toml` triggers
4. **Env vars** — every env var named should appear in `.env.example` or be read by code (`process.env.<NAME>` / `os.environ["<NAME>"]`)
5. **External services** — flag contradictions ("uses Brevo SMTP" but code imports `@getbrevo/brevo` REST client)
6. **Directory structure** — diff enumerated dirs against `ls` output

For each drift finding: report the CLAUDE.md line, the actual code fact, and the one-line edit that fixes it.

#### Phase A-4: DUPLICATE + STRUCTURE CHECKS

1. Detect duplicate section headings (`^## `, `^### ` appearing ≥2 times)
2. Detect near-duplicate paragraphs (same first 60 characters on two different lines)
3. Report any line contradicting another line in the same file

#### Phase A-5: INSTRUCTION BUDGET + PRESCRIPTIVE RATIO

1. Count instructions — any line starting with imperative verb (Always, Never, Use, Don't, Prefer, Avoid, Run, Check, Write, Edit, Follow) OR inside a bullet list under "Rules/Conventions/Do/Don't" heading
2. Budget thresholds:
   - ≤ 100 instructions: 🟢 healthy
   - 100–200: 🟡 monitor
   - > 200: 🟠 over budget — suggest splits or cuts
3. Descriptive vs prescriptive classifier:
   - **Descriptive** = describes what code already shows ("this is a Next.js app with Postgres")
   - **Prescriptive** = tells Claude what to do ("when editing migrations, add both up and down")
   Report ratio. Descriptive lines are budget waste.

#### Phase A-5.5: HOOK-CANDIDATE DETECTION

CLAUDE.md instructions are advisory — community evidence puts compliance around 70–80%. Rules phrased as absolute commands fail this ceiling silently. Scan for deterministic-sounding rules and flag them for hook conversion.

Patterns to flag:

- Lines starting with `NEVER`, `Never`, `Always`, `MUST`, `Do not` followed by a verb
- Rules naming destructive commands: `rm -rf`, `git push --force`, `git reset --hard`, `DROP TABLE`, `truncate`, `vercel --prod`, `gcloud ... delete`
- Rules requiring 100% pre-commit gates: lint, typecheck, test must pass before commit

For each match: report the line, classify as `hook-candidate`, and identify the right hook type:

- Destructive command gates → `PreToolUse` hook returning exit code 2 to block
- Pre-commit verification → `PreToolUse` on git commit or `PostToolUse` on file Edit/Write
- Always-run-after-edit checks → `PostToolUse` hook

Report wording: "This rule reads as deterministic but lives in advisory territory. Convert to a hook in `.claude/settings.json` for 100% enforcement; keep the CLAUDE.md line as documentation of the hook's intent, or remove it." Cite [Anthropic hooks docs](https://code.claude.com/docs/en/hooks) and the ~80% advisory ceiling.

#### Phase A-6: REPORT

Output grouped by severity, per project:

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
**File:** ~/Projects/acme-web/CLAUDE.md (142 instructions)

### Leaks (P0 — rotate before any other work)
- Line 38: `AUTH_SECRET=...` (value redacted in report)
  - Fix: replace with `The AUTH_SECRET env var is required; see .env.example`
  - Rotate the secret in production, then `git filter-repo --path CLAUDE.md --invert-paths`

### Drift
- Line 52: claims "Brevo SMTP" — code uses REST (`@getbrevo/brevo` at src/lib/email.ts:4)
  - Fix: change to "Brevo REST API via @getbrevo/brevo"

### Duplicates
- "## Email" heading appears at lines 50 and 89
```

#### Phase A-7: OFFER FIXES (INTERACTIVE)

After the report, ask: "Apply the suggested edits for <project X>? [y/N]". Apply only after confirmation. **Do NOT apply P0 LEAK fixes automatically** — they require secret rotation and git-history scrub the user must drive.

---

## Quality Bar (both modes)

A run passes if **every** check is true. Otherwise rewrite the offending recommendation.

- Every deletion / drift finding cites the rule it enforces (R1–R10 in improve; specific drift type in audit)
- Every addition uses real project data (read `package.json`, `pyproject.toml`, etc.) — not generic placeholders
- Every rewrite provides a concrete replacement, not "make this clearer"
- No proposal uses "consider", "perhaps", "you might want to" — every suggestion is concrete and accept/reject-able
- Summaries contain exact counts, not estimates
- P0 LEAK findings always present before any other audit content (audit mode)

## Gotchas (both modes)

- **Do not auto-apply.** Always present for approval. Surgical Edits only — never whole-file Write.
- **Do not invent project context.** Read `package.json` / `pyproject.toml` / `Cargo.toml` / `Gemfile` / `README.md` to ground suggestions in actual project data.
- **Do not propose splitting into `.claude/rules/` automatically.** Suggest it; the user decides.
- **Do not rotate secrets or scrub git history.** Audit reports leaks and guides; user drives the rotation + history scrub.
- **Do not enforce a specific style across repos.** Each repo's existing voice is respected. Improve mode rewrites for STRUCTURE, not VOICE.
- **Do not flag perfectly fine lines.** A line that fails the removability test must actually fail it — not "could maybe be tighter."
- **Do not add a rule on first occurrence of a mistake.** Log it in MEMORY.md or a scratch list. Promote to CLAUDE.md only after the second occurrence. Improves signal-to-noise; cuts noise rules that bloat the file without preventing real mistakes. (Source: Redreamality, April 2026.)
- **Do not hardcode user paths.** Use `$TARGET`, `$HOME`, `$1`. Never `/Users/<name>/...`.

## Changelog

### V2 (2026-05-27)
Optimized via `skillforge optimize` (outcome research on AI-native repo / AGENTS.md best practices).
- **AGENTS.md support** — audit/improve the cross-agent standard, not just CLAUDE.md; flag CLAUDE.md/AGENTS.md duplication and recommend one-source-of-truth.
- **"Never auto-generate" anti-pattern** with the controlled-study evidence (curated +4pp vs auto-generated −0.5–2% / +20–23% cost). Strengthens the existing trim-not-add doctrine.
- Outcome target: the skill now improves the file that actually changes agent behavior across harnesses, and actively prevents the bloat that degrades it. Sources: [AGENTS.md efficiency study (arXiv 2026)](https://arxiv.org/html/2601.20404v2); [agents.md standard](https://agents.md/); Augment Code AGENTS.md guide.

## Sibling Skills

| Skill | When |
|---|---|
| **`/claude-md improve`** | One file, structural rewrite for best-practice alignment |
| **`/claude-md audit`** | Many files, hygiene / drift / secret scan |
| `/init` (Anthropic built-in) | Generate a starter CLAUDE.md from current project state |
| `compound-engineering:ce-compound-refresh` | Same spirit, different target — refreshes `docs/solutions/` |

## References

**Anthropic primary sources:**
- [How Claude remembers your project](https://code.claude.com/docs/en/memory)
- [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)
- [How Anthropic teams use Claude Code (PDF)](https://www-cdn.anthropic.com/58284b19e702b49db9302d5b6f135ad8871e7658.pdf)
- [Claude Code Advanced Patterns (PDF)](https://resources.anthropic.com/hubfs/Claude%20Code%20Advanced%20Patterns_%20Subagents%2C%20MCP%2C%20and%20Scaling%20to%20Real%20Codebases.pdf)

**Community sources (consistent with primary):**
- [HumanLayer — Writing a Good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md)
- [zodchiii — The CLAUDE.md File That 10x'd My Output](https://x.com/zodchiii/status/2048683276194185640) (1.3M views)
- [abhishekray07/claude-md-templates](https://github.com/abhishekray07/claude-md-templates)
- [Augment Code — Karpathy skills on OpenClaw (April 2026)](https://www.augmentcode.com/blog/karpathy-skills-on-openclaw-agents-don-t-write-better-code-but-they-do-it-more-efficiently) — empirical counterevidence: Claude Code quality regressed −0.07 when Karpathy rules were layered on top of an already-aligned system prompt.
- [Fraser — Claude.md Setup Tips That Will 10x Your Claude Code Workflow (Medium, May 2026)](https://medium.com/ai-systems-lab/claude-md-setup-tips-that-will-10x-your-claude-code-workflow-1d7d23793755) — Karpathy's 4 rules + 8 additions, including CLI-redundancy avoidance and in-file priority ordering.
- ["Dep" (@0xdepressionn) — Karpathy CLAUDE.md rule compilation (X, May 2026)](https://x.com/0xdepressionn/status/2055999112470839383) — viral 14-rule set (7 communication + 7 behavior/safety) expanding Karpathy's 4 behaviors; feeds the high-impact-lines menu above. ⚠️ Headline stats (82k stars, 65%→94% accuracy, $/week figures) are unsourced marketing — the rule wording is the value, the numbers are not citable.
- [Redreamality — CLAUDE.md and AGENTS.md, In Depth (April 2026)](https://redreamality.com/blog/claude-md-agents-md-deep-dive/) — second-occurrence promotion rule; ~80% advisory ceiling synthesis.

**Related discipline:**
- Strunk & White — *The Elements of Style* — Rule 17 ("Omit needless words") is the upstream principle behind Anthropic's removability test

## Testing

Run the structural eval:

```bash
bash tests/eval.sh
```

To verify behavior end-to-end:

1. Improve: `/claude-md improve` in any project — verify rubric scorecard cites every R1–R10, every change cites its rule, "no" reply writes nothing, "yes" applies surgically
2. Audit: `/claude-md audit all` — verify P0 LEAK section appears first when leaks present, drift findings cite specific code locations, instruction budget reported per file
3. Auto-detect: `/claude-md` (no args) in a project with CLAUDE.md → improve runs; in `~/` with no local file → audit runs
4. Mode override: `/claude-md audit ./CLAUDE.md` → single-file audit (subset of audit, single target)
