# PR body template
Title: `learn: lessons from #<PR> (<feature>)`

```
## Source
Merged PR: #<n> (<merge sha>) · specs: <paths> · run by: <agent/harness> at <ISO time>

## Lessons (≤5)
| # | action | file | line(s) | lesson (do/don't + why) | evidence |
|---|---|---|---|---|---|
| 1 | ADD | AGENTS.md | +L42 | ... | review comment URL / file:line |
| 2 | EDIT | docs/topics/billing.md | L10 | ... | diff hunk |
| 3 | DELETE | AGENTS.md | -L18 | stale: `scripts/old.sh` removed in <sha> | diff hunk |

## Considered and dropped
- <candidate> — reason (throwaway: one-off / discoverable / unverified / duplicate of <file:line>)

## Retired
| path | action | why safe |
|---|---|---|
| specs/<feature>/ | moved → docs/archive/<feature>/ | added by #<n>; no open PR touches it; 0 inbound links |

## Follow-ups (not in this PR)
- issue #… open question from slice 04
- proposed lint: <invariant>

## Verification
- [ ] verify.sh passed (output below)
- [ ] AGENTS.md words: <before> → <after> (budget <n>)
- [ ] reviewer: confirm each DELETE
```
