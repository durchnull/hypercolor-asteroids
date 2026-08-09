#!/bin/sh
# ---------------------------------------------------------------------------
# branch.sh - a branch that says what it is about before anybody opens it.
#
# Branches here live in a directory, and the directory is the mark: the same
# nine words the book puts on a chapter and the flight strip puts on a pull
# request. Not feat/ and fix/ and chore/, which describe the shape of a change
# - and every change is one of those three, so the word is spent before it has
# said anything. The mark says which part of the cabinet you were standing in.
#
#   game/comets-come-in-threes
#   game-within/the-trap-that-spares-nobody
#   chronicle/the-plates-paint-themselves
#
# The mark is not typed. It is read off what you have changed, through
# tools/chronicle.sh --marks, which is where that question lives and the only
# place it is answered. A change wearing several marks takes the first one the
# book would print, because that is already an order of loudness: the game
# before the game within it, both before the ui, the rules and the notes last.
#
#   tools/branch.sh <name>          branch, mark read off your changes
#   tools/branch.sh <name> <mark>   ... or named, when nothing has changed yet
#   tools/branch.sh --rename        rename the branch you are on to fit it
#   tools/branch.sh --marks         the nine directories, in order
# ---------------------------------------------------------------------------
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  printf 'branch: not a git repo\n' >&2; exit 1; }
cd "$ROOT" || exit 1

BOOK=tools/chronicle.sh

# A mark as a directory: what the badge says, in the one alphabet git and a
# terminal both take without argument. Only "game within" has a space in it,
# and this is the whole of the transformation.
slug() { printf '%s\n' "$1" | tr '[:upper:] ' '[:lower:]-'; }

marks_all() { sh "$BOOK" --marks --all 2>/dev/null | while IFS= read -r m; do slug "$m"; done; }

# What the working tree is about, most important first. Staged, unstaged and
# untracked - the last of those is not a nicety here: a feature is a new file
# in this project (GR3), so the commonest branch there is would otherwise read
# as being about nothing at all.
marks_here() {
  { git diff --name-only HEAD 2>/dev/null
    git diff --cached --name-only 2>/dev/null
    git ls-files --others --exclude-standard 2>/dev/null; } \
    | sh "$BOOK" --marks 2>/dev/null | while IFS= read -r m; do slug "$m"; done
}

# The name half: lower case, spaces to dashes, and then it has to be something
# git will take. A slash is refused rather than cleaned - somebody typing
# ui/thing has picked their own directory, and the whole point is that they do
# not get to.
clean_name() {
  n=$(slug "$1")
  case $n in
    */*) printf 'branch: the directory is not yours to pick - pass the name alone\n' >&2; return 1 ;;
    ''|-*) printf 'branch: that is not a name\n' >&2; return 1 ;;
  esac
  case $n in
    *[!a-z0-9._-]*) printf 'branch: %s has something in it git will argue about\n' "$n" >&2; return 1 ;;
  esac
  printf '%s\n' "$n"
}

# The mark, either read or checked. Prints it, or explains itself and fails.
resolve_mark() {
  if [ -n "${1:-}" ]; then
    want=$(slug "$1")
    if marks_all | grep -qx "$want"; then printf '%s\n' "$want"; return 0; fi
    printf 'branch: %s is not one of the marks. they are:\n' "$want" >&2
    marks_all | sed 's/^/  /' >&2
    return 1
  fi
  set -- $(marks_here)
  if [ $# -eq 0 ]; then
    printf 'branch: nothing has changed yet, so there is no mark to read.\n' >&2
    printf '        name one and branch anyway:  tools/branch.sh <name> <mark>\n' >&2
    marks_all | sed 's/^/  /' >&2
    return 1
  fi
  [ $# -gt 1 ] && printf 'branch: also touching %s - taking the first\n' "$(shift; echo "$*")" >&2
  printf '%s\n' "$1"
}

case "${1:---help}" in
  -h|--help)
    sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'
    ;;

  --marks)
    marks_all | sed 's|$|/|'
    ;;

  # For the branch you already made before you knew what it would hold, which
  # is most of them. Refused once it has been pushed: renaming then leaves the
  # old name on the remote and any pull request pointing at it, and that is a
  # mess made in public rather than in this clone.
  --rename)
    cur=$(git branch --show-current) || exit 1
    [ -n "$cur" ] || { printf 'branch: detached head, nothing to rename\n' >&2; exit 1; }
    case $cur in main) printf 'branch: that is main\n' >&2; exit 1 ;; esac
    if git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' >/dev/null 2>&1; then
      printf 'branch: %s is already pushed - rename it and the remote keeps the old\n' "$cur" >&2
      printf '        one, along with any pull request on it. Leave it.\n' >&2
      exit 1
    fi
    mark=$(resolve_mark "${2:-}") || exit 1
    name=$(clean_name "${cur##*/}") || exit 1
    [ "$cur" = "$mark/$name" ] && { printf 'branch: already %s\n' "$cur"; exit 0; }
    git branch -m "$mark/$name" && printf 'branch: %s -> %s\n' "$cur" "$mark/$name"
    ;;

  -*)
    printf 'branch: unknown option %s\n' "$1" >&2; exit 2
    ;;

  *)
    name=$(clean_name "$1") || exit 1
    mark=$(resolve_mark "${2:-}") || exit 1
    git switch -c "$mark/$name"
    ;;
esac
