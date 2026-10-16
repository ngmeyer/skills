# Releasing and leak checks

Linked from `AGENTS.md`. Moved here to keep the always-loaded file under its word budget.

## Pushing to `main` is production

Pushing to GitHub `main` publishes immediately: it updates the skills.sh package and the plugin marketplace, and downstream consumers (incl. Vercel installs) are notified on every push.

- **Test before you push.** Run the affected skill's `tests/eval.sh` and confirm 0 failures. There is no CI: the eval is the gate, and you are it.
- **Never push** a red eval, a WIP change, or an unscoped working tree. Stage only the files that ship.
- **Batch** related changes into one push; every push pings consumers.
- A docs-only change (`AGENTS.md`, README) is still a production push: same discipline, lower risk.

## Leak checks before pushing

Grep for internal project names, real product/repo references, and secrets. Each skill's `tests/eval.sh` carries a self-containment guard that fails on known internal names; running the eval is the gate. A skill that mentions a real internal project in an example, a changelog, or a validation note is a leak: genericize it ("a production web codebase", not the project's name).

Forbidden in any skill: hardcoded user paths (`/Users/<name>`, `/Volumes/...`, `~/.claude/projects/...`; use `$HOME`, `~`, or placeholders), private project names or business metrics, secrets or secret locations.

## Version-gated agent behavior

`CLAUDE.md` is a one-line `@AGENTS.md` import. Claude Code reads `AGENTS.md` directly from v2.1.277, but only when no `CLAUDE.md` exists; the import covers older versions and sessions that cannot load `AGENTS.md`, and never loads it twice (https://code.claude.com/docs/en/memory#agents-md). Use the import, not a symlink: a committed symlink checks out as a plain text file on Windows without `core.symlinks`.
