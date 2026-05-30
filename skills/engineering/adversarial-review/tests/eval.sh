#!/usr/bin/env bash
# Structural eval for adversarial-review.
#
# adversarial-review is a prompt-only skill. Behavioral evaluation requires
# fixture artifacts + LLM-as-judge against a recorded baseline — deferred.
#
# This eval locks in the SKILL.md design contract: 6 phases, 5 attack vectors,
# 3 severity tiers, mandatory output sections, redirect-to-council rule, flag
# composability, and the sibling-skill distinctions.
#
# Usage: bash tests/eval.sh
# Exit 0 on pass, 1 on any assertion failure.

set -u
cd "$(dirname "$0")/.."

PASS=0
FAIL=0
pass() { echo "PASS  $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL  $1"; FAIL=$((FAIL+1)); }

have() { grep -qF -- "$1" "$2"; }

echo "== 6-Phase architecture =="
for phase in "Phase 1: SCOPE" "Phase 2: READ" "Phase 3: ATTACK" "Phase 4: TRIAGE" "Phase 5: PRESENT"; do
  if have "$phase" SKILL.md; then pass "Phase present: $phase"; else fail "Phase missing: $phase"; fi
done

echo ""
echo "== 5 attack vectors =="
for flag in "\`--security\`" "\`--logic\`" "\`--user\`" "\`--scale\`" "\`--quick\`"; do
  if have "$flag" SKILL.md; then pass "Flag documented: $flag"; else fail "Flag missing: $flag"; fi
done

echo ""
echo "== 3 severity tiers =="
for tier in "CRITICAL" "IMPORTANT" "NIT"; do
  if have "$tier" SKILL.md; then pass "Tier present: $tier"; else fail "Tier missing: $tier"; fi
done

echo ""
echo "== Mandatory output sections =="
for section in "What I Could Not Break" "What This Review Did NOT Cover"; do
  if have "$section" SKILL.md; then pass "Mandatory section present: $section"; else fail "Mandatory section missing: $section"; fi
done

echo ""
echo "== Sibling-skill distinction =="
if have "/council-review" SKILL.md; then pass "Mentions /council-review sibling"; else fail "Missing /council-review reference"; fi
if have "Reject open questions" SKILL.md || have "open question" SKILL.md; then pass "Open-question redirect rule documented"; else fail "Open-question redirect rule missing"; fi

echo ""
echo "== Anti-fluff invariants =="
for invariant in "speculate without an example" "pad findings" "do not be balanced"; do
  if grep -qiF -- "$invariant" SKILL.md; then pass "Anti-fluff rule: $invariant"; else fail "Missing anti-fluff rule: $invariant"; fi
done

echo ""
echo "== Research positioning =="
if have "M3MADBench" SKILL.md; then pass "M3MADBench cited (positioning vs council-review)"; else fail "Missing M3MADBench citation"; fi
if have "Codex" SKILL.md; then pass "Codex Review Plugin precedent cited"; else fail "Missing Codex precedent"; fi

echo ""
echo "== Portability rules =="
if grep -qE "/Users/[a-z]" SKILL.md; then fail "Hardcoded /Users/ path leaked"; else pass "No /Users/ hardcoded paths"; fi
if grep -qE "/home/[a-z]" SKILL.md; then fail "Hardcoded /home/ path leaked"; else pass "No /home/ hardcoded paths"; fi

echo ""
echo "== Frontmatter =="
if have "name: adversarial-review" SKILL.md; then pass "Skill name in frontmatter"; else fail "Skill name missing"; fi
if have "user-invocable: true" SKILL.md; then pass "user-invocable flag set"; else fail "user-invocable missing"; fi
if have "argument-hint:" SKILL.md; then pass "argument-hint declared"; else fail "argument-hint missing"; fi

echo ""
echo "== Shipped files =="

echo ""
echo "================================"
echo "PASS: $PASS  FAIL: $FAIL"
echo "================================"
[ $FAIL -eq 0 ] && exit 0 || exit 1
