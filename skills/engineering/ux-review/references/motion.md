# Motion and micro-interaction checklist

This is a pass, not a scored section. File each miss under the existing law, heuristic, or WCAG SC the check names (`rule` is that item; the M-id lives in `evidence` or `also`). Do not add `scores.motion` or change the 35/25/25/15 weights. Never use an M-id as `rule`.

**Evidence strength.** Every check carries a label. **research**: a peer-reviewed study or controlled experiment. **standard**: WCAG normative text or a W3C technique. **platform**: Apple HIG, Material 3, or a production design system. **practitioner**: NN/g or WebAIM guidance from usability practice. Thresholds marked **house heuristic** are our calibration inside a sourced range, not a published number. Weak evidence means low severity: craft checks (M02, M03, M05-M09, M15-M20, M24 outside Reduce Motion, M26) file at severity 1-2. Only M01, M21, and M22 may reach severity 3, when the user cannot tell an action registered, input is dropped, or a long wait has no indicator. M23, M25, and 2.3.1 follow WCAG tiering.

**Evidence.** Motion often cannot be seen in a still. A finding needs interaction (click, tap, scroll, open/close) or video. Otherwise write `not observable` and do not lower a score. Never fabricate a motion finding. `not observable` applies to the check, not automatically to the linked law: if `doherty-threshold` or H1 has other evidence (INP, a visible spinner), score it as usual. Confidence: 1.0 when a duration is measured (DevTools, `document.getAnimations()`), 0.8 from a clear recording, 0.5 if easing was only eyeballed. If the previous run was stills-only and this run has interaction or video, set `loop.decision: "baseline-reset"`; new motion findings are not a regression against a stills baseline.

**Reduced motion.** Honor `prefers-reduced-motion` (and the platform Reduce Motion setting) on every check, and record it in `target.capture.reduced_motion`. Under `reduce`, missing decorative motion is never a miss. A reduced alternative passes when nothing travels, scales, or springs: an instant change, or an opacity-only cross-fade of about 200 ms or less (Astryx `design:reduced-motion` DR1-DR3, which also keeps in-place values and colors instant and lets momentum after a throw continue; Apple's dissolve, highlight fade, or color shift). Large motion that still plays under `reduce` is a [2.3.3](https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions) note (Level AAA: report-only, no grade cap); see M24 for the trigger list. Seizure-risk flashing (more than three flashes in one second, or above the general or red flash thresholds) is [2.3.1](https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold) (Level A). File it as P0 (safety) under the scored 2.3.1 item, with the recording attached.

Fitts's law, Hick's law, and the Doherty threshold are already in [laws.md](laws.md). Cross-reference them from this pass; do not file a second copy.

## Method notes

- **MX1 Production captures are read-only and pixel-blocked.** On a production URL, block ad and analytics requests (Google Ads, Meta, GA, and the like) at the network layer before any interaction, and submit nothing. A motion run clicks a lot; it must not pollute the site's conversion data. Say in the report that pixels were blocked.
- **MX2 Read after settle.** Sample focus styles, sticky-bar positions, and final layout only after `document.getAnimations()` is empty or the transition's `finished` promise resolves. A focus ring whose `outline-color` animates reads as transparent right after Tab, which is a false 2.4.7.
- **MX3 Read framework easing from keyframes.** Svelte, Framer Motion, and other WAAPI wrappers often report `effect.getTiming().easing` as `linear` and bake the curve into the keyframes. Read `effect.getKeyframes()` (per-keyframe `easing` and offsets) before filing linear motion.
- **MX4 Measure, then compare to a band.** Record enter and exit durations separately, and time from input to first visible change. Compare to the bands below; do not file a number that is inside its band.

## Checks

### M01 Taps visibly register

**Rule:** A press, tap, or click produces a visible change (pressed state, highlight, or the result itself). The result painting counts as confirmation.
**Threshold:** Exempt when the result paints within 400 ms of input (**house heuristic**; Nielsen puts the limit for needing no special feedback at 1 s). File when nothing visible changes for more than 400 ms. A direct-manipulation control (toggle, checkbox, drag handle) with no state change within about 100 ms is a severity-1 note (Nielsen's 0.1 s direct-manipulation limit).
**File under:** H1, `doherty-threshold`. If the control also lacks hover, focus, and active states, that is T19; list `2.4.7` in `also` only when focus is missing.
**Source:** [Nielsen: response times](https://www.nngroup.com/articles/response-times-3-important-limits/) (practitioner, after Miller 1968 and Card et al. 1991); [NN/g: role of animation](https://www.nngroup.com/articles/animation-purpose-ux/) (practitioner).

### M02 Surfaces open from their trigger

**Rule:** A modal, sheet, popover, or expanded state appears connected to the control that opened it (grows or moves from near the trigger, `transform-origin` toward it), so the user can track the change. It never grows from `scale(0)` or a point.
**Threshold:** Pass or fail on a recording. **Repeat guard:** a surface opened many times per session (a "save and add another" dialog, a command palette) may open instantly; do not file it.
**File under:** H1, `law-of-uniform-connectedness`; `jakobs-law` when the platform already uses a container or hero transition and this screen does not.
**Source:** [Heer & Robertson 2007](https://idl.cs.washington.edu/files/2007-AnimatedTransitions-InfoVis.pdf), [Bederson & Boltman 1999](https://www.cs.umd.edu/projects/hcil/jazz/learn/papers/CS-TR-3964.pdf) (research); [Apple HIG: Motion](https://developer.apple.com/design/human-interface-guidelines/motion) (platform).
**Reduced motion:** Fade in place with no scale; scaling is a vestibular trigger.

### M03 Mode-change icons transition

**Rule:** An icon that signals a mode change (edit to save, add to done) morphs or cross-fades rather than swapping in one frame.
**Threshold:** Exempt frequent binary toggles (menu/close, play/pause, show/hide password): a one-frame swap is fine (M20). Severity 1 at most.
**File under:** H1, `law-of-similarity`.
**Source:** [NN/g: role of animation](https://www.nngroup.com/articles/animation-purpose-ux/), state change (practitioner).
**Reduced motion:** No blur; animated blur is an Apple Reduce Motion trigger. An instant swap passes.

### M05 Transitions minimize occlusion

**Rule:** During a transition, elements do not smear over each other: no two semi-transparent copies stacked mid-cross-fade, no moving element hiding the one the user is tracking. Enter and exit by alpha or clip.
**File under:** H1, `law-of-uniform-connectedness`.
**Source:** [Heer & Robertson 2007](https://idl.cs.washington.edu/files/2007-AnimatedTransitions-InfoVis.pdf), "minimize occlusion" and alpha-blended entry and exit (research).

### M06 Stage the change

**Rule:** One thing moves at a time, or the primary change leads and the rest follow. Complex changes are broken into simple stages. Several unrelated animations at once compete and cancel out.
**File under:** `selective-attention`, H1. Related to M07 and M17; file one finding if several apply.
**Source:** [Heer & Robertson 2007](https://idl.cs.washington.edu/files/2007-AnimatedTransitions-InfoVis.pdf): staged transitions were preferred and, in several conditions, more accurate (research); [NN/g: role of animation](https://www.nngroup.com/articles/animation-purpose-ux/) (practitioner).

### M07 Stagger stays short

**Rule:** A cascade on a list is allowed (staggering reduces overlap when items reorder) but never delays the task.
**Threshold:** File when the last row of a cascade lands more than about 500 ms after the trigger (NN/g: at 500 ms animations "start to feel like a real drag"), or when the cascade blocks the primary action. Never file a missing stagger.
**File under:** `cognitive-load` or `selective-attention`.
**Source:** [Heer & Robertson 2007](https://idl.cs.washington.edu/files/2007-AnimatedTransitions-InfoVis.pdf), staggered sorting (research); [NN/g: animation duration](https://www.nngroup.com/articles/animation-duration/) (practitioner).

### M08 Menus open in a short band

**Rule:** A menu, select, or small popover opens fast enough not to feel like waiting.
**Threshold:** Small menus pass at up to 300 ms, so 100-150 ms is fine; about 250 ms is a good center. A snap with no transition is not a finding. File severity 1 above 300 ms, severity 2 at 500 ms or more on a frequently used control. A hover-opened menu may wait a short hover-intent delay before opening and keep a short exit guard; do not count that delay as animation time. Flicker when the pointer brushes out and back is a miss (H4). Keyboard focus should open with no dwell.
**File under:** `doherty-threshold`, H1.
**Source:** [Material 3 duration tokens](https://m3.material.io/styles/motion/easing-and-duration/tokens-specs): short 50-200 ms for small utility transitions (platform); [NN/g: animation duration](https://www.nngroup.com/articles/animation-duration/): about 100 ms for simple feedback (practitioner); [Astryx `design:motion` DEC-1](https://github.com/meta/astryx/blob/main/docs/design/motion.md), hover entry delay and exit guard (platform).

### M09 Exits are not slower than entrances

**Rule:** Dismiss, close, and collapse take no longer than the matching open.
**Threshold:** File only when the exit is longer than 200 ms **and** at least as long as the entrance. An exit of 200 ms or less is never a finding (Material's exit tokens are 200 ms), so a 120/120 pair passes.
**File under:** `doherty-threshold`, H1.
**Source:** [Material 3: applying easing and duration](https://m3.material.io/styles/motion/easing-and-duration/applying-easing-and-duration): exits use shorter durations (platform); [NN/g: animation duration](https://www.nngroup.com/articles/animation-duration/): appear 300 ms, disappear 200-250 ms (practitioner).

### M15 Moves ease; they are not linear

**Rule:** Movement that changes position or size uses slow-in/slow-out: ease-in-out or a standard curve when it begins and ends on screen, decelerate (ease-out) on enter, accelerate on a permanent exit.
**Threshold:** Opacity-only fades are exempt. Read keyframes first (MX3). Do not file CSS `ease-in-out` versus Material's standard cubic; file visibly mechanical, constant-speed travel.
**File under:** H8, `aesthetic-usability-effect`.
**Source:** [Heer & Robertson 2007](https://idl.cs.washington.edu/files/2007-AnimatedTransitions-InfoVis.pdf), "maximize predictability" (research); [Material 3: applying easing and duration](https://m3.material.io/styles/motion/easing-and-duration/applying-easing-and-duration) (platform); [NN/g: animation duration](https://www.nngroup.com/articles/animation-duration/) (practitioner); [Chang & Ungar 1993](https://bibliography.selflanguage.org/_static/animation.pdf).

### M16 No bounce on everyday UI

**Rule:** Everyday UI, especially confirms, errors, and frequent controls, settles without overshoot. A destructive or confirm dialog that bounces is a miss. A small spring at the end of a user's gesture, or playful marketing motion, is not automatically a miss.
**File under:** H4, `cognitive-load` (ui-ux-pro-max #7, excessive motion).
**Source:** [Material 3 motion overview](https://m3.material.io/styles/motion/overview) (Standard scheme, minimal bounce); [Astryx `design:motion` DR3](https://github.com/meta/astryx/blob/main/docs/design/motion.md), controlled deceleration rather than ornamental bounce (platform); [NN/g: animation duration](https://www.nngroup.com/articles/animation-duration/), more frequent means subtler (practitioner).

### M17 Motion has a purpose

**Rule:** Every non-trivial animation serves feedback, a state or mode change, spatial orientation, or a signifier. Name the purpose in `evidence`; if you cannot, it is decoration. Looping or attention-grabbing motion next to the task is a miss.
**File under:** `selective-attention`, H8.
**Source:** [Apple HIG: Motion](https://developer.apple.com/design/human-interface-guidelines/motion), "don't add motion for the sake of adding motion" (platform); [Astryx `design:motion` DR1](https://github.com/meta/astryx/blob/main/docs/design/motion.md) (platform); [NN/g: role of animation](https://www.nngroup.com/articles/animation-purpose-ux/) (practitioner); [Tversky et al. 2002](https://hci.stanford.edu/courses/cs448b/papers/Tversky_AnimationFacilitate_IJHCS02.pdf): many studies find no benefit of animation over equivalent static graphics (research).

### M18 Object constancy

**Rule:** Across a view change, the same object moves or transforms continuously instead of teleporting, and an object never morphs into an unrelated one (that implies a false relation). Zoom or push direction matches moving down or up a hierarchy.
**File under:** `mental-model`, H1.
**Source:** [Heer & Robertson 2007](https://idl.cs.washington.edu/files/2007-AnimatedTransitions-InfoVis.pdf): animated transitions improved graphical perception over static ones (research); [Bederson & Boltman 1999](https://www.cs.umd.edu/projects/hcil/jazz/learn/papers/CS-TR-3964.pdf): animated viewpoint changes significantly reduced errors when users reconstructed the space, with no task-time penalty (research).

### M19 Duration scales with size and distance

**Rule:** Small local feedback is short; larger moves take longer. Use the shortest duration that is not jarring.
**Threshold:** Simple feedback about 100 ms; a modal or sheet 200-300 ms; up to about 400 ms only for large moves. 500 ms or more on UI chrome is a miss (severity 1-2). Material: short 50-200, medium 250-400, long 450-600 ms; above 600 ms is for ambient motion without user input. Data-visualization transitions are the exception: around 1 s tested well. For menus and small popovers use M08 instead; file once.
**File under:** `doherty-threshold`, H7.
**Source:** [NN/g: animation duration](https://www.nngroup.com/articles/animation-duration/) (practitioner); [Material 3 tokens](https://m3.material.io/styles/motion/easing-and-duration/tokens-specs) and [applying](https://m3.material.io/styles/motion/easing-and-duration/applying-easing-and-duration) (platform); [Astryx `design:motion` DR2](https://github.com/meta/astryx/blob/main/docs/design/motion.md), weight determines timing (platform; Astryx sets no numbers); Heer & Robertson 2007, citing Robertson et al., for the 1 s viz figure (research, secondary).

### M20 Frequency budget

**Rule:** The more often an interaction happens, the shorter and subtler its motion, down to none. Never file missing motion on a frequent control; file motion that makes a frequent action wait.
**Threshold:** A control used several times per session: about 150 ms or no motion (**house heuristic**).
**File under:** H7, `cognitive-load`.
**Source:** [Apple HIG: Motion](https://developer.apple.com/design/human-interface-guidelines/motion), "avoid adding motion to UI interactions that occur frequently" (platform); [NN/g: animation duration](https://www.nngroup.com/articles/animation-duration/) (practitioner).

### M21 Motion never blocks input

**Rule:** The user can click, type, press Esc, or reverse a transition mid-flight, and the UI responds at once. Input is never dropped or queued until an animation ends.
**Threshold:** Act at about half-way through a running transition. Dropped or deferred input is a miss; it may be severity 3.
**File under:** H3, `doherty-threshold`.
**Source:** [Apple HIG: Motion](https://developer.apple.com/design/human-interface-guidelines/motion), "let people cancel motion" (platform); [Dessart et al. 2011](https://doi.org/10.1145/1996461.1996501): animated transitions helped understanding and trust but users were bothered by lag (research); [Tversky et al. 2002](https://hci.stanford.edu/courses/cs448b/papers/Tversky_AnimationFacilitate_IJHCS02.pdf): user control of an animation helps overcome its perception limits (research).

### M22 Loading feedback matches the wait

**Rule:** Pick the indicator by wait length.
**Threshold:** A full-page wait under 1 s: no spinner or skeleton (a flash is a miss). About 2-10 s: a skeleton for a full page, a spinner for a module. Over 10 s: percent-done, an estimate, and a way to cancel. A determinate bar that stalls near the end is a severity-1 note.
**File under:** H1, `doherty-threshold`.
**Source:** [Nielsen: response times](https://www.nngroup.com/articles/response-times-3-important-limits/), [NN/g: skeleton screens](https://www.nngroup.com/articles/skeleton-screens/), [NN/g: progress indicators](https://www.nngroup.com/articles/progress-indicators/) (practitioner); [Harrison et al. 2007](https://www.chrisharrison.net/projects/progressbars/ProgBarHarrison.pdf): pauses near the end made progress feel longer (research).
**Reduced motion:** A static skeleton or a text status passes.

### M23 Auto-playing motion can be paused

**Rule:** Motion that starts on its own, lasts more than 5 s, and plays alongside other content (carousels, looping hero video, marquees, animated backgrounds) has a pause, stop, or hide control. Auto-updating content needs one regardless of length. A preload animation is exempt only while no interaction is possible.
**File under:** `2.2.2` (Level A, scored; caps at C).
**Source:** [WCAG 2.2 Understanding 2.2.2](https://www.w3.org/WAI/WCAG22/Understanding/pause-stop-hide.html), including Note 4 (standard); [Apple Reduced Motion criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria/), stop auto-advancing carousels (platform).

### M24 Vestibular triggers respect Reduce Motion

**Rule:** Under `reduce`, remove or replace parallax, scroll-jacking, scroll-linked decorative motion, large zoom or scale, spinning, multi-axis or multi-speed motion, animated blur or depth of field, and moving images under static text.
**Threshold:** Still playing under `reduce` is a 2.3.3 note (AAA, no cap). Without `reduce`, parallax or scroll-jacking is a severity-1 `cognitive-load` note.
**File under:** `2.3.3` note, or `cognitive-load`.
**Source:** [WCAG 2.2 Understanding 2.3.3](https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions) and [technique C39](https://www.w3.org/WAI/WCAG22/Techniques/css/C39) (standard); [Apple Reduced Motion criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria/), [Astryx `design:reduced-motion`](https://github.com/meta/astryx/blob/main/docs/design/reduced-motion.md) (platform); [WebAIM: seizure and vestibular disorders](https://webaim.org/articles/seizure/) (practitioner); [Frederick et al. 2015](http://uxpajournal.org/wp-content/uploads/pdf/JUS_Frederick_Feb2015.pdf): 2 of 43 participants on a parallax site got motion sickness (research, small sample).

### M25 Sticky or animated bars do not hide focus

**Rule:** With a sticky header, footer, or bar (especially one that slides in), Tab through the page and compare each focused element's rect with the bar's rect after both settle (MX2).
**Threshold:** Focused element entirely covered fails 2.4.11. The usual fix is `scroll-padding` (technique C43).
**File under:** `2.4.11` (scored; caps at C).
**Source:** [WCAG 2.2 Understanding 2.4.11](https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html), failure F110 (standard).

### M26 Motion is never the only signal

**Rule:** A state change shown by motion (added to cart, saved, error) also shows statically (text, an icon with color, a badge), so it still reads under Reduce Motion or change blindness.
**Threshold:** Turn Reduce Motion on; the state must still be perceivable.
**File under:** H1.
**Source:** [Apple HIG: Motion](https://developer.apple.com/design/human-interface-guidelines/motion), "avoid using it as the only way to communicate important information" (platform); [Astryx `design:motion` DR5](https://github.com/meta/astryx/blob/main/docs/design/motion.md) (platform); [NN/g: role of animation](https://www.nngroup.com/articles/animation-purpose-ux/), change blindness (practitioner).

## Animation principles lens (not scored, never a finding on its own)

These ids are retired as checks. Use the vocabulary to explain a finding filed elsewhere; never file "missing" one of these. Disney's principles (Thomas and Johnston, *The Illusion of Life*, 1981) reach UI through [Chang & Ungar 1993](https://bibliography.selflanguage.org/_static/animation.pdf), a design essay without a user study. Of these, only slow-in/slow-out has independent experimental support, and that lives in M15.

| Id | Principle | Why it is not a check |
|---|---|---|
| M04 | Rubber band past the edge | Overscroll belongs to the OS or browser; no evidence found for a web check. Don't disable native overscroll on the main scroller (`jakobs-law`). |
| M10 | Popovers start near full size | The 0.95 figure has no source. "Not from scale(0)" now lives in M02. |
| M11 | Squash and stretch | Taste on everyday UI; when it reads as bounce, file M16. |
| M12 | Anticipation | A wind-up that delays an action is filed as M19 or M21. |
| M13 | Follow-through | Chang & Ungar's end-of-move wiggle conflicts with M16 on everyday UI; M16 wins. |
| M14 | Move in arcs | Simple translation is easier to track (Heer & Robertson 2007); a straight eased slide is not a miss. |

## Sources and attribution

Ideas are paraphrased; no text is copied. The first draft of this checklist (PR #9) started from a social-media tip list; every surviving rule has been re-sourced below, and no rule depends on it.

| Source | Strength | Used for |
|---|---|---|
| Heer, J. & Robertson, G. (2007). Animated transitions in statistical data graphics. IEEE TVCG. [PDF](https://idl.cs.washington.edu/files/2007-AnimatedTransitions-InfoVis.pdf) | research | M02, M05-M07, M14, M15, M18, M19 |
| Bederson, B. & Boltman, A. (1999). Does animation help users build mental maps of spatial information? IEEE InfoVis. [TR](https://www.cs.umd.edu/projects/hcil/jazz/learn/papers/CS-TR-3964.pdf) | research | M02, M18 |
| Tversky, B., Morrison, J. B. & Bétrancourt, M. (2002). Animation: can it facilitate? IJHCS. [PDF](https://hci.stanford.edu/courses/cs448b/papers/Tversky_AnimationFacilitate_IJHCS02.pdf) | research review | M17, M21 |
| Dessart, C.-E., Motti, V. G. & Vanderdonckt, J. (2011). Showing user interface adaptivity by animated transitions. EICS. [doi](https://doi.org/10.1145/1996461.1996501) | research | M21 |
| Harrison, C., Amento, B., Kuznetsov, S. & Bell, R. (2007). Rethinking the progress bar. UIST. [PDF](https://www.chrisharrison.net/projects/progressbars/ProgBarHarrison.pdf) | research | M22 |
| Frederick et al. (2015). The effects of parallax scrolling on user experience in web design. JUS. [PDF](http://uxpajournal.org/wp-content/uploads/pdf/JUS_Frederick_Feb2015.pdf) | research, small n | M24 |
| Chang, B.-W. & Ungar, D. (1993). Animation: from cartoons to the user interface. UIST. [PDF](https://bibliography.selflanguage.org/_static/animation.pdf) | design essay | M15, lens |
| [Nielsen: response times](https://www.nngroup.com/articles/response-times-3-important-limits/) (1993; Miller 1968; Card et al. 1991) | practitioner | M01, M22 |
| NN/g: [role of animation](https://www.nngroup.com/articles/animation-purpose-ux/), [animation duration](https://www.nngroup.com/articles/animation-duration/) (Laubheimer 2020), [skeleton screens](https://www.nngroup.com/articles/skeleton-screens/), [progress indicators](https://www.nngroup.com/articles/progress-indicators/) | practitioner | Purpose, bands, frequency, loading |
| Material 3: [applying easing and duration](https://m3.material.io/styles/motion/easing-and-duration/applying-easing-and-duration), [tokens](https://m3.material.io/styles/motion/easing-and-duration/tokens-specs), [overview](https://m3.material.io/styles/motion/overview) | platform | Duration tokens, exits, easing types, bounce |
| [Apple HIG: Motion](https://developer.apple.com/design/human-interface-guidelines/motion); [Apple Reduced Motion criteria](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/reduced-motion-evaluation-criteria/) | platform | Purpose, frequency, cancel, not-only-signal, trigger list |
| [meta/astryx](https://github.com/meta/astryx) `docs/design/motion.md` (draft) and `docs/design/reduced-motion.md` (current), MIT, Copyright (c) 2026 Meta Platforms, Inc. | platform (production design system) | Corroborates purpose, weight-based timing, no ornamental bounce, not-only-signal; hover-intent delay (M08); reduced-motion pass criteria. Sets no duration tokens |
| WCAG 2.2 Understanding [2.2.2](https://www.w3.org/WAI/WCAG22/Understanding/pause-stop-hide.html), [2.3.1](https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold), [2.3.3](https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions), [2.4.11](https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html); [C39](https://www.w3.org/WAI/WCAG22/Techniques/css/C39) | standard | M23-M25, flashing, reduced motion |
| [WebAIM: seizure and vestibular disorders](https://webaim.org/articles/seizure/) | practitioner | M24 |
