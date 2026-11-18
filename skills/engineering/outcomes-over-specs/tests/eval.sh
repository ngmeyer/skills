#!/usr/bin/env bash
# Structural eval for outcomes-over-specs (v1.1).
#
# Prompt-only skill; runtime output is non-deterministic. This eval locks in the
# design contract: MANDATORY independence (separate test-author + implementer, the
# implementer never edits the gate), the two modes (greenfield acceptance vs
# brownfield characterize-first), the human approval gate, behavior-not-coverage,
# quarantine-not-retry, the pyramid altitude, self-containment, and Gotchas.
# Behavioral quality is verified by the iterate-then-extract pilot in the changelog.
#
# Usage: bash tests/eval.sh — exit 0 on pass, 1 on any failure.

set -u
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
have() { grep -qiF "$1" SKILL.md; }
haveR() { grep -qiE "$1" SKILL.md; }
pass() { echo "PASS  $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL  $1"; FAIL=$((FAIL+1)); }
chk() { if have "$2"; then pass "$1"; else fail "$1 (missing: $2)"; fi; }

echo "== Frontmatter =="
haveR '^name: outcomes-over-specs' && pass "name" || fail "name"
haveR '^description:' && pass "description present" || fail "description"
haveR '^allowed-tools:.*Task' && pass "allowed-tools includes Task (subagents)" || fail "Task tool missing (needed to spawn independent agents)"

echo "== Mandatory independence (the core invariant) =="
chk "implementer never edits the gate" "never writes or edits the test gate"
chk "non-negotiable invariant section" "non-negotiable invariant"
chk "separate test-author vs implementer" "test-author"
chk "names self-agreement failure" "agree"
chk "independence check diffs test files" "diff the test files"
# guard: independence must NOT be presented as opt-in
if grep -qiE '\-\-(solo|independent)\b' SKILL.md; then fail "independence appears optional (--solo/--independent flag present)"; else pass "independence is not an opt-in flag"; fi

echo "== Human approval gate =="
chk "Phase 0 approves the outcome" "approve the outcome"
chk "stop for approval before code" "before any test or code"

echo "== Two modes =="
chk "greenfield mode" "greenfield"
chk "brownfield mode" "brownfield"
chk "characterize before touching" "characterize"
chk "Chesterton's Fence / missing why" "Chesterton"
chk "every flip labeled (no silent regression)" "labeled"

echo "== Phases (0..4) =="
for p in "Phase 0" "Phase 1" "Phase 2" "Phase 3" "Phase 4"; do chk "$p present" "$p"; done
# author precedes implementer in the file
A=$(grep -n "Independent test-author" SKILL.md | head -1 | cut -d: -f1)
I=$(grep -n "Independent implementer" SKILL.md | head -1 | cut -d: -f1)
if [ -n "$A" ] && [ -n "$I" ] && [ "$A" -lt "$I" ]; then pass "test-author precedes implementer"; else fail "author/implementer ordering"; fi

echo "== Google guardrails =="
chk "size vs scope" "size"
chk "pyramid ratio" "80/15/5"
chk "ice-cream cone anti-pattern" "ice-cream cone"
chk "hermetic" "hermetic"
chk "quarantine-not-retry" "retry-until-green"
chk "mutation over coverage" "mutation"
chk "coverage != behavior" "Coverage is not behavior"

echo "== Scope discipline =="
chk "when NOT to use" "When NOT to use"

echo "== Self-containment (CE optional) =="
chk "composes-with-CE section" "Composing with Compound Engineering"
have "not required" && pass "CE marked optional" || fail "CE optionality"
if grep -qE 'allowed-tools.*ce-' SKILL.md; then fail "allowed-tools hard-depends on CE"; else pass "no hard CE dependency in allowed-tools"; fi

echo "== Convention =="
chk "Gotchas heading" "## Gotchas"
chk "Changelog present" "## Changelog"
chk "References to playbook" "google-testing-playbook.md"
[ -f references/google-testing-playbook.md ] && pass "playbook file exists" || fail "playbook file missing"
if have "What NOT to Do"; then fail "stale 'What NOT to Do' heading"; else pass "no 'What NOT to Do' heading"; fi
LINES=$(wc -l < SKILL.md | tr -d ' ')
[ "$LINES" -le 500 ] && pass "SKILL.md $LINES lines (<=500)" || fail "SKILL.md $LINES lines (>500)"

echo ""
echo "======================================"
echo "  PASS: $PASS    FAIL: $FAIL"
echo "======================================"
[ "$FAIL" -eq 0 ]
