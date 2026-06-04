---
name: write-well
description: >
  Write prose with craft and a real voice — and edit flat or AI-flavored prose to find it.
  Two modes: `draft` (write from scratch) and `edit` (bring voice to existing text against
  a pattern catalog). Adopt any voice or persona — `--voice <name>` from a library,
  `--persona <name|desc>` (voice + worldview), or `--like <sample>` to clone one. Backed by
  a deduped craft canon (Strunk, Zinsser, Orwell, Williams, Lanham, Clark, Pinker, Le Guin,
  McPhee, Provost) plus the full AI-tell catalog. The core idea is positive: great writing has
  a person behind it; the so-called AI tells are just the absence of voice. Use when DRAFTING
  or EDITING fiction, blog posts, essays, marketing copy, newsletters, or any long-form prose.
  NOT for code, technical docs, or chat replies. Trigger: 'write this', 'draft this', 'make this
  better', 'give this voice', 'in the voice of', 'does this sound like AI', 'humanize', 'apply my style'.
argument-hint: "<topic or text> [--voice <name>] [--persona <name|desc>] [--like <sample>]"
---

# write-well

Great prose has a person behind it — a voice, a body, opinions, a sense of rhythm. The patterns that make writing "sound like AI" (significance inflation, rule-of-three, em-dash spray, flat reporting) are **symptoms of one disease: no voice.** So the move is positive — *add* craft and voice, and the tells disappear on their own. Subtracting tells from voiceless prose just gives you cleaner voiceless prose.

## Two modes

| Mode | For | Starting point |
|---|---|---|
| **draft** (default) | writing from scratch | a topic, an outline, a blank page |
| **edit** | text that's flat, generic, or AI-flavored | an existing draft to bring alive |

Both modes serve the same core; they just enter from different ends.

## The core — what good prose has (both modes)

1. **Voice.** A real person reacting, not a neutral reporter. Opinions ("I genuinely don't know how to feel about this"), acknowledged complexity ("impressive but unsettling"), first person when it fits, a little mess (tangents, self-correction). Voiceless-but-clean is as obvious as slop.
2. **Reliving, not reporting (VAKS).** Most weak writing *reports* ("I met her at a bar, did a trick, won her over"). Good writing *relives* it with sensory detail — **V**isual, **A**uditory, **K**inesthetic, **S**mell. Every scene/section needs ≥2 VAKS ingredients, at least one non-visual. Diagnostic: "am I watching a movie or reading a news summary?" Summary → add VAKS.
3. **Rhythm — vary sentence length.** The single biggest lever for "music." Short sentences punch. Then a longer one builds and breathes and carries the reader somewhere before it sets them down. Then a fragment. If every sentence is the same length, the prose is a monotone (Provost). **Read it aloud** — your ear catches what your eye skims.
4. **Specific over abstract.** "I moved schools four times because I kept getting bullied" beats "I had a difficult childhood." Dense, concrete words carry more than vague ones. Name the thing.
5. **Story-first structure.** Hook → Struggle → Breakthrough → Application. Drop into a moment, relive the difficulty, *show* the turn, link to the point **last**. The AI default inverts this (state the lesson, backfill with anecdotes) — a sermon. Lead with life; arrive at the principle. *(Register-gated — see below. A performance review is not a personal essay.)*

## Register & tone — set this first

The core has a bias toward **punch**: short kicks, high-contrast rhythm, the dramatic short-fragment closer ("She did that."), "don't narrate the landing." That register is right for **marketing, fiction, and personal essays** — and wrong everywhere else. Set the register *before* you reach for those tools; ask or infer it from the task if it isn't given.

| Register | Wants | Avoid |
|---|---|---|
| **Punchy / dramatic** — marketing, fiction, personal essay | short kicks, the *earned* closer, contrast, voice turned up | flatness, hedging |
| **Measured / professional** — performance feedback, business, diplomatic, reference, academic | specific + balanced + kind, even rhythm, substance-led, claims you'd stand behind | the zinger ending, manufactured drama, the fragment closer |

**The punchy short-fragment closer is now its own AI tell.** Don't reach for it by reflex. In measured registers, *close on substance, not a kick* — the last line lands a point, it doesn't perform one. **Performance feedback** specifically: lead with the specific behavior + its impact, balance strength and growth, stay warm and direct, never end on a one-liner.

## Voices & personas

By default write-well calibrates a voice to the piece, audience, and **register** (above). You can also set one explicitly — the LLM *adopts* it; no config needed:

- `--voice <name>` — adopt a named voice. **Two libraries:** pick a **register voice** by *what you're writing* (`plain-professional`, `warm-feedback`, `diplomatic`, `executive-brief`, `conversational`, `academic`, `punchy-marketing`, `storyteller`) — no author knowledge needed — or an **author voice** if you know it (Hemingway, Didion, …).
- `--persona <name|description>` — a voice **plus a stance/worldview** (the implied author — e.g. "skeptical engineer"). A persona writes *as someone*.
- `--like <sample path or paste>` — **clone** a voice: read the sample's fingerprint and write toward it. Use this to match *your* habits — including whether you use em-dashes at all.

Every voice is one **6-axis fingerprint** — diction · syntax (parataxis↔hypotaxis, clause-nesting) · rhythm (sentence-length *variance*) · POV/distance · tone/punctuation · stance (persona only). The first five are clonable from a sample; stance is the rhetorical layer you describe, not sample. Full model + a starter library (Hemingway, McCarthy, DFW, Vonnegut, Morrison, Didion, Thompson, Faulkner) with 2–4 exemplars each: [references/voices.md](references/voices.md).

**Two failure modes — engineer against both** (a voice tuned away from one drifts into the other):
- **Regression to generic** (the default gravity — the LLM falls back to bland web-average). Guard: make the voice's *most distinctive* axis a **hard constraint** (e.g. Hemingway → no subordinating conjunctions) and pass 2–4 exemplars.
- **Caricature** (maxing every axis → parody: "and…and…and" every line). Guard: treat the fingerprint as a **center of gravity *with variance***, not a rule applied to 100% of sentences — real voices vary.

In `edit`/rewrite, **separate meaning from style**: re-skin the voice, keep the content (watch for meaning drift).

## The craft canon

The five-part core is the spine; the full positive ruleset — deduped across Strunk, Zinsser, Orwell, Williams, Lanham, Clark, Pinker, Le Guin, McPhee, Provost — lives in [references/craft-canon.md](references/craft-canon.md). The load-bearing rules beyond the core:

- **Characters as subjects, actions as verbs; kill nominalizations** (Williams) — the strongest *positive* clarity engine (tells you what to build, not just what to delete).
- **Cohesion: open with old information, end with the new** (Williams) — what makes paragraphs *flow*, not just sentences shine.
- **The Paramedic Method** (Lanham) for edit mode — circle prepositions + be-verbs → find the action → make the doer the subject → start fast.
- **Right-branch; emphatic word last** (Clark/Strunk) — information order *within* the sentence.
- **Structure from the material, kept invisible; write the lead first** (McPhee) — the nonfiction structure model.
- **Classic style** (Pinker) — prose as a window: show the reader what you see, as an equal. The default stance for essay/newsletter/blog.
- **Beat the curse of knowledge** (Pinker) — you're too close to the subject to see what the reader doesn't know; use a test reader.

**Rules are defaults with reasons, not commandments.** Keep the positive maxims, but the grammar *superstitions* (never the passive, never split an infinitive, never open with "however") are folklore — know *why* a rule exists, then break it when it serves the reader. Inviolable: voice, specificity. Calibration-dependent: em-dash budget, tricolon limit, passive voice (use it when the acted-upon is the reader's focus).

## draft mode

Write the piece, holding the core (and the chosen voice). Plus:
- **Open on a moment, not exposition.** Sensation, dialogue, or a question — never a concept the reader doesn't care about yet. The opening earns or loses the reader.
- **POV-colored vocabulary** (fiction): a painter sees composition, an engineer sees load-bearing walls. Narration should taste like the character.
- **Dialogue does the work.** Don't narrate exposition — let characters say it, argue it, get it wrong. Each line answers the *actual* previous line.
- **Don't narrate the landing.** Never state the emotional conclusion ("that changed everything"). If you have to name it, the scene didn't earn it.

Craft detail + examples: [references/prose-craft.md](references/prose-craft.md).

## edit mode

The text exists but it's flat or AI-flavored. Bring it alive:

1. **Add voice first** (the positive half). Inject opinions, complexity, first-person where it fits, varied rhythm, specific feeling. This is what most "humanize" passes skip — and it's the half that matters.
2. **Then fix the patterns.** Work the catalog of 29 recurring AI patterns (significance inflation, promotional language, superficial -ing phrases, vague attributions, rule-of-three, copula avoidance, em-dash overuse, inline-header lists, hedging, filler, sycophancy, etc.) with before/after fixes: [references/edit-catalog.md](references/edit-catalog.md).
3. **Run the Paramedic Method** on bloated sentences (see the craft canon) for a mechanical concision pass.
4. **Match the target voice** — if `--voice`/`--like` is set, rewrite toward that fingerprint, not toward generic "natural."

## The final pass (both modes)

Cheap, high-yield. After drafting or editing, run two prompts:
1. *"What makes this sound AI-generated or flat?"* — name the remaining tells honestly.
2. *"Now fix exactly those."* — revise.

This catches what the first pass missed.

## Banned words & phrases

Hard-ban list (delve, tapestry, testament to, "It's not just X, it's Y", "at its core", bold-colon bullets, etc.): [references/banned-words.md](references/banned-words.md). Quick gut-check: if a sentence "says everything and means nothing," cut it.

## Self-review checklist

- [ ] **Voice** — is there a person here? Opinions, complexity, a pulse? *(If a voice/persona was set: is its most distinctive axis actually present — and not caricatured?)*
- [ ] **VAKS** — every scene/section has ≥2 sensory ingredients, ≥1 non-visual?
- [ ] **Rhythm** — sentence lengths vary? Read one paragraph aloud — does it have music?
- [ ] **Clarity** — subjects name the characters, verbs name the actions? Nominalizations un-buried? Sentences open old → close new?
- [ ] **Structure** — leads with a moment, lesson last?
- [ ] **Specific** — concrete over abstract? Named, not vague?
- [ ] **Register fits the task** — punchy only where it belongs; no reflexive zinger / short-fragment closer in feedback, professional, or diplomatic prose.
- [ ] **Em-dashes near-zero** — now a top AI tell; use commas, periods, or parentheses instead, and reserve the em-dash for a genuine interruption. **Triples** cut unless there are genuinely three things; no triple anaphora (X. Y. Z.); paragraph lengths varied.
- [ ] Banned words scanned; bold-colon and rule-of-three patterns gone.
- [ ] **Final pass** run (diagnose → revise).
- [ ] American English (color, gray, traveled).

## Domains

Generic domain notes (apply the core, weight differently): [references/domains.md](references/domains.md) covers fiction, articles/essays, marketing/testimonials, and faith/values content. For a specific project, layer that project's own style guide on top — this skill is the foundation, not the override.

## Gotchas

- **Over-correcting kills voice.** Applying every rule rigidly produces sterile prose — as obviously AI as the tells. The core is the goal; the rules are guardrails. When in doubt, keep the voice.
- **Set the register before the punch.** The dramatic levers (short kicks, the fragment closer, manufactured drama) belong to marketing / fiction / personal essay. In performance feedback, professional, or diplomatic writing they read wrong — go measured, specific, and kind, and never end on a zinger. The default is *not* punchy.
- **Em-dashes are a top AI tell now — default near-zero, not budgeted.** Replace with commas, periods, or parentheses; reserve the em-dash for a genuine interruption. Raise the count only if a `--like` sample shows you actually use them. Same caution for the rule-of-three.
- **A voice sits *between* generic and caricature.** Both are failures. Generic = no fingerprint; caricature = the fingerprint on every sentence. Aim for a center of gravity with variance.
- **Rules are defaults, not commandments.** Don't apply the grammar superstitions robotically — that makes write-well the very rule-bot it warns against (Pinker).
- **Add, don't just subtract.** Edit mode's first step is *add voice*. A draft scrubbed of every tell but still flat has not been fixed.
- **Chat is not prose.** This is for long-form content. Don't apply it to quick replies.
- **"Too much" is usually unfamiliar, not wrong.** The risk is rarely going too far; it's not going far enough.

## Changelog

### V2.1 (2026-06-04) — register-first + register voices (real-use feedback)
From using V2 on performance feedback, where the punchy default fought the task. Four fixes:
- **Register & tone, set first.** The punch bias (short kicks, the dramatic closer, "don't narrate the landing") is now explicitly a *register tool* for marketing/fiction/essay — **not the default**. Measured registers (feedback, professional, diplomatic, reference, academic) get even rhythm, balance, and substance-led endings.
- **Named the punchy short-fragment closer as its own AI tell** — don't reach for it by reflex; close on substance in measured prose.
- **Em-dashes → near-zero by default** (a top AI tell now), not the old ~4/1,000 budget; triples tightened. Budget rises only if a `--like` sample uses them.
- **Register voices** (`plain-professional`, `warm-feedback`, `diplomatic`, `executive-brief`, `conversational`, `academic`, `punchy-marketing`, `storyteller`) — pickable by *what you're writing*, since the author-name voices are useless if you don't know the author. Author voices kept as a power-user library.

### V2 (2026-06-02) — voices & personas + the craft canon
Two research-backed expansions ([deep-research](deep-research) on the style canon + on voice/persona/stylometry):
- **Voices & personas system** — `--voice` / `--persona` / `--like`, built on a 6-axis voice fingerprint (diction, syntax, rhythm-variance, POV, tone/punctuation, stance) with a starter library + 2–4 exemplars each. Engineered against the two documented failure modes: regression-to-generic (arXiv 2509.14543 — "LLMs default to a generic style… stripping the personal touch") and caricature/stereotype-amplification. The persona/voice split follows the rhetoric distinction (ethos/persona = the *implied author*, separate from style mechanics).
- **The craft canon** — a deduped positive ruleset across ten authorities, adding what the anti-AI references lacked: Williams' characters-as-subjects + cohesion (old→new), Lanham's Paramedic Method, McPhee's structure law, Pinker's classic style + curse-of-knowledge, and the **rules-as-defaults-not-commandments** principle (Pinker vs Strunk/Orwell — keep the positive maxims, demote the grammar superstitions). Deliberately did NOT add the no-passive/no-split-infinitive folklore.

### V1 (2026-05-27)
Merged `human-writing` (drafting craft) + `humanizer` (29-pattern edit catalog) into one positively-framed skill: lead with *what good writing has* (voice, VAKS, rhythm, specificity, story-first) and treat AI tells as the absence of those, fixed in `edit` mode. Added Gary Provost's sentence-variety/read-aloud principle. Genericized domains (no project-specific names). Sources: VAKS + story arc (Vinh Giant); edit catalog (Wikipedia "Signs of AI writing"); rhythm (Provost).

## References
- [references/craft-canon.md](references/craft-canon.md) — the deduped positive ruleset from the ten authorities, with sources
- [references/voices.md](references/voices.md) — the 6-axis fingerprint model + named voice/persona library
- [references/prose-craft.md](references/prose-craft.md) — fiction prose craft + anti-AI rules
- [references/edit-catalog.md](references/edit-catalog.md) — the 29 AI-tell patterns, before/after
- [references/banned-words.md](references/banned-words.md) · [references/domains.md](references/domains.md)
