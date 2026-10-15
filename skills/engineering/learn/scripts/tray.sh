#!/usr/bin/env bash
# learn — the capture tray's verbs. A session that produces no merge (debugging,
# planning, exploring) stages its lessons here, so a later session — another week,
# another worktree — can select, read and judge them.
#
#   tray.sh capture --track <decision|checkable|standing>
#                   --claim "<the lesson, one line>"
#                   --evidence "<content citation, one line>"
#                   --path <repo-relative path> [--path ...]
#                   [--accepted true|false]   # required iff --track decision
#     Writes one entry and prints its path. Creates the tray if this is the first
#     capture. Writes nothing anywhere else: no commit, no staging, no file in the
#     working tree.
#
#   tray.sh list
#     Prints every entry — id, age, track, state, claim, match paths — so an entry can be
#     judged without opening the file. An empty tray says so and is not an error. Scans
#     the entries it reads and reports findings masked, deleting nothing. Runs the expiry
#     sweep after printing, so an entry past the window is reported and then reaped.
#
#   tray.sh reject <id> --reason "<why>"
#     Deletes that one entry and appends the reason to the tray log. The only verb that
#     deletes on purpose. An unknown id is reported and nothing changes.
#
#   tray.sh sweep (--no-matches | --matched <id> [--matched <id>]...)
#     Expires entries past the window and records each removal in the tray log. Prints
#     nothing on stdout. Creates nothing — no tray, no log — until there is a removal to
#     record, so a sweep is invisible in a repository nobody has captured into.
#
#   tray.sh promote --event <merge|decision-acceptance>
#                   [--confirms <id>]...
#                   [--contradicts <id>="<what the default branch says instead>"]...
#                   [--as <id>=<track>]...        # a disclosed override of the routing hint
#                   [--budget <words>] [--instruction-file <path>]
#     Evaluates EVERY entry and prints one routing line each — promote / staged / excluded
#     / held — with the line it would add and where. It WRITES NOTHING: the session applies
#     the lines, re-scans the staged diff, commits, opens ONE DRAFT pull request it never
#     merges, and records it with `propose`.
#
#   tray.sh propose <id> [<id>...] --branch <head branch> --pr <reference>
#     Marks each promoted entry `state: proposed` with the pull request it now sits in.
#     The filename never changes, so the capture date — the expiry clock — is untouched.
#
# Paths come from tray-path.sh and nowhere else, so there is one tray per repository.
#
# EXPIRY — lazy, and ordered after matching
# The sweep is the only runner there is: a scheduled workflow is forbidden here and the
# hook may not be installed, so expiry happens on the verbs or it does not happen. It runs
# on capture, on listing and on promotion. Listing is in that set because it is the
# discovery path, and therefore the only runner that fires in a repository nobody is
# capturing into — a tray with no runner does not expire slowly, it does not expire at all.
#
# The MATCHED SET IS AN ARGUMENT, and stating it is mandatory: a caller passes the ids this
# invocation matched, or `--no-matches` to say there were none. A sweep cannot run before
# matching is settled, because it cannot run without its outcome. That is what keeps the
# order match -> filter -> prune: an over-age entry whose proof arrived in this very
# invocation is promoted by the caller, never reaped by the sweep that the same event ran.
# Were the matched set optional, forgetting it would read as "nothing matched" and the
# sweep would delete exactly the entry that had just been earned.
#
# Every removal is recorded in the tray log (`tray-path.sh log`), one line, never rewritten:
#   - <swept-date> expired id=<id> age=<days>d captured=<date> reason=<reason>
# so `grep ' expired id=' <log>` counts removals and nothing else.
#
# THE TRAY LOG IS SHARED, AND THE VERB IS WHAT DISTINGUISHES THE WRITER. The sweep writes
# `expired`, reject writes `rejected`, and a later verb writes its own word — never another
# verb's, or that verb's count silently inflates. The same rule is why no writer may add a
# header line that another writer's grep would match (the first version of this file's
# header restated the expiry format and was counted as an expiry). Reject's line is
#   - <rejection-date> rejected id=<id> captured=<date> reason="<why>"
# and the free-text reason is checked against the expiry grep before the line is appended:
# the reason is the one field a caller controls, so it is the one way a rejection could
# still land a line that counts as an expiry.
#
# The window is eight weeks (56 days), counted from the entry's capture date, which leaves
# a three-week-old entry real margin. An entry is expired once it is OLDER than the window,
# so it survives the full eight weeks.
#
# `state: proposed` is exempt: its lesson is sitting in a pull request the writing session
# will not merge itself, and that dwell has no upper bound. The exemption is only safe
# because the same three runners reconcile a proposed entry against its pull request —
# without that, exempt means permanent.
#
# RECONCILIATION — the precondition that makes that exemption safe, on all three runners
# The signal is git and nothing else: `propose` records the pull request's HEAD BRANCH, and
# reconciliation asks the remote whether that branch is still there. R18's verbs must work
# with no forge tooling, so there is no API call to make and no status to read.
#   - branch still on the remote -> leave `proposed`, clock frozen. This precondition is
#     the whole of it: a merged claim is ABSENT from the default branch for as long as the
#     pull request is open, so reading "absent -> return to captured" without first asking
#     about the branch demotes every staged entry on the first runner after a promotion —
#     restarting the expiry clock mid-dwell and letting one lesson promote twice.
#   - branch gone, claim present in the default branch -> consumed: the entry is removed
#     and the removal is logged as `consumed`, its own word, never another verb's.
#   - branch gone, claim absent -> a reviewer trimmed that line out of the pull request.
#     The entry returns to `captured` with its clock UNTOUCHED (the filename, which carries
#     the capture date, is never rewritten) so the next session can promote it again. Two
#     of three lines merging must not take the third with them.
# Every signal it cannot get leaves the entry alone: no recorded branch, an unreachable
# remote, an unresolvable default branch. Consumption deletes, so it never guesses.
#
# ROUTING — what `promote` decides, and in what order
# EVERY promotion event evaluates EVERY entry: the track selects the gate, not the trigger.
# EVIDENCE RESOLVES BEFORE THE TRACK ROUTES, and that order is load-bearing. `standing`
# skips the evidence step entirely and `decision` is exempt from it, so routing first and
# resolving second would let a `checkable` entry whose evidence just failed be re-routed
# onto `standing` and promoted on the strength of the step that refused it. The override
# is therefore refused for such an entry, not merely disclosed.
#   checkable, evidence confirms                   -> promote (the gate is a condition, not
#                                                     an event: both events open it)
#   checkable, evidence unresolvable               -> re-anchor against the entry's paths;
#                                                     if that fails too, SURFACE and leave
#                                                     staged. Never deleted, never expired
#                                                     quietly into nothing.
#   checkable, evidence contradicts the claim      -> surface with the contradiction NAMED,
#                                                     leave staged. Nothing here can tell a
#                                                     claim that was always false from one
#                                                     the merge just fixed, and the merge
#                                                     most likely to touch a bug's paths is
#                                                     the fix for it — deleting on
#                                                     contradiction would reap the entry at
#                                                     the moment it became worth keeping.
#   decision                                       -> a merge does not accept a decision:
#                                                     promote on a merge only if acceptance
#                                                     is recorded, and on a decision-
#                                                     acceptance event as a decision record.
#   standing                                       -> promote to docs/topics/, flagged
#                                                     ASSERTED, never into the instruction
#                                                     file, on either event.
# Destination: a `checkable` lesson goes to the instruction file only if it FITS the word
# budget. Assume it does not — an instruction file at its limit is the normal case, not the
# exception — in which case it goes to docs/topics/ and the report says so. A lesson is
# never silently dropped and the budget is never silently blown.
# A secret found in an entry at promotion time excludes ONLY that entry, by id, masked,
# with a rotate-the-credential instruction; the rest of the batch promotes. Aborting the
# whole promotion would let one poisoned entry block every later one indefinitely.
#
# ENTRY SCHEMA — YAML frontmatter in a Markdown file. Free text is double-quoted
# (backslash and quote escaped); the constrained fields are bare. All required:
#   id           8 hex chars, generated. Also in the filename, which is what makes two
#                captures in the same second collision-free — so it is never derived
#                from the clock.
#   claim        the lesson, one line.
#   evidence     the content citation behind the claim, one line. A commit identifier is
#                never evidence on its own: a squash-merge leaves a branch commit
#                unreachable from the default branch as a matter of routine.
#   paths        repo-relative paths the claim is about, in the order given, and with NO
#                line numbers: paths are the match key and survive edits, line numbers
#                are evidence and do not.
#   captured_on  the capture date, read back out of the filename so one date can never
#                disagree with the other.
#   track        decision | checkable | standing. A ROUTING HINT, which the promoting
#                session may override and must disclose — never a claim that the lesson
#                is true. Choose `decision` when the lesson settles a choice against a
#                rejected alternative; else `checkable` when the claim can be resolved
#                against the default branch; else `standing`. The capturing session
#                chooses, so two sessions filing one lesson do not file it two ways.
#   state        captured (what capture writes) | proposed (a promoted entry).
#   verified     always false at capture: nothing has re-checked this claim yet.
#   accepted     decision track only — whether the decision was accepted, because
#                nothing else in the system records that.
# Anything after the closing `---` is free prose a reader may ignore. No harness API is
# involved: another agent can produce a valid entry with printf and the filename from
# `tray-path.sh entry <id>`.
#
# A missing or malformed field is refused here rather than at promotion, where the
# capturing session is long gone and the gap can no longer be filled.
#
# Secrets block the write instead of being redacted. A tray file is never in a pull
# request and never staged, so neither review nor the pre-commit scan would ever see it,
# and a redacted entry is useless as evidence anyway.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
NL='
'
die() { printf 'learn: %s\n' "$1" >&2; exit 1; }
# YAML double-quoted scalar. Escaping every literal backslash first means no accidental
# escape sequence (\n, \t) can be introduced by the text itself.
q() { printf '"%s"' "$(printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"; }
oneline() { case $2 in *"$NL"*) die "--$1 must be one line; put longer prose in the entry body";; esac; }
WINDOW_DAYS=56   # eight weeks; see EXPIRY above
BUDGET_WORDS=400 # the instruction-file fallback budget; the repo's own lint wins (--budget)
REMOTE=${REMOTE:-origin}   # same knob verify.sh uses

# The default branch as a ref this repository can read, resolved with git alone.
def_ref() {
  local s b
  if s=$(git symbolic-ref --quiet "refs/remotes/$REMOTE/HEAD" 2>/dev/null) && [ -n "$s" ]; then
    printf '%s\n' "${s#refs/remotes/}"; return 0
  fi
  for b in main master trunk; do
    if git rev-parse --verify --quiet "refs/remotes/$REMOTE/$b" >/dev/null 2>&1; then
      printf '%s/%s\n' "$REMOTE" "$b"; return 0
    fi
  done
  return 1
}
in_set() { case "$NL$2$NL" in *"$NL$1$NL"*) return 0;; esac; return 1; }
val_for() { printf '%s\n' "$2" | sed -n "s/^$1=//p" | head -1; }   # ids are [A-Za-z0-9_-]
ok_id() { case $1 in ''|*[!A-Za-z0-9_-]*) return 1;; esac; return 0; }

# YYYYMMDD -> days since 1970-01-01, by arithmetic only. `date -d` is GNU, `date -v` is
# BSD, and a sweep that cannot subtract two dates on the host it runs on expires nothing
# forever. (days_from_civil; every year here is positive, so no era sign handling.)
days() {
  local y m d mm era yoe doy doe
  y=$((10#${1:0:4})); m=$((10#${1:4:2})); d=$((10#${1:6:2}))   # 10# so "08" is not octal
  if [ "$m" -gt 2 ]; then mm=$((m-3)); else mm=$((m+9)); y=$((y-1)); fi
  era=$((y/400)); yoe=$((y-era*400))
  doy=$(((153*mm+2)/5+d-1))
  doe=$((yoe*365+yoe/4-yoe/100+doy))
  printf '%s\n' $((era*146097+doe-719468))
}

sweep() {
  local declared=0 matched="" tray log today f base d id age
  while [ $# -gt 0 ]; do
    case $1 in
      --matched)
        [ $# -ge 2 ] || die "--matched needs an entry id"
        [ -n "$2" ] || die "--matched is empty"
        matched=$matched$2$NL; declared=1; shift 2;;
      --no-matches) declared=1; shift;;
      *) die "unknown argument '$1' — see the usage at the top of $0";;
    esac
  done
  [ $declared = 1 ] || die "sweep needs --matched <id> (repeatable) or --no-matches: the set this invocation matched. Expiry runs after matching, so the sweep will not guess that nothing matched and delete the entry a merge just proved."

  tray=$("$HERE/tray-path.sh") || exit 1
  # No tray means nothing to expire. Returning here is also what keeps a sweep from
  # creating the tray it was asked to prune — an empty tray and a log full of nothing.
  [ -d "$tray" ] || return 0
  log=$("$HERE/tray-path.sh" log) || exit 1
  today=$(days "$(date +%Y%m%d)")

  for f in "$tray"/entry-*.md; do
    [ -f "$f" ] || continue                      # no entries: the glob is literal
    base=${f##*/}; d=${base#entry-}; d=${d%%-*}
    # The date is read off the filename tray-path.sh chose; capture derives `captured_on`
    # from that same name, so the two cannot disagree. A name that carries no date is
    # left alone rather than guessed at: the sweep deletes, so it never improvises.
    case $d in [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]) ;; *) continue;; esac
    id=${base%.md}; id=${id#entry-"$d"-}
    case "$NL$matched" in *"$NL$id$NL"*) continue;; esac   # matched here: the caller promotes it
    grep -q '^state: proposed$' "$f" && continue           # in a pull request; dwell is unbounded
    age=$((today - $(days "$d")))
    [ "$age" -gt "$WINDOW_DAYS" ] || continue

    if [ ! -e "$log" ]; then
      # The header does not restate the line format: a format example reads as a removal
      # to anyone counting them with grep, and the first version of this header was
      # counted as one. The format lives in this file's EXPIRY note instead.
      { printf -- '# learn — tray log\n\n'
        printf 'Append-only: one line per tray entry the expiry sweep removed.\n\n'
      } >> "$log" || die "cannot write the tray log at $log"
    fi
    # The record is written BEFORE the removal. A failed write then costs an expiry the
    # next sweep repeats; the other order costs an entry nothing records the loss of, and
    # R12 asks for the record, not the deletion.
    printf -- '- %s expired id=%s age=%sd captured=%s-%s-%s reason=unmatched-for-more-than-%s-days\n' \
      "$(date +%Y-%m-%d)" "$id" "$age" "${d:0:4}" "${d:4:2}" "${d:6:2}" "$WINDOW_DAYS" >> "$log" \
      || die "cannot write the tray log at $log"
    rm "$f" || die "logged the expiry of $id but could not remove $f"
  done
}

# An entry read back the way the schema promises any agent can read it: strip the key,
# unquote, unescape. Nothing here parses YAML.
field() { sed -n "s/^$2: //p" "$1" | sed 's/^"\(.*\)"$/\1/; s/\\\(.\)/\1/g'; }
epaths() { awk '/^paths:/{f=1;next} f&&/^  - /{sub(/^  - /,"");print;next} f{exit}' "$1" \
  | sed 's/^"\(.*\)"$/\1/; s/\\\(.\)/\1/g'; }
# The capture date off the filename, or empty when the name carries none. The id comes from
# the filename too, and for the same reason the sweep takes it from there: a listing that
# read the id out of the frontmatter instead could name an entry differently from the log
# line recording its removal.
date_of() { local d=${1##*/}; d=${d#entry-}; d=${d%%-*}
  case $d in [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]) printf '%s\n' "$d";; *) printf '\n';; esac; }
id_of() { local b=${1##*/} d; b=${b%.md}; d=$(date_of "$1")
  if [ -n "$d" ]; then printf '%s\n' "${b#entry-"$d"-}"; else printf '%s\n' "${b#entry-}"; fi; }
cap_date() { local d; d=$(date_of "$1")
  if [ -n "$d" ]; then printf '%s-%s-%s\n' "${d:0:4}" "${d:4:2}" "${d:6:2}"; else printf 'unknown\n'; fi; }
# R17: the capture-time scan binds only the capture verb, so an entry written as a plain
# file by a human or a non-Claude agent never reached it. Every verb that reads the tray
# scans what it reads. A finding is reported — already masked by the scanner — and nothing
# is deleted: deletion is reject's alone.
scan_entry() { local found blocks
  if ! found=$("$HERE/redact-scan.sh" "$1" 2>&1); then
    blocks=$(printf '%s\n' "$found" | grep '^BLOCK ')
    if [ -n "$blocks" ]; then
      printf '%s\n' "$blocks" | sed 's/^/  ! /'
      printf '  ! the entry is left in place; only `reject` deletes. Rotate the credential, then reject this entry.\n'
    else
      # The scanner did not run. Saying "unscanned" is the only honest report: a non-zero
      # exit with no finding is indistinguishable from a clean entry otherwise, and this
      # verb's whole claim is that what it reads has been scanned.
      printf '  ! UNSCANNED: the secret scan could not run on this entry (%s)\n' "$(printf '%s' "$found" | tr '\n' ' ')"
    fi
  fi
}

# See RECONCILIATION above. Runs on all three runners (capture, list, promote) because
# `state: proposed` is exempt from expiry: a runner that skipped this would leave an entry
# exempt forever, and shipping the exemption without the reconciler is the one combination
# that leaks entries permanently. Reports on stdout; every caller sends it to stderr, so
# the verb's own output stays exactly what it was.
reconcile() {
  local tray log ref f id b r heads claim line rc t
  tray=$("$HERE/tray-path.sh") || return 1
  [ -d "$tray" ] || return 0
  log=$("$HERE/tray-path.sh" log) || return 1
  for f in "$tray"/entry-*.md; do
    [ -f "$f" ] || continue
    grep -q '^state: proposed$' "$f" || continue
    id=$(id_of "$f"); b=$(field "$f" pr_branch); r=$(field "$f" pr_ref)
    if [ -z "$b" ]; then
      printf 'proposed %s: no pull request is recorded, so nothing can be reconciled — left proposed. `propose` records one; an entry marked by hand may carry none.\n' "$id"
      continue
    fi
    # GIT_TERMINAL_PROMPT=0 so a remote that wants credentials FAILS instead of blocking:
    # this runs inside an ordinary capture, and a capture that hangs on a password prompt
    # is worse than one that reports it could not reconcile.
    if ! heads=$(GIT_TERMINAL_PROMPT=0 git ls-remote --heads "$REMOTE" "$b" 2>/dev/null); then
      printf 'proposed %s: cannot ask %s whether %s is still there — left proposed. Nothing is consumed on a signal this verb could not get.\n' "$id" "$REMOTE" "$b"
      continue
    fi
    if [ -n "$heads" ]; then
      printf 'proposed %s: %s is still on %s — left proposed, expiry clock frozen.\n' "$id" "$b" "$REMOTE"
      continue
    fi
    if ! ref=$(def_ref); then
      printf 'proposed %s: %s is gone from %s, but the default branch cannot be resolved there — left proposed.\n' "$id" "$b" "$REMOTE"
      continue
    fi
    claim=$(field "$f" claim)
    if [ -z "$claim" ]; then
      printf 'proposed %s: no claim to look for in %s — left proposed.\n' "$id" "$ref"; continue
    fi
    git grep -qF -e "$claim" "$ref" >/dev/null 2>&1; rc=$?
    if [ $rc -gt 1 ]; then
      printf 'proposed %s: cannot read %s to look for the claim — left proposed.\n' "$id" "$ref"; continue
    fi
    if [ $rc = 0 ]; then
      # `consumed` is this verb's own word in the shared log (see THE TRAY LOG IS SHARED).
      # The pull request reference is caller-controlled text, so the rendered line is
      # checked against the other verbs' greps before it is appended.
      line=$(printf -- '- %s consumed id=%s captured=%s pr=%s' "$(date +%Y-%m-%d)" "$id" "$(cap_date "$f")" "$(q "$r")")
      case $line in *" expired id="*|*" rejected id="*)
        printf 'proposed %s: the recorded pull request reference would make its consumption line count as another verb — left proposed.\n' "$id"; continue;;
      esac
      if [ ! -e "$log" ]; then
        { printf -- '# learn — tray log\n\n'
          printf 'Append-only: one line per tray entry removed, naming the verb that removed it.\n\n'
        } >> "$log" || { printf 'proposed %s: cannot write the tray log at %s — left proposed.\n' "$id" "$log"; continue; }
      fi
      # Recorded before the removal, as the sweep and reject are: a failed write costs a
      # reconciliation the next runner repeats, the other order costs the record.
      printf '%s\n' "$line" >> "$log" || { printf 'proposed %s: cannot write the tray log at %s — left proposed.\n' "$id" "$log"; continue; }
      rm "$f" || { printf 'logged the consumption of %s but could not remove %s\n' "$id" "$f"; continue; }
      printf 'consumed %s: %s is gone from %s and the claim is in %s — the lesson is durable now; recorded in %s\n' "$id" "$b" "$REMOTE" "$ref" "$log"
    else
      # The filename is not touched, so the capture date — the clock — is untouched too.
      t=$tray/.tmp.$$
      if awk '/^state: proposed$/ && !d { print "state: captured"; d=1; next }
              /^pr_branch: /{next} /^pr_ref: /{next} {print}' "$f" > "$t" && mv "$t" "$f"; then
        printf 'returned %s: %s is gone from %s but the claim is not in %s — a reviewer trimmed it out. Back to captured, clock untouched; nothing was deleted.\n' "$id" "$b" "$REMOTE" "$ref"
      else
        rm -f "$t"; printf 'proposed %s: could not return it to captured — left proposed.\n' "$id"
      fi
    fi
  done
}

propose() {
  local branch="" pr="" ids="" id f found count tray qb qr t
  while [ $# -gt 0 ]; do
    case $1 in
      --branch) [ $# -ge 2 ] || die "--branch needs a value"; oneline branch "$2"; branch=$2; shift 2;;
      --pr)     [ $# -ge 2 ] || die "--pr needs a value";     oneline pr "$2";     pr=$2;     shift 2;;
      -*) die "unknown argument '$1' — see the usage at the top of $0";;
      *)  ok_id "$1" || die "'$1' is not an entry id — ids are letters, digits, '-' and '_' (see 'tray.sh list')"
          ids=$ids$1$NL; shift;;
    esac
  done
  [ -n "$ids" ]    || die "propose needs the ids the promotion put in the pull request: tray.sh propose <id> [<id>...] --branch <head> --pr <ref>"
  [ -n "$branch" ] || die "propose needs --branch <head branch>: reconciliation asks the remote whether that branch is still there, and with no forge tooling that is the only signal it has"
  [ -n "$pr" ]     || die "propose needs --pr <reference>: an entry exempt from expiry has to name the pull request it is waiting on"
  case $branch in *[[:space:]]*|*'*'*|*'?'*|*'['*) die "'$branch' is not a branch name the remote can be asked about";; esac
  case $pr in *" expired id="*|*" rejected id="*|*" consumed id="*)
    die "that pull request reference would make this entry's consumption line count as another verb's in the tray log; reword it";; esac

  tray=$("$HERE/tray-path.sh") || exit 1
  qb=$(q "$branch"); qr=$(q "$pr")
  # Validated first, marked second: a batch naming one bad id must not leave half of one
  # pull request's entries marked and half not.
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    found=""; count=0
    for f in "$tray"/entry-*-"$id".md; do [ -f "$f" ] || continue; found=$f; count=$((count+1)); done
    [ "$count" != 0 ] || die "no entry with id '$id' in the tray — nothing was changed. 'tray.sh list' shows the ids actually there."
    [ "$count" = 1 ] || die "$count entries match id '$id'; refusing to guess which one to mark"
    grep -q '^state: captured$' "$found" || die "entry '$id' is in state '$(field "$found" state)', not captured — refusing to overwrite the pull request it already records"
  done <<<"${ids%$NL}"
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    found=""
    for f in "$tray"/entry-*-"$id".md; do [ -f "$f" ] || continue; found=$f; done
    t=$tray/.tmp.$$
    awk -v b="$qb" -v r="$qr" '/^state: captured$/ && !d { print "state: proposed"; print "pr_branch: " b; print "pr_ref: " r; d=1; next } {print}' \
      "$found" > "$t" && mv "$t" "$found" || { rm -f "$t"; die "could not mark '$id' proposed; $found is unchanged"; }
    printf 'proposed %s: waiting on %s (%s) — exempt from expiry until that branch is gone from %s\n' "$id" "$pr" "$branch" "$REMOTE"
  done <<<"${ids%$NL}"
}

list() {
  local tray log today f d id age n=0 seen="" line p
  [ $# -eq 0 ] || die "list takes no arguments — it lists the whole tray (see the usage at the top of $0)"
  tray=$("$HERE/tray-path.sh") || exit 1
  log=$("$HERE/tray-path.sh" log) || exit 1
  # Reconciliation runs BEFORE the printing, so the state each entry is listed under is the
  # state it is actually in: one consumed here is not listed at all, and one a reviewer
  # trimmed out lists as `captured` again. Its report goes to stderr — stdout is the
  # listing. (See RECONCILIATION: listing is the only runner that fires in a repository
  # nobody is capturing into, so it is the one that must not skip this.)
  ( reconcile ) >&2 || :
  # No tray is an answer, not an error — and listing must not create the one it was asked
  # to read, or capture's "a finding writes nothing, not even the tray" stops being true.
  if [ -d "$tray" ]; then
    today=$(days "$(date +%Y%m%d)")
    for f in "$tray"/entry-*.md; do
      [ -f "$f" ] || continue                    # no entries: the glob is literal
      d=$(date_of "$f"); id=$(id_of "$f")
      if [ -n "$d" ]; then age="$((today - $(days "$d")))d"; else age=unknown; fi
      n=$((n+1)); seen=$seen$id' '$f$NL
      printf 'entry %s  age=%s  track=%s  state=%s\n' "$id" "$age" "$(field "$f" track)" "$(field "$f" state)"
      printf '  claim: %s\n' "$(field "$f" claim)"
      epaths "$f" | while IFS= read -r p; do printf '  path: %s\n' "$p"; done
      scan_entry "$f"
    done
  fi
  [ "$n" = 0 ] && printf 'the tray is empty: no lesson has been captured in this repository.\n'

  # Listing is one of the three expiry runners (see EXPIRY) and the only one that fires in a
  # repository nobody is capturing into. It sweeps AFTER printing: an over-age entry is
  # reported and then reaped, in that order, so the operator reads what this listing removed
  # instead of finding it silently gone. Which entries went is read off the disk afterwards
  # rather than predicted here, so the sweep stays the only judge of what is over-age.
  ( sweep --no-matches ) || :
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    id=${line%% *}; f=${line#* }
    [ -e "$f" ] && continue
    printf 'expired %s: past the expiry window — removed by this listing, recorded in %s\n' "$id" "$log"
  done <<<"${seen%$NL}"
}

reject() {
  local id="" reason="" tray log f found count=0 d captured line
  while [ $# -gt 0 ]; do
    case $1 in
      --reason)
        [ $# -ge 2 ] || die "--reason needs a value"
        oneline reason "$2"; reason=$2; shift 2;;
      -*) die "unknown argument '$1' — see the usage at the top of $0";;
      *)  [ -z "$id" ] || die "reject takes one entry id; got '$id' and '$1'"
          id=$1; shift;;
    esac
  done
  [ -n "$id" ]     || die "reject needs the entry id to delete: tray.sh reject <id> --reason \"<why>\""
  [ -n "$reason" ] || die "reject needs --reason \"<why>\": the deletion is permanent and the tray log is the only record of why"
  # A glob metacharacter in the id would match several entries, and reject deletes exactly
  # the one it was given.
  case $id in *[!A-Za-z0-9_-]*) die "'$id' is not an entry id — ids are letters, digits, '-' and '_' (see 'tray.sh list')";; esac

  tray=$("$HERE/tray-path.sh") || exit 1
  for f in "$tray"/entry-*-"$id".md; do [ -f "$f" ] || continue; found=$f; count=$((count+1)); done
  [ "$count" != 0 ] || die "no entry with id '$id' in the tray — nothing was changed. 'tray.sh list' shows the ids actually there."
  [ "$count" = 1 ] || die "$count entries match id '$id'; refusing to guess which one to delete"

  log=$("$HERE/tray-path.sh" log) || exit 1
  d=$(date_of "$found")
  if [ -n "$d" ]; then captured="${d:0:4}-${d:4:2}-${d:6:2}"; else captured=unknown; fi
  line=$(printf -- '- %s rejected id=%s captured=%s reason=%s' "$(date +%Y-%m-%d)" "$id" "$captured" "$(q "$reason")")
  # The rendered line, not the raw reason: this is exactly what the counting greps see.
  case $line in
    *" expired id="*) die "that reason would make the rejection line count as an expiry (\`grep ' expired id='\`); reword it";;
  esac
  if [ ! -e "$log" ]; then
    # Generic, and naming no line format: a format example in the log reads as a removal to
    # anyone counting removals with grep. The formats live in this file's TRAY LOG note.
    { printf -- '# learn — tray log\n\n'
      printf 'Append-only: one line per tray entry removed, naming the verb that removed it.\n\n'
    } >> "$log" || die "cannot write the tray log at $log"
  fi
  # Recorded before the removal, as the sweep does: a failed write then costs a rejection
  # the caller can repeat, where the other order costs an entry nothing records the loss of.
  printf '%s\n' "$line" >> "$log" || die "cannot write the tray log at $log"
  rm "$found" || die "logged the rejection of $id but could not remove $found"
  printf 'rejected %s: removed, reason recorded in %s\n' "$id" "$log"
}

capture() {
  local track="" claim="" evidence="" accepted="" paths="" p id path base d captured_on body found
  while [ $# -gt 0 ]; do
    case $1 in
      --track|--claim|--evidence|--path|--accepted)
        [ $# -ge 2 ] || die "$1 needs a value"
        case $1 in
          --track)    track=$2;;
          --claim)    oneline claim "$2";    claim=$2;;
          --evidence) oneline evidence "$2"; evidence=$2;;
          --accepted) accepted=$2;;
          --path)
            p=$2
            [ -n "$p" ] || die "--path is empty"
            oneline path "$p"
            case $p in /*) die "--path '$p' must be repo-relative, not absolute";; esac
            case $p in *..*) die "--path '$p' must not escape the repo with '..'";; esac
            case $p in *:[0-9]*|*'#L'[0-9]*)
              die "--path '$p' carries a line number — paths are the match key and survive, line numbers are evidence and do not; drop the ':<n>'";;
            esac
            paths=$paths$p$NL;;
        esac
        shift 2;;
      *) die "unknown argument '$1' — see the usage at the top of $0";;
    esac
  done

  [ -n "$claim" ]    || die "capture needs --claim: the lesson in one line"
  [ -n "$evidence" ] || die "capture needs --evidence: the content citation behind the claim (a commit id is never evidence on its own)"
  [ -n "$paths" ]    || die "capture needs at least one --path: the repo-relative path the claim is about"
  case $track in
    decision)
      case $accepted in true|false) ;; *)
        die "--track decision needs --accepted true|false: nothing else in the system records whether the decision was accepted";;
      esac;;
    checkable|standing)
      [ -z "$accepted" ] || die "--accepted belongs to --track decision only";;
    '') die "capture needs --track decision|checkable|standing — where the lesson should go, not a claim that it is true";;
    *)  die "unknown track '$track' — one of decision, checkable, standing";;
  esac

  id=$(od -An -tx1 -N4 /dev/urandom | tr -d ' \n')
  [ ${#id} -eq 8 ] || die "could not generate an entry id"
  path=$("$HERE/tray-path.sh" entry "$id") || exit 1
  # The capture date comes out of the filename the resolver chose, so the two can never
  # disagree (two `date` calls either side of midnight would).
  base=${path##*/}; d=${base#entry-}; d=${d%%-*}
  captured_on="${d:0:4}-${d:4:2}-${d:6:2}"

  body=$(
    printf -- '---\n'
    printf 'id: %s\n' "$id"
    printf 'claim: %s\n' "$(q "$claim")"
    printf 'evidence: %s\n' "$(q "$evidence")"
    printf 'paths:\n'
    while IFS= read -r p; do printf -- '  - %s\n' "$(q "$p")"; done <<<"${paths%$NL}"
    printf 'captured_on: %s\n' "$captured_on"
    printf 'track: %s\n' "$track"
    printf 'state: captured\n'
    printf 'verified: false\n'
    [ -z "$accepted" ] || printf 'accepted: %s\n' "$accepted"
    printf -- '---\n'
  )

  # Scan before anything exists on disk, so a finding leaves no tray behind either.
  if ! found=$(printf '%s\n' "$body" | "$HERE/redact-scan.sh" -); then
    printf '%s\n' "$found" >&2
    die "capture aborted: nothing was written to the tray. Rotate or remove the finding and capture again — a redacted entry would be evidence of nothing."
  fi
  mkdir -p "${path%/*}" || die "cannot create the tray at ${path%/*}"
  # noclobber makes the create exclusive: a reused id loses the file rather than the
  # entry already there.
  ( set -C; printf '%s\n' "$body" > "$path" ) || die "an entry already exists at $path"
  printf '%s\n' "$path"
  # Capture is one of the three expiry runners (see EXPIRY). It runs last, after the entry
  # is written and its path is out: a capture that refused to write — a missing field, a
  # credential — must leave the tray exactly as it found it, and the caller gets its path
  # even if the sweep then fails. Nothing this capture wrote can be over-age, and capture
  # matches nothing, so it declares --no-matches. The subshell is why a tray the sweep
  # cannot write (a read-only git directory) reports on stderr instead of failing a
  # capture that already succeeded.
  #
  # Capture is also one of the three reconciliation runners, for the same reason it is one
  # of the three expiry runners: `state: proposed` is exempt from expiry, so an entry no
  # runner reconciles is exempt forever. Reconciliation goes first — it decides what state
  # an entry is in, where the sweep only decides what to do about an over-age one — and
  # like the sweep it reports on stderr, so capture's stdout stays exactly one path.
  ( reconcile ) >&2 || :
  ( sweep --no-matches ) || :
}

# What git can answer about an entry's evidence: whether the artifact it cites is still
# there to be looked at. Prints "<outcome> <detail>".
#   located <anchor>     the citation resolves in the default branch
#   re-anchored <path>   the cited commit is unreachable — a squash merge does that as a
#                        matter of routine — but a path of this entry is still there
#   unresolvable <why>   neither; there is nothing left to resolve against
locate_evidence() { # <entry file> <default ref>
  local ev commit p hit=""
  ev=$(field "$1" evidence)
  commit=$(printf '%s' "$ev" | tr -c '0-9A-Za-z' '\n' | grep -xE '[0-9a-f]{7,40}' | head -1)
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    git cat-file -e "$2:$p" 2>/dev/null && { hit=$p; break; }
  done <<<"$(epaths "$1")"
  if [ -n "$commit" ]; then
    git merge-base --is-ancestor "$commit" "$2" 2>/dev/null && { printf 'located %s\n' "$commit"; return 0; }
    [ -z "$hit" ] || { printf 're-anchored %s\n' "$hit"; return 0; }
    printf 'unresolvable the cited commit %s is not reachable from %s and no path of this entry is there to re-anchor against\n' "$commit" "$2"
    return 0
  fi
  [ -z "$hit" ] || { printf 'located %s\n' "$hit"; return 0; }
  printf 'unresolvable no path of this entry exists in %s to resolve its evidence against\n' "$2"
}
# The area a topic file is named for: the directory the claim is about.
area_of() { local p=${1%/} d; d=${p%/*}
  if [ "$d" = "$p" ]; then d=${p##*/}; d=${d%.*}; else d=${d##*/}; fi
  printf '%s\n' "${d:-general}"; }
render_line() { # <entry file> <effective track>
  local claim ev ps="" p
  claim=$(field "$1" claim); ev=$(field "$1" evidence)
  while IFS= read -r p; do [ -n "$p" ] || continue; ps=${ps:+$ps, }$p; done <<<"$(epaths "$1")"
  case $2 in
    standing) printf -- '- %s (learn: asserted — nothing in the repository resolves this; %s; %s)\n' "$claim" "$ev" "$ps";;
    decision) printf -- '- %s (learn: decision record, against the alternative not adopted; %s; %s)\n' "$claim" "$ev" "$ps";;
    *)        printf -- '- %s (learn: %s; %s)\n' "$claim" "$ev" "$ps";;
  esac
}

promote() {
  local event="" budget=$BUDGET_WORDS ifile="" confirms="" contras="" asks=""
  local tray ref f id st track loc ev det sc eff dest why line a sw
  local missing="" matched="" npro=0 nst=0 nex=0 nheld=0 n=0 wf wl
  while [ $# -gt 0 ]; do
    case $1 in
      --event) [ $# -ge 2 ] || die "--event needs a value"
        case $2 in merge|decision-acceptance) event=$2;;
          *) die "unknown event '$2' — merge or decision-acceptance";; esac; shift 2;;
      --confirms) [ $# -ge 2 ] || die "--confirms needs an entry id"
        ok_id "${2:-}" || die "--confirms '${2:-}' is not an entry id"
        confirms=$confirms$2$NL; shift 2;;
      --contradicts) [ $# -ge 2 ] || die "--contradicts needs <id>=\"<what the default branch says instead>\""
        case $2 in *=*) ;; *) die "--contradicts takes <id>=\"<what the default branch says instead>\": a contradiction nobody named cannot be surfaced to the session that reads this entry next";; esac
        ok_id "${2%%=*}" || die "--contradicts '${2%%=*}' is not an entry id"
        [ -n "${2#*=}" ] || die "--contradicts '${2%%=*}' names no contradiction; say what the default branch holds instead"
        contras=$contras$2$NL; shift 2;;
      --as) [ $# -ge 2 ] || die "--as needs <id>=<track>"
        ok_id "${2%%=*}" || die "--as '${2%%=*}' is not an entry id"
        case ${2#*=} in decision|checkable|standing) ;;
          *) die "--as '$2': the track must be decision, checkable or standing";; esac
        asks=$asks$2$NL; shift 2;;
      --budget) [ $# -ge 2 ] || die "--budget needs a word count"
        case $2 in ''|*[!0-9]*) die "--budget '$2' is not a word count";; esac; budget=$2; shift 2;;
      --instruction-file) [ $# -ge 2 ] || die "--instruction-file needs a path"
        [ -n "$2" ] || die "--instruction-file is empty"; ifile=$2; shift 2;;
      *) die "unknown argument '$1' — see the usage at the top of $0";;
    esac
  done
  [ -n "$event" ] || die "promote needs --event merge|decision-acceptance: every promotion event evaluates every entry, and the event is what selects each track's gate"
  if [ -z "$ifile" ]; then
    if [ -f CLAUDE.md ] && [ ! -f AGENTS.md ]; then ifile=CLAUDE.md; else ifile=AGENTS.md; fi
  fi

  tray=$("$HERE/tray-path.sh") || exit 1
  ( reconcile ) >&2 || :
  if [ -d "$tray" ]; then for f in "$tray"/entry-*.md; do [ -f "$f" ] && n=$((n+1)); done; fi
  [ "$n" != 0 ] || { printf 'no lesson is staged in this repository: the tray is empty.\n'; return 0; }
  ref=$(def_ref) || die "cannot resolve the default branch through '$REMOTE' — evidence resolves against it and promotion will not guess. Fetch the remote, or set REMOTE."

  # PASS 1 — resolve and validate everything before reporting anything, so a refusal
  # cannot land halfway through a report that already said it was promoting entries.
  for f in "$tray"/entry-*.md; do
    [ -f "$f" ] || continue
    id=$(id_of "$f"); ok_id "$id" || continue
    grep -q '^state: captured$' "$f" || continue
    [ -z "$(scan_entry "$f")" ] || continue
    track=$(field "$f" track)
    if [ "$track" != checkable ]; then
      if in_set "$id" "$confirms" || in_set "$id" "$(printf '%s' "$contras" | sed 's/=.*//')"; then
        die "'$id' is on the $track track, which the evidence step does not apply to — there is nothing here to confirm or contradict"
      fi
      continue
    fi
    loc=$(locate_evidence "$f" "$ref"); st=${loc%% *}; det=${loc#* }
    if [ "$st" = unresolvable ]; then
      if in_set "$id" "$confirms" || in_set "$id" "$(printf '%s' "$contras" | sed 's/=.*//')"; then
        die "nothing resolved for '$id', so there is nothing to confirm or contradict: $det"
      fi
      a=$(val_for "$id" "$asks")
      [ -z "$a" ] || die "refusing to re-route '$id' onto $a: its evidence did not resolve on the checkable track ($det), and $a would skip the evidence step that just refused it. The entry stays staged; re-anchor it or reject it."
      continue
    fi
    if in_set "$id" "$confirms"; then
      ! in_set "$id" "$(printf '%s' "$contras" | sed 's/=.*//')" || die "'$id' is given as both confirmed and contradicted"
    elif in_set "$id" "$(printf '%s' "$contras" | sed 's/=.*//')"; then
      a=$(val_for "$id" "$asks")
      [ -z "$a" ] || die "refusing to re-route '$id' onto $a: its evidence resolved and contradicts its claim, and $a would skip the evidence step that just refused it. The entry stays staged — nothing here deletes it."
    else
      missing="$missing $id"
    fi
  done
  [ -z "$missing" ] || die "promotion needs the evidence verdict for:$missing — --confirms <id>, or --contradicts <id>=\"<what the default branch says instead>\". Evidence resolves before the track routes, so a checkable entry whose evidence resolved cannot be routed until this invocation says what it found."

  # PASS 2 — the report.
  for f in "$tray"/entry-*.md; do
    [ -f "$f" ] || continue
    id=$(id_of "$f"); track=$(field "$f" track)
    if ! ok_id "$id"; then
      printf 'held id=%s reason=unusable-id note=no-verb-can-name-this-entry\n' "${f##*/}"; nheld=$((nheld+1)); continue
    fi
    if ! grep -q '^state: captured$' "$f"; then
      printf 'held id=%s state=%s reason=already-in-a-pull-request\n' "$id" "$(field "$f" state)"; nheld=$((nheld+1)); continue
    fi
    sc=$(scan_entry "$f")
    if [ -n "$sc" ]; then
      case $sc in *BLOCK*) printf 'excluded id=%s reason=secret-finding note=only-this-entry-the-rest-of-the-batch-promotes\n' "$id";;
                  *)       printf 'excluded id=%s reason=unscanned note=only-this-entry-the-rest-of-the-batch-promotes\n' "$id";; esac
      printf '%s\n' "$sc"; nex=$((nex+1)); continue
    fi
    # Evidence FIRST, then the track routes. The override below cannot reach back and
    # change what this step found — that is the whole of the refusal in pass 1.
    ev=exempt; det=""
    case $track in
      standing) ev=skipped;;
      decision) ev=exempt;;
      checkable)
        loc=$(locate_evidence "$f" "$ref"); st=${loc%% *}; det=${loc#* }
        if [ "$st" = unresolvable ]; then ev=unresolvable
        elif in_set "$id" "$confirms"; then
          if [ "$st" = re-anchored ]; then ev=re-anchored; else ev=confirms; fi
        else ev=contradicts; det=$(val_for "$id" "$contras"); fi;;
    esac
    case $ev in
      unresolvable)
        printf 'staged id=%s track=%s evidence=unresolvable reason="%s" note=surfaced-not-expired-nothing-deleted\n' "$id" "$track" "$det"
        nst=$((nst+1)); continue;;
      contradicts)
        # Matched by this event: the merge most likely to touch a bug's paths is the fix
        # for that bug, so the sweep this same invocation runs must not reap it.
        printf 'staged id=%s track=%s evidence=contradicts contradiction="%s" note=left-staged-nothing-deleted\n' "$id" "$track" "$det"
        matched=$matched$id$NL; nst=$((nst+1)); continue;;
    esac
    eff=$track; a=$(val_for "$id" "$asks")
    [ -z "$a" ] || eff=$a
    case $eff in
      decision)
        if [ "$event" = merge ] && [ "$(field "$f" accepted)" != true ]; then
          printf 'staged id=%s track=%s reason=no-acceptance-recorded note=a-merge-does-not-accept-a-decision\n' "$id" "$eff"
          nst=$((nst+1)); continue
        fi
        dest="docs/decisions/$(field "$f" captured_on)-$id.md"; why=decision-record-draft;;
      standing)
        dest="docs/topics/$(area_of "$(epaths "$f" | head -1)").md"
        why=standing-is-asserted-never-the-instruction-file;;
      *)
        line=$(render_line "$f" "$eff")
        wf=0; [ ! -f "$ifile" ] || wf=$(wc -w < "$ifile" | tr -d ' ')
        wl=$(printf '%s\n' "$line" | wc -w | tr -d ' ')
        if [ $((wf + wl)) -gt "$budget" ]; then
          dest="docs/topics/$(area_of "$(epaths "$f" | head -1)").md"
          why="instruction-file-over-budget($ifile=${wf}w+${wl}w>${budget}w)"
        else
          dest=$ifile; why="fits-the-instruction-file-budget(${wf}w+${wl}w<=${budget}w)"
        fi;;
    esac
    printf 'promote id=%s track=%s%s event=%s evidence=%s dest=%s reason=%s\n' \
      "$id" "$track" "$([ "$eff" = "$track" ] || printf -- '->%s' "$eff")" "$event" "$ev" "$dest" "$why"
    printf '  line: %s' "$(render_line "$f" "$eff")"; printf '\n'
    matched=$matched$id$NL; npro=$((npro+1))
  done
  printf 'promoted=%s staged=%s excluded=%s held=%s event=%s instruction-file=%s budget=%s\n' \
    "$npro" "$nst" "$nex" "$nheld" "$event" "$ifile" "$budget"
  printf 'next: apply these lines, re-run scripts/redact-scan.sh on the staged diff, commit on a learn/ branch, open ONE DRAFT pull request and never merge it here, then record it with: tray.sh propose <id>... --branch <head> --pr <ref>\n'
  # Promotion is the third expiry runner. The matched set is every entry this event
  # resolved against the repository — the ones it promotes, and the contradicted ones R16
  # is written about. An entry it could not resolve at all was not matched by it and ages
  # normally; its paths are gone, which is what made it unresolvable.
  if [ -z "$matched" ]; then ( sweep --no-matches ) || :
  else
    sw=""
    while IFS= read -r id; do [ -n "$id" ] || continue; sw="$sw --matched $id"; done <<<"${matched%$NL}"
    ( sweep $sw ) || :   # ids are [A-Za-z0-9_-]; splitting them into arguments is the point
  fi
}

case ${1:-} in
  capture) shift; capture "$@";;
  promote) shift; promote "$@";;
  propose) shift; propose "$@";;
  list)    shift; list "$@";;
  reject)  shift; reject "$@";;
  sweep)   shift; sweep "$@";;
  *) sed -n '2,43p' "$0" >&2; exit 2;;
esac
