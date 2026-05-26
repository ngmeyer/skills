# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

Session Close is a Claude Code skill that reconciles session outcomes into persistent project memory files. It replaces unstructured session dumps with section-aware merging that produces files indistinguishable from human-maintained project documentation.

**Repo:** github.com/ngmeyer/session-close
**Author:** Neal Meyer

## File Structure

```
session-close/
├── SKILL.md      # The executable skill — this IS the product
├── README.md     # GitHub-facing documentation with install instructions
├── LICENSE        # MIT
└── CLAUDE.md      # This file
```

## Architecture

This is a **prompt-only skill** — no runtime code, no dependencies, no build step. The entire product is `SKILL.md`, a markdown file that Claude Code loads and executes at invocation time.

### 7-Phase Execution

```
Phase 1: IDENTIFY  — find touched projects (conversation + git + cwd)
Phase 2: READ      — load existing memory files, parse sections
Phase 3: EXTRACT   — classify events, apply three-gate filter
Phase 4: RECONCILE — section-aware merge (REPLACE/MERGE-LIST/PRESERVE)
Phase 5: PRESENT   — show diff for user approval
Phase 6: INDEX     — update MEMORY.md if new files created
Phase 7: CLEANUP   — offer to remove stale artifacts
```

### Key Design Decisions

- **State reconciliation, not session logging.** The anti-pattern is session dumps. Output should read like a human updated the project docs.
- **Three-gate filter (Durability, Specificity, Retrieval).** Events must pass all three to be persisted. This is the quality mechanism.
- **Section-aware merging.** Status is REPLACE (current state). Backlog is MERGE-LIST (deduplicate + append). Stack/Architecture is PRESERVE (don't touch unless changed).
- **Never write without approval.** Phase 5 always shows a diff and asks before modifying files.
- **No section regeneration.** LLM rewrites subtly lose nuance. Use Edit tool on specific lines, not Write on the whole file.
- **Dynamic path resolution.** Memory directory is resolved from the project path, not hardcoded. Works for any user on any OS.

### Portability Requirements

- **No hardcoded user paths.** Memory paths are resolved dynamically from `~/.claude/projects/`.
- **Cross-platform git commands.** Use `--since="12 hours ago"` (portable) not `date -v-12H` (macOS-only).
- **Section matching is flexible.** Headings like "Backlog", "TODO", "Next Steps" all match MERGE-LIST strategy.

## Editing Guidelines

- **SKILL.md is the product.** Changes to SKILL.md change behavior for all users.
- **Prompt changes are code changes.** The event classification table, three-gate filter, and merge strategies are load-bearing — test before shipping.
- **Don't add runtime dependencies.** Must remain a single markdown file.
- **Keep "What NOT to Do" section current.** Every anti-pattern caught in production should be documented there.

## Testing

No automated tests — this is a prompt file. To test:

1. Install locally: `cp SKILL.md ~/.claude/skills/session-close/SKILL.md`
2. Do meaningful work in a project session
3. Run `/session-close` and verify:
   - Correct projects identified
   - Events properly classified and filtered
   - Diff preview shown before any writes
   - Section merging respects REPLACE/MERGE-LIST/PRESERVE
   - No session-dump anti-pattern in output
4. Test edge cases: zero-outcome session, multi-project session, no existing memory file

## Commit Style

Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`
