#!/usr/bin/env bash
# learn from-memories — deterministic pre-pass. The agent still judges every CANDIDATE
# against references/lesson-filter.md; this script only does what grep can do reliably.
#
#   memory-triage.sh map <repo-root>... -- <memory-file>...
#     -> "<file>\t<repo-root|global>"  (by project path; see references/memory-import.md)
#   memory-triage.sh triage <repo-root|global> <memory-file>
#     -> "<CLASS>\t<file>:<line>\t<text>" per bullet, plus one record for the
#        frontmatter `description` when the file is one-fact-per-file, CLASS in
#        BLOCKED-SECRET | NOT-FOR-REPO | STALE | DUPLICATE | CANDIDATE
#     exit 1 if any BLOCKED-SECRET (the whole file is then out of scope until cleaned).
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
enc() { printf '%s' "$1" | sed -E 's/[^A-Za-z0-9]/-/g'; }

map() {
  local repos=() f r best
  while [ $# -gt 0 ] && [ "$1" != -- ]; do repos+=("$(cd "$1" && pwd)"); shift; done
  shift
  for f in "$@"; do
    best=global; abs=$(cd "$(dirname "$f")" && pwd)/$(basename "$f")
    for r in "${repos[@]}"; do
      case "$abs" in "$r"/*) best=$r;; esac                       # file inside the repo (project CLAUDE.md, .cursor/rules, exports placed in repo)
      case "$abs" in *"/$(enc "$r")/"*) best=$r;; esac            # Claude project memory dir = encoded repo path
      grep -qiE "^(project|repo|path):[[:space:]]*$r/?\$" "$f" 2>/dev/null && best=$r   # plain-text export header
    done
    printf '%s\t%s\n' "$f" "$best"
  done
}

ctx_files() { local r=$1; for p in AGENTS.md CLAUDE.md docs/topics .cursor/rules docs/decisions; do [ -e "$r/$p" ] && find "$r/$p" -type f \( -name '*.md' -o -name '*.mdc' \); done; }
norm() { tr 'A-Z' 'a-z' | sed -E 's/[^a-z0-9 ]/ /g'; }

# One text -> one CLASS. Called for bullets and for a one-fact-per-file description.
classify() {
  local t=$1 repo=$2 ctx=$3 cls=CANDIDATE p words total best
  if [ "$repo" = global ] || grep -qiE '(\bI (prefer|like|use)\b|\bmy (editor|shell|machine|laptop|setup)\b|~/|\$HOME|/Users/|/home/)' <<<"$t"; then
    cls=NOT-FOR-REPO
  else
    # STALE: a backticked repo-relative path that no longer exists
    for p in $(grep -oE '`[A-Za-z0-9_./-]+/[A-Za-z0-9_./-]+`' <<<"$t" | tr -d '`'); do
      [ -e "$repo/$p" ] || { cls=STALE; break; }
    done
    if [ $cls = CANDIDATE ] && [ -n "$ctx" ]; then
      # DUPLICATE: >=80% of the line's significant words (>=4 chars) appear on one context line
      words=$(norm <<<"$t" | tr ' ' '\n' | awk 'length>=4' | sort -u)
      total=$(grep -c . <<<"$words")
      if [ "$total" -ge 3 ]; then
        # One awk pass, not a grep per word per context line: ctx is already
        # normalized to lowercase words, so a field match is a word match.
        best=$(awk -v W="$(tr '\n' ' ' <<<"$words")" '
          BEGIN { n = split(W, a, " "); for (i = 1; i <= n; i++) want[a[i]] = 1 }
          { delete seen; k = 0
            for (i = 1; i <= NF; i++) if (want[$i] && !($i in seen)) { seen[$i] = 1; k++ }
            if (k > m) m = k }
          END { print m + 0 }' <<<"$ctx")
        [ $((best*100)) -ge $((total*80)) ] && cls=DUPLICATE
      fi
    fi
  fi
  printf '%s' "$cls"
}

triage() {
  local repo=$1 f=$2 n=0 fm=0 dline=0 desc="" mtype=""
  [ -f "$f" ] || { echo "no such file $f" >&2; exit 2; }
  if ! "$HERE/redact-scan.sh" "$f" >/dev/null; then
    "$HERE/redact-scan.sh" "$f" | grep '^BLOCK ' | sed -E "s/^BLOCK ([a-z-]+) [^:]+:([0-9]+): /BLOCKED-SECRET\t$(printf '%s' "$f" | sed 's/[\/&]/\\&/g'):\2\t[\1] /"
    exit 1
  fi
  local ctx=""; [ "$repo" != global ] && ctx=$(ctx_files "$repo" | xargs -r cat 2>/dev/null | norm)

  # One-fact-per-file memories carry the lesson in frontmatter `description` + prose,
  # with no bullets at all, so a bullet-only pass reads them as empty. Triage the
  # description as the fact and let `metadata.type` steer it.
  if [ "$(head -1 "$f")" = '---' ]; then
    fm=$(awk 'NR>1 && /^---[[:space:]]*$/{print NR; exit}' "$f")
    fm=${fm:-0}
    if [ "$fm" -gt 1 ]; then
      dline=$(awk -v e="$fm" 'NR<e && /^description:/{print NR; exit}' "$f")
      desc=$(awk -v e="$fm" 'NR<e && /^description:/{sub(/^description:[[:space:]]*/,""); print; exit}' "$f")
      # folded/literal scalar (`description: >`): the value is the indented block under it
      case "$desc" in ''|'>'|'>-'|'|'|'|-') desc=$(awk -v s="${dline:-0}" -v e="$fm" 'NR>s && NR<e && /^[[:space:]]+[^[:space:]]/{sub(/^[[:space:]]+/,""); printf "%s ", $0; next} NR>s && NR<e && /^[^[:space:]]/{exit}' "$f");; esac
      desc=$(sed -E 's/^"(.*)"$/\1/; s/^'\''(.*)'\''$/\1/; s/[[:space:]]+$//' <<<"$desc")
      # `type:` sits at the top level in older memories and under `metadata:` in newer ones.
      mtype=$(awk -v e="$fm" 'NR<e && /^[[:space:]]*type:[[:space:]]*[a-z]/{sub(/^[[:space:]]*type:[[:space:]]*/,""); print $1; exit}' "$f")
    fi
  fi
  # `type: user` is who the user is, start to finish — the body is as personal as
  # the summary, so the whole file is out, the same way a secret takes the whole file.
  [ "$mtype" = user ] && repo=global

  if [ -n "$desc" ]; then
    printf '%s\t%s:%s\t%s%s\n' "$(classify "$desc" "$repo" "$ctx")" "$f" "${dline:-1}" "${mtype:+[type:$mtype] }" "$desc"
  fi

  while IFS= read -r line; do
    n=$((n+1))
    [ "$n" -le "$fm" ] && continue
    case "$line" in '- '*|'* '*) ;; *) continue;; esac
    t=${line#??}
    printf '%s\t%s:%s\t%s\n' "$(classify "$t" "$repo" "$ctx")" "$f" "$n" "$t"
  done < "$f"
}

case "${1:-}" in
  map) shift; map "$@";;
  triage) shift; triage "$@";;
  *) sed -n '2,12p' "$0"; exit 2;;
esac
