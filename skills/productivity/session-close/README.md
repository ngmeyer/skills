# Session Close

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-Skill-blueviolet?logo=anthropic)](https://claude.ai/code)
[![GitHub Stars](https://img.shields.io/github/stars/ngmeyer/session-close?style=social)](https://github.com/ngmeyer/session-close)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey)]()

A Claude Code skill that reconciles session outcomes into persistent project memory files. State reconciliation, not session logging -- the output should be indistinguishable from a human updating the project docs after a week of work.

## The Problem

After a long Claude Code session, you have decisions, discoveries, and state changes scattered across the conversation. Without capture, the next session starts from zero. The naive fix -- dumping everything into `session_notes_apr8.md` -- creates files nobody reads.

## The Solution

`/session-close` extracts only the durable, specific, retrievable outcomes and merges them into per-project memory files using section-aware strategies:

```
Session conversation + git state
         |
   Classify events (DECISION, STATUS_CHANGE, DISCOVERY, ...)
         |
   Three-gate filter (Durability, Specificity, Retrieval)
         |
   Section-aware merge (REPLACE status, MERGE-LIST backlog, PRESERVE stack)
         |
   Show diff for approval -> Write
```

## Install

Clone the repo and copy the skill into your Claude Code skills directory:

```bash
# Clone
git clone https://github.com/ngmeyer/session-close.git
cd session-close

# Global install (available in all projects)
mkdir -p ~/.claude/skills/session-close
cp SKILL.md ~/.claude/skills/session-close/SKILL.md

# Or per-project install
mkdir -p .claude/skills/session-close
cp SKILL.md .claude/skills/session-close/SKILL.md
```

Then use it in Claude Code at the end of any work session:

```
/session-close
/session-close myproject
```

## How It Works

### 7-Phase Procedure

| Phase | What | Key Behavior |
|-------|------|-------------|
| 1. IDENTIFY | Find touched projects | Conversation + git + cwd convergence |
| 2. READ | Load existing memory | Parse sections, check file size |
| 3. EXTRACT | Classify events | 6 event types, three-gate filter |
| 4. RECONCILE | Section-aware merge | REPLACE / MERGE-LIST / PRESERVE strategies |
| 5. PRESENT | Show diff for approval | Never writes without asking |
| 6. INDEX | Update MEMORY.md | Add new project entries |
| 7. CLEANUP | Remove stale artifacts | Plans, task dirs, session dumps |

### Event Classification

| Type | Persist? | Example |
|------|----------|---------|
| DECISION | Always | "Switched from cookies to JWT for auth" |
| STATUS_CHANGE | Always | "Deployed to production" |
| DISCOVERY | If novel | "Neon has a 100-connection limit on free tier" |
| IMPLEMENTATION | Outcome only | "Built MCP server" (not "created 12 files") |
| TROUBLESHOOTING | Pattern only | "Vercel Blob needed for files >4.5MB" |
| EXPLORATION | Never | Reading docs, abandoned approaches |

### Three-Gate Filter

Every event must pass all three gates to be persisted:

1. **Durability** -- Will this still be true in 30 days?
2. **Specificity** -- Can I state this as a concrete claim? ("Imported 457K records" not "worked on imports")
3. **Retrieval** -- Is a future session likely to need this?

### Section-Aware Merging

| Strategy | Sections | Behavior |
|----------|----------|----------|
| **REPLACE** | Status | Full overwrite -- represents current state |
| **MERGE-LIST** | Backlog, Features, TODO | Deduplicate, mark completed, append new |
| **PRESERVE** | Stack, Architecture, Config | Only touch if explicitly changed |

## Core Principle

**Code captures outcomes; memory captures reasoning.** Git records *what* changed. Memory files capture *why* decisions were made, *what state* the project is in, and *what comes next*.

## What It Won't Do

- Create session dumps (`project_session_apr8.md`)
- Write without showing you the diff first
- Persist debugging steps, error messages, or abandoned approaches
- Update memory for projects that were only mentioned, not worked on
- Regenerate sections that didn't change (LLM rewrites lose nuance)

## Memory File Format

The skill expects memory files with markdown sections. Here's a minimal template:

```markdown
---
name: my-project
description: One-line description of the project
type: project
---

## What It Does
- Feature 1
- Feature 2

## Stack
- Language, framework, etc.

## Status (Apr 13, 2026)
- Current branch: main
- Deployed: production
- Next: implement auth

## Backlog
- [ ] Add OAuth support
- [ ] Write API docs
- [x] Set up CI pipeline
```

## Credits

- Skill by: **Neal Meyer**

## License

MIT
