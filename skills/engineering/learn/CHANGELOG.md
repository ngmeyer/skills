# learn changelog

History lives here, not in `SKILL.md` — a changelog is loaded on every invoke and changes
no behavior. The version it tracks is `metadata.version` in `SKILL.md`, which is this
skill's own; `.claude-plugin/plugin.json` carries a separate version covering every skill
in the repo and is not this file's business.

## 0.4.0 (2026-10-14)

**A session with nothing to merge now has somewhere to put a lesson.** Until this version
the skill stopped at step 1 unless a PR had merged, so a debugging, planning or exploring
session had no path through it at all. It now has a third mode: entries are staged in a
per-repository capture tray that lives in the shared git directory, outside the working
tree and outside version control, with verbs to capture, list, reject, promote and record
the proposed PR. A later session — another week, another worktree — selects and judges
what was staged. Promotion re-enters the main procedure at the Place step, routes by
track, resolves evidence before routing, and deletes nothing: a contradicted claim is
surfaced with the contradiction named and left staged, because nothing can tell a claim
that was always false from one the merge just fixed.

**The description was the bug.** A harness decides whether to load a skill from
`description` alone, and this one opened "Post-merge learning pass. After a feature PR
merges, …" with seven merge-dependent triggers and nothing a no-merge session would ever
say. The mode above was implemented and unreachable. The framing is corrected in all three
places it is written down — the frontmatter, the repository README, and the plugin
manifest's installer blurb — and `tests/eval.sh` now pins each one, which nothing did
before.

**The boundary with `session-close` moved from the domain to the file set.** Both skills
can now run on a session with nothing merged, so "local memory versus committed context"
no longer tells them apart. What does is which files each one writes: `session-close`
writes local memory, `learn` writes repository files and only by proposing them in a PR.
A tray entry is neither until promotion.

**The leak detector no longer is the leak.** It used to hold a list of real private
project names in plaintext — a published list of the names it existed to keep out — and it
scanned every file but the one it lived in. It now has two halves:

- **Path shapes.** An absolute user or volume path, an encoded agent-home namespace, or a
  container agent's home, matched as shapes so no real name is needed to express them. The
  documented tilde-relative harness locations in `references/harness-notes.md` stay legal,
  which is the point of matching the encoded form rather than the placeholder.
- **A name detector whose terms are never committed.** It reads one term per line from
  `tests/private-terms.local` (gitignored; override with `LEARN_PRIVATE_TERMS`), reports a
  match masked — the file, never the term — and has three outcomes rather than two, because
  "cannot scan" must never read as "clean". A term file that is missing or holds no terms
  after comment-stripping is reported as a scan that did not happen, and the one belonging
  to a `LEARN_PRIVATE_TERMS` that was explicitly set is a hard failure.

Both halves now scan the test directory and this changelog too. **Operator note:** a fresh
clone has no term list, by construction, so the real-tree name scan reports `SKIP` and the
summary says the result is not clean. Write the terms you care about into
`tests/private-terms.local` to turn that into a real check. The detector's own mechanism is
proved against a fixture on every run regardless, so a clean clone still gets a gate.

## 0.3.0 (2026-10-11)

Read the memory format the harness actually writes rather than an assumed one: a fact is a
bullet *or* a whole file, and one repo can own more than one memory namespace, so a count
taken from either alone is wrong. Sourced the rules behind the lesson filter honestly and
dropped an invented export format that no tool produces.

## 0.2.0 (2026-10-11)

Added `from-memories`: import durable lessons out of agent memory files into each repo the
same way a merge does, one draft PR per repo, with a mandatory redact gate that blocks a
file rather than warning about it.

## 0.1.0 (2026-10-11)

First version. The post-merge pass: harvest candidates from the merged diff and the review
threads, filter durable from throwaway, place each lesson, dedupe against what the context
already says, retire the feature's specs, and propose the lot as one draft PR that is never
merged by the skill.
