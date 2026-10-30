---
name: ux-review
description: >
  Grades a website, a single page, a mobile web view, or a native or Flutter app (from screenshots)
  against all 30 Laws of UX, Nielsen's 10 heuristics, WCAG 2.2 AA basics, and platform touch-target
  rules. Produces an overall % and letter grade, ranks every violation by severity x reach x
  confidence / effort into P0-P3, and gives a concrete fix for each. Writes a diffable findings JSON
  with stable ids, so an auto-improve loop can tell whether it is winning. Use when: 'ux review',
  'grade this page', 'audit the UX', 'what should we fix first on this screen', 'usability review',
  'heuristic evaluation', 'is this accessible', 'score this app', or as the sense step of a UI
  improvement loop. Not for: AI-generated look and copy tells (anti-ai-slop-ui), rewriting copy
  (write-well), or code structure (a code review skill). An expert review, not a usability study.
user-invocable: true
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep", "Agent"]
argument-hint: "<url|route list|screenshot dir> [--task '<primary task>'] [--previous <artifact.json>] [--weights laws=35,heuristics=25,wcag=25,platform=15] [--target 85] [--out <dir>]"
license: MIT
metadata:
  owner: ngmeyer
  version: 1.0.0
---

# ux-review: grade a UI and rank what to fix first

**Why this exists:** "make the UI better" is not a loop anyone can win, because nobody can tell whether the last change helped. This skill turns a UI into a score that only moves when a specific, evidenced finding changes, plus a ranked fix list. A loop can then ship the top fixes, re-run, and see the diff.

It is an expert heuristic review with evidence, and it says so in its output. Real session data (funnels, rage clicks, support tickets) outranks it whenever the two disagree.

## Inputs

| Input | Capture |
|---|---|
| URL or route list | Playwright full-page shots at the viewports in [platform-targets.md](references/platform-targets.md), an axe-core scan per route, optional Lighthouse. Cap a site at 8 routes unless the caller says otherwise (default set: home, pricing, signup, one core app screen, one empty state, one error state). |
| Screenshot folder | PNGs plus a manifest (`screen`, `platform`, `viewport`, `state`). Code-dependent checks become `n/a` with `reason: "screenshot-only"`; never guess them. |
| Existing capture | A screenshot dir or Playwright trace from a PR preview. Preferred for loops. |
| Flutter app | `integration_test` screenshots plus the `meetsGuideline` checks listed in platform-targets.md. |
| Optional | Primary task per screen, audience, brand tokens, the previous run's artifact, section weights, target %. |

## Procedure

1. **Capture.** Run deterministic tools first (axe, Lighthouse, Flutter guidelines, measured target boxes). Each failure becomes a finding with `confidence: 1.0`. Record tool versions in `tools` and capture settings in `target.capture`.
2. **Name the primary task per screen.** Use the caller's, or infer one and mark `primary_task_source: "inferred"`. Every check is judged against it.
3. **Walk the 30 laws** in [laws.md](references/laws.md). Each law gets findings with evidence (screenshot plus bbox, or a selector), or `n/a` with a reason.
4. **Walk H1-H10** in [heuristics.md](references/heuristics.md). If one problem touches a law and a heuristic, file one finding and list the rest in `also`.
5. **Check WCAG 2.2 AA basics and platform items** in [platform-targets.md](references/platform-targets.md).
6. **Refute P0s before scoring.** For each would-be P0 (severity 4 or a P0 override in Ranking), a fresh-context agent that sees only the screenshots and the finding tries to refute it. Drop or demote a refuted P0 before it moves a score or reaches a loop.
7. **Score** (below). Per screen first, then roll up to the target.
8. **Rank** (below) and write each fix: the element, the change, the expected effect, and the laws it serves. Copy problems get a structural fix plus `delegate_to: "write-well"` (or the caller's product-copy skill, e.g. `product-writing`). Never rewrite copy here.
9. **Diff** against `--previous` if given. Without one, every finding is `new`, and `previous_run_id` and `loop` are null.
10. **Emit** the human summary and the JSON (below).

## Scoring

Two scales. Never mix them.

- **Item score, 0-4, higher is better.** `item = 4 - max(severity of live findings linked to the item)`, floored at 0. A finding is linked when the item is its `rule` or is in its `also`. Live means `diff` is not `resolved`. No live findings: 4. Does not apply: `n/a` with a reason in `scores.na_reasons`.
- **Finding severity, 0-4, higher is worse.** NN/g scale, defined in heuristics.md.

A score can only change when a linked finding changes. That is the guard against judge noise between loop runs: re-reading a screen in a different mood moves nothing unless it files or drops a finding.

**Per screen, then target.** Score each item per screen. The target-level item score is the **min** across screens if any linked live finding is P0 or P1, otherwise the **mean** of applicable screens, rounded to 2 decimals. A blocker on one screen is not averaged away by four clean ones.

**Section %** = sum of target item scores / (4 x applicable items) x 100, rounded to 1 decimal.

**Overall %** = weighted mean of section %. Default weights: laws 35, heuristics 25, wcag 25, platform 15. The caller may override them with `--weights`; record what was used in `config.section_weights`. A wholly n/a section drops out and the rest are reweighted.

**Grade.** A >= 90, B >= 80, C >= 70, D >= 60, F < 60. Caps, applied after: any live P0 caps the grade at D; any live WCAG AA failure (a live finding linked to a `scores.wcag` item) caps it at C. When a cap lowers the grade, name it in `grade_cap_reason`; otherwise leave it null. Calibration: most real interfaces land in C or B, so a B is a good page.

## Ranking

Each finding carries:

| Field | Values |
|---|---|
| `severity` | 0-4 (NN/g) |
| `reach` | 5 signup or primary task on the main path; 4 core create, edit, or publish; 3 trial, checkout, or settings; 2 marketing page; 1 static or rare page. If real session counts exist, use them and set `reach_source: "sessions"`. |
| `effort` | 1 copy or CSS token; 2 one component; 3 several components; 4 flow change; 5 architectural |
| `confidence` | 1.0 deterministic tool or measurement; 0.8 clear visual evidence; 0.5 judgment call |

`priority_score = severity^2 x reach x confidence / effort`, rounded to 2 decimals. Squaring severity keeps one catastrophe above a pile of cosmetics.

**Tier** comes from severity plus overrides; the score sorts within a tier. Write the override in `tier_reason`.

| Tier | Rule |
|---|---|
| P0 Blocking | severity 4, OR blocks the primary task, OR fabricated proof (from anti-ai-slop-ui), OR data-loss risk |
| P1 Major | severity 3, OR any WCAG 2.2 AA failure, OR "would a user contact support over this?" |
| P2 Minor | severity 2 |
| P3 Polish | severity 0-1 |

Sort live findings by tier, then `priority_score` descending, then `id`, with resolved ones last, so two runs print the same order.

## Output

- **Human summary:** grade and overall %, the cap if any, the top 5 fixes (tier, rule, one-line fix), and any regressions.
- **JSON** validating against [findings-schema.json](references/findings-schema.json), written to `<out>/ux-review-<target-slug>-YYYY-MM-DD.json` (default `<out>` is the working directory). Worked example: [example-page.json](references/example-page.json).

**Stable id.** `id = "uxr_" + first 10 hex of sha1("ux-review|<rule>|<screen>|<locator>")`, where `<locator>` is `location.selector` normalized (no nth-child indices, no hashed class names) or, for screenshot-only runs, `location.region` (a cell on a 4x4 grid, `r1c1` to `r4c4`). The same problem on the next run gets the same id, which is what the diff keys on.

**Diff values:** `new`; `persisting`; `resolved` (in the previous run, gone now; carried for one run, never scored); `regressed` (resolved earlier, back now). **Status** uses ledger states: `open | investigating | pr_open | shipped | verified | wontfix`.

## Loop rules

For auto-improve loops. Where the loop runs is the caller's choice: **default is on PR previews**; a scheduled run (for example weekly on the top routes) works the same way, diffing against the last scheduled artifact.

**Per iteration**
1. Run on the same capture settings as the previous run. If they changed, say so, set `loop.decision: "baseline-reset"`, and do not report deltas.
2. Diff against `previous_run_id`.
3. Hand the top 1-3 live findings (tier, then score) to whatever ships fixes, as one brief. Goal: each finding's `fix`. Done when: those ids come back `resolved` on re-run, with a preview URL and screenshots. Constraint: no new P0 or P1 anywhere.
4. Re-run on the preview. Merge only if no regression rule fires. Ask a human first for auth, billing, data-schema, or email surfaces, and stress-test risky fix PRs with `adversarial-review` if installed.

**Regression: block the merge or revert the iteration** if any of these hold: a new P0; any finding with `diff: "regressed"`; any law or heuristic score dropping 2 or more, or any WCAG item dropping 1 or more; overall % dropping 3 points or more; `slop_score` (from anti-ai-slop-ui) rising 10 or more.

**Stop** when any of these hold:
- **Target met:** no live P0 or P1, overall % at or above `config.target_pct` (default 85), and slop_score at or below 25 if that skill ran.
- **Plateau:** two consecutive iterations with overall delta under 1 point and nothing resolved.
- **Budget:** 5 iterations per target per loop run (`config.iteration_budget`).
- **Stuck:** the same finding survives 2 fix PRs (count them in `fix_attempts`). Stop and write a STUCK note: what was tried, what was seen, what is suspected, what is needed.

**Delivery.** Say nothing if nothing changed. Otherwise one line per resolved or regressed item plus the grade delta. Never invent counts. If you keep a findings ledger, each live P0 or P1 becomes or updates a row keyed `ux-review:<rule>` plus URL and viewport.

## Gotchas

- **Two scales, opposite directions.** Item scores go up when good; severity goes up when bad. Writing a severity into `scores` silently inverts the grade.
- **Do not double-file.** One problem that violates Fitts and H8 and a platform target is one finding with `also`, not three. Three findings triple its rank and break the diff when the fix lands.
- **n/a is not "looks fine".** n/a means the item cannot apply or could not be checked, with a reason. An unchecked item scored 4 inflates the grade.
- **The same element at two viewports is one finding.** The id has no viewport in it on purpose. Put the worst viewport in `location.viewport` and the others in `evidence`.
- **Locators must be normalized before hashing.** `div:nth-child(3) > .css-1x9f2a` changes between builds; the id churns and every finding looks `new`. Hash the semantic selector (`form button[type=submit]`).
- **Do not average away a blocker.** The min-for-P0/P1 rollup exists because a broken signup screen is not fixed by a fine pricing page.
- **Screenshot-only runs cannot see focus order, labels, or token contrast.** Mark them n/a; a guessed WCAG pass is worse than an honest gap.
- **`also` escalates.** Listing a WCAG SC in `also` makes the finding a WCAG failure: P1 at least, and the grade caps at C. List an SC only when it actually fails.
- **One id per rule, element, screen.** Two problems with the same rule on the same element are one finding; merge the evidence. A shared component that fails on every screen is filed on its highest-reach screen, with the others named in `evidence`.
- **Artifacts leak.** Signed-in screenshots can hold real user data, and preview URLs can carry tokens. Redact both before an artifact leaves the machine, and keep eval targets for private products in a private note.

## References

- [laws.md](references/laws.md): the 30 laws, what to check, common overlaps, fix lookup
- [heuristics.md](references/heuristics.md): H1-H10, the overlap rule, the severity scale
- [platform-targets.md](references/platform-targets.md): WCAG items, platform items, capture defaults
- [findings-schema.json](references/findings-schema.json): the artifact schema, shared with anti-ai-slop-ui
- [example-page.json](references/example-page.json): a worked single-page run
- [sources.md](references/sources.md): attribution and licenses
