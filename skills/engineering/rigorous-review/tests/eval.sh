#!/usr/bin/env bash
# Structural eval for rigorous-review (V1).
#
# Prompt-only skill; runtime output is non-deterministic. This eval locks in the
# V1 design contract: the two scoring axes (severity × confidence) + the gate with
# the P0-at-50 exception, per-lane threshold asymmetry, do-NOT-flag suppression +
# settled-precedents, cross-reviewer dedup + agreement promotion, the INDEPENDENT
# validator wave (not self-recheck) with degraded-keep, four lanes incl. correctness,
# the API-contract / behavior-preservation check, coverage additions (OWASP-2025,
# SSRF/deserialization, Core Web Vitals, real dead-code tooling), the process layer
# (effort dial, model-tiering), and the load-bearing invariants (prod read-only,
# safe-vs-gated, mandatory secrets scan). Behavioral quality is the next real audit run.
#
# Usage: bash tests/eval.sh — exit 0 on pass, 1 on any failure.

set -u
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
have()  { grep -qiF "$1" SKILL.md; }
haveR() { grep -qiE "$1" SKILL.md; }
haveIn(){ grep -qiF "$2" "$1"; }
pass() { echo "PASS  $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL  $1"; FAIL=$((FAIL+1)); }
chk()  { if have "$2"; then pass "$1"; else fail "$1 (missing: $2)"; fi; }
chkR() { if haveR "$2"; then pass "$1"; else fail "$1 (missing: $2)"; fi; }
chkF() { if [ -f "$1" ] && haveIn "$1" "$2"; then pass "$3"; else fail "$3 (missing in $1: $2)"; fi; }

echo "== Frontmatter =="
haveR '^name: rigorous-review' && pass "name" || fail "name"
haveR '^description:' && pass "description present" || fail "description"
haveR '^allowed-tools:.*Agent' && pass "allowed-tools includes Agent (fan-out + validators)" || fail "Agent tool missing"
haveR 'argument-hint:.*--effort' && pass "effort dial in argument-hint" || fail "effort dial not advertised"

echo "== Identity preserved (behavior-preserving, report-first) =="
chk "no observable change constraint" "no observable change"
chk "byte-for-byte for legitimate callers" "byte-for-byte"
chk "deliverable is a report" "deliverable is a"
chk "production read-only" "Production is read-only"
chk "safe vs gated load-bearing" "load-bearing"
chk "authorization fixes are safe" "Authorization fixes are"

echo "== Two scoring axes + the gate =="
chk "severity axis P0-P3" "P0–P3"
chk "confidence axis anchors" "0/25/50/75/100"
chk "axes are independent" "independent"
chk "suppression gate at 75" "below confidence 75"
chk "P0-at-50 exception" "P0 at confidence ≥50 survives"
chk "per-lane asymmetry: security lower bar" "Security: lower bar"
chk "per-lane asymmetry: performance higher bar" "Performance: higher bar"

echo "== Suppression / precedents (noise control) =="
chk "do-NOT-flag lists referenced" "do-NOT-flag"
chk "settled-precedents table referenced" "settled-precedents"
chk "check callers before flagging" "check callers before flagging"
chkF references/scoring-gating-validation.md "Settled-precedents table" "precedents table in reference"
chkF references/reviewer-lanes.md "do NOT flag" "per-lane suppression lists exist"

echo "== Dedup + agreement promotion (Phase 2) =="
chk "fingerprint dedup" "line_bucket"
chk "agreement promotion on 2+ lanes" "Agreement promotion"

echo "== Independent validator wave (replaces self-recheck) =="
chk "fresh validator per finding" "fresh"
chk "one validator per finding (no batching)" "single batched validator"
chk "no commitment to the finding" "no commitment"
chk "degraded-keep on validator crash" "degraded"
# guard: must NOT revert to orchestrator self-recheck as the validation step
if haveR 'Re-verify the worst findings yourself'; then fail "V1 self-recheck phrasing still present (should be replaced by validator wave)"; else pass "self-recheck replaced by independent wave"; fi

echo "== Four lanes incl. correctness =="
chk "security lane" "Security"
chk "performance lane" "Performance"
chk "refactoring lane" "Refactoring"
chk "correctness lane" "Correctness"
chkF references/reviewer-lanes.md "error-masking fallbacks" "correctness lane detail (error-masking)"
chkF references/reviewer-lanes.md "TOCTOU" "correctness lane detail (TOCTOU)"

echo "== API-contract / behavior preservation (the core-invariant guard) =="
chk "API-contract check present" "API-contract"
chk "additive vs mutative" "additive-vs-mutative"
chk "silent-semantics-change" "silent-semantics-change"
chk "Phase 5 behavior-preservation verifier" "behavior-preservation verifier"
chk "boundary walk stop at first break" "first broken boundary"
chkF references/behavior-preservation.md "Silent-semantics-change" "silent-semantics detail in reference"
chkF references/behavior-preservation.md "boundary-walk verifier" "boundary-walk verifier in reference"

echo "== Coverage expansion =="
chk "mandatory secrets scan retained" "secrets scan"
chkF references/reviewer-lanes.md "SSRF" "security: SSRF"
chkF references/reviewer-lanes.md "deserialization" "security: insecure deserialization"
chkF references/reviewer-lanes.md "OWASP Top 10:2025" "security: OWASP-2025 tagging"
chkF references/reviewer-lanes.md "Core Web Vitals" "perf: Core Web Vitals"
chkF references/reviewer-lanes.md "serverless" "perf: serverless traps"
chkF references/reviewer-lanes.md "knip" "refactor: real dead-code tooling"
chkF references/reviewer-lanes.md "Fowler" "refactor: Fowler smell taxonomy"
chkF references/reviewer-lanes.md "two-adapter seam" "refactor: two-adapter seam rule"

echo "== Process layer =="
chk "effort dial low/medium high-confidence" "high-confidence only"
chk "effort dial high/max broader recall" "widen recall"
chk "model-tiering assignment" "model tiers"
chkF references/scoring-gating-validation.md "Model-tiering" "model-tiering detail in reference"

echo "== Phases (0..5) =="
for p in "Phase 0" "Phase 1" "Phase 2" "Phase 3" "Phase 4" "Phase 5"; do chk "$p present" "$p"; done
# fan-out (Phase 1) precedes validation (Phase 3)
F=$(grep -n "Fan out four parallel reviewers" SKILL.md | head -1 | cut -d: -f1)
V=$(grep -n "Independent validator wave" SKILL.md | head -1 | cut -d: -f1)
if [ -n "$F" ] && [ -n "$V" ] && [ "$F" -lt "$V" ]; then pass "fan-out precedes validation"; else fail "phase ordering (fan-out before validation)"; fi

echo "== Convention =="
chk "Gotchas heading" "## Gotchas"
chk "Changelog present" "## Changelog"
chkR "V1 changelog entry" '### V1'
chk "References section" "## References"
for f in references/reviewer-lanes.md references/scoring-gating-validation.md references/behavior-preservation.md; do
  [ -f "$f" ] && pass "ref exists: $f" || fail "ref missing: $f"
done
[ ! -f README.md ] && pass "no root README (house convention: SKILL.md + tests/)" || fail "root README.md present (siblings ship none)"
[ -f tests/README.md ] && pass "tests/README.md present (eval docs, sibling format)" || fail "tests/README.md missing"
LINES=$(wc -l < SKILL.md | tr -d ' ')
[ "$LINES" -le 500 ] && pass "SKILL.md $LINES lines (<=500)" || fail "SKILL.md $LINES lines (>500)"

echo ""
echo "======================================"
echo "  PASS: $PASS    FAIL: $FAIL"
echo "======================================"
[ "$FAIL" -eq 0 ]
