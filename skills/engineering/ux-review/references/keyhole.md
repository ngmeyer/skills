# Keyhole pass (K01-K04)

A keyhole is an arbitrary restriction on the user's ability to see or express something: looking at a room through the keyhole in its door. The ones that matter are **gratuitous**: nothing technical forces the limit, somebody picked a constant where a variable belongs. The idea, the name, and the "gratuitous" test come from Scott Meyers' *The Keyhole Problem* (see [Sources](#sources)).

The keyhole pass is a **standard, always-run** part of every review. Every run walks K01-K04 on every captured screen. A family the capture cannot show (K04 on a screenshot-only run) is reported as not checked in the summary, never guessed and never silently skipped.

**Filing.** K-ids are not scored items and are **never a `rule`**. File each keyhole under the heuristic it breaks, as `rule`: `H7` (flexibility and efficiency) for room the content can't use, `H3` (user control and freedom) for limits the user can't lift, `H6` (recognition rather than recall) for hidden text the user has to remember. Put the K-id, and any law named below, in `also`. Start `evidence` with `keyhole:` followed by the measured numbers (content box vs. viewport width, visible rows vs. total, the limit vs. a realistic value). One exception: when the keyhole also fails a WCAG SC (content clipped at 320 px is `1.4.10`), the SC is the `rule`, and the heuristic plus the K-id go in `also`.

| id | Keyhole | Detect | Rule | Not a keyhole when |
|---|---|---|---|---|
| K01 | **Primary content in a keyhole.** The editor, document, canvas, table, or image the primary task works on is pinned to a fixed width or height while wide empty bands of the viewport go unused, or scrolls in a small inner box inside a page that also scrolls | Widest captured viewport: content box width and height vs. viewport; computed `max-width`, `width`, `height` on the working surface | H7 | Prose with a reading measure (about 45-90 characters a line) inside a pane that fills the space; a fixed width the user can widen |
| K02 | **Panes that can't flex.** A sidebar, panel, dialog, splitter, or textarea with a fixed size and no resize, collapse, or maximize, so content that outgrows it clips or scrolls in a few lines | DOM and styles (`resize: none`, fixed dialog size, no splitter); visual for clipped or inner-scrolling content | H3 | The content always fits; a mobile sheet that goes full-screen; a size the platform convention fixes |
| K03 | **Truncation with no way out.** Names, titles, paths, IDs, table cells, select options, or an input's own value cut with an ellipsis or clipped, with no tooltip, wrap, expand, detail view, or copy action; lists capped at N with no "show all" | Visual; DOM for `text-overflow: ellipsis`, `line-clamp`, `overflow: hidden`, or `scrollWidth > clientWidth` on an input, with no `title`, disclosure, or link to the full value | H6 | The full value is one obvious action away; decorative text where the rest adds nothing |
| K04 | **Expression limits.** A `maxlength`, pattern, or validator stricter than real data: short name or address caps, password maximums, rejecting `+` in email, apostrophes, hyphens, or non-ASCII letters in names, spaces or dashes in phone and card numbers; or a limit the user only learns at submit | DOM attributes and client-side validity (see notes); never extra submits | H3, with `postels-law` in `also`, and `H5` too when the limit appears only at submit | A limit with a real reason (a fixed-format ID, a cap the backend truly enforces) that is shown before typing and explained in the error |

## Detection notes

- **Measure both ends.** Judge K01 and K02 at the widest captured viewport and K03 at the narrowest, and name the viewport in `evidence`. A centered fixed-width card looks tidy at 1280 px; it is a keyhole only when the screen has room the content can't use. A work surface (editor, IDE, design tool, table) should grow with the window. Don't add a viewport mid-loop, because that changes `target.capture` and forces a baseline reset; add wide viewports when the baseline is set.
- **K04 never adds submissions.** Type realistic values, not attacks (`O'Brien-Núñez`, `ana+news@example.com`, `+1 (555) 010-0199`, a 64-character passphrase, a 120-character street address), blur the field, and read `maxlength`, `pattern`, `validity`, `validationMessage`, and any inline error. Do not submit. The only real submit in a run is the slop pass's single one, with the caller's test address. A limit enforced only on the server is out of reach: say so in the summary.
- **Screenshot-only runs** can see K01, most of K03, and clipped K02. They cannot see `maxlength` or validators, so K04 is reported as not checked.

## Severity and tier

- Severity 3 when the keyhole constrains the primary task's content (K01 on the core editor, K03 hiding the value the user needs to finish: which account, which file, the full error). Otherwise severity 2.
- A K04 limit that rejects a valid value on the primary task (signup, checkout, the core create form) **blocks the primary task**: P0. Put the rejected value and the exact error text in `evidence`, because the P0 refuter sees only the screenshots, the brand doc, and the finding.
- **Guard.** A limit with a real reason is not gratuitous: file nothing and say why in the human summary. If you can't name the real screen or real data the limit fails, there is no finding.

## Fix lookup

| id | Typical fix |
|---|---|
| K01 | Size the working surface from the viewport or the content, or give it a drag handle or full-width toggle; keep a reading measure only on prose |
| K02 | Allow `resize` on textareas, make splitters and dialogs resizable or let them grow with content, add collapse or maximize, or open long content in a full view |
| K03 | Wrap, or show the full value on hover and focus, in a detail view, or with a copy action; keep the distinguishing end of IDs and paths visible; add "show all" |
| K04 | Raise or remove the limit to match real data, normalize input instead of rejecting it, and show any real limit before typing |

## Sources

| Source | License | Used for |
|---|---|---|
| Scott Meyers, *The Keyhole Problem* ([project page and draft overview paper](https://aristeia.com/TKP/)) | cited, not copied | The keyhole definition ("arbitrary restrictions on your ability to see or express something"), the name, and the focus on gratuitous keyholes. The four families, detection rules, and wording are ours. |
