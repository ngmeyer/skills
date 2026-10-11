# Lesson filter: durable vs throwaway
Keep a candidate only if ALL four are yes. Why each gate exists is in brackets.
1. **Recurs** — would a different feature in this repo hit it? [one-off facts rot instantly]
2. **Non-obvious** — not findable with one grep/read of the code or README. [ETH: discoverable overviews add tokens, not success]
3. **Actionable** — phrased as do/don't + reason; changes agent behavior. [descriptive trivia is ignored]
4. **Verified** — true in the merged tree; evidence = file:line, commit, or review URL. [lessons from abandoned attempts mislead]

| durable (keep) | throwaway (drop) |
|---|---|
| "Scheduled-job routes must use the shared auth helper; a bare header check rejects the scheduler (review comment on the PR)" | "Slice 03 took two tries" |
| "Run `npm run verify:local` before push; CI does not run e2e" | task checklists, slice ordering, status |
| new invariant → propose lint + pointer | restating what the diff did |
| decision with rejected alternatives → ADR | spec acceptance criteria already encoded as tests |

Tie-breaker: if a lesson can be a test or lint, propose the check and keep at most a one-line pointer in prose.
Cap: ≤ 5 lessons per PR. More than that usually means throwaway leaked in.
