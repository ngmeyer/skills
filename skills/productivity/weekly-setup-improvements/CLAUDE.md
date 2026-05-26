# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

Weekly Setup Improvements is a Claude Code skill that audits the trailing 7 days of work in a folder and writes a forward-looking improvement report. The output is structured into 5 sections (context file updates, new skill ideas, workflow gaps, files to clean up, what's working).

**Repo:** github.com/ngmeyer/weekly-setup-improvements
**Author:** Neal Meyer

## File Structure

```
weekly-setup-improvements/
├── SKILL.md      # The executable skill — this IS the product
├── README.md     # GitHub-facing documentation
├── LICENSE       # MIT
├── CLAUDE.md     # This file
└── tests/
    ├── eval.sh         # Structural eval (asserts SKILL.md design contract)
    ├── README.md       # What's tested vs deferred
    └── fixtures/       # Sample inputs for future runtime tests
```

## Architecture

This is a **prompt-only skill** — no runtime code, no dependencies, no build step. The entire product is `SKILL.md`, a markdown file Claude Code loads and executes at invocation time.

### 6-Phase Execution

```
Phase 1: SCOPE    — resolve working folder + compute 7-day window
Phase 2: SURVEY   — file mtimes, git log, file-type distribution
Phase 3: READ     — load CLAUDE.md, MEMORY.md, AGENTS.md, context anchors
Phase 4: ANALYZE  — five lenses (repetition, manual effort, drift, bloat, wins)
Phase 5: WRITE    — generate report, archive any prior report
Phase 6: PRESENT  — print path + per-section summary + opening lines
```

### Key Design Decisions

- **Forward-looking, not backward.** The report says what to do next week, not what happened last week.
- **Quality bar over quantity.** Cap of 3 new skill ideas. Hedge phrases banned. Every bullet must reference a real file or pattern.
- **Cross-platform first.** No `date -v` (macOS-only) or `date -d` (GNU-only). Uses `python3` for date math, portable `--since=` flag for git, `-mtime` for find.
- **Archive, don't overwrite.** Prior reports get renamed to dated filenames; the canonical path always holds the latest.
- **Sibling-aware.** README explicitly contrasts with `/vault-audit` and `/claude-md-audit` so users pick the right tool.
- **Optional integrations.** `compound-engineering:ce-sessions` is used if available; the skill must work without it.

### Portability Requirements

- **No hardcoded user paths.** Use `$WORKING_FOLDER`, `$HOME`, `$1`. Never `/Users/<name>/...` or `/home/<name>/...`.
- **Cross-platform date math.** `python3 -c "..."` for date arithmetic; `git log --since="7 days ago"` for git.
- **Graceful skip.** If folder isn't a git repo, skip git commands without erroring. If no context files exist, Section 1 says so.

## Editing Guidelines

- **SKILL.md is the product.** Changes to SKILL.md change behavior for all users.
- **Prompt changes are code changes.** The phase order, the quality bar list, and the banned-hedge phrases are load-bearing — test before shipping.
- **Don't add runtime dependencies.** Must remain a single markdown file.
- **Keep "What NOT to Do" current.** Every anti-pattern caught in production should land there.
- **Keep the cap at 3 skill ideas.** This is the difference between a useful report and noise.

## Testing

Run the structural eval:

```bash
bash tests/eval.sh
```

Exit 0 = design contract intact. Exit 1 = regression.

To verify behavior end-to-end:

1. `cd` into a folder with at least 7 days of recent activity
2. Run `/weekly-setup-improvements`
3. Check that:
   - The report lands in cwd as `weekly-setup-improvements.md`
   - All 5 sections populated, every bullet references a real file or pattern
   - No hedge phrases ("consider", "perhaps", "you might want to")
   - Prior report (if any) was archived to `weekly-setup-improvements-YYYY-MM-DD.md`
4. Re-run with explicit path: `/weekly-setup-improvements ~/some-other-folder`. Verify report goes to that folder.

## Commit Style

Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`
