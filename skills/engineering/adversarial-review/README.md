# Adversarial Review

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-Skill-blueviolet?logo=anthropic)](https://claude.ai/code)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey)]()

A Claude Code skill that stress-tests a known artifact — a PR, draft, spec, plan, code file, or argument — by actively trying to break it. Single-critic, attack-focused, deliberately not balanced.

## The Problem

Most uses of AI confirm what you already think. The strongest practitioners use it to *disconfirm*. But generic "review this" prompts produce polite, balanced, mostly-positive feedback that misses real flaws.

## The Solution

`/adversarial-review` is the inverse role. The reviewer's job is to find what's wrong, not what's right. It runs five attack vectors:

```
Artifact (PR, draft, spec, code, plan)
        |
   SCOPE  -> validate this is a finished thing, not an open question
        |
   READ   -> full artifact + project context
        |
   ATTACK -> security / logic / user / scale / universal probe
        |
   TRIAGE -> CRITICAL / IMPORTANT / NIT, ranked
        |
   PRESENT -> findings + "what I could not break" + "what I did not cover"
```

## Install

```bash
git clone https://github.com/ngmeyer/adversarial-review.git
cd adversarial-review

# Global install (available in all projects)
mkdir -p ~/.claude/skills/adversarial-review
cp SKILL.md ~/.claude/skills/adversarial-review/SKILL.md

# Or per-project install
mkdir -p .claude/skills/adversarial-review
cp SKILL.md .claude/skills/adversarial-review/SKILL.md
```

Use it in Claude Code:

```
/adversarial-review docs/spec.md
/adversarial-review 123                                # PR number
/adversarial-review https://github.com/org/repo/pull/123
/adversarial-review src/auth.ts --security
/adversarial-review docs/architecture.md --scale
/adversarial-review docs/proposal.md --quick
```

Trigger phrases: *adversarial review*, *red team this*, *find what is wrong*, *tell me why this is wrong*, *pre-mortem this*, *attack this*, *stress test*, *devil's advocate*, *try to break this*.

## When to Use This vs /council-review

| Tool | Use For | Mode |
|---|---|---|
| **`/adversarial-review`** | Stress-testing a *known artifact* | Single-critic, attack-focused |
| **`/council-review`** | Open questions, decisions, "what should we do?" | Multi-agent, collaborative (DMAD) |

If the input is a question without a proposed answer, the skill redirects you to `/council-review`. If the input is a finished thing you want probed for flaws, this is the right tool.

## Attack Vectors

| Flag | Focus |
|---|---|
| (none) | All five vectors run in parallel |
| `--security` | Auth gaps, input validation, secrets, external trust, data exposure |
| `--logic` | Missing cases, unstated assumptions, internal contradictions, race conditions, counter-examples |
| `--user` | Footguns, surprising defaults, confirmation traps, accessibility, error recovery |
| `--scale` | Algorithmic cliffs, memory growth, DB hot spots, concurrency, external dependency limits |
| `--quick` | Single attack pass, severity-ranked, no deep dives — cheap drive-by |

Flags compose: `/adversarial-review src/api.ts --security --scale` runs both attack dimensions.

## Output Format

```
## Adversarial Review: [Artifact Name]

**Attack vectors run:** security, logic, user, scale, universal probe
**Findings:** 2 CRITICAL / 5 IMPORTANT / 3 NIT

### CRITICAL (2)

#### [1] [One-line title — what breaks]
**Location:** file:line
**Trigger:** the specific input/condition
**What breaks:** the failure mode in one sentence
**Fix sketch:** one sentence

### IMPORTANT (5)
[same structure]

### NIT (3)
[one-line bullets]

### What I Could Not Break
[2-3 sentences naming the strongest parts — calibration, not flattery]

### What This Review Did NOT Cover
[Dimensions skipped, usually because runtime testing or user research is required]
```

## What It Won't Do

- Be balanced. The artifact's defenders already exist.
- Pad with fluff findings. If a dimension produced nothing, the report says so.
- Speculate without examples. "An attacker could imagine..." is noise; "Send X, observe Y" is signal.
- Redirect finished artifacts to `/council-review`. That's the inverse mistake.
- Propose entire rewrites in fix sketches. One sentence each, or "needs deeper redesign."
- Omit *What I Could Not Break*. Calibration matters.

## Why This Works (Research Backing)

- M3MADBench (2026) shows multi-agent *adversarial* debate underperforms collaborative debate on open questions — but single-critic adversarial probing of a *known artifact* is a different operation, and the right tool for that job.
- The Codex Review Plugin popularized `/codex:adversarial-review` as a daily-driver mode for catching issues that pass three rounds of human review.
- Pre-mortem methodology (assume failure, trace backward) consistently surfaces issues that prospective review misses.

## Sibling Skills

| Skill | When to use |
|---|---|
| `/adversarial-review` | Single-critic stress test of a known artifact |
| `/council-review` | Multi-agent collaborative deliberation on open questions |
| `/ce:review` (compound-engineering) | Tiered persona PR review with confidence-gated findings |
| `/security-review` (built-in) | Anthropic's official security review slash command |

## Credits

- Adversarial role inspiration: Codex Review Plugin (`/codex:adversarial-review`)
- Attack-vector taxonomy: pre-mortem methodology + OWASP categories
- Empirical positioning: M3MADBench (2026) on adversarial vs collaborative debate
- Skill by: **Neal Meyer**

## License

MIT
