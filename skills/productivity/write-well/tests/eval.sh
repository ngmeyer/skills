#!/usr/bin/env bash
# Structural eval for write-well (V2).
#
# Prompt-only skill; runtime output is non-deterministic. This eval locks in the
# design contract: the five-part core, the Voices & Personas system (3 controls +
# 6-axis fingerprint + the two failure-mode guards), the craft canon (the positive
# rules + the rules-as-defaults meta-rule, and the explicit refusal to import the
# grammar superstitions), self-containment (no personal-project coupling), and the
# reference files. Writing quality is verified by a blind voice A/B, not here.
#
# Usage: bash tests/eval.sh — exit 0 on pass, 1 on any failure.

set -u
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
have() { grep -qiF -- "$1" SKILL.md; }
haveR() { grep -qiE -- "$1" SKILL.md; }
pass() { echo "PASS  $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL  $1"; FAIL=$((FAIL+1)); }
chk() { if have "$2"; then pass "$1"; else fail "$1 (missing: $2)"; fi; }

echo "== Frontmatter =="
haveR '^name: write-well' && pass "name" || fail "name"
haveR '^description:' && pass "description" || fail "description"
haveR '^argument-hint:.*--voice' && pass "argument-hint advertises voices" || fail "argument-hint missing --voice"

echo "== The five-part core =="
for c in "Voice" "VAKS" "Rhythm" "Specific over abstract" "Story-first"; do chk "core: $c" "$c"; done

echo "== Voices & personas system =="
chk "--voice control" "--voice"
chk "--persona control" "--persona"
chk "--like (clone) control" "--like"
chk "6-axis fingerprint" "6-axis fingerprint"
chk "failure mode: regression to generic" "Regression to generic"
chk "failure mode: caricature" "aricature"
chk "voices.md reference" "references/voices.md"
[ -f references/voices.md ] && pass "voices.md exists" || fail "voices.md missing"
grep -qiF "Hemingway" references/voices.md && grep -qiF "fingerprint" references/voices.md && pass "voices.md has the library + fingerprint model" || fail "voices.md incomplete"

echo "== The craft canon =="
chk "characters as subjects / nominalizations" "nominalization"
chk "cohesion old->new" "open with old"
chk "Paramedic Method" "Paramedic Method"
chk "classic style (Pinker)" "Classic style"
chk "curse of knowledge" "curse of knowledge"
chk "rules-as-defaults meta-rule" "defaults with reasons, not commandments"
chk "craft-canon.md reference" "references/craft-canon.md"
[ -f references/craft-canon.md ] && pass "craft-canon.md exists" || fail "craft-canon.md missing"
# the load-bearing refusal: do NOT import the grammar superstitions
grep -qiF "Do NOT import" references/craft-canon.md && pass "refuses the grammar superstitions" || fail "missing the no-superstition guard"

echo "== Self-containment (no personal-project coupling) =="
LEAK=0
for term in Threshold OurGospelStudy PithyByte GEARU SignUpSpark Voltron LocalCred VeroWrite; do
  if grep -rqiF "$term" SKILL.md references/ 2>/dev/null; then echo "  leak: $term"; LEAK=1; fi
done
[ "$LEAK" -eq 0 ] && pass "no personal-project names in skill or references" || fail "personal-project coupling present"

echo "== Convention =="
chk "Gotchas heading" "## Gotchas"
chk "Changelog present" "## Changelog"
if have "What NOT to Do"; then fail "stale 'What NOT to Do' heading"; else pass "no 'What NOT to Do' heading"; fi
LINES=$(wc -l < SKILL.md | tr -d ' ')
[ "$LINES" -le 500 ] && pass "SKILL.md $LINES lines (<=500)" || fail "SKILL.md $LINES lines (>500)"

echo ""
echo "======================================"
echo "  PASS: $PASS    FAIL: $FAIL"
echo "======================================"
[ "$FAIL" -eq 0 ]
