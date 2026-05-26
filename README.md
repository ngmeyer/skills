# Skills

[![skills.sh](https://skills.sh/b/ngmeyer/skills)](https://skills.sh/ngmeyer/skills)

Agent skills I use every day — small, composable, model-agnostic. Built for Claude Code, Codex, and any agent that reads a `SKILL.md`.

These aren't a framework. Each skill is a single self-contained directory you can read in a minute, fork, and make your own. No process owns your work; the skills give you sharper tools and get out of the way.

## Quickstart

Install with the [skills.sh](https://skills.sh) installer — pick the skills and the agents you want:

```bash
npx skills@latest add ngmeyer/skills
```

Or add the whole set as a Claude Code plugin marketplace:

```text
/plugin marketplace add ngmeyer/skills
```

## The skills

### Engineering

| Skill | What it does |
|---|---|
| [`claude-md`](./skills/engineering/claude-md/SKILL.md) | Audit CLAUDE.md files for drift, secrets, and bloat; or improve one against best-practice rubric. |
| [`adversarial-review`](./skills/engineering/adversarial-review/SKILL.md) | Single-critic red-team of a finished artifact — PR, spec, plan, or code — actively trying to break it. |
| [`session-recover`](./skills/engineering/session-recover/SKILL.md) | Recover lost agent-session context by merging duplicate project memory directories. |

### Productivity

| Skill | What it does |
|---|---|
| [`council-review`](./skills/productivity/council-review/SKILL.md) | Run a decision through a 5-advisor multi-agent debate with a chairman synthesis. |
| [`six-pager`](./skills/productivity/six-pager/SKILL.md) | Amazon-style narrative decision memos and PR/FAQ launch docs, under Strunk prose rules. |
| [`session-close`](./skills/productivity/session-close/SKILL.md) | Reconcile a work session's outcomes into persistent project memory — section-aware, not a dump. |
| [`weekly-setup-improvements`](./skills/productivity/weekly-setup-improvements/SKILL.md) | Audit a week of work in a folder and produce a forward-looking self-improvement report. |

> Skills under `skills/in-progress/` are not yet shipped (not listed in the plugin manifest) and may change or move.

## Conventions

Every skill is one directory with a `SKILL.md` (YAML frontmatter: `name`, `description`) plus optional `references/` and `scripts/`. Skills are categorized under `skills/<category>/<name>/`. See [CONTEXT.md](./CONTEXT.md) for the design philosophy and [CLAUDE.md](./CLAUDE.md) for how to add one.

## License

[MIT](./LICENSE) © 2026 Neal Meyer
