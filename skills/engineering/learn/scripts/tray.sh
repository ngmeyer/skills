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
#   tray.sh sweep (--no-matches | --matched <id> [--matched <id>]...)
#     Expires entries past the window and records each removal in the tray log. Prints
#     nothing on stdout. Creates nothing — no tray, no log — until there is a removal to
#     record, so a sweep is invisible in a repository nobody has captured into.
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
# The window is eight weeks (56 days), counted from the entry's capture date, which leaves
# a three-week-old entry real margin. An entry is expired once it is OLDER than the window,
# so it survives the full eight weeks.
#
# `state: proposed` is exempt: its lesson is sitting in a pull request the writing session
# will not merge itself, and that dwell has no upper bound. The exemption is only safe
# because the same three runners reconcile a proposed entry against its pull request —
# without that, exempt means permanent.
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
  ( sweep --no-matches ) || :
}

case ${1:-} in
  capture) shift; capture "$@";;
  sweep)   shift; sweep "$@";;
  *) sed -n '2,19p' "$0" >&2; exit 2;;
esac
