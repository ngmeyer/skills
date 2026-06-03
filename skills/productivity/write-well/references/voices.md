# Voices & Personas — the fingerprint model + library

How to adopt, build, or clone a writing voice. The LLM does the adopting; this file gives it the model and the library. Grounded in craft (the anatomy of voice) + stylometry (what actually distinguishes voices) + the LLM style-transfer evidence.

## What a voice is

A voice is **the consistent pattern of choices that creates the illusion of a person speaking** (Don Fry, via Roy Peter Clark) — not one trait. A **persona** is a voice *plus a worldview/role* — the "implied author," the mask (rhetoric distinguishes this from the real author; ethos is the narrower credibility layer). So: `--voice` = the *how*; `--persona` = the *how* + the *who/what-it-believes*.

## The 6-axis fingerprint

Five surface axes (clonable from a sample — they're stylometrically measurable) + one rhetorical axis (described, not sampled).

| Axis | What it is | Stylometric correlate | Controls |
|------|-----------|----------------------|----------|
| **1. Diction** | word choice | mean word length; vocabulary richness; rare/invented-word rate | plain↔ornate, concrete↔abstract |
| **2. Syntax** | sentence structure | parataxis↔hypotaxis; clause-nesting depth; poly/asyndeton; **function-word profile** (the strongest authorial tell) | the shape of thought |
| **3. Rhythm** | sentence-length pattern | mean length + **variance / burstiness** | the music (staccato↔flowing) |
| **4. POV** | person + distance | pronoun frequencies | intimacy, who's looking |
| **5. Tone/punctuation** | attitude + marks | punctuation density & placement; degree-adverb use | irony, restraint, intensity |
| **6. Stance** *(persona only)* | worldview/role | — (rhetorical, not stylometric) | what the voice *notices and believes* |

> **Why these and not numbers:** stylometry *measures* voices (Burrows' Delta over standardized function-word frequencies discriminates authors on texts as short as ~5,000 words), but there's no evidence an LLM writes better from raw z-scores than from the same axes stated *qualitatively*. Store and apply the fingerprint as words + exemplars, not statistics. Content words are a *weak* signal — *what* you write about barely fingerprints you; *how* you connect words is the strong one.

## How the three controls work

- **`--voice <name>`** — load axes 1–5 from the library. Mechanics only.
- **`--persona <name|description>`** — axes 1–5 **+ axis 6** (stance). E.g. "gonzo journalist" isn't just breathless syntax; it's writer-as-subject, subjectivity-as-the-story.
- **`--like <sample path or paste>`** — read the sample and extract axes 1–5 *qualitatively* (is it paratactic or nested? how much does sentence length vary? what are its punctuation/function-word habits?), then write toward that. Axis 6 (stance) can't be recovered from style alone — infer it or ask if persona-level fidelity is wanted. **Few-shot beats description, but saturates fast: use 2–4 exemplars, never a wall.**

## The two failure modes (the whole system is tuned to sit between them)

1. **Regression to generic** — the default gravity. LLMs "default to a generic style learned from vast web data, stripping away the personal touch," and informal/conversational voices clone *worst* (arXiv 2509.14543). **Guard:** make the voice's *single most distinctive axis* a hard constraint, and always pass exemplars. Generic = the fingerprint is simply absent.
2. **Caricature / stereotype amplification** — the opposite cliff. Maxing every axis on every sentence is parody (McCarthy's "and…and…and" in *every* line; a DFW footnote on *every* sentence). **Guard:** the fingerprint is a **center of gravity with variance**, not a rule applied 100% of the time. Rhythm variance (axis 3) is itself the hedge — real voices vary.

**Rewrite mode:** separate meaning from style — preserve the content, re-skin the voice — and check for meaning drift (style leaking into, or distorting, the meaning).

## Starter library (named fingerprints)

Each entry: the distinctive axes + the one **hard-constraint** tell + 2–4 exemplar lines (add real samples when you use them). These are study anchors, not the only voices — `--like` gives unlimited custom ones.

| Voice | Diction | Syntax | Rhythm | Stance (persona) | Hard-constraint tell |
|-------|---------|--------|--------|------------------|----------------------|
| **Hemingway** | plain, concrete, Anglo-Saxon | parataxis; **asyndeton** (no linking words) | short, declarative, even | stoic; the iceberg — omit, let the reader fill | no subordinating conjunctions; strings of simple sentences |
| **Cormac McCarthy** | spare, biblical, archaic | parataxis + **polysyndeton** (and…and…) | rolling, incantatory | mythic; all things equal weight | minimal punctuation; "and"-chains (sparingly) |
| **David Foster Wallace** | hyper-specialized, invented abbrevs | long, multi-clause, **nested** | digressive, accelerating | self-conscious maximalist | footnotes/endnotes; clauses within clauses |
| **Vonnegut** | plain, blunt | simple, short, repetitive | choppy; short paragraphs | dark-comic, humane | declarative refrains ("So it goes") |
| **Toni Morrison** | lyrical; coined words ("rememory") | fluid; oral-tradition repetition | call-and-response, musical | communal, mythic; trauma + beauty | invented vocabulary; oral cadence |
| **Joan Didion** | precise, connotation-rich | elliptical, controlled | cool, measured | restrained, observational, detached dread | emotional restraint; exact nouns |
| **Hunter S. Thompson** | hyperbolic, profane, slangy | breathless, run-on | manic, escalating | gonzo: writer-as-subject | caricatured first-person; subjectivity = story |
| **Faulkner** | dense, Latinate | **hypotaxis**: long, subordinated | sprawling, recursive | interior, historical-Gothic | stream-of-consciousness; one-sentence paragraphs |

*Use a library voice as a center of gravity — not a costume. The goal is "recognizably in that voice," not "indistinguishable parody."*

## Sources
- Voice anatomy: Roy Peter Clark / Don Fry; craft glossaries on diction/syntax/tone/rhythm/POV.
- Persona ≠ ethos ≠ author: rhetoric scholarship (the persona as theatrical mask / implied author).
- Named-voice fingerprints: parataxis/asyndeton (Hemingway), parataxis+polysyndeton (McCarthy), nesting+footnotes (DFW), plain-repetitive (Vonnegut), oral/coined (Morrison), elliptical-restrained (Didion), gonzo (Thompson).
- Stylometry: function words as topic-independent authorial habit; Burrows' Delta (standardized function-word frequencies; ~5,000-word floor); sentence-length variance, punctuation, vocabulary richness.
- LLM style-transfer: arXiv 2509.14543 (LLMs regress to generic; few-shot > zero-shot but saturates; informal voices hardest); persona-prompting stereotype-amplification risk; meaning/style separation for style transfer (Reif et al., arXiv 2109.03910).
