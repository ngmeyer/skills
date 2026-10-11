#!/usr/bin/env bash
# learn from-memories — deterministic pre-pass. The agent still judges every CANDIDATE
# against references/lesson-filter.md; this script only does what grep can do reliably.
#
#   memory-triage.sh map <repo-root>... -- <memory-file>...
#     -> "<file>\t<repo-root|global>"  (by project path; see references/memory-import.md)
#   memory-triage.sh triage <repo-root|global> <memory-file>
#     -> "<CLASS>\t<file>:<line>\t<text>" per bullet, CLASS in
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

triage() {
  local repo=$1 f=$2 n=0 blocked=0
  [ -f "$f" ] || { echo "no such file $f" >&2; exit 2; }
  if ! "$HERE/redact-scan.sh" "$f" >/dev/null; then
    "$HERE/redact-scan.sh" "$f" | grep '^BLOCK ' | sed -E "s/^BLOCK ([a-z-]+) [^:]+:([0-9]+): /BLOCKED-SECRET\t$(printf '%s' "$f" | sed 's/[\/&]/\\&/g'):\2\t[\1] /"
    exit 1
  fi
  local ctx=""; [ "$repo" != global ] && ctx=$(ctx_files "$repo" | xargs -r cat 2>/dev/null | norm)
  while IFS= read -r line; do
    n=$((n+1))
    case "$line" in '- '*|'* '*) ;; *) continue;; esac
    t=${line#??}
    cls=CANDIDATE
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
          best=$(while IFS= read -r c; do k=0; for w in $words; do grep -qw "$w" <<<"$c" && k=$((k+1)); done; echo $k; done <<<"$(grep -E '[a-z]{4}' <<<"$ctx")" | sort -n | tail -1)
          [ $((best*100)) -ge $((total*80)) ] && cls=DUPLICATE
        fi
      fi
    fi
    printf '%s\t%s:%s\t%s\n' "$cls" "$f" "$n" "$t"
  done < "$f"
}

case "${1:-}" in
  map) shift; map "$@";;
  triage) shift; triage "$@";;
  *) sed -n '2,12p' "$0"; exit 2;;
esac
