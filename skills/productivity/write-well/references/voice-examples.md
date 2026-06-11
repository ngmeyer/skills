# Voice examples — one passage, many fingerprints

A single fixed passage rewritten across voices, so the **only** variable is the voice. This is the concrete companion to [voices.md](voices.md): it shows what each 6-axis fingerprint actually *does* to the same meaning, and it shows the two failure modes (generic / caricature) being avoided — each rewrite is a *center of gravity with variance*, not the trait stamped on every sentence.

## The source

Shakespeare, *Romeo and Juliet*, Prologue (the content, stripped to prose): two old Verona families hate each other for reasons no one remembers; a boy and girl, one from each, fall in love and kill themselves; only their deaths end the feud; the play runs about two hours; watch patiently and we'll make up in effort for whatever it lacks.

> Two households, both alike in dignity / (In fair Verona, where we lay our scene), / From ancient grudge break to new mutiny… / A pair of star-crossed lovers take their life.

---

## Author voices

### `--voice hemingway`
*Parataxis, asyndeton, short declaratives, even rhythm; the iceberg (omit, let the reader fill). Em-dashes near-zero — and that's native to this voice, not the default fighting it.*

> Two families in Verona. Both old. Both proud. They hated each other. No one remembered the reason. A boy came from one house. A girl from the other. They met. They loved each other. It was not going to work. They knew it. They did it anyway. They died. The dying stopped the hate. Nothing else had. We will show you how it happened. It takes two hours. Sit down. Watch.

### `--voice "cormac mccarthy"`
*Parataxis + polysyndeton (and…and…), rolling and incantatory, mythic; minimal punctuation. The variance is the one short line dropped into the chant.*

> There were two houses in Verona and they were ancient and they were proud and the hatred between them was older than any man who carried it. A boy of the one and a girl of the other looked on each other in the dark and were undone. They loved against the wheeling of the stars and the stars gave them nothing. And they died. And the dying did what no word and no judge and no years of spilled blood had done. It buried the hatred with them in the ground.

### `--voice "david foster wallace"`
*Long nested multi-clause, self-conscious maximalism, the footnote. Note this voice deliberately overrides write-well's near-zero em-dash default — the fingerprint wins over the house style.*

> What gets lost in the two-families-in-Verona version¹ is that the hatred had by now come totally unmoored from whatever first caused it — nobody could have told you the reason, which is exactly what made it unkillable — so that when the boy from the one house and the girl from the other met and fell into the kind of love that doesn't check the situation first, the thing was already, in a sense the next two hours will make unbearably literal, over.
>
> ¹ The prologue, which spoils its own ending, on the apparent theory that suspense was never the point.

### `--voice didion`
*Elliptical, controlled, cool; exact nouns, emotional restraint, a detached dread. The shortest sentences carry the most.*

> It was an old quarrel. No one in Verona could have said how it began, only that it was understood, the way the heat in August was understood. The two children were not to meet. They met. What followed was always going to follow. The only open question was how long it would take, and it did not take long.

### `--voice ogilvy`  *(the new one)*
*The ad-man: plain, concrete, benefit-led, zero jargon; short and often imperative; one promise, one unmistakable ask. He's selling you the play — and respects you while doing it.*

> Two of the greatest families in Verona. One feud neither will end. And two children who fall in love straight across the battle line — and pay for it with their lives. Their death is the one thing on earth strong enough to stop the war between their parents. We will tell you the whole of it in two hours. It will hold you from the first line to the last. Give us your attention. We will earn it.

---

## Register voices (pick by the job, no author knowledge needed)

### `--voice executive-brief`
*Tight, front-loaded, BLUF; answer first, then support; the action stated plainly; no wind-up, no drama. This is Ogilvy's business register, not his ad voice.*

> Bottom line: two feuding Verona families lose their children — a boy and girl who fall in love and take their own lives — and those deaths are what finally end the feud. Runtime is two hours. We've staged it as tightly as we can; tell us where it falls short and we'll mend it.

---

## What this demonstrates

- **The fingerprint is the variable.** Same plot every time; diction/syntax/rhythm/stance do all the work. Hemingway and McCarthy are both paratactic, yet asyndeton vs. polysyndeton makes them unmistakable.
- **Voice overrides the house defaults.** write-well keeps em-dashes near-zero by default — but the DFW voice restores them because they're load-bearing to *that* fingerprint. The default is a default, not a law.
- **Center of gravity, not a costume.** Each piece varies its own signature (Hemingway's one longer line, McCarthy's one short one). Maxing the trait on every sentence would be the caricature failure mode.
- **`ogilvy` the voice ≠ Ogilvy the rules.** The `ogilvy` voice sells; his *rules* (≤2 pages, clear action, no jargon) live in the business registers and the canon's cooling-off pass.
