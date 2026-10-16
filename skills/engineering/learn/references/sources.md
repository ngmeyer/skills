# Sources

Every rule in this skill traces to something a reader can open. Sources were fetched and
quoted on 2026-10-11; quotes below are verbatim from the fetched pages.

| rule in this skill | claim it rests on | source |
|---|---|---|
| AGENTS.md is a map, not a manual | "give Codex a map, not a 1,000-page instruction manual"; "we treat it as **the table of contents**… A short `AGENTS.md` (roughly 100 lines) is injected into context and serves primarily as a map, with pointers to deeper sources" | OpenAI, [Harness engineering](https://openai.com/index/harness-engineering/) (Feb 11 2026) |
| Detail goes in `references/`, loaded on demand | "For domain knowledge or workflows that are only relevant sometimes, use skills instead. Claude loads them on demand without bloating every conversation." · "allows agents to incrementally discover relevant context through exploration" | Anthropic, [Claude Code best practices](https://www.anthropic.com/engineering/claude-code-best-practices) · [Effective context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) |
| Import deterministically (`@AGENTS.md`), don't rely on "read it" | "imported files still load and enter the context window at launch" | Anthropic, [memory docs](https://docs.claude.com/en/docs/claude-code/memory) |
| Only non-obvious rules; no repository overviews | "providing context files does not generally improve task success rates, while *increasing inference cost* by over 20% on average… repository overviews, although popular and recommended by model providers, are not helpful" · "Only add context Claude doesn't already have." | [Evaluating AGENTS.md: Are Repository-Level Context Files Helpful for Coding Agents?](https://arxiv.org/abs/2602.11988) (arXiv 2602.11988) · Anthropic, [skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) |
| Every lesson carries its *why* | "Providing context or motivation behind your instructions, such as explaining to Claude why such behavior is important, can help Claude better understand your goals" | Anthropic, [Claude 4 prompting best practices](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/claude-4-best-practices) |
| Prefer a lint/test over prose for invariants | "Claude treats them as context, not enforced configuration. To block an action regardless of what Claude decides, use a PreToolUse hook instead." · "Dedicated linters and CI jobs validate that the knowledge base is up to date, cross-linked, and structured correctly." | Anthropic memory docs · OpenAI, Harness engineering |
| Reference, never copy | "Reference files instead of copying their contents—this keeps rules short and prevents them from becoming stale as code changes" · "A single blob doesn't lend itself to mechanical checks (coverage, freshness, ownership, cross-links), so drift is inevitable." | [Cursor rules docs](https://cursor.com/docs/rules) · OpenAI, Harness engineering |
| Run post-merge, as gardening | "A recurring 'doc-gardening' agent scans for stale or obsolete documentation that does not reflect the real code behavior and opens fix-up pull requests." | OpenAI, Harness engineering |
| Capture lessons into a file in git | "Check CLAUDE.md into git so your team can contribute. The file compounds in value over time." | Anthropic, Claude Code best practices |
| Specs are disposable; decisions are durable | "Active plans, completed plans, and known technical debt are all versioned and co-located" · "Specs are disposable; **long-term memory** is what the harness keeps" | OpenAI, Harness engineering · Context Specs |
| Cap lessons per PR; curate, don't accumulate | "Context… must be treated as a finite resource with diminishing marginal returns." · "Instructions become long and sometimes conflict with each other. Models tend to attend less to content buried in the middle of long contexts" | Anthropic, Effective context engineering · Thoughtworks [Technology Radar vol. 34](https://www.thoughtworks.com/en-us/radar/techniques/context-engineering), *Agent instruction bloat* (Caution), Apr 2026 |
| Evals gate a context change | "any attempts to improve performance should be rigorously evaluated before deployment." · "**Create evaluations BEFORE writing extensive documentation.**" | arXiv 2602.11988 · Anthropic, skill authoring best practices |

## Framing
Karpathy, via [Simon Willison](https://simonwillison.net/2025/Jun/27/context-engineering/) (27 Jun 2025): "context engineering is the delicate art and science of filling the context window with just the right information for the next step."

## What is *not* sourced
The line budget this skill defaults to (400 words for AGENTS.md) is borrowed from one
project's lint, and the per-PR lesson cap (5) is a judgment call about review size.
Both are defaults, labelled as such where they appear. Neither is measured, and a repo
that states its own number overrides them.
