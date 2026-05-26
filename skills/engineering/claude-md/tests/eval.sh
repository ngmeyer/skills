#!/usr/bin/env bash
# Structural eval for claude-md (merged audit + improve).
#
# Asserts BOTH modes' design contracts: improve mode (5 phases, 10-rule
# rubric, 5 canonical sections, surgical-Edit invariant) and audit mode
# (7 phases, secret-scan-first invariant, drift-detection categories,
# instruction-budget classifier, never-auto-apply-leaks invariant).
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

echo "== Mode dispatch =="
if have "Mode Dispatch" SKILL.md; then pass "Mode Dispatch section present"; else fail "Mode Dispatch section missing"; fi
for mode in "improve" "audit"; do
  if have "/claude-md $mode" SKILL.md; then pass "Mode invocation documented: $mode"; else fail "Mode invocation missing: $mode"; fi
done

echo ""
echo "== Improve Mode: 5 phases =="
for phase in "Phase I-1: SCOPE" "Phase I-2: MEASURE" "Phase I-3: PROPOSE" "Phase I-4: PRESENT" "Phase I-5: APPLY"; do
  if have "$phase" SKILL.md; then pass "Improve phase: $phase"; else fail "Improve phase missing: $phase"; fi
done

echo ""
echo "== Improve Mode: 10-rule rubric =="
for rule in "R1" "R2" "R3" "R4" "R5" "R6" "R7" "R8" "R9" "R10"; do
  if have "| $rule " SKILL.md || have " $rule " SKILL.md; then pass "Rubric rule present: $rule"; else fail "Rubric rule missing: $rule"; fi
done

echo ""
echo "== Improve Mode: 5 canonical sections =="
for section in "Project" "Stack" "Commands" "Architecture" "Rules" "Workflow" "Out of scope"; do
  if have "## $section" SKILL.md || have "\`## $section" SKILL.md; then pass "Canonical section: $section"; else fail "Canonical section missing: $section"; fi
done

echo ""
echo "== Audit Mode: 7 phases =="
for phase in "Phase A-1: DISCOVER" "Phase A-2: SECRET SCAN" "Phase A-3: DRIFT DETECTION" "Phase A-4: DUPLICATE" "Phase A-5: INSTRUCTION BUDGET" "Phase A-6: REPORT" "Phase A-7: OFFER FIXES"; do
  if have "$phase" SKILL.md; then pass "Audit phase: $phase"; else fail "Audit phase missing: $phase"; fi
done

echo ""
echo "== Audit Mode: secret patterns =="
for pattern in "AUTH_SECRET" "sk_live_" "sk-ant-" "postgres" "JWT"; do
  if have "$pattern" SKILL.md; then pass "Secret pattern: $pattern"; else fail "Secret pattern missing: $pattern"; fi
done

echo ""
echo "== Audit Mode: drift categories =="
for cat in "MCP servers" "API routes" "Cron jobs" "Env vars" "External services" "Directory structure"; do
  if have "$cat" SKILL.md; then pass "Drift category: $cat"; else fail "Drift category missing: $cat"; fi
done

echo ""
echo "== Anthropic primary sources cited =="
for src in "code.claude.com/docs/en/memory" "code.claude.com/docs/en/best-practices"; do
  if have "$src" SKILL.md; then pass "Anthropic source cited: $src"; else fail "Anthropic source missing: $src"; fi
done

echo ""
echo "== Removability test (universal pruning rule) =="
if have "removability test" SKILL.md || have "if I removed this" SKILL.md; then pass "Removability test cited"; else fail "Removability test missing"; fi

echo ""
echo "== Strunk lineage (improve mode) =="
if have "Strunk" SKILL.md; then pass "Strunk lineage cited"; else fail "Strunk lineage missing"; fi

echo ""
echo "== Anti-auto-apply invariants =="
if have "Do not auto-apply" SKILL.md || have "Surgical Edits only" SKILL.md; then pass "Auto-apply invariant present"; else fail "Auto-apply invariant missing"; fi
if have "Do not rotate secrets" SKILL.md || have "rotation" SKILL.md; then pass "Leak-rotation-by-user invariant present"; else fail "Leak-rotation invariant missing"; fi

echo ""
echo "== Anti-pattern list (improve) =="
for anti in "Personality instructions" "auto memory will capture" "Duplicate rules"; do
  if have "$anti" SKILL.md; then pass "Anti-pattern listed: $anti"; else fail "Anti-pattern missing: $anti"; fi
done

echo ""
echo "== Quality bar =="
if have "Quality Bar" SKILL.md; then pass "Quality Bar section present"; else fail "Quality Bar section missing"; fi
for hedge in "consider" "perhaps" "you might want to"; do
  if have "$hedge" SKILL.md; then pass "Hedge banned: $hedge"; else fail "Hedge ban missing: $hedge"; fi
done

echo ""
echo "== Sibling-skill awareness =="
if have "ce-compound-refresh" SKILL.md; then pass "Sibling /ce-compound-refresh referenced"; else fail "Sibling /ce-compound-refresh missing"; fi
if have "/init" SKILL.md; then pass "Sibling /init referenced"; else fail "Sibling /init missing"; fi

echo ""
echo "== Portability rules =="
if grep -qE "/Users/[a-z]" SKILL.md; then fail "Hardcoded /Users/ path leaked"; else pass "No /Users/ hardcoded paths"; fi
if grep -qE "/home/[a-z]" SKILL.md; then fail "Hardcoded /home/ path leaked"; else pass "No /home/ hardcoded paths"; fi

echo ""
echo "== Frontmatter =="
if have "name: claude-md" SKILL.md; then pass "Skill name in frontmatter"; else fail "Skill name missing"; fi
if have "user-invocable: true" SKILL.md; then pass "user-invocable flag set"; else fail "user-invocable missing"; fi
if have "argument-hint:" SKILL.md; then pass "argument-hint declared"; else fail "argument-hint missing"; fi

echo ""
echo "== Shipped files =="
[ -f README.md ] && pass "README.md shipped" || fail "README.md missing"
[ -f LICENSE ] && pass "LICENSE shipped" || fail "LICENSE missing"
[ -f CLAUDE.md ] && pass "CLAUDE.md shipped" || fail "CLAUDE.md missing"

echo ""
echo "================================"
echo "PASS: $PASS  FAIL: $FAIL"
echo "================================"
[ $FAIL -eq 0 ] && exit 0 || exit 1
