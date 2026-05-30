---
name: adversarial-review
description: >
  Single-critic adversarial stress test of a known artifact — a PR, draft, spec, plan, code file, or argument.
  The reviewer actively tries to break it: edge cases, hidden assumptions, failure modes, logical inconsistencies,
  security gaps, scalability cliffs, surprising user behavior, counter-examples. Distinct from /council-review,
  which is for OPEN questions and decisions; this skill is for stress-testing a finished thing.
  Use when: 'adversarial review', 'red team this', 'find what is wrong', 'tell me why this is wrong',
  'pre-mortem this', 'attack this', 'stress test', 'devil's advocate', 'try to break this',
  or before shipping any artifact where a missed edge case is expensive.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "Agent"]
argument-hint: "[file path, PR number, GitHub URL, or pasted artifact] [--security] [--logic] [--user] [--scale] [--quick]"
---

# /adversarial-review -- Single-Critic Stress Test

Stress-test a known artifact by actively trying to break it. The reviewer's job is to be the smartest critic in the room — not balanced, not constructive, not polite. Adversarial.

## When to Use This vs /council-review

| Tool | Use For | Mode |
|---|---|---|
| **`/adversarial-review`** | Stress-testing a *known artifact* (PR, draft, spec, plan, argument) | Single-critic, attack-focused |
| **`/council-review`** | Open questions, decisions, "what should we do?" | Multi-agent, collaborative DMAD |

If the input is a question without a proposed answer, redirect to `/council-review`. If the input is a finished thing the user wants probed for flaws, this is the right tool.

Empirical note: M3MADBench (2026) shows multi-agent *adversarial* debate underperforms multi-agent *collaborative* debate for open questions. Single-critic adversarial probing is a different operation — and the right tool when the goal is to find specific flaws in a specific artifact rather than synthesize a verdict across viewpoints.

## Why This Works

The strongest practitioners ask the model what is *wrong* with their work, not what is right. Most users use AI to confirm their thinking. Adversarial-review forces disconfirmation. The same model that produces fluent agreement on demand will, when prompted correctly, dismantle the same argument with equal speed.

Inspired by:
- Codex Review Plugin's `/codex:adversarial-review` mode — probes edge cases, questions architectural decisions, plays devil's advocate
- The "tell me why I'm wrong" prompting practice
- Pre-mortem methodology — assume the artifact failed; trace backward

## Arguments

- **Argument 1 (required):** The artifact to review. One of:
  - File path (`docs/spec.md`, `src/auth.ts`)
  - PR number or URL (`123`, `https://github.com/org/repo/pull/123`)
  - Pasted text in quotes
- **Flags (optional, composable):**
  - `--security` — prioritize attack surface, auth gaps, input validation, secret handling
  - `--logic` — prioritize logical inconsistencies, missing cases, unstated assumptions
  - `--user` — prioritize UX gaps, footguns, surprising behavior, accessibility
  - `--scale` — prioritize what breaks at 10× or 100× expected load, concurrency, contention
  - `--quick` — single attack pass, severity-ranked findings, no deep dives (cheap mode)

When no flag is set, all five attack vectors run. Flags narrow the focus.

## Procedure

### Phase 1: SCOPE — Validate that this is the right tool

1. Parse flags from `$ARGUMENTS`.
2. Classify the input:
   - **PR** — Numeric value, or URL containing `/pull/`. Fetch via `gh pr view --json title,body && gh pr diff`.
   - **File path** — String resolving to an existing file. Read the file.
   - **Pasted text** — Treat as the artifact itself.
3. **Reject open questions.** If the input is phrased as a question without a proposed answer ("Should we use GraphQL?", "What's the best way to..."), redirect:
   > *"This is an open question, not an artifact. Use `/council-review` for decisions and `/adversarial-review` for stress-testing a specific draft, PR, spec, or plan."*
   Do not proceed.
4. **Confirm the scope.** Say back to the user one sentence: *"Reviewing [artifact] for [attack vectors enabled]. Looking for what's wrong, not what's right."*

### Phase 2: READ — Load the full artifact + context

For PRs:
- `gh pr view <id> --json title,body,baseRefName,headRefName,changedFiles`
- `gh pr diff <id>`
- Read any context files referenced in the PR body

For file paths:
- Read the full file
- Read sibling files if the artifact references them
- Read project `CLAUDE.md` / `AGENTS.md` if present (for convention context)

For pasted text:
- Use as-is

### Phase 3: ATTACK — Run adversarial probes

Default behavior (no flag): run **all five** attack vectors as parallel sub-agents OR as a single agent with structured sections (your call based on artifact size — sub-agents for >500 LOC, single agent otherwise).

Each attack vector has a focused prompt:

#### `--security` (or default)

```
You are a security reviewer trying to break this artifact. Find:
- Auth gaps: missing checks, broken object-level authorization, IDOR potential
- Input validation failures: injection, untrusted-input flow, type confusion
- Secret handling: hardcoded secrets, secret-in-logs, secret-in-error-messages
- External API trust: assuming responses are well-formed, missing timeouts
- Data exposure: PII in responses, over-fetching, sensitive errors

For each finding: severity (CRITICAL/HIGH/MEDIUM/LOW), specific location (file:line if applicable), reproduction sketch, and the fix in one sentence.

Do not list things that are already secure. Do not pad the report. If you find nothing, say "no findings in this dimension" and move on.
```

#### `--logic` (or default)

```
You are a logician reviewing this artifact. Find:
- Missing cases: state combinations the artifact doesn't handle (null, empty, max-int, negative, concurrent)
- Unstated assumptions: things the author treats as obvious that aren't
- Internal contradictions: claim X in one section, claim ~X in another
- Off-by-one and boundary errors
- Ordering: race conditions, dependency cycles, lock ordering
- Counter-examples: an input that breaks the central claim

For each finding: a concrete adversarial example, why it breaks the artifact, and the smallest fix.
```

#### `--user` (or default)

```
You are a user encountering this for the first time, trying to use it incorrectly. Find:
- Footguns: things that look fine but cause silent damage
- Surprising defaults: behavior the user doesn't expect from the docs/UI
- Confirmation traps: irreversible actions that look reversible (or vice versa)
- Accessibility: keyboard-only use, screen reader, color-only signaling
- Error states: what happens when the user does the wrong thing? Is the recovery path clear?

For each finding: the specific user action, the surprising or harmful outcome, and the fix.
```

#### `--scale` (or default)

```
You are a system reviewer asking: what breaks at 10× or 100× the expected load? Find:
- Algorithmic cliffs: O(n²) or worse hidden in normal-looking code
- Memory growth: unbounded caches, accumulating state, missing cleanup
- Database hot spots: missing indexes, N+1 queries, table-locking transactions
- Concurrency: shared mutable state, race conditions, lock contention
- External dependencies: rate limits, fan-out blast radius, retry storms
- Single points of failure

For each finding: the failure mode, the rough threshold (rows / users / RPS), and the fix.
```

#### Universal probe (always run unless `--quick`)

```
You are the harshest reviewer this artifact will ever see. Beyond the categories above, find:
- The thing the author was avoiding thinking about
- The simplest counter-example to the central claim
- The version of the artifact that exists in 30 days, after one round of feedback — what changed and why?
- The strongest argument *against* the artifact's central thesis
- The "we'll handle it later" item that becomes a real problem

Be specific. No abstract concerns.
```

#### Escalation probe (V2 — always run unless `--quick`)

Single-pass review misses the failure modes that only appear over a *sequence* of interactions — the documented blind spot of static, single-turn evaluation. Probe the artifact dynamically:

```
Single inputs may look safe; sequences break. Find the multi-step failure:
- What's the 2-4 step interaction that compounds into a failure no single step triggers? (state accretion, retry storms, partial-failure left mid-way, auth downgraded across a flow)
- What does a user/attacker do AFTER the first thing works — and where does step N break what step 1 established?
- Where does the artifact assume a clean single attempt but production delivers retries, reorders, or interleaving?

Give the concrete step sequence and the state at each step up to the break.
```

### Phase 4: TRIAGE — Categorize and rank

Group every finding into one of three severity tiers:

| Tier | Definition | Action |
|---|---|---|
| **CRITICAL** | Will fail in production / break safety / breach security under realistic conditions | Fix before shipping |
| **IMPORTANT** | Will degrade quality / cause real bugs in edge cases / confuse users | Fix in the next pass |
| **NIT** | Style, polish, minor inconsistency | Optional |

Within each tier, rank by likelihood × blast radius. Drop findings that are pure speculation or "you could imagine a scenario where..." — keep only findings backed by a concrete example.

**(V2) Validation gate — confirm before you escalate.** For every CRITICAL (and ideally each IMPORTANT), state the *exact* reproduction and mentally re-run it against the artifact: does the trigger actually reach the failure given the code/spec as written, or does an existing guard already stop it? Demote or drop any finding that doesn't survive this re-test. Automated red-teaming's edge is *validated* findings with reproductions, not raw volume — an unreproducible CRITICAL costs more trust than it's worth. Mark each surviving finding `[reproduced]`.

### Phase 5: PRESENT — Surface findings with reproduction

Output structure:

```
## Adversarial Review: [Artifact Name]

**Attack vectors run:** [list of dimensions]
**Findings:** [N CRITICAL / M IMPORTANT / K NIT]

---

### CRITICAL (N)

#### [1] [One-line title — what breaks]
**Location:** [file:line or section]
**Trigger:** [the specific input/condition that breaks the artifact]
**What breaks:** [the failure mode, in one sentence]
**Fix sketch:** [one sentence — what to change]

[Repeat per CRITICAL finding]

---

### IMPORTANT (M)

[Same structure, one tier down]

---

### NIT (K)

[One-line bullets, no expanded structure]

---

### What I Could Not Break

[2-3 sentences naming the strongest parts of the artifact — the parts that resisted attack. This is calibration, not flattery: it tells the user where the artifact is genuinely strong.]

---

### What This Review Did NOT Cover

[Honesty section. List dimensions you did not probe — usually because they require runtime testing, user research, or knowledge the artifact doesn't include. Saves the user from assuming "no findings" means "no risks".]
```

### Phase 6: PRESENT — Show in chat + offer to save

Print the full report inline. Offer to save to `<cwd>/adversarial-review-<artifact-slug>-<date>.md` if the artifact was a file or PR.

## Gotchas

- **Do not be balanced.** This is the adversarial role. The artifact's defenders already exist; this skill exists to find what they missed.
- **Do not pad findings.** If a dimension produced nothing, say so. Five fluffy findings beat ten real ones less than zero.
- **Do not speculate without an example.** "An attacker could imagine a scenario where..." is noise. "Send `<input>` and observe `<failure>`" is signal.
- **Do not redirect to `/council-review` for finished artifacts.** That's the inverse mistake — council is for open questions, this is for stress tests.
- **Do not propose entire rewrites in fix sketches.** One-sentence fix or "this needs a deeper redesign — see Notes." Save the rewrite for the author.
- **Do not omit "What I Could Not Break".** Without it, the user can't tell where the artifact is genuinely solid vs where you didn't look.

## Changelog

### V2 (2026-05-27)
Optimized via `skillforge optimize` (outcome research: red-teaming practice 2026).
- **Escalation probe (Phase 3)** — adds multi-step/sequence attacks; static single-turn review is documented to miss interaction-dependent, escalation-driven failures.
- **Validation gate (Phase 4)** — every CRITICAL must carry a confirmed reproduction (`[reproduced]`); unreproducible findings are demoted/dropped. Mirrors automated red-teaming's edge: validated findings with reproductions beat raw volume (learning-based RT reports ~3.9× discovery at 89% validation accuracy vs manual).
- Outcome target: deeper multi-step failure analysis + fewer false positives (validation gate). Sources: [Algorithmic Red-Teaming review (arXiv 2026)](https://arxiv.org/pdf/2602.21267); [Learning-based automated RT](https://arxiv.org/pdf/2512.20677); red-teaming practitioner guides 2026.
- **Verification (independent A/B, 2026-05-27):** V1 (single-pass) vs V2 (+escalation probe) on a planted retry/idempotency bug. *Both* arms caught the bug — so the escalation probe's catch-rate advantage is **unproven** on this case (the bug was catchable single-pass). V2's demonstrated win was reproduction quality: a concrete 7-step compound-failure trace vs V1's one-line mention. Claim is scoped to that; a genuinely sequence-only bug would be needed to test catch-rate.

## Cost Budget

| Mode | Agent Calls | Best For |
|------|-------------|----------|
| Default (all vectors) | 6–7 (per-vector + universal + escalation probe + triage) | Pre-merge PR review, spec sign-off |
| Single dimension (`--security` etc.) | 2 (focused probe + triage) | Targeted audit |
| Quick (`--quick`) | 1 | Cheap drive-by check |

## Routine / Schedule

For pre-merge automation, wrap as a GitHub Actions step that runs `claude code -p "/adversarial-review $PR_URL --security"` on PRs touching auth or data paths.

## Testing

This is a prompt-only skill. The shipped `tests/eval.sh` asserts the structural contract. To verify behavior end-to-end:

1. `cd` into a project with a recent PR or draft spec.
2. Run `/adversarial-review docs/spec.md` (or any artifact path).
3. Check that:
   - Findings are categorized into CRITICAL / IMPORTANT / NIT
   - Each CRITICAL has a specific trigger and reproduction sketch
   - "What I Could Not Break" section is present and substantive
   - "What This Review Did NOT Cover" section is honest about gaps
4. Run with a single flag: `/adversarial-review docs/spec.md --security`. Verify only security findings are reported.
5. Run on an open question to verify redirect: `/adversarial-review "Should we use GraphQL?"` should redirect to `/council-review`.
