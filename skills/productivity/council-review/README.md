# Council Review

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-Skill-blueviolet?logo=anthropic)](https://claude.ai/code)
[![GitHub Stars](https://img.shields.io/github/stars/ngmeyer/council-review?style=social)](https://github.com/ngmeyer/council-review)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey)]()

A Claude Code skill that runs decisions, code, plans, and PRs through a **Diverse Multi-Agent Debate (DMAD)** council of 5 advisors with distinct reasoning methods. Advisors collaborate, peer-review each other anonymously, and a chairman synthesizes a verdict.

This is the collaborative-DMAD pattern — empirically validated to outperform adversarial multi-agent debate ([M3MADBench 2026](https://arxiv.org/pdf/2601.02854); [DMAD ICLR 2025](https://openreview.net/forum?id=t6QHYUOQL7)). For single-critic adversarial stress-testing of a known artifact, use `/adversarial-review` instead.

Based on [Andrej Karpathy's LLM Council](https://github.com/karpathy/llm-council) and [Ole Lehmann's](https://x.com/itsolelehmann) Claude Code adaptation.

## How It Works

```
You -> Question/Code/Plan
         |
   5 Advisors (parallel, independent, distinct reasoning methods)
         |
   5 Peer Reviews (anonymous, cross-review)
         |
   Chairman Synthesis (verdict + dissent preservation + verification)
         |
   Report + Recommendation + "What You Lose"
```

**The 5 Advisors:**

| Advisor | Angle | Reasoning Method |
|---------|-------|-----------------|
| The Contrarian | What will fail? | **Inversion** -- assume it failed, trace backward |
| First Principles | What are we actually solving? | **Decomposition** -- break into atomic claims, challenge each |
| The Expansionist | What upside are we missing? | **Analogy** -- what adjacent domain solved this differently? |
| The Outsider | Zero context, fresh eyes | **Naive questioning** -- flag anything requiring insider knowledge |
| The Executor | What do you do Monday morning? | **Dependency graphing** -- what blocks what? |

Each advisor uses a different *reasoning method*, not just a different angle. This is the key insight from [DMAD research](https://openreview.net/forum?id=t6QHYUOQL7): same-model councils need method diversity to avoid converging on the same reasoning patterns.

## Install

Clone the repo and copy the skill into your Claude Code skills directory:

```bash
# Clone
git clone https://github.com/ngmeyer/council-review.git
cd council-review

# Global install (available in all projects)
mkdir -p ~/.claude/skills/council-review
cp SKILL.md ~/.claude/skills/council-review/SKILL.md

# Or per-project install
mkdir -p .claude/skills/council-review
cp SKILL.md .claude/skills/council-review/SKILL.md
```

Then use it in Claude Code:

```
/council-review Should we rewrite our auth layer in Rust?
/council-review docs/plans/v2-migration.md
/council-review https://github.com/org/repo/pull/42
/council-review --quick Is this naming convention worth changing?
/council-review --adversarial Should we adopt microservices?
```

## Modes

| Mode | Flag | Calls | Best For |
|------|------|-------|----------|
| **Full** (default) | none | 11 | High-stakes decisions |
| **Quick** | `--quick` | 4 | Routine decisions, gut-checks |
| **Adaptive** | `--adaptive` | 6–26 | Multi-round debate with KS-statistic early stopping (up to 94.5% cost cut on convergent questions) |
| **Confidence** | `--confidence` | 11 | Confidence-weighted synthesis. Each advisor self-rates and rates peers; chairman weights by calibrated confidence rather than majority vote |
| **Measure diversity** | `--measure-diversity` | 11 | Score reasoning-footprint overlap; flag theatrical consensus when advisors converge despite different methods |
| **Adversarial** *(deprecated)* | `--adversarial` | 11 | Retained for backward compatibility; prefer `/adversarial-review` for new use cases |

**Quick mode** runs 3 advisors (Contrarian, Executor, Outsider) + chairman. No peer review. Fast.

**Adaptive mode** measures response distribution convergence between rounds via Kolmogorov-Smirnov statistic; halts when shift drops below epsilon for two consecutive rounds. Best for open questions where the council may converge quickly.

**Confidence mode** has each advisor end with `CONFIDENCE: 1-10` and a one-line rationale; peers also rate confidence; the chairman synthesis is weighted by calibrated certainty. Surfaces low-confidence consensus as a yellow flag.

**Measure-diversity mode** scores reasoning-footprint overlap across responses. High overlap (>60%) is flagged as theatrical consensus — the chairman treats it as a single advisor's opinion.

Flags compose: `/council-review --adaptive --confidence "Should we adopt GraphQL?"` runs convergence-stopped, confidence-weighted deliberation.

## What It Reviews

| Input | What Happens |
|-------|-------------|
| **A question or decision** | 5 advisors independently analyze tradeoffs, peer-review each other, synthesize a recommendation |
| **An implementation plan** | Advisors stress-test feasibility, scope, risks, missing pieces, and execution order |
| **A PR or code change** | Advisors review from security, architecture, performance, usability, and pragmatism angles |
| **A file path** | Reads the file and councils its contents |

## Why This Works

1. **Method diversity** -- Each advisor uses a distinct reasoning method (inversion, decomposition, analogy, naive questioning, dependency graphing). Same-model councils converge without this.
2. **Parallel independence** -- Advisors don't see each other's responses. No groupthink.
3. **Anonymous peer review** -- Responses are shuffled as A-E before review. No deference to roles.
4. **Forced tension** -- The Contrarian *must* find flaws. The Expansionist *must* find upside. Coverage is structural.
5. **Disagreement classification** -- Chairman distinguishes "value tensions" (both sides valid) from "error catches" (one advisor found a real flaw).
6. **Dissent preservation** -- "What You Lose" section explicitly names the cost of ignoring the minority view.
7. **Chairman override** -- The synthesizer can side with a minority if their reasoning is strongest.
8. **"What did ALL five miss?"** -- The most valuable question in the peer review.

## Output Format

```
## Council Verdict: [Topic]

### Where the Council Agrees
[High-confidence signals -- multiple advisors converged independently]

### Where the Council Clashes
[Value Tension] Both sides valid, depends on priorities...
[Error Catch] One advisor found a real flaw others missed...

### Blind Spots Revealed
[Things only the peer review caught]

### Recommendation
[Clear, actionable. Not "it depends." A real answer.]

### What You Lose
[Cost of following this recommendation. The strongest dissent, preserved.]

### Do This First
[One concrete next step.]
How to verify: [2-3 checks to confirm the recommendation was right]
```

## Auto-Context

The skill automatically reads project files before framing the question:
- `README.md`, `CLAUDE.md` / `AGENTS.md`
- Recent git log
- PR diff (if reviewing a PR)
- Referenced files

No manual context-pasting needed. Advisors see your project, not a blank slate.

## Credits

- Original concept: **Andrej Karpathy** ([LLM Council](https://github.com/karpathy/llm-council))
- Claude Code adaptation: **Ole Lehmann** ([@itsolelehmann](https://x.com/itsolelehmann))
- Reasoning method diversity: **DMAD** ([ICLR 2025](https://openreview.net/forum?id=t6QHYUOQL7))
- Collaborative > adversarial empirical evidence: **M3MADBench** ([arXiv 2601.02854](https://arxiv.org/pdf/2601.02854), 2026)
- Confidence-modulated debate protocol: **Demystifying MAD** ([arXiv 2601.19921](https://arxiv.org/pdf/2601.19921), 2026)
- KS-statistic adaptive stopping: **rachittshah/llmcouncil** (S2 MAD)
- Diversity-footprint verification: **Counsel** ([Same model, same blind spots](https://counsel.getmason.io/research/model-bindings))
- Skill by: **Neal Meyer**

## License

MIT
