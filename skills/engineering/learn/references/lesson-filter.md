# Lesson filter: durable vs throwaway
Keep a candidate only if ALL four are yes. Why each gate exists is in brackets.
1. **Recurs** — would a different feature in this repo hit it? [one-off facts rot instantly]
2. **Non-obvious** — not findable with one grep/read of the code or README. [ETH: discoverable overviews add tokens, not success]
3. **Actionable** — phrased as do/don't + reason; changes agent behavior. [descriptive trivia is ignored]
4. **Evidenced** — in one of two classes, and the entry says which. [lessons from abandoned attempts mislead]
   - *Resolved* (`checkable`): true in the merged tree; evidence = file:line, commit, or review URL. A commit alone is not enough — a squash merge routinely leaves it unreachable — so the entry's paths are the anchor that survives: a citation that stops resolving is re-anchored against them, or surfaced, never dropped. Evidence that resolves and *contradicts* the claim is surfaced with the contradiction named, and the candidate waits; it is not deleted, because nothing can tell a claim that was always false from one the merge just fixed.
   - *Recorded* (`decision`): the alternative considered and not adopted, what was adopted instead, and where it was settled. A rejected alternative has no merged-tree artifact **by definition**, so demanding one would drop exactly the lesson worth keeping — the record of the choice *is* the evidence. This second class is why the gate is two classes rather than one gate loosened for every track.

   A `standing` lesson has neither class: nothing in the repository resolves it, so the evidence step does not apply. It is neither dropped nor promoted as verified — it goes to `docs/topics/` flagged **asserted**, and **never into the instruction file**.

| durable (keep) | throwaway (drop) |
|---|---|
| "Scheduled-job routes must use the shared auth helper; a bare header check rejects the scheduler (review comment on the PR)" | "Slice 03 took two tries" |
| "Run `npm run verify:local` before push; CI does not run e2e" | task checklists, slice ordering, status |
| new invariant → propose lint + pointer | restating what the diff did |
| decision with rejected alternatives → ADR | spec acceptance criteria already encoded as tests |

Tie-breaker: if a lesson can be a test or lint, propose the check and keep at most a one-line pointer in prose.
Cap: ≤ 5 lessons per PR. More than that usually means throwaway leaked in.
