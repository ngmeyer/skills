# Voice fidelity: cloning a real person's voice, and knowing whether it worked

Reference for `--like` when the target is a real author (usually the user). It covers choosing samples, handling tics, the voice file and its corrections, and the test that says whether the output sounds like them.

## Why a described voice is a guess

Reading samples and writing down "how this person writes" produces a plausible style guide and no evidence that it works. In a published 2026 experiment (Michael Taylor, Every), a guide written that way lost to optimized alternatives on 80 to 95 percent of held-out posts, and on one model it lost to using no skill at all. The cause was visible on inspection: the guide listed the writer's most recognizable moves, the model applied them everywhere, and it invented an anecdote to carry them.

That was one writer and small samples, so read it as a strong hint. The practical lessons hold up on their own:

- A list of traits pulls toward caricature. A list of **corrections** ("the draft did X, the author changed it to Y") pulls toward the person.
- Substance and style have to be separated, or you can't tell which one the draft got right.
- A voice setup is only as good as the test it has passed.

## Choosing samples

- **Same format as the target.** Long-form samples for long-form writing. Tweets and emails are shaped by their medium and clone badly into essays.
- **Recent beats many.** Style drifts over years. A dozen or two recent pieces from one publication or format do better than a decade of everything.
- **No writing? Use transcripts.** Meeting or voice-memo transcripts capture how the person talks. Formalizing an authentic voice later is easy; making stiff prose sound human is hard.
- **In the prompt, still 2 to 4 exemplars.** The larger set is for extraction and testing, not for pasting in whole.

## Tics and signature phrases

Note them with their real frequency ("opens a section with a question about once per piece"). Then:

- Permitted at the sample's rate. Never required.
- Never the hard constraint. The hard constraint is structural: syntax or rhythm.
- Never a reason to invent content. If a signature move needs a joke or an anecdote the brief doesn't contain, skip the move.

## The voice file

A plain markdown file the author owns and keeps wherever they like. Pass it with `--like <path>`. The skill offers to create or append to it and never writes to it unasked.

```markdown
# Voice: <name>, <format, e.g. newsletter essays>

## Samples
- <path or link>, <date>
- (2 to 4 short excerpts may be pasted here)

## Fingerprint
Diction: ...
Syntax: ...
Rhythm: ...
POV: ...
Tone/punctuation: ...
Tics (with frequency): ...

## Corrections
- 2026-11-17: draft bolded people's names; author removed the bold.
- 2026-11-17: asides read as performed; author cut two and flattened one.
```

Rules for the corrections list:

- **Corrections outrank the fingerprint.** They are observed; the fingerprint is inferred.
- **Record voice and style edits only.** A fixed fact or a new argument is substance, not voice.
- **One line each, dated, stated as what happened.** Generalize ("prefers understatement") only after the same correction shows up in separate pieces.
- **Keep it short.** Past about twenty entries, merge repeats into the fingerprint and delete what the newer entries contradict. Old corrections describe the writer they were.

## The fidelity eval

Run this before trusting a voice file, after changing it, and after switching models.

1. **Hold out real pieces.** Five or more published pieces by the author, in the target format, that are *not* among the samples. If their style is changing, hold out the most recent.
2. **Extract a style-free brief from each.** Thesis, outline, every fact, source, anecdote, and exact quote; no phrasing, hooks, or jokes. Each draft then has the full substance and none of the style, so resemblance can be credited to the voice setup.
3. **Draft each brief under each condition.** At minimum: the model with no skill, write-well with no voice set, and write-well with `--like <voice file>`. Add the previous version of the voice file when testing a change.
4. **Judge in pairs against the real piece.** The judge sees the real piece and two drafts from the same brief, picks the draft closer to the real one, and writes a note on how each draft differs from it.
5. **Swap the order and judge again.** Judges favor the first draft they read. Count a comparison only when both orders agree; report the disagreements as ties. Use the most consistent judge available, and check its consistency before believing its verdicts.
6. **Read the notes.** The win rate says whether the setup helps. The notes say why, and they become corrections.

How to read the result:

- `--like` must beat **both** write-well's default and the no-skill baseline. If no-skill wins, the voice file is doing harm: cut described traits before adding anything.
- Most of the gain arrives in the first few rounds of correction. Stop when a round changes nothing.
- The eval rewards resemblance to past writing. It does not measure whether the piece is good, and it will resist a deliberate change of style.
- It covers the cloned-voice path only. The quality of write-well's default voice needs a human reader's judgment.

## What this is not

It is not an optimizer. Automated loops that rewrite a skill against this metric exist (GEPA in DSPy, among others) and produce a skill tuned to one author and one model. That is a separate tool. This file gives the manual version: samples, a short correction list, and a test.

## Source

Michael Taylor, "How I Finally Got AI to Write Like Me," Every (2026): the brief-extraction step, the pairwise judge against a real reference with order swapping, corrections over descriptions, sample-selection findings, and the model-specificity result. Paraphrased, not reproduced.
