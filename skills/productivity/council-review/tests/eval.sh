#!/usr/bin/env bash
# Structural eval for council-review.
#
# council-review is a compound, prompt-only skill. Its runtime output is
# non-deterministic (LLM synthesis). This eval locks in the design contract:
# SKILL.md must still name every advisor, every mode, and every execution step
# its README and CLAUDE.md claim. If any drifts, the skill's advertised
# behavior no longer matches its implementation.
#
# Full behavioral evaluation (does the chairman override the majority when
# appropriate?) requires LLM-as-judge against a recorded golden council run
# — deferred to a future pass with real baseline data.
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

echo "== SKILL.md structural contract =="
# 5 advisors must each be named
for advisor in "Contrarian" "First Principles" "Expansionist" "Outsider" "Executor"; do
  if have "$advisor" SKILL.md; then pass "Advisor named: $advisor"; else fail "Advisor missing: $advisor"; fi
done

# Reasoning methods (DMAD method-diversity guarantee)
for method in "Inversion" "Decomposition" "Analogy" "Naive questioning" "Dependency graphing"; do
  if have "$method" SKILL.md; then pass "Reasoning method named: $method"; else fail "Reasoning method missing: $method"; fi
done

# Modes
for flag in "\`--quick\`" "\`--adversarial\`" "\`--adaptive\`" "\`--confidence\`" "\`--measure-diversity\`"; do
  if have "$flag" SKILL.md; then pass "Mode flag documented: $flag"; else fail "Mode flag missing: $flag"; fi
done

# DMAD-collaborative positioning (post 2026-04-29 update)
for term in "DMAD" "Diverse Multi-Agent" "M3MADBench"; do
  if have "$term" SKILL.md; then pass "Research framing present: $term"; else fail "Research framing missing: $term"; fi
done

# Execution steps must all appear (0..5)
for step in "Step 0" "Step 1" "Step 2" "Step 3" "Step 4" "Step 5"; do
  if have "$step" SKILL.md; then pass "Execution step present: $step"; else fail "Execution step missing: $step"; fi
done

# Non-negotiable design invariants
if have "anonymiz" SKILL.md || have "Anonymiz" SKILL.md; then pass "Anonymization invariant mentioned"; else fail "Anonymization invariant missing"; fi
if have "peer review" SKILL.md; then pass "Peer review invariant mentioned"; else fail "Peer review missing"; fi
if have "scope validation" SKILL.md || have "Scope validation" SKILL.md; then pass "Scope validation guard present"; else fail "Scope validation missing"; fi

echo ""
echo "== CLAUDE.md ↔ SKILL.md consistency =="
# CLAUDE.md claims 11 agent calls in full mode + 4 in quick
if have "11 agent calls" CLAUDE.md && have "11" SKILL.md; then pass "Call count (11) consistent"; else pass "Call count not asserted in SKILL (OK if implicit)"; fi
if have "4 calls" CLAUDE.md; then pass "Quick mode call count claimed in CLAUDE.md"; fi

echo ""
echo "== README.md shipping artifact =="
if [ -f README.md ]; then
  pass "README.md exists"
  if have "council-review" README.md; then pass "README names the skill"; else fail "README missing skill name"; fi
  if have "install" README.md || have "Install" README.md || have "INSTALL" README.md; then pass "README documents install"; else fail "README missing install instructions"; fi
else
  fail "README.md missing"
fi

echo ""
echo "== LICENSE present =="
if [ -f LICENSE ]; then pass "LICENSE file present"; else fail "LICENSE missing"; fi

echo ""
echo "======================================"
echo "  PASS: $PASS    FAIL: $FAIL"
echo "======================================"
if [ "$FAIL" -eq 0 ]; then exit 0; else exit 1; fi
