---
name: skillforge
description: Forge new Claude Code skills or optimize existing ones to V2. Two modes — `forge` scaffolds a new skill (frontmatter, progressive disclosure, helper scripts, mandatory Gotchas, iterate-then-extract); `optimize` makes an existing skill measurably better at its OUTCOME, not just its packaging (quality audit + domain outcome-research + changelog + V1-vs-V2 verification). Use when the user wants to create, write, build, scaffold, improve, upgrade, or optimize a skill.
license: MIT
---

# Skillforge — write and optimize Claude Code skills the right way

For full Anthropic-authoritative guidance (frontmatter fields, 500-line budget, dynamic context injection, testing framework, anti-patterns, the 9 skill types, the 5 workflow patterns), load: [references/anthropic-skill-best-practices.md](references/anthropic-skill-best-practices.md).

## Two modes

| Mode | Use for | Output |
|---|---|---|
| **forge** (default) | A new skill that doesn't exist yet | A new skill dir, drafted per the process below |
| **optimize** | An existing skill that works but should be better | A **V2** of that skill — measurably better at its *outcome* |

**`forge`** follows the process + checklist in the rest of this file.

**`optimize <skill>`** runs a metric-driven loop: define the outcome + metric → **set gates (incl. a no-cheating audit)** → quality audit → research the domain for outcome-improving techniques → synthesize V2 with a changelog → verify V2 beats V1 **on a held-out benchmark, not a single example**, discarding any candidate that fails a gate. "Optimize," not "tidy": a cleanup that doesn't move the outcome is not a V2, and a score that jumped by gaming the rubric is a regression. The loop is self-contained; for a heavy run (many hypotheses, parallel experiments, hours) you can *optionally* escalate to an external optimizer if you have one (`ce-optimize` plugin, `evo`, or Microsoft's `SkillOpt`). Full playbook: [references/optimize-mode.md](references/optimize-mode.md).

## Meta-process: iterate first, extract second

Anthropic's recommended creation flow: *iterate on a single challenging task until Claude succeeds, then extract the winning approach into a skill.* Don't write skills for hypothetical future needs. Solve the real problem in conversation, find the prompt + context shape that works, freeze it.

## Process

1. **Gather requirements** - ask user about:
   - What task/domain does the skill cover?
   - What specific use cases should it handle? (Surface a real recent example.)
   - Does it need executable scripts or just instructions?
   - Any reference materials to include?
   - Any side effects (deploy, commit, send-message)? → set `disable-model-invocation: true`
   - Tools that would otherwise prompt? → list in `allowed-tools:`

2. **Draft the skill** - create:
   - SKILL.md with concise instructions (target ≤100 lines locally; Anthropic's public bar is 500)
   - `references/` files for detail that doesn't need to load on every invoke
   - `scripts/` for deterministic helpers (sorting, validation, format conversion)

3. **Review with user** - present draft and ask:
   - Does this cover your use cases?
   - Anything missing or unclear?
   - Should any section be more/less detailed?

## Skill Structure

```
skill-name/
├── SKILL.md           # Main instructions (required)
├── REFERENCE.md       # Detailed docs (if needed)
├── EXAMPLES.md        # Usage examples (if needed)
└── scripts/           # Utility scripts (if needed)
    └── helper.js
```

## SKILL.md Template

```md
---
name: skill-name
description: Brief description of capability. Use when [specific triggers].
---

# Skill Name

## Quick start

[Minimal working example]

## Workflows

[Step-by-step processes with checklists for complex tasks]

## Advanced features

[Link to separate files: See [REFERENCE.md](REFERENCE.md)]
```

## Description Requirements

The description is **the only thing your agent sees** when deciding which skill to load. It's surfaced in the system prompt alongside all other installed skills. Your agent reads these descriptions and picks the relevant skill based on the user's request.

**Goal**: Give your agent just enough info to know:

1. What capability this skill provides
2. When/why to trigger it (specific keywords, contexts, file types)

**Format**:

- Max 1,536 chars (combined `description` + `when_to_use`)
- Write in third person
- First sentence: what it does
- Second sentence: "Use when [specific triggers]"
- **Anti-pattern:** narrative summary ("This skill does A, B, and C") fails the routing test. Write decision rules.

**Good example**:

```
Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when user mentions PDFs, forms, or document extraction.
```

**Bad example**:

```
Helps with documents.
```

The bad example gives your agent no way to distinguish this from other document skills.

## When to Add Scripts

Add utility scripts when:

- Operation is deterministic (validation, formatting)
- Same code would be generated repeatedly
- Errors need explicit handling

Scripts save tokens and improve reliability vs generated code.

## When to Split Files

Split into separate files when:

- SKILL.md exceeds 100 lines
- Content has distinct domains (finance vs sales schemas)
- Advanced features are rarely needed

## Gotchas section (mandatory for production skills)

Anthropic: *"the highest-signal content in any skill — the diff between 60% reliability and 95% reliability."* Build it from real failures, not anticipation. One-line failure mode + one-line workaround. Update on every recurring miss. A production skill without a Gotchas section is leaving the reliability win on the table.

## Testing the skill

Three stages, per Anthropic:

1. **Triggering** — does it fire when it should? Does it *not* fire when it shouldn't? (Test prompts both inside and outside the trigger condition.)
2. **Functional** — given a known input, does it produce the expected output? Edge cases handled?
3. **Performance** — same task with vs. without the skill. If with-skill doesn't beat without, the skill isn't earning its slot.

## Review Checklist

After drafting, verify:

- [ ] Description includes triggers ("Use when...") and is ≤1,536 chars
- [ ] SKILL.md under 100 lines (local target; Anthropic's public bar is 500)
- [ ] Frontmatter declares `allowed-tools` if the skill needs specific ones
- [ ] `disable-model-invocation: true` set if the skill has side effects
- [ ] Gotchas section present (or marked as TODO with first failure)
- [ ] No time-sensitive info
- [ ] Consistent terminology
- [ ] Concrete examples included
- [ ] References one level deep
- [ ] No `claude` or `anthropic` in skill name; no `README.md` in folder

## Changelog

### V2.2 (2026-05-29) — added SkillOpt + train/val split
- Added **Microsoft SkillOpt** ([MIT, arxiv 2605.23904](https://arxiv.org/abs/2605.23904)) as a third optional external escalation alongside `ce-optimize` and `evo`. SkillOpt trains markdown skills NN-style (epochs / mini-batches / validation gates) against standardized benchmarks (SearchQA, ALFWorld, DocVQA, SpreadsheetBench, OfficeQA). Best fit for benchmark-driven rigor; ce-optimize for in-session workflow; evo for parallel/tree-search architecture.
- **Sharpened the verify step (#6) with a train/validation split** — divide the held-out benchmark into a tuning subset (which iterating may overfit to) and a validation subset (never seen by the change process). If validation regresses while tuning improves, the change overfit; drop it. Borrowed from SkillOpt's discipline.
- Reframed the hand-run loop honestly: "one epoch, batch of one" — small, fast, useful for one-skill V2s; escalate when you want real training.

### V2.1 (2026-05-28) — merged ce-optimize discipline
Evolved `optimize` mode by merging the metric-driven rigor of **`ce-optimize`** (CE plugin) and **`evo`** ([alokbishoyi97](https://x.com/alokbishoyi97/status/2059610305408462898), evo-hq.com):
- Added a **gates** step (degenerate gates + **no-cheating audit** + held-out check) — discard any candidate that fails a gate even if it scored best. Closes the "gamed metric" hole the prior loop had.
- Verify now uses a **held-out benchmark (~10–20 tasks), not a one-off** — fixes the N=1 weakness in the council-review A/B.
- Added **optional external escalation**: for heavy runs (many hypotheses / parallel experiments / hours), optionally hand off to an external optimizer (`ce-optimize` plugin or `evo`, evo-hq.com) if installed; skillforge stays self-contained and keeps the unique outcome-research + skill-quality-audit front end.

### V2 (2026-05-27)
- Added **`optimize` mode** (forge new vs optimize existing-to-V2). Optimize runs a metric-driven loop — define outcome + metric, quality audit, domain outcome-research, synthesize V2 + changelog, verify V2 beats V1 — so a "V2" must measurably improve the *outcome*, not just the packaging. Playbook: `references/optimize-mode.md`.
- Dogfooded across 7 skills (council-review pilot + a 6-skill batch), which is what promoted skillforge out of `in-progress/`.
