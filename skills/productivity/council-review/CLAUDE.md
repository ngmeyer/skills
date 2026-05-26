# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Council Review is a Claude Code skill that runs decisions, code, plans, and PRs through a council of 5 AI advisors with anonymous peer review and chairman synthesis. Based on Karpathy's LLM Council, adapted by Ole Lehmann, with reasoning method diversity from DMAD (ICLR 2025).

**Repo:** github.com/ngmeyer/council-review
**Author:** Neal Meyer

## File Structure

```
council-review/
├── SKILL.md                    # The executable skill — this IS the product
├── README.md                   # GitHub-facing documentation with install instructions
├── LICENSE                     # MIT
├── CLAUDE.md                   # This file
└── docs/
    └── ideation/               # Ideation artifacts from ce-ideate sessions
```

## Architecture

This is a **prompt-only skill** — no runtime code, no dependencies, no build step. The entire product is `SKILL.md`, a markdown file that Claude Code loads and executes at invocation time.

### Execution Flow (11 agent calls in full mode)

```
Step 0: Pre-flight    — parse flags, scope validation, input classification
Step 1: Context+Frame — auto-read project files, frame neutral question
Step 2: 5 Advisors    — parallel agents with distinct reasoning methods (haiku)
Step 3: 5 Reviewers   — anonymous peer review, randomized A-E mapping (haiku)
Step 4: Chairman      — synthesis with disagreement classification (best model)
Step 5: Present       — verdict + transcript
```

### The 5 Advisors and Their Reasoning Methods

| Advisor | Method | Why This Method |
|---------|--------|----------------|
| Contrarian | Inversion | Traces backward from failure — catches "sounds great but..." |
| First Principles | Decomposition | Breaks into atomic claims — catches wrong abstractions |
| Expansionist | Analogy | Cross-domain pattern matching — catches small thinking |
| Outsider | Naive questioning | Fresh eyes — catches curse of knowledge |
| Executor | Dependency graphing | Maps critical path — catches missing first steps |

Method diversity is critical. DMAD (ICLR 2025) showed same-model councils converge without it.

### Modes

| Mode | Flag | Calls | Advisors |
|------|------|-------|----------|
| Full | (none) | 11 | All 5 + peer review + chairman |
| Quick | `--quick` | 4 | Contrarian + Executor + Outsider + chairman |
| Adversarial | `--adversarial` | 11 | 2 advocates + 2 skeptics + 1 neutral + review + chairman |

## Key Design Decisions

- **Anonymization is non-negotiable.** Research confirms reviewers defer to role names. Always shuffle to A-E before peer review.
- **Chairman can override majority.** Quality of reasoning > vote count.
- **Disagreement classification matters.** "Value tension" (both valid) vs "error catch" (real flaw found) changes what the user does with the verdict.
- **"What You Lose" section.** Dissent preservation — explicitly name the cost of ignoring the minority view.
- **Same-model limitation.** Acknowledged in gotchas. This uses persona/method diversity, not model diversity like Karpathy's original.

## Editing Guidelines

- **SKILL.md is the product.** Changes to SKILL.md change the skill behavior for all users.
- **README.md is marketing.** Keep install instructions, output format examples, and feature table in sync with SKILL.md.
- **Prompt changes are code changes.** Treat advisor prompts, chairman output format, and peer review questions with the same rigor as code — test before shipping.
- **Don't add runtime dependencies.** The skill must remain a single markdown file that any Claude Code user can copy.
- **Keep advisor prompts under 100 words each.** Longer prompts don't improve output and waste tokens across 5 parallel calls.

## Testing

There is no automated test suite — this is a prompt file. To test changes:

1. Install locally: `cp SKILL.md ~/.claude/skills/council-review/SKILL.md`
2. Run against a known decision: `/council-review Should we use a monorepo or polyrepo?`
3. Verify: all 5 advisors respond, peer review is anonymized, chairman produces all sections
4. Test `--quick` mode: `/council-review --quick Is this worth refactoring?`
5. Test `--adversarial` mode: `/council-review --adversarial Should we adopt GraphQL?`
6. Test scope validation: `/council-review What is 2+2?` (should reject as trivial)

## Commit Style

Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`

## Research References

- `.ai/WebSocketProtocol.md` — N/A (this project has no protocol)
- `docs/ideation/` — Ideation artifacts from improvement sessions
- DMAD paper: https://openreview.net/forum?id=t6QHYUOQL7
- Karpathy's LLM Council: https://github.com/karpathy/llm-council
- "Can LLMs Really Debate?" (ICLR 2025): https://arxiv.org/abs/2511.07784
- agent-council (competing): https://github.com/yogirk/agent-council
