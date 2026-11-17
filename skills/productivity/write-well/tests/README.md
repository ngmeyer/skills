# write-well — Eval harness

**Level:** Prompt-only. Output is prose and non-deterministic, so there are two layers: a structural eval that runs in seconds and gates every push, and a voice-fidelity protocol that needs real writing samples and a judge model and is run by hand.

## Layer 1: structural eval (`eval.sh`)

Asserts the design contract of `SKILL.md` and its references:

- Frontmatter (`name`, `description`, `argument-hint` advertising `--voice`)
- The five-part core (Voice, VAKS, Rhythm, Specific over abstract, Story-first)
- Voices and personas: the three controls, the 6-axis fingerprint, both failure-mode guards, the register and author libraries
- The craft canon rules, the rules-as-defaults meta-rule, and the refusal to import grammar superstitions
- Register-first rules and the punchy closer named as a tell
- Ogilvy and Strunk & White incorporation points
- **1.1:** the substance gate (brief, never invent, `[NEED:` marker), tic-safe cloning (structural hard constraint, tics never required), the edit feedback loop, the voice-fidelity reference, and the model-drift gotcha
- **Self-containment:** no personal-project names in the skill or its references
- **Dogfood:** em-dash density of `SKILL.md` and the purged reference files stays under budget
- Conventions: Gotchas, Changelog, 500-line cap

```bash
bash tests/eval.sh
```

Exit 0 means the contract is intact. Exit 1 means a regression.

## Layer 2: voice-fidelity eval (manual)

Tests whether `--like` output resembles a real author more than the alternatives do. Full protocol: [../references/voice-fidelity.md](../references/voice-fidelity.md). In short:

1. Hold out five or more of the author's published pieces that are not among the samples.
2. Extract a style-free brief from each (substance only).
3. Draft each brief with no skill, with write-well's default voice, and with `--like <voice file>`.
4. A judge model sees the real piece and two drafts, picks the closer one, and notes how each differs.
5. Run every comparison twice with the order swapped; count only agreeing verdicts.

A change may be described as improving voice only if it wins on held-out pieces against both the previous version and the no-skill baseline. Rerun after a model change.

**Status:** the protocol is documented and has not yet been run against write-well. No fixtures are checked in, because real writing samples are private; keep them outside the repo.

## What this does NOT test

- Whether a given draft is good. Layer 2 measures resemblance to past writing, not quality.
- The default (no `--like`) voice. That still needs a human reader.
- Whether the model obeys the substance gate at runtime (asks or marks `[NEED: …]` instead of inventing).
- Whether corrections are extracted correctly from an author's edits.

## Extending

- When a real run invents content, caricatures a voice, or misses a tell, add a structural assertion for the rule that should have prevented it and a Gotcha in `SKILL.md`.
- When Layer 2 is run, record the win rates and judge consistency in the `SKILL.md` changelog, without the sample text.
