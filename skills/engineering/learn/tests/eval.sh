#!/usr/bin/env bash
# Structural + behavioral eval for learn.
# Structural: design contract in SKILL.md (+ portability across harnesses).
# Behavioral: scripts/verify.sh against a scratch git repo with a fake
# rebase-merged multi-commit PR (needs git; no network).
# Usage: bash tests/eval.sh   Exit 0 on pass, 1 on any failure.
set -u
cd "$(dirname "$0")/.."
SKILL_DIR=$(pwd)
PASS=0; FAIL=0
pass() { echo "PASS  $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL  $1"; FAIL=$((FAIL+1)); }
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
for r in lesson-filter dedupe-staleness spec-retirement pr-template multi-agent harness-notes telemetry-followup sources; do
  [ -f references/$r.md ] && pass "reference $r.md" || fail "reference $r.md missing"
done
[ -x scripts/verify.sh ] && pass "scripts/verify.sh executable" || fail "verify.sh not executable"

echo "== Portability (core is harness-agnostic) =="
lines=$(wc -l < SKILL.md); [ "$lines" -le 250 ] && pass "SKILL.md $lines lines" || fail "SKILL.md $lines lines"
bytes=$(wc -c < SKILL.md); [ "$bytes" -le 16000 ] && pass "SKILL.md $bytes bytes (<=16k)" || fail "SKILL.md $bytes bytes"
body_dash=$(awk 'NR>1 && /^---$/{c++} END{print c+0}' SKILL.md)
[ "$body_dash" -eq 1 ] && pass "no bare --- in body" || fail "bare --- lines in body: $((body_dash-1))"
if grep -nE '~/\.claude|\.claude/|\.cursor/|allowed-tools|/Users/|/home/[a-z]|\bgh (pr|api)\b|Bash\(|AskUserQuestion' SKILL.md; then fail "harness-specific token in core"; else pass "no harness-specific tokens in core"; fi
LEAK=0
for term in signupspark swim-records ourgospelstudy voltron localcred superscore pithybyte gearu verowrite portolan ponytail /workspace; do
  grep -rqiF "$term" SKILL.md references/ scripts/ && { echo "  leak: $term"; LEAK=1; }
done
[ $LEAK = 0 ] && pass "no internal names" || fail "internal names present"

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

echo ""; echo "PASS: $PASS  FAIL: $FAIL"
[ $FAIL -eq 0 ]
