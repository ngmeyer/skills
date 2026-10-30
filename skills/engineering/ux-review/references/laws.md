# Laws of UX checklist (all 30)

Canonical list: [lawsofux.com](https://lawsofux.com/) and its [llms.txt](https://lawsofux.com/llms.txt). The `law_id` is the site's URL slug, so a ref is `https://lawsofux.com/<law_id>/`. One exception: the id `law-of-pragnanz` is kept ASCII for shell tooling, and its ref is `https://lawsofux.com/law-of-pr%C3%A4gnanz/`.

Judge every law against the screen's primary task. Record a finding with evidence, or `n/a` with a reason in `scores.na_reasons` (key `<screen>:<law_id>` when per-screen). "Looks fine" is a 4, not an n/a.

| law_id | What to check (UI-observable) | Often also |
|---|---|---|
| aesthetic-usability-effect | Polish is not masking a broken flow, and broken polish is not eroding trust | H8 |
| choice-overload | Count competing options at decision points (plans, CTAs, settings) | hicks-law |
| chunking | Long content and forms are grouped into scannable chunks | H8 |
| cognitive-bias | No manipulative defaults or dark patterns that exploit bias | H3 |
| cognitive-load | Extraneous elements, jargon, and simultaneous demands on the task screen | H8 |
| doherty-threshold | Feedback within about 400 ms: INP, Core Web Vitals, visible loading states | H1 |
| fittss-law | Primary action size and distance, thumb-zone placement, target sizes | touch-target-44 |
| flow | Mid-task interruptions: modals, forced signups, context switches | H3 |
| goal-gradient-effect | Progress indicators in multi-step flows | H1 |
| hicks-law | Choices at the primary step; is there a recommended default? | choice-overload |
| jakobs-law | Conventions: logo goes home, cart top-right, standard form and platform nav | H4 |
| law-of-common-region | Related controls share a container | law-of-proximity |
| law-of-proximity | Spacing groups related items and separates unrelated ones (labels near fields) | H8 |
| law-of-pragnanz | Simple, unambiguous shapes and layouts | occams-razor |
| law-of-similarity | Same-looking things behave the same; different things look different | H4 |
| law-of-uniform-connectedness | Visual connection (lines, containers) matches functional relation | law-of-common-region |
| mental-model | Labels, icons, and flows match domain expectations | H2 |
| millers-law | Short-term memory demands: codes to copy, steps to recall | H6 |
| occams-razor | Elements that can be removed without loss | H8 |
| paradox-of-the-active-user | Users need not read docs first; help is inline | H10 |
| pareto-principle | The most-used 20% is the most prominent | serial-position-effect |
| parkinsons-law | Tasks are as short as possible: autofill, smart defaults | H7 |
| peak-end-rule | Success and error moments are designed, not bare | H9 |
| postels-law | Inputs tolerate formats (phone, dates, paste); outputs are consistent | H5 |
| selective-attention | Critical info is not where banner blindness hides it | H1 |
| serial-position-effect | Key items sit first or last in lists and nav | pareto-principle |
| teslers-law | Complexity is absorbed by the system, not pushed to the user | H7 |
| von-restorff-effect | Exactly one visually distinct primary action per view | H8 |
| working-memory | Info needed across steps stays visible (summary panels, context) | H6 |
| zeigarnik-effect | Incomplete tasks are surfaced (drafts, setup checklists) | H1 |

## Writing the fix

A fix names the element, the change, and the expected effect, and cites the laws it serves. Example: "Move 'Create' into the thumb zone as a 48dp primary button; demote 'Import' to a text link (fittss-law, hicks-law, von-restorff-effect)."

For fix wording on common patterns, the upstream ui-ux-pro-max guideline table is a good lookup (see [sources.md](sources.md)). Name the row in the fix text, e.g. `(ui-ux-pro-max #22)`, and paraphrase; do not paste rows. Rows that map cleanly: 22 touch target size (fittss-law), 10 and 78 loading states (doherty-threshold), 35 confirmation dialogs (H5), 33 and 55 error placement (H9), 54 input labels (law-of-proximity), 7 excessive motion (cognitive-load), 4 back button (H3).
