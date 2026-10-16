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

## Promoted from the capture tray (omit the section if none)
This PR is **opened as a draft and is never merged** by the skill. Each entry below stays
`state: proposed` until this PR's head branch is gone from the remote.

| entry id | track | evidence | destination | why not the instruction file |
|---|---|---|---|---|
| <id> | checkable | <path> (re-anchored from <commit>) | docs/topics/<area>.md | instruction file is at <n> of <budget> words |
| <id> | standing | asserted — nothing in the repo resolves it | docs/topics/<area>.md | a standing lesson never goes in it |
| <id> | decision | the alternative not adopted, and what was | docs/decisions/<date>-<id>.md | — |

- **Left staged**, nothing deleted: <id> — the evidence contradicts the claim: <the contradiction, named> · <id> — the evidence did not resolve and re-anchoring failed: <why>
- **Excluded by the secret scan**: <id> — <masked finding>. **Rotate the credential**, then reject that entry.

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
