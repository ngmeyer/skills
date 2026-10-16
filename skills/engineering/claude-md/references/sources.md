# Sources

## Anthropic primary sources
- [How Claude remembers your project](https://code.claude.com/docs/en/memory)
- [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)
- [Hooks](https://code.claude.com/docs/en/hooks) — the enforcement path when an advisory rule must hold 100% of the time
- [How Anthropic teams use Claude Code (PDF)](https://www-cdn.anthropic.com/58284b19e702b49db9302d5b6f135ad8871e7658.pdf)
- [Claude Code Advanced Patterns (PDF)](https://resources.anthropic.com/hubfs/Claude%20Code%20Advanced%20Patterns_%20Subagents%2C%20MCP%2C%20and%20Scaling%20to%20Real%20Codebases.pdf)

## Cross-agent standard
- [agents.md](https://agents.md/) — the `AGENTS.md` standard both modes also apply to
- [OpenAI — Harness engineering](https://openai.com/index/harness-engineering/) (Feb 2026) — the ~100-line map figure quoted in SKILL.md → Budgets

## Empirical
- [AGENTS.md efficiency study (arXiv 2026)](https://arxiv.org/html/2601.20404v2) — curated context ~+4pp task quality at ~20% token overhead; auto-generated **reduces** success ~0.5–2% while raising cost 20–23%. The basis for the "never auto-generate" anti-pattern.
- [Augment Code — Karpathy skills on OpenClaw (April 2026)](https://www.augmentcode.com/blog/karpathy-skills-on-openclaw-agents-don-t-write-better-code-but-they-do-it-more-efficiently) — counterevidence: Claude Code quality regressed −0.07 when Karpathy rules were layered onto an already-aligned system prompt. The basis for trim-not-add.

## Community (consistent with primary)
- [HumanLayer — Writing a Good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md)
- [zodchiii — The CLAUDE.md File That 10x'd My Output](https://x.com/zodchiii/status/2048683276194185640) (1.3M views) — the ≤15-hard-rules figure
- [abhishekray07/claude-md-templates](https://github.com/abhishekray07/claude-md-templates)
- [Fraser — Claude.md Setup Tips (Medium, May 2026)](https://medium.com/ai-systems-lab/claude-md-setup-tips-that-will-10x-your-claude-code-workflow-1d7d23793755) — Karpathy's 4 rules + 8 additions, CLI-redundancy avoidance, in-file priority ordering
- ["Dep" (@0xdepressionn) — Karpathy CLAUDE.md rule compilation (X, May 2026)](https://x.com/0xdepressionn/status/2055999112470839383) — 14-rule set feeding high-impact-lines.md. ⚠️ Headline stats (82k stars, 65%→94% accuracy, $/week figures) are unsourced marketing — the rule wording is the value, the numbers are not citable.
- [Redreamality — CLAUDE.md and AGENTS.md, In Depth (April 2026)](https://redreamality.com/blog/claude-md-agents-md-deep-dive/) — second-occurrence promotion rule; ~80% advisory ceiling synthesis

## Related discipline
- Strunk & White, *The Elements of Style* — Rule 17 ("Omit needless words") is the upstream principle behind Anthropic's removability test
