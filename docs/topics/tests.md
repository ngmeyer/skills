# Skill evals (`tests/eval.sh`)

- Eval fixtures that create git repos must use git init -b main (and init --bare -b main for origins) so a host whose init.defaultBranch is master does not leave clones empty (learn: skills/engineering/learn/tests/eval.sh fixture helpers, fixed in b4bc5c6 on PR #1; skills/engineering/learn/tests/eval.sh, CLAUDE.md)
