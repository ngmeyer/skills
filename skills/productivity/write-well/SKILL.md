---
name: write-well
description: >
  Write prose with craft and a real voice, and edit flat or AI-flavored prose to find it.
  Two modes: `draft` (write from scratch) and `edit` (bring voice to existing text against
  a pattern catalog). Adopt any voice or persona: `--voice <name>` from a library,
  `--persona <name|desc>` (voice plus worldview), or `--like <sample>` to clone one. Backed by
  a deduped craft canon (Strunk, Zinsser, Orwell, Williams, Lanham, Clark, Pinker, Le Guin,
  McPhee, Provost) plus the full AI-tell catalog. The core idea is positive: great writing has
  a person behind it, and the so-called AI tells are just the absence of voice. Use when DRAFTING
  or EDITING fiction, blog posts, essays, marketing copy, newsletters, or any long-form prose.
  NOT for code, technical docs, or chat replies. Trigger: 'write this', 'draft this', 'make this
  better', 'give this voice', 'in the voice of', 'does this sound like AI', 'humanize', 'apply my style'.
argument-hint: "<topic or text> [--voice <name>] [--persona <name|desc>] [--like <sample>]"
---

# write-well

Great prose has a person behind it: a voice, a body, opinions, a sense of rhythm. The patterns that make writing "sound like AI" (significance inflation, rule-of-three, em-dash spray, flat reporting) are **symptoms of one disease: no voice.** So the move is positive. *Add* craft and voice, and the tells disappear on their own. Subtracting tells from voiceless prose just gives you cleaner voiceless prose.

## Two modes

| Mode | For | Starting point |
|---|---|---|
| **draft** (default) | writing from scratch | a topic, an outline, a blank page |
| **edit** | text that's flat, generic, or AI-flavored | an existing draft to bring alive |

Both modes serve the same core. They just enter from different ends.

## The core — what good prose has (both modes)

1. **Voice.** A real person reacting, not a neutral reporter. Opinions ("I genuinely don't know how to feel about this"), acknowledged complexity ("impressive but unsettling"), first person when it fits, a little mess (tangents, self-correction). Voiceless-but-clean is as obvious as slop.
2. **Reliving, not reporting (VAKS).** Most weak writing *reports* ("I met her at a bar, did a trick, won her over"). Good writing *relives* it with sensory detail: **V**isual, **A**uditory, **K**inesthetic, **S**mell. Every scene or section needs ≥2 VAKS ingredients, at least one non-visual. Diagnostic: "am I watching a movie or reading a news summary?" Summary means add VAKS.
3. **Rhythm — vary sentence length.** The single biggest lever for "music." Short sentences punch. Then a longer one builds and breathes and carries the reader somewhere before it sets them down. Then a fragment. If every sentence is the same length, the prose is a monotone (Provost). **Read it aloud.** Your ear catches what your eye skims.
4. **Specific over abstract.** "I moved schools four times because I kept getting bullied" beats "I had a difficult childhood." Dense, concrete words carry more than vague ones. Name the thing.
5. **Story-first structure.** Hook, Struggle, Breakthrough, Application. Drop into a moment, relive the difficulty, *show* the turn, link to the point **last**. The AI default inverts this (state the lesson, backfill with anecdotes), and the result reads like a sermon. Lead with life; arrive at the principle. *(Register-gated; see below. A performance review is not a personal essay.)*

## Punctuation budget — a generation rule, not a cleanup

Set this **while writing**, not in a later pass. The em-dash is the loudest AI tell, and the model's instinct is to oversupply it.

- **Em-dash budget: aim for zero, cap at ~2 per 1,000 words** of nonfiction. Don't type the em-dash in the first place. Reach for a comma, a period (start a new sentence), a colon (when the second half delivers on the first), or parentheses (a true aside) instead. Reserve the em-dash for a genuine interruption or hard reversal, and spend it deliberately.
- **Count in the final pass.** Search the draft for every `—`, and replace each one that isn't an earned interruption. If a draft of 600 words has eight em-dashes, seven are wrong.
- This is a **default with one exception:** a `--voice`/`--like` whose own fingerprint runs on em-dashes (DFW, some essayists) restores them, because the voice outranks the house default. Absent that signal, stay near zero.
- Same discipline, lighter touch, for the **rule-of-three** and the **short-fragment closer** below: countable habits, not reflexes.

## Register & tone — set this first

The core has a bias toward **punch**: short kicks, high-contrast rhythm, the dramatic short-fragment closer ("She did that."), "don't narrate the landing." That register is right for **marketing, fiction, and personal essays**, and wrong everywhere else. Set the register *before* you reach for those tools. Ask or infer it from the task if it isn't given.

| Register | Wants | Avoid |
|---|---|---|
| **Punchy / dramatic** (marketing, fiction, personal essay) | short kicks, the *earned* closer, contrast, voice turned up | flatness, hedging |
| **Measured / professional** (performance feedback, business, diplomatic, reference, academic) | specific, balanced, kind; even rhythm; substance-led; claims you'd stand behind | the zinger ending, manufactured drama, the fragment closer |

**The punchy short-fragment closer is now its own AI tell.** Don't reach for it by reflex. In measured registers, *close on substance, not a kick*: the last line lands a point, it doesn't perform one. **Performance feedback** specifically: lead with the specific behavior and its impact, balance strength and growth, stay warm and direct, never end on a one-liner.

## Voices & personas

By default write-well calibrates a voice to the piece, audience, and **register** (above). You can also set one explicitly, and the LLM *adopts* it with no config needed:

- `--voice <name>` adopts a named voice. **Two libraries:** pick a **register voice** by *what you're writing* (`plain-professional`, `warm-feedback`, `diplomatic`, `executive-brief`, `conversational`, `academic`, `punchy-marketing`, `storyteller`), no author knowledge needed, or an **author voice** if you know it (Hemingway, Didion, and so on).
- `--persona <name|description>` is a voice **plus a stance/worldview** (the implied author, e.g. "skeptical engineer"). A persona writes *as someone*.
- `--like <sample path or paste>` **clones** a voice: read the sample's fingerprint and write toward it. Use this to match *your* habits, including whether you use em-dashes at all.

Every voice is one **6-axis fingerprint**: diction · syntax (parataxis↔hypotaxis, clause-nesting) · rhythm (sentence-length *variance*) · POV/distance · tone/punctuation · stance (persona only). The first five are clonable from a sample; stance is the rhetorical layer you describe, not sample. Full model plus a starter library (Hemingway, McCarthy, DFW, Vonnegut, Morrison, Didion, Thompson, Faulkner, Ogilvy) with 2–4 exemplars each: [references/voices.md](references/voices.md).

**Two failure modes — engineer against both** (a voice tuned away from one drifts into the other):
- **Regression to generic** (the default gravity, where the LLM falls back to bland web-average). Guard: make the voice's *most distinctive* axis a **hard constraint** (e.g. Hemingway means no subordinating conjunctions) and pass 2–4 exemplars.
- **Caricature** (maxing every axis into parody: "and…and…and" every line). Guard: treat the fingerprint as a **center of gravity *with variance***, not a rule applied to 100% of sentences. Real voices vary.

In `edit`/rewrite, **separate meaning from style**: re-skin the voice, keep the content, and watch for meaning drift.

## The craft canon

The five-part core is the spine. The full positive ruleset, deduped across Strunk, Zinsser, Orwell, Williams, Lanham, Clark, Pinker, Le Guin, McPhee, and Provost, lives in [references/craft-canon.md](references/craft-canon.md). The load-bearing rules beyond the core:

- **Characters as subjects, actions as verbs; kill nominalizations** (Williams). The strongest *positive* clarity engine: it tells you what to build, not just what to delete.
- **Cohesion: open with old information, end with the new** (Williams). This is what makes paragraphs *flow*, not just sentences shine.
- **The Paramedic Method** (Lanham) for edit mode: circle prepositions and be-verbs, find the action, make the doer the subject, start fast.
- **Right-branch; emphatic word last; keep related words together** (Clark; Strunk & White R22/R20). Information order *within* the sentence: don't split the subject from its verb.
- **Express coordinate ideas in similar form** (Strunk & White R19). Like content in like grammatical form, most load-bearing in lists, goals, tenets, and headings, where a broken parallel reads as a stumble.
- **Make the paragraph the unit; front the point in exposition/argument** (Strunk & White R13). The register counterpart to the core's story-first rule: narrative *delays* the point, argument *fronts* it. A memo paragraph opens with its claim; an essay paragraph opens with a moment.
- **Structure from the material, kept invisible; write the lead first** (McPhee). The nonfiction structure model.
- **Classic style** (Pinker): prose as a window. Show the reader what you see, as an equal. The default stance for essay/newsletter/blog.
- **Beat the curse of knowledge** (Pinker). You're too close to the subject to see what the reader doesn't know, so use a test reader.

**Rules are defaults with reasons, not commandments.** Keep the positive maxims, but the grammar *superstitions* (never the passive, never split an infinitive, never open with "however") are folklore. Know *why* a rule exists, then break it when it serves the reader. Inviolable: voice, specificity. Calibration-dependent: em-dash budget, tricolon limit, passive voice (use it when the acted-upon is the reader's focus).

## draft mode

Write the piece, holding the core (and the chosen voice). Plus:
- **Open on a moment, not exposition.** Sensation, dialogue, or a question, never a concept the reader doesn't care about yet. The opening earns or loses the reader.
- **POV-colored vocabulary** (fiction): a painter sees composition, an engineer sees load-bearing walls. Narration should taste like the character.
- **Dialogue does the work.** Don't narrate exposition; let characters say it, argue it, get it wrong. Each line answers the *actual* previous line. Don't prop up "said" with adverbs or explanatory verbs ("he said consolingly," "she consoled"); let the line disclose the manner (White, *don't explain too much*).
- **Don't narrate the landing.** Never state the emotional conclusion ("that changed everything"). If you have to name it, the scene didn't earn it.

Craft detail and examples: [references/prose-craft.md](references/prose-craft.md).

## edit mode

The text exists but it's flat or AI-flavored. Bring it alive:

1. **Add voice first** (the positive half). Inject opinions, complexity, first-person where it fits, varied rhythm, specific feeling. This is what most "humanize" passes skip, and it's the half that matters.
2. **Then fix the patterns.** Work the catalog of 29 recurring AI patterns (significance inflation, promotional language, superficial -ing phrases, vague attributions, rule-of-three, copula avoidance, em-dash overuse, inline-header lists, hedging, filler, sycophancy, and the rest) with before/after fixes: [references/edit-catalog.md](references/edit-catalog.md).
3. **Run the Paramedic Method** on bloated sentences (see the craft canon) for a mechanical concision pass.
4. **Match the target voice.** If `--voice`/`--like` is set, rewrite toward that fingerprint, not toward generic "natural."
5. **Cool off and check facts** (anything that matters). Sleep on it, reread aloud, get a second reader; verify quotations, names, and numbers. See the craft canon's [cooling-off pass](references/craft-canon.md) (Ogilvy).

## The final pass (both modes)

Cheap, high-yield. After drafting or editing, run three prompts:
1. *"Count the em-dashes; replace every one that isn't a genuine interruption."* The budget is enforced here if it slipped during drafting.
2. *"What makes this sound AI-generated or flat?"* Name the remaining tells honestly.
3. *"Now fix exactly those."* Revise.

This catches what the first pass missed.

## Banned words & phrases

Hard-ban list (delve, tapestry, testament to, "It's not just X, it's Y", "at its core", bold-colon bullets, and so on): [references/banned-words.md](references/banned-words.md). Quick gut-check: if a sentence "says everything and means nothing," cut it.

## Self-review checklist

- [ ] **Voice** — is there a person here? Opinions, complexity, a pulse? *(If a voice/persona was set: is its most distinctive axis actually present, and not caricatured?)*
- [ ] **VAKS** — every scene or section has ≥2 sensory ingredients, ≥1 non-visual?
- [ ] **Rhythm** — sentence lengths vary? Read one paragraph aloud; does it have music?
- [ ] **Clarity** — subjects name the characters, verbs name the actions? Nominalizations un-buried? Sentences open old, close new?
- [ ] **Structure** — leads with a moment, lesson last?
- [ ] **Specific** — concrete over abstract? Named, not vague?
- [ ] **Register fits the task** — punchy only where it belongs; no reflexive zinger or short-fragment closer in feedback, professional, or diplomatic prose.
- [ ] **Em-dash budget met** — counted, ≤2 per 1,000 words, ideally zero; each surviving em-dash is a genuine interruption. Replace the rest with commas, periods, colons, or parentheses. **Triples** cut unless there are genuinely three things; no triple anaphora (X. Y. Z.); paragraph lengths varied.
- [ ] Banned words scanned; bold-colon and rule-of-three patterns gone.
- [ ] **Final pass** run (count em-dashes, diagnose, revise).
- [ ] American English (color, gray, traveled).

## Domains

Generic domain notes (apply the core, weight differently): [references/domains.md](references/domains.md) covers fiction, articles/essays, marketing/testimonials, and faith/values content. For a specific project, layer that project's own style guide on top. This skill is the foundation, not the override.

## Gotchas

- **The em-dash rule only works if you obey it while writing.** "Near-zero" as a review-pass note failed in practice: the model drafts in em-dashes and the cleanup doesn't catch them all. Treat the budget as a generation rule (don't type it), then *count* in the final pass. The skill's own files are held to the same budget, and its eval fails if they regress, because the prose write-well is written in is the example the model imitates.
- **Over-correcting kills voice.** Applying every rule rigidly produces sterile prose, as obviously AI as the tells. The core is the goal; the rules are guardrails. When in doubt, keep the voice.
- **Set the register before the punch.** The dramatic levers (short kicks, the fragment closer, manufactured drama) belong to marketing, fiction, and personal essay. In performance feedback, professional, or diplomatic writing they read wrong, so go measured, specific, and kind, and never end on a zinger. The default is *not* punchy.
- **A voice sits *between* generic and caricature.** Both are failures. Generic means no fingerprint; caricature means the fingerprint on every sentence. Aim for a center of gravity with variance.
- **Rules are defaults, not commandments.** Don't apply the grammar superstitions robotically; that makes write-well the very rule-bot it warns against (Pinker).
- **Add, don't just subtract.** Edit mode's first step is *add voice*. A draft scrubbed of every tell but still flat has not been fixed.
- **Chat is not prose.** This is for long-form content. Don't apply it to quick replies.
- **"Too much" is usually unfamiliar, not wrong.** The risk is rarely going too far; it's not going far enough.

## Changelog

### 1.0 (2026-06-10) — first release
First real version of write-well. **Lightly tested in real prose so far** (a few passes), so expect iteration; the dated entries below are the pre-release development log, not a maturity claim. 1.0 ships the five-part core, the voices & personas system (6-axis fingerprint, register + author libraries, the two failure-mode guards), the deduped craft canon (Strunk, Zinsser, Orwell, Williams, Lanham, Clark, Pinker, Le Guin, McPhee, Provost, plus Ogilvy and Strunk & White 4th-ed), the 29-pattern AI-tell edit catalog, and a countable em-dash budget the skill dogfoods.

The fix that triggered cutting 1.0: write-well's *output* ran heavy on em-dashes. Two root causes, both addressed:
- **The rule was advisory and post-hoc.** "Near-zero" lived in the checklist and Gotchas, a cleanup pass the model was trusted to run after drafting. Replaced with a **countable generation-time budget** (aim zero, cap ~2 per 1,000 words nonfiction; don't type it, then *count* `—` in the final pass and replace each non-interruption). New "Punctuation budget" section, hardened checklist item, and a first final-pass prompt that counts.
- **The skill contradicted itself.** Its own SKILL.md ran ~30 em-dashes per 1,000 words, full spray, so the in-context exemplar taught the opposite of the rule. Rewrote SKILL.md to meet its own budget, and added a **dogfood eval** (`tests/eval.sh` counts em-dash density in the skill's files and fails if SKILL.md regresses). The voice-override exception (DFW and the like) is preserved.

**Development log (pre-1.0) — what was built, and when. The V-numbers are the build passes, not shipped releases.**

### V2.3 (2026-06-07) — Strunk & White studied in full (4th edition, the source of record)
Studied *The Elements of Style*, 4th ed. (the source provided), and drew the composition principles from it (copyrighted text consulted and paraphrased, not reproduced). Strunk was already credited five times (omit-needless-words, active voice, positive form, specific/concrete, emphatic-word-last); the dedup had hidden him. Three genuinely-new rules added, plus a resolved tension. **All numbering follows the 4th edition, matching six-pager** (an earlier draft used the 1918 numbers, corrected against the 4th-ed text):
- **Express coordinate ideas in similar form** (Rule 19). New canon rule; load-bearing in lists, goals, tenets, headings.
- **Keep related words together** (Rule 20). New; proximity shows relationship, so don't split subject from verb.
- **Make the paragraph the unit of composition** (Rule 13). New, *register-gated*: exposition/argument fronts the point; the core's story-first rule still governs narrative. Precision note: the 4th ed *dropped* the explicit "begin with a topic sentence" (that's Strunk's 1918 Rule 9, condensed into Rule 13), so it's prescribed by name, not cited as a 4th-ed rule.
- **Voice vs. White's "do not inject opinion."** Stated and resolved: White cuts *gratuitous* opinion in exposition; write-well's voice is earned, relevant stance. Register decides.
- Folded "avoid a succession of loose sentences" (Rule 18) into the vary-rhythm rule. Left the Elementary Rules of Usage (Rules 1–11: comma/colon/dash/agreement/case) out, since those are correctness, not craft.
- **Then studied White's Chapter V ("An Approach to Style").** Finding: it adds no new positive rule; it supplies the *restraint half* of voice. Added a **voice-discipline note** (place yourself in the background, don't overwrite or overstate, no breezy manner, prefer standard to offbeat, don't explain too much) tied to the existing caricature failure mode, and sharpened draft mode's dialogue rule (no adverb-propped "said"). White independently corroborates the AI-tell catalog from the stylist's side.

### V2.2 (2026-06-07) — Ogilvy's "How To Write" memo, incorporated three ways
From Ogilvy's 1982 staff memo (the 10 rules plus the Roman & Raphaelson lineage it points to). Sorted by *what kind of rule each is*, not bolted on whole, since the memo is mostly a business-register playbook, not new core rules:
- **Core canon.** Ogilvy added as a cited authority (short words, no jargon already lived in the canon; he corroborates, doesn't duplicate).
- **Edit-process.** A new *cooling-off pass* in the craft canon: sleep on it, then reread aloud and edit, get a colleague to improve it, check your quotations and facts. Surfaced as edit-mode step 5.
- **Register layer.** Rules 2/5/9/10 folded into the business registers (`plain-professional`, `executive-brief`, `punchy-marketing`): write the way you talk, ≤2 pages, **make the desired action unmistakable**, and don't-write-when-you-should-talk as the register's boundary.
- **Author voice.** Added `ogilvy` to the voices library (the ad-man's prose: concrete, benefit-led, zero jargon), distinct from applying his rules.

### V2.1 (2026-06-04) — register-first + register voices (real-use feedback)
From using V2 on performance feedback, where the punchy default fought the task. Four fixes:
- **Register & tone, set first.** The punch bias (short kicks, the dramatic closer, "don't narrate the landing") is now explicitly a *register tool* for marketing/fiction/essay, **not the default**. Measured registers (feedback, professional, diplomatic, reference, academic) get even rhythm, balance, and substance-led endings.
- **Named the punchy short-fragment closer as its own AI tell.** Don't reach for it by reflex; close on substance in measured prose.
- **Em-dashes → near-zero by default** (a top AI tell now), not the old ~4/1,000 budget; triples tightened. Budget rises only if a `--like` sample uses them.
- **Register voices** (`plain-professional`, `warm-feedback`, `diplomatic`, `executive-brief`, `conversational`, `academic`, `punchy-marketing`, `storyteller`), pickable by *what you're writing*, since the author-name voices are useless if you don't know the author. Author voices kept as a power-user library.

### V2 (2026-06-02) — voices & personas + the craft canon
Two research-backed expansions ([deep-research](deep-research) on the style canon plus on voice/persona/stylometry):
- **Voices & personas system.** `--voice` / `--persona` / `--like`, built on a 6-axis voice fingerprint (diction, syntax, rhythm-variance, POV, tone/punctuation, stance) with a starter library plus 2–4 exemplars each. Engineered against the two documented failure modes: regression-to-generic (arXiv 2509.14543, "LLMs default to a generic style… stripping the personal touch") and caricature/stereotype-amplification. The persona/voice split follows the rhetoric distinction (ethos/persona is the *implied author*, separate from style mechanics).
- **The craft canon.** A deduped positive ruleset across ten authorities, adding what the anti-AI references lacked: Williams' characters-as-subjects plus cohesion (old→new), Lanham's Paramedic Method, McPhee's structure law, Pinker's classic style plus curse-of-knowledge, and the **rules-as-defaults-not-commandments** principle (Pinker vs Strunk/Orwell: keep the positive maxims, demote the grammar superstitions). Deliberately did NOT add the no-passive/no-split-infinitive folklore.

### V1 (2026-05-27)
Merged `human-writing` (drafting craft) plus `humanizer` (29-pattern edit catalog) into one positively-framed skill: lead with *what good writing has* (voice, VAKS, rhythm, specificity, story-first) and treat AI tells as the absence of those, fixed in `edit` mode. Added Gary Provost's sentence-variety/read-aloud principle. Genericized domains (no project-specific names). Sources: VAKS plus story arc (Vinh Giant); edit catalog (Wikipedia "Signs of AI writing"); rhythm (Provost).

## References
- [references/craft-canon.md](references/craft-canon.md) — the deduped positive ruleset from the ten authorities, with sources
- [references/voices.md](references/voices.md) — the 6-axis fingerprint model plus named voice/persona library
- [references/voice-examples.md](references/voice-examples.md) — one passage rewritten across voices (Hemingway, McCarthy, DFW, Didion, Ogilvy, executive-brief)
- [references/prose-craft.md](references/prose-craft.md) — fiction prose craft plus anti-AI rules
- [references/edit-catalog.md](references/edit-catalog.md) — the 29 AI-tell patterns, before/after
- [references/banned-words.md](references/banned-words.md) · [references/domains.md](references/domains.md)
