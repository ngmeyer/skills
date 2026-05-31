#!/usr/bin/env bash
# Structural eval for deep-research.
#
# deep-research is a prompt-only skill; its runtime output is non-deterministic
# (LLM synthesis over live search). This eval locks in the design contract:
# SKILL.md must still name every phase, every mode, and every V2 faithfulness
# lever the changelog claims. If any drifts, the skill's advertised behavior no
# longer matches its implementation.
#
# Behavioral quality (does the brief catch false triangulation, abstain on
# single-source claims, etc.) is verified separately via the source-fixed
# blind A/B recorded in the SKILL.md changelog.
#
# Usage: bash tests/eval.sh
# Exit 0 on pass, 1 on any assertion failure.

set -u
cd "$(dirname "$0")/.."

PASS=0
FAIL=0
pass() { echo "PASS  $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL  $1"; FAIL=$((FAIL+1)); }
have() { grep -qF "$1" "$2"; }
haveR() { grep -qE "$1" "$2"; }

echo "== Frontmatter =="
if haveR '^name: deep-research' SKILL.md; then pass "name is deep-research"; else fail "name wrong/missing"; fi
if haveR '^description:' SKILL.md; then pass "description present"; else fail "description missing"; fi
# description trigger should not be duplicated (V2 fix)
DUP=$(grep -o "'deep research'" SKILL.md | wc -l | tr -d ' ')
if [ "$DUP" -le 1 ]; then pass "no duplicate 'deep research' trigger"; else fail "duplicate trigger ($DUP)"; fi

echo "== Phases =="
for phase in "Phase 0: Frame" "Phase 1: DISCOVER" "Phase 2: SYNTHESIZE" "Phase 3: VERIFY" "Phase 4: DELIVER"; do
  if have "$phase" SKILL.md; then pass "Phase present: $phase"; else fail "Phase missing: $phase"; fi
done

echo "== Modes =="
for flag in '`--quick`' '`--deep`' '`--agent`' '`--save'; do
  if have "$flag" SKILL.md; then pass "Mode/flag documented: $flag"; else fail "Mode/flag missing: $flag"; fi
done

echo "== Graceful degradation (must work with zero API keys) =="
if have "WebSearch fallback" SKILL.md || have "zero API keys" SKILL.md; then pass "graceful degradation kept"; else fail "graceful degradation dropped"; fi

echo "== V2 faithfulness levers (changelog contract) =="
have "quote span" SKILL.md && pass "quote-grounded citations" || fail "quote-grounding missing"
have "independent origin" SKILL.md && pass "source-independence grouping" || fail "independence grouping missing"
have "Chain-of-Verification" SKILL.md && pass "chain-of-verification" || fail "CoVe missing"
have "draft hidden" SKILL.md && pass "factored CoVe (draft hidden)" || fail "factored-CoVe detail missing"
have "Sourced" SKILL.md && have "Analysis" SKILL.md && pass "Sourced vs Analysis split" || fail "Sourced/Analysis split missing"
have "stale by default" SKILL.md && pass "staleness discipline" || fail "staleness missing"
have "SIFT" SKILL.md && pass "SIFT lateral reading" || fail "SIFT missing"
have "Terminology Map" SKILL.md && pass "Terminology Map (regression guard)" || fail "Terminology Map missing"
have "Evidence Matrix" SKILL.md && pass "Evidence Matrix" || fail "Evidence Matrix missing"
have "Evidence insufficient" SKILL.md && pass "abstention rule" || fail "abstention missing"

echo "== Convention compliance =="
have "## Gotchas" SKILL.md && pass "Gotchas heading (not 'What NOT to Do')" || fail "Gotchas heading missing"
if have "What NOT to Do" SKILL.md; then fail "stale 'What NOT to Do' heading present"; else pass "no 'What NOT to Do' heading"; fi
have "## Changelog" SKILL.md && pass "Changelog present" || fail "Changelog missing"
have "## Credits" SKILL.md && pass "Credits present" || fail "Credits missing"

echo "== Line budget (Anthropic bar 500) =="
LINES=$(wc -l < SKILL.md | tr -d ' ')
if [ "$LINES" -le 500 ]; then pass "SKILL.md $LINES lines (<=500)"; else fail "SKILL.md $LINES lines (>500)"; fi

echo ""
echo "======================================"
echo "  PASS: $PASS    FAIL: $FAIL"
echo "======================================"
[ "$FAIL" -eq 0 ]
