#!/usr/bin/env bash
# Structural eval for session-close.
#
# session-close is a compound skill that writes to user memory files. A full
# behavioral eval requires (a) a fixture session transcript + (b) a recorded
# expected diff of the memory file. That's a moderate-effort fixture to build,
# deferred to a follow-up pass.
#
# This eval locks in the design contract: 9 phases, three-gate filter,
# REPLACE/MERGE-LIST/PRESERVE strategies, portability rules, the "state
# reconciliation not session logging" core principle, and (V3) the AAR:
# four questions, DEAD_END capture, the four-check promotion gate, and the
# PROCESS:/DEAD-END: closure loop.
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

echo "== 9-Phase architecture (incl. AAR + CLAUDE.md audit handoff) =="
for phase in "Phase 1: IDENTIFY" "Phase 2: READ" "Phase 3: EXTRACT" "Phase 4: AAR" "Phase 5: RECONCILE" "Phase 6: PRESENT" "Phase 7: INDEX" "Phase 8: CLAUDE.md AUDIT" "Phase 9: CLEANUP"; do
  if have "$phase" SKILL.md; then pass "Phase present: $phase"; else fail "Phase missing: $phase"; fi
done
# Renumbering regression: no stale cross-reference to the V2.1 numbering
if grep -nF "Phase 7" SKILL.md | grep -vE '(INDEX|### V2\.1|Added \*\*Phase 7)' | grep -q .; then
  fail "Stale 'Phase 7' cross-reference outside INDEX / V2.1 changelog"
else
  pass "No stale phase cross-references after renumbering"
fi

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
for type in "DECISION" "STATUS_CHANGE" "DISCOVERY" "DEAD_END"; do
  if have "$type" SKILL.md; then pass "Event type classified: $type"; else fail "Event type missing: $type"; fi
done

echo ""
echo "== AAR: four questions (V3) =="
for q in "What was supposed to happen" "What actually happened" "Why the difference" "Sustain / Improve"; do
  if grep -qiF "$q" SKILL.md; then pass "AAR question present: $q"; else fail "AAR question missing: $q"; fi
done
# The delta is the point: Q3 must demand a mechanism, not a culprit
if grep -qiF "mechanism" SKILL.md && grep -qiF "never the actor" SKILL.md; then
  pass "Blameless framing: names mechanism, not actor"
else
  fail "Blameless framing missing (mechanism / never the actor)"
fi

echo ""
echo "== AAR: bounded output (anti-theater) =="
if grep -qiE "at most 3|max(imum)? 3|0-3" SKILL.md; then pass "Improve items capped"; else fail "Improve item cap missing"; fi
if grep -qiF "zero" SKILL.md && grep -qiF "valid" SKILL.md; then pass "Zero-is-valid stated"; else fail "Zero-is-valid outcome missing"; fi
if grep -qiF "theater" SKILL.md; then pass "AAR-theater anti-pattern named"; else fail "AAR-theater anti-pattern missing"; fi

echo ""
echo "== AAR: promotion gate (anti-bloat) =="
# All four checks must be named -- an ungated promotion path bloats CLAUDE.md,
# which the research shows measurably degrades agent success.
for check in "Behavior-changing" "Recurrent or costly" "Not already covered" "Stated as a rule"; do
  if have "$check" SKILL.md; then pass "Gate check present: $check"; else fail "Gate check missing: $check"; fi
done
if grep -qiE "merge, don't append|merged into the existing" SKILL.md; then
  pass "Merge-not-append rule present"
else
  fail "Merge-not-append rule missing"
fi

echo ""
echo "== AAR: closure loop (cross-session state) =="
for tag in "PROCESS:" "DEAD-END:"; do
  if have "$tag" SKILL.md; then pass "Backlog tag defined: $tag"; else fail "Backlog tag missing: $tag"; fi
done
if grep -qiF "carry forward" SKILL.md || grep -qiF "carry-forward" SKILL.md; then
  pass "Phase 2 carry-forward present (AAR has cross-session memory)"
else
  fail "Carry-forward missing -- AAR would repeat itself every session"
fi
for mech in "Recurred" "Resolved" "Zombie"; do
  if have "$mech" SKILL.md; then pass "Closure outcome defined: $mech"; else fail "Closure outcome missing: $mech"; fi
done
# Nothing may vanish silently
if grep -qiF "not discarded" SKILL.md || grep -qiF "never just disappears" SKILL.md; then
  pass "Failed-gate items are retained, not silently dropped"
else
  fail "Silent-discard guard missing"
fi

echo ""
echo "== AAR: per-project scope (found in V3 validation) =="
if grep -qiF "one AAR per project" SKILL.md; then
  pass "AAR runs per project, not per session"
else
  fail "Per-project AAR scope missing (multi-repo sessions would blur deltas)"
fi

echo ""
echo "== Progressive disclosure =="
if [ -f references/aar-playbook.md ]; then pass "AAR playbook reference exists"; else fail "references/aar-playbook.md missing"; fi
if have "references/aar-playbook.md" SKILL.md; then pass "SKILL.md links the playbook"; else fail "Playbook not linked from SKILL.md"; fi
# Anthropic's public bar is 500 lines
SKILL_LINES=$(wc -l < SKILL.md)
if [ "$SKILL_LINES" -le 500 ]; then pass "SKILL.md within 500-line budget ($SKILL_LINES)"; else fail "SKILL.md over budget ($SKILL_LINES lines)"; fi

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
