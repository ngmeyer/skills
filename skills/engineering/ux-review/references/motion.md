# Motion and micro-interaction checklist (M01-M16)

This is a pass, not a scored section. File each miss under the existing law, heuristic, or WCAG SC the tip names (`rule` is that item; the M-id lives in `evidence` or `also`). Do not add `scores.motion` or change the 35/25/25/15 weights.

**Evidence.** Motion often cannot be seen in a still screenshot. A finding needs interaction (click, tap, scroll, open/close) or video. Otherwise write `not observable` and do not lower a score. Never fabricate a motion finding. `not observable` applies to the tip, not automatically to the linked law: if `doherty-threshold` or H1 has other evidence (INP, a visible spinner), score it as usual; if the tip was the only check and you could not observe it, do not give that check a silent 4. Confidence: 1.0 when a duration is measured in DevTools, 0.8 from a clear recording, 0.5 if easing was only eyeballed. Never use an M-id as `rule`. If the previous run was stills-only and this run has interaction or video, set `loop.decision: "baseline-reset"`; new motion findings are not a regression against a stills baseline.

**Reduced motion.** Every tip honors `prefers-reduced-motion` (and the platform Reduce Motion setting). Record the setting in `target.capture.reduced_motion`. If Reduce Motion is on, do not file missing decorative motion (scale pulse, stagger, blur, rubber-band, bounce) as a miss; check that a reduced alternative exists. Missing that handling (large motion still plays) is a [2.3.3](https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions) note (Level AAA: report-only, no grade cap). Replace large scale, blur, parallax, decorative rubber-banding, long staggers, and bounce with a short fade or an instant state change. Seizure-risk flashing - more than three flashes in one second, or above the general or red flash thresholds - is [2.3.1](https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold) (Level A). File it as P0 (safety). 2.3.1 is not in the scored WCAG basics list, so it does not by itself cap the grade at C; a live P0 still caps it at D.

Tips 7-9 on the first inspiration reel (Fitts's law, Hick's law, the Doherty threshold) are already in [laws.md](laws.md). Cross-reference them from this pass; do not file a second copy.

Numbers marked **reel heuristic** come from Instagram @theecommguy and are not standards. Verified figures cite Apple or Material. M11-M14 (Disney principles) are craft notes: they rarely become findings on everyday UI. **M16 tempers M11:** squash-and-stretch that reads as bounce on a confirm or everyday control is filed under M16, not praised as craft.

## M01-M06 Interaction craft

### M01 Pulse to confirm

**Good:** A press, tap, or click gets a short, local confirmation (highlight, ripple, or small scale) inside the Doherty window (~400 ms).
**Failure:** The control does nothing visible, so the user cannot tell the tap registered.
**Observe:** Press primary controls and watch or record the press. Stills: `not observable`.
**File under:** H1, `doherty-threshold`. If the component also has no hover, focus, or active state, that is T19: file once, with T19 in `also` when focus is missing (`2.4.7`).
**Reduced motion:** A color or opacity change still confirms; do not rely on a large scale pulse.

### M02 Expand the same element

**Good:** A modal, sheet, or expanded state grows out of the control that opened it, so the user can track the transition (Apple HIG: Motion). Set `transform-origin` toward the trigger. Pairs with M10.
**Failure:** A modal pops in at the center, unconnected to the button that launched it.
**Observe:** Open and close the overlay from its trigger. Stills: `not observable`.
**File under:** H1, `law-of-uniform-connectedness`. Also `jakobs-law` when the platform already uses a container-transform or hero transition and this screen does not.

### M03 Crossfade icons with blur

**Good:** An icon that changes meaning (menu/close, play/pause) morphs or crossfades, rather than swapping in a single frame. Blur is optional seasoning.
**Failure:** The icon teleports to a different metaphor with no transition, when motion is allowed.
**Observe:** Toggle the control. Stills: `not observable`.
**File under:** `law-of-similarity`, H4.
**Reduced motion:** Skip the blur. Apple lists animated blur as a motion trigger; a short opacity crossfade, or an instant swap, is enough.

### M04 Rubber band past the edge

**Good:** On platforms that rubber-band (iOS, many Android overscroll treatments), a scroll surface gives slightly past the edge and settles back.
**Failure:** A primary scroll surface dead-stops with no give on a rubber-banding platform, with no good reason; or a desktop page fakes a rubber band the platform does not use. Do not file a canvas, a snapped carousel, or a deliberate `overscroll-behavior: none` inside a shell that already overscrolls.
**Observe:** Overscroll a list or page. Stills: `not observable`.
**File under:** `jakobs-law`. This is not M16: edge give on scroll is a platform convention, not a dialog bounce.
**Reduced motion:** Drop decorative overscroll stretch; a hard edge is acceptable when Reduce Motion is on.

### M05 Reveal with masks

**Good:** New content is clipped or masked in, so it feels like the same surface opening, not a second copy fading on top. Material: fade outgoing content out before incoming content fades in; if a crossfade is required, keep it short.
**Failure:** A panel or image pops fully formed, or overlapping semi-transparent frames smear together.
**Observe:** Open a panel, accordion, or media reveal. Stills: `not observable`.
**File under:** H1, `law-of-uniform-connectedness`.

### M06 Stage the focus

**Good:** Motion points at the primary task. One thing leads, the rest follow or stay still (selective attention; Disney staging).
**Failure:** Every card on the page flies in together and competes for attention.
**Observe:** Load or navigate to the screen, or watch a recording of the first second. Stills: `not observable`.
**File under:** `selective-attention`, H1. Closely related to M07; file one finding if both apply.

## M07-M10, M15-M16 Timing and easing (checkable)

### M07 Stagger list rows

**Good:** Rows in a newly appearing list may enter in a short cascade so the eye can follow them. Keep the cascade brief, and do not delay the primary task.
**Failure:** A long stagger makes the list unusable, or - when a short cascade would help and motion is allowed - every row pops in as one block after a heavy load. Do not file a missing stagger on a static, already-visible list.
**Observe:** Watch the list appear. Stills: `not observable`.
**File under:** `selective-attention` or `cognitive-load` (if the cascade is the problem). Related to M06; file once.

### M08 Dropdowns in 250 ms

**Good:** A menu, select, or dropdown opens in the short-to-medium range, about 150-300 ms. Material's `medium1` token and the "Standard decelerate / enter the screen" pair are both 250 ms. **Reel heuristic:** "dropdowns in 250 ms" - treat 250 ms as a useful center, not a pass/fail tick.
**Failure:** The menu snaps open with no transition when motion is allowed, or it takes long enough to feel like waiting (well above 300 ms).
**Observe:** Open and close the menu; measure with DevTools or a recording. Stills: `not observable`.
**File under:** `doherty-threshold`, H1.

### M09 Exits shorter than entrances

**Good:** Dismiss, close, and collapse animations are shorter than the matching open. Material (M3 and M2): exits "use shorter durations" because they need less attention than the next task. Verified pairs: M3 Standard enter 250 ms / exit 200 ms, Emphasized enter 400 ms / exit 200 ms; M2 drawer 250/200, card 300/250. The reel restates the rule; those numbers are Material's, not the reel's.
**Failure:** The exit is as long as, or longer than, the entrance, so dismissal feels sticky.
**Observe:** Open and close the same overlay and compare durations. Stills: `not observable`.
**File under:** `doherty-threshold`, H1.

### M10 Start popovers at 0.95 scale, not 0

**Good:** A popover or menu starts near full size and grows from the trigger (`transform-origin` toward the control; pairs with M02). **Reel heuristic:** start at `scale(0.95)`, not `0`. That exact value is not in Apple HIG or Material. A public Chrome example starts from `scale(0.9)`, which supports "near full size" without making 0.95 a standard. Somewhere around 0.9-0.97 is the usual range; file the miss when the surface scales from 0 or from a tiny unreadable smudge, not when it starts at 0.9 instead of 0.95.
**Failure:** A dialog or menu grows from a point or from `scale(0)`.
**Observe:** Open the overlay, ideally slowed in DevTools. Stills: `not observable`.
**File under:** H1, `law-of-uniform-connectedness`.
**Reduced motion:** Prefer a short fade with no scale. Scaling is a documented vestibular trigger (Apple Reduced Motion criteria, MDN).

### M15 Ease-in-out for moves

**Good:** Movement that begins and ends on screen uses an ease-in-out / standard curve (accelerate, then decelerate), not a linear one. Material: "begin and end on screen" uses Emphasized or Standard easing; enter uses decelerate (ease-out); a permanent exit uses accelerate (ease-in). Apple: linear motion feels wrong for movement; ease-in-out keeps position and velocity continuous when starting from rest. **Reel heuristic:** "ease-in-out for moves" - that matches the on-screen case, not every enter or exit.
**Failure:** A linear slide, or a harsh ease-in, on a move that stays on screen.
**Observe:** Watch a recorded move; a DevTools cubic-bezier read helps. Stills: `not observable`.
**File under:** H8, `aesthetic-usability-effect`. Do not file CSS `ease-in-out` versus Material's standard cubic as a miss; file mechanical, linear motion.

### M16 No bounce on everyday UI

**Good:** Everyday UI - especially confirms, errors, and frequent controls - settles without overshoot. Apple: when unsure, use bounce 0; be cautious with large bounce. Material's Standard scheme is "minimal bounce" for utilitarian products; Expressive overshoots, which is a product-level choice, not a license to bounce a delete confirm. **Reel heuristic:** the before/after of a bouncy delete-confirm replaced by a crisp ease-out.
**Failure:** A destructive or confirm dialog, or another frequent everyday control, bounces in or out.
**Observe:** Open the dialog or trigger the control. Stills: `not observable`.
**File under:** H4, `cognitive-load` (ui-ux-pro-max #7, excessive motion). A small spring at the end of a gesture, or playful marketing motion, is not automatically a miss.
**Tempers M11:** squash-and-stretch that reads as bounce on everyday UI is this finding, not a craft flourish.

## M11-M14 Disney craft notes (rarely findings)

These four are principles from Thomas and Johnston, *The Illusion of Life* (1981). On everyday UI they are taste, not a checklist. File one only when the exaggeration gets in the way of the primary task (usually under M16 or `cognitive-load`). Do not file "missing anticipation" on a settings toggle.

### M11 Squash and stretch

**Good:** A moving object may change shape slightly so it feels like it has weight, while keeping volume. **Tempered by M16.**
**Failure worth filing:** A confirm, error, or frequent control squashes and stretches like a cartoon bounce.
**Observe:** Interaction or video; stills: `not observable`.
**File under:** M16's targets (H4, `cognitive-load`) when it becomes bounce; otherwise leave it as a note.

### M12 Anticipation

**Good:** A larger move may take a short, opposite beat first so the action reads.
**Failure worth filing:** A wind-up that delays a frequent or urgent action.
**Observe:** Interaction or video; stills: `not observable`.
**File under:** `doherty-threshold` or `parkinsons-law` only when the delay is the problem.

### M13 Follow-through

**Good:** Loose parts may settle after the main motion stops, so the stop does not feel cut off.
**Failure worth filing:** Trailing motion that keeps going on a control the user already needs to use, or that ignores Reduce Motion.
**Observe:** Interaction or video; stills: `not observable`.
**File under:** `cognitive-load` or H1 only when it interferes; otherwise a note.

### M14 Move in arcs

**Good:** Natural moves often follow a slight curve rather than a perfectly straight slide.
**Failure worth filing:** Almost never on everyday UI. A straight easing slide is not a miss.
**Observe:** Interaction or video; stills: `not observable`.
**File under:** Leave as a note unless the path itself causes confusion (then H1).

## Sources and attribution

Ideas below are paraphrased; no text is copied. Reel numbers stay labelled **reel heuristic**.

| Source | License | Used for |
|---|---|---|
| Instagram @theecommguy, two reels titled "10 Design tips for better UI/UX" and "10 design tips for better UI/UX" | cited as inspiration | The tip list M01-M16. Numbers taken from the reels are reel heuristics, not standards |
| [Apple HIG: Motion](https://developer.apple.com/design/human-interface-guidelines/motion) | cited | Purposeful, brief feedback; help people track a transition; do not use motion as the only signal; let people cancel motion |
| [Apple: Reduced Motion evaluation criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria/) | cited | Scaling, spinning, animated blur, and parallax as motion triggers; replace with a fade or color shift |
| [Material 3: applying easing and duration](https://m3.material.io/styles/motion/easing-and-duration/applying-easing-and-duration) | cited | Exits shorter than entrances; Standard enter 250 ms / exit 200 ms; begin-and-end-on-screen vs enter vs exit easing |
| [Material 3: easing and duration tokens](https://m3.material.io/styles/motion/easing-and-duration/tokens-specs) | cited | `medium1` = 250 ms |
| [Material 3: motion overview](https://m3.material.io/styles/motion/overview) | cited | Standard scheme = minimal bounce; Expressive overshoots |
| [Material 2: duration and easing](https://m2.material.io/guidelines/motion/duration-easing.html) | cited | Worked enter/exit pairs (drawer 250/200, card 300/250) |
| [WCAG Understanding 2.3.1](https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold) | cited | Three flashes or below threshold (Level A) |
| [WCAG Understanding 2.3.3](https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions) | cited | Animation from interactions (Level AAA); `prefers-reduced-motion` as a technique |
| [MDN: prefers-reduced-motion](https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-reduced-motion) | cited | The media query; scaling as a vestibular trigger |
| [Chrome: natural interactions](https://developer.chrome.com/docs/modern-web-guidance/guides/user-experience/natural-interactions) | cited | Example of opening from the trigger and scaling from 0.9, not 0 - an example, not a 0.95 standard |
| [Wikipedia: 12 basic principles of animation](https://en.wikipedia.org/wiki/12_basic_principles_of_animation) | cited, not copied | Names of squash and stretch, anticipation, follow-through, arcs, and staging. Thomas and Johnston, *The Illusion of Life* (1981) |
