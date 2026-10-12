#!/usr/bin/env bash
# Repo-wide skill lint (context best practices). There is no CI: run before every push.
#
# What this script CAN check (mechanical): frontmatter shape, metadata.owner, SKILL.md
# length, Changelog placement, missing tests/eval.sh, plugin.json listing, hardcoded user
# paths, Claude-only paths in core, user-invocable, presence of a trigger phrase.
#
# What it CANNOT check -- a clean run is not a passing audit. These need a human or an
# agent reading the prose:
#   1. Does each rule say *why*?  A rule without a reason gets dropped under pressure.
#   2. Is content copied or referenced?  Duplicated text drifts; a pointer cannot.
#   3. Is the trigger actually *clear*?  Grepping for the word "trigger" proves the word
#      is present, not that an agent can tell when to reach for the skill.
# Usage: scripts/lint-skills.sh [--strict] [--evals]
#   default  : hard rules FAIL, best-practice gaps WARN (exit 1 only on FAIL)
#   --strict : WARNs also fail (target once existing skills are migrated)
#   --evals  : also run every skills/*/*/tests/eval.sh
set -u
cd "$(dirname "$0")/.."
STRICT=0; EVALS=0
for a in "$@"; do case $a in --strict) STRICT=1;; --evals) EVALS=1;; esac; done
F=0; W=0
fail() { echo "FAIL  $1"; F=$((F+1)); }
warn() { echo "WARN  $1"; W=$((W+1)); }
MAX_LINES=${MAX_LINES:-250}
for skill in skills/*/*/; do
  s=${skill%/}; md=$s/SKILL.md; n=$(basename "$s")
  [ -f "$md" ] || { fail "$s: no SKILL.md"; continue; }
  # hard rules (repo CLAUDE.md)
  head -1 "$md" | grep -qx -- '---' || fail "$n: no frontmatter"
  grep -qE "^name: $n\$" "$md" || fail "$n: frontmatter name != dir name"
  grep -qE '^description:' "$md" || fail "$n: no description"
  [ -f "$s/tests/eval.sh" ] || fail "$n: missing tests/eval.sh"
  grep -qF "\"./$s\"" .claude-plugin/plugin.json || fail "$n: not listed in plugin.json"
  [ -f "$s/README.md" ] && fail "$n: README.md inside skill dir (SKILL.md is the doc)"
  # placeholder users (me, alice, you, name, <x>) are allowed examples
  grep -oE '/(Users|home)/[A-Za-z0-9_.-]+' "$md" | grep -vE '/(Users|home)/(me|alice|bob|you|user|name|username)$' | grep -q . && fail "$n: hardcoded user path"
  # best-practice gaps (context audit)
  l=$(wc -l < "$md"); [ "$l" -le "$MAX_LINES" ] || warn "$n: SKILL.md $l lines > $MAX_LINES (move detail to references/)"
  [ "$l" -gt 150 ] && [ ! -d "$s/references" ] && warn "$n: $l lines and no references/"
  grep -qE '^\s+owner:|^owner:' "$md" || warn "$n: no metadata.owner"
  grep -qE '^## Changelog' "$md" && warn "$n: ## Changelog in SKILL.md (always-loaded history; move out)"
  # Portability is only a goal for skills that claim it. A skill whose whole job is
  # Claude's own local memory declares `harness: claude-code` and is not nagged to
  # abstract away the paths it exists to manage.
  if grep -qE '^[[:space:]]*harness:[[:space:]]*claude-code' "$md"; then
    :
  else
    c=$(grep -cE '~/\.claude' "$md"); [ "$c" -eq 0 ] || warn "$n: $c Claude-only path(s) in core (move to references/harness-*.md, or declare metadata.harness: claude-code)"
  fi
  grep -qE '^user-invocable:' "$md" || warn "$n: no user-invocable (no /$n slash command in Claude Code)"
  grep -qiE 'use when|trigger' "$md" || warn "$n: no explicit trigger phrases"
done
# plugin.json entries must exist
for p in $(grep -oE '"\./skills/[^"]+"' .claude-plugin/plugin.json | tr -d '"'); do [ -f "$p/SKILL.md" ] || fail "plugin.json lists missing $p"; done
if [ $EVALS = 1 ]; then
  for e in skills/*/*/tests/eval.sh; do bash "$e" >/dev/null 2>&1 && echo "PASS  eval $e" || fail "eval $e"; done
fi
echo "FAIL: $F  WARN: $W"
[ $F -eq 0 ] && { [ $STRICT = 0 ] || [ $W -eq 0 ]; }
