# Tell catalog (T01-T23)

**Weights are a starting point, calibrate.** They are adapted from the IOV Labs tell weights (hankimis/ai-design-tells), where higher is a stronger signal; tells with no IOV weight got a proposed one. Style weights sum to 99. Proof tells (marked P0) carry no weight: they gate, they do not score. Detect: `tokens` = CSS and design tokens, `styles` = computed styles, `DOM`, `visual` = screenshots, `copy` = visible text, `ask` = a source from the caller or `proof.json`.

| id | Tell | Family | Detect | Wt | False-positive guard (craft credit) |
|---|---|---|---|---|---|
| T01 | "House indigo": Tailwind indigo-500 or violet as the primary or accent | color | tokens | 9 | An established brand purple, documented and used consistently |
| T02 | Purple-to-blue gradient washes; gradient text in headlines | color | tokens | 7 | The gradient is a documented brand asset |
| T03 | Inter-only or system-default type with no contrast in the scale | type | styles | 9 | Inter with a deliberate scale, weights, and spacing |
| T04 | Three identical feature cards: icon tile, heading, two lines | layout | visual | 8 | Genuinely three parallel items, each with its own visual |
| T05 | Emoji as bullets or icons | iconography | DOM | 6 | Emoji is the product's voice and is not standing in for icons |
| T06 | Sparkle icon and "AI-powered" badges | iconography, copy | DOM, copy | 5 | AI is the product and the badge says what it does |
| T07 | Stock icon set only, used as decoration, no custom iconography | iconography | DOM | 4 | Icons are functional controls |
| T08 | Reflexive glassmorphism (`backdrop-filter` panels) | surface | tokens | 4 | Overlay on real imagery where the blur helps legibility |
| T09 | One radius and one soft shadow everywhere; cards inside cards | surface | tokens | 4 | Radius and elevation system documented in tokens |
| T10 | Everything centered, no grid tension | layout | visual | 5 | n/a on single-purpose pages (login, 404, checkout) |
| T11 | Stock section order: hero, logos, three features, testimonials, three-tier pricing with a highlighted middle, FAQ, CTA, email signup | layout | visual | 5 | Counts only with at least two other style tells |
| T12 | Vague hero copy ("unlock the power of", "elevate", "seamless", "revolutionize", "the AI-powered X for modern Y") | copy | copy, delegate | 6 | None. Always a specific claim instead |
| T13 | Em-dash habit in UI copy | copy | count, delegate | 4 | Long-form editorial pages; follow the copy skill's budget |
| T14 | Testimonials with no source, or a testimonial wall with stock avatars | proof | visual, ask | P0 | Each quote sourced in `proof.json` |
| T15 | "Trusted by" logo strip with no customer relationship on file | proof | visual, ask | P0 | Real customers, with permission on file |
| T16 | Implausible or unsourced stats ("10,000+ teams", animated counters) | proof | copy, ask | P0 | A sourced number with a date |
| T17 | Template chrome: tracked all-caps eyebrows, "A · B · C" meta strings, mono labels, an arrow on every button, one colored word per headline, 01/02/03 on things that are not a sequence | type, layout | DOM, visual | 4 | Used once, on purpose |
| T18 | The same fade-and-slide-in on every section | motion | DOM | 3 | Sparing, and honors reduced motion |
| T19 | No hover, focus, or active states (an untouched component-kit default) | states | DOM, a11y | 7 | None. P1 when focus is missing (also `2.4.7`) |
| T20 | Fake terminal or code-window hero on a product that is not a developer tool | layout | visual | 3 | Developer tool where the terminal is the product |
| T21 | A form that shows success but stores or sends nothing | proof, flow | test submit | P0 | None |
| T22 | Gray text on colored backgrounds; an icon tile above every heading | color, layout | contrast calc | 3 | None. P1 when contrast fails (also `1.4.3`) |
| T23 | Over-corrected "anti-slop" defaults: cream with a serif and terracotta, near-black with acid green, broadsheet hairlines | color, type | tokens | 3 | The look is brand-documented |

## Sources and attribution

Ideas below are paraphrased; no text is copied unless marked.

| Source | License | Used for |
|---|---|---|
| [hankimis/ai-design-tells](https://github.com/hankimis/ai-design-tells) and the [IOV Labs paper](https://labs.iovstudio.kr/papers/ai-design-tells.pdf) | MIT, Copyright (c) 2026 Han Kim / IOV Labs | Tell families, starting weights, the 0-100 score idea, craft credit |
| [Gesso-Build/skills](https://github.com/Gesso-Build/skills/blob/main/skills/anti-slop/references/rules.md) | MIT, Copyright (c) 2026 Gesso Build, Inc. | Per-rule cap, 1-2 / 3-6 / 7+ bands, em-dash advisory mode, optional `check --json` pre-pass |
| [Nutlope/hallmark](https://github.com/Nutlope/hallmark) | MIT, Copyright (c) 2026 Hallmark contributors | Fresh-context reviewer, template chrome, dead forms |
| [Ferousco-dev/anti-slop-design](https://github.com/Ferousco-dev/anti-slop-design) | MIT, Copyright (c) 2026 Feranmi (AppMD) | Regression-to-the-mean framing, the over-correction warning |
| [miqdadbadjuber/anti-slop](https://github.com/miqdadbadjuber/anti-slop) | MIT, Copyright (c) 2026 Miqdad Badjuber | Splitting findings by concern so copy is delegated |
| [pbakaus/impeccable](https://github.com/pbakaus/impeccable) | Apache-2.0 | Optional `detect --json` pre-pass; tell ideas (gradient text, radius, gray on color). Paraphrased only, so no NOTICE is carried |
| [Anthropic frontend-design](https://github.com/anthropics/skills/blob/main/skills/frontend-design/SKILL.md) | Apache-2.0 | The list of next-generation defaults behind T17 and T23. Paraphrased only |
| [febbhav/signs-of-ai-design](https://github.com/febbhav/signs-of-ai-design) | No license asserted: cited, not copied | Tell ideas and false-positive notes, paraphrased |
| [16 CFR Part 465](https://www.ecfr.gov/current/title-16/chapter-I/subchapter-D/part-465) | US federal rule | The legal basis for treating fake reviews and testimonials as P0 |
| [Wikipedia: Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing) | CC BY-SA, cited | The "signs, not proof" framing; copy tells T12 and T13 |
