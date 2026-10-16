# Retiring specs and slices
Specs/slices are disposable once the feature merges; leaving them makes retrieval return outdated intent.

**Scope (all must hold for a file to be retired):**
- path is under a spec dir (`specs/`, `prds/`, `docs/specs/`, or repo-declared) AND
- it was added by the merged PR, or by commits linked to it, or the user named it explicitly; AND
- no open PR/branch modifies it (`git log --all --not origin/<default> -- <path>` empty; forge open-PR file lists if available); AND
- no live doc links to it except the PR itself (repair those links in the same PR).

**Action:** default `git mv <path> docs/archive/<feature>/` (reversible, keeps history, still greppable unless the repo ignores archive). Delete only if repo convention says "delete" AND the user confirmed in this run. Done-test scripts that still guard behavior are NOT specs: move them under tests/ or keep.

**Before retiring:** unfinished items (open questions, deferred slices) → issue or backlog line, linked in PR body. Durable bits → already harvested in step 2.

Enforced by scripts/verify.sh: path must be relative, glob-free, and >= 2 folders deep under a spec root (`specs/<feature>`, never `specs/`).
Never: wildcard deletes (`rm -r specs/`), retiring another feature's dir, retiring files outside the repo.
