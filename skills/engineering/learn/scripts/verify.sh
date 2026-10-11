#!/usr/bin/env bash
# learn — pre-PR verification. Run from the target repo root on the learn branch.
# Usage: verify.sh <merge-sha> <default-branch> <budget-words> [retired paths...]
# Env: BASE  — base of the merged PR (default <merge-sha>^1). Set it for rebase-merged
#              multi-commit PRs (PR base SHA, or `git merge-base`).
#      REMOTE — remote name (default origin). SPEC_DIRS — space-separated spec roots
#              (default "specs prds docs/specs").
set -u
MERGE=$1; DEF=$2; BUDGET=$3; shift 3
BASE=${BASE:-$MERGE^1}; REMOTE=${REMOTE:-origin}; SPEC_DIRS=${SPEC_DIRS:-"specs prds docs/specs"}
fail=0
f() { echo "FAIL  $*"; fail=1; }
br=$(git rev-parse --abbrev-ref HEAD)
[ "$br" != "$DEF" ] || f "on default branch $DEF"
git merge-base --is-ancestor "$MERGE" "$REMOTE/$DEF" 2>/dev/null || f "$MERGE not merged into $REMOTE/$DEF"
if [ -f AGENTS.md ]; then w=$(wc -w < AGENTS.md); [ "$w" -le "$BUDGET" ] || f "AGENTS.md $w words > $BUDGET"; fi
added=$(git diff --name-only --diff-filter=A "$BASE" "$MERGE")
for raw in "$@"; do
  p=${raw%/}
  # Delete-scope rule: relative, no globs/.., and >= 2 folders deep under a spec root
  # (e.g. specs/<feature>/...), never a spec root itself.
  case "$p" in /*|*..*|*'*'*|*'?'*|*'['*|'') f "unsafe retire path: '$raw'"; continue;; esac
  ok=0
  for r in $SPEC_DIRS; do
    case "$p" in "$r"/*) rest=${p#"$r"/}; [ -n "$rest" ] && ok=1;; esac
  done
  [ $ok = 1 ] || { f "retire path '$p' is not >=2 folders deep under a spec root ($SPEC_DIRS)"; continue; }
  echo "$added" | grep -qF -- "$p" || echo "WARN  $p not added by $BASE..$MERGE (needs explicit user naming)"
  refs=$(git grep -nF -- "$p" -- AGENTS.md CLAUDE.md docs ':!docs/archive' 2>/dev/null)
  [ -z "$refs" ] || { f "live link to retired $p:"; echo "$refs"; }
  [ -z "$(git log --all --oneline "^$REMOTE/$DEF" "^HEAD" -- "$p" | head -1)" ] || echo "WARN  $p touched on another unmerged branch"
done
[ -f scripts/context-docs.mjs ] && { node scripts/context-docs.mjs || f "context-docs lint"; }
if [ $fail = 0 ]; then echo "PASS"; else echo "VERIFY FAILED"; exit 1; fi
