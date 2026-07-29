---
name: session-close
description: >
  Close a work session two ways: reconcile durable outcomes into persistent
  project memory (section-aware merging, not a session dump), then run an
  After Action Review -- what was supposed to happen vs what did, why the
  difference, what to sustain or improve -- so the next session works better
  than this one. Captures dead ends so failed approaches are never retried,
  and promotes proven lessons into CLAUDE.md behind a strict gate.
  Use when: 'session close', 'close session', 'save session', 'update memory',
  'wrap up', 'end of session', 'after action review', 'AAR', 'retro this
  session', 'what did we learn', or before ending a big session.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "Agent"]
argument-hint: "[optional: project name if not obvious from cwd/context]"
---

# /session-close -- Reconciliation + After Action Review

Close a session on two axes:

1. **State reconciliation** -- fold durable outcomes into persistent project memory. Not session logging; the output should be indistinguishable from a human updating project memory after a week of work.
2. **After Action Review** -- compare what the session was *supposed* to do against what it *did*, name why they differ, and turn that into one or two changes that make the next session better.

The first answers *"what is this project?"* The second answers *"how do we work on it better?"* Both are durable; neither is a diary.

## Core Principle

**Code captures outcomes; memory captures reasoning; the AAR captures the delta.** Git already records what changed. Project memory captures *why* decisions were made, *what state* the project is in, and *what comes next*. The AAR captures the gap between intent and result -- the only one of the three that improves how the next session runs, and the only one nothing else in the toolchain records.

Two corollaries drive the procedure:

- **A failed approach is knowledge.** The costliest cross-session failure is re-attempting a fix that already failed, because a fresh session has no memory of it. Dead ends persist as one-line conclusions.
- **A lesson has to cost something to earn promotion.** Every line added to `CLAUDE.md` is a token the model burns before reaching the task. Unearned lessons make the agent worse, not better -- so promotion is gated, and the default is no.

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

5. **Carry forward the open AAR items.** Scan the Backlog for entries tagged `PROCESS:` or `DEAD-END:` -- these are Improve items and dead ends from previous closes that haven't been resolved or promoted. Note each one, and how many closes it has survived. Phase 4 needs them to detect recurrence, close what got fixed, and kill what turned out to be noise. Without this step the AAR has no memory and repeats itself forever.

Also read:
- `MEMORY.md` index (to check whether index updates are needed)
- The project's CLAUDE.md if you need stack/architecture context -- and, in Phase 4, to check whether a lesson is already covered

### Phase 3: EXTRACT -- Classify and filter session events

Review the conversation and git history. For each significant event, **classify** it:

| Type | Persist? | Example |
|------|----------|---------|
| **DECISION** | Always | "Switched from session cookies to JWT for auth" |
| **STATUS_CHANGE** | Always | "Promoted to staging", "deployed to production" |
| **DISCOVERY** | If novel | "Learned Neon has a 100-connection limit on free tier" |
| **IMPLEMENTATION** | Outcome only | "Built MCP server" (not "created 12 files in src/mcp/") |
| **TROUBLESHOOTING** | Pattern only | "Vercel Blob needed for files >4.5MB" (not the 5 debugging steps) |
| **DEAD_END** | Conclusion only | "Raising the timeout and indexing the column both failed -- the cost was an N+1 in the serializer" |
| **EXPLORATION** | Never | Reading docs, searching code, the order approaches were tried |

**`DEAD_END` is the one type that survives the "don't persist exploration" rule**, and the distinction is sharp: discard the *process* of exploring, persist the *conclusion*. "Approach X does not work here **because** Y" -- one line, always with the reason, because a dead end without a reason leaves the next session unable to tell whether the constraint still applies. These feed Phase 4, which routes them.

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

This isn't extra work — it's putting each fact where the *next* reader will actually look. If the repo isn't yet set up for this (no ADRs / PROJECT_STATUS), note it and suggest creating those committed docs; until then, memory is the fallback. Memory then holds only what genuinely has no repo home. **Phase 8 acts on the `CLAUDE.md`/`AGENTS.md` items this step identifies** — handing them to the `claude-md` audit for surgical promotion.

### Phase 4: AAR -- Review the session against its intent

Phase 3 harvested *what the project now is*. This phase asks *how the session went*, using the four After Action Review questions. Keep it short: an AAR is minutes, not a narrative. Depth, mechanism taxonomy, and worked examples live in [references/aar-playbook.md](references/aar-playbook.md).

**Run one AAR per project, not one per session.** A session that touched two repos has two intents and two deltas; merging them produces a mechanism that fits neither and an Improve item that lands in the wrong `CLAUDE.md`. Same rule as Phase 1's convergence check -- projects stay independent all the way through.

**Q1. What was supposed to happen?** Recover the session's intent from the opening ask plus any mid-session redirection. One line. If intent legitimately changed, record both and the pivot -- a stated change of direction is not drift; an unstated one is.

**Q2. What actually happened?** One line, from git plus conversation. The outcome, not a chronology.

**Q3. Why the difference?** Only if Q1 and Q2 diverge. Name the **mechanism**, never the actor:

`missing context` · `wrong assumption` · `untested hypothesis chain` · `scope drift` · `blocked dependency` · `recurring known issue` · `steering correction`

If Q1 and Q2 match, say so in one line and move to Q4. A session that went to plan is a real and common result.

**Q4. Sustain / Improve.**

- **Sustain** -- a non-obvious practice that measurably helped. Most sessions produce none. Don't list "wrote tests."
- **Improve** -- **at most 3**, each written as `mechanism -> concrete change -> home`. Example: `missing context -> read the deploy README before editing config -> CLAUDE.md rule`.

**Zero Improve items is a valid and frequent outcome.** Filling three slots because the template has three is how an AAR becomes theater.

#### Route each Improve item

| The item is | Home |
|---|---|
| A rule any agent working this repo needs | `CLAUDE.md` -- via Phase 8, if it passes the gate below |
| A first occurrence, not yet proven | Backlog, tagged `PROCESS:` |
| Blocked on tooling that doesn't exist | Backlog, tagged `PROCESS:`, noted as a skill idea |
| A dead end worth never retrying (from Phase 3) | `CLAUDE.md` if it's a durable rule, else Backlog, tagged `DEAD-END:` |

#### Promotion gate -- all four must hold

Before anything reaches `CLAUDE.md`:

1. **Behavior-changing** -- had this line been in `CLAUDE.md` this morning, the session would have gone differently. If you can't say how, it fails.
2. **Recurrent or costly** -- it matched an open `PROCESS:` item (so it has now bitten twice), or it cost this session real time.
3. **Not already covered** -- grep `CLAUDE.md` / `AGENTS.md` first. A near-duplicate gets **merged into the existing line**, never appended alongside it.
4. **Stated as a rule** -- imperative and checkable. "Read `X` before changing `Y`," not "be careful with config."

An item that fails the gate is **not discarded** -- it goes to the Backlog as a `PROCESS:` item and gets another chance next close. Nothing evaporates silently.

#### Closure, escalation, and zombies

Using the carry-forward from Phase 2:

- **Recurred** -- this session's Q3 mechanism matches an open `PROCESS:` item. It now satisfies gate #2. **Escalate it** to `CLAUDE.md` via Phase 8.
- **Resolved** -- the change was made this session. Check it off.
- **Zombie** -- open across 3 closes and never recurred. **Kill it** and say so. Stale process items train the reader to skim the whole section.

**Blameless by construction.** Name the mechanism, not the actor. "Config location wasn't verified before editing" -- not "I stupidly assumed," and not "the prompt was unclear." Both of those end the analysis before it produces a change you can make. When ambiguity genuinely caused the delta, the Improve item is the clarifying question to ask next time, stated neutrally.

### Phase 5: RECONCILE -- Section-aware merging

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
- **Apply Phase 4's AAR items here.** Unpromoted Improve items enter as `- [ ] PROCESS: <rule>`; dead ends that didn't earn a `CLAUDE.md` line enter as `- [ ] DEAD-END: <approach> failed because <reason>`. Resolved ones get checked off; zombies (open 3 closes, never recurred) are deleted outright rather than left to rot

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

### Phase 6: PRESENT -- Show changes for approval

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

Then the AAR, as its own block -- it is reviewed separately because it proposes changes to *how you work*, not to what the project is:

```
## After Action Review

Intent:   [Q1 -- one line]
Actual:   [Q2 -- one line]
Delta:    [Q3 -- mechanism, or "went to plan"]

Sustain:  [0-1 items, or "none"]
Improve:  [0-3 items as: mechanism -> change -> home]

Carry-forward: N resolved, N recurring (escalating), N killed as zombies
Promoting to CLAUDE.md: [items passing all 4 gate checks, or "none"]
```

If the AAR produces nothing on every line, print `AAR: session went to plan, no process changes` and move on. That is a clean result, not a skipped step.

Then ask: **"Apply these changes?"**
- **Yes** -- apply all
- **Edit** -- let the user modify before applying
- **Skip [project]** -- skip a specific project

On approval, use the Edit tool for surgical section updates. For the Status section, replace the entire block. **Never rewrite sections that didn't change.**

### Phase 7: INDEX -- Update MEMORY.md

If any new memory files were created:
1. Add an entry to the `## Projects` section of MEMORY.md
2. Follow the existing format: `- [Project Name](memory/project_name.md) -- one-line description`
3. Keep alphabetical order within the section
4. **Line count check:** If MEMORY.md exceeds 180 lines, warn that it's approaching the 200-line context load limit

### Phase 8: CLAUDE.md AUDIT -- Promote cross-agent lessons (optional; needs the `claude-md` skill)

Memory captured this session's *reasoning*. But some of what Phases 3.5 and 4 routed isn't memory's job -- it's a **convention or architecture rule every agent and teammate needs**, which belongs in the committed `CLAUDE.md`/`AGENTS.md`: the cross-agent layer a fresh clone or a different agent reads first. Lessons stranded in local memory are invisible to them, and get silently dropped when someone re-runs `/init`.

For each touched project that has (or should have) a `CLAUDE.md` / `AGENTS.md`:

1. **Collect the promotable items** from two sources: Phase 3.5's conventions and architecture rules, plus Phase 4's Improve items and dead ends that **passed all four gate checks**. (If neither phase surfaced any, skip this phase.) Phase 4's gate is what keeps this list short -- promote the two lines that earned it, not the ten that sounded useful.
2. **Merge, don't append.** For each item, check whether a near-duplicate rule already exists. If it does, tighten the existing line instead of adding a second one. Two rules saying almost the same thing is the interference failure mode -- it makes both less likely to be followed.
3. **Hand off to `claude-md` if it's installed** (it ships alongside this skill in `ngmeyer/skills`): run `/claude-md audit` (drift, leaked secrets, bloat across all CLAUDE.md files) or `/claude-md improve <path>` (measure one file against best practices, propose surgical diffs), seeding it with the items from step 1. `claude-md` already gates every diff on your approval.
4. **If `claude-md` is absent, degrade gracefully:** print the items -- *"N convention(s) from this session may belong in CLAUDE.md; install `claude-md` or add them by hand"* -- so nothing is lost. Never block on it.

**Never run `/init` to update an existing CLAUDE.md.** `/init` *regenerates* the file wholesale: it invents architecture sections and discards the curated, hard-won lessons that were never written into it. This phase is **surgical promotion** (add the few lines that earned their place, leave the rest byte-for-byte), not regeneration. If a project has no `CLAUDE.md` yet, *suggest* a minimal one -- don't auto-generate a large one.

This is a **soft dependency by design** -- it degrades to a printed list when `claude-md` is absent, so session-close stays self-contained for a cherry-picked install.

### Phase 9: CLEANUP -- Offer to remove artifacts

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
- **No AAR theater.** Never manufacture three Improve items because the template shows three. Most clean sessions yield zero. A forced item is worse than none -- it dilutes the ones that matter
- **No blame in either direction.** "I stupidly assumed X" and "the prompt was ambiguous" are the same failure: both end the analysis before it reaches a change you can make. Name the mechanism
- **No narrative in Q2.** "What actually happened" is one line -- the outcome. The moment it becomes a chronology, the AAR has turned into the session dump this skill exists to prevent
- **No promoting taste.** A one-off preference the user expressed isn't a project rule. Promote a steering correction only when it encodes a durable constraint a future agent would need
- **No silent discard of Improve items.** An item that fails the promotion gate goes to the Backlog as `PROCESS:`. It gets another chance next close, or gets explicitly killed as a zombie -- it never just disappears
- **No dead end without a reason.** "Tried Temporal, didn't work" is useless. The reason is the entire value: it tells the next session whether the constraint still applies
- **Never `/init` to refresh an existing CLAUDE.md.** It regenerates wholesale and drops the curated lessons that lived only in memory. Promote to CLAUDE.md surgically via the `claude-md` skill (Phase 8), never by regeneration. Memory is for reasoning; CLAUDE.md/AGENTS.md is the cross-agent convention layer -- keep each in its lane

## Section Naming Conventions

The reconciliation logic matches sections by these patterns. Your memory files should use these headings (or close equivalents):

| Merge Type | Section Headings (matched flexibly) |
|------------|-------------------------------------|
| **REPLACE** | `## Status`, `## Current Status` |
| **MERGE-LIST** | `## Backlog`, `## TODO`, `## Next Steps`, `## Roadmap`, `## What It Does`, `## Features`, `## Capabilities` |
| **PRESERVE** | `## Stack`, `## Architecture`, `## Safety`, `## Config`, `## Parameters`, `## Database` |

Sections not matching any pattern are treated as PRESERVE (safe default).

**AAR item tags** live inside the Backlog rather than in a section of their own, so they inherit MERGE-LIST dedup and survive across closes:

| Tag | Means | Lifecycle |
|---|---|---|
| `PROCESS:` | An unpromoted Improve item | Recurs -> escalate to CLAUDE.md · Resolved -> check off · Open 3 closes without recurring -> kill |
| `DEAD-END:` | An approach that failed, plus why | Stays until the constraint provably changes, then delete with a note |

## Edge Cases

**No existing memory file:** Create a new one following the template from existing project files (frontmatter + sections for What It Does, Stack, Status, Backlog). Present the full new file for approval.

**Zero durable outcomes:** Report "No durable state changes detected for any project. Nothing to update." **But still run Phase 4** -- a session that produced no state change often produced the most useful AAR, because the delta between intent and outcome is exactly what's worth examining. A pure-reading session that answered the question went to plan and closes clean; a debugging session that changed nothing in four hours has dead ends worth recording. Do not force a memory update; do not skip the review.

**Abandoned exploration:** The old rule was "never persist." That holds for the *process*, and inverts for the *conclusion*. A spike that hit a wall produces one `DEAD_END` line naming the constraint that stopped it -- otherwise the next session re-runs the same spike.

**Session ended mid-task:** Q1 and Q2 diverge because the work is unfinished, not because anything went wrong. Record the intent, the actual stopping point, and the state of the working tree in Status. The mechanism is "interrupted," and it usually yields no Improve item.

**Conflicting information:** Flag conflicts between conversation and git to the user. Example: "Conversation mentions deploying to Fly.io, but no deployment commits found. Include in status update?"

**Multi-project session from home dir:** Process each project independently. This is exactly what prevents the session-dump anti-pattern.

**Very large session (4+ hours):** Process projects sequentially, not all at once. Present one project's changes at a time.

**File exceeds 80 lines after update:** Warn the user and suggest pruning completed backlog items or compressing verbose sections. Project files should be lean -- they compete for the 200-line MEMORY.md context budget.

**Uncommitted work detected:** Always include in Status section. Previous sessions have lost track of uncommitted work, causing confusion in the next session.

## Changelog

### V3 (2026-07-26) -- After Action Review + negative knowledge

Optimized via `skillforge optimize` (outcome research: AAR doctrine, incident-postmortem practice, agent procedural memory). V2.1 answered *"what is this project?"* well and *"how do we work on it better?"* not at all. Four evidence-backed changes:

- **Phase 4: AAR** -- the four doctrinal questions (intent · actual · why the difference · sustain/improve), bounded at 3 Improve items with zero as a valid answer, blameless by naming the mechanism rather than the actor. V2.1 harvested outcomes but never computed the intent-vs-actual delta, which is where the learning lives. Source: [CALL four-question AAR](https://www.citygov.com/article/beyond-what-went-wrong-the-four-question-aar-playbook-every-leader-should-steal-from-the-army), [FM 7-0 App. K](https://www.first.army.mil/Portals/102/FM%207-0%20Appendix%20K.pdf).
- **`DEAD_END` event type** -- fixes a real defect. V2.1 classified abandoned approaches as `EXPLORATION -> never persist`, but the costliest cross-session failure for coding agents is re-attempting fixes that already failed. Now the *conclusion* persists ("X fails because Y") while the *process* is still discarded. Source: [PROJECTMEM, arXiv 2606.12329](https://arxiv.org/pdf/2606.12329).
- **Four-check promotion gate before anything reaches CLAUDE.md** -- behavior-changing, recurrent-or-costly, not-already-covered, stated-as-a-rule; near-duplicates merge rather than append. Auto-appending lessons is actively harmful: across 2,303 context files from 1,925 repos, LLM-generated context files cut task success ~2-3% and raised cost >20%. Sources: [arXiv 2511.12884](https://arxiv.org/pdf/2511.12884), [CODESKILL, arXiv 2605.25430](https://arxiv.org/pdf/2605.25430) (utility-gated retention, merge, prune).
- **Closure loop via `PROCESS:` / `DEAD-END:` backlog tags** -- Phase 2 carries open items forward so Phase 4 can escalate what recurred, check off what got fixed, and kill what turned out to be noise. The measure of a retrospective practice isn't documents written, it's whether the same contributing factor reappears; untracked action items produce nothing. Reuses existing MERGE-LIST machinery, so no new memory sections. Source: [incident.io](https://incident.io/blog/sre-incident-postmortem-best-practices), [Retrium](https://www.retrium.com/ultimate-guide-to-agile-retrospectives/retrospective-anti-patterns).

Phases renumbered 4-8 -> 5-9. AAR depth in [references/aar-playbook.md](references/aar-playbook.md).

**Measured:** 10 synthetic session transcripts (clean feature · thrashing debug · abandoned spike · scope drift · zero-outcome · recurring failure · multi-project · wrong assumption · interrupted · user-corrected), frozen before V3 was authored and split 5 tuning / 5 held-out. Weighted rubric across delta-surfaced, negative-knowledge, improve-actionability, restraint, and state-reconciliation: **V2.1 3.00 -> V3 4.74 on tuning, 2.53 -> 4.60 on held-out validation.** The validation gain (+2.07) exceeding the tuning gain (+1.74) is the anti-overfit signal. V2.1 scores near-ceiling on state reconciliation and restraint; the entire delta comes from the three axes it has no procedure for. Validation also surfaced one real defect -- the AAR didn't specify per-project scope on multi-repo sessions -- fixed after scoring. Caveat: the playbook's two worked examples mirror tuning transcripts, so tuning scores are inflated; validation is uncontaminated.

### V2.1 (2026-06-11) -- CLAUDE.md audit handoff (Phase 7)
Added **Phase 7: CLAUDE.md AUDIT**. After reconciling memory, promote the cross-agent conventions Phase 3.5 identified into the committed `CLAUDE.md`/`AGENTS.md` by handing off to the **`claude-md`** skill's surgical, approval-gated `audit`/`improve` -- never `/init`, which regenerates the file and drops curated lessons that lived only in memory. Closes the loop Phase 3.5 opened: it *identified* CLAUDE.md-worthy items but nothing *acted* on them. **Soft dependency** -- degrades to a printed list when `claude-md` isn't installed, so session-close stays self-contained; both skills ship in `ngmeyer/skills`, so the sibling reference is safe. CLEANUP renumbered 7 -> 8.

### V2 (2026-05-27)
Optimized via `skillforge optimize` (outcome research: AI agent memory / context engineering 2026).
- **Phase 3.5 ROUTE by layer** — route durable items to their right home (conventions→CLAUDE.md/AGENTS.md, decisions→repo ADRs, status→PROJECT_STATUS) instead of defaulting everything into local memory; memory keeps only the residue. The three-layer split is the 2026 engineering consensus.
- Reinforces the existing "not a dump" / size-check rules with the documented reason: context rot (quality degrades as memory bloats), and selective memory is ~10–20× cheaper than fat context.
- Outcome target: resume-critical knowledge ends up where *any* agent or teammate will find it, not siloed in one machine's local memory. Sources: [State of AI Agent Memory 2026 (mem0)](https://mem0.ai/blog/state-of-ai-agent-memory-2026); [Agent Memory vs Context Engineering (Augment)](https://www.augmentcode.com/guides/agent-memory-vs-context-engineering).

## Credits

Skill by: Neal Meyer
