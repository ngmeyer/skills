#!/usr/bin/env bash
# Structural eval for claude-md (merged audit + improve).
#
# Asserts BOTH modes' design contracts: improve mode (5 phases, 10-rule
# rubric, 5 canonical sections, surgical-Edit invariant) and audit mode
# (7 phases, secret-scan-first invariant, drift-detection categories,
# instruction-budget classifier, never-auto-apply-leaks invariant).
#
# The unit under test is THE SKILL, not one file. `have` searches SKILL.md plus
# references/; `in_map` pins the things that must be in the always-loaded body
# (dispatch, phase list, invariants, budgets). An earlier version asserted
# everything against SKILL.md alone, which made progressive disclosure -- the
# thing this repo's lint and Anthropic's own guidance both require -- impossible
# without failing the eval.
#
# Usage: bash tests/eval.sh
# Exit 0 on pass, 1 on any assertion failure.

set -u
cd "$(dirname "$0")/.."

PASS=0
FAIL=0
pass() { echo "PASS  $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL  $1"; FAIL=$((FAIL+1)); }

SKILL_FILES=(SKILL.md)
for f in references/*.md; do [ -f "$f" ] && SKILL_FILES+=("$f"); done

have()   { grep -qF -- "$1" "${SKILL_FILES[@]}"; }
in_map() { grep -qF -- "$1" SKILL.md; }

echo "== Mode dispatch (must be in the map) =="
if in_map "Mode Dispatch"; then pass "Mode Dispatch section present"; else fail "Mode Dispatch section missing"; fi
for mode in "improve" "audit"; do
  if in_map "/claude-md $mode"; then pass "Mode invocation documented: $mode"; else fail "Mode invocation missing: $mode"; fi
done

echo ""
echo "== Improve Mode: 5 phases (must be in the map) =="
for phase in "Phase I-1: SCOPE" "Phase I-2: MEASURE" "Phase I-3: PROPOSE" "Phase I-4: PRESENT" "Phase I-5: APPLY"; do
  if in_map "$phase"; then pass "Improve phase: $phase"; else fail "Improve phase missing: $phase"; fi
done

echo ""
echo "== Improve Mode: 10-rule rubric =="
for rule in "R1" "R2" "R3" "R4" "R5" "R6" "R7" "R8" "R9" "R10"; do
  if have "| $rule " || have " $rule "; then pass "Rubric rule present: $rule"; else fail "Rubric rule missing: $rule"; fi
done

echo ""
echo "== Improve Mode: 5 canonical sections =="
for section in "Project" "Stack" "Commands" "Architecture" "Rules" "Workflow" "Out of scope"; do
  if have "## $section" || have "\`## $section"; then pass "Canonical section: $section"; else fail "Canonical section missing: $section"; fi
done

echo ""
echo "== Audit Mode: 7 phases (must be in the map) =="
for phase in "Phase A-1: DISCOVER" "Phase A-2: SECRET SCAN" "Phase A-3: DRIFT DETECTION" "Phase A-4: DUPLICATE" "Phase A-5: INSTRUCTION BUDGET" "Phase A-6: REPORT" "Phase A-7: OFFER FIXES"; do
  if in_map "$phase"; then pass "Audit phase: $phase"; else fail "Audit phase missing: $phase"; fi
done

echo ""
echo "== Audit Mode: secret patterns =="
for pattern in "AUTH_SECRET" "sk_live_" "sk-ant-" "postgres" "JWT"; do
  if have "$pattern"; then pass "Secret pattern: $pattern"; else fail "Secret pattern missing: $pattern"; fi
done

echo ""
echo "== Audit Mode: drift categories =="
for cat in "MCP servers" "API routes" "Cron jobs" "Env vars" "External services" "Directory structure"; do
  if have "$cat"; then pass "Drift category: $cat"; else fail "Drift category missing: $cat"; fi
done

echo ""
echo "== Anthropic primary sources cited =="
for src in "code.claude.com/docs/en/memory" "code.claude.com/docs/en/best-practices"; do
  if have "$src"; then pass "Anthropic source cited: $src"; else fail "Anthropic source missing: $src"; fi
done

echo ""
echo "== Removability test (universal pruning rule) =="
if in_map "removability test" || in_map "if I removed this"; then pass "Removability test cited in map"; else fail "Removability test missing from map"; fi

echo ""
echo "== Strunk lineage (improve mode) =="
if have "Strunk"; then pass "Strunk lineage cited"; else fail "Strunk lineage missing"; fi

echo ""
echo "== Anti-auto-apply invariants (must be in the map) =="
if in_map "Do not auto-apply" || in_map "Surgical Edits only"; then pass "Auto-apply invariant present"; else fail "Auto-apply invariant missing"; fi
if in_map "Do not rotate secrets" || in_map "rotation"; then pass "Leak-rotation-by-user invariant present"; else fail "Leak-rotation invariant missing"; fi
if in_map "Do NOT apply P0 LEAK fixes automatically"; then pass "P0 leaks never auto-applied"; else fail "P0 auto-apply guard missing"; fi

echo ""
echo "== Anti-pattern list (improve) =="
for anti in "Personality instructions" "auto memory will capture" "Duplicate rules"; do
  if have "$anti"; then pass "Anti-pattern listed: $anti"; else fail "Anti-pattern missing: $anti"; fi
done

echo ""
echo "== Quality bar (must be in the map) =="
if in_map "Quality Bar"; then pass "Quality Bar section present"; else fail "Quality Bar section missing"; fi
for hedge in "consider" "perhaps" "you might want to"; do
  if in_map "$hedge"; then pass "Hedge banned: $hedge"; else fail "Hedge ban missing: $hedge"; fi
done

echo ""
echo "== Budget is defined once =="
if in_map "Budgets (one definition"; then pass "Budgets section present in map"; else fail "Budgets section missing"; fi
# The line budget may be stated once, in the Budgets table. A second bare "200-line"
# claim elsewhere is the drift this section exists to prevent.
n=$(grep -cE '^\| \*\*Line budget\*\*' SKILL.md)
if [ "$n" = 1 ]; then pass "line budget declared exactly once"; else fail "line budget declared $n times"; fi
if grep -qF "openai.com/index/harness-engineering" SKILL.md; then pass "alternative budget figure is sourced"; else fail "unsourced alternative budget"; fi

echo ""
echo "== Sibling-skill awareness =="
if in_map "ce-compound-refresh"; then pass "Sibling /ce-compound-refresh referenced"; else fail "Sibling /ce-compound-refresh missing"; fi
if in_map "/init"; then pass "Sibling /init referenced"; else fail "Sibling /init missing"; fi

echo ""
echo "== Progressive disclosure =="
for ref in references/rubric.md references/high-impact-lines.md references/audit-checks.md references/report-templates.md references/sources.md; do
  if [ -f "$ref" ]; then pass "reference exists: $ref"; else fail "reference missing: $ref"; fi
  if in_map "$ref"; then pass "map links $ref"; else fail "map does not link $ref"; fi
done
# Anthropic: "Keep references one level deep from SKILL.md" -- a reference that points at
# another reference gets partially read.
nested=$(grep -lE 'references/[A-Za-z0-9_-]+\.md' references/*.md 2>/dev/null)
if [ -n "$nested" ]; then fail "nested reference link in: $nested (must be one level deep)"; else pass "references are one level deep"; fi
if grep -qE '^## Changelog' SKILL.md; then fail "## Changelog in always-loaded body"; else pass "changelog kept out of SKILL.md"; fi
if [ -f CHANGELOG.md ]; then pass "CHANGELOG.md exists"; else fail "CHANGELOG.md missing"; fi
L=$(wc -l < SKILL.md)
if [ "$L" -le 250 ]; then pass "SKILL.md $L lines (within repo limit)"; else fail "SKILL.md $L lines > 250"; fi

echo ""
echo "== Portability rules =="
if grep -qE "/Users/[a-z]" "${SKILL_FILES[@]}"; then fail "Hardcoded /Users/ path leaked"; else pass "No /Users/ hardcoded paths"; fi
if grep -qE "/home/[a-z]" "${SKILL_FILES[@]}"; then fail "Hardcoded /home/ path leaked"; else pass "No /home/ hardcoded paths"; fi

echo ""
echo "== Frontmatter =="
if in_map "name: claude-md"; then pass "Skill name in frontmatter"; else fail "Skill name missing"; fi
if in_map "user-invocable: true"; then pass "user-invocable flag set"; else fail "user-invocable missing"; fi
if in_map "argument-hint:"; then pass "argument-hint declared"; else fail "argument-hint missing"; fi
if in_map "owner:"; then pass "metadata.owner declared"; else fail "metadata.owner missing"; fi
if in_map "AGENTS.md"; then pass "AGENTS.md scope in description/body"; else fail "AGENTS.md scope missing"; fi

echo ""
echo "================================"
echo "PASS: $PASS  FAIL: $FAIL"
echo "================================"
[ $FAIL -eq 0 ] && exit 0 || exit 1
