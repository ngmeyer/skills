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
# Paths come from tray-path.sh and nowhere else, so there is one tray per repository.
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
}

case ${1:-} in
  capture) shift; capture "$@";;
  *) sed -n '2,15p' "$0" >&2; exit 2;;
esac
