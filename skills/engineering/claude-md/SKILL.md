---
name: claude-md
description: >
  All-in-one skill for `CLAUDE.md` and `AGENTS.md` instruction files. Two modes: `audit` finds drift
  (claimed facts no longer matching code), leaked secrets, duplicates, instruction-budget bloat, and
  prescriptive-vs-descriptive imbalance across every such file in your projects. `improve` measures one
  file against Anthropic's official best practices (line budget, removability test, emphasis tuning,
  3-tier hierarchy) plus community-validated guidance, then proposes concrete rewrite diffs applied only
  after user approval. Default behavior auto-detects: in a project with a CLAUDE.md → improve mode;
  otherwise → audit all.
  Use when: 'audit claude.md', 'check claude md drift', 'lint CLAUDE.md', 'claude md audit',
  'audit AGENTS.md', 'refresh instructions', 'improve CLAUDE.md', 'restructure CLAUDE.md',
  'tune CLAUDE.md', 'apply CLAUDE.md best practices', 'is my CLAUDE.md good', 'CLAUDE.md is too long',
  'rebalance CLAUDE.md', or quarterly as a hygiene check.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep"]
argument-hint: "[improve|audit] [project name | 'all' | path to CLAUDE.md] — defaults to auto-detect"
metadata:
  owner: ngmeyer
  harness: claude-code
---

# /claude-md -- Audit and Improve CLAUDE.md Files

> **Naming exception (documented):** skillforge's checklist forbids `claude` or `anthropic` in a skill name. This skill is a deliberate exception: it operates on the literal `CLAUDE.md` artifact, so the precision of the name is the value. Treat this as the only such exception in the library.

Two modes, one skill. **Audit** finds problems across many CLAUDE.md files (hygiene). **Improve** rewrites one file against a best-practice rubric (structure). Both ground in the same core principle.

## Core Principle

> **The removability test:** "For every line in CLAUDE.md, ask — *if I removed this, would Claude make a mistake?* If not, remove it."
> — Anthropic, [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)

This is the unifying rule. Audit mode flags lines that fail the test as drift / waste / duplicates. Improve mode proposes their removal. Same diagnostic, different scale.

A second invariant cuts across both modes: **CLAUDE.md is tracked in git and visible to every agent that opens the repo.** Pasted secrets are durable leaks. Both modes treat secret-leak detection as a P0 finding.

## Mode Dispatch

| Invocation | Mode | What runs |
|---|---|---|
| `/claude-md` (no args, in a project with `./CLAUDE.md`) | auto → improve | Improve the local CLAUDE.md |
| `/claude-md` (no args, no local file) | auto → audit | Scan every CLAUDE.md under your projects roots |
| `/claude-md improve [path]` | improve | Single-file structural rewrite (10-rule rubric) |
| `/claude-md audit [project\|all\|path]` | audit | Hygiene scan: secrets P0, drift, duplicates, budget |

If both modes would apply (e.g. `/claude-md improve` in a folder with no CLAUDE.md), ask for clarification.

### Also applies to `AGENTS.md`

`AGENTS.md` is the cross-agent standard (Linux Foundation / Agentic AI Foundation; read by Codex, Cursor, Gemini, Copilot, and 30+ tools). Everything here — the rubric, the secret scan, drift detection, the budget — applies to `AGENTS.md` identically. When both exist, audit both and flag duplication: the right pattern is **one source of truth** (`AGENTS.md`) with `CLAUDE.md` as a thin alias/`@import`, not two drifting files. Treat a repo's nearest-scoped `AGENTS.md` (monorepos nest them) the same way.

## Budgets (one definition — cite it, don't restate it)

Two different metrics were both called "the budget" here, with three different numbers. They are not the same thing:

| metric | value | unit | source |
|---|---|---|---|
| **Line budget** | **200** | lines of the file | Anthropic — [memory docs](https://code.claude.com/docs/en/memory) |
| **Instruction count** | 100 / 200 | imperative lines (Phase A-5) | this skill's own bands |

The **line budget is the single number.** Every mode reports against it and nothing restates it with a different value. The instruction count is a separate signal: a 150-line file can hold 200 instructions, and the fix differs (trim prose vs. split rules out).

**If you want the line budget tighter, change it here and nowhere else.** OpenAI puts an always-loaded map file at roughly half: "we treat it as **the table of contents**… A short `AGENTS.md` (roughly 100 lines) is injected into context and serves primarily as a map, with pointers to deeper sources" ([Harness engineering](https://openai.com/index/harness-engineering/), Feb 2026). Both numbers are published and both are defensible; 200 is kept because it is Anthropic's figure for *this* file. Tightening to 100 is a judgment call, not a bug fix.

**Do not borrow either number for a `SKILL.md`.** Both apply to files injected at launch. A skill body is not: only its `name` and `description` are pre-loaded, and the body is read when the skill becomes relevant, so its ceiling is 500 lines and its enforced limit lives in `scripts/lint-skills.sh`. Same word, different artifact.

---

## Improve Mode

Measure one file against the rubric, then propose concrete rewrite diffs. Apply only after user approval.

**Rubric: references/rubric.md** — R1–R10 with sources, the 5 canonical sections (R6 detail), and the anti-pattern list. Every recommendation cites the rule it enforces.

**One empirical caveat (Claude Code specifically).** When the target file is short (<100 lines) and already aligned with Karpathy-style rules, *adding* more rules can regress Claude Code quality. Augment Code (April 2026) tested Karpathy rules across Auggie, Claude Code, and Codex on 40 OpenClaw PRs: speed and cost improved on all three (−3% to −8% on duration and tool calls), but Claude Code quality dropped 0.07 overall (correctness −0.07, completeness −0.06, code reuse −0.05). Auggie and Codex were stable. Their hypothesis: Claude Code's system prompt already encodes similar constraints; further layering reduces exploration. **When the rubric scores 9/10 or 10/10 on a Claude Code target, the default recommendation is trim, not add.**

### Improve Mode Procedure

#### Phase I-1: SCOPE

1. Resolve the target file. If multiple candidates exist, list them and ask.
2. Read the file in full. Note size (lines, characters).
3. Read sibling files for cross-tier duplication detection: the user-level `CLAUDE.md` (if improving a project file), `./CLAUDE.local.md`, and `./.claude/rules/*.md` (path-scoping in use?).

#### Phase I-2: MEASURE

Run the rubric programmatically where possible:

```bash
LINES=$(wc -l < "$TARGET")                                   # R1
grep -c -iE 'IMPORTANT|YOU MUST|NEVER' "$TARGET"             # R4
grep -c '^#' "$TARGET"                                       # R5
# R10: cross-reference against package.json / pyproject.toml / Cargo.toml / etc.
```

Produce a per-rule scorecard with line-level evidence.

#### Phase I-3: PROPOSE

Three categories of change — DELETE (fails R2 or R10), ADD (missing canonical section per R6), REWRITE (specificity R3 + emphasis R4). Exact formats: references/report-templates.md. Draw additions from references/high-impact-lines.md, subject to the trim-not-add caveat above.

#### Phase I-4: PRESENT

Proposal template: references/report-templates.md. Report current size against the line budget, rubric pass rate out of 10, exact counts per change category, then the full diff with reasons. End by asking: apply these changes? (yes / partial / no)

#### Phase I-5: APPLY

Use the `Edit` tool for surgical changes — never overwrite the whole file with `Write`. Apply one change at a time. After all changes:

1. Re-measure: print new size, new rubric pass rate.
2. Suggest: "Run `/claude-md audit` afterward to verify no drift introduced."
3. If the file now has obvious path-scoped subsections, suggest splitting them into `.claude/rules/<topic>.md` (R9).

---

## Audit Mode

Lint and audit CLAUDE.md files across all projects. Flags drift (claimed facts no longer matching code), leaked secrets, duplicate blocks, descriptive-vs-prescriptive line balance, and files approaching either budget.

CLAUDE.md files rot. In practice a portfolio audit will routinely surface several projects with drifted files — and occasionally one with a leaked secret. This mode catches both shapes in one pass.

**Check detail for A-2 through A-5.5: references/audit-checks.md.**

### Audit Mode Procedure

#### Phase A-1: DISCOVER

Find every `CLAUDE.md` under your projects roots, skipping vendored trees:

```bash
find "$PROJECTS_ROOT" -name 'CLAUDE.md' \
  -not -path '*/node_modules/*' -not -path '*/.venv/*' -not -path '*/vendor/*' 2>/dev/null
```

For each file, note the owning project and size (line count).

#### Phase A-2: SECRET SCAN (ALWAYS RUN FIRST)

Grep each file for high-confidence secret patterns — assignments, JWT prefixes, URL-embedded credentials, `sk_live_`/`sk-ant-` provider prefixes, `postgres://` connection strings, a pasted `AUTH_SECRET`. Full pattern list in references/audit-checks.md.

**This phase runs before any other audit because a leak is a P0 finding that interrupts the rest of the flow.** Any match → mark the file 🔴 P0 LEAK and report the line, the pattern, and the remediation (rotate, then reference env var names only, then scrub history).

#### Phase A-3: DRIFT DETECTION

Verify every claim the file makes against real code, across six categories: **MCP servers**, **API routes**, **Cron jobs**, **Env vars**, **External services**, **Directory structure**. Each finding reports the CLAUDE.md line, the actual code fact, and the one-line edit that fixes it. Details and the grep targets: references/audit-checks.md.

#### Phase A-4: DUPLICATE + STRUCTURE CHECKS

Duplicate section headings, near-duplicate paragraphs, and any line contradicting another line in the same file.

#### Phase A-5: INSTRUCTION BUDGET + PRESCRIPTIVE RATIO

Count imperative instructions, report against the instruction-count bands (separate from the R1 line budget — report both), and classify descriptive vs prescriptive lines. Descriptive lines are budget waste.

#### Phase A-5.5: HOOK-CANDIDATE DETECTION

CLAUDE.md instructions are advisory — compliance runs around 70–80%, so a rule phrased as an absolute command fails silently. Flag deterministic-sounding rules (`NEVER`/`Always`/`MUST` + verb, destructive commands, 100% pre-commit gates) as `hook-candidate` and name the right hook type.

#### Phase A-6: REPORT

Grouped by severity, per project, P0 leaks first. Template: references/report-templates.md.

#### Phase A-7: OFFER FIXES (INTERACTIVE)

Ask: "Apply the suggested edits for <project X>? [y/N]". Apply only after confirmation. **Do NOT apply P0 LEAK fixes automatically** — they require secret rotation and a git-history scrub the user must drive.

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
- **Do not rotate secrets or scrub git history.** Audit reports leaks and guides; the user drives the rotation + history scrub.
- **Do not enforce a specific style across repos.** Each repo's existing voice is respected. Improve mode rewrites for STRUCTURE, not VOICE.
- **Do not flag perfectly fine lines.** A line that fails the removability test must actually fail it — not "could maybe be tighter."
- **Do not add a rule on first occurrence of a mistake.** Log it in MEMORY.md or a scratch list. Promote to CLAUDE.md only after the second occurrence. Improves signal-to-noise; cuts noise rules that bloat the file without preventing real mistakes. (Source: Redreamality, April 2026.)
- **Do not hardcode user paths.** Use `$TARGET`, `$HOME`, `$1`.

## Sibling Skills

| Skill | When |
|---|---|
| **`/claude-md improve`** | One file, structural rewrite for best-practice alignment |
| **`/claude-md audit`** | Many files, hygiene / drift / secret scan |
| `/init` (Anthropic built-in) | Generate a starter CLAUDE.md from current project state |
| `compound-engineering:ce-compound-refresh` | Same spirit, different target — refreshes `docs/solutions/` |

## References

- `references/rubric.md` — R1–R10, canonical sections, anti-patterns
- `references/high-impact-lines.md` — the add-only-if-missing menu
- `references/audit-checks.md` — secret patterns, drift categories, hook candidates
- `references/report-templates.md` — proposal and report formats
- `references/sources.md` — every citation, incl. [memory docs](https://code.claude.com/docs/en/memory), [best practices](https://code.claude.com/docs/en/best-practices), and the Strunk lineage behind the removability test
- `CHANGELOG.md` — version history (kept out of this always-loaded body)

## Testing

```bash
bash tests/eval.sh
```

To verify behavior end-to-end:

1. Improve: `/claude-md improve` in any project — verify the scorecard cites every R1–R10, every change cites its rule, "no" writes nothing, "yes" applies surgically
2. Audit: `/claude-md audit all` — verify the P0 LEAK section appears first when leaks are present, drift findings cite specific code locations, budgets reported per file
3. Auto-detect: `/claude-md` (no args) in a project with CLAUDE.md → improve; in a dir with no local file → audit
4. Mode override: `/claude-md audit ./CLAUDE.md` → single-file audit
