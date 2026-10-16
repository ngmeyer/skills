# Skill authoring and publishing

Lessons that apply to every skill in this repo. Rules with a number live in `scripts/lint-skills.sh`; this file holds the *why* the lint cannot.

- Publishing a skill is three edits, not one: its path in `.claude-plugin/plugin.json`, its entry in the README catalog (and the slash-command block), and the skill count spelled out in both the README intro and the `plugin.json` description. The lint checks only the first, so the count drifts (learn: 0c6b985 bumped "Eight"→"Nine" in both; 2c07600 did the same for write-well; README.md, .claude-plugin/plugin.json)
- A bare --- line inside a SKILL.md body truncates the skill when Grok registers it; keep --- only as the frontmatter fences (use *** or a heading for a rule) (learn: skills/engineering/learn/tests/eval.sh 'no bare --- in body' check and tests/README.md portability line, added on PR #1; skills/engineering/learn/tests/eval.sh, CLAUDE.md)
