# Multi-agent and concurrency rules
- **Lock by branch name:** `learn/<pr>-<slug>`. If the branch or an open PR with that head already exists, do not create a second; append to it or stop and report.
- **Rebase before PR:** fetch default, rebase, re-run dedupe/staleness (another learn PR may have merged the same lesson).
- **Line-level edits only** to AGENTS.md; conflicts are then small and reviewable. Never rewrite the file.
- **No auto-merge, no push to default** regardless of harness permissions. The human merges.
- **Spec retirement re-check after rebase:** an in-flight branch may have started touching the spec since step 6.
- **Session-close vs learn is a file boundary, not a domain one:** both can run on a session with nothing merged, so what separates them is which files each one writes. Session-close writes local memory; learn writes repository files, and only by proposing them in a PR. A tray entry is neither — it is outside the working tree and outside version control until promotion. They never write the same file, so the two can run on one session in either order.
