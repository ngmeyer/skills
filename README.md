# Skills For Thinking, Not Just Coding

[![skills.sh](https://skills.sh/b/ngmeyer/skills)](https://skills.sh/ngmeyer/skills)

Ten agent skills I use every day, for deciding, writing, remembering, and improving, not just generating code. Small, composable, model-agnostic. Built for Claude Code, Codex, Cursor, and any agent that reads a `SKILL.md`.

Most of an agent's failures aren't coding failures. The agent agrees when it should push back. The big decision gets made in a chat window. The setup quietly rots. The session ends and the context is gone. The prose comes out sounding like a machine. These skills are built for exactly those moments.

They aren't a framework. Each skill is a single self-contained directory you can read in a minute and fork into your own. No process owns your work; the skills give you sharper tools and then get out of the way.

## Quickstart (30-second setup)

1. Run the [skills.sh](https://skills.sh) installer. It auto-detects which coding agents you have (Claude Code, Codex, Cursor, …), prompts you to pick which skills to install, and copies them into the right place. Works with any public GitHub repo, no registration needed.

```bash
npx skills@latest add ngmeyer/skills
```

2. Pick the skills and agents you want.

3. That's it. Each skill is self-contained, with no per-repo setup step. Invoke them directly:

```text
/six-pager        /council-review     /adversarial-review
/claude-md        /session-close      /skillforge
/rigorous-review  /write-well
```

<details>
<summary>Other install methods (Claude Code plugin marketplace, manual)</summary>

### Claude Code plugin marketplace

For the official Claude Code plugin flow. Two steps:

```text
# 1. Register this repo as a plugin marketplace
/plugin marketplace add ngmeyer/skills

# 2. Install individual skills
/plugin install six-pager@ngmeyer-skills
/plugin install council-review@ngmeyer-skills
# ...one per skill you want
```

Then `/reload-plugins` to activate. Marketplace-installed skills are namespaced, so you invoke them as `/ngmeyer-skills:six-pager`, `/ngmeyer-skills:council-review`, and so on.

### Manual

```bash
git clone https://github.com/ngmeyer/skills.git ~/ngmeyer-skills
# Symlink the ones you want into your agent's skills dir
ln -s ~/ngmeyer-skills/skills/productivity/six-pager ~/.claude/skills/six-pager
```

</details>

## Why These Skills Exist

I built these to fix the failure modes I kept hitting with Claude Code and other agents, the ones that have nothing to do with whether the code compiles.

### #1: The Agent Just Agrees With Me

> "Where all think alike, no one thinks very much."
>
> Walter Lippmann, *The Stakes of Diplomacy*

**The Problem**: An agent's default is to agree. Ask "is this a good plan?" and you get a confident yes. That's the most dangerous failure mode in a thinking partner. It feels like validation, and it's worth nothing.

**The Fix** is manufactured dissent: make the agent argue against you before you commit, and audit the work before you ship.

- [`/council-review`](./skills/productivity/council-review/SKILL.md) runs your question through five advisors with distinct reasoning methods, who peer-review each other anonymously before a chairman synthesizes the verdict. Use it for open questions with real stakes.
- [`/adversarial-review`](./skills/engineering/adversarial-review/SKILL.md) is a single critic that actively tries to break a *finished* thing: a PR, a spec, a plan, an argument. Use it before you ship.
- [`/rigorous-review`](./skills/engineering/rigorous-review/SKILL.md) widens that to the whole codebase. It's a behavior-preserving audit for security, performance, correctness, and refactoring that scores every finding by confidence and reports before it changes a line.

Decide with `/council-review`, stress-test one artifact with `/adversarial-review`, then audit the codebase with `/rigorous-review`.

### #2: The Big Decision Got Made In A Chat Window

> "There is no way to write a six-page, narratively structured memo and not have clear thinking."
>
> Jeff Bezos, [2017 Amazon shareholder letter](https://www.aboutamazon.com/news/company-news/2017-letter-to-shareholders)

**The Problem**: Decisions worth a week of consequences get made in a few sloppy chat turns. The bullet points hide the gaps. Nobody writes down what would make this fail.

**The Fix** is to force the prose. Writing is the thinking instrument, not the record of it.

- [`/six-pager`](./skills/productivity/six-pager/SKILL.md) generates an Amazon-style narrative decision memo (or a PR/FAQ for a launch), under Strunk's prose rules, with a **required premortem**: assume it's twelve months later and this failed, then name the three most likely causes now, while you can still act on them.

### #3: My Setup Quietly Rots

> "Don't live with broken windows."
>
> David Thomas & Andrew Hunt, [The Pragmatic Programmer](https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/)

**The Problem**: A `CLAUDE.md` starts sharp and drifts. It claims facts that no longer match the code, accumulates bloat, sometimes leaks a secret. And the wider setup (skills, workflows, context files) decays one small unaddressed thing at a time.

**The Fix** is regular, opinionated maintenance:

- [`/claude-md`](./skills/engineering/claude-md/SKILL.md) has two modes: `audit` finds drift, leaked secrets, duplicates, and budget bloat across all your `CLAUDE.md` files; `improve` measures one against Anthropic's best-practice rubric and proposes concrete rewrite diffs.
- [`/weekly-setup-improvements`](./skills/productivity/weekly-setup-improvements/SKILL.md) audits a week of work and writes a forward-looking improvement report: a closure check on last week's actions, zombie-action kills (dropped twice, killed, never re-surfaced), and auto-drafted scaffolds for the skills you keep wishing you had. Safe to schedule weekly.

### #4: The Session Ends And The Context Is Gone

> "The palest ink is better than the best memory."
>
> Chinese proverb

**The Problem**: Everything the agent learned this session (which decisions you made, which paths turned out to be dead ends, and why) evaporates when the window closes. Worse, a folder move or a second working directory can split your project memory into two namespaces, and the work you saved appears to vanish.

**The Fix** is to write memory down, and to repair it when it splits:

- [`/session-close`](./skills/productivity/session-close/SKILL.md) reconciles a session's outcomes into persistent project-memory files with section-aware merges. Not a session dump; an update.
- [`/session-recover`](./skills/engineering/session-recover/SKILL.md) finds duplicate project directories that point at the same logical project from different paths, unifies the memory into the canonical one, and captures the lesson so the split doesn't repeat.

### #5: My Skills Don't Get Better

> "Without data, you're just another person with an opinion."
>
> W. Edwards Deming

**The Problem**: You write a skill, it works well enough, and it never improves. "Better" stays a vibe. There's no measurement, so there's no progress.

**The Fix** is to treat a skill like any other artifact you can measure and tune:

- [`/skillforge`](./skills/productivity/skillforge/SKILL.md) has two modes: `forge` scaffolds a new skill the right way (frontmatter, progressive disclosure, helper scripts, mandatory Gotchas); `optimize` makes an existing skill measurably better at its *outcome*, not just its packaging, with a quality audit, domain outcome-research, and a held-out train/validation A/B that catches overfitting. Every skill in this repo was built and tuned with it.

### #6: My Writing Reads Like A Machine Wrote It

> "The style is the man himself."
>
> Comte de Buffon, *Discourse on Style* (1753)

**The Problem**: Ask an agent to write and you get prose with no person behind it. Clean, grammatical, and dead. The significance inflation, the rule-of-three, the em-dash spray, the flat reporting. Those aren't separate bugs; they're one symptom, the absence of a voice.

**The Fix** is to add the voice, not just scrub the tells. A draft with every tell removed but no one home still reads as a machine:

- [`/write-well`](./skills/productivity/write-well/SKILL.md) drafts or edits prose with a real voice, working from a deduped craft canon (Strunk, Zinsser, Orwell, Ogilvy, White, and six more) and the full AI-tell catalog. Adopt any voice with `--voice`, `--persona`, or `--like` a sample of your own writing. It even holds its own em-dash budget, and its tests fail if the skill's prose breaks the rule it teaches.

### Summary

The fundamentals of good thinking don't change because an agent is doing the typing. You still have to disagree before you commit, write to find out what you actually think, and maintain what you build. These skills are my best effort at making an agent do that by default. Enjoy.

## Reference

### Engineering

Code-facing skills.

- **[adversarial-review](./skills/engineering/adversarial-review/SKILL.md)** — Single-critic red-team of a finished artifact: edge cases, hidden assumptions, failure modes. Actively tries to break it before it ships.
- **[claude-md](./skills/engineering/claude-md/SKILL.md)** — Two modes for `CLAUDE.md` files: `audit` finds drift, leaked secrets, and bloat across your projects; `improve` rewrites one against Anthropic's best-practice rubric.
- **[rigorous-review](./skills/engineering/rigorous-review/SKILL.md)** — Whole-codebase audit (security · performance · correctness · refactoring) that never changes outward-facing behavior: scores every finding on severity × confidence, suppresses predictable noise, validates survivors with an independent agent, and reports before it touches anything.
- **[session-recover](./skills/engineering/session-recover/SKILL.md)** — Recover lost context by merging duplicate project-memory directories that a folder move split into two namespaces.

### Productivity

Thinking and process skills, not code-specific.

- **[council-review](./skills/productivity/council-review/SKILL.md)** — Run a decision through a 5-advisor multi-agent debate (DMAD) with anonymous peer review and a chairman synthesis. Built to beat sycophancy.
- **[six-pager](./skills/productivity/six-pager/SKILL.md)** — Amazon-style narrative decision memo or PR/FAQ, under Strunk prose rules, with a required premortem.
- **[session-close](./skills/productivity/session-close/SKILL.md)** — Reconcile a work session into persistent project memory with section-aware merges, not a session dump.
- **[weekly-setup-improvements](./skills/productivity/weekly-setup-improvements/SKILL.md)** — Audit a week of work and produce a forward-looking improvement report: closure check, zombie-action kills, auto-drafted skill scaffolds.
- **[skillforge](./skills/productivity/skillforge/SKILL.md)** — Forge a new skill, or `optimize` an existing one to a measurably better V2 (quality audit + outcome research + train/validation A/B).
- **[write-well](./skills/productivity/write-well/SKILL.md)** — Draft or edit prose with a real voice: `draft` from scratch or `edit` flat or AI-flavored text against a pattern catalog, in any `--voice`, `--persona`, or cloned `--like` a sample. Backed by a deduped craft canon (Strunk, Zinsser, Orwell, Ogilvy, White …).

## Conventions

Every skill is one directory with a `SKILL.md` (YAML frontmatter: `name`, `description`) plus optional `references/` (progressive-disclosure depth) and `scripts/` (deterministic helpers). Skills live under `skills/<category>/<name>/`.

See [CONTEXT.md](./CONTEXT.md) for the design philosophy and [CLAUDE.md](./CLAUDE.md) for how to add or evolve one.

## License

[MIT](./LICENSE) © 2026 Neal Meyer
