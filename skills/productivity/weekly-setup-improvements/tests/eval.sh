#!/usr/bin/env bash
# Structural eval for weekly-setup-improvements.
#
# weekly-setup-improvements is a prompt-only skill. A full behavioral eval would
# require (a) a fixture folder with 7 days of seeded activity and (b) a recorded
# expected report. That's deferred to a follow-up pass.
#
# This eval locks in the SKILL.md design contract: 6 phases, the 5 analysis
# lenses, the 5 report sections, the quality bar, the cap on skill ideas, and
# portability rules.
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
have_re() { grep -qE -- "$1" "$2"; }

echo "== 6-Phase architecture (+ V3 Phase 5b) =="
for phase in "Phase 1: SCOPE" "Phase 2: SURVEY" "Phase 3: READ" "Phase 4: ANALYZE" "Phase 5: WRITE" "Phase 5b: MATERIALIZE DRAFTS" "Phase 6: PRESENT"; do
  if have "$phase" SKILL.md; then pass "Phase present: $phase"; else fail "Phase missing: $phase"; fi
done

echo ""
echo "== 5 analysis lenses (Phase 4) =="
for lens in "Repetition" "Manual effort" "Drift" "Bloat" "Wins"; do
  if have "$lens" SKILL.md; then pass "Lens present: $lens"; else fail "Lens missing: $lens"; fi
done

echo ""
echo "== 5 report sections =="
for section in \
  "## 1. Context File Updates" \
  "## 2. New Skill Ideas" \
  "## 3. Workflow Gaps" \
  "## 4. Files to Clean Up" \
  "## 5. What's Working"; do
  if have "$section" SKILL.md; then pass "Section present: $section"; else fail "Section missing: $section"; fi
done

echo ""
echo "== Quality bar =="
if have "Quality Bar" SKILL.md; then pass "Quality Bar section present"; else fail "Quality Bar section missing"; fi
if have "Cap at 3" SKILL.md; then pass "Skill-idea cap (3) present"; else fail "Skill-idea cap missing"; fi
for hedge in "consider" "perhaps" "hedging"; do
  if have "$hedge" SKILL.md; then pass "Hedge banned: $hedge"; else fail "Hedge ban missing: $hedge"; fi
done

echo ""
echo "== Portability rules =="
if grep -qE "/Users/[a-z]" SKILL.md; then fail "Hardcoded /Users/ path leaked"; else pass "No /Users/ hardcoded paths"; fi
if grep -qE "/home/[a-z]" SKILL.md; then fail "Hardcoded /home/ path leaked"; else pass "No /home/ hardcoded paths"; fi
if have 'date -v' SKILL.md; then
  # Allow as a "do NOT use" mention, but not as actual usage. Check it's only in the banned context.
  if grep -E '^\s*[A-Z_]+=\$\(date -v' SKILL.md > /dev/null; then
    fail "date -v used as actual command (macOS-only)"
  else
    pass "date -v only mentioned as banned"
  fi
else
  pass "date -v not used"
fi
if grep -qF -- '--since=' SKILL.md; then pass "Portable git --since= flag used"; else fail "Missing portable --since= flag"; fi

echo ""
echo "== Output filename + archive behavior =="
if have "weekly-setup-improvements.md" SKILL.md; then pass "Canonical output filename present"; else fail "Output filename missing"; fi
if have "weekly-setup-improvements-" SKILL.md; then pass "Archive-by-date pattern present"; else fail "Archive-by-date pattern missing"; fi

echo ""
echo "== Sibling skill awareness =="
if have "vault-audit" SKILL.md; then pass "Mentions /vault-audit sibling"; else fail "Missing /vault-audit reference"; fi
if have "claude-md-audit" SKILL.md; then pass "Mentions /claude-md-audit sibling"; else fail "Missing /claude-md-audit reference"; fi

echo ""
echo "== Gotchas =="
if have "## Gotchas" SKILL.md; then pass "Gotchas section present"; else fail "Gotchas section missing"; fi
if have "Do not write a session log" SKILL.md; then pass "Anti-diary rule present"; else fail "Anti-diary rule missing"; fi
if have "more than 3 new skills" SKILL.md; then pass "3-skill cap restated in Gotchas"; else fail "3-skill cap missing from Gotchas"; fi

echo ""
echo "== V3 additions =="
if have "Dominant root cause" SKILL.md; then pass "Dominant root cause invariant present"; else fail "Dominant root cause missing"; fi
if have "_drafts/" SKILL.md; then pass "_drafts/ directory referenced"; else fail "_drafts/ directory missing"; fi
if have "zombie" SKILL.md || have "killed" SKILL.md; then pass "Zombie/kill action rule present"; else fail "Zombie/kill rule missing"; fi
if have "skill-draft-template.md" SKILL.md; then pass "skill-draft-template reference linked"; else fail "skill-draft-template reference missing"; fi
if [ -f references/skill-draft-template.md ]; then pass "references/skill-draft-template.md shipped"; else fail "references/skill-draft-template.md missing"; fi

echo ""
echo "== Frontmatter =="
if have "name: weekly-setup-improvements" SKILL.md; then pass "Skill name in frontmatter"; else fail "Skill name missing"; fi
if have "user-invocable: true" SKILL.md; then pass "user-invocable flag set"; else fail "user-invocable missing"; fi
if have 'argument-hint:' SKILL.md; then pass "argument-hint declared"; else fail "argument-hint missing"; fi

echo ""
echo "== Shipped files =="

echo ""
echo "================================"
echo "PASS: $PASS  FAIL: $FAIL"
echo "================================"
[ $FAIL -eq 0 ] && exit 0 || exit 1
