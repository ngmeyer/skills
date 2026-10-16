#!/usr/bin/env bash
# Always-loaded instruction budget. AGENTS.md is read by every agent on every session, so
# its size is a cost paid on every task. There is no CI: run before every push.
#
# MAX_WORDS=400 matches the fallback budget the `learn` skill's verify.sh uses, and keeps
# the file well inside OpenAI's "roughly 100 lines" map guidance and Claude Code's
# "under 200 lines" target. Overflow goes to docs/topics/, linked from AGENTS.md.
#
# Usage: scripts/lint-agents-md.sh        (exit 1 on any FAIL)
set -u
cd "$(dirname "$0")/.."
MAX_WORDS=${MAX_WORDS:-400}
F=0
fail() { echo "FAIL  $1"; F=$((F+1)); }
[ -f AGENTS.md ] || fail "no AGENTS.md (the canonical instruction file)"
if [ -f AGENTS.md ]; then
  w=$(wc -w < AGENTS.md)
  [ "$w" -le "$MAX_WORDS" ] && echo "PASS  AGENTS.md $w/$MAX_WORDS words" || fail "AGENTS.md $w words > $MAX_WORDS (move overflow to docs/topics/)"
  # every docs/topics/ file should be reachable from AGENTS.md, or nothing loads it
  for t in docs/topics/*.md; do [ -f "$t" ] || continue; grep -qF "$t" AGENTS.md || fail "$t not linked from AGENTS.md"; done
fi
# CLAUDE.md must stay a pointer: an @AGENTS.md import and nothing that could drift
if [ -f CLAUDE.md ]; then
  grep -qx '@AGENTS.md' CLAUDE.md || fail "CLAUDE.md does not import @AGENTS.md"
  [ "$(grep -cv '^[[:space:]]*$' CLAUDE.md)" -le 1 ] || fail "CLAUDE.md holds more than the @AGENTS.md import"
fi
echo "FAIL: $F"
[ $F -eq 0 ]
