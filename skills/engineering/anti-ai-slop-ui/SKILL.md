---
name: anti-ai-slop-ui
description: >
  Finds the tells that make a site or app look machine-generated (house indigo, gradient text,
  Inter-only type, the three-card row, stock section order, emoji icons, glass panels, sparkle
  "AI-powered" badges, template chrome) and, above all, fabricated proof: invented testimonials,
  logos, and stats. Scores a slop_score 0-100 with a craft-credit guard so real brand systems are
  not flagged, ranks findings P0-P3, and writes the same findings JSON as ux-review so one loop can
  rank both. Use when: 'does this look AI-generated', 'anti-slop review', 'de-slop this landing
  page', 'why does our site look generic', 'check for fake social proof', 'slop score', or as the
  second sense step of a UI improvement loop. Not for: usability, laws, or accessibility grading
  (ux-review), or rewriting copy (write-well). Reports signs, not proof of AI use.
user-invocable: true
allowed-tools: ["Read", "Write", "Bash", "Glob", "Grep", "Agent"]
argument-hint: "<url|route list|screenshot dir> [--brand <tokens file>] [--proof <proof.json>] [--previous <artifact.json>] [--slop-target 25] [--out <dir>]"
license: MIT
metadata:
  owner: ngmeyer
  version: 1.0.0
---

# anti-ai-slop-ui: find generic-AI tells and fabricated proof

**Why this exists:** generated UIs regress to the mean of their training data, so they converge on one look: indigo accent, Inter, three cards, a testimonial wall. Visitors read that look as "nobody cared", and invented proof is worse: a fake testimonial or stat is a trust failure and, in the US, a legal one (16 CFR Part 465). This skill names each tell with evidence, scores how template-grade the whole thing is, and blocks on fabrication.

These are **signs, not proof.** The skill reports tells; it never claims or implies that anyone used AI.

## Inputs

Same capture as [ux-review](../ux-review/SKILL.md); reuse its screenshots and DOM when both run. Plus, optional: brand tokens or a design-system doc (feeds craft credit), `proof.json` (a source record per testimonial, logo, stat, or rating), and the previous run's artifact.

## Procedure

1. **Capture**, or reuse ux-review's.
2. **Deterministic pass.** From CSS, computed styles, and the DOM: indigo/violet hues, gradient text, font stacks, the radius and shadow set, `backdrop-filter`, emoji in icon positions, em-dash count in visible copy, fade-in-on-scroll. Optional pre-pass: if impeccable (`detect --json`) or Gesso (`check --json`) is already installed, run it; never fetch or install a tool mid-review and map its hits to T-ids. Our tells are canonical; a tool hit with no T-id is noted in `evidence`, not scored. Neither tool is required.
3. **Visual pass.** On screenshots: three-card rows, centered everything, the stock section order, logo soup, testimonial walls, the fake terminal hero, template chrome.
4. **Copy pass.** Extract visible copy and check it for T12 and T13. File a finding with `delegate_to: "write-well"` (or the caller's product-copy skill). Never rewrite copy here; the copy skill owns the banned-word list and the fix.
5. **Fabrication pass.** For every testimonial, customer logo, stat, rating, or "trusted by" claim, look it up in `proof.json`; if there is none, ask the caller for a source. No source: P0 (T14, T15, T16). Submit each email or contact form once, only on a preview or staging deploy and only with a test address the caller supplied (never production, never a real person's address; no preview means skip and note it). A fake success that stores nothing is T21, P0. Recommend the fix pattern: a `SOCIAL_PROOF_SLOT` placeholder rendered only from a sourced `proof.json` entry, with the build failing on an unsourced slot.
6. **Craft-credit pass.** For each tell found, check its false-positive guard in [tells.md](references/tells.md). Real craft is a documented brand color used with restraint, a deliberate type scale, custom illustration, real product screenshots, and real hover and focus states. When the guard holds, keep the finding with `severity: 0`, `tell_weight: 0`, and the reason in `craft_credit`, so the run shows the guard fired. Have a fresh-context agent that sees only the screenshots and the brand doc confirm each credit, and each P0.
7. **Score** (below).
8. **Tier, rank, emit** (below). Diff against `--previous` as ux-review does.

## Scoring

Each style tell (every T-id except the proof tells T14, T15, T16, T21) has a weight in tells.md. A tell found on any screen, without craft credit, contributes its weight **once**: more instances add evidence, not points. That is the per-tell cap: one tell repeated forty times is still one tell, and the fix is the same.

`slop_score = round(100 x sum(weights of tells found) / sum(weights of applicable tells))`. A tell is not applicable (`n/a`, reason in `scores.na_reasons`, key `T09`) when the capture cannot show it, for example token tells on a screenshot-only run. If no style tell is applicable, `slop_score` is null.

Proof tells are not in `slop_score`. One invented stat should block a release, not move a score by four points.

**Band**, from the count of style tells found without craft credit: 0 `none`, 1-2 `isolated`, 3-6 `pattern`, 7+ `template-grade`. Write it to `scores.slop_band`. The weights are a starting point adapted from the IOV Labs study; calibrate them on your own controls before trusting a threshold.

In the artifact: `skill: "anti-ai-slop-ui"`; `scores.laws`, `heuristics`, `wcag`, and `platform` are null; `sections_pct`, `overall_pct`, and `grade` are null; `config.slop_target` defaults to 25.

## Tiers

Findings use the shared [findings schema](../ux-review/references/findings-schema.json) and ux-review's `priority_score` and ordering.

First matching row wins.

| Tier | Which tells | Severity |
|---|---|---|
| P0 | Fabrication: T14, T15, T16 without a source; T21 when the form drops data | 4 |
| P1 | A tell that also breaks UX or accessibility: no focus state (T19), failing contrast (T22), emoji-only icons with no label (T05). List the ux-review item in `also` (`2.4.7`, `1.4.3`, `1.1.1`) and set `tier_reason`. | 3 |
| P2 | Any style tell when the band is `template-grade` | 2 |
| P3 | Isolated or pattern-band style tells | 1 |
| none | Craft-credited | 0, tier P3 |

**Stable id:** `"slop_" + first 10 hex of sha1("anti-ai-slop-ui|<rule>|<screen>|<locator>")`. A token-level tell (color, type, radius) is site-wide: use `screen: "*"` and the token or CSS custom property as the locator, so it does not churn as routes change.

## Fixes

Every fix points to **the product's own** brand tokens, content, and screenshots: "use the brand teal from the tokens file for the primary button", "replace the three icon cards with one screenshot of the real editor and two sentences". Never prescribe a different stock look.

**Over-correction warning.** The usual replacements are the next generation of defaults: cream background with a serif and a terracotta accent, near-black with an acid-green accent, broadsheet hairlines. That is T23. A fix that swaps one template for another is not a fix.

## Loop use

Runs beside ux-review in the same loop (see its Loop rules). Concatenate both `findings` arrays and rank them together. ux-review's regression rule already blocks a merge when `slop_score` rises 10 or more; its target-met rule wants `slop_score` at or below `config.slop_target`. Any live P0 from this skill blocks, as ux-review's do.

## Gotchas

- **Purple is not slop; unconsidered purple is.** T01 and T03 fire constantly on well-crafted brands. Run the craft-credit pass before tiering, never after.
- **Asking for proof is not accusing.** The finding says "no source on file for this claim", not "this is fake". The caller may have the source.
- **Do not double-count with ux-review.** A missing focus ring is one problem. This skill still files T19 (with `also: ["2.4.7"]`) and counts its weight in `slop_score`; when the loop merges both arrays, keep ux-review's 2.4.7 finding, add `T19` to its `also`, and drop the slop finding from the merged list only.
- **T11 alone is nothing.** The stock section order only counts when at least two other style tells are present.
- **Copy belongs to the copy skill.** Flag T12 and T13 with evidence and `delegate_to`; do not paste in a rewrite.
- **Single-purpose pages are centered on purpose.** T10 is n/a on login, 404, and checkout.
- **Weights are uncalibrated.** Report the band with the score, and do not gate a release on a raw `slop_score` until it has been checked against known-generated and known-crafted controls.

## References

- [tells.md](references/tells.md): T01-T23 with weights, detection, false-positive guards, sources, and attribution
- [findings-schema.json](../ux-review/references/findings-schema.json): the shared artifact schema
- [ux-review](../ux-review/SKILL.md): ranking, ordering, diff, and loop rules this skill reuses
- [tests/fixtures/example-slop.json](tests/fixtures/example-slop.json): a worked run, recomputed by the eval
