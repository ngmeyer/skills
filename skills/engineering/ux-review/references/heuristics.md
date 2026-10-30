# Nielsen's 10 heuristics (H1-H10)

Definitions: [NN/g, 10 Usability Heuristics for User Interface Design](https://www.nngroup.com/articles/ten-usability-heuristics/). Score each 0-4 per screen (4 = fully satisfied) or `n/a` with a reason. Totals renormalize over applicable items, the approach impeccable's critique uses (see [sources.md](sources.md)).

| id | Heuristic | What to look for |
|---|---|---|
| H1 | Visibility of system status | Loading, saving, progress, and success are shown promptly |
| H2 | Match between system and the real world | User vocabulary, not internal jargon; natural ordering |
| H3 | User control and freedom | Undo, cancel, back, and a clear exit from every modal or flow |
| H4 | Consistency and standards | Same words and patterns for the same thing; platform conventions |
| H5 | Error prevention | Constraints, confirmations for destructive actions, forgiving inputs |
| H6 | Recognition rather than recall | Options and needed info are visible, not memorized |
| H7 | Flexibility and efficiency of use | Shortcuts, defaults, and bulk actions for frequent users |
| H8 | Aesthetic and minimalist design | Nothing competes with the primary task |
| H9 | Help users recognize, diagnose, and recover from errors | Plain-language error at the field, with the fix, input preserved |
| H10 | Help and documentation | Help is findable and in context when it is needed |

## Overlap rule

Many heuristics overlap with laws (see the "Often also" column in [laws.md](laws.md)). When one problem touches both, file ONE finding: put the most specific item in `rule` and the rest in `also`. The finding then lowers every item it is linked to. Two findings for one problem double-count the severity in the ranking and break the diff when only one of them gets fixed.

## Severity (finding scale, higher is worse)

From [NN/g severity ratings](https://www.nngroup.com/articles/how-to-rate-the-severity-of-usability-problems/), weighing frequency, impact, and persistence:

| severity | Meaning |
|---|---|
| 0 | Not a usability problem (do not file it) |
| 1 | Cosmetic; fix if time allows |
| 2 | Minor; low priority |
| 3 | Major; important to fix |
| 4 | Catastrophe; must fix before release |

Do not mix this up with the item score, where higher is better.
