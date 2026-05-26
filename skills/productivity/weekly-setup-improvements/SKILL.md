---
name: weekly-setup-improvements
description: >
  Audit recent work in a folder and produce a forward-looking self-improvement
  report. Reviews files modified in the past week, git activity, file-type
  distribution, and recurring task patterns; writes a 5-section
  weekly-setup-improvements.md with concrete updates for context files,
  ideas for new skills, workflow gaps to close, files to clean up, and
  what's working well enough to leave alone. Cross-platform; safe to schedule
  weekly via /schedule.
  Use when: 'weekly review', 'weekly self audit', 'improve my setup',
  'what should I clean up', 'suggest new skills', 'self improvement loop',
  'weekly setup improvements', or before a planning week.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep"]
argument-hint: "[optional: path to working folder, defaults to cwd]"
---

# /weekly-setup-improvements -- Weekly Self-Improvement Audit

Audit the past 7 days of work in a folder and write a structured improvement report. This is **state reflection**, not journaling -- the output should be specific, actionable, and short enough that a busy practitioner will actually read it.

## Core Principle

Every week generates patterns. Most patterns reveal an obvious next step -- a context file that needs updating, a slash command that should exist, a directory that needs cleaning. The cost of running this skill is a few minutes; the cost of *not* running it is invisible drift in the setup over months.

## What This Skill Is (and Is Not)

| | This skill | Not this skill |
|---|---|---|
| **Scope** | One folder | Whole machine |
| **Window** | Trailing 7 days | All time |
| **Output** | Forward-looking actions | Backward-looking diary |
| **Sibling** | `/vault-audit` (snapshot, no time window), `/claude-md-audit` (CLAUDE.md drift only) | |

## Arguments

- **Argument 1 (optional):** Path to working folder. Defaults to `pwd`.

## Procedure

### Phase 1: SCOPE

1. Resolve the working folder:
   - If an argument was passed, validate that the path exists and is a directory; abort with a clear error if not.
   - Otherwise use `pwd`.
2. Compute the time window. Use only portable shell:
   ```bash
   TODAY=$(date +%Y-%m-%d)
   # 7-day boundary as ISO date (portable):
   START=$(python3 -c "from datetime import date,timedelta; print(date.today()-timedelta(days=7))")
   ```
   Do **not** use `date -v-7d` (macOS-only) or `date -d` (GNU-only).
3. Echo the scope back to the user before continuing:
   `Auditing <folder> for the period <START> to <TODAY>.`

### Phase 2: SURVEY

Collect raw signals. Run these in parallel where possible:

```bash
WORKING_FOLDER="$1"

# Files modified in the last 7 days (skip dotdirs and dependency dirs)
find "$WORKING_FOLDER" -type f -mtime -7 \
  -not -path '*/.*' -not -path '*/node_modules/*' \
  -not -path '*/.venv/*' -not -path '*/dist/*' -not -path '*/target/*' \
  | head -150

# Git activity if folder is a repo (use --since= flag, portable across platforms)
git -C "$WORKING_FOLDER" log --since="7 days ago" --oneline 2>/dev/null
git -C "$WORKING_FOLDER" log --since="7 days ago" --stat --no-merges 2>/dev/null | head -300
git -C "$WORKING_FOLDER" status --porcelain 2>/dev/null

# Recently touched directories (signals new work areas)
find "$WORKING_FOLDER" -type d -mtime -7 -not -path '*/.*' | head -30

# File-type distribution (signals task type: code, prose, config, data)
find "$WORKING_FOLDER" -type f -mtime -7 -not -path '*/.*' \
  | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -10
```

If the folder is not a git repo, skip the git commands silently and rely on `find -mtime` alone.

### Phase 3: READ

Look for and read whichever of these exist (gracefully skip missing files):

- `CLAUDE.md` (Claude Code project context)
- `MEMORY.md` (memory index)
- `AGENTS.md` (agent context)
- `about-me.md`, `voice-and-style.md`, `working-rules.md` (Karpathy-style context anchors)
- Any `*.md` in a `memory/`, `context/`, or `docs/` subdirectory near the root

These are the targets for Section 1 (Context File Updates).

### Phase 4: ANALYZE

Walk the signals from Phase 2 with these specific lenses, in this order. For each lens, write down what you find before moving on:

1. **Repetition.** Sort the modified-files list and the git log by name; flag any base-name pattern that appears more than once (`linkedin-*-draft.md`, repeated commits with the same verb, sibling fixtures). Each repetition is a candidate skill.
2. **Manual effort.** Look for sequences of small commits that look like "fix typo / fix typo / fix typo" or "add file / remove file / re-add file" -- those are workflows that should have been a script or a hook.
3. **Drift.** For each context file read in Phase 3, find one claim it makes (a path, a tool, a constraint) and check whether the past week's work contradicts it. List every contradiction with a one-line fix.
4. **Bloat.** Files older than the audit window that no longer match a current naming convention; `*-draft-N.md` siblings; archive candidates.
5. **Wins.** What pattern in the week clearly worked? Name the file or commit that proves it. Don't generalize before naming the proof.

If `compound-engineering:ce-sessions` is installed, optionally use it to surface conversational themes (e.g., "user paused three times this week to ask 'how do I X'"). Skip if not available -- the skill must work without it.

### Phase 5: WRITE

**Output file:** `<WORKING_FOLDER>/weekly-setup-improvements.md`

**If a prior report exists:** Before writing, archive it:
```bash
PRIOR="$WORKING_FOLDER/weekly-setup-improvements.md"
if [ -f "$PRIOR" ]; then
  PRIOR_DATE=$(grep -m1 '^# Weekly Setup Improvements' "$PRIOR" | sed -E 's/.*— ([A-Za-z]+ [0-9]+, [0-9]+).*/\1/' | tr ' ,' '--')
  [ -z "$PRIOR_DATE" ] && PRIOR_DATE=$(date -r "$PRIOR" +%Y-%m-%d 2>/dev/null || echo "$START")
  mv "$PRIOR" "$WORKING_FOLDER/weekly-setup-improvements-$PRIOR_DATE.md"
fi
```

**Structure (use exactly):**

```markdown
# Weekly Setup Improvements — <Month Day, Year>

Based on review of <one-line scope>: files modified, git activity, and patterns from <START> to <TODAY>.

---

## 1. Context File Updates

For each context file, give one of:
- **Create:** path + suggested content (in a code block)
- **Update:** path + the specific lines to add or change
- **No change:** path + one-line reason it's still accurate

## 2. New Skill Ideas

Cap at 3. Quality over quantity. For each:
- `/skill-name` — one-line description
- **What it does:** 2-3 bullets
- **Trigger phrases:** when the user would invoke it

## 3. Workflow Gaps

Each gap is one bullet group:
- **Did manually:** what
- **Should be:** what (a tool, a script, a skill, a hook)
- **Cost of waiting:** why this matters

## 4. Files to Clean Up

For each: path + action (DELETE / MOVE TO / ARCHIVE / MERGE INTO).
Skip the section if nothing to clean up.

## 5. What's Working

3-5 bullets. Concrete -- name specific files, skills, or workflows that produced clear value this week.

---
*Generated by /weekly-setup-improvements on <TODAY>.*
```

### Phase 6: PRESENT

After writing, print:
1. The full output file path.
2. A summary line per section (e.g., "Section 2: 2 new skill ideas; Section 4: 5 files to clean up").
3. The opening 15-20 lines of the report so the user can act without opening Obsidian.

## Quality Bar

A report passes if **every** check is true. Otherwise rewrite the offending section.

- Each Section 1 entry references an actual file (existing or proposed) and gives a concrete diff or content block, not "consider updating."
- Each Section 2 skill cites the specific repetition that justifies it (commit count, file count, prompt count).
- Each Section 3 gap names what was done manually and what should replace it.
- Each Section 4 entry includes a verb (DELETE/MOVE/ARCHIVE/MERGE) and a path.
- Section 5 names files or commits, not virtues.
- No section uses "consider", "perhaps", "you might want to", "establish a process for", or any other hedging phrase. Every recommendation is concrete enough to act on in the next 30 minutes.

## What NOT to Do

- **Do not write a session log.** This is forward-looking improvement, not "here's what you did" diary. If a section reads like a diary entry, rewrite it as an action.
- **Do not pad with general advice.** Every bullet must reference an actual file, skill, or pattern observed this week.
- **Do not suggest more than 3 new skills.** More than that is noise; the user won't build any of them.
- **Do not skip "What's Working."** Negative bias is the enemy; the user needs to know what to keep as much as what to change.
- **Do not modify any other files.** This skill writes one file (and renames the prior one if present).
- **Do not hardcode user paths.** Use `$WORKING_FOLDER`, `$HOME`, `$1`. Never `/Users/<name>/...`.

## Routine / Schedule

To run weekly, invoke the `/schedule` skill and ask it to schedule this skill against the desired folder and cron expression. Example:

```
/schedule weekly-setup-improvements every Sunday at 9am, working folder ~/path-to-folder
```

The schedule skill handles the cron syntax and persistence -- this skill itself only knows how to produce a report when run.

## Testing

This is a prompt-only skill -- no automated runtime tests. The shipped `tests/eval.sh` runs a structural eval that asserts the design contract is intact in SKILL.md (phases present, no banned hardcoded paths, output filename correct, etc.).

To verify behavior end-to-end:

1. `cd` into a folder with at least 7 days of recent activity.
2. Run `/weekly-setup-improvements`.
3. Check that:
   - The output file lands in the cwd.
   - All 5 sections are populated (or "What's Working" has fewer than 5 with a real reason).
   - Each bullet names a real file, command, or pattern from the past week.
   - No "consider..." or "perhaps..." padding.
   - Prior report (if any) was archived to a dated filename, not overwritten.
4. Re-run with an explicit path argument: `/weekly-setup-improvements ~/some-other-folder`.
   Verify the report writes to that folder, not cwd.
