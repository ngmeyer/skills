# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

Adversarial Review is a Claude Code skill that stress-tests a known artifact (PR, draft, spec, code, plan, argument) by actively trying to break it. Single-critic, attack-focused, deliberately not balanced. Distinct from `/council-review` (multi-agent collaborative deliberation on open questions).

**Repo:** github.com/ngmeyer/adversarial-review
**Author:** Neal Meyer

## File Structure

```
adversarial-review/
├── SKILL.md      # The executable skill — this IS the product
├── README.md     # GitHub-facing documentation
├── LICENSE       # MIT
├── CLAUDE.md     # This file
└── tests/
    ├── eval.sh         # Structural eval (asserts SKILL.md design contract)
    ├── README.md       # What's tested vs deferred
    └── fixtures/       # Sample artifacts for future runtime tests
```

## Architecture

This is a **prompt-only skill** — no runtime code, no dependencies. The entire product is `SKILL.md`.

### 6-Phase Execution

```
Phase 1: SCOPE    — validate input is a known artifact (not an open question)
Phase 2: READ     — load artifact + project context
Phase 3: ATTACK   — run 5 attack vectors (security, logic, user, scale, universal)
Phase 4: TRIAGE   — categorize CRITICAL / IMPORTANT / NIT, rank by likelihood × blast radius
Phase 5: PRESENT  — findings + "what I could not break" + "what I did not cover"
Phase 6: SAVE     — offer to save report alongside the artifact
```

### Key Design Decisions

- **Single-critic, not multi-agent.** Council-review handles multi-agent. This is one sharp critic doing focused attack work.
- **Reject open questions.** If the input is "Should we use X?" without a proposed answer, redirect to `/council-review`. Different tool, different job.
- **Attack vectors are composable.** Default runs all five; flags narrow the focus.
- **No fluff findings.** If a dimension produced nothing, the report says so. Five fluffy findings are worse than two real ones.
- **No speculation without example.** Every finding must have a concrete trigger or reproduction sketch.
- **"What I Could Not Break" is mandatory.** Without it, the user can't distinguish "this section is solid" from "I didn't look here."
- **"What This Did NOT Cover" is mandatory.** Honest about dimensions that need runtime testing, user research, or knowledge the artifact doesn't include.
- **Triage is severity × likelihood, not just severity.** A theoretical CRITICAL that needs five rare conditions to fire ranks below an IMPORTANT that fires under normal load.

### Distinction from sibling skills

| Skill | When |
|---|---|
| `/adversarial-review` | Stress-test a finished artifact |
| `/council-review` | Open question, multiple valid answers |
| `/ce:review` (compound-engineering) | Tiered persona PR review with merge/dedup pipeline |
| `/security-review` (Anthropic) | Official security audit |

Adversarial-review's niche: deeper than ce:review (focused attack mode), broader than security-review (5 attack vectors not just security), more focused than council-review (single-critic stress test).

### Portability Requirements

- **No hardcoded user paths.** All paths are derived from cwd, args, or `$HOME`.
- **Cross-platform.** Works on macOS, Linux, Windows under Claude Code. No `date -v` or `date -d`; use `python3` for any date math.
- **Graceful skip.** Missing PR access tools, missing project context files — skip and note, don't error.

## Editing Guidelines

- **SKILL.md is the product.** Changes to SKILL.md change behavior for all users.
- **Prompt changes are code changes.** The five attack-vector prompts, the triage tiers, and the mandatory output sections are load-bearing — test before shipping.
- **Don't add runtime dependencies.** Must remain a single markdown file.
- **Keep attack-vector prompts under 150 words each.** Longer prompts don't improve output and blow the token budget across parallel sub-agents.
- **Mandatory sections stay mandatory.** "What I Could Not Break" and "What This Did NOT Cover" are not optional polish — they're calibration mechanisms.

## Testing

Run the structural eval:

```bash
bash tests/eval.sh
```

Exit 0 = design contract intact. Exit 1 = regression.

To verify behavior end-to-end:

1. `cd` into a project with a recent PR or draft spec
2. Run `/adversarial-review docs/spec.md` (or any artifact path)
3. Check that:
   - Findings are categorized into CRITICAL / IMPORTANT / NIT
   - Each CRITICAL has a specific trigger and reproduction sketch
   - "What I Could Not Break" section is present and substantive
   - "What This Review Did NOT Cover" section is honest about gaps
4. Run with `/adversarial-review docs/spec.md --security` and verify only security findings appear
5. Run on an open question and verify redirect to /council-review

## Commit Style

Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`
