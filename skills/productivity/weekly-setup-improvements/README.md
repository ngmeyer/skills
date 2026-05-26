# Weekly Setup Improvements

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-Skill-blueviolet?logo=anthropic)](https://claude.ai/code)
[![GitHub Stars](https://img.shields.io/github/stars/ngmeyer/weekly-setup-improvements?style=social)](https://github.com/ngmeyer/weekly-setup-improvements)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey)]()

A Claude Code skill that audits the past week of work in a folder and writes a forward-looking improvement report. State reflection, not journaling -- the output should be specific enough to act on in the next 30 minutes.

## The Problem

Setups drift. Context files go stale. The same prompt gets pasted three times in a week before anyone notices it should be a slash command. Cleanup happens "when there's time," which is never.

## The Solution

`/weekly-setup-improvements` runs a structured audit on a folder and writes a 5-section report:

```
Working folder + trailing 7 days
         |
   SCOPE  -> resolve folder, compute date window
         |
   SURVEY -> file mtimes, git log, file-type distribution
         |
   READ   -> CLAUDE.md, MEMORY.md, AGENTS.md, context anchors
         |
   ANALYZE -> repetition, manual effort, drift, bloat, wins
         |
   WRITE  -> weekly-setup-improvements.md (archives prior report)
         |
   PRESENT -> print path + section summary + first 20 lines
```

## Install

```bash
git clone https://github.com/ngmeyer/weekly-setup-improvements.git
cd weekly-setup-improvements

# Global install (available in all projects)
mkdir -p ~/.claude/skills/weekly-setup-improvements
cp SKILL.md ~/.claude/skills/weekly-setup-improvements/SKILL.md

# Or per-project install
mkdir -p .claude/skills/weekly-setup-improvements
cp SKILL.md .claude/skills/weekly-setup-improvements/SKILL.md
```

Then use it in Claude Code:

```
/weekly-setup-improvements                  # audits cwd
/weekly-setup-improvements ~/some-folder    # audits explicit path
```

Trigger phrases: *weekly review*, *improve my setup*, *what should I clean up*, *suggest new skills*.

## How It Works

### 6-Phase Procedure

| Phase | What | Key Behavior |
|-------|------|-------------|
| 1. SCOPE   | Resolve folder + window | Portable date math (no `date -v` or `date -d`) |
| 2. SURVEY  | Collect raw signals | `find -mtime`, `git log --since=`, file-type counts |
| 3. READ    | Load context files | CLAUDE.md, MEMORY.md, AGENTS.md, etc. |
| 4. ANALYZE | Five lenses | Repetition, manual effort, drift, bloat, wins |
| 5. WRITE   | Generate the report | Archives prior report to dated filename |
| 6. PRESENT | Show summary | File path, per-section counts, opening lines |

### Report Structure

The output file (`weekly-setup-improvements.md`) has exactly five sections:

1. **Context File Updates** — concrete diffs or content blocks for CLAUDE.md / MEMORY.md / etc.
2. **New Skill Ideas** — capped at 3, each justified by an observed repetition
3. **Workflow Gaps** — what was manual, what should replace it, why it matters
4. **Files to Clean Up** — DELETE / MOVE / ARCHIVE / MERGE actions with paths
5. **What's Working** — concrete wins, named files and commits, not virtues

### Quality Bar

The skill rejects its own output if any of these are true:

- A recommendation uses *consider*, *perhaps*, *you might want to*, or any other hedge
- A skill suggestion has no observed repetition behind it
- A "files to clean up" entry lacks an explicit verb (DELETE / MOVE / ARCHIVE / MERGE)
- *What's Working* names a virtue instead of a file or commit

## Schedule (Run Weekly)

Use the `/schedule` skill to register a recurring run:

```
/schedule weekly-setup-improvements every Sunday at 9am, working folder ~/path-to-folder
```

The skill will write a fresh report to that folder each Sunday and archive the prior one as `weekly-setup-improvements-YYYY-MM-DD.md` automatically.

## What It Won't Do

- Write a session log or activity diary (this is forward-looking only)
- Modify any file other than the report and its predecessor
- Suggest more than 3 new skills
- Skip *What's Working* (negative bias is the enemy)
- Hardcode user paths or use platform-specific date commands

## Sibling Skills

| Skill | Scope | Window | When to use |
|---|---|---|---|
| `/weekly-setup-improvements` | One folder | Trailing 7 days | Recurring delta audit |
| `/vault-audit` | One folder | All time | One-shot snapshot |
| `/claude-md-audit` | All CLAUDE.md files | All time | Drift hunt across projects |

## Credits

- Skill by: **Neal Meyer**
- Inspired by Karpathy's context-file pattern (about-me / voice-and-style / working-rules)

## License

MIT
