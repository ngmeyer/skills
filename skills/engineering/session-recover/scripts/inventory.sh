#!/usr/bin/env bash
# Inventory candidate duplicate Claude Code project dirs for /session-recover.
#
# Usage:
#   inventory.sh                # uses basename "$PWD" as project token
#   inventory.sh <token>        # explicit token, e.g. "myapp"
#
# Lists every ~/.claude/projects/*<token>*/ dir with:
#   - jsonl file count, total bytes, newest mtime
#   - memory dir entry count
#   - rough classification of the encoded path
#
# Exits 0 if at least one candidate found, 1 if none.

set -euo pipefail

TOKEN="${1:-$(basename "${PWD:-/}")}"
if [ -z "$TOKEN" ] || [ "$TOKEN" = "/" ]; then
    echo "ERROR: pass a project-name token, e.g. 'inventory.sh myapp'" >&2
    exit 2
fi

PROJECTS_ROOT="$HOME/.claude/projects"
if [ ! -d "$PROJECTS_ROOT" ]; then
    echo "ERROR: $PROJECTS_ROOT does not exist" >&2
    exit 2
fi

CANDIDATES=()
while IFS= read -r line; do
    CANDIDATES+=("$line")
done < <(find "$PROJECTS_ROOT" -maxdepth 1 -type d -iname "*${TOKEN}*" 2>/dev/null | sort)

if [ "${#CANDIDATES[@]}" -eq 0 ]; then
    echo "No candidate dirs match token '$TOKEN' under $PROJECTS_ROOT"
    exit 1
fi

if [ "${#CANDIDATES[@]}" -eq 1 ]; then
    echo "Only one candidate matches '$TOKEN' — no duplicates to merge:"
    echo "  ${CANDIDATES[0]}"
    exit 0
fi

echo "Found ${#CANDIDATES[@]} candidate dirs matching '$TOKEN':"
echo

# Header
printf "%-60s  %5s  %12s  %19s  %5s  %s\n" \
    "PATH" "JSONL" "TOTAL_BYTES" "NEWEST_MTIME" "MEM" "CLASS"
printf "%-60s  %5s  %12s  %19s  %5s  %s\n" \
    "----" "-----" "-----------" "------------" "---" "-----"

for d in "${CANDIDATES[@]}"; do
    short="${d#$PROJECTS_ROOT/}"

    jsonl_count=$(find "$d" -maxdepth 1 -name "*.jsonl" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$jsonl_count" -gt 0 ]; then
        total_bytes=$(find "$d" -maxdepth 1 -name "*.jsonl" -exec stat -f '%z' {} \; 2>/dev/null \
                     | awk '{s+=$1} END{print s+0}')
        newest=$(find "$d" -maxdepth 1 -name "*.jsonl" -exec stat -f '%Sm' -t '%Y-%m-%d_%H:%M' {} \; 2>/dev/null \
                 | sort | tail -1)
    else
        total_bytes=0
        newest="-"
    fi

    if [ -d "$d/memory" ]; then
        mem_count=$(find "$d/memory" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')
    else
        mem_count="-"
    fi

    # Rough classification
    case "$short" in
        *Volumes-*)             klass="external/secondary drive" ;;
        *mnt-*)                 klass="external/secondary drive" ;;
        *Users-*-Projects-*)    klass="~/Projects mirror" ;;
        *home-*)                klass="Linux home" ;;
        *)                      klass="other" ;;
    esac

    printf "%-60s  %5s  %12s  %19s  %5s  %s\n" \
        "$short" "$jsonl_count" "$total_bytes" "$newest" "$mem_count" "$klass"
done

echo
echo "Next: pick the canonical winner (default = the path mentioned in the"
echo "current session's system prompt under 'persistent, file-based memory"
echo "system at …'). The other(s) are losers; merge their memory + archive"
echo "their jsonls per the SKILL.md procedure."
