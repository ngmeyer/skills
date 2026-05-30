# Skills

[![skills.sh](https://skills.sh/b/ngmeyer/skills)](https://skills.sh/ngmeyer/skills)

Eight agent skills I use every day — small, composable, model-agnostic. Built for Claude Code, Codex, Cursor, and any agent that reads a `SKILL.md`.

These aren't a framework. Each skill is a single self-contained directory you can read in a minute, fork, and make your own. No process owns your work; the skills give you sharper tools and get out of the way.

## Install

### Option 1 — `npx skills` (recommended, multi-agent)

The [skills.sh](https://skills.sh) installer auto-detects which coding agents you have (Claude Code, Codex, Cursor, …), prompts you to pick which skills to install, and copies them into the right place. Works with any public GitHub repo — no registration needed.

```bash
npx skills@latest add ngmeyer/skills
```

After install, skills are invocable directly: `/adversarial-review`, `/council-review`, `/six-pager`, etc.

### Option 2 — Claude Code plugin marketplace

For users who prefer the official Claude Code plugin flow. Two steps:

```text
# 1. Register this repo as a plugin marketplace
/plugin marketplace add ngmeyer/skills

# 2. Install individual skills (or 'all')
/plugin install adversarial-review@ngmeyer-skills
/plugin install council-review@ngmeyer-skills
# ...etc, one per skill you want
```

Then `/reload-plugins` to activate. Marketplace-installed skills are namespaced: invoke them as `/ngmeyer-skills:adversarial-review`, `/ngmeyer-skills:council-review`, etc.

### Option 3 — Manual

```bash
git clone https://github.com/ngmeyer/skills.git ~/ngmeyer-skills
# Symlink the ones you want into ~/.claude/skills/ (Claude Code) or your agent's skills dir
ln -s ~/ngmeyer-skills/skills/productivity/six-pager ~/.claude/skills/six-pager
```

## The skills

### Engineering

| Skill | Use when |
|---|---|
| [`adversarial-review`](./skills/engineering/adversarial-review/SKILL.md) | You need a single critic to red-team a finished artifact — PR, spec, plan, or code — actively trying to break it. |
| [`claude-md`](./skills/engineering/claude-md/SKILL.md) | Auditing `CLAUDE.md` files for drift, leaked secrets, and bloat — or improving one against the Anthropic best-practice rubric. |
| [`session-recover`](./skills/engineering/session-recover/SKILL.md) | Recovering a lost agent session by merging duplicate project memory directories with a reconciliation gate. |

### Productivity

| Skill | Use when |
|---|---|
| [`council-review`](./skills/productivity/council-review/SKILL.md) | Running a decision through a 5-advisor multi-agent debate (DMAD-style) with a chairman synthesis and sycophancy guardrails. |
| [`six-pager`](./skills/productivity/six-pager/SKILL.md) | Writing an Amazon-style narrative decision memo or PR/FAQ launch doc under Strunk prose rules and a premortem requirement. |
| [`session-close`](./skills/productivity/session-close/SKILL.md) | Reconciling a work session's outcomes into persistent project memory — section-aware writes, not a session dump. |
| [`weekly-setup-improvements`](./skills/productivity/weekly-setup-improvements/SKILL.md) | Auditing a week of work in a folder and producing a forward-looking improvement report — closure check, zombie-action kills, auto-drafted skill scaffolds. |
| [`skillforge`](./skills/productivity/skillforge/SKILL.md) | Forging a new skill, or `optimize`ing an existing one to a measurably-better V2 (quality audit + outcome research + train/val A/B verification). |

## Conventions

Every skill is one directory with a `SKILL.md` (YAML frontmatter: `name`, `description`) plus optional `references/` (progressive-disclosure depth) and `scripts/` (deterministic helpers). Skills are categorized under `skills/<category>/<name>/`.

See [CONTEXT.md](./CONTEXT.md) for the design philosophy and [CLAUDE.md](./CLAUDE.md) for how to add or evolve one.

## License

[MIT](./LICENSE) © 2026 Neal Meyer
