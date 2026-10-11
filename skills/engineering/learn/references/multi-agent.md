# Multi-agent and concurrency rules
- **Lock by branch name:** `learn/<pr>-<slug>`. If the branch or an open PR with that head already exists, do not create a second; append to it or stop and report.
- **Rebase before PR:** fetch default, rebase, re-run dedupe/staleness (another learn PR may have merged the same lesson).
- **Line-level edits only** to AGENTS.md; conflicts are then small and reviewable. Never rewrite the file.
- **No auto-merge, no push to default** regardless of harness permissions. The human merges.
- **Spec retirement re-check after rebase:** an in-flight branch may have started touching the spec since step 6.
- Session-close (local) and learn (repo) never write the same file: local memory vs committed context.
