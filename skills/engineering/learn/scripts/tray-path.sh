#!/usr/bin/env bash
# learn — where the capture tray lives. Prints a path and creates nothing: the tray is
# made lazily by the first capture, never at install time.
#
#   tray-path.sh              -> <git-common-dir>/learn-tray
#   tray-path.sh log          -> <tray>/tray-log.md
#   tray-path.sh entry <id>   -> <tray>/entry-<YYYYMMDD>-<id>.md   (date = capture date)
#
# The tray sits in the repository's SHARED git directory, so it is outside the working
# tree and outside version control, and removing a linked worktree cannot take the
# entries with it.
#
# Resolution asks git for the common dir in ABSOLUTE form on purpose. The relative form
# is `.git` in a main working tree and a path into another checkout's `.git` from a
# linked worktree, so a relative answer resolves to two different directories and
# silently splits one repository's tray in two. Prefix-matching the working-tree root
# instead has the same bug plus a symlink one. Everything that reads the tray must
# resolve it through here, so there is one answer.
set -u
dir=$(git rev-parse --path-format=absolute --git-common-dir) || {
  echo "learn: cannot resolve the capture tray — it lives in the repository's git directory (see git's error above)" >&2
  exit 1
}
tray=$dir/learn-tray
case ${1:-dir} in
  dir)   printf '%s\n' "$tray";;
  log)   printf '%s\n' "$tray/tray-log.md";;
  entry) printf '%s\n' "$tray/entry-$(date +%Y%m%d)-${2:?usage: tray-path.sh entry <id>}.md";;
  *)     echo "usage: tray-path.sh [dir|log|entry <id>]" >&2; exit 2;;
esac
