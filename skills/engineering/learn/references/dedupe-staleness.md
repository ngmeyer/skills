# Dedupe and staleness
## Dedupe (per lesson)
1. Extract 2–4 key terms (symbol, path, command, concept).
2. `grep -rniE '<terms>' AGENTS.md CLAUDE.md docs/topics docs/decisions .cursor/rules` (whichever exist).
3. Decide: **SKIP** same rule already present · **EDIT** related line exists → merge into it (keep one line) · **ADD** nothing related.
4. Never ADD a line that contradicts an existing one; EDIT the old one and cite why it changed.

## Staleness (per merged diff)
1. List renamed/deleted paths: `git diff --name-status -M <merge>^1 <merge> | grep -E '^(R|D)'`.
2. List removed scripts/commands (package.json scripts, Makefile targets) and removed exported symbols.
3. `grep -rn` each in AGENTS.md, CLAUDE.md, docs/topics, .cursor/rules. Every hit → propose EDIT (new path) or DELETE (concept gone).
4. Deletions of context lines need evidence (the diff hunk) in the PR body. Never delete a line only because it looks old.

## Single source of truth
If a topic duplicates a long-form doc, edit the canonical one and leave/repair the pointer; do not edit both.
