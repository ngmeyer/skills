# skillforge

A Claude Code skill that forges new skills the right way.

Most "write a skill" guides drop you into the YAML frontmatter and stop there. Skillforge captures Anthropic's full authoring discipline — three-tier progressive disclosure, the description-as-routing-rule, mandatory Gotchas, the 3-stage testing framework, and the meta-process Anthropic actually recommends: *iterate on a real task until it works, then extract the winning approach into a skill.*

It's small (~140 lines in `SKILL.md`) and demand-loads the deeper reference (`references/anthropic-skill-best-practices.md`, ~180 lines) only when authoring or auditing.

## Install

```bash
git clone https://github.com/ngmeyer/skillforge.git ~/.claude/skills/skillforge
```

Then in any Claude Code session: invoke with `/skillforge` or just say *"write a skill that does X"* / *"build a skill for Y"*.

## What's inside

```
skillforge/
├── SKILL.md                                    # entry point, ~140 lines
├── README.md
├── LICENSE
└── references/
    └── anthropic-skill-best-practices.md       # full Anthropic guidance, ~180 lines
```

## What it does

When you ask Claude to create or improve a skill, skillforge walks you through:

1. **The meta-process first.** *Iterate on a real challenging task until Claude succeeds — then extract the winning approach.* Skills built ahead of need are usually wrong; skills extracted from real successful runs are usually right.
2. **Frontmatter that routes correctly.** `description` as decision rule, not narrative summary. `allowed-tools` to kill permission prompts. `disable-model-invocation: true` for side-effect skills. `context: fork` for isolated execution.
3. **Three-tier progressive disclosure.** What stays in `SKILL.md` (always loads on invoke), what goes in `references/` (demand-loaded), what goes in `scripts/` (deterministic helpers).
4. **The Gotchas section.** Anthropic's practitioner guidance is explicit: *"the highest-signal content in any skill — the diff between 60% reliability and 95% reliability."* Built from real failures, not anticipation.
5. **Three-stage testing.** Triggering tests (does it fire when it should — and *not* fire when it shouldn't?), functional tests, performance comparison (with vs. without).

## Why this exists

Most skills in the wild fail one of two ways: they're either too thin (frontmatter + a paragraph, no Gotchas, never tested) or too fat (the entire reference inlined, eating context on every invoke). Skillforge encodes the discipline that produces skills somewhere in between — small enough to load fast, deep enough to actually work.

## Sources

The reference content is distilled from:
- [Anthropic Claude Code Skills docs](https://code.claude.com/docs/en/skills.md)
- [Anthropic Engineering — Equipping agents for the real world with Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
- [The Complete Guide to Building Skills for Claude (PDF)](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf)
- [github.com/anthropics/skills](https://github.com/anthropics/skills) — the 17 reference skills worth reading before authoring your own
- Practitioner thread from [@trq212](https://x.com/trq212/status/2033949937936085378)

## License

MIT — see `LICENSE`.
