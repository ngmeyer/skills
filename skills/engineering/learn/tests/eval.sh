#!/usr/bin/env bash
# Structural + behavioral eval for learn.
# Structural: design contract in SKILL.md (+ portability across harnesses).
# Behavioral: scripts/verify.sh against a scratch git repo with a fake
# rebase-merged multi-commit PR (needs git; no network).
# Usage: bash tests/eval.sh   Exit 0 on pass, 1 on any failure.
set -u
cd "$(dirname "$0")/.."
SKILL_DIR=$(pwd)
PASS=0; FAIL=0; SKIP=0
pass() { echo "PASS  $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL  $1"; FAIL=$((FAIL+1)); }
# A third outcome, for exactly one check: the private-name scan of the real tree, whose
# term list is deliberately never committed (KTD13). In a fresh clone that list is absent,
# and the two honest answers there are "did not scan" and "failed" — never "clean". SKIP is
# "did not scan", it prints no PASS line, and it is counted and restated in the summary so
# a reader cannot mistake it for a clean result. Every other check either passes or fails.
skip() { echo "SKIP  $1"; SKIP=$((SKIP+1)); }
chk() { if grep -qF -- "$2" SKILL.md; then pass "$1"; else fail "$1"; fi; }

echo "== Frontmatter =="
head -1 SKILL.md | grep -qx -- '---' && pass "frontmatter opens" || fail "frontmatter opens"
chk "name: learn" "name: learn"
chk "description" "description:"
chk "owner" "owner: ngmeyer"
chk "triggers" "Use when:"
desc=$(awk '/^description:/{f=1;next} f&&/^[a-z-]+:/{exit} f' SKILL.md | wc -c)
[ "$desc" -le 1024 ] && pass "description <= 1024 chars ($desc)" || fail "description too long ($desc)"

echo "== Design contract =="
for s in "## Inputs" "## Procedure" "## Verification" "## Gotchas" "## References"; do chk "section $s" "$s"; done
for k in "Verify merged" "Harvest" "durable vs throwaway" "Dedupe + staleness" "Retire specs" "Budget check" "Open the PR" "Never merge" "as a draft" "never commit to the default branch"; do chk "contract: $k" "$k"; done
for r in memory-import lesson-filter dedupe-staleness spec-retirement pr-template multi-agent harness-notes telemetry-followup sources; do
  [ -f references/$r.md ] && pass "reference $r.md" || fail "reference $r.md missing"
done
for x in verify redact-scan memory-triage tray-path tray; do [ -x scripts/$x.sh ] && pass "scripts/$x.sh executable" || fail "$x.sh not executable"; done
for k in "Mode: from-memories" "Redact gate" "Not for repo" "One draft PR per repo" "never prune them yourself" "Read-only"; do chk "from-memories: $k" "$k"; done
# R7/R18/R20 reachable from the instructions, not only from the scripts: an agent whose
# session produced no merge stops at step 1 unless step 1 routes it onward, and the mode it
# lands in has to name all three tray verbs.
# The heading pin carries its `##`: the step-1 pointer names the mode too, so a bare
# "Mode: no-merge capture" passes with the section itself deleted — it did, as a mutant.
for k in "nothing merged" "## Mode: no-merge capture" "scripts/tray.sh capture --track" "scripts/tray.sh list" "scripts/tray.sh reject <id> --reason" "stays listable"; do
  chk "no-merge mode: $k" "$k"
done
# The mode's exit. Without a promotion step an agent reading this file can capture, list
# and reject, and has no instruction for how a staged lesson ever leaves the tray — the
# tray becomes a drawer. Each pin is a rule an agent cannot reconstruct from the scripts:
# where promotion re-enters the spine, the order evidence and routing happen in, what the
# refusal is, and the two halves of the proposed state's reconciliation.
for k in "scripts/tray.sh promote --event" "scripts/tray.sh propose <id>... --branch <head> --pr <ref>" \
         "Evidence resolves before the track routes" "the attempt is refused" "step 4 (Place)" \
         "one draft PR and never merge it here" "clock stays frozen while that branch is still on the remote" \
         "returns to \`captured\` with its clock untouched"; do
  chk "no-merge mode promotion: $k" "$k"
done
# Gate 4 demanded evidence in the merged tree, which a rejected alternative has none of by
# definition — R10 and the gate were in direct conflict. The fix is a second evidence
# class, not a weaker gate for every track.
rchk() { if grep -qF -- "$3" "references/$2"; then pass "$1"; else fail "$1"; fi; }
for k in "*Resolved*" "*Recorded*" "by definition" "flagged **asserted**" "never into the instruction file"; do
  rchk "lesson-filter gate 4: $k" lesson-filter.md "$k"
done
for k in "Promoted from the capture tray" "opened as a draft and is never merged" "Left staged" "Rotate the credential"; do
  rchk "pr-template: $k" pr-template.md "$k"
done

echo "== Hygiene: size, no harness tokens, no internal names (a lint — the portability PROOF is the differential at the end of this file) =="
lines=$(wc -l < SKILL.md); [ "$lines" -le 250 ] && pass "SKILL.md $lines lines" || fail "SKILL.md $lines lines"
bytes=$(wc -c < SKILL.md); [ "$bytes" -le 16000 ] && pass "SKILL.md $bytes bytes (<=16k)" || fail "SKILL.md $bytes bytes"
body_dash=$(awk 'NR>1 && /^---$/{c++} END{print c+0}' SKILL.md)
[ "$body_dash" -eq 1 ] && pass "no bare --- in body" || fail "bare --- lines in body: $((body_dash-1))"
# THIS IS A HYGIENE LINT, NOT THE PORTABILITY PROOF. Searching the body for
# harness-specific strings shows only that nothing NAMES a harness; it cannot show that a
# verb RUNS anywhere, and a skill whose scripts were all broken would pass it unchanged.
# R5 and R13 are proved at the end of this file instead — the same state produced by the
# skill, by hand and by a stream editor, read by the same checks, and every verb run under
# a bare shell with no harness environment and no forge CLI on PATH. The lint stays
# because the repo's own hygiene rule forbids these tokens (and a user path) in a
# published skill, which is a different claim worth keeping.
# Frontmatter is exempt: it is per-harness metadata each one parses or ignores, and
# `user-invocable`/`allowed-tools` is what makes this a slash command in Claude Code.
body=$(awk 'NR>1 && /^---$/{f=1;next} f' SKILL.md)
if grep -nE '~/\.claude|\.claude/|\.cursor/|allowed-tools|/Users/|/home/[a-z]|\bgh (pr|api)\b|Bash\(|AskUserQuestion' <<<"$body"; then fail "hygiene lint: harness-specific token in core"; else pass "hygiene lint: no harness-specific tokens in the core body (not the portability proof — see the differential)"; fi
grep -qE '^user-invocable: true' SKILL.md && pass "slash-invocable in Claude Code" || fail "no user-invocable: true"

# --- KTD13, half one: path SHAPES, not literal names -------------------------------------
# A leak is a shape, and a shape needs no private name to match: an absolute path into
# somebody's disk, an encoded agent-home namespace, or a container agent's home. The scan
# set now includes tests/, which the literal denylist above excluded — so the file running
# the scan was the one file exempt from it, and a name planted here was invisible.
# CHANGELOG.md is in the set because the repo's own hygiene rule names a changelog as a
# place a private name leaks from, and it is a published file like any other.
SCAN_SET="SKILL.md CHANGELOG.md references/ scripts/ tests/"
SHAPE=0
# Every pattern below brackets one of its own letters (`[U]sers`, `[u]mes`). That is NOT a
# file or line exclusion — nothing is skipped, and a real leak anywhere in this file is
# still matched. It only stops each pattern's own spelling from matching itself, which it
# otherwise does: written plainly, this loop reported itself and nothing else, and a
# scanner that always finds exactly one hit in its own source cannot be read.
# The trailing class deliberately excludes `.`, so this file's own `$M/home/.claude/...`
# fixture tree and the hygiene regex's own alternations above do not match, while a real
# absolute home path does. The encoded-namespace pattern matches an agent-home namespace
# after encoding (every non-alphanumeric becomes `-`, so a real one always starts with
# `-`), which is why the `<encoded-abs-path>` placeholder documented in
# references/harness-notes.md stays legal and a planted real one does not.
for shape in '/Vol[u]mes/[A-Za-z0-9_-]' '/[U]sers/[A-Za-z0-9_-]' '/ho[m]e/[A-Za-z0-9_-]' '\.claude/pro[j]ects/-' '/works[p]ace'; do
  hits=$(grep -rnE -- "$shape" $SCAN_SET 2>/dev/null)
  [ -n "$hits" ] && { echo "  path shape $shape:"; printf '%s\n' "$hits" | sed 's/^/    /'; SHAPE=1; }
done
[ $SHAPE = 0 ] && pass "no leaked path shapes (absolute user or volume path, encoded agent-home namespace, container agent home)" || fail "leaked path shape present"

# --- KTD13, half two: the private-NAME detector ------------------------------------------
# Shapes cannot catch a bare name, and the eleven literal names that used to sit in the
# denylist above were themselves the leak they searched for: a denylist of real private
# names is a published list of real private names. Deleting them without replacement would
# have left the "no internal names" check green by having nothing to find — so the names
# move to a file that is never committed and the detector stays.
#   term file: $LEARN_PRIVATE_TERMS, else tests/private-terms.local (tests/.gitignore)
#   one term per line; `#` comments and blank lines stripped; fixed-string, case-insensitive
# Exit codes are three, not two, because "cannot scan" is not "clean":
#   0 nothing found   1 a term is present   2 cannot scan (no term file, or it holds none)
# A match is reported MASKED — the file that matched, never the term, or this eval's own
# output would republish the name the detector exists to keep out of the tree.
NAME_TERMS_DEFAULT=tests/private-terms.local
terms_path() { echo "${LEARN_PRIVATE_TERMS:-$NAME_TERMS_DEFAULT}"; }
scan_names() {
  tf=$1; shift
  [ -f "$tf" ] || { echo "  CANNOT SCAN: no term file at $tf"; return 2; }
  sn_terms=$(sed -e 's/#.*//' "$tf" | tr -d '\r' | awk 'NF')
  [ -n "$sn_terms" ] || { echo "  CANNOT SCAN: term file $tf holds no terms"; return 2; }
  sn_found=0
  # The term list matches itself — it is a file full of the terms, and when it sits at the
  # default path it sits inside the scanned tests/ directory. Excluding it by filename is
  # not a hole: it is gitignored, so it is not one of the published files this check is
  # about. Nothing else is excluded, this eval file least of all.
  sn_self=$(basename "$tf")
  while IFS= read -r sn_t; do
    sn_hit=$(grep -rliF --exclude="$sn_self" -- "$sn_t" "$@" 2>/dev/null)
    [ -n "$sn_hit" ] && { echo "  private name (masked) present in: $(printf '%s' "$sn_hit" | tr '\n' ' ')"; sn_found=1; }
  done <<<"$sn_terms"
  [ $sn_found = 0 ] && return 0 || return 1
}

echo "== KTD13: the name detector's own mechanism, proved on a fixture tree =="
# Proved on a fixture, because the real tree is (and should be) clean: a detector asserted
# only against clean state is indistinguishable from a detector that cannot find anything.
# `acme-widgets` is a placeholder, not anybody's project.
NT=$(mktemp -d)
# The fixture tree is built FROM $SCAN_SET — the same variable the real scan uses — so the
# locations proved below are the locations actually scanned. A hard-coded fixture would
# stay green with every entry but one dropped from $SCAN_SET.
NTLOCS=
for p in $SCAN_SET; do
  case $p in
    */) mkdir -p "$NT/tree/$p"; NTLOCS="$NTLOCS ${p}f.txt";;
    *)  NTLOCS="$NTLOCS $p";;
  esac
done
mkdir -p "$NT/tree"
for loc in $NTLOCS; do printf 'generic placeholder content\n' > "$NT/tree/$loc"; done
printf '# a comment line\n\nacme-widgets\n' > "$NT/terms"
printf '# only comments\n\n\n'              > "$NT/terms-blank"
printf 'a-term-in-no-file\n'                > "$NT/terms-other"
# `|| exit 9`, not `&&`: a failed `cd` would make the subshell exit 1, which is exactly the
# code that means "a planted name was caught". A wrapper whose error path collides with a
# meaningful result is how a check passes for the wrong reason, so the error path gets a
# code nothing else uses.
sn() { (cd "$NT/tree" || exit 9; scan_names "$1" $SCAN_SET >/dev/null 2>&1); echo $?; }
nloc=$(printf '%s\n' $NTLOCS | grep -c .)
[ "$nloc" -ge 5 ] && pass "the fixture covers all $nloc entries of the real scan set" || fail "the fixture covers only $nloc scan-set entries"
[ "$(sn "$NT/terms")" = 0 ] && pass "a clean tree reports clean (0)" || fail "clean tree not reported clean"
# One planted name per scanned location. A single planted file would stay green with every
# other path dropped from the scan set, and tests/ is the path the old denylist omitted.
for loc in $NTLOCS; do
  printf 'we hit this in acme-widgets last week\n' >> "$NT/tree/$loc"
  [ "$(sn "$NT/terms")" = 1 ] && pass "a name planted in $loc is caught (1)" || fail "a name planted in $loc is NOT caught"
  sed -i.bak '$d' "$NT/tree/$loc"; rm -f "$NT/tree/$loc.bak"
  [ "$(sn "$NT/terms")" = 0 ] && pass "…and the tree is clean again once $loc is restored" || fail "$loc restore left the planted name behind"
done
# "Cannot scan" must never read as "clean". Both arms: no file at all, and a file that
# exists but yields no terms after stripping — the shape that would otherwise match every
# file in the tree against the empty string, or none of them, and call it a pass.
[ "$(sn "$NT/no-such-file")" = 2 ] && pass "a missing term file fails loudly (2), it does not report clean" || fail "a missing term file does not return the cannot-scan code"
[ "$(sn "$NT/no-such-file")" != 0 ] && pass "a missing term file is specifically not the clean code (0)" || fail "a missing term file reported clean"
[ "$(sn "$NT/terms-blank")" = 2 ] && pass "a comment-only term file fails loudly (2), it does not report clean" || fail "a comment-only term file does not return the cannot-scan code"
# The environment override, proved in both directions on a tree where the two term files
# disagree — otherwise reading the wrong one is undetectable. The default-path file names a
# term the tree contains; the override names one it does not.
printf 'we hit this in acme-widgets last week\n' >> "$NT/tree/SKILL.md"
printf 'acme-widgets\n' > "$NT/tree/$NAME_TERMS_DEFAULT"
snr() { (cd "$NT/tree" || exit 9; scan_names "$(terms_path)" $SCAN_SET >/dev/null 2>&1); echo $?; }
# And prove that error path is reachable and distinguishable, or the guard above is a
# comment rather than a check.
sn_bad() { (cd "$NT/no-such-tree" || exit 9; scan_names "$1" $SCAN_SET >/dev/null 2>&1); echo $?; }
[ "$(sn_bad "$NT/terms")" = 9 ] && pass "the fixture wrapper's own failure is code 9, distinct from both clean (0) and caught (1)" || fail "the fixture wrapper's failure path is indistinguishable from a result"
# `unset` so an operator who happens to have the override exported does not turn the
# no-override arm into a second copy of the override arm — it did, and the arm passed
# anyway because the subshell's own error exit also happened to be 1.
[ "$(unset LEARN_PRIVATE_TERMS; snr)" = 1 ] && pass "with no override, the default term file is the one read" || fail "the default term file was not read"
[ "$(LEARN_PRIVATE_TERMS=$NT/terms-other snr)" = 0 ] && pass "an override is read INSTEAD of the default (its term is absent, so the default's present term is not reported)" || fail "the override did not replace the default"
[ "$(LEARN_PRIVATE_TERMS=$NT/no-such-file snr)" = 2 ] && pass "an override pointing at nothing fails loudly rather than falling back to the default" || fail "a missing override fell back instead of failing"
rm -rf "$NT"

# And now the real tree, with the same scan set the shapes use (tests/ included).
NAME_TERMS=$(terms_path)
scan_names "$NAME_TERMS" $SCAN_SET; name_rc=$?
case $name_rc in
  0) pass "no private project name in the skill's published files, this eval file included (terms: $NAME_TERMS)";;
  1) fail "private project name present in the skill's published files";;
  # Two different situations, and conflating them is how "cannot scan" starts reading as
  # "clean". An override was ASKED FOR and could not be honoured: that is a failure, the
  # scan someone requested did not happen. Nothing configured at all is a fresh clone,
  # where the term list is absent by construction because it is never committed: that is a
  # SKIP — loud, counted, restated in the summary, and emphatically not a PASS.
  *) if [ -n "${LEARN_PRIVATE_TERMS:-}" ]; then
       fail "LEARN_PRIVATE_TERMS=$LEARN_PRIVATE_TERMS was set and could not be read: the private-name scan you asked for did not run"
     else
       skip "private-name scan of the real tree DID NOT RUN: no term list at $NAME_TERMS. NOT a clean result — put one term per line there (it is gitignored, see tests/.gitignore) or set LEARN_PRIVATE_TERMS, then re-run. The detector's mechanism is proved above and the path shapes were scanned regardless."
     fi;;
esac

echo "== The framing a harness actually reads (U10 step 4) =="
# A harness decides whether to load this skill from `description` alone. While that field
# opened "Post-merge learning pass. After a feature PR merges, …" and every one of its
# triggers named a merge, the no-merge capture mode was implemented and unreachable: no
# session without a merge would ever say anything that loads the skill. Nothing asserted
# any of this before, in any of the three places the framing is written down.
desc_block=$(awk '/^description:/{f=1;next} f&&/^[a-z-]+:/{exit} f' SKILL.md)
# Guard first. Three of the checks below are NEGATIVE — they assert a string is gone — and
# a negative grep against an empty extraction passes for the worst possible reason. So
# prove the extraction found something, and found the part the negatives are about.
{ [ -n "$desc_block" ] && printf '%s' "$desc_block" | grep -qF 'Use when:'; } \
  && pass "the description block extracted non-empty and contains its trigger list (so the negative pins below are not matching an empty string)" \
  || fail "the description block could not be extracted — every negative pin below is vacuous"
printf '%s' "$desc_block" | grep -qF 'Post-merge learning pass' \
  && fail "the description still opens on the merge-only framing" \
  || pass "the description no longer frames the whole skill as a post-merge pass"
printf '%s' "$desc_block" | grep -qF 'nothing merged' \
  && pass "the description names the no-merge case, so a harness can route to it" \
  || fail "the description never mentions a session with nothing merged"
# Pinned as a set, not as one phrase: any single wording is fair game to edit, and the
# claim worth holding is that the no-merge half is represented among the triggers at all.
nm=0
for t in "capture this lesson" "we just learned something" "what did this debugging session teach us" "what lessons are staged"; do
  printf '%s' "$desc_block" | grep -qF "$t" && nm=$((nm+1))
done
[ "$nm" -ge 1 ] && pass "the trigger list carries $nm phrase(s) a debugging/planning/exploring session would actually utter" \
  || fail "every trigger in the description is merge-dependent: the no-merge mode is unreachable from the instructions"
# The other two copies of the framing: the repository README and the installer blurb. Both
# live outside the skill, so both are skipped — never passed — in a standalone install.
ROOT=$(cd "$SKILL_DIR/../../.." 2>/dev/null && pwd || true)
if [ -n "$ROOT" ] && [ -f "$ROOT/README.md" ]; then
  lrn=$(grep -F 'skills/engineering/learn/SKILL.md' "$ROOT/README.md")
  lrn_n=$(printf '%s\n' "$lrn" | grep -c . )
  [ "$lrn_n" -ge 2 ] && pass "the README's learn entries were found ($lrn_n of them) — the negative pins below have something to read" \
    || fail "fewer than two learn entries found in the README: the pins below would be vacuous"
  printf '%s' "$lrn" | grep -qF 'runs after a PR merges' \
    && fail "README still tells a reader learn runs after a PR merges" \
    || pass "README no longer scopes learn to after a PR merges"
  printf '%s' "$lrn" | grep -qF 'Post-merge learning pass' \
    && fail "README's reference entry still calls learn a post-merge learning pass" \
    || pass "README's reference entry no longer calls learn a post-merge pass"
  printf '%s' "$lrn" | grep -qiF 'capture tray' \
    && pass "the README's learn entries name the no-merge half (the capture tray)" \
    || fail "the README describes only the merge half of the skill"
else
  skip "README framing not checked: no repository README at $SKILL_DIR/../../.. (standalone install)"
fi
if [ -n "$ROOT" ] && [ -f "$ROOT/.claude-plugin/plugin.json" ]; then
  PJ=$ROOT/.claude-plugin/plugin.json
  pjd=$(grep -F '"description"' "$PJ")
  [ -n "$pjd" ] && pass "the installer blurb was found in plugin.json" || fail "no description field in plugin.json: the pins below are vacuous"
  printf '%s' "$pjd" | grep -qF 'post-merge learning PRs' \
    && fail "the installer blurb still sells learn as post-merge learning PRs" \
    || pass "the installer blurb no longer sells learn as post-merge only"
  printf '%s' "$pjd" | grep -qF 'no-merge' \
    && pass "the installer blurb names the no-merge half" \
    || fail "the installer blurb never mentions the no-merge half"
  # Two independently-written statements of the same count, which is the only reason
  # checking them is worth anything: the prose word and the array length can disagree.
  pj_n=$(grep -c -E '^[[:space:]]*"\./skills/' "$PJ")
  grep -qF '"./skills/engineering/learn"' "$PJ" && pass "learn is listed in plugin.json" || fail "learn is not listed in plugin.json"
  [ "$pj_n" -eq 11 ] && pass "plugin.json lists 11 skills" || fail "plugin.json lists $pj_n skills, not 11"
  printf '%s' "$pjd" | grep -qF 'Eleven composable' && pass "and its prose says Eleven, agreeing with the array it sits next to" \
    || fail "the blurb's stated count no longer agrees with the $pj_n entries in the array"
else
  skip "installer blurb not checked: no .claude-plugin/plugin.json above the skill (standalone install)"
fi
# A FOURTH location the plan's step 4 does not name, found while implementing it: the body's
# own H1 and the "Why this exists" line, both of which still scoped the skill to a merge.
# The description routes a harness here; these two are the first things the agent then reads,
# and an agent that has just been told the skill is for merges will not look for the no-merge
# mode five sections down.
h1=$(grep -m1 '^# ' SKILL.md)
[ -n "$h1" ] && pass "the body's H1 was found (the negative pin below is not matching an empty string)" || fail "no H1 in SKILL.md"
printf '%s' "$h1" | grep -qF 'after a merge' \
  && fail "the H1 still scopes the whole skill to after a merge" \
  || pass "the H1 no longer scopes the whole skill to after a merge"
chk "the why-line covers the no-merge batch too" "or per batch a no-merge session staged"

echo "== The session-close boundary is file-level, not domain-level (U10 step 5) =="
# "Local memory vs committed context" stopped separating these two skills the moment this
# one grew a no-merge mode: both now capture from a session with nothing to merge. The line
# that still holds is which FILES each one writes, and a boundary drawn at the domain sends
# an agent to the wrong skill in exactly the case where both appear to apply.
chk "the not-for line draws the boundary at files" "writing anything outside the repo"
for k in "Both can run on a session with nothing merged" "which files each one writes"; do
  chk "boundary: $k" "$k"
done
rchk "multi-agent.md draws the same boundary at the file set" multi-agent.md "which files each one writes"

echo "== Version and changelog (U10 step 6) =="
[ -f CHANGELOG.md ] && pass "a sibling CHANGELOG.md exists" || fail "no sibling CHANGELOG.md"
grep -qE '^## Changelog' SKILL.md \
  && fail "version history is back in the always-loaded body" \
  || pass "no ## Changelog section in the always-loaded body (the repo lint warns on one)"
# Guard before the cross-check: an awk that returns nothing would make the next line
# `grep -qF ""`, which matches every file ever written. Demand a semver shape first.
skill_ver=$(awk '/^metadata:/{f=1} f&&/^[[:space:]]+version:[[:space:]]*/{print $2; exit}' SKILL.md)
printf '%s' "$skill_ver" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' \
  && pass "SKILL.md declares a semver skill version ($skill_ver)" \
  || fail "no semver metadata.version in SKILL.md — the cross-check below would grep for the empty string"
# An ENTRY, not a mention: a heading. `grep -F "$skill_ver"` anywhere in the file would be
# satisfied by the version appearing in a sentence of prose about some other release.
{ [ -n "$skill_ver" ] && [ -f CHANGELOG.md ] && grep -qE "^## +$(printf '%s' "$skill_ver" | sed 's/\./\\./g')( |$)" CHANGELOG.md; } \
  && pass "the changelog carries a heading entry for the version SKILL.md declares ($skill_ver)" \
  || fail "CHANGELOG.md has no heading entry for the declared version"
# The ONLY version in this repository that is not this skill's own is the plugin's, and it
# covers all eleven skills. Bumping it is a release decision for the other ten, so this
# unit does not touch it, and that restraint is pinned rather than remembered.
if [ -n "${ROOT:-}" ] && [ -f "$ROOT/.claude-plugin/plugin.json" ]; then
  grep -qF '"version": "1.0.0"' "$ROOT/.claude-plugin/plugin.json" \
    && pass "the shared plugin version is untouched at 1.0.0 — a release decision for eleven skills, not this skill's to make" \
    || fail "the shared plugin version moved: that is a release decision affecting ten other skills"
else
  skip "shared plugin version not checked: no .claude-plugin/plugin.json above the skill"
fi

echo "== Behavioral: verify.sh on scratch repo =="
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
(
  set -e
  git init -q --bare "$T/origin.git"
  git clone -q "$T/origin.git" "$T/w" 2>/dev/null; cd "$T/w"
  git config user.email t@t; git config user.name t; git checkout -q -b main
  printf 'Read docs/topics/x.md\n' > AGENTS.md; mkdir -p docs/topics; echo x > docs/topics/x.md
  git add -A; git commit -qm init; git push -q origin main
  BASE=$(git rev-parse HEAD)
  git checkout -q -b feat
  mkdir -p specs/feat/slices; echo spec > specs/feat/mainspec.md; git add -A; git commit -qm "c1 spec"
  echo s1 > specs/feat/slices/01.md; git add -A; git commit -qm "c2 slice"
  echo code > app.txt; git add -A; git commit -qm "c3 code"
  git checkout -q main; git rebase -q feat; git push -q origin main   # rebase-merge: 3 commits
  echo "$BASE" > "$T/base"; git rev-parse HEAD > "$T/merge"
  git checkout -q -b learn/1-feat
)
cd "$T/w"; B=$(cat "$T/base"); M=$(cat "$T/merge"); V="$SKILL_DIR/scripts/verify.sh"
out=$(BASE=$B bash "$V" "$M" main 400 specs/feat 2>&1); [ $? = 0 ] && ! grep -q WARN <<<"$out" && pass "happy path: multi-commit PR, BASE set" || { echo "$out"; fail "happy path"; }
out=$(bash "$V" "$M" main 400 specs/feat 2>&1); grep -q "WARN  specs/feat not added" <<<"$out" && pass "without BASE, earlier commits flagged (WARN)" || { echo "$out"; fail "BASE default"; }
BASE=$B bash "$V" "$M" main 400 specs >/dev/null 2>&1 && fail "spec root 'specs' accepted" || pass "rejects spec root 'specs' (<2 folders)"
BASE=$B bash "$V" "$M" main 400 specs/ >/dev/null 2>&1 && fail "'specs/' accepted" || pass "rejects 'specs/'"
BASE=$B bash "$V" "$M" main 400 'specs/*' >/dev/null 2>&1 && fail "glob accepted" || pass "rejects glob"
BASE=$B bash "$V" "$M" main 400 specs/../app.txt >/dev/null 2>&1 && fail ".. accepted" || pass "rejects .."
BASE=$B bash "$V" "$M" main 400 app.txt >/dev/null 2>&1 && fail "non-spec path accepted" || pass "rejects path outside spec roots"
echo "see specs/feat/mainspec.md" >> docs/topics/x.md
BASE=$B bash "$V" "$M" main 400 specs/feat >/dev/null 2>&1 && fail "dangling link accepted" || pass "fails on live link to retired spec"
git checkout -q docs/topics/x.md
git checkout -q main; BASE=$B bash "$V" "$M" main 400 specs/feat >/dev/null 2>&1 && fail "ran on default branch" || pass "fails on default branch"
git checkout -q learn/1-feat
yes word | head -500 > AGENTS.md; BASE=$B bash "$V" "$M" main 400 >/dev/null 2>&1 && fail "over budget accepted" || pass "fails over AGENTS.md budget"
git checkout -q AGENTS.md
BASE=$B bash "$V" deadbeef main 400 >/dev/null 2>&1 && fail "unmerged sha accepted" || pass "fails on unmerged/unknown sha"

echo "== Behavioral: from-memories on fixture memories =="
cd "$SKILL_DIR"
M=$(mktemp -d); trap 'rm -rf "$T" "$M"' EXIT
cp -r tests/fixtures/repo "$M/app"; R=$(cd "$M/app" && pwd)
E=$(printf '%s' "$R" | sed -E 's/[^A-Za-z0-9]/-/g')
mkdir -p "$M/home/.claude/projects/$E/memory" "$M/pasted"
cp tests/fixtures/memories/project.md "$M/home/.claude/projects/$E/memory/project.md"
cp tests/fixtures/memories/global.md "$M/home/.claude/CLAUDE.md"
sed "s#__REPO__#$R#" tests/fixtures/memories/pasted-text.txt > "$M/pasted/notes.txt"
# secret is assembled at runtime so no token-shaped string is ever committed
tok="gh""p_$(printf 'Z%.0s' $(seq 1 36))"
printf -- "- Staging deploy uses %s\n- Escalate to %s\n" "$tok" "ops.lead@""corp-mail.io" > "$M/pasted/secret.txt"
cp -r "$M/home" "$M/home.before"
PM="$M/home/.claude/projects/$E/memory/project.md"
map=$(scripts/memory-triage.sh map "$R" -- "$PM" "$M/home/.claude/CLAUDE.md" "$M/pasted/notes.txt")
grep -qE "project.md[[:space:]]$R$" <<<"$map" && pass "map: Claude project memory -> repo (encoded path)" || { echo "$map"; fail "map project"; }
grep -qE "CLAUDE.md[[:space:]]global$" <<<"$map" && pass "map: global CLAUDE.md -> global" || fail "map global"
grep -qE "notes.txt[[:space:]]$R$" <<<"$map" && pass "map: pasted text with hand-typed project: header -> repo" || fail "map pasted header"
tri=$(scripts/memory-triage.sh triage "$R" "$PM")
grep -qE '^CANDIDATE[[:space:]].*Scheduled job routes' <<<"$tri" && pass "triage: durable lesson is CANDIDATE" || { echo "$tri"; fail "candidate"; }
grep -qE '^STALE[[:space:]].*legacy importer' <<<"$tri" && pass "triage: missing path -> STALE" || fail "stale"
grep -qE '^DUPLICATE[[:space:]].*npm run verify' <<<"$tri" && pass "triage: AGENTS.md duplicate -> DUPLICATE" || fail "dup AGENTS.md"
grep -qE '^NOT-FOR-REPO[[:space:]].*I prefer tabs' <<<"$tri" && pass "triage: personal line -> NOT-FOR-REPO" || fail "personal"
scripts/memory-triage.sh triage "$R" "$M/pasted/notes.txt" | grep -qE '^DUPLICATE[[:space:]].*idempotent' && pass "triage: docs/topics duplicate -> DUPLICATE" || fail "dup topics"
scripts/memory-triage.sh triage global "$M/home/.claude/CLAUDE.md" | grep -qE '^NOT-FOR-REPO[[:space:]].*British' && pass "triage: global item -> NOT-FOR-REPO" || fail "global item"
# One-fact-per-file memories have no bullets at all: the lesson is the frontmatter
# description, so a bullet-only read reports an empty file and imports nothing.
ff=$(scripts/memory-triage.sh triage "$R" tests/fixtures/memories/project-frontmatter.md)
grep -qE '^CANDIDATE[[:space:]].*\[type:feedback\].*equalize its error reasons' <<<"$ff" && pass "triage: frontmatter description -> CANDIDATE with type" || { echo "$ff"; fail "frontmatter fact"; }
uf=$(scripts/memory-triage.sh triage "$R" tests/fixtures/memories/user-frontmatter.md)
[ -z "$(grep -v '^NOT-FOR-REPO' <<<"$uf")" ] && [ -n "$uf" ] && pass "triage: type:user takes the whole file (body included)" || { echo "$uf"; fail "user-type file"; }
printf -- '- grep CLAUDE.md for `https://.*:.*@` before committing\n' | scripts/redact-scan.sh - >/dev/null && pass "redact: documented credential pattern is not a credential" || fail "pattern read as credential"
out=$(scripts/memory-triage.sh triage "$R" "$M/pasted/secret.txt"); rc=$?
[ $rc -ne 0 ] && grep -q '^BLOCKED-SECRET.*\[token\]' <<<"$out" && grep -q '^BLOCKED-SECRET.*\[email\]' <<<"$out" && pass "triage: token + email BLOCK (exit $rc)" || { echo "$out"; fail "secret not blocked"; }
grep -qF "$tok" <<<"$out" && fail "secret echoed unmasked" || pass "blocked output is masked"
grep -q CANDIDATE <<<"$out" && fail "lines from secret file leaked as candidates" || pass "secret file contributes no candidates"
echo "key: AKIA$(printf 'Q%.0s' $(seq 1 16))" | scripts/redact-scan.sh - >/dev/null && fail "AWS key passed" || pass "redact: AWS key blocks (stdin/diff mode)"
printf -- "- %s = %s\n" "pass""word" "hunter2""hunter2" | scripts/redact-scan.sh - >/dev/null && fail "password assignment passed" || pass "redact: key=value assignment blocks"
printf -- "- call %s\n" "415-555-""2671" | scripts/redact-scan.sh - >/dev/null && fail "phone passed" || pass "redact: phone blocks"
printf -- "- contact dev@example.com, 555-0123\n" | scripts/redact-scan.sh - >/dev/null && pass "redact: allowlisted example email/555-01xx pass" || fail "allowlist"
scripts/redact-scan.sh tests/fixtures/memories/*.md tests/fixtures/repo/AGENTS.md >/dev/null && pass "committed fixtures are clean" || fail "fixtures contain secrets"
diff -r "$M/home" "$M/home.before" >/dev/null && pass "source memories untouched (read-only)" || fail "source memories modified"

echo "== Behavioral: tray path resolution =="
# Every working tree sharing one git directory must resolve to ONE tray, byte-identically:
# a main tree, a subdirectory of it, a linked worktree, and a symlinked path to it.
cd "$SKILL_DIR"
TR=$(mktemp -d); trap 'rm -rf "$T" "$M" "$TR"' EXIT
TP="$SKILL_DIR/scripts/tray-path.sh"
(
  set -e
  mkdir -p "$TR/main/deep/er"
  cd "$TR/main"; git init -q .; git config user.email t@t; git config user.name t
  echo x > a.txt; git add -A; git commit -qm init
  git worktree add -q "$TR/wt" -b side
  ln -s main "$TR/link"
) >/dev/null 2>&1 || fail "tray fixture setup"
p_main=$(cd "$TR/main"         && bash "$TP")
p_sub=$(cd "$TR/main/deep/er"  && bash "$TP")
p_wt=$(cd "$TR/wt"             && bash "$TP")
p_link=$(cd "$TR/link"         && bash "$TP")
case "$p_main" in /*/learn-tray) pass "tray path is absolute, under the git dir, named learn-tray";; *) fail "tray path shape: '$p_main'";; esac
# Each comparison demands a non-empty absolute path as well as equality: two failed
# resolutions are also "equal", and that pair must not read as a pass.
eq() { [ -n "$2" ] && [ "${2#/}" != "$2" ] && [ "$2" = "$p_main" ] && pass "$1" || { echo "  got '$2' want '$p_main'"; fail "$1"; }; }
eq "subdirectory resolves to the same tray" "$p_sub"
eq "symlinked checkout resolves byte-identically (AE6)" "$p_link"
eq "linked worktree resolves byte-identically (AE7)" "$p_wt"
[ -n "$p_main" ] && [ ! -e "$p_main" ] && pass "resolution creates nothing (tray is lazy, made on first capture)" || fail "resolution created the tray"
# Contract filenames: entry-<YYYYMMDD>-<id>.md and tray-log.md, one source of truth.
e=$(cd "$TR/wt" && bash "$TP" entry abc123)
[ "$e" = "$p_main/entry-$(date +%Y%m%d)-abc123.md" ] && pass "entry filename is entry-<YYYYMMDD>-<id>.md in the tray" || { echo "  $e"; fail "entry filename"; }
[ "$(cd "$TR/wt" && bash "$TP" log)" = "$p_main/tray-log.md" ] && pass "tray log is <tray>/tray-log.md" || fail "tray log path"
mkdir -p "$p_main"; printf 'lesson\n' > "$e"; printf 'log\n' > "$p_main/tray-log.md"
[ "$(cd "$TR/main" && cat "$(bash "$TP")/$(basename "$e")")" = lesson ] && pass "entry written from the linked worktree is readable from the main tree" || fail "entry not readable from main tree"
[ "$(ls "$p_main" | grep -c '^entry-')" = 1 ] && pass "entry- prefix counts 1 entry, never the log" || fail "entry count includes the log"
(cd "$TR/main" && git worktree remove --force "$TR/wt" && git worktree prune) >/dev/null 2>&1 || fail "worktree prune setup"
[ ! -d "$TR/wt" ] && [ -f "$e" ] && pass "entry survives the worktree being pruned (AE7)" || fail "entry lost with the worktree"
so=$(cd "$TR" && bash "$TP" 2>/dev/null); rc=$?
se=$(cd "$TR" && bash "$TP" 2>&1 >/dev/null)
[ $rc -ne 0 ] && [ -z "$so" ] && grep -q '^learn: ' <<<"$se" && grep -qi 'not a git repositor' <<<"$se" && pass "outside a repository: fails naming the cause, prints no path (exit $rc)" || { echo "  rc=$rc out='$so' err='$se'"; fail "outside-repo resolution"; }

echo "== Behavioral: capture verb (entry schema) =="
# A no-merge session stages a lesson that a session weeks later, in another worktree,
# can select, read and judge. So the file has to be complete, honest about being
# unverified, and readable with nothing but sed.
cd "$SKILL_DIR"
CT=$(mktemp -d); trap 'rm -rf "$T" "$M" "$TR" "$CT"' EXIT
TS="$SKILL_DIR/scripts/tray.sh"
newrepo() { # a repo with a durable store (AGENTS.md + docs/topics) and one real source path
  mkdir -p "$1" && cd "$1" && git init -q . && git config user.email t@t && git config user.name t \
    && printf 'Read docs/topics/x.md\n' > AGENTS.md && mkdir -p docs/topics src/jobs \
    && echo x > docs/topics/x.md && echo code > src/jobs/auth.ts && git add -A && git commit -qm init
}
# A plain reader, the way a non-Claude agent would do it: strip the key, unquote, unescape.
fm() { sed -n "s/^$2: //p" "$1" | sed 's/^"\(.*\)"$/\1/; s/\\\(.\)/\1/g'; }
fmpaths() { awk '/^paths:/{f=1;next} f&&/^  - /{sub(/^  - /,"");print;next} f{exit}' "$1" | sed 's/^"\(.*\)"$/\1/'; }
keys() { awk 'NR>1&&/^---$/{exit} /^[a-z_]+:/{sub(/:.*/,"");print}' "$1"; }
ents() { ls "$1" 2>/dev/null | grep -c '^entry-'; }

(newrepo "$CT/r1") >/dev/null 2>&1 || fail "capture fixture setup"
cd "$CT/r1"; TRAY1=$(bash "$TP")
[ ! -e "$TRAY1" ] || fail "fixture repo already has a tray"
CLAIM='A scheduled-job route behind a bare header check rejects every caller that cannot set the header'
cap() { bash "$TS" capture --track checkable --claim "$CLAIM" --evidence 'the guard runs before the body is read' --path src/jobs/auth.ts "$@"; }
p=$(cap); rc=$?
[ $rc = 0 ] && [ -f "$p" ] && pass "capture writes the entry whose path it prints" || { echo "  rc=$rc p='$p'"; fail "capture writes an entry"; }
[ -d "$TRAY1" ] && pass "the first capture creates the tray (nothing else does)" || fail "tray not created"
[ "$(ents "$TRAY1")" = 1 ] && pass "AE1: one no-merge capture leaves exactly one tray entry" || fail "AE1 entry count $(ents "$TRAY1")"
grep -q '^verified: false$' "$p" && pass "AE1: the entry is marked unverified" || fail "AE1 unverified"
grep -q '^state: captured$' "$p" && pass "capture writes state: captured" || fail "state: captured"
# Both of these hold trivially when no capture happened at all, so each one demands the
# entry exist first: "changed nothing" is only evidence next to "wrote the lesson".
[ -f "${p:-/nonexistent}" ] && [ -z "$(git status --porcelain)" ] && pass "AE1: the working tree is untouched (the tray is outside it)" || { git status --porcelain; fail "AE1 working tree dirty"; }
[ -f "${p:-/nonexistent}" ] && ! grep -rqF 'header check' AGENTS.md docs/ && pass "AE1: nothing in docs/topics/ or the instruction file" || fail "AE1: the lesson leaked into the durable store"
i=$(fm "$p" id); case "$p" in *"-$i.md") pass "the filename carries the entry id";; *) fail "filename '$p' does not carry id '$i'";; esac

# Rejected at write time, not at promotion: an incomplete entry never reaches the tray.
bad() { local lbl=$1 n0 n1 o rc; shift
  n0=$(ents "$TRAY1"); o=$(bash "$TS" capture "$@" 2>&1); rc=$?; n1=$(ents "$TRAY1")
  [ $rc -ne 0 ] && [ "$n0" = "$n1" ] && grep -q '^learn: ' <<<"$o" && pass "rejected at write time: $lbl" || { echo "  rc=$rc n0=$n0 n1=$n1 out='$o'"; fail "not rejected: $lbl"; }
}
bad "no --claim"                     --track standing --evidence e --path src/jobs/auth.ts
bad "no --evidence"                  --track standing --claim c --path src/jobs/auth.ts
bad "no --path"                      --track standing --claim c --evidence e
bad "no --track"                     --claim c --evidence e --path src/jobs/auth.ts
bad "track outside the vocabulary"   --track lore --claim c --evidence e --path src/jobs/auth.ts
bad "path carrying a line number (KTD3)" --track standing --claim c --evidence e --path src/jobs/auth.ts:42
bad "absolute path"                  --track standing --claim c --evidence e --path /etc/hosts
bad "--track decision with no --accepted (R8)" --track decision --claim c --evidence e --path src/jobs/auth.ts
bad "--accepted on a track that cannot carry it" --track standing --accepted true --claim c --evidence e --path src/jobs/auth.ts
pd=$(bash "$TS" capture --track decision --accepted false --claim 'Chose the queue over a cron route' --evidence 'the cron route cannot retry a failed run' --path src/jobs/auth.ts)
[ -f "${pd:-/nonexistent}" ] && grep -q '^accepted: false$' "$pd" && pass "a decision entry records whether the decision was accepted (R8)" || fail "accepted not recorded"

# Two captures in the same second: the id is what keeps them apart, so it cannot be time-derived.
n0=$(ents "$TRAY1"); s1=$(date +%s); a=$(cap); b=$(cap); c=$(cap); s2=$(date +%s)
u=$(printf '%s\n%s\n%s\n' "$a" "$b" "$c" | sort -u | grep -c .)
[ "$u" = 3 ] && [ -f "$a" ] && [ -f "$b" ] && [ -f "$c" ] && [ "$(ents "$TRAY1")" = $((n0+3)) ] && pass "3 captures within $((s2-s1))s -> 3 distinct files, none overwritten" || { echo "  $a $b $c"; fail "same-second captures collide"; }

# Round-trip: written in one invocation, read back whole in another.
HARD='Do not trust "x-internal: 1" as auth: it is one #comment and a \ away from nothing'
p2=$(bash "$TS" capture --track standing --claim "$HARD" --evidence 'the guard compares one header, then returns' --path src/jobs/auth.ts --path docs/topics/x.md)
[ "$(fm "${p2:-/nonexistent}" claim)" = "$HARD" ] && pass "round-trip: a claim with quotes, a colon, a # and a backslash is byte-identical on read-back" || { echo "  got '$(fm "${p2:-/nonexistent}" claim)'"; fail "round-trip claim"; }
[ "$(fmpaths "${p2:-/nonexistent}")" = "$(printf 'src/jobs/auth.ts\ndocs/topics/x.md')" ] && pass "round-trip: every path, in order" || { echo "  got '$(fmpaths "${p2:-/nonexistent}")'"; fail "round-trip paths"; }
miss=""; for k in id claim evidence captured_on track state verified; do [ -n "$(fm "${p2:-/nonexistent}" "$k")" ] || miss="$miss $k"; done
[ -z "$miss" ] && pass "round-trip: every required field reads back non-empty" || fail "missing on read-back:$miss"
[ "$(fm "${p2:-/nonexistent}" captured_on)" = "$(date +%Y-%m-%d)" ] && pass "captured_on is the capture date" || fail "captured_on"

# No harness API: another agent writes the entry with printf and it is the same artifact.
h=$(bash "$TP" entry handwritten)
{ printf -- '---\n'; printf 'id: handwritten\n'
  printf 'claim: "A bare header check is not authentication"\n'
  printf 'evidence: "the guard compares one header, then returns"\n'
  printf 'paths:\n  - "src/jobs/auth.ts"\n'
  printf 'captured_on: %s\n' "$(date +%Y-%m-%d)"
  printf 'track: standing\nstate: captured\nverified: false\n'; printf -- '---\n'; } > "$h"
[ "$(fm "$h" claim)" = "A bare header check is not authentication" ] && pass "a hand-written entry (printf only, no harness API) reads back through the same reader" || fail "hand-written entry unreadable"
[ -n "$(keys "$h")" ] && [ "$(keys "$h")" = "$(keys "${p2:-/nonexistent}")" ] && pass "hand-written and captured entries carry the same field keys in the same order" || { diff <(keys "$h") <(keys "${p2:-/nonexistent}"); fail "hand-written schema differs from capture's"; }

# AE12: a credential in the entry text aborts the capture. Fresh repo, so "no file was
# written" is checkable as "no tray exists at all" — the scan runs before anything is made.
(newrepo "$CT/r2") >/dev/null 2>&1 || fail "AE12 fixture setup"
cd "$CT/r2"; TRAY2=$(bash "$TP")
tok2="gh""p_$(printf 'Y%.0s' $(seq 1 36))"
o=$(bash "$TS" capture --track standing --claim 'The callback rejects a valid session' --evidence "the request header carried $tok2" --path src/jobs/auth.ts 2>&1); rc=$?
# Each assert demands the deliberate abort report, so a crash (or a missing script) can
# never read as "aborted correctly" — exit 127 and silence satisfy a bare `rc -ne 0`.
blocked() { grep -q '^BLOCK token' <<<"$o" && grep -q '^learn: ' <<<"$o"; }
[ $rc -ne 0 ] && blocked && pass "AE12: capture aborts on a credential in the entry text (exit $rc)" || { echo "  rc=$rc out='$o'"; fail "AE12 capture did not abort by design"; }
blocked && ! grep -qF "$tok2" <<<"$o" && pass "AE12: the finding is reported masked" || fail "AE12: the finding was echoed unmasked"
blocked && [ ! -e "$TRAY2" ] && pass "AE12: nothing written — not even the tray (no redacted entry)" || { ls -a "$TRAY2" 2>/dev/null; fail "AE12 wrote to the tray"; }
cd "$SKILL_DIR"

echo "== Behavioral: lazy expiry and the tray log =="
# R12 + AE5, under KTD5 and KTD4. The sweep is the only expiry runner there is — the
# pilot's own lint forbids scheduled workflows and the hook may not be installed — so it
# has to fire on ordinary verbs. And it must never reap the entry whose proof just
# arrived: the set this invocation matched is an ARGUMENT the caller must state, which is
# how "match, then filter, then prune" is expressed as something a test can falsify.
XP=$(mktemp -d); trap 'rm -rf "$T" "$M" "$TR" "$CT" "$XP"' EXIT
# Both date flavours: -v is BSD, -d is GNU. A host with neither makes no 8-digit day, and
# then mkentry fails its assertion instead of quietly dating every entry today — which
# would make every "expires" assertion pass for the wrong reason.
daysago() { date -v-"$1"d +%Y%m%d 2>/dev/null || date -d "$1 days ago" +%Y%m%d; }
mkentry() { # <tray> <days-ago> <id> <state> -> path. printf only, as any agent would write it.
  local d p
  d=$(daysago "$2") || return 1
  case $d in [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]) ;; *) return 1;; esac
  p="$1/entry-$d-$3.md"
  { printf -- '---\n'; printf 'id: %s\n' "$3"
    printf 'claim: "An abandoned exploration left the guard half-written"\n'
    printf 'evidence: "the guard returns before the body is read"\n'
    printf 'paths:\n  - "src/jobs/auth.ts"\n'
    printf 'captured_on: %s-%s-%s\n' "${d:0:4}" "${d:4:2}" "${d:6:2}"
    printf 'track: standing\nstate: %s\nverified: false\n' "$4"; printf -- '---\n'; } > "$p"
  printf '%s\n' "$p"
}

(newrepo "$XP/r3") >/dev/null 2>&1 || fail "expiry fixture setup"
cd "$XP/r3"; TRAY3=$(bash "$TP"); LOG3=$(bash "$TP" log); mkdir -p "$TRAY3"
old=$(mkentry   "$TRAY3" 400 aaaaaaa1 captured) || fail "mkentry needs BSD date -v or GNU date -d"
young=$(mkentry "$TRAY3"   3 aaaaaaa2 captured) || fail "mkentry 3d"
edge=$(mkentry  "$TRAY3"  56 aaaaaaa3 captured) || fail "mkentry 56d"
prop=$(mkentry  "$TRAY3" 400 aaaaaaa4 proposed) || fail "mkentry proposed"
so=$(bash "$TS" sweep --no-matches 2>&1); rc=$?
# Every assertion below would hold on an untouched tray ("still there", "not logged"), so
# each one is anchored on the removal having actually happened. A missing sweep verb must
# not be able to pass a single one of them.
reaped() { [ $rc = 0 ] && [ ! -e "${old:-/nonexistent}" ] && [ -f "${LOG3:-/nonexistent}" ]; }
reaped && pass "AE5: an unmatched entry past the window is removed" || { echo "  rc=$rc out='$so'"; fail "AE5: entry not expired"; }
line=$(grep -F ' expired id=aaaaaaa1 ' "$LOG3" 2>/dev/null)
reaped && grep -qE "^- [0-9]{4}-[0-9]{2}-[0-9]{2} expired id=aaaaaaa1 age=400d captured=[0-9]{4}-[0-9]{2}-[0-9]{2} reason=unmatched-for-more-than-56-days$" <<<"$line" \
  && pass "AE5: the removal is logged naming id, age and reason" || { echo "  got '$line'"; fail "AE5: log line shape"; }
reaped && [ "$(grep -c ' expired id=' "$LOG3")" = 1 ] && pass "AE5: one removal, one line (the other three entries are not logged)" || { cat "$LOG3" 2>/dev/null; fail "AE5: log line count"; }
reaped && [ -f "$young" ] && [ -f "$edge" ] && pass "an entry inside the window is untouched (3d, and 56d = the window edge)" || fail "in-window entry removed"
reaped && [ -f "$prop" ] && ! grep -q 'id=aaaaaaa4' "$LOG3" && pass "KTD4: a proposed entry past the window is not reaped" || fail "proposed entry reaped"
reaped && [ -z "$(git status --porcelain)" ] && ! grep -rqF 'abandoned exploration' AGENTS.md docs/ \
  && pass "AE5: the expired entry never reached the durable store" || { git status --porcelain; fail "AE5: durable store touched"; }

# The ordering case (KTD5): same entry, same clock, one difference — the matched set.
m1=$(mkentry "$TRAY3" 400 bbbbbbb1 captured) || fail "mkentry matched"
o=$(bash "$TS" sweep --matched bbbbbbb1 2>&1); rc=$?
[ $rc = 0 ] && [ -f "$m1" ] && ! grep -q 'id=bbbbbbb1' "$LOG3" \
  && pass "KTD5 ordering: an over-age entry THIS invocation matched survives the sweep (it promotes, it is not pruned)" || { echo "  rc=$rc out='$o'"; fail "KTD5: matched entry pruned"; }
o=$(bash "$TS" sweep --no-matches 2>&1); rc=$?
[ $rc = 0 ] && [ ! -e "$m1" ] && grep -q 'id=bbbbbbb1' "$LOG3" \
  && pass "KTD5 ordering: the same entry at the same age, unmatched, is reaped — so the matched set is what decides" || { echo "  rc=$rc out='$o'"; fail "KTD5: unmatched entry survived"; }
# A caller that has not settled matching yet cannot sweep by accident.
n0=$(ents "$TRAY3"); o=$(bash "$TS" sweep 2>&1); rc=$?
[ $rc -ne 0 ] && [ "$(ents "$TRAY3")" = "$n0" ] && grep -q '^learn: ' <<<"$o" \
  && pass "sweep refuses to run until the caller states the matched set (--matched/--no-matches)" || { echo "  rc=$rc n0=$n0 out='$o'"; fail "sweep ran with no matched set"; }

# Capture is one of the three runners, and the sweep may not disturb what capture returns.
(newrepo "$XP/r4") >/dev/null 2>&1 || fail "capture-runner fixture setup"
cd "$XP/r4"; TRAY4=$(bash "$TP"); LOG4=$(bash "$TP" log); mkdir -p "$TRAY4"
c1=$(mkentry "$TRAY4" 90 ccccccc1 captured) || fail "mkentry 90d"
np=$(bash "$TS" capture --track checkable --claim "$CLAIM" --evidence 'the guard runs before the body is read' --path src/jobs/auth.ts); rc=$?
swept() { [ ! -e "${c1:-/nonexistent}" ] && grep -q 'id=ccccccc1 age=90d' "$LOG4" 2>/dev/null; }
swept && pass "KTD5: an ordinary capture is a runner — it expires the stale entry it found" || { ls "$TRAY4"; fail "capture did not sweep"; }
# Anchored on the sweep having run: "capture printed one path" holds with no sweep at all.
swept && [ $rc = 0 ] && [ "$(printf '%s' "$np" | grep -c .)" = 1 ] && [ -f "${np:-/nonexistent}" ] \
  && pass "capture still prints exactly one path and exits 0 (the sweep writes nothing to stdout)" || { echo "  rc=$rc out='$np'"; fail "capture stdout disturbed by the sweep"; }
# Likewise: with no log, `! grep` is true for free.
swept && [ -f "${np:-/nonexistent}" ] && ! grep -q "id=$(fm "${np:-/nonexistent}" id)" "$LOG4" \
  && pass "the entry this capture just wrote is not expired by its own sweep" || fail "capture reaped its own entry"

# No tray at all: the sweep must create nothing, or AE12's "not even the tray" dies.
(newrepo "$XP/r5") >/dev/null 2>&1 || fail "no-tray fixture setup"
cd "$XP/r5"; TRAY5=$(bash "$TP")
o=$(bash "$TS" sweep --no-matches 2>&1); rc=$?
[ $rc = 0 ] && [ ! -e "$TRAY5" ] && pass "no tray yet: the sweep is a no-op and creates nothing, not even the log" || { echo "  rc=$rc out='$o'"; ls -a "$TRAY5" 2>/dev/null; fail "sweep created a tray"; }

# Nobody swept for a long time. One invocation catches up, and the entries it keeps are
# byte-identical afterwards: a sweep that corrupts the tray is worse than one never run.
(newrepo "$XP/r6") >/dev/null 2>&1 || fail "catch-up fixture setup"
cd "$XP/r6"; TRAY6=$(bash "$TP"); LOG6=$(bash "$TP" log); mkdir -p "$TRAY6"
keep=""
for spec in "400 ddddddd1 captured gone" "90 ddddddd2 captured gone" "57 ddddddd3 captured gone" \
            "56 ddddddd4 captured keep" "3 ddddddd5 captured keep" "400 ddddddd6 proposed keep"; do
  set -- $spec; e=$(mkentry "$TRAY6" "$1" "$2" "$3") || fail "mkentry catch-up $2"
  [ "$4" = keep ] && keep="$keep $e"
done
cp -r "$TRAY6" "$TRAY6.before"
o=$(bash "$TS" sweep --no-matches 2>&1); rc=$?
intact=1; for e in $keep; do cmp -s "$e" "$TRAY6.before/$(basename "$e")" || intact=0; done
[ $rc = 0 ] && [ "$(ents "$TRAY6")" = 3 ] && [ "$(grep -c ' expired id=' "$LOG6")" = 3 ] \
  && pass "after a long silence one sweep catches up on every overdue entry (3 removed, 3 kept)" || { echo "  rc=$rc out='$o' entries=$(ents "$TRAY6")"; fail "catch-up sweep"; }
[ "$(ents "$TRAY6")" = 3 ] && [ $intact = 1 ] && pass "the entries it keeps are byte-identical — the tray is intact, not corrupted" || fail "survivors modified"
cd "$SKILL_DIR"

echo "== Behavioral: list and reject =="
# R18 + R20 + R17 + R16. The tray only pays off if a later session can judge an entry
# without opening the file, and is only safe if the one verb that deletes on purpose says
# why in the log. `list` is also the third expiry runner — the only one that fires in a
# repository nobody is capturing into.
LS=$(mktemp -d); trap 'rm -rf "$T" "$M" "$TR" "$CT" "$XP" "$LS"' EXIT

# An empty tray is an answer, not an error — and listing must create nothing, or AE12's
# "nothing written, not even the tray" stops meaning anything.
(newrepo "$LS/r7") >/dev/null 2>&1 || fail "list fixture setup"
cd "$LS/r7"; TRAY7=$(bash "$TP"); LOG7=$(bash "$TP" log)
lo=$(bash "$TS" list 2>&1); rc=$?
[ $rc = 0 ] && [ -n "$lo" ] && grep -qi 'empty' <<<"$lo" && [ ! -e "$TRAY7" ] \
  && pass "R20: an empty tray lists cleanly — exit 0, says it is empty, creates nothing" || { echo "  rc=$rc out='$lo'"; fail "empty tray does not list cleanly"; }

# The whole verification sequence: capture, list, reject, list again.
p=$(cap); i=$(fm "${p:-/nonexistent}" id)
lo=$(bash "$TS" list 2>&1); rc=$?
# Every field is demanded separately. An id-only listing satisfies "the entry is listed"
# while being useless for judging it, which is the entire point of R18. And `grep -q ""`
# matches any output at all, so each id/claim grep is guarded by its value being non-empty.
[ $rc = 0 ] && [ -n "$i" ] && grep -q "$i" <<<"$lo" && grep -qF "$CLAIM" <<<"$lo" \
  && grep -q 'track=checkable' <<<"$lo" && grep -q 'state=captured' <<<"$lo" \
  && grep -qF 'src/jobs/auth.ts' <<<"$lo" && grep -qE 'age=[0-9]+d' <<<"$lo" \
  && pass "R18: a listed entry shows its id, age, track, state, claim and match paths" || { echo "$lo"; fail "R18 listing is not enough to judge an entry"; }
REASON='the claim is already a line in AGENTS.md'
ro=$(bash "$TS" reject "$i" --reason "$REASON" 2>&1); rc=$?
# Anchored on the deletion having happened: "not logged"/"still empty" hold for free
# against a missing verb, and exit 127 with no output satisfies a bare `rc -ne 0`.
rejected() { [ -n "$i" ] && [ $rc = 0 ] && [ ! -e "${p:-/nonexistent}" ] && [ -f "$LOG7" ]; }
rejected && [ "$(ents "$TRAY7")" = 0 ] && pass "R18: reject deletes the entry it was given" || { echo "  rc=$rc out='$ro' entries=$(ents "$TRAY7")"; fail "R18 reject did not remove the entry"; }
rl=$(grep -F " rejected id=$i " "$LOG7" 2>/dev/null)
rejected && grep -qE "^- [0-9]{4}-[0-9]{2}-[0-9]{2} rejected id=$i captured=[0-9]{4}-[0-9]{2}-[0-9]{2} reason=\"$REASON\"$" <<<"$rl" \
  && pass "R18: the rejection is one log line naming the id and the reason" || { echo "  got '$rl'"; fail "R18 rejection log line shape"; }
rejected && [ "$(grep -c ' expired id=' "$LOG7")" = 0 ] \
  && pass "the rejection line does not match the expiry grep (' expired id=' counts expiries and nothing else)" || { cat "$LOG7" 2>/dev/null; fail "rejection inflates the expiry count"; }
lo2=$(bash "$TS" list 2>&1)
rejected && grep -qi 'empty' <<<"$lo2" && ! grep -q "$i" <<<"$lo2" \
  && pass "capture, list, reject, list: the entry appears, then is gone, and the tray lists clean when emptied" || { echo "$lo2"; fail "rejected entry still listed"; }

# Listing an over-age entry: it is reported AND reaped, in that order, so the operator
# reads what this listing removed instead of finding it silently gone.
(newrepo "$LS/r8") >/dev/null 2>&1 || fail "list-reaps fixture setup"
cd "$LS/r8"; TRAY8=$(bash "$TP"); LOG8=$(bash "$TP" log); mkdir -p "$TRAY8"
oldl=$(mkentry  "$TRAY8" 400 fffffff1 captured) || fail "mkentry list 400d"
propl=$(mkentry "$TRAY8" 400 fffffff2 proposed) || fail "mkentry list proposed"
cp "$propl" "$LS/proposed.before"
lo=$(bash "$TS" list 2>&1); rc=$?
reaped8() { [ $rc = 0 ] && [ ! -e "${oldl:-/nonexistent}" ] && [ -f "$LOG8" ]; }
reaped8 && grep -q fffffff1 <<<"$lo" && pass "R20: listing reports the over-age entry it reaps (it is not silently gone)" || { echo "  rc=$rc out='$lo'"; fail "R20 over-age entry not reported by the listing that reaped it"; }
rep=$(grep -n fffffff1 <<<"$lo" | head -1 | cut -d: -f1)
exp=$(grep -n '^expired' <<<"$lo" | head -1 | cut -d: -f1)
reaped8 && [ -n "$rep" ] && [ -n "$exp" ] && [ "$rep" -lt "$exp" ] \
  && pass "R20 ordering: the entry's listing block precedes the removal notice — report, then reap" || { echo "  listed at '$rep', removal notice at '$exp'"; fail "R20 ordering: report does not precede reap"; }
reaped8 && [ "$(grep -c ' expired id=' "$LOG8")" = 1 ] && grep -q 'id=fffffff1' "$LOG8" \
  && pass "R20: the reap a listing performs is logged as an expiry, once" || { cat "$LOG8" 2>/dev/null; fail "listing's reap not logged as one expiry"; }
reaped8 && grep -q fffffff2 <<<"$lo" && cmp -s "$propl" "$LS/proposed.before" \
  && pass "a proposed entry is listed and left untouched — not reaped, and not reconciled either, because it records no pull request to reconcile against" || { echo "  rc=$rc out='$lo'"; fail "proposed entry reaped or modified by list"; }
reaped8 && ! grep -q 'id=fffffff2' "$LOG8" && pass "nothing is recorded against the proposed entry" || fail "proposed entry written to the log"

# One log, two writers (the cross-unit contract): U5 records expiries, U4 records
# rejections, and each must be countable without catching the other.
e3=$(mkentry "$TRAY8" 3 fffffff3 captured) || fail "mkentry 3d for rejection"
ro=$(bash "$TS" reject fffffff3 --reason 'duplicates an existing topic line' 2>&1); rc=$?
[ $rc = 0 ] && [ ! -e "${e3:-/nonexistent}" ] && [ "$(grep -c ' expired id=' "$LOG8")" = 1 ] && [ "$(grep -c ' rejected id=' "$LOG8")" = 1 ] \
  && pass "one log, two writers: an expiry and a rejection in the same log count separately and correctly" || { echo "  rc=$rc out='$ro'"; cat "$LOG8" 2>/dev/null; fail "expiry/rejection counts collide"; }
# A reason is free text, so it is the one way a rejection could still land a line that the
# expiry grep matches.
n0=$(ents "$TRAY8"); o=$(bash "$TS" reject fffffff2 --reason 'was expired id=fffffff2 before we looked' 2>&1); rc=$?
[ $rc -ne 0 ] && grep -q '^learn: ' <<<"$o" && [ "$(ents "$TRAY8")" = "$n0" ] && [ "$(grep -c ' expired id=' "$LOG8")" = 1 ] \
  && pass "a reason that would be counted as an expiry is refused, so the expiry grep stays exact" || { echo "  rc=$rc out='$o'"; fail "reason collides with the expiry grep"; }
# Unknown id, and a rejection with no reason: both report and change nothing.
before=$(cat "$LOG8"); o=$(bash "$TS" reject deadbeef --reason 'never captured' 2>&1); rc=$?
[ $rc -ne 0 ] && grep -q '^learn: ' <<<"$o" && grep -q deadbeef <<<"$o" && [ "$(ents "$TRAY8")" = "$n0" ] && [ "$(cat "$LOG8")" = "$before" ] \
  && pass "rejecting an unknown id reports it by name and changes nothing (no entry, no log line)" || { echo "  rc=$rc out='$o'"; fail "unknown id not reported or something changed"; }
o=$(bash "$TS" reject fffffff2 2>&1); rc=$?
[ $rc -ne 0 ] && grep -q '^learn: ' <<<"$o" && [ -f "${propl:-/nonexistent}" ] && [ "$(cat "$LOG8")" = "$before" ] \
  && pass "reject without --reason refuses: deletion is permanent and the log is the only record of why" || { echo "  rc=$rc out='$o'"; fail "reject ran with no reason"; }
# The id in a listing must be the id `reject` and the log answer to — the filename's, which
# is where the sweep takes it from too. An entry whose frontmatter disagrees (hand-written,
# or copied from another) must not be listed under a name no verb accepts.
mm=$(mkentry "$TRAY8" 3 fffffff4 captured) || fail "mkentry mismatched id"
sed 's/^id: fffffff4$/id: a-different-id/' "$mm" > "$LS/mm.t" && cp "$LS/mm.t" "$mm"
lo=$(bash "$TS" list 2>&1); ro=$(bash "$TS" reject fffffff4 --reason 'the frontmatter id is a typo' 2>&1); rc=$?
grep -q '^entry fffffff4 ' <<<"$lo" && ! grep -q 'a-different-id' <<<"$lo" && [ $rc = 0 ] && [ ! -e "${mm:-/nonexistent}" ] \
  && pass "an entry is listed under the id reject and the log use (the filename's), not the one its frontmatter claims" || { echo "  rc=$rc out='$ro'"; echo "$lo"; fail "listing id disagrees with the id the verbs accept"; }
# A scan that cannot run is not a clean entry. Copy the two scripts somewhere without the
# scanner beside them: a non-zero exit with no finding must read as UNSCANNED, not silence.
mkdir -p "$LS/partial"; cp "$TS" "$TP" "$LS/partial/"
lo=$(bash "$LS/partial/tray.sh" list 2>&1); rc=$?
[ $rc = 0 ] && grep -q '^entry fffffff2 ' <<<"$lo" && grep -q 'UNSCANNED' <<<"$lo" \
  && pass "a secret scan that cannot run is reported as UNSCANNED, not read as a clean entry" || { echo "  rc=$rc out='$lo'"; fail "a failed scan is indistinguishable from a clean entry"; }

# One tray per repository: an entry captured in a linked worktree is listable from the main
# tree. This is what the shared git directory buys (and the only reason the tray lives there).
(newrepo "$LS/r9") >/dev/null 2>&1 || fail "worktree list fixture setup"
cd "$LS/r9"; git worktree add -q "$LS/r9wt" -b side >/dev/null 2>&1 || fail "worktree add"
WTCLAIM='A linked worktree and its main tree share one capture tray'
pw=$(cd "$LS/r9wt" && bash "$TS" capture --track standing --claim "$WTCLAIM" --evidence 'the tray resolves to the shared git directory' --path src/jobs/auth.ts)
iw=$(fm "${pw:-/nonexistent}" id)
lo=$(cd "$LS/r9" && bash "$TS" list 2>&1); rc=$?
[ $rc = 0 ] && [ -n "$iw" ] && [ -f "${pw:-/nonexistent}" ] && grep -q "$iw" <<<"$lo" && grep -qF "$WTCLAIM" <<<"$lo" \
  && pass "list shows an entry captured in a different worktree" || { echo "  rc=$rc pw='$pw' out='$lo'"; fail "worktree capture not listed from the main tree"; }

# R17: the capture-time scan binds only `capture`. An entry a human or a non-Claude agent
# wrote as a plain file never passed it, so every verb that READS the tray scans what it
# reads and reports findings masked — and a finding on read deletes nothing.
(newrepo "$LS/r10") >/dev/null 2>&1 || fail "plain-file secret fixture setup"
cd "$LS/r10"; TRAY10=$(bash "$TP"); LOG10=$(bash "$TP" log); mkdir -p "$TRAY10"
tok3="gh""p_$(printf 'X%.0s' $(seq 1 36))"
hs=$(mkentry "$TRAY10" 3 9999999a captured) || fail "mkentry secret entry"
printf 'The failing request carried %s in its header.\n' "$tok3" >> "$hs"
lo=$(bash "$TS" list 2>&1); rc=$?
# Anchored on the report: "the entry is still there" and "nothing was logged" both hold
# against a list that never scanned anything at all.
reported() { grep -q 'BLOCK token' <<<"$lo" && grep -q 9999999a <<<"$lo"; }
[ $rc = 0 ] && reported && pass "R17: a secret in a hand-written entry is reported on list (exit $rc)" || { echo "  rc=$rc out='$lo'"; fail "R17 secret in a plain-file entry went unreported"; }
reported && ! grep -qF "$tok3" <<<"$lo" && pass "R17: the finding is reported masked" || fail "R17 the finding was echoed unmasked"
reported && [ -f "$hs" ] && [ "$(ents "$TRAY10")" = 1 ] && pass "R16: a finding on read does not delete the entry — deletion is reject's alone" || fail "R17 list deleted the entry it flagged"
reported && [ ! -e "$LOG10" ] && pass "a finding on read records nothing in the tray log" || { cat "$LOG10" 2>/dev/null; fail "finding written to the log"; }

# "Exactly that entry" needs a sibling whose id shares a prefix: with one entry in the
# tray, a glob-happy match deletes the right file for the wrong reason and nothing notices
# (it survived as a mutant until this was written).
s1=$(mkentry "$TRAY10" 3 7777777  captured) || fail "mkentry prefix id"
s2=$(mkentry "$TRAY10" 3 77777770 captured) || fail "mkentry prefix sibling"
cp "$s2" "$LS/sibling.before"
ro=$(bash "$TS" reject 7777777 --reason 'the path it names no longer exists' 2>&1); rc=$?
[ $rc = 0 ] && [ ! -e "${s1:-/nonexistent}" ] && [ -f "${s2:-/nonexistent}" ] && cmp -s "$s2" "$LS/sibling.before" \
  && [ "$(grep -c ' rejected id=7777777 ' "$LOG10")" = 1 ] && ! grep -q ' rejected id=77777770 ' "$LOG10" \
  && pass "R18: reject removes exactly the entry named — a sibling whose id shares its prefix is untouched" || { echo "  rc=$rc out='$ro'"; fail "reject matched more than the id it was given"; }

# R16: a filter declining an entry at one promotion is "not yet", so the entry stays
# listable. Only reject is permanent, and the two outcomes must not look alike.
d1=$(mkentry "$TRAY10" 3 9999999b captured) || fail "mkentry declined"
cp "$d1" "$LS/declined.before"
l1=$(bash "$TS" list 2>&1); l2=$(bash "$TS" list 2>&1)
# `still` is the snapshot of the two listings taken while the entry was only declined, so
# it keeps meaning after the rejection deletes the file.
still() { grep -q 9999999b <<<"$l1" && grep -q 9999999b <<<"$l2"; }
still && [ -f "${d1:-/nonexistent}" ] && cmp -s "$d1" "$LS/declined.before" \
  && pass "R16: an entry no verb rejected is still listable, byte-identical, after a later listing (declining is 'not yet')" || { echo "  l2='$l2'"; fail "R16 a declined entry did not survive"; }
ro=$(bash "$TS" reject 9999999b --reason 'the claim is wrong: the guard does read the body' 2>&1); rc=$?
l3=$(bash "$TS" list 2>&1)
still && [ $rc = 0 ] && [ ! -e "${d1:-/nonexistent}" ] && ! grep -q 9999999b <<<"$l3" && grep -q ' rejected id=9999999b ' "$LOG10" \
  && pass "R16: rejection is the permanent half — the same entry is gone from the listing and the log says why" || { echo "  rc=$rc out='$ro'"; fail "R16 rejection is not distinct from declining"; }
cd "$SKILL_DIR"

echo "== Behavioral: the proposed state and reconciliation (KTD4, AE8) =="
# `state: proposed` is exempt from expiry, and the dwell in a pull request has no upper
# bound — so the exemption is only safe if something later reconciles the entry against
# that pull request. The signal is git and nothing else (R18's verbs must work with no
# forge tooling): the recorded head branch is either still on the remote or it is gone.
PM=$(mktemp -d); trap 'rm -rf "$T" "$M" "$TR" "$CT" "$XP" "$LS" "$PM"' EXIT
pmrepo() { # <dir> -> <dir>/w: a clone, on main, of a real <dir>/origin.git
  git init -q --bare "$1/origin.git"
  git init -q "$1/seed"
  git -C "$1/seed" config user.email t@t; git -C "$1/seed" config user.name t
  git -C "$1/seed" checkout -q -b main
  mkdir -p "$1/seed/docs/topics" "$1/seed/src/jobs"
  printf 'Read docs/topics/x.md\n' > "$1/seed/AGENTS.md"
  printf 'topics\n' > "$1/seed/docs/topics/x.md"
  printf 'export function handler(req){ return ok(req) }\n' > "$1/seed/src/jobs/auth.ts"
  git -C "$1/seed" add -A; git -C "$1/seed" commit -qm init
  git -C "$1/seed" remote add origin "$1/origin.git"; git -C "$1/seed" push -q -u origin main
  git clone -q "$1/origin.git" "$1/w"
  git -C "$1/w" config user.email t@t; git -C "$1/w" config user.name t
}
EV='the guard returns before the body is read'

# AE8 — the trimmed line. A reviewer deletes one of three lines from the promotion PR and
# merges. Two entries are consumed; the third must come back, not vanish and not stay
# exempt forever. This is the one data-loss path with no signal anywhere, so it is built
# before the happy path.
(pmrepo "$PM/ae8") >/dev/null 2>&1 || fail "AE8 fixture setup"
cd "$PM/ae8/w"; TRAY_A=$(bash "$TP"); LOG_A=$(bash "$TP" log)
C1='A scheduled-job route behind a bare header check rejects every caller'
C2='The importer is idempotent because the queue redelivers on timeout'
C3='A squash merge leaves the branch commit unreachable from the default branch'
pa=$(bash "$TS" capture --track standing --claim "$C1" --evidence "$EV" --path src/jobs/auth.ts)
pb=$(bash "$TS" capture --track standing --claim "$C2" --evidence "$EV" --path src/jobs/auth.ts)
pc=$(bash "$TS" capture --track standing --claim "$C3" --evidence "$EV" --path src/jobs/auth.ts)
ia=$(fm "${pa:-/nonexistent}" id); ib=$(fm "${pb:-/nonexistent}" id); ic=$(fm "${pc:-/nonexistent}" id)
age_entry() { # <path> <days-ago> -> the same entry with its clock (the filename) moved back
  local d n; d=$(daysago "$2") || return 1
  n="${1%/*}/entry-$d-$(fm "$1" id).md"
  sed "s/^captured_on: .*/captured_on: ${d:0:4}-${d:4:2}-${d:6:2}/" "$1" > "$n" && rm "$1" && printf '%s\n' "$n"
}
# The entry the reviewer will trim is given a real age, well inside the window. Captured
# today it would be indistinguishable from one whose clock a promotion silently reset —
# and the reset is the bug KTD4 is about.
pc=$(age_entry "$pc" 30) || fail "AE8: age_entry needs BSD date -v or GNU date -d"
cp "$pc" "$PM/ae8-c.captured" 2>/dev/null
po=$(bash "$TS" propose "$ia" "$ib" "$ic" --branch learn/tray-1 --pr '#7' 2>&1); rc=$?
prop3() { [ $rc = 0 ] && [ -n "$ia$ib$ic" ] && grep -q '^state: proposed$' "${pa:-/nonexistent}" \
  && grep -q '^state: proposed$' "${pb:-/nonexistent}" && grep -q '^state: proposed$' "${pc:-/nonexistent}"; }
prop3 && [ "$(fm "$pa" pr_branch)" = learn/tray-1 ] && [ "$(fm "$pa" pr_ref)" = '#7' ] \
  && pass "a promoted entry is marked proposed with the pull request it sits in (branch + reference)" || { echo "  rc=$rc out='$po'"; fail "propose did not record the pull request"; }
prop3 && [ "$(ents "$TRAY_A")" = 3 ] && pass "propose renames nothing and deletes nothing — three entries, same three files" || fail "propose moved or removed an entry"
git push -q origin HEAD:learn/tray-1 2>/dev/null || fail "AE8 branch push"
cp "$pa" "$PM/ae8-a.open" 2>/dev/null

# KTD4: while the head branch is still on the remote the claim is absent from the default
# branch for the whole review — reading the table's `proposed` row without that
# precondition demotes every staged entry on the first listing after a promotion.
lo=$(bash "$TS" list 2>&1); rc=$?
# Anchored on the listing having actually asked about the branch: "still proposed" is also
# what a list that never reconciled at all would leave behind.
asked() { [ $rc = 0 ] && grep -q 'learn/tray-1' <<<"$lo"; }
asked && cmp -s "$pa" "$PM/ae8-a.open" && grep -q '^state: proposed$' "${pc:-/nonexistent}" && [ "$(ents "$TRAY_A")" = 3 ] \
  && pass "KTD4: a listing while the pull request is still open leaves every entry proposed, clock frozen" || { echo "  rc=$rc out='$lo'"; fail "KTD4: an open pull request demoted or changed its entries"; }

# The merge, with one of the three lines trimmed out by the reviewer, and the head branch
# deleted the way a forge deletes it on merge.
printf -- '- %s (learn)\n- %s (learn)\n' "$C1" "$C2" >> docs/topics/x.md
git add -A >/dev/null 2>&1; git commit -qm 'learn: two of the three lines' >/dev/null 2>&1
git push -q origin main 2>/dev/null || fail "AE8 merge push"
git push -q origin --delete learn/tray-1 2>/dev/null || fail "AE8 branch delete"
lo=$(bash "$TS" list 2>&1); rc=$?
gone2() { [ $rc = 0 ] && [ -n "$ia$ib" ] && [ ! -e "${pa:-/nonexistent}" ] && [ ! -e "${pb:-/nonexistent}" ] && [ -f "${LOG_A:-/nonexistent}" ]; }
gone2 && [ "$(grep -c ' consumed id=' "$LOG_A")" = 2 ] && grep -q " consumed id=$ia " "$LOG_A" && grep -q " consumed id=$ib " "$LOG_A" \
  && pass "AE8: the two lines that survived the trim are consumed, each recorded once" || { echo "  rc=$rc out='$lo'"; cat "$LOG_A" 2>/dev/null; fail "AE8: surviving lines not consumed"; }
gone2 && [ -f "${pc:-/nonexistent}" ] && [ "$(ents "$TRAY_A")" = 1 ] \
  && pass "AE8: the tray is left holding exactly the trimmed entry — not empty" || { echo "  entries=$(ents "$TRAY_A")"; fail "AE8: the trimmed entry was lost with the other two"; }
# Byte-identical to the file capture wrote: same filename (so the same capture date), same
# captured_on, state back to captured, no pull-request fields left behind. That is the
# whole of "returns to captured with its clock untouched", in one comparison.
gone2 && cmp -s "$pc" "$PM/ae8-c.captured" \
  && pass "AE8: the trimmed entry is byte-identical to its capture — back to captured, clock untouched" || { diff "$PM/ae8-c.captured" "$pc" 2>&1 | head -8; fail "AE8: the returned entry is not its captured self"; }
gone2 && [ "$(grep -c ' expired id=' "$LOG_A")" = 0 ] && [ "$(grep -c ' rejected id=' "$LOG_A")" = 0 ] \
  && pass "AE8: consumption takes its own word in the shared log — it inflates neither count" || { cat "$LOG_A"; fail "AE8: consumption counted as an expiry or a rejection"; }
lo2=$(bash "$TS" list 2>&1)
gone2 && grep -q "$ic" <<<"$lo2" && grep -q 'state=captured' <<<"$lo2" && ! grep -q "$ia" <<<"$lo2" \
  && pass "AE8: the returned entry lists as captured again, so a later session can promote it" || { echo "$lo2"; fail "AE8: the returned entry is not listable as captured"; }

# Reconciliation is wired into all three runners. Expiry already exempts `state: proposed`,
# so a runner that does not reconcile leaves an entry exempt FOREVER — shipping the
# exemption without the reconciler is the one combination that leaks entries permanently.
# Each runner is proved on its own fixture: a shared one cannot tell which runner acted.
RC='A retry without a jittered backoff turns one timeout into a thundering herd'
runner_fixture() { # <dir> -> the entry path, proposed, its branch merged and deleted
  pmrepo "$1" >/dev/null 2>&1 || return 1
  cd "$1/w" || return 1
  local p i
  p=$(bash "$TS" capture --track standing --claim "$RC" --evidence "$EV" --path src/jobs/auth.ts) || return 1
  i=$(fm "$p" id)
  bash "$TS" propose "$i" --branch learn/r-1 --pr '#9' >/dev/null 2>&1
  git push -q origin HEAD:learn/r-1 2>/dev/null || return 1
  printf -- '- %s\n' "$RC" >> docs/topics/x.md
  git add -A >/dev/null 2>&1; git commit -qm merged >/dev/null 2>&1
  git push -q origin main 2>/dev/null || return 1
  git push -q origin --delete learn/r-1 2>/dev/null || return 1
  printf '%s\n' "$p"
}
for runner in list capture promote; do
  # The fixture runs in a command substitution, so its `cd` does not reach here.
  rp=$(runner_fixture "$PM/rc-$runner") || { fail "reconcile-runner fixture ($runner)"; continue; }
  cd "$PM/rc-$runner/w" || { fail "reconcile-runner cwd ($runner)"; continue; }
  RLOG=$(bash "$TP" log)
  case $runner in
    list)    bash "$TS" list >/dev/null 2>&1;;
    capture) bash "$TS" capture --track standing --claim 'An unrelated lesson, captured later' --evidence "$EV" --path src/jobs/auth.ts >/dev/null 2>&1;;
    promote) bash "$TS" promote --event merge >/dev/null 2>&1;;
  esac
  # Both halves demanded: the entry gone AND the consumption recorded. "Still proposed" is
  # what an unwired runner leaves, and an entry that merely disappeared is a different bug.
  [ -n "$rp" ] && [ ! -e "$rp" ] && grep -q ' consumed id=' "$RLOG" 2>/dev/null \
    && pass "reconciliation runs on \`$runner\`: a merged, branch-deleted entry is consumed by it alone" || { echo "  entry='$rp'"; fail "reconciliation is not wired into $runner"; }
done

# Fail-closed. Consumption deletes, so every signal it cannot get must leave the entry
# alone rather than guess: an unreachable remote, and an entry marked proposed by hand
# with no pull request recorded at all.
(newrepo "$PM/r11") >/dev/null 2>&1 || fail "fail-closed fixture setup"
cd "$PM/r11"; TRAY_B=$(bash "$TP"); LOG_B=$(bash "$TP" log); mkdir -p "$TRAY_B"
nb=$(mkentry "$TRAY_B" 3 8888888a proposed) || fail "mkentry no-branch"
cp "$nb" "$PM/nb.before"
lo=$(bash "$TS" list 2>&1); rc=$?
# Anchored on the surface line, not on "nothing changed": an unwired reconciler changes
# nothing either, and that pair of assertions would pass against no reconciler at all.
[ $rc = 0 ] && grep -q 'no pull request is recorded' <<<"$lo" && [ -f "$nb" ] && cmp -s "$nb" "$PM/nb.before" && [ ! -e "$LOG_B" ] \
  && pass "an entry marked proposed with no pull request recorded is surfaced and left exactly as it is" || { echo "  rc=$rc out='$lo'"; fail "a proposed entry with no recorded pull request was changed or went unsurfaced"; }
ub=$(mkentry "$TRAY_B" 3 8888888b proposed) || fail "mkentry unreachable-remote"
printf 'pr_branch: "learn/nowhere"\npr_ref: "#1"\n' >> "$ub"   # appended after the body: still readable by the same reader
cp "$ub" "$PM/ub.before"
lo=$(bash "$TS" list 2>&1); rc=$?
# Same anchor: the branch name only reaches the output if reconciliation read the field
# and tried to ask the remote about it.
[ $rc = 0 ] && grep -q 'learn/nowhere' <<<"$lo" && [ -f "$ub" ] && cmp -s "$ub" "$PM/ub.before" && [ ! -e "$LOG_B" ] \
  && pass "no remote to ask: nothing is consumed and nothing is demoted (reconciliation fails closed)" || { echo "  rc=$rc out='$lo'"; fail "reconciliation acted without being able to ask the remote, or never asked"; }
cd "$SKILL_DIR"

echo "== Behavioral: promotion routes by track, and evidence resolves first =="
# Every promotion event evaluates EVERY entry: the track selects the gate, not the
# trigger. Each track must therefore promote on its own event and on no other, and the
# entries that do not promote must be surfaced rather than quietly dropped.
(pmrepo "$PM/rt") >/dev/null 2>&1 || fail "routing fixture setup"
cd "$PM/rt/w"; TRAY_R=$(bash "$TP"); LOG_R=$(bash "$TP" log)
# A squash merge, which is what makes a cited commit unreachable as a matter of routine.
(set -e
 git checkout -q -b squashed
 printf 'export function guard(req){ return req.headers.get("x-internal") }\n' >> src/jobs/auth.ts
 git add -A; git commit -qm 'the guard'
 git rev-parse HEAD > "$PM/sq"
 git checkout -q main; git merge -q --squash squashed; git commit -qm 'squash: the guard'
 git push -q origin main; git branch -q -D squashed) >/dev/null 2>&1 || fail "squash fixture"
SQ=$(cat "$PM/sq" 2>/dev/null)
git merge-base --is-ancestor "${SQ:-HEAD}" origin/main 2>/dev/null && fail "squash fixture: the cited commit is still reachable, so AE9 would prove nothing"
mk() { bash "$TS" capture "$@"; }
pk=$(mk --track checkable --claim 'A scheduled-job route behind a bare header check rejects the scheduler' --evidence "$EV" --path src/jobs/auth.ts)
pg=$(mk --track checkable --claim 'The legacy importer swallowed every error it could not parse' --evidence 'the importer caught and dropped the parse failure' --path src/legacy/importer.ts)
pb=$(mk --track checkable --claim 'The admin route rejects an authenticated caller with 500' --evidence 'the handler reads the body before the guard runs' --path src/jobs/auth.ts)
ps=$(mk --track checkable --claim 'The guard must read the header before the body' --evidence "commit $SQ added the guard on the branch" --path src/jobs/auth.ts)
pdy=$(mk --track decision --accepted true --claim 'Chose the queue over a cron route for retries' --evidence 'a cron route cannot retry a single failed run' --path src/jobs/auth.ts)
pdn=$(mk --track decision --accepted false --claim 'Considered a second datastore and did not adopt it' --evidence 'two writers leave no authority over the same row' --path src/jobs/auth.ts)
pst=$(mk --track standing --claim 'Reviewers read the diff, not the spec it came from' --evidence 'nothing in the tree settles this' --path src/jobs/auth.ts)
k_ok=$(fm "${pk:-/nonexistent}" id);  k_gone=$(fm "${pg:-/nonexistent}" id); k_bad=$(fm "${pb:-/nonexistent}" id)
k_sq=$(fm "${ps:-/nonexistent}" id);  d_yes=$(fm "${pdy:-/nonexistent}" id); d_no=$(fm "${pdn:-/nonexistent}" id)
s_1=$(fm "${pst:-/nonexistent}" id)
[ "$(ents "$TRAY_R")" = 7 ] && [ -n "$k_ok$k_gone$k_bad$k_sq$d_yes$d_no$s_1" ] && pass "routing fixture: seven entries, one per cell of the table" || fail "routing fixture entries"
cp "$pb" "$PM/rt-bad.before" 2>/dev/null
CONTRA='the route now returns 401 and the guard runs before the body'

po=$(bash "$TS" promote --event merge --confirms "$k_ok" --confirms "$k_sq" --contradicts "$k_bad=$CONTRA" 2>/dev/null); rc=$?
# Anchored on the run having produced a report at all: every `grep -q` below is satisfied
# by nothing when the output is empty, and `rc` alone cannot tell a refusal from a crash.
ran() { [ $rc = 0 ] && grep -q '^promoted=' <<<"$po"; }
ran && grep -q "^promote id=$k_ok track=checkable event=merge evidence=confirms dest=AGENTS.md " <<<"$po" \
  && grep -A1 "^promote id=$k_ok " <<<"$po" | grep -q '^  line: .*src/jobs/auth.ts' \
  && pass "AE2: a merge promotes a checkable entry whose evidence resolves, with its file reference attached" || { echo "  rc=$rc"; echo "$po"; fail "AE2: confirmed checkable entry not promoted"; }
ran && grep -q "^promote id=$k_sq track=checkable event=merge evidence=re-anchored dest=" <<<"$po" \
  && pass "AE9: a cited commit a squash merge made unreachable is re-anchored through the entry's paths, and promotes" || { echo "$po"; fail "AE9: squashed-away commit not re-anchored"; }
ran && grep -q "^promote id=$s_1 track=standing event=merge evidence=skipped dest=docs/topics/jobs.md " <<<"$po" \
  && grep -A1 "^promote id=$s_1 " <<<"$po" | grep -q '^  line: .*asserted' \
  && pass "AE11: a standing entry promotes into docs/topics/, flagged asserted" || { echo "$po"; fail "AE11: standing entry misrouted"; }
# The distinguishing half: in this very run the instruction file had the headroom and a
# checkable entry went into it. So "standing went to topics" is the track's doing, not the
# budget's — with one entry in the fixture the two are indistinguishable.
ran && ! grep -q "^promote id=$s_1 .*dest=AGENTS.md" <<<"$po" && grep -q "dest=AGENTS.md" <<<"$po" \
  && pass "AE11: standing never reaches the instruction file, in a run where another entry did" || { echo "$po"; fail "AE11: standing/instruction-file separation is untested"; }
ran && grep -q "^staged id=$k_bad track=checkable evidence=contradicts contradiction=\"$CONTRA\" " <<<"$po" \
  && pass "a checkable entry whose evidence contradicts its claim is surfaced with the contradiction named" || { echo "$po"; fail "contradiction not surfaced by name"; }
# The debugging case: the entry was staged against a broken route and this is the merge
# that fixed it. Deleting on contradiction would reap the lesson at the moment it became
# worth keeping, so the file has to come through untouched.
ran && [ -f "${pb:-/nonexistent}" ] && cmp -s "$pb" "$PM/rt-bad.before" && [ ! -e "$LOG_R" ] \
  && pass "R16: the contradicted entry stays in the tray, byte-identical — nothing is deleted and nothing is logged" || { fail "R16: the fix for the bug reaped the lesson about it"; }
ran && grep -q "^staged id=$k_gone track=checkable evidence=unresolvable " <<<"$po" \
  && pass "R16: evidence that cannot be resolved is surfaced and left staged, distinct from one that contradicts" || { echo "$po"; fail "unresolvable evidence not surfaced"; }
ran && grep -q "^promote id=$d_yes track=decision event=merge evidence=exempt dest=docs/decisions/" <<<"$po" \
  && pass "a decision whose acceptance is recorded promotes at a merge event" || { echo "$po"; fail "accepted decision not promoted at a merge"; }
ran && grep -q "^staged id=$d_no track=decision reason=no-acceptance-recorded" <<<"$po" \
  && pass "a decision with no recorded acceptance stays staged through a merge event" || { echo "$po"; fail "unaccepted decision promoted by a merge"; }
ran && [ "$(ents "$TRAY_R")" = 7 ] && [ "$(fm "$pk" state)" = captured \
  ] && pass "promotion itself writes nothing: seven entries in, seven out, all still captured" || fail "promote mutated the tray"
ran && grep -q 'ONE DRAFT pull request and never merge it here' <<<"$po" \
  && pass "the promotion report ends in a draft pull request the skill never merges" || { echo "$po"; fail "promotion does not say draft/never-merge"; }

# The same tray, the other event. Each track must promote on its own event and on no other.
po2=$(bash "$TS" promote --event decision-acceptance --confirms "$k_ok" --confirms "$k_sq" --contradicts "$k_bad=$CONTRA" 2>/dev/null); rc=$?
ran2() { [ $rc = 0 ] && grep -q '^promoted=' <<<"$po2"; }
ran2 && grep -q "^promote id=$d_yes track=decision event=decision-acceptance evidence=exempt dest=docs/decisions/" <<<"$po2" \
  && pass "an already-accepted decision promotes at an acceptance event too" || { echo "$po2"; fail "accepted decision not promoted at an acceptance event"; }
ran2 && grep -q "^promote id=$d_no track=decision event=decision-acceptance evidence=exempt dest=docs/decisions/" <<<"$po2" \
  && pass "AE3: a decision-track entry promotes as a decision record at an acceptance event, with no merge in existence" || { echo "$po2"; fail "AE3: decision entry did not promote on its own event"; }
ran2 && grep -q "^promote id=$k_ok track=checkable event=decision-acceptance evidence=confirms dest=AGENTS.md " <<<"$po2" \
  && pass "a checkable entry already true in the default branch promotes at a decision-acceptance event (its gate is a condition, not an event)" || { echo "$po2"; fail "checkable entry gated on the merge event"; }
ran2 && grep -q "^promote id=$s_1 track=standing event=decision-acceptance evidence=skipped dest=docs/topics/" <<<"$po2" \
  && pass "a standing entry promotes on either event, always to docs/topics/" || { echo "$po2"; fail "standing entry gated on an event"; }
ran2 && grep -q "^promote id=$k_sq track=checkable event=decision-acceptance evidence=re-anchored dest=" <<<"$po2" \
  && pass "re-anchoring is not an event's doing either: the squashed-away citation promotes on both events" || { echo "$po2"; fail "re-anchored entry gated on the merge event"; }
ran2 && grep -q "^staged id=$k_bad .*evidence=contradicts" <<<"$po2" && grep -q "^staged id=$k_gone .*evidence=unresolvable" <<<"$po2" \
  && pass "neither failed-evidence entry promotes on the other event either — the evidence gate is not an event gate" || { echo "$po2"; fail "a failed-evidence entry promoted on a decision-acceptance event"; }

# R16/KTD7: the refusal. `standing` skips the evidence step entirely, so re-routing an
# entry whose evidence just failed onto it would promote it on the strength of the step
# that refused it. The attempt is refused, not disclosed.
for bad in "$k_gone=standing" "$k_bad=standing"; do
  o=$(bash "$TS" promote --event merge --confirms "$k_ok" --confirms "$k_sq" --contradicts "$k_bad=$CONTRA" --as "$bad" 2>&1); rc=$?
  [ $rc -ne 0 ] && grep -q '^learn: ' <<<"$o" && grep -q "${bad%%=*}" <<<"$o" && ! grep -q '^promote id=' <<<"$o" \
    && pass "a failed-evidence entry cannot be re-routed onto standing (${bad%%=*}): the attempt is refused, and nothing promotes" || { echo "  rc=$rc out='$o'"; fail "re-routing ${bad%%=*} onto standing was allowed or merely disclosed"; }
done
# The control that makes the refusal mean something: an override IS allowed, and disclosed,
# when the evidence step did not refuse the entry. Without this, refusing every --as passes.
o=$(bash "$TS" promote --event merge --confirms "$k_ok" --confirms "$k_sq" --contradicts "$k_bad=$CONTRA" --as "$k_ok=standing" 2>/dev/null); rc=$?
[ $rc = 0 ] && grep -q "^promote id=$k_ok track=checkable->standing event=merge evidence=confirms dest=docs/topics/" <<<"$o" \
  && pass "an override of the routing hint is honoured and disclosed when the evidence resolved" || { echo "  rc=$rc out='$o'"; fail "every override is refused, so the refusal proves nothing"; }
# Evidence resolves before the track routes, so promotion cannot run until the session
# says what it found — and must not demand a verdict for the entry nothing resolved for.
o=$(bash "$TS" promote --event merge 2>&1); rc=$?
[ $rc -ne 0 ] && grep -q '^learn: ' <<<"$o" && grep -q "$k_ok" <<<"$o" && grep -q "$k_sq" <<<"$o" && grep -q "$k_bad" <<<"$o" \
  && ! grep -q "$k_gone" <<<"$o" && ! grep -q '^promote id=' <<<"$o" \
  && pass "promotion refuses until the evidence verdict is stated for every checkable entry that resolved — and asks for none where nothing resolved" || { echo "  rc=$rc out='$o'"; fail "promotion routed checkable entries with no verdict"; }
o=$(bash "$TS" promote --event merge --confirms "$k_ok" --confirms "$k_sq" --confirms "$s_1" --contradicts "$k_bad=$CONTRA" 2>&1); rc=$?
[ $rc -ne 0 ] && grep -q '^learn: ' <<<"$o" && grep -q "$s_1" <<<"$o" \
  && pass "a verdict offered for a track the evidence step does not apply to is refused, not quietly applied" || { echo "  rc=$rc out='$o'"; fail "standing entry accepted an evidence verdict"; }

# R17 at promotion time: a secret introduced AFTER capture (capture's scan cannot have
# seen it) excludes that entry alone. Aborting the batch would let one poisoned entry
# block every later lesson indefinitely.
tok5="gh""p_$(printf 'W%.0s' $(seq 1 36))"
printf 'The failing request carried %s in its header.\n' "$tok5" >> "$pk"
po3=$(bash "$TS" promote --event merge --confirms "$k_ok" --confirms "$k_sq" --contradicts "$k_bad=$CONTRA" 2>/dev/null); rc=$?
ex() { [ $rc = 0 ] && grep -q "^excluded id=$k_ok reason=secret-finding" <<<"$po3"; }
ex && grep -q 'BLOCK token' <<<"$po3" && ! grep -qF "$tok5" <<<"$po3" && grep -qi 'rotate the credential' <<<"$po3" \
  && pass "R17: a secret introduced after capture excludes that entry by id, masked, with a rotate-the-credential instruction" || { echo "  rc=$rc"; echo "$po3"; fail "R17: promotion-time finding not excluded or not masked"; }
ex && grep -q "^promote id=$s_1 " <<<"$po3" && grep -q "^promote id=$d_yes " <<<"$po3" \
  && pass "R17: the rest of the batch still promotes — one poisoned entry does not block every later one" || { echo "$po3"; fail "R17: one finding aborted the whole promotion"; }
ex && [ -f "$pk" ] && pass "R17: the excluded entry is not deleted (only reject deletes)" || fail "R17: promotion deleted the entry it flagged"

# Promotion is the third expiry runner, and the matched set is what this event resolved.
# Same age, same track, one difference: whether this promotion resolved against it.
(pmrepo "$PM/sw") >/dev/null 2>&1 || fail "promotion-sweep fixture setup"
cd "$PM/sw/w"; TRAY_S=$(bash "$TP"); LOG_S=$(bash "$TP" log)
oa=$(mk --track checkable --claim 'The retired importer logged nothing on a parse failure' --evidence 'the importer caught and dropped it' --path src/legacy/importer.ts)
ob=$(mk --track checkable --claim 'The admin route rejects an authenticated caller with 500' --evidence 'the handler reads the body before the guard runs' --path src/jobs/auth.ts)
oa=$(age_entry "$oa" 400) || fail "age_entry unresolvable"
ob=$(age_entry "$ob" 400) || fail "age_entry contradicted"
ib=$(fm "${ob:-/nonexistent}" id)
po4=$(bash "$TS" promote --event merge --contradicts "$ib=$CONTRA" 2>/dev/null); rc=$?
swept4() { [ $rc = 0 ] && [ -n "$ib" ] && [ ! -e "${oa:-/nonexistent}" ] && [ -f "${LOG_S:-/nonexistent}" ]; }
swept4 && grep -q ' expired id=' "$LOG_S" \
  && pass "promotion is the third expiry runner: an over-age entry it could not resolve ages out, logged" || { echo "  rc=$rc out='$po4'"; fail "promotion did not sweep"; }
swept4 && [ -f "${ob:-/nonexistent}" ] && ! grep -q "id=$ib" "$LOG_S" \
  && pass "KTD5 at promotion: the contradicted entry, the same age, is matched by this event and survives its sweep" || { cat "$LOG_S" 2>/dev/null; fail "the sweep reaped the entry this promotion had just resolved against"; }

# The instruction file's word budget. Overflow is the NORMAL path — an always-loaded file
# sits at its limit — so the surprise worth testing is a promotion that fits.
(pmrepo "$PM/bud") >/dev/null 2>&1 || fail "budget fixture setup"
cd "$PM/bud/w"
yes word | head -397 | tr '\n' ' ' > AGENTS.md
[ "$(wc -w < AGENTS.md | tr -d ' ')" = 397 ] || fail "budget fixture: AGENTS.md is not 397 words"
pbu=$(mk --track checkable --claim 'A scheduled-job route behind a bare header check rejects the scheduler' --evidence "$EV" --path src/jobs/auth.ts)
ibu=$(fm "${pbu:-/nonexistent}" id)
po5=$(bash "$TS" promote --event merge --confirms "$ibu" 2>/dev/null); rc=$?
[ $rc = 0 ] && [ -n "$ibu" ] && grep -q "^promote id=$ibu .*dest=docs/topics/jobs.md reason=instruction-file-over-budget(AGENTS.md=397w" <<<"$po5" \
  && pass "a lesson that would push the instruction file over its budget routes to docs/topics/ and the report says so, with the count" || { echo "  rc=$rc out='$po5'"; fail "budget overflow not routed or not stated"; }
po6=$(bash "$TS" promote --event merge --confirms "$ibu" --budget 100000 2>/dev/null); rc=$?
# The same entry, the same instruction file: only the budget differs. Without this pair,
# "it went to topics" is indistinguishable from a router that never looks at the budget.
[ $rc = 0 ] && grep -q "^promote id=$ibu .*dest=AGENTS.md reason=fits-the-instruction-file-budget(397w" <<<"$po6" \
  && pass "the same lesson under a budget it fits goes into the instruction file — the budget is what moved it" || { echo "  rc=$rc out='$po6'"; fail "the router does not read the budget"; }
cd "$SKILL_DIR"

echo "== Differential: one durable-store state, three producers (R5) =="
# R5 says every check on the durable store's content validates FILE STATE ALONE: the same
# state passes or fails identically whether a human, this skill, or another agent produced
# it. The hygiene lint near the top of this file cannot test that — a search of SKILL.md
# for harness-specific strings only shows that nothing NAMES a harness, never that a check
# ignores who wrote the file, and a skill that ran nowhere at all would pass it. So the
# proof is a differential: one state, built three ways, read by the same four checks, with
# the exit codes and the output compared byte for byte.
#
# The three producers are independent paths, not three calls to one function:
#   skill — `tray.sh capture` writes the entry; `tray.sh promote` prints the line and the
#           session appends it, which is the documented flow.
#   hand  — no verb is ever invoked in that repository: `mkdir` plus `printf` write the
#           entry and a here-document appends the line. A human with an editor.
#   sed   — a stream editor rewrites a DIFFERENT entry already on disk into the target and
#           `mv`s it into place (a new inode), and inserts the line with `sed '$a\'`. An
#           agent editing files it did not create and cannot call the verbs for.
# The three states end up byte-identical on purpose, and that is asserted with `cmp`
# before any check runs. What differs is everything AROUND the bytes: which process made
# them, in what order, whether the tray was created by `capture` or by `mkdir`, mtimes,
# inodes, and whether the verbs ever ran in that clone at all. That is exactly the
# provenance R5 forbids a check from consulting, and the author-awareness mutant (a
# sidecar `capture` writes and `list` reads) turns this section red when one does.
DF=$(mktemp -d); trap 'rm -rf "$T" "$M" "$TR" "$CT" "$XP" "$LS" "$PM" "$DF"' EXIT
DFDATE='2001-02-03T04:05:06+0000'
DCLAIM='A scheduled-job route behind a bare header check rejects every caller that cannot set the header'
DEV='the guard returns before the body is read'
DSPEC='specs/feat/slices/01.md'
# ONE origin, cloned three times, with the commit dates pinned: the three repositories
# share a history byte for byte, so any difference in a check's output can only have come
# from the producer.
(set -e
 git init -q --bare "$DF/origin.git"
 git init -q "$DF/seed"; cd "$DF/seed"
 git config user.email t@t; git config user.name t; git checkout -q -b main
 mkdir -p docs/topics src/jobs "${DSPEC%/*}"
 printf 'Read docs/topics/x.md\n' > AGENTS.md
 printf 'topics\n' > docs/topics/x.md
 printf 'export function handler(req){ return ok(req) }\n' > src/jobs/auth.ts
 printf 'the slice spec\n' > "$DSPEC"
 git add -A
 GIT_AUTHOR_DATE=$DFDATE GIT_COMMITTER_DATE=$DFDATE git commit -qm init
 git remote add origin "$DF/origin.git"; git push -q -u origin main) >/dev/null 2>&1 || fail "differential: origin fixture"
# Each producer gets its OWN copy of that one origin. Sharing a remote made the second
# clone start from the first producer's pushed line, which is how the first red run of
# this section reported three states of 30, 58 and 86 words rather than three of 30.
dclone() { cp -R "$DF/origin.git" "$1.git" && git clone -q "$1.git" "$1" >/dev/null 2>&1 \
  && git -C "$1" config user.email t@t && git -C "$1" config user.name t; }
# Applying the line, committing and pushing is the same for all three: the producer is who
# writes the content, which is what R5 is about.
dcommit() { git add -A >/dev/null 2>&1 \
  && GIT_AUTHOR_DATE=$DFDATE GIT_COMMITTER_DATE=$DFDATE git commit -qm 'apply the promoted lesson' >/dev/null 2>&1 \
  && git push -q origin main >/dev/null 2>&1 && git checkout -q -b learn/1 >/dev/null 2>&1; }
dcheck() { local lbl=$1 o rc; shift; o=$("$@" 2>&1); rc=$?; printf '## %s rc=%s\n%s\n' "$lbl" "$rc" "$o"; }
# Every check that reads the durable store, in one blob. The repository path and the merge
# sha are the two things that are a property of the clone rather than of its content, so
# they are the only things normalised — the path in both the plain and the /private form
# macOS resolves a temp dir to.
dblob() { # <repo> <verify budget> [retire path...] -> the whole check set, normalised
  local r=$1 bud=$2 sha; shift 2
  cd "$r" || return 1
  sha=$(git rev-parse HEAD)
  { dcheck list    /bin/bash "$TS" list
    dcheck promote /bin/bash "$TS" promote --event merge --confirms "$DID"
    dcheck redact  /bin/bash "$SKILL_DIR/scripts/redact-scan.sh" AGENTS.md docs/topics/x.md
    dcheck verify  env BASE="$sha^1" /bin/bash "$SKILL_DIR/scripts/verify.sh" "$sha" main "$bud" "$@"
  } | sed -e "s|/private$r|<REPO>|g" -e "s|$r|<REPO>|g" -e "s|$sha|<SHA>|g"
}
# PRODUCER 1 — the skill.
dclone "$DF/skill" || fail "differential: skill clone"
cd "$DF/skill"
pA=$(bash "$TS" capture --track checkable --claim "$DCLAIM" --evidence "$DEV" --path src/jobs/auth.ts --path "$DSPEC" 2>&1) || fail "differential: capture ($pA)"
DID=$(fm "${pA:-/nonexistent}" id)
DLINE=$(bash "$TS" promote --event merge --confirms "${DID:-x}" 2>/dev/null | sed -n 's/^  line: //p' | head -1)
[ -n "$DID" ] && [ -n "$DLINE" ] || fail "differential: no id or no line to apply (id='${DID:-}')"
printf '%s\n' "$DLINE" >> AGENTS.md
dcommit || fail "differential: skill commit"
DBASE=${pA##*/}; DD=${DBASE#entry-}; DD=${DD%%-*}
DCAP="${DD:0:4}-${DD:4:2}-${DD:6:2}"
# PRODUCER 2 — a hand edit. No verb is invoked in this clone at all.
dclone "$DF/hand" || fail "differential: hand clone"
cd "$DF/hand"
mkdir -p "$(bash "$TP")" || fail "differential: hand tray"
pB=$(bash "$TP" entry "$DID")
{ printf -- '---\n'; printf 'id: %s\n' "$DID"
  printf 'claim: "%s"\n' "$DCLAIM"
  printf 'evidence: "%s"\n' "$DEV"
  printf 'paths:\n  - "src/jobs/auth.ts"\n  - "%s"\n' "$DSPEC"
  printf 'captured_on: %s\n' "$DCAP"
  printf 'track: checkable\nstate: captured\nverified: false\n'; printf -- '---\n'; } > "$pB"
cat >> AGENTS.md <<DLEOF
$DLINE
DLEOF
dcommit || fail "differential: hand commit"
# PRODUCER 3 — a stream editor, transforming state already on disk.
dclone "$DF/sed" || fail "differential: sed clone"
cd "$DF/sed"
mkdir -p "$(bash "$TP")" || fail "differential: sed tray"
DEC=$(bash "$TP" entry 0decoy00)
{ printf -- '---\n'; printf 'id: 0decoy00\n'
  printf 'claim: "An abandoned exploration left the guard half-written"\n'
  printf 'evidence: "nothing in the repository resolves this"\n'
  printf 'paths:\n  - "src/jobs/auth.ts"\n  - "%s"\n' "$DSPEC"
  printf 'captured_on: %s\n' "$DCAP"
  printf 'track: standing\nstate: captured\nverified: false\n'; printf -- '---\n'; } > "$DEC"
pC=$(bash "$TP" entry "$DID")
sed -e "s|^id: .*|id: $DID|" -e "s|^claim: .*|claim: \"$DCLAIM\"|" \
    -e "s|^evidence: .*|evidence: \"$DEV\"|" -e "s|^track: .*|track: checkable|" "$DEC" > "$DF/sed.entry" \
  && mv "$DF/sed.entry" "$pC" && rm -f "$DEC" || fail "differential: sed entry producer"
sed -e "\$a\\
$DLINE" AGENTS.md > "$DF/sed.agents" && mv "$DF/sed.agents" AGENTS.md || fail "differential: sed line producer"
dcommit || fail "differential: sed commit"
cd "$SKILL_DIR"
# The states are identical before any check runs, and non-trivially so: a non-empty entry
# carrying the claim, and an instruction file carrying the promoted line. Three empty
# files are also "identical", and that pair must not read as a pass.
dsame() { [ -s "$1" ] && cmp -s "$1" "$2" && cmp -s "$1" "$3"; }
dsame "$pA" "${pB:-/nonexistent}" "${pC:-/nonexistent}" && grep -qF "$DCLAIM" "$pA" \
  && [ "${pA##*/}" = "${pB##*/}" ] && [ "${pA##*/}" = "${pC##*/}" ] \
  && dsame "$DF/skill/AGENTS.md" "$DF/hand/AGENTS.md" "$DF/sed/AGENTS.md" && grep -qF -- "$DLINE" "$DF/skill/AGENTS.md" \
  && pass "the skill, a hand edit and a stream editor leave byte-identical state — same entry filename, same entry bytes, same instruction file" \
  || { for z in "$pA" "$pB" "$pC"; do echo "  $z"; done; diff "$pA" "${pB:-/dev/null}" | head -6; diff "$DF/skill/AGENTS.md" "$DF/sed/AGENTS.md" | head -6; fail "the three producers did not leave the same state"; }
DVS=$(dblob "$DF/skill" 400); DVH=$(dblob "$DF/hand" 400); DVD=$(dblob "$DF/sed" 400)
DFS=$(dblob "$DF/skill" 10 "$DSPEC"); DFH=$(dblob "$DF/hand" 10 "$DSPEC"); DFD=$(dblob "$DF/sed" 10 "$DSPEC")
cd "$SKILL_DIR"
# Anchored on what only a working implementation emits. Three blobs that are empty, or
# three that died identically at `exit 127`, are also "identical output" — which is how a
# differential passes while testing nothing.
danchor() {
  grep -q "^entry $DID  age=0d  track=checkable  state=captured\$" <<<"$1" \
  && grep -qF "  claim: $DCLAIM" <<<"$1" \
  && grep -q "^promote id=$DID track=checkable event=merge evidence=confirms dest=AGENTS.md " <<<"$1" \
  && grep -qF "  line: $DLINE" <<<"$1" \
  && grep -qx 'CLEAN' <<<"$1" \
  && [ "$(grep -c '^## [a-z]* rc=' <<<"$1")" = 4 ]
}
dok()  { danchor "$1" && grep -qx 'PASS' <<<"$1" && [ "$(grep -c '^## [a-z]* rc=0$' <<<"$1")" = 4 ]; }
dbad() { danchor "$1" && grep -qx '## verify rc=1' <<<"$1" \
  && grep -qE "^FAIL  AGENTS\.md[[:space:]]+30 words > 10\$" <<<"$1" \
  && grep -qx "FAIL  live link to retired $DSPEC:" <<<"$1" \
  && grep -q "^AGENTS.md:2:- $DCLAIM " <<<"$1" && grep -qx 'VERIFY FAILED' <<<"$1"; }
[ "$DVS" = "$DVH" ] && [ "$DVS" = "$DVD" ] && dok "$DVS" \
  && pass "R5: one valid state, three producers — every check returns the same exit code and the same output" \
  || { diff <(printf '%s\n' "$DVS") <(printf '%s\n' "$DVH") | head -10; diff <(printf '%s\n' "$DVS") <(printf '%s\n' "$DVD") | head -10; dok "$DVS" || printf '%s\n' "$DVS" | head -20; fail "R5: the valid state is not read identically across producers"; }
# The must-fail arm. Without it the differential could pass with every producer green, and
# a check that is author-aware only on the failure path — the path where it matters, since
# that is the one that blocks a push — would never be touched.
[ "$DFS" = "$DFH" ] && [ "$DFS" = "$DFD" ] && dbad "$DFS" \
  && pass "R5: one INVALID state (over budget, live link to a retired spec), three producers — the same failure, the same message, the same exit code" \
  || { diff <(printf '%s\n' "$DFS") <(printf '%s\n' "$DFH") | head -10; diff <(printf '%s\n' "$DFS") <(printf '%s\n' "$DFD") | head -10; dbad "$DFS" || printf '%s\n' "$DFS" | head -24; fail "R5: the invalid state is not refused identically across producers"; }
# The two arms have to be telling the states apart, or both differentials are comparing one
# blob with itself twice and neither says anything about valid versus invalid.
[ "$DVS" != "$DFS" ] && dok "$DVS" && dbad "$DFS" \
  && pass "the valid and invalid arms are distinguishable: the same producer's state passes one check set and fails the other" || fail "the valid and invalid blobs are indistinguishable"

echo "== R13: every verb is a plain command (bare shell, no harness env, no forge CLI) =="
# R13 says every capture and promotion step is invocable as a plain command, with a harness
# hook as an optional accelerant. What that claims is testable only by taking the harness
# away: the verbs run under `env -i` with nothing but PATH, HOME and TZ, and with no forge
# CLI anywhere on PATH.
#
# The bare PATH is built by symlinking the real PATH MINUS the forge tools rather than by
# listing what to include. A hand-written include list that forgot `od` or `tr` would make
# every assertion below fail at exit 127, which is indistinguishable from a verb that needs
# a harness — and "it failed" is not what this section is trying to show.
DBIN="$DF/bin"; DHOME="$DF/home"; mkdir -p "$DBIN" "$DHOME"
printf '%s\n' "$PATH" | tr ':' '\n' | while IFS= read -r d; do
  [ -n "$d" ] && [ -d "$d" ] || continue
  for f in "$d"/*; do
    [ -f "$f" ] && [ -x "$f" ] || continue
    case ${f##*/} in gh|glab|hub|tea|git-pr|forgejo) continue;; esac
    [ -e "$DBIN/${f##*/}" ] || ln -s "$f" "$DBIN/${f##*/}" 2>/dev/null
  done
done
# TZ is pinned in BOTH arms: it is not harness state, and an arm that disagreed with the
# other about what day it is would report a different `age=` and fail for nothing.
dbare() { env -i TZ=UTC PATH="$DBIN" HOME="$DHOME" /bin/bash "$@"; }
dharn() { env TZ=UTC CLAUDECODE=1 CLAUDE_CODE_ENTRYPOINT=cli CLAUDE_PLUGIN_ROOT=plugins GROK_BOT_SESSION=1 CURSOR_TRACE_ID=x /bin/bash "$@"; }
# Both halves demanded. "No harness variables are set" is true for free in a bare terminal,
# so the harness arm has to be shown actually carrying them, or the comparison below is
# between two identical environments.
nh=$(dharn -c env | grep -cE '^(CLAUDECODE|CLAUDE_|GROK_|CURSOR_|ANTHROPIC_)')
nb=$(dbare -c env | grep -cE '^(CLAUDECODE|CLAUDE_|GROK_|CURSOR_|ANTHROPIC_)')
[ "$nh" -ge 5 ] && [ "$nb" = 0 ] && pass "the two arms really differ: $nh harness variables set in one, $nb in the other" || fail "the harness and bare arms did not differ in environment ($nh vs $nb)"
bgit=$(dbare -c 'command -v git || true'); bgh=$(dbare -c 'command -v gh || true')
[ -n "$bgit" ] && [ -z "$bgh" ] && pass "no forge CLI on PATH, and the PATH is not merely empty (git resolves)" || { echo "  git='$bgit' gh='$bgh'"; fail "the bare PATH is empty or still carries a forge CLI"; }
dclone "$DF/bare" || fail "bare-shell clone"
cd "$DF/bare"
bp=$(dbare "$TS" capture --track checkable --claim "$DCLAIM" --evidence "$DEV" --path src/jobs/auth.ts 2>&1); rc=$?
[ $rc = 0 ] && [ -f "${bp:-/nonexistent}" ] && grep -qF "$DCLAIM" "$bp" \
  && pass "capture is a plain command: no harness environment, no forge CLI, and the entry it printed is on disk" || { echo "  rc=$rc out='$bp'"; fail "capture needs a harness or a forge CLI"; }
bid=$(fm "${bp:-/nonexistent}" id)
lh=$(dharn "$TS" list 2>&1); rch=$?
lb=$(dbare "$TS" list 2>&1); rcb=$?
[ $rch = 0 ] && [ "$rch" = "$rcb" ] && [ "$lh" = "$lb" ] && [ -n "$bid" ] && grep -q "^entry $bid  age=0d " <<<"$lb" \
  && pass "Claude Code parity is machine-verified here: one state, listed under the harness and under a bare shell, identical exit code and output" || { echo "  rc=$rch/$rcb"; diff <(printf '%s\n' "$lh") <(printf '%s\n' "$lb") | head -8; fail "listing differs with and without the harness"; }
ph=$(dharn "$TS" promote --event merge --confirms "$bid" 2>&1); rch=$?
pb=$(dbare "$TS" promote --event merge --confirms "$bid" 2>&1); rcb=$?
[ $rch = 0 ] && [ "$rch" = "$rcb" ] && [ "$ph" = "$pb" ] && grep -q "^promote id=$bid .*dest=AGENTS.md " <<<"$pb" && grep -qF '  line: - ' <<<"$pb" \
  && pass "the promotion step is a plain command too: the same routing and the same line to apply, with no harness and no forge CLI" || { echo "  rc=$rch/$rcb"; diff <(printf '%s\n' "$ph") <(printf '%s\n' "$pb") | head -8; fail "promotion differs with and without the harness, or needs forge tooling"; }
# `propose` is the step most likely to reach for a forge CLI — it records a pull request —
# so it is the one worth running with no such tool on PATH at all.
po=$(dbare "$TS" propose "$bid" --branch learn/bare-1 --pr '#7' 2>&1); rc=$?
[ $rc = 0 ] && grep -q '^state: proposed$' "$bp" && grep -qF 'learn/bare-1' "$bp" \
  && pass "recording the pull request needs no forge tooling either: propose marks the entry from a bare shell" || { echo "  rc=$rc out='$po'"; fail "propose needs forge tooling"; }
cd "$SKILL_DIR"

echo "== R13 / KTD12: the Grok Bot parity record =="
# KTD12 keeps Grok Bot parity an OPEN item owned by Grok Bot, with a dated manual record
# as the interim evidence. Three things have to hold of that record, each falsifiable on
# its own:
#   - it carries a real ISO date for when a human last reviewed it. Its absence fails;
#   - it states when the procedure was last RUN BY HAND in one of exactly two shapes — an
#     ISO date, or the literal NOT-YET-RUN. Prose ("recently", "see above", "n/a") fails,
#     because an undated run claim is indistinguishable from an invented one, and KTD12's
#     whole point is that the interim must be honest today;
#   - the pair must agree: NOT-YET-RUN requires `status: open`, and a run date requires a
#     status that is not open. It fails from either side, so it cannot be satisfied by
#     dropping the harder half — writing a date without having run it still has to pass a
#     status change a reader would see.
HN=references/harness-notes.md
ISO='^[0-9][0-9][0-9][0-9]-\(0[1-9]\|1[0-2]\)-\(0[1-9]\|[12][0-9]\|3[01]\)$'
gsec=$(awk '/^### Grok Bot parity/{f=1;next} f&&/^##/{exit} f' "$HN")
gval() { printf '%s\n' "$gsec" | sed -n "s/^- $1: //p" | head -1; }
gdate=$(gval 'record last reviewed'); grun=$(gval 'procedure last run by hand'); gstat=$(gval status)
[ -n "$gsec" ] && grep -q "$ISO" <<<"$gdate" \
  && pass "the Grok Bot record carries a date it was last reviewed on ($gdate)" || { echo "  section=$([ -n "$gsec" ] && echo present || echo MISSING) date='$gdate'"; fail "the Grok Bot record carries no reviewed-on date"; }
case $grun in
  NOT-YET-RUN*) pass "the record says plainly that the manual procedure has not been run ('$grun')";;
  *) grep -q "$ISO" <<<"$grun" && pass "the record dates the last hand-run of the procedure ($grun)" \
       || { echo "  run field='$grun'"; fail "the hand-run field is neither an ISO date nor the literal NOT-YET-RUN"; };;
esac
case $grun in
  NOT-YET-RUN*) [ "$gstat" = open ] && pass "KTD12: an unrun procedure leaves parity marked open (status: $gstat)" || { echo "  status='$gstat'"; fail "the procedure has never been run and parity is not marked open"; };;
  '') fail "no hand-run field at all: there is nothing for the status to agree with";;
  *) [ -n "$gstat" ] && [ "$gstat" != open ] && pass "a hand-run procedure carries a status a reader can see ($gstat)" || { echo "  status='$gstat'"; fail "a dated hand-run still marked open"; };;
esac
# The factual question the plan names and nobody here can answer. Recorded as open, not
# resolved: if Grok Bot's shell does not share a git directory with the user's clone, the
# tray resolves somewhere else entirely and the entries never meet.
printf '%s\n' "$gsec" | grep -q '^- open question: .*git directory' \
  && pass "the unanswered question (does Grok Bot's shell share the clone's git directory?) is recorded as open" || fail "the open git-directory question is not recorded"
# The claim R13 makes about Claude Code is that parity is MACHINE-verified, so the record
# has to say which check verifies it rather than asserting it in prose.
printf '%s\n' "$gsec" | grep -qF 'tests/eval.sh' \
  && pass "the record cites the check that machine-verifies the other harness, not prose" || fail "the record cites no machine check"

echo ""
[ $SKIP -gt 0 ] && echo "NOT A CLEAN RESULT: $SKIP check(s) did not run — see the SKIP line(s) above"
echo "PASS: $PASS  FAIL: $FAIL  SKIP: $SKIP"
[ $FAIL -eq 0 ]
