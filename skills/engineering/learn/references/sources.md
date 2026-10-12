# Sources

Each rule in this skill should be traceable to something a reader can open. Where it
is, the source is named below. Where it is not, it is labelled a convention — a claim
this skill makes on its own authority, which you are free to overrule.

## Named public sources
- **No discoverable overviews.** Agents do not find context files they are not pointed at — hence the `@AGENTS.md` import and the explicit trigger phrases. *ETH Zurich AGENTS.md study.*
- **Doc gardening.** Context files rot unless a routine edits them on a cadence tied to real work; this is why `learn` runs post-merge rather than on request. *OpenAI harness-engineering write-up.*
- **Disposable specs vs. durable decisions.** A spec is scaffolding and gets retired; a decision outlives it and becomes an ADR. See spec-retirement.md. *Context Specs.*
- **Curated beats auto-generated.** An auto-generated context file measurably lowers task success while raising cost; a curated one helps slightly. This is the whole reason this skill caps lessons per PR instead of appending freely. *arXiv 2026 AGENTS.md efficiency study (also cited by `claude-md`).*

## Conventions (this skill's own judgment, not citations)
A map file that routes to detail; progressive disclosure into `references/`; every rule
states its *why*; prefer mechanical enforcement over prose; reference instead of copy;
learn after the task, not during it.

These are stated as practice because they have held up in use here, not because a study
is being quoted. If you need one of them to be authoritative, source it first.

## Provenance note
These rules were originally keyed to numbered practices (#2–#13, §4) in a private
research note held outside this repo. Numbers pointing at a document the reader cannot
open are not citations, so the numbering was removed rather than preserved. If that note
is ever trimmed and committed under `references/`, re-key the public claims to it and
move anything it actually sources out of the Conventions list above.
