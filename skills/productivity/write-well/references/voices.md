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

## Register voices — start here (pick by what you're writing)

You don't need to know an author. Pick the voice by the *job*. The **hard do/don't** is the load-bearing part — it's what keeps each voice in its lane. Note that the measured registers explicitly switch OFF the punch tools (the short-fragment closer, manufactured drama) and keep em-dashes near-zero.

| Voice | Use it for | Diction | Syntax / rhythm | Tone & stance | Hard do / don't |
|-------|-----------|---------|-----------------|---------------|-----------------|
| **plain-professional** | updates, docs, straightforward business | neutral, concrete, jargon-light | simple, direct; even | clear, neutral | write the way you talk; say the next step plainly; no flourish, **no zinger closer**; em-dash near-zero |
| **warm-feedback** | performance reviews, 1:1s, coaching | specific, plain, human | balanced; calm, even | candid **and** kind; balance strength + growth | lead with behavior + its impact; **never end on a punchy line**; no manufactured drama; close on substance |
| **diplomatic** | sensitive comms, pushback, de-escalation | careful, soft-edged | hedged where it earns it; smooth | measured, respectful | acknowledge before you counter; **no sharp closer**; minimal em-dash |
| **executive-brief** | leadership updates, BLUF, decisions | tight, decisive | short, front-loaded; brisk | confident, conclusion-first | answer first then support; make the one action you want unmistakable; ≤2 pages — if it won't fit, simplify; no wind-up; no drama |
| **conversational** | newsletters, blogs, explainers | everyday, contractions, first person | varied; relaxed | warm, equal-to-equal (classic style) | talk to one smart friend; punch allowed but *sparing* |
| **academic** | analysis, evidence-led writing | precise, qualified | complex-but-clear; even | objective, cautious | claims earn their hedges; no hype; no zinger |
| **punchy-marketing** | landing pages, ads, hooks | concrete, vivid | short + high contrast | bold, benefit-led | one promise + one unmistakable next step; **the earned kick closer belongs HERE**; still no em-dash spray |
| **storyteller** | personal essays, narrative | sensory, specific | varied; scenic, VAKS-heavy | voiced, reflective | relive don't report; don't narrate the landing |

Each maps to the 6 axes below; `--like <your sample>` clones *your* register instead. For most non-fiction work the default should be **measured**, not punchy.

> **The business/professional registers are Ogilvy's "How To Write" memo (1982), made operational** — write the way you talk, short words/sentences, no jargon, ≤2 pages, and *make the action you want unmistakable*. His last rule is the boundary on the whole register: **if a message really needs action, a direct conversation often beats the memo** — don't write when you should talk. (The cooling-off/accuracy habits from the same memo live in the craft canon's edit-process pass.)

## Author voices — power-user library (only if you know them)

Study anchors for people who recognize the author. Most users want the register voices above. Each entry: the distinctive axes + the one **hard-constraint** tell + 2–4 exemplar lines (add real samples when you use them). `--like` gives unlimited custom ones.

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
| **David Ogilvy** | plain, concrete, benefit-led; zero jargon | short, direct, often imperative | brisk, declarative; even | the ad-man — respects the reader ("the consumer is not a moron; she is your wife"), sells the benefit, never entertains at the sale's expense | every claim names a concrete benefit; no jargon ever; one unmistakable ask. Exemplars: "If it doesn't sell, it isn't creative." / "You cannot bore people into buying your product." |

*Use a library voice as a center of gravity — not a costume. The goal is "recognizably in that voice," not "indistinguishable parody."* Note: the **Ogilvy** voice is the ad-man's *prose* — distinct from applying his 10 rules (those live in the business registers above + the canon's cooling-off pass).

## Sources
- Voice anatomy: Roy Peter Clark / Don Fry; craft glossaries on diction/syntax/tone/rhythm/POV.
- Persona ≠ ethos ≠ author: rhetoric scholarship (the persona as theatrical mask / implied author).
- Named-voice fingerprints: parataxis/asyndeton (Hemingway), parataxis+polysyndeton (McCarthy), nesting+footnotes (DFW), plain-repetitive (Vonnegut), oral/coined (Morrison), elliptical-restrained (Didion), gonzo (Thompson), benefit-led/no-jargon ad-man (Ogilvy — *Ogilvy on Advertising* + the 1982 "How To Write" memo).
- Stylometry: function words as topic-independent authorial habit; Burrows' Delta (standardized function-word frequencies; ~5,000-word floor); sentence-length variance, punctuation, vocabulary richness.
- LLM style-transfer: arXiv 2509.14543 (LLMs regress to generic; few-shot > zero-shot but saturates; informal voices hardest); persona-prompting stereotype-amplification risk; meaning/style separation for style transfer (Reif et al., arXiv 2109.03910).
