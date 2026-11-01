# Keyhole catalog (K01-K04)

A keyhole is a limit that makes users see or enter the world through a smaller opening than they, their screen, or their data need. Nothing technical forces the limit; somebody picked a number. The idea and the name come from Scott Meyers' *The Keyhole Problem* (see [Sources](#sources)).

K-ids are **not scored items**, and unlike T-ids they are **never a `rule`**. Each keyhole is filed with the scored item named in **File under** as `rule` and its K-id in `also`, so it lowers that item and nothing else. A K-id in `also` adds no weight and never touches `slop_score`. One exception, the same one the slop pass uses: when the keyhole also fails a WCAG SC (clipped content at 320 px is `1.4.10`), the SC is the `rule` and the home item plus the K-id go in `also`.

| id | Keyhole | Detect | File under | Not a keyhole when |
|---|---|---|---|---|
| K01 | Fixed-width editor or content column in a wide viewport: a code editor, textarea, table, or document pane pinned to a few hundred px while the rest of the screen sits empty and the content scrolls or wraps | visual at the widest captured viewport; computed `max-width` / `width` on the editing surface | H7 | Prose with a measure set for reading (about 45-90 characters per line); a fixed width that the user can widen |
| K02 | Pane, dialog, sidebar, or textarea the user cannot resize when its content outgrows it: `resize: none`, fixed-size modals, split views with no splitter, a fixed-height scroll box showing a few lines of long content inside a tall page | DOM and styles; visual for clipped or inner-scrolling content | H3 | The content always fits; a mobile sheet that goes full-screen; a fixed size the platform convention requires |
| K03 | Truncation with no escape: ellipsized or clipped text (names, paths, IDs, table cells, select options, notification text) with no tooltip, expand, wrap, detail view, or copy action that shows the full value | visual; DOM for `text-overflow: ellipsis`, `line-clamp`, `overflow: hidden` without a `title`, disclosure, or link to the full value | H6 | The full value is one obvious action away; decorative text where the rest adds nothing |
| K04 | Arbitrary input limits: a `maxlength`, pattern, or validator stricter than the real data (short name or address caps, password maximums, rejecting `+` in email, apostrophes or hyphens in names, spaces or dashes in phone numbers, non-ASCII letters), or a limit the user only learns about at submit | DOM attributes and validation rules; client-side validity checks, no extra submits (see notes) | postels-law, with H5 in `also` when the limit is only revealed at submit | A limit with a real reason (a fixed-format ID, a downstream system) that is shown before typing and explained in the error |

## Detection notes

- **K01 needs width.** Judge it at the widest viewport in the capture, and name that viewport in `evidence`. Never add a viewport mid-loop, because that changes `target.capture` and forces a baseline reset. A caller who cares about wide screens adds 1920x1080 to the capture when the baseline is set.
- **K04 never adds submissions.** Type realistic values, not attacks (`O'Brien-Núñez`, `ana+news@example.com`, `+1 (555) 010-0199`, a 64-character password, a 120-character street address), blur the field, and read `maxlength`, `pattern`, `validity`, `validationMessage`, and any inline error. Do not submit. The only real submit in a run is the slop pass's single one, with the caller's test address. A limit enforced only on the server is out of reach here: say so in the summary.
- **Screenshot-only runs** can see K01, most K03, and clipped K02. They cannot see `maxlength` or validators, so K04 is not checked; say so in the summary, not as a guess.

## Severity and tier

Ordinary severity rules apply. Two common overrides:

- A K04 limit that rejects a valid value on the primary task (signup, checkout, the core create form) **blocks the primary task**: P0. Put the rejected value and the exact error text in `evidence`, since the P0 refuter sees only the screenshots, the brand doc, and the finding.
- A K03 truncation that hides a value the user needs to finish the task (which account, which file, the full error) is at least severity 3.

## Fix lookup

| id | Typical fix |
|---|---|
| K01 | Let the editing surface grow with the viewport, or give it a drag handle or a full-width toggle; keep a reading measure on prose only |
| K02 | Allow `resize` on textareas, make dialogs and splitters resizable or let the dialog grow with content, or open long content in a full view |
| K03 | Wrap, or show the full value on hover and focus, in a detail view, or with a copy action; keep the distinguishing end of IDs and paths visible |
| K04 | Raise or remove the limit to match the real data, normalize input instead of rejecting it, and show any real limit before typing |

## Sources

| Source | License | Used for |
|---|---|---|
| Scott Meyers, *The Keyhole Problem* ([draft chapters](https://www.aristeia.com/TKP/)) | cited, not copied | The keyhole idea and name, and the four families. Wording and detection rules are ours. |
