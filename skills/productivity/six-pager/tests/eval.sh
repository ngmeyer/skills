#!/usr/bin/env bash
# Structural eval for six-pager.
#
# six-pager is a prompt-only skill. Behavioral evaluation requires fixture
# topics + LLM-as-judge against expected document structure — moderate fixture
# cost, deferred. This harness asserts the SKILL.md design contract: 6 phases,
# 2 modes, 6 canonical memo sections, 3 PRFAQ sub-documents, prose-audit
# checks, sibling-skill awareness, three-tradition citation, anti-fake-numbers
# invariant, and the Quality Bar.
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
for phase in "Phase 1: SCOPE" "Phase 2: DRAFT" "Phase 3: CONSTRAIN" "Phase 4: AUDIT" "Phase 5: PRESENT" "Phase 6: SAVE"; do
  if have "$phase" SKILL.md; then pass "Phase present: $phase"; else fail "Phase missing: $phase"; fi
done

echo ""
echo "== 2 modes =="
for mode in "memo" "prfaq"; do
  if have "\`$mode\`" SKILL.md || have " $mode " SKILL.md; then pass "Mode present: $mode"; else fail "Mode missing: $mode"; fi
done

echo ""
echo "== 6 canonical memo sections =="
for section in "Introduction" "Goals" "Tenets" "State of the Business" "Lessons Learned" "Strategic Priorities" "Appendix"; do
  if have "$section" SKILL.md; then pass "Memo section: $section"; else fail "Memo section missing: $section"; fi
done

echo ""
echo "== 3 PRFAQ sub-documents =="
for sub in "Press Release" "External FAQ" "Internal FAQ"; do
  if have "$sub" SKILL.md; then pass "PRFAQ sub: $sub"; else fail "PRFAQ sub missing: $sub"; fi
done

echo ""
echo "== Prose-audit checks (Strunk + Anthropic) =="
for check in "Passive voice" "Vague language" "Needless words" "Qualifiers" "Parallel construction" "Topic sentence" "Overstatement" "Removability"; do
  if have "$check" SKILL.md; then pass "Audit check: $check"; else fail "Audit check missing: $check"; fi
done

echo ""
echo "== Three traditions cited =="
for tradition in "Bezos" "Strunk" "Anthropic"; do
  if have "$tradition" SKILL.md; then pass "Tradition cited: $tradition"; else fail "Tradition missing: $tradition"; fi
done
if have "Working Backwards" SKILL.md; then pass "Working Backwards book cited"; else fail "Working Backwards missing"; fi
if have "Elements of Style" SKILL.md; then pass "Elements of Style cited"; else fail "Elements of Style missing"; fi
if have "removability test" SKILL.md; then pass "Removability test cited"; else fail "Removability test missing"; fi

echo ""
echo "== Sibling-skill awareness (only skills shipped in this repo) =="
for sibling in "/council-review" "/adversarial-review"; do
  if have "$sibling" SKILL.md; then pass "Sibling referenced: $sibling"; else fail "Sibling missing: $sibling"; fi
done

echo ""
echo "== Anti-fake-numbers invariant =="
if have "Do not generate fake numbers" SKILL.md || have "fake numbers" SKILL.md; then pass "Anti-fake-numbers rule present"; else fail "Anti-fake-numbers rule missing"; fi
if have "Generic placeholders" SKILL.md || have "generic placeholders" SKILL.md; then pass "Generic-placeholders rejected"; else fail "Generic-placeholders rule missing"; fi

echo ""
echo "== Hard 6-page cap =="
if have "6 pages" SKILL.md; then pass "6-page cap stated"; else fail "6-page cap missing"; fi
if have "constraint IS the value" SKILL.md; then pass "Constraint-is-the-value framing present"; else fail "Constraint-is-the-value framing missing"; fi

echo ""
echo "== Tenets discipline =="
if have "no qualifiers" SKILL.md; then pass "Tenets-no-qualifiers rule present"; else fail "Tenets-no-qualifiers rule missing"; fi
if have "Hedged Tenets" SKILL.md || have "hedge" SKILL.md; then pass "Hedge-detection invariant present"; else fail "Hedge-detection invariant missing"; fi

echo ""
echo "== PRFAQ canonical question =="
if have "what would cause us to kill this" SKILL.md || have "kill this" SKILL.md; then pass "PRFAQ kill-question present"; else fail "PRFAQ kill-question missing"; fi
if have "work backwards" SKILL.md || have "Work backwards" SKILL.md; then pass "Work-backwards principle stated"; else fail "Work-backwards principle missing"; fi

echo ""
echo "== Quality bar =="
if have "Quality Bar" SKILL.md; then pass "Quality Bar section present"; else fail "Quality Bar section missing"; fi

echo ""
echo "== Optional flags =="
for flag in "\`--silent-read\`" "\`--strunk-only\`"; do
  if have "$flag" SKILL.md; then pass "Flag documented: $flag"; else fail "Flag missing: $flag"; fi
done

echo ""
echo "== Portability rules =="
if grep -qE "/Users/[a-z]" SKILL.md; then fail "Hardcoded /Users/ path leaked"; else pass "No /Users/ hardcoded paths"; fi
if grep -qE "/home/[a-z]" SKILL.md; then fail "Hardcoded /home/ path leaked"; else pass "No /home/ hardcoded paths"; fi

echo ""
echo "== Frontmatter =="
if have "name: six-pager" SKILL.md; then pass "Skill name in frontmatter"; else fail "Skill name missing"; fi
if have "user-invocable: true" SKILL.md; then pass "user-invocable flag set"; else fail "user-invocable missing"; fi
if have "argument-hint:" SKILL.md; then pass "argument-hint declared"; else fail "argument-hint missing"; fi

echo ""
echo "== Shipped files =="

echo ""
echo "================================"
echo "PASS: $PASS  FAIL: $FAIL"
echo "================================"
[ $FAIL -eq 0 ] && exit 0 || exit 1
