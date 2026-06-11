#!/usr/bin/env bash
# Structural eval for write-well (1.0).
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

echo "== V2.1: register-first + register voices + tightened defaults =="
chk "register-first section" "Register & tone"
chk "punchy closer named as a tell" "own AI tell"
chk "em-dashes near-zero (not budget)" "near-zero"
chk "set the register before the punch (gotcha)" "before the punch"
grep -qiF "warm-feedback" references/voices.md && grep -qiF "plain-professional" references/voices.md && pass "register voices (warm-feedback, plain-professional, ...) present" || fail "register voices missing from voices.md"
grep -qiF "never end on a punchy" references/voices.md && pass "feedback voice forbids the zinger closer" || fail "feedback voice missing the no-closer rule"

echo "== V2.2: Ogilvy incorporated (canon + edit-process + register + author voice) =="
chk "Ogilvy in SKILL voice library + changelog" "Ogilvy"
chk "edit-mode cooling-off step" "Cool off and check facts"
grep -qiF "David Ogilvy" references/voices.md && pass "voices.md has the Ogilvy author voice" || fail "voices.md missing Ogilvy author voice"
grep -qiF "cooling-off pass" references/craft-canon.md && pass "craft-canon has the cooling-off pass" || fail "craft-canon missing cooling-off pass"
grep -qiF "Check your quotations" references/craft-canon.md && pass "cooling-off: check your quotations" || fail "cooling-off missing check-quotations"
grep -qiF "unmistakable" references/voices.md && pass "register folds in Ogilvy's clear-action rule" || fail "register missing the clear-action rule"

echo "== V2.3: Strunk & White studied (4th-ed, source of record) =="
grep -qiF "coordinate ideas in similar form" references/craft-canon.md && pass "canon: parallel construction (Rule 19)" || fail "canon missing parallel construction"
grep -qiF "Keep related words together" references/craft-canon.md && pass "canon: keep related words together (Rule 20)" || fail "canon missing keep-related-words"
grep -qiF "topic sentence" references/craft-canon.md && pass "canon: paragraph rule + topic-sentence precision note" || fail "canon missing topic-sentence treatment"
grep -qiF "do not inject opinion" references/craft-canon.md && pass "canon: voice-vs-opinion tension resolved" || fail "canon missing the opinion tension"
grep -qiF "source of record" references/craft-canon.md && pass "canon: 4th-ed is the source of record" || fail "canon missing source-of-record anchor"
grep -qiF "4th-ed Rule 19" references/craft-canon.md && pass "canon: 4th-ed numbering applied" || fail "canon missing 4th-ed numbering"
grep -qiF "Voice discipline" references/craft-canon.md && pass "canon: White voice-discipline (restraint half)" || fail "canon missing White voice-discipline note"
grep -qiF "breezy manner" references/craft-canon.md && pass "canon: White anti-caricature reminders" || fail "canon missing White reminders"
chk "SKILL surfaces parallel construction (R19)" "coordinate ideas in similar form"
[ -f references/voice-examples.md ] && pass "voice-examples.md exists" || fail "voice-examples.md missing"
grep -qiF "voice ogilvy" references/voice-examples.md && pass "voice-examples covers the ogilvy voice" || fail "voice-examples missing ogilvy"

echo "== Self-containment (no personal-project coupling) =="
LEAK=0
for term in Threshold OurGospelStudy PithyByte GEARU SignUpSpark Voltron LocalCred VeroWrite Neal-specific; do
  if grep -rqiF "$term" SKILL.md references/ 2>/dev/null; then echo "  leak: $term"; LEAK=1; fi
done
[ "$LEAK" -eq 0 ] && pass "no personal-project names in skill or references" || fail "personal-project coupling present"

echo "== Em-dash budget (1.0) — the rule, made countable =="
chk "punctuation budget section present" "Punctuation budget"
chk "budget stated per 1,000 words" "per 1,000 words"
chk "framed as a generation rule, not a cleanup" "generation rule"
chk "final pass counts em-dashes" "Count the em-dashes"
# DOGFOOD: SKILL.md is the always-loaded in-context exemplar — it must itself meet a low
# em-dash density, or it teaches the model the spray the rule forbids. Prose rule is <=2/1000;
# the residual here is markdown structure (headings, checklist labels, ref/changelog separators),
# so the ceiling is 10/1000 (V2.3 was ~30/1000 — full spray).
emc=$(grep -o "—" SKILL.md | wc -l | tr -d ' ')
sw=$(wc -w < SKILL.md | tr -d ' ')
dens=$(awk -v c="$emc" -v w="$sw" 'BEGIN{printf "%.1f",(w?c*1000.0/w:0)}')
ok=$(awk -v c="$emc" -v w="$sw" 'BEGIN{print ((w && c*1000.0/w<=10)?1:0)}')
if [ "$ok" -eq 1 ]; then pass "dogfood: SKILL.md em-dash density ${dens}/1000 words (<=10)"; else fail "dogfood: SKILL.md em-dash density ${dens}/1000 words (>10 — meet your own budget)"; fi
echo "  (informational) reference-file em-dash density — purge targets if high:"
for f in references/*.md; do
  ec=$(grep -o "—" "$f" | wc -l | tr -d ' '); fw=$(wc -w < "$f" | tr -d ' ')
  awk -v f="$f" -v c="$ec" -v w="$fw" 'BEGIN{printf "    %-34s %.1f /1000\n", f, (w?c*1000.0/w:0)}'
done
# purged exemplar files must stay clean (hard checks); cap 5/1000
for f in references/craft-canon.md references/banned-words.md; do
  ec=$(grep -o "—" "$f" | wc -l | tr -d ' '); fw=$(wc -w < "$f" | tr -d ' ')
  d=$(awk -v c="$ec" -v w="$fw" 'BEGIN{printf "%.1f",(w?c*1000.0/w:0)}')
  okk=$(awk -v c="$ec" -v w="$fw" 'BEGIN{print((w&&c*1000.0/w<=5)?1:0)}')
  if [ "$okk" -eq 1 ]; then pass "dogfood: $f ${d}/1000 (<=5)"; else fail "dogfood: $f ${d}/1000 (>5)"; fi
done
# dead-reference guard: nonfiction-ai-patterns.md does not exist in this skill
if grep -rqF "nonfiction-ai-patterns" SKILL.md references/; then fail "dead reference to nonfiction-ai-patterns.md present"; else pass "no dead reference to nonfiction-ai-patterns.md"; fi

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
