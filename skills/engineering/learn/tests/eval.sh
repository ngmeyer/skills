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
for x in verify redact-scan memory-triage tray-path tray; do [ -x scripts/$x.sh ] && pass "scripts/$x.sh executable" || fail "$x.sh not executable"; done
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

echo ""; echo "PASS: $PASS  FAIL: $FAIL"
[ $FAIL -eq 0 ]
