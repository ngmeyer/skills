# WCAG 2.2 AA basics and platform targets

Two scored sections. Any WCAG 2.2 AA failure is at least P1 (impeccable's convention, see [sources.md](sources.md)), and caps the grade at C.

## WCAG items (`scores.wcag`, keyed by SC number)

Deterministic tools supply most of these: an axe-core scan per route via `@axe-core/playwright`, Lighthouse, and measured boxes. Their failures are findings with `confidence: 1.0`.

| SC | Check | Notes |
|---|---|---|
| 1.1.1 | Non-text content has a text alternative | Icon-only buttons need a name |
| 1.3.1 | Info and relationships: labels tied to inputs, headings are headings | Placeholder is not a label |
| 1.4.3 | Contrast at least 4.5:1 body, 3:1 large text | Measure; do not eyeball |
| 1.4.10 | Reflow at 320 CSS px with no two-way scroll | Capture a 320 wide shot |
| 1.4.11 | Non-text contrast 3:1 for controls and focus rings | |
| 2.1.1 | Everything works from the keyboard | Needs DOM; n/a on screenshot-only runs |
| 2.4.7 | Focus visible | |
| 2.4.11 | Focus not fully hidden by sticky headers or cookie bars | [Understanding 2.4.11](https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html) |
| 2.5.8 | Target size at least 24x24 CSS px, or the spacing exception | [Understanding 2.5.8](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html) |
| 3.3.1 | Errors identified in text | |
| 4.1.2 | Name, role, value for custom controls | |

Spec: [WCAG 2.2](https://www.w3.org/TR/WCAG22/) and [What's new in 2.2](https://www.w3.org/WAI/standards-guidelines/wcag/new-in-22/). Score only the SCs you could check; list the rest as `n/a` with `reason: "screenshot-only"` or the missing tool. Never guess a code-dependent check from pixels.

## Platform items (`scores.platform`)

| id | Rule | Applies to | Source |
|---|---|---|---|
| touch-target-44 | Every tappable control is at least 44x44 px; WCAG's 24 px is the legal floor, not the goal | web-mobile, web-tablet | house floor |
| thumb-zone | Primary action of the screen sits in the lower half on phones, or is reachable without a regrip | phones | fittss-law |
| ios-hit-44pt | Hit region at least 44x44 pt (60x60 pt on visionOS) | ios | [Apple HIG: Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons), [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility) |
| android-target-48dp | Targets at least 48x48 dp, about 8 dp between targets, pointer targets at least 44 dp | android | [M3 target sizes](https://m3.material.io/foundations/designing/structure), [Android touch targets](https://support.google.com/accessibility/android/answer/7101858) |
| safe-area | Content and controls clear notches, home indicator, and system bars | ios, android | [Apple HIG: Layout](https://developer.apple.com/design/human-interface-guidelines/layout) |
| flutter-tap-target | `androidTapTargetGuideline` and `iOSTapTargetGuideline` pass | flutter | [flutter_test](https://api.flutter.dev/flutter/flutter_test/androidTapTargetGuideline-constant.html) |
| flutter-labeled-tap | `labeledTapTargetGuideline` passes | flutter | [flutter_test](https://api.flutter.dev/flutter/flutter_test/labeledTapTargetGuideline-constant.html) |
| flutter-text-contrast | `textContrastGuideline` passes | flutter | [flutter_test](https://api.flutter.dev/flutter/flutter_test/textContrastGuideline-constant.html) |

Mark items for other platforms `n/a` with `reason: "platform not in target"`. A Flutter `meetsGuideline` failure is hard evidence: `confidence: 1.0`. Background: [Flutter accessibility testing](https://docs.flutter.dev/ui/accessibility/accessibility-testing).

## Capture defaults

Viewports 375x812, 768x1024, and 1280x800, plus 1440x900 for marketing pages. Pin color scheme, reduced motion, and device profiles per run and record them in `target.capture`; a diff across different capture settings is not a diff. Sources: Playwright [screenshots](https://playwright.dev/docs/screenshots), [emulation](https://playwright.dev/docs/emulation), [accessibility testing](https://playwright.dev/docs/accessibility-testing); [axe-core](https://github.com/dequelabs/axe-core); [Lighthouse](https://developer.chrome.com/docs/lighthouse/overview).
