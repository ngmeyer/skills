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
# R7/R18/R20 reachable from the instructions, not only from the scripts: an agent whose
# session produced no merge stops at step 1 unless step 1 routes it onward, and the mode it
# lands in has to name all three tray verbs.
# The heading pin carries its `##`: the step-1 pointer names the mode too, so a bare
# "Mode: no-merge capture" passes with the section itself deleted — it did, as a mutant.
for k in "nothing merged" "## Mode: no-merge capture" "scripts/tray.sh capture --track" "scripts/tray.sh list" "scripts/tray.sh reject <id> --reason" "stays listable"; do
  chk "no-merge mode: $k" "$k"
done

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
  && pass "a proposed entry is listed and left untouched — neither reaped nor reconciled (reconciliation is not this unit's)" || { echo "  rc=$rc out='$lo'"; fail "proposed entry reaped or modified by list"; }
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

echo ""; echo "PASS: $PASS  FAIL: $FAIL"
[ $FAIL -eq 0 ]
