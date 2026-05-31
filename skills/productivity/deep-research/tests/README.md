# deep-research — Eval harness

**Level:** Compound (multi-provider search + LLM synthesis + optional critique loop).
Runtime output varies by query + providers + time — unit testing against
specific claims would immediately drift. This harness asserts the **design
contract** CLAUDE.md promises: 3 phases, 4 modes, graceful degradation,
confidence taxonomy, and anti-loop protocols.

## What's asserted

- All 3 phases named (DISCOVER, SYNTHESIZE, CRITIQUE)
- All 4 mode flags documented (`--quick`, `--deep`, `--agent`, `--save`)
- Graceful degradation + WebSearch fallback claimed
- Both optional providers (Tavily, Exa) named
- Confidence levels (HIGH, MEDIUM, LOW + contradiction handling) documented
- `write-after-every-search` anti-loop pattern named
- Multi-perspective (STORM) search pattern named
- `allowed-tools` frontmatter present
- README and LICENSE shipped

## Run

```bash
bash tests/eval.sh
```

Exit 0 = contract intact. Exit 1 = regression.

## What this does NOT test

- Whether queries actually hit Tavily/Exa when keys are set
- Whether confidence scores correlate with source count
- Whether contradictions are genuinely surfaced
- Quality of the synthesized brief

Those need golden-run fixtures (a recorded research run on a known topic with
expected outputs). Deferred.

## Extending

- Any time a real research run misses an advertised feature, add an assertion.
- If a new provider is added, include it in the "Optional providers" check.
- If `--save` output format changes, add a file-format check.
