---
name: session-close
description: >
  Reconcile session outcomes into persistent project memory files.
  Updates project state, backlog, and status via section-aware merging --
  not a session dump. Use at the end of any significant work session.
  Use when: 'session close', 'close session', 'save session',
  'update memory', 'wrap up', 'end of session', or before ending a big session.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "Agent"]
argument-hint: "[optional: project name if not obvious from cwd/context]"
---

# /session-close -- Session-to-Memory Reconciliation

Reconcile durable outcomes from the current session into persistent project memory files. This is **state reconciliation**, not session logging -- the output should be indistinguishable from a human updating the project memory after a week of work.

## Core Principle

**Code captures outcomes; memory captures reasoning.** Git already records what changed. Project memory files exist to capture *why* decisions were made, *what state* the project is in, and *what comes next* -- things that can't be derived from a diff.

## The Anti-Pattern This Skill Prevents

Files like `project_session_apr8_9.md` -- unstructured dumps of everything done across multiple projects in one session. These fail the "new team member" test: a developer joining tomorrow can't distinguish signal from noise. State reconciliation produces files that answer "what is this project?" not "what happened today?"

## Arguments

- **Argument 1 (optional):** Project name to update. If omitted, the skill identifies projects from conversation context and working directory.

## Procedure

### Phase 1: IDENTIFY -- What projects were touched?

Determine which projects received meaningful work in this session using three sources:

1. **Conversation context (primary).** Review the current conversation to identify projects discussed. This is the richest source -- it captures intent, decisions, and outcomes that git alone cannot.

2. **Working directory.** Check the current working directory:
   - If cwd is a project dir (has `.git/`), that's the primary project
   - If cwd is a workspace containing multiple project subdirectories, check which ones have recent activity
   - If cwd is home (`~/`), rely on conversation context entirely

3. **Git state (verification).** For each identified project directory:
   ```bash
   # Cross-platform: works on macOS and Linux
   git -C $PROJECT log --oneline --since="12 hours ago" 2>/dev/null
   git -C $PROJECT status --porcelain 2>/dev/null  # uncommitted work
   ```
   Git confirms what code actually changed. If conversation mentions work but git shows nothing, flag the discrepancy. Also note any **uncommitted changes** -- these are critical to capture in Status.

**Project-to-memory mapping:** Resolve the memory directory dynamically:
- Claude Code stores project memory at `~/.claude/projects/<escaped-project-path>/memory/`
- The escaped path replaces `/` with `-` (e.g., `/Users/alice/Projects/myapp` becomes `-Users-alice-Projects-myapp`)
- Memory files follow the naming convention `project_{name}.md`
- If a memory directory already exists for the project, use it. If not, create it.

**Convergence rule:** A project must appear in conversation context AND at least one other source (git or cwd) to be included. This prevents updating memory for projects that were merely mentioned.

### Phase 2: READ -- Load existing project memory

For each identified project:

1. Read the project's memory file (`project_{name}.md`) from the resolved memory directory
2. Parse the structure: frontmatter, section headings, content
3. If no file exists, note it -- a new one will be created following existing templates
4. **Size check:** Count lines. If >80 lines, flag for potential pruning during reconciliation. MEMORY.md loads the first 200 lines across all files -- bloated project files crowd out other memories.

Also read:
- `MEMORY.md` index (to check whether index updates are needed)
- The project's CLAUDE.md if you need stack/architecture context

### Phase 3: EXTRACT -- Classify and filter session events

Review the conversation and git history. For each significant event, **classify** it:

| Type | Persist? | Example |
|------|----------|---------|
| **DECISION** | Always | "Switched from session cookies to JWT for auth" |
| **STATUS_CHANGE** | Always | "Promoted to staging", "deployed to production" |
| **DISCOVERY** | If novel | "Learned Neon has a 100-connection limit on free tier" |
| **IMPLEMENTATION** | Outcome only | "Built MCP server" (not "created 12 files in src/mcp/") |
| **TROUBLESHOOTING** | Pattern only | "Vercel Blob needed for files >4.5MB" (not the 5 debugging steps) |
| **EXPLORATION** | Never | Reading docs, searching code, trying approaches that were abandoned |

Then apply the **three-gate filter** -- every item must pass ALL three:

1. **DURABILITY:** Will this still be true/relevant in 30 days?
   - YES: architecture decisions, features shipped, config changes, deployment state
   - NO: debugging steps, error messages, intermediate attempts, commands run

2. **SPECIFICITY:** Can I state this as a concrete claim with a subject, verb, and specific value?
   - YES: "Imported 457K swim results from HyTek MDB files"
   - NO: "Worked on the import system"

3. **RETRIEVAL:** Is a future session likely to need this?
   - YES: constraints, conventions, decisions with rationale, integration details
   - NO: how we discovered something, which files we read, what order we tried things

For items that pass all three, record:
- **WHAT** changed (the concrete fact)
- **WHY** it changed (the reasoning -- this is what code alone can't tell you)
- **WHAT it affects** downstream (scope of impact)

### Phase 3.5: ROUTE by layer (V2) -- repo vs local

Local memory is the *wrong* home for knowledge a clone-only agent or collaborator needs. The 2026 consensus is a three-layer split: **conventions → `CLAUDE.md`/`AGENTS.md`**, **decisions + rationale → repo `docs/decisions/` (ADRs)**, **current status/next → `docs/PROJECT_STATUS.md`** — and *local memory keeps only the residue* (personal scratch, secret-locations, cross-project notes). Before persisting each durable item, route it:

| Item | Belongs in | Action |
|---|---|---|
| Decision + rationale a teammate/remote agent needs | repo ADR (`docs/decisions/`) | write it to the repo; don't bury rationale in local memory |
| Convention / architecture rule | `CLAUDE.md` / `AGENTS.md` | suggest the edit there |
| Current state / next steps | `PROJECT_STATUS.md` if the repo uses one, else memory Status | route accordingly |
| Secret-location, personal/tooling scratch, cross-project note | **local memory only** | keep (never commit) |

This isn't extra work — it's putting each fact where the *next* reader will actually look. If the repo isn't yet set up for this (no ADRs / PROJECT_STATUS), note it and suggest creating those committed docs; until then, memory is the fallback. Memory then holds only what genuinely has no repo home. **Phase 7 acts on the `CLAUDE.md`/`AGENTS.md` items this step identifies** — handing them to the `claude-md` audit for surgical promotion.

### Phase 4: RECONCILE -- Section-aware merging

For each project memory file, classify each section by its **merge type**, then apply the appropriate strategy:

#### REPLACE sections (overwrite entirely)

**Status section** (identified by heading starting with `## Status`):
- Delete the existing Status block entirely
- Write a new one: `## Status (Mon DD, YYYY)` with 3-5 bullets
- Cover: current branch, deployment state, key metrics, immediate next steps
- **Include uncommitted work:** If `git status --porcelain` shows changes, note "N uncommitted files in working tree" to prevent confusion in the next session
- This section is always fully overwritten -- it represents current state, not history

#### MERGE-LIST sections (deduplicate, update, append)

**Backlog** (or equivalent: TODO, Next Steps, Roadmap):
- Match existing items by their core description (ignore checkbox state, dates, tags)
- Mark completed items: `- [ ]` becomes `- [x]` (keep for progress tracking)
- Add new items identified during the session
- Reorder by priority if the session revealed new priorities

**Capability sections** (What It Does, Features, Capabilities, etc.):
- Match by entity name (e.g., "MCP server", "SSE streaming")
- If the entity exists: update the bullet in place with new state
- If new: append to the section
- Never duplicate information already present

#### PRESERVE sections (touch only if explicitly changed)

**Stack, Safety, Parameters, DB, Architecture, Config** (or equivalent):
- Only modify if the session explicitly changed something in this category
- If untouched, leave the section byte-for-byte identical
- **Never regenerate these sections** -- LLM rewrites subtly lose nuance and change voice

#### Frontmatter
- Update `description` only if the project's one-liner scope changed (rare)
- Do not add or change `originSessionId`

#### Reconciliation rules
1. Never duplicate information already present
2. When updating a fact, find the existing statement and edit it in place
3. Preserve the existing file's voice and structure -- do not rewrite prose you aren't changing
4. If unsure whether something changed, leave existing text unchanged
5. New sections should follow the established pattern in that file

### Phase 5: PRESENT -- Show changes for approval

**Do not write files without showing the user what will change.**

For each project, present a clear summary of proposed changes:

```
## project_{name}.md -- Proposed Changes

### Status (full replace):
- [new status bullets]

### Backlog (N completed, M added):
- [x] Completed item (done Mon DD)
- [ ] NEW: New item description

### [Section Name] (N updates):
- Added: [item]
- Changed: [old] -> [new]

### Size: current NN lines -> proposed NN lines
```

Then ask: **"Apply these changes?"**
- **Yes** -- apply all
- **Edit** -- let the user modify before applying
- **Skip [project]** -- skip a specific project

On approval, use the Edit tool for surgical section updates. For the Status section, replace the entire block. **Never rewrite sections that didn't change.**

### Phase 6: INDEX -- Update MEMORY.md

If any new memory files were created:
1. Add an entry to the `## Projects` section of MEMORY.md
2. Follow the existing format: `- [Project Name](memory/project_name.md) -- one-line description`
3. Keep alphabetical order within the section
4. **Line count check:** If MEMORY.md exceeds 180 lines, warn that it's approaching the 200-line context load limit

### Phase 7: CLAUDE.md AUDIT -- Promote cross-agent lessons (optional; needs the `claude-md` skill)

Memory captured this session's *reasoning*. But some of what Phase 3.5 routed isn't memory's job -- it's a **convention or architecture rule every agent and teammate needs**, which belongs in the committed `CLAUDE.md`/`AGENTS.md`: the cross-agent layer a fresh clone or a different agent reads first. Lessons stranded in local memory are invisible to them, and get silently dropped when someone re-runs `/init`.

For each touched project that has (or should have) a `CLAUDE.md` / `AGENTS.md`:

1. **Collect the CLAUDE.md-worthy items** surfaced in Phase 3.5 -- conventions, architecture rules, "always/never" guidance that emerged this session and a *different* agent would need. (If Phase 3.5 surfaced none, skip this phase.)
2. **Hand off to `claude-md` if it's installed** (it ships alongside this skill in `ngmeyer/skills`): run `/claude-md audit` (drift, leaked secrets, bloat across all CLAUDE.md files) or `/claude-md improve <path>` (measure one file against best practices, propose surgical diffs), seeding it with the items from step 1. `claude-md` already gates every diff on your approval.
3. **If `claude-md` is absent, degrade gracefully:** print the items -- *"N convention(s) from this session may belong in CLAUDE.md; install `claude-md` or add them by hand"* -- so nothing is lost. Never block on it.

**Never run `/init` to update an existing CLAUDE.md.** `/init` *regenerates* the file wholesale: it invents architecture sections and discards the curated, hard-won lessons that were never written into it. This phase is **surgical promotion** (add the few lines that earned their place, leave the rest byte-for-byte), not regeneration. If a project has no `CLAUDE.md` yet, *suggest* a minimal one -- don't auto-generate a large one.

This is a **soft dependency by design** -- it degrades to a printed list when `claude-md` is absent, so session-close stays self-contained for a cherry-picked install.

### Phase 8: CLEANUP -- Offer to remove artifacts

Check for and offer to delete:

1. **Session-specific plan files** in `~/.claude/plans/` where all tasks are completed
2. **Session dump memory files** (like `project_session_*.md`) whose content has been reconciled into per-project files
3. **Completed task directories** in `~/.claude/tasks/` where all tasks show status `completed`
4. **Stale Status sections** in other project files: if any project file has a Status section dated >30 days ago, flag it for review

**Always ask before deleting.** Present the cleanup list and wait for confirmation.

## Gotchas

- **No session dumps.** Never create `project_session_*.md` files -- this is the anti-pattern the skill exists to prevent
- **No session framing.** Never write "In the April 11 session, we..." -- write state, not history
- **No implementation details.** Don't include file paths, line numbers, or function names unless they are architectural landmarks. Code captures outcomes; memory captures reasoning
- **No silent writes.** Always show the diff preview and get approval before modifying memory files
- **No forced updates.** If the session had zero durable outcomes (pure debugging, research, or exploration that was abandoned), report "No durable state changes detected" and exit
- **No scope creep.** Only update `project_*.md` files -- do not touch feedback, user, or reference memory files
- **No remote calls.** Don't fetch from git remotes or make network requests. Use local state only
- **No phantom projects.** Don't create memory for projects that were mentioned but not worked on
- **No date-stamped items** in capability or stack sections. Dates belong only in the Status section
- **No section regeneration.** Never rewrite a section you aren't changing. LLM rewrites subtly lose detail, change voice, and introduce drift. Use the Edit tool on specific lines, not Write on the whole file
- **No vague summaries.** "Worked on auth improvements" fails the specificity gate. Every persisted fact must have a subject, verb, and concrete value
- **Never `/init` to refresh an existing CLAUDE.md.** It regenerates wholesale and drops the curated lessons that lived only in memory. Promote to CLAUDE.md surgically via the `claude-md` skill (Phase 7), never by regeneration. Memory is for reasoning; CLAUDE.md/AGENTS.md is the cross-agent convention layer -- keep each in its lane

## Section Naming Conventions

The reconciliation logic matches sections by these patterns. Your memory files should use these headings (or close equivalents):

| Merge Type | Section Headings (matched flexibly) |
|------------|-------------------------------------|
| **REPLACE** | `## Status`, `## Current Status` |
| **MERGE-LIST** | `## Backlog`, `## TODO`, `## Next Steps`, `## Roadmap`, `## What It Does`, `## Features`, `## Capabilities` |
| **PRESERVE** | `## Stack`, `## Architecture`, `## Safety`, `## Config`, `## Parameters`, `## Database` |

Sections not matching any pattern are treated as PRESERVE (safe default).

## Edge Cases

**No existing memory file:** Create a new one following the template from existing project files (frontmatter + sections for What It Does, Stack, Status, Backlog). Present the full new file for approval.

**Zero durable outcomes:** Report "No durable state changes detected for any project. Nothing to update." Exit cleanly. This is the correct outcome for debugging sessions, research/reading sessions, or exploration that was abandoned. Do not force an update.

**Conflicting information:** Flag conflicts between conversation and git to the user. Example: "Conversation mentions deploying to Fly.io, but no deployment commits found. Include in status update?"

**Multi-project session from home dir:** Process each project independently. This is exactly what prevents the session-dump anti-pattern.

**Very large session (4+ hours):** Process projects sequentially, not all at once. Present one project's changes at a time.

**File exceeds 80 lines after update:** Warn the user and suggest pruning completed backlog items or compressing verbose sections. Project files should be lean -- they compete for the 200-line MEMORY.md context budget.

**Uncommitted work detected:** Always include in Status section. Previous sessions have lost track of uncommitted work, causing confusion in the next session.

## Changelog

### V2.1 (2026-06-11) -- CLAUDE.md audit handoff (Phase 7)
Added **Phase 7: CLAUDE.md AUDIT**. After reconciling memory, promote the cross-agent conventions Phase 3.5 identified into the committed `CLAUDE.md`/`AGENTS.md` by handing off to the **`claude-md`** skill's surgical, approval-gated `audit`/`improve` -- never `/init`, which regenerates the file and drops curated lessons that lived only in memory. Closes the loop Phase 3.5 opened: it *identified* CLAUDE.md-worthy items but nothing *acted* on them. **Soft dependency** -- degrades to a printed list when `claude-md` isn't installed, so session-close stays self-contained; both skills ship in `ngmeyer/skills`, so the sibling reference is safe. CLEANUP renumbered 7 -> 8.

### V2 (2026-05-27)
Optimized via `skillforge optimize` (outcome research: AI agent memory / context engineering 2026).
- **Phase 3.5 ROUTE by layer** — route durable items to their right home (conventions→CLAUDE.md/AGENTS.md, decisions→repo ADRs, status→PROJECT_STATUS) instead of defaulting everything into local memory; memory keeps only the residue. The three-layer split is the 2026 engineering consensus.
- Reinforces the existing "not a dump" / size-check rules with the documented reason: context rot (quality degrades as memory bloats), and selective memory is ~10–20× cheaper than fat context.
- Outcome target: resume-critical knowledge ends up where *any* agent or teammate will find it, not siloed in one machine's local memory. Sources: [State of AI Agent Memory 2026 (mem0)](https://mem0.ai/blog/state-of-ai-agent-memory-2026); [Agent Memory vs Context Engineering (Augment)](https://www.augmentcode.com/guides/agent-memory-vs-context-engineering).

## Credits

Skill by: Neal Meyer
