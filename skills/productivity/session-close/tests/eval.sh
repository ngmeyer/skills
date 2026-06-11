#!/usr/bin/env bash
# Structural eval for session-close.
#
# session-close is a compound skill that writes to user memory files. A full
# behavioral eval requires (a) a fixture session transcript + (b) a recorded
# expected diff of the memory file. That's a moderate-effort fixture to build,
# deferred to a follow-up pass.
#
# This eval locks in the CLAUDE.md design contract: 7 phases, three-gate
# filter, REPLACE/MERGE-LIST/PRESERVE strategies, portability rules, and the
# "state reconciliation not session logging" core principle.
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

echo "== 8-Phase architecture (incl. CLAUDE.md audit handoff) =="
for phase in "Phase 1: IDENTIFY" "Phase 2: READ" "Phase 3: EXTRACT" "Phase 4: RECONCILE" "Phase 5: PRESENT" "Phase 6: INDEX" "Phase 7: CLAUDE.md AUDIT" "Phase 8: CLEANUP"; do
  if have "$phase" SKILL.md; then pass "Phase present: $phase"; else fail "Phase missing: $phase"; fi
done

echo ""
echo "== Three-gate filter (quality mechanism) =="
# SKILL.md uses UPPERCASE (DURABILITY), CLAUDE.md uses Title Case — accept either
for gate in "Durability" "Specificity" "Retrieval"; do
  if grep -qFi "$gate" SKILL.md; then pass "Gate named: $gate"; else fail "Gate missing: $gate"; fi
done

echo ""
echo "== Section-aware merge strategies =="
for strategy in "REPLACE" "MERGE-LIST" "PRESERVE"; do
  if have "$strategy" SKILL.md; then pass "Merge strategy named: $strategy"; else fail "Merge strategy missing: $strategy"; fi
done

echo ""
echo "== Core principle + anti-pattern =="
if have "state reconciliation" SKILL.md || have "State reconciliation" SKILL.md; then pass "Core principle 'state reconciliation' named"; else fail "Core principle missing"; fi
if have "session logging" SKILL.md || have "session dump" SKILL.md; then pass "Anti-pattern named"; else fail "Anti-pattern missing"; fi
if grep -qFi "approval" SKILL.md && grep -qFi "diff" SKILL.md; then pass "Approval-before-write invariant present"; else fail "Approval invariant missing"; fi

echo ""
echo "== Portability (CLAUDE.md claims no hardcoded user paths) =="
# Hardcoded user paths = /Users/<name>/ or /home/<name>/ as actual directives
# (in commands or path literals), not in doc examples showing *how* escaping works.
# Exclude lines that are clearly examples: "e.g.", parenthetical, or preceded by "example"/"such as".
check_hardcoded() {
  local pattern="$1" label="$2"
  # Flag real usage; tolerate doc examples explicitly marked with "e.g." on the same line
  if grep -nE "$pattern" SKILL.md | grep -vE '(e\.g\.|example|such as|becomes `)' | grep -q .; then
    fail "Hardcoded $label path found in SKILL.md (actual usage, not a doc example)"
  else
    pass "No hardcoded $label paths outside doc examples"
  fi
}
check_hardcoded '/Users/[a-z]+/' '/Users/<name>/'
check_hardcoded '/home/[a-z]+/' '/home/<name>/'
# Dynamic path reference must be present
if have "~/.claude/projects" SKILL.md; then pass "Dynamic memory path pattern documented"; else fail "Dynamic memory path not documented"; fi

echo ""
echo "== Cross-platform git flags (no macOS-only date -v) =="
if grep -qE 'date -v' SKILL.md; then
  fail "macOS-only 'date -v' flag found in SKILL.md (breaks on Linux)"
else
  pass "No macOS-only 'date -v' flag"
fi
if grep -qF -- '--since=' SKILL.md; then pass "Portable --since= git flag used"; else fail "Portable --since= not used"; fi

echo ""
echo "== CLAUDE.md audit handoff (Phase 7, V2.1) =="
if have "claude-md" SKILL.md; then pass "delegates to the claude-md skill"; else fail "claude-md handoff missing"; fi
if grep -qiF "soft dependency" SKILL.md; then pass "claude-md is a soft dependency (self-contained without it)"; else fail "soft-dependency framing missing"; fi
if grep -qF "/init" SKILL.md && grep -qiF "regenerat" SKILL.md; then pass "anti-/init regeneration rule present"; else fail "anti-/init rule missing"; fi
if have "AGENTS.md" SKILL.md; then pass "cross-agent layer (AGENTS.md) named"; else fail "AGENTS.md not named"; fi

echo ""
echo "== Event classification =="
for type in "DECISION" "STATUS_CHANGE" "DISCOVERY"; do
  if have "$type" SKILL.md; then pass "Event type classified: $type"; else fail "Event type missing: $type"; fi
done

echo ""
echo "== Fixture validity =="
if [ -f tests/fixtures/memory/project_demo.md ] && have "Backlog" tests/fixtures/memory/project_demo.md && have "Status" tests/fixtures/memory/project_demo.md; then
  pass "Fixture memory file exists and has Status + Backlog sections"
else
  fail "Fixture memory file missing or malformed"
fi

echo ""

echo ""
echo "======================================"
echo "  PASS: $PASS    FAIL: $FAIL"
echo "======================================"
if [ "$FAIL" -eq 0 ]; then exit 0; else exit 1; fi
