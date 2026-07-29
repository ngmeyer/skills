# AAR playbook — running the four questions on a work session

Depth for **Phase 4** of `session-close`. SKILL.md carries the procedure; this
file carries the mechanism taxonomy, the worked examples, and the reasoning
behind the promotion gate. Load it when a session's delta is hard to name or an
Improve item is hard to route.

## Why an AAR and not a postmortem

An After Action Review is not a critique and not an incident postmortem. It runs
after *every* action, not only failures, and its output is forward-looking:
what to sustain, what to improve. The U.S. Army's framing is four questions —
what was supposed to happen, what actually happened, why the difference, what do
we learn — under a process-over-personality ground rule.

Two doctrinal properties carry over to agent sessions, and both are easy to lose:

- **It is short.** An AAR is minutes, not hours. An AAR that grows into a
  narrative has become the session dump this skill exists to prevent.
- **It is blameless by construction.** In doctrine that means rank-neutrality.
  For an agent it means: name the *mechanism*, never the actor. Self-criticism
  ("I stupidly assumed…") and blame-shifting ("the prompt was unclear") are the
  same failure — both stop the analysis before it reaches a change you can make.

## Q3 mechanism taxonomy

Q3 is the whole point of the exercise. A delta with no named mechanism produces
an Improve item nobody can act on. Classify against this list; extend it when a
session presents a mechanism that genuinely isn't here.

| Mechanism | Signature | Typical Improve item |
|---|---|---|
| **Missing context** | The fact existed and was readable; nobody read it | "Read `<file>` before touching `<area>`" |
| **Wrong assumption** | Acted on an unverified belief about the system | "Verify `<X>` by running `<cmd>`, don't infer it" |
| **Untested hypothesis chain** | Several fixes attempted before the cause was isolated | "Reproduce and isolate before the first fix" |
| **Scope drift** | Work delivered nobody asked for | "Refactors are a separate, asked-for change" |
| **Blocked dependency** | Cost/access/infra constraint discovered late | "Check `<constraint>` before spiking `<tech>`" |
| **Recurring known issue** | Previously identified, never fixed | escalate the existing item — see below |
| **Steering correction** | The user redirected the approach mid-session | capture the *preference* as a rule, if durable |

**Steering correction deserves a note.** When a user corrects an agent's proposed
approach, that is not a failure — it is the system working. It becomes an Improve
item only when the correction encodes a durable project constraint the agent
should have known ("in-process LRU is enough at this scale"). A one-off taste
call is not a rule. Promoting every correction to `CLAUDE.md` is how that file
bloats into uselessness.

## The promotion gate, and why it is strict

The temptation is to append every lesson to `CLAUDE.md`. The evidence says don't:
across 2,303 context files from 1,925 repositories, LLM-generated context files
*reduced* agent task success by roughly 2–3% while raising inference cost by more
than 20%; developer-written files bought about 4% at similar cost
([arXiv 2511.12884](https://arxiv.org/pdf/2511.12884)). Every promoted line is a
token the model processes before it reaches the actual task. A lesson that isn't
worth that toll makes the agent worse, not better.

The same discipline appears in procedural-memory research for coding agents:
CODESKILL keeps a learned skill only when it measurably improves success, merges
near-duplicates, and prunes low-utility entries — its three named failure modes
are memory bloat, lessons extracted from accidental successes, and interference
between overly specific rules ([arXiv 2605.25430](https://arxiv.org/pdf/2605.25430)).

So the gate is four checks, all of which must hold, and the default is *no*.

## Negative knowledge — the cheapest win available

The costliest cross-session failure mode for coding agents is re-attempting fixes
that have already been tried and already failed
([PROJECTMEM, arXiv 2606.12329](https://arxiv.org/pdf/2606.12329)). A fresh
session has no memory of the three approaches that didn't work, so it burns the
same hours discovering the same dead ends.

This is why the `DEAD_END` classification exists and why it outranks the general
"don't persist exploration" rule. The distinction:

- **Discard:** the *process* of exploring — files read, searches run, order of attempts.
- **Persist:** the *conclusion* — "approach X does not work here because Y."

One line each. A dead end without a reason is worse than nothing, because the
next session can't tell whether the constraint still applies.

**Worked example (from a thrashing debug session).** Three approaches failed
before the real cause surfaced. What persists is not the debugging narrative:

> Nightly job timeout: raising the timeout, indexing `created_at`, and batching
> the query all failed to help — the cost was an N+1 in the serializer, not the
> query plan.

That is one sentence, it names all three dead ends with the reason they were
irrelevant, and it stops the next session from re-running the same experiments.

**Worked example (blocked dependency).** A spike that ended in a wall:

> Temporal was evaluated and rejected: the self-hosted operator needs a
> persistent Postgres this project doesn't run, and the managed tier's pricing
> floor exceeds the project's infra budget.

Note what makes it durable — it names the *constraint*, so a future session with
a different budget can re-open the decision on purpose rather than by accident.

## Escalation, closure, and killing zombies

The measure of a retrospective practice is not whether documents get written. It
is whether the same contributing factor shows up again next time; postmortems
that are written and never tracked produce nothing
([incident.io](https://incident.io/blog/sre-incident-postmortem-best-practices)).
Vague, unowned action items are indistinguishable from no action items at all.

That is what the `PROCESS:` backlog tag is for. It gives an unproven Improve item
a home with cross-session state, so the *next* close can see it:

- **Recurred** — this session's Q3 named a mechanism matching an open `PROCESS:`
  item. It has now bitten twice, which satisfies the "recurrent or costly" check.
  Escalate it to `CLAUDE.md` through the Phase 8 gate.
- **Resolved** — the change was made. Check it off; it stops competing for attention.
- **Zombie** — open across three closes and never recurred. It was noise, not a
  lesson. Kill it explicitly and say so. A backlog of stale process items trains
  the reader to ignore the whole section.

Killing zombies is not optional bookkeeping. It is what keeps the surviving items
credible.

## Failure modes of this phase

- **AAR theater.** Producing three Improve items because the template has three
  slots. Most clean sessions yield zero. Zero is the correct and common answer.
- **Narrative creep.** Q2 becoming a chronology. It is one line: the outcome.
- **Promoting taste.** A one-off preference is not a project rule.
- **Blame in either direction.** Self-flagellation and prompt-blaming both end
  the analysis before it produces a change.
- **Silent discard.** An Improve item that fails the promotion gate goes to the
  backlog. It never evaporates without being written down or explicitly killed.
