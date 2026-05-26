# Anthropic Skill Best Practices — Reference

Authoritative skill-authoring guidance distilled from Anthropic's official documentation, engineering blog, and the 17 reference skills in [github.com/anthropics/skills](https://github.com/anthropics/skills). Load this when authoring or improving a skill.

## Sources

- **Anthropic official docs** — [Claude Code Skills](https://code.claude.com/docs/en/skills.md)
- **Anthropic Engineering blog** — [Equipping agents for the real world with Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
- **Anthropic complete guide** — [The Complete Guide to Building Skills for Claude (33pp PDF)](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf)
- **Anthropic reference skills** — [github.com/anthropics/skills](https://github.com/anthropics/skills)
- **Anthropic practitioner thread** — [@trq212 March 2026](https://x.com/trq212/status/2033949937936085378)

## Three-tier progressive disclosure (the core principle)

| Tier | Content | When loaded | Token cost |
|---|---|---|---|
| 1. Frontmatter | `name` + `description` | Always — Claude scans to decide relevance | ~100 tokens |
| 2. SKILL.md body | Full instructions | When Claude decides skill matches task | Up to ~5K tokens |
| 3. Linked files | `references/`, `scripts/`, `assets/` | On demand during execution | Only what's read |

This is why "skill count has minimal context impact" — only the frontmatter is always-loaded. **Stuffing reference docs into SKILL.md inflates token cost across every invocation.** Move detail into `references/`.

## Frontmatter fields

### Required / strongly recommended

```yaml
---
name: skill-name              # lowercase, hyphens, ≤64 chars; must match folder
description: |                # ≤1,536 chars combined with `when_to_use`; routing signal
  What it does. Use when [specific trigger phrases].
---
```

**Description must be a routing rule, not a summary.** Anthropic's anti-pattern callout: don't write *"This skill helps with X."* Write *"Use when the user asks for X, or when working with Y file types."* Include keywords users naturally say. First sentence: what. Second sentence: when.

### High-value optional fields

| Field | Use when | Effect |
|---|---|---|
| `allowed-tools:` | Skill needs specific tools that would otherwise prompt | Pre-approves listed tools (e.g. `[Read, Edit, Bash]`); kills friction |
| `disable-model-invocation: true` | Skill has side effects (deploy, commit, send-message, post-to-Slack) | Prevents Claude from auto-invoking — user must explicitly call |
| `context: fork` | Skill should run in isolation (research, exploration, anything that pollutes history) | Executes in a subagent so the main conversation stays clean |
| `version: x.y.z` | Skill is versioned and you want history visible | Surfaces version in skill listings |
| `license: MIT` | Open-source skill | Surfaces license in the listing |

`allowed-tools` is what most local skills miss. Adding it eliminates per-tool permission prompts that otherwise fire repeatedly.

## SKILL.md size budget

Anthropic's public guidance: **≤500 lines** in SKILL.md. Move reference material to separate files when over budget.

Our local convention is stricter: **≤100 lines**. The stricter target is intentional discipline — most skills don't need 500 lines, and shorter SKILL.md loads faster on invoke. When over the local budget, split into `references/` files.

Either way, the test is per-line: *would removing this line change Claude's behavior?* If no, cut it. If yes, keep it.

## Skill folder structure

```
skill-name/
├── SKILL.md            # entry point (required, exactly this filename, case-sensitive)
├── references/         # demand-loaded detailed docs
│   ├── api.md
│   └── examples.md
├── assets/             # templates, fixtures, schemas
│   └── template.md
├── scripts/            # deterministic helpers Claude can invoke
│   └── helper.py
└── config.json         # persistent skill state (optional)
```

Hard rules:
- Folder name is kebab-case (`brand-voice` ✓ — `Brand_Voice` ✗)
- `SKILL.md` filename is exact and case-sensitive
- **No `README.md` inside skill folders** — confuses Claude's loader
- No `claude` or `anthropic` in skill names (reserved)
- No XML tags in frontmatter (security)
- Reference at most one level deep — don't nest `references/sub/file.md`

## Dynamic context injection

Anthropic's `summarize-changes` reference skill demonstrates the pattern:

```yaml
---
description: Summarizes uncommitted changes and flags anything risky.
  Use when the user asks what changed, wants a commit message, or asks to review their diff.
---

Run this command to see the current diff: !`git diff HEAD`

[then your instructions reference the inlined diff]
```

The `` !`command` `` syntax executes the shell command at skill-invoke time and inlines the output. Result: the SKILL.md body stays small, but Claude sees fresh runtime state. Use this for any skill that wraps git, file lists, process state, env vars, or other runtime queryable data. Keeps the always-on cost low and the on-invoke context fresh.

## Mandatory section: Gotchas

Anthropic's practitioner guidance: *"the Gotchas section is the highest-signal content in any skill — built from real failures, updated over time. The diff between 60% reliability and 95% reliability."*

Build it after the skill has actually hit edge cases. Don't try to anticipate. Each entry: one-line failure mode + one-line workaround. Update on every recurring miss.

Example:
```markdown
## Gotchas

- **Symlinked vault paths** — vault may be on an external drive. If `os.path.realpath` returns `/Volumes/...`, the path is fine, but `git -C` will fail because the symlinked dir isn't tracked. Use the resolved path for fs ops, the symlinked path for everything else.
- **Curly vs straight quotes from ChatGPT-source text** — incoming text from ChatGPT often has `"smart"` quotes that break grep and downstream string matching. Run a normalization pass first.
```

If a skill is in production and has no Gotchas section, it's incomplete. The first time it surprises you, write it down.

## Helper scripts: when to bundle code

Bundle a script (`scripts/helper.py` or `.sh`) when:
- The operation is **deterministic** — sorting, summing, validation, format conversion
- The same code would otherwise be regenerated by Claude every time
- Errors need explicit handling that prompt-following can't reliably do
- The task involves walking the filesystem in a structured way

"Code execution is far more expensive than simply running a sorting algorithm" (Anthropic engineering). Use code for logistics, prompt for composition.

## Testing framework (3 stages)

Anthropic's official testing recommendation:

1. **Triggering tests** — does the skill fire when it should? Does it *not* fire when it shouldn't? (The harder direction.) Test with prompts both inside and outside the trigger condition.
2. **Functional tests** — given a known input, does the skill produce the expected output? Edge cases handled? Errors surfaced cleanly?
3. **Performance comparison** — same task, with the skill vs. without. Measure: token count, tool calls, back-and-forth turns. If the with-skill version doesn't beat without, the skill isn't earning its slot.

For a skill that fails any of these, fix or delete. The cost of a dead-but-installed skill is the always-loaded frontmatter slot it consumes.

## The 9 skill types (Anthropic internal taxonomy)

| Type | What it does |
|---|---|
| Library / API Reference | Internal tools, CLIs, SDKs — especially edge cases and gotchas |
| Product Verification | Drives a product end-to-end, asserts state at each step |
| Data Fetching & Analysis | Connects to monitoring/data with credentials, dashboards, common queries |
| Business Process Automation | One-command workflow with results logged to files |
| Code Scaffolding | Framework boilerplate for codebase-specific patterns |
| Code Quality / Review | Enforces standards; spawns adversarial reviewers |
| CI/CD & Deployment | Fetch, push, deploy, monitor, rollback, babysit flaky CI |
| Runbooks | Symptom → investigation → structured report |
| Infrastructure Operations | Routine maintenance with guardrails for destructive actions |

Skills that don't fit a type are usually trying to do too much. Split.

## The 5 canonical workflow patterns

| Pattern | Shape |
|---|---|
| Sequential Workflow Orchestration | Multi-step process in fixed order; validation at each stage; rollback on failure |
| Multi-MCP Coordination | Workflow spanning multiple services; phase separation; centralized errors |
| Iterative Refinement | Output quality improves with loops; quality criteria; "know when to stop" |
| Context-Aware Tool Selection | Same outcome, different tools depending on context; decision trees; fallback options |
| Domain-Specific Intelligence | Specialized knowledge beyond tool access; compliance-before-action |

If a skill's behavior doesn't map to one of these, the design is probably unclear.

## The meta-process: "iterate, then extract"

Anthropic's recommended skill-creation flow: *"Iterate on a single challenging task until Claude succeeds, then extract the winning approach into a skill."*

Translation: don't write a skill in advance. Solve the problem in conversation. When you find the prompt + context shape that works, freeze it as a skill. The skills that work best are the ones that capture a real successful run, not anticipated future needs.

## Anti-patterns Anthropic explicitly calls out

- **Overly rigid instructions** — locking Claude into strict rules instead of giving it judgment-enabling context
- **Blurred categories** — combining disparate domains in one SKILL.md ("deployment + database + monitoring")
- **Description as narrative** — *"This skill does A, B, and C"* fails the routing test
- **All content inline** — stuffing reference docs into SKILL.md inflates every invocation
- **No Gotchas section** — a production skill without one is leaving the 60→95% reliability win on the table
- **Anticipatory authoring** — writing skills for hypothetical future needs rather than extracting from successful runs
- **Skill names with `claude` or `anthropic`** — reserved
- **README.md in skill folders** — confuses the loader; use SKILL.md only

## Reference skills worth reading

The 17 skills in [github.com/anthropics/skills](https://github.com/anthropics/skills) are the canonical examples. Worth surveying before authoring a new skill, especially if it falls into one of the 9 types above. Most of them are <300 lines, well under the 500-line bar.

---

*Last updated 2026-05-06 from the Anthropic official docs and the April 2026 vault research note. When Anthropic ships updated guidance, update this file rather than scattering edits across multiple SKILL.md files.*
