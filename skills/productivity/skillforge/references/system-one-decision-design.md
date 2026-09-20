# System-1 decision design — typed judgments in skills, without a System One model

Provenance: TypeSafe's Jev ("System One Models") reframes model calls as **typed decisions with
calibrated confidence** that code consumes, instead of generated text a human reads. The model
itself doesn't transfer to a Claude Code session; the *process* does. This file is the transferable
half: how to author skills whose judgment points are typed, thresholded, and composable — using the
session's own model (or a cheaper one) as the judge.

## The three-band spectrum

Every step in a skill's workflow sits in one of three bands. Most skill-quality problems come from
putting a step in the wrong band.

| Band | Nature of the step | Implement as |
|---|---|---|
| **Deterministic** | Same input → same output; no semantics needed (sort, validate, diff, count) | `scripts/` helper. Never make the model reason through it. |
| **Typed judgment** | Needs semantic understanding but has a *closed answer space* (route, verdict, severity, yes/no) | A declared decision point: schema + confidence + escalation rule (below). |
| **Open reasoning** | Answer space is open (synthesis, writing, design, debugging) | Ordinary instructions; full model reasoning. |

The middle band is the historically underserved one. The common failure is pushing it *down* into
scripts (deterministic but slow and tedious to write, brittle at semantics — regex pretending to be
judgment) or letting it float *up* into open reasoning (unstructured "use your judgment" prose whose
output no later step can consume). Name the middle band explicitly when forging a skill.

## Typed decision points

A decision point is a question the skill author writes into SKILL.md with its answer space fixed in
advance. Three shapes cover nearly everything (Jev's Choice / Noul / Score, translated to
instruction patterns):

- **Choice** — pick one from an enumerated set. *"Classify the change: `{behavior-preserving,
  behavior-changing, unclear}`."* The set is the contract; "other" is allowed only if you define
  what happens on "other".
- **Binary probability** — is this proposition true, and how sure? *"Is this finding a real defect?
  Answer CONFIRMED or PLAUSIBLE."* (A verdict enum like CONFIRMED/PLAUSIBLE *is* this pattern:
  a yes/no fused with a confidence band.)
- **Score** — position on ordered levels. *"Severity: critical / major / minor / nit"* — levels
  defined, each with a one-line boundary example so adjacent levels are distinguishable.

Rules that make decision points work:

1. **One narrow question per judgment.** "Is this test flaky AND should we quarantine it?" is two
   questions; fused questions produce uncalibratable answers. Split, then compose in the workflow.
2. **Declare the schema before the reasoning**, in the skill text. The model fills a slot; it does
   not invent the shape of its own answer.
3. **Independent questions run in parallel** — fan out subagents, each returning one schema-shaped
   answer; the parent (or a script) composes. Cheaper/faster models are fine for narrow judgments;
   reserve the strong model for open reasoning.
4. **Machine-readable output** when a script or later step consumes it (one JSON object, keys
   fixed), prose when only a human does.

## The confidence + escalation contract

Jev's core operational idea: *act when confident, escalate when not* — with the threshold set by
the author, not improvised by the model. Every typed decision point in a skill should carry:

- **A confidence band**, not a percentage. Verbalized numeric confidence from an LLM is **not
  calibrated** — don't build policy on "87%". Use 2–3 bands with behavioral definitions:
  *high = would act without review; low = would want a human to look.*
- **An escalation rule per band**, written into the skill: high → proceed autonomously;
  low → stop and ask the user / mark as PLAUSIBLE / take the reversible path. The rule is the
  skill's policy, stated once, instead of per-run vibes.
- **Self-consistency when the decision is load-bearing**: ask the same narrow question to k
  independent judges (parallel subagents, no shared context) and use the vote fraction as the
  confidence signal. Agreement across independent samples is the best calibration a session can
  get without a purpose-trained decision model.

## Code owns the workflow

The inversion that makes the above compose: the skill is a **deterministic scaffold with judgment
slots**, not a narrative the model interprets end to end. The workflow order, the gates, and what
happens at each verdict live in the skill text or a script; the model supplies only the semantic
fills. Symptoms that a skill has this backwards: the model decides *whether* to run a gate; outputs
of one step can't be checked by the next; two runs of the skill take structurally different paths.

For high-volume micro-judgments, a `scripts/` helper can even shell out to a headless model call
(`claude -p` with a small/fast model and a strict output schema, validate + one retry on invalid
output) — a poor man's System One endpoint. Only worth it when the same narrow question is asked
many times per run; for a handful of judgments, in-session decision points are simpler.

## When NOT to type-ify

- Open-ended synthesis (writing, design, root-cause narration) — forcing a schema onto it destroys
  the value; that band stays open reasoning.
- One-shot skills with a single judgment and a human reading the output — the contract adds
  ceremony, not reliability.
- Anywhere a deterministic check exists — a schema-validated model judgment is still a model
  judgment; if `jq`/a validator can answer it, it's band one.

## Forging checklist (add to the normal review checklist)

- [ ] Each workflow step assigned a band; no semantic regex, no model-run arithmetic
- [ ] Each typed decision point: enumerated answer space + confidence band + escalation rule
- [ ] Fused questions split; independent judgments parallelized
- [ ] Machine-consumed outputs schema'd (fixed keys), human-consumed outputs prose
- [ ] Load-bearing decisions use self-consistency (k independent judges) rather than one sample's
      stated confidence
