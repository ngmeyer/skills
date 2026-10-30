# Sources and attribution

Rules here are our own words. Where an idea came from another project, it is credited below. No text is copied verbatim from any of these sources.

| Source | License | What this skill takes from it |
|---|---|---|
| [pbakaus/impeccable](https://github.com/pbakaus/impeccable) ([critique.md](https://github.com/pbakaus/impeccable/blob/main/skill/reference/critique.md), [audit.md](https://github.com/pbakaus/impeccable/blob/main/skill/reference/audit.md)) | Apache-2.0 | The scoring shape: 0-4 per heuristic with n/a renormalization, P0-P3 tiers, "would a user contact support?" as a P1 test, WCAG AA failures as at least P1, per-run snapshots for trends. Ideas paraphrased, no text copied. |
| [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) ([ux-guidelines.csv](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill/blob/28b3b8dee8c976df4fa3e94aed4e092ad43fcb03/.claude/skills/ui-ux-pro-max/data/ux-guidelines.csv), read at commit `28b3b8d`) | MIT, Copyright (c) 2024 Next Level Builder | Row numbers used as a lookup for fix wording in [laws.md](laws.md). Read from upstream only. |
| [Laws of UX](https://lawsofux.com/) by Jon Yablonski | site content, cited | The 30 law names and slugs. Check text is ours. |
| [NN/g: 10 Usability Heuristics](https://www.nngroup.com/articles/ten-usability-heuristics/) and [severity ratings](https://www.nngroup.com/articles/how-to-rate-the-severity-of-usability-problems/) | cited | H1-H10 names and the 0-4 severity scale. |
| [Nutlope/hallmark](https://github.com/Nutlope/hallmark) | MIT, Copyright (c) 2026 Hallmark contributors | The fresh-context reviewer for P0s. |
| [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) | MIT | Fix the top three per round, with a small round budget. |
| [keysjoao/laws-of-ux-skills](https://github.com/keysjoao/laws-of-ux-skills) | MIT | Prior art for a Laws of UX checker. |
| [RICE prioritization (Intercom)](https://www.intercom.com/blog/rice-simple-prioritization-for-product-managers/) | cited | Effort as the divisor in `priority_score`. |
| W3C WCAG 2.2, Apple HIG, Material 3, Android, Flutter docs | cited | Thresholds in [platform-targets.md](platform-targets.md). |

The slop pass credits its own sources in [slop-tells.md](slop-tells.md#sources-and-attribution).

impeccable's Apache-2.0 license asks that a NOTICE travel with copied text. Nothing is copied, so no NOTICE is shipped; if you later quote it, add one.
