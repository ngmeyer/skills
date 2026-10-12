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
for r in memory-import lesson-filter dedupe-staleness spec-retirement pr-template multi-agent harness-notes telemetry-followup sources; do
  [ -f references/$r.md ] && pass "reference $r.md" || fail "reference $r.md missing"
done
for x in verify redact-scan memory-triage; do [ -x scripts/$x.sh ] && pass "scripts/$x.sh executable" || fail "$x.sh not executable"; done
for k in "Mode: from-memories" "Redact gate" "Not for repo" "One draft PR per repo" "never prune them yourself" "Read-only"; do chk "from-memories: $k" "$k"; done

echo "== Portability (core is harness-agnostic) =="
lines=$(wc -l < SKILL.md); [ "$lines" -le 250 ] && pass "SKILL.md $lines lines" || fail "SKILL.md $lines lines"
bytes=$(wc -c < SKILL.md); [ "$bytes" -le 16000 ] && pass "SKILL.md $bytes bytes (<=16k)" || fail "SKILL.md $bytes bytes"
body_dash=$(awk 'NR>1 && /^---$/{c++} END{print c+0}' SKILL.md)
[ "$body_dash" -eq 1 ] && pass "no bare --- in body" || fail "bare --- lines in body: $((body_dash-1))"
# The body is what every harness reads as instructions, so that is what must stay
# harness-agnostic. Frontmatter is per-harness metadata each one parses or ignores:
# `user-invocable`/`allowed-tools` is what makes this a slash command in Claude Code.
body=$(awk 'NR>1 && /^---$/{f=1;next} f' SKILL.md)
if grep -nE '~/\.claude|\.claude/|\.cursor/|allowed-tools|/Users/|/home/[a-z]|\bgh (pr|api)\b|Bash\(|AskUserQuestion' <<<"$body"; then fail "harness-specific token in core"; else pass "no harness-specific tokens in core"; fi
grep -qE '^user-invocable: true' SKILL.md && pass "slash-invocable in Claude Code" || fail "no user-invocable: true"
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

echo "== Behavioral: from-memories on fixture memories =="
cd "$SKILL_DIR"
M=$(mktemp -d); trap 'rm -rf "$T" "$M"' EXIT
cp -r tests/fixtures/repo "$M/app"; R=$(cd "$M/app" && pwd)
E=$(printf '%s' "$R" | sed -E 's/[^A-Za-z0-9]/-/g')
mkdir -p "$M/home/.claude/projects/$E/memory" "$M/grok"
cp tests/fixtures/memories/project.md "$M/home/.claude/projects/$E/memory/project.md"
cp tests/fixtures/memories/global.md "$M/home/.claude/CLAUDE.md"
sed "s#__REPO__#$R#" tests/fixtures/memories/grok-export.txt > "$M/grok/export.txt"
# secret is assembled at runtime so no token-shaped string is ever committed
tok="gh""p_$(printf 'Z%.0s' $(seq 1 36))"
printf -- "- Staging deploy uses %s\n- Escalate to %s\n" "$tok" "ops.lead@""corp-mail.io" > "$M/grok/secret.txt"
cp -r "$M/home" "$M/home.before"
PM="$M/home/.claude/projects/$E/memory/project.md"
map=$(scripts/memory-triage.sh map "$R" -- "$PM" "$M/home/.claude/CLAUDE.md" "$M/grok/export.txt")
grep -qE "project.md[[:space:]]$R$" <<<"$map" && pass "map: Claude project memory -> repo (encoded path)" || { echo "$map"; fail "map project"; }
grep -qE "CLAUDE.md[[:space:]]global$" <<<"$map" && pass "map: global CLAUDE.md -> global" || fail "map global"
grep -qE "export.txt[[:space:]]$R$" <<<"$map" && pass "map: plain-text export with project: header -> repo" || fail "map export"
tri=$(scripts/memory-triage.sh triage "$R" "$PM")
grep -qE '^CANDIDATE[[:space:]].*Scheduled job routes' <<<"$tri" && pass "triage: durable lesson is CANDIDATE" || { echo "$tri"; fail "candidate"; }
grep -qE '^STALE[[:space:]].*legacy importer' <<<"$tri" && pass "triage: missing path -> STALE" || fail "stale"
grep -qE '^DUPLICATE[[:space:]].*npm run verify' <<<"$tri" && pass "triage: AGENTS.md duplicate -> DUPLICATE" || fail "dup AGENTS.md"
grep -qE '^NOT-FOR-REPO[[:space:]].*I prefer tabs' <<<"$tri" && pass "triage: personal line -> NOT-FOR-REPO" || fail "personal"
scripts/memory-triage.sh triage "$R" "$M/grok/export.txt" | grep -qE '^DUPLICATE[[:space:]].*idempotent' && pass "triage: docs/topics duplicate -> DUPLICATE" || fail "dup topics"
scripts/memory-triage.sh triage global "$M/home/.claude/CLAUDE.md" | grep -qE '^NOT-FOR-REPO[[:space:]].*British' && pass "triage: global item -> NOT-FOR-REPO" || fail "global item"
# One-fact-per-file memories have no bullets at all: the lesson is the frontmatter
# description, so a bullet-only read reports an empty file and imports nothing.
ff=$(scripts/memory-triage.sh triage "$R" tests/fixtures/memories/project-frontmatter.md)
grep -qE '^CANDIDATE[[:space:]].*\[type:feedback\].*equalize its error reasons' <<<"$ff" && pass "triage: frontmatter description -> CANDIDATE with type" || { echo "$ff"; fail "frontmatter fact"; }
uf=$(scripts/memory-triage.sh triage "$R" tests/fixtures/memories/user-frontmatter.md)
[ -z "$(grep -v '^NOT-FOR-REPO' <<<"$uf")" ] && [ -n "$uf" ] && pass "triage: type:user takes the whole file (body included)" || { echo "$uf"; fail "user-type file"; }
printf -- '- grep CLAUDE.md for `https://.*:.*@` before committing\n' | scripts/redact-scan.sh - >/dev/null && pass "redact: documented credential pattern is not a credential" || fail "pattern read as credential"
out=$(scripts/memory-triage.sh triage "$R" "$M/grok/secret.txt"); rc=$?
[ $rc -ne 0 ] && grep -q '^BLOCKED-SECRET.*\[token\]' <<<"$out" && grep -q '^BLOCKED-SECRET.*\[email\]' <<<"$out" && pass "triage: token + email BLOCK (exit $rc)" || { echo "$out"; fail "secret not blocked"; }
grep -qF "$tok" <<<"$out" && fail "secret echoed unmasked" || pass "blocked output is masked"
grep -q CANDIDATE <<<"$out" && fail "lines from secret file leaked as candidates" || pass "secret file contributes no candidates"
echo "key: AKIA$(printf 'Q%.0s' $(seq 1 16))" | scripts/redact-scan.sh - >/dev/null && fail "AWS key passed" || pass "redact: AWS key blocks (stdin/diff mode)"
printf -- "- %s = %s\n" "pass""word" "hunter2""hunter2" | scripts/redact-scan.sh - >/dev/null && fail "password assignment passed" || pass "redact: key=value assignment blocks"
printf -- "- call %s\n" "415-555-""2671" | scripts/redact-scan.sh - >/dev/null && fail "phone passed" || pass "redact: phone blocks"
printf -- "- contact dev@example.com, 555-0123\n" | scripts/redact-scan.sh - >/dev/null && pass "redact: allowlisted example email/555-01xx pass" || fail "allowlist"
scripts/redact-scan.sh tests/fixtures/memories/*.md tests/fixtures/repo/AGENTS.md >/dev/null && pass "committed fixtures are clean" || fail "fixtures contain secrets"
diff -r "$M/home" "$M/home.before" >/dev/null && pass "source memories untouched (read-only)" || fail "source memories modified"

echo ""; echo "PASS: $PASS  FAIL: $FAIL"
[ $FAIL -eq 0 ]
