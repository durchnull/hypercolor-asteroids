#!/bin/sh
# ---------------------------------------------------------------------------
# waveoff.sh - the pull requests that cannot land, and what is standing on the
# runway.
#
# The tower waves a landing off when the strip is not clear, and the pilot
# comes round again. A pull request whose branch and main both moved the same
# file is that, exactly: nothing is wrong with either piece of work, the two of
# them simply cannot both be true at once, and github stops at "conflicting"
# without ever saying what or why.
#
# Nobody at this keyboard can clear it either. Most of what arrives here comes
# from somebody else's clone, and even when it does not, that branch is their
# work and pushing a fix into it is a thing you do not do - GR4 counts lines,
# and this would be the whole approach. So the only useful move is to tell
# them, precisely enough that the fix is one command, and this is what there is
# to tell:
#
#   which paths, what each side did to them, which commit on main did it, how
#   far behind the branch has drifted, and whether anybody has said so already.
#
#   tools/waveoff.sh              every open pull request, and which cannot land
#   tools/waveoff.sh <n>          one of them in detail: what conflicts, and why
#   tools/waveoff.sh --marker <n> the line a comment carries, so a later run
#                                 can tell a fresh approach from one already
#                                 waved off
#
# Exit 0 = the runway is clear. Exit 1 = something is on it. Exit 2 = could not
# find out, which is a different answer and is never printed as one.
#
# The message itself is deliberately not in here. A paragraph canned in a shell
# script reads as a paragraph canned in a shell script the second time somebody
# gets one, and every other sentence this cabinet says to a person was written
# by somebody. This prints facts; /waveoff writes to the contributor.
#
# No dependencies past sh, git, awk and sed (GR2), plus the gh cli for the half
# of the question that lives on github - guarded, like tools/labels.sh.
# ---------------------------------------------------------------------------
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  printf 'waveoff: not a git repo\n' >&2; exit 2; }
cd "$ROOT" || exit 2

BASE=main

need_gh() {
  command -v gh >/dev/null 2>&1 || {
    printf 'waveoff: needs the gh cli to ask github what is open\n' >&2; exit 2; }
}

ask() {
  gh pr view "$1" --json "$2" --jq "$3" 2>/dev/null
}

plural() { [ "$1" = 1 ] || printf s; }

# --- the roll ---------------------------------------------------------------
#
# github's own verdict here, because it is one call for the whole room and it
# is the verdict the merge button obeys. UNKNOWN is not a failure: it means
# github had not computed the merge yet and has now started because we asked.
# Ask again in a moment and it will have an answer.

roll() {
  need_gh
  rows=$(gh pr list --state open --limit 50 \
    --json number,author,mergeable,headRefOid,headRefName \
    --jq '.[] | [.number, .author.login, .mergeable, (.headRefOid[0:7]), .headRefName] | @tsv' \
    2>/dev/null) || {
      printf 'waveoff: github did not answer\n' >&2; exit 2; }

  if [ -z "$rows" ]; then
    printf '\n  Nothing is open. The runway is empty.\n\n'
    return 0
  fi

  printf '\n  open pull requests\n\n'
  printf '%s\n' "$rows" | while IFS='	' read -r n who state sha branch; do
    case "$state" in
      CONFLICTING) verdict='cannot land - something is in the way' ;;
      MERGEABLE)   verdict='clear' ;;
      UNKNOWN)     verdict='github is still working it out - ask again' ;;
      *)           verdict=$state ;;
    esac
    printf '    #%-5s %-16s %-9s %s\n' "$n" "$who" "$sha" "$verdict"
    printf '           %s\n\n' "$branch"
  done

  fouled=$(printf '%s\n' "$rows" | grep -c '	CONFLICTING	') || fouled=0
  if [ "$fouled" -gt 0 ]; then
    printf '  %s of them cannot land. tools/waveoff.sh <n> says what is in the way.\n\n' "$fouled"
    return 1
  fi
  printf '  All clear.\n\n'
  return 0
}

# --- one of them, in detail -------------------------------------------------
#
# Local and authoritative rather than github's summary: merge-tree performs the
# whole merge in memory, touches no worktree and no index, and names the paths
# that came apart and the way each one did. That last part is the answer worth
# having. "Conflicting" is a state; "main deleted it and you changed it" is
# something a person can act on without opening a file.

detail() {
  n=$1
  need_gh

  state=$(ask "$n" state '.state')
  [ -n "$state" ] || { printf 'waveoff: no pull request #%s\n' "$n" >&2; exit 2; }
  [ "$state" = OPEN ] || {
    printf 'waveoff: #%s is %s. Nothing to wave off.\n' \
      "$n" "$(printf '%s' "$state" | tr 'A-Z' 'a-z')" >&2; exit 2; }

  who=$(ask "$n" author '.author.login')
  branch=$(ask "$n" headRefName '.headRefName')
  BASE=$(ask "$n" baseRefName '.baseRefName')
  fork=$(ask "$n" headRepository,isCrossRepository \
    'if .isCrossRepository then .headRepository.nameWithOwner else "" end')

  # refs/pull/<n>/head is on the base repository whether the branch is or not,
  # so a fork answers here exactly like a branch cut in this clone does. It
  # lands in FETCH_HEAD and is read out of it immediately; no ref is written
  # and nothing in a shared worktree moves.
  git fetch -q origin "refs/pull/$n/head" 2>/dev/null || {
    printf 'waveoff: could not fetch #%s\n' "$n" >&2; exit 2; }
  head=$(git rev-parse FETCH_HEAD) || exit 2
  if git fetch -q origin "$BASE" 2>/dev/null; then
    tip=$(git rev-parse FETCH_HEAD)
  else
    tip=$(git rev-parse "origin/$BASE" 2>/dev/null) || {
      printf 'waveoff: no %s to compare against\n' "$BASE" >&2; exit 2; }
  fi
  mb=$(git merge-base "$tip" "$head") || {
    printf 'waveoff: #%s and %s share no history\n' "$n" "$BASE" >&2; exit 2; }

  short=$(printf '%s' "$head" | cut -c1-7)
  behind=$(git rev-list --count "$mb..$tip")

  printf '\n  pull request #%s, %s\n' "$n" "$who"
  printf '    %s -> %s, head %s\n' "$branch" "$BASE" "$short"
  [ -n "$fork" ] && printf '    from %s - their clone, not ours\n' "$fork"
  printf '    %s commit%s landed on %s since they cut it\n\n' \
    "$behind" "$(plural "$behind")" "$BASE"

  out=$(git merge-tree --write-tree --name-only "$tip" "$head" 2>&1)
  rc=$?
  if [ "$rc" -eq 0 ]; then
    printf '  It merges clean. Whatever github is still saying, git is not.\n\n'
    said "$n" "$short"
    return 0
  fi
  [ "$rc" -eq 1 ] || {
    printf 'waveoff: git could not merge these at all\n%s\n' "$out" >&2; exit 2; }

  # merge-tree prints the tree it built, then one conflicted path per line,
  # then a blank line, then its own commentary. The paths are the list; the
  # commentary is the only place the kind of each conflict is written down.
  paths=$(printf '%s\n' "$out" | awk 'NR > 1 { if ($0 == "") exit; print }')
  count=$(printf '%s\n' "$paths" | grep -c .)

  printf '  It cannot land: %s file%s two people moved at once.\n\n' \
    "$count" "$(plural "$count")"

  printf '%s\n' "$paths" | while IFS= read -r p; do
    [ -n "$p" ] || continue
    kind=$(printf '%s\n' "$out" | grep -F "$p" \
      | sed -n 's/^CONFLICT (\([^)]*\)).*/\1/p' | head -1)
    theirs=$(git rev-list --count "$mb..$head" -- "$p" 2>/dev/null)

    printf '    %s\n' "$p"
    printf '      %s\n' "$(plainly "$kind" "$tip" "$p")"
    git log --format="      on $BASE:  %h  %s" -3 "$mb..$tip" -- "$p" 2>/dev/null
    printf '      on the branch:  %s commit%s\n\n' "$theirs" "$(plural "$theirs")"
  done

  said "$n" "$short"
  printf '  They merge %s into their branch and push. Nobody here can do it for\n' "$BASE"
  printf '  them, and the merge button stays theirs either way.\n\n'
  return 1
}

# The kinds git reports, each in words a person reads once. A kind git invents
# later falls through as itself rather than as a guess at what it meant.
plainly() {
  case "$1" in
    modify/delete)
      if git cat-file -e "$2:$3" 2>/dev/null
        then printf 'the branch deleted it, %s changed it' "$BASE"
        else printf '%s deleted it, the branch changed it' "$BASE"
      fi ;;
    content)        printf 'both sides changed the same lines' ;;
    add/add)        printf 'both sides added a file by this name' ;;
    rename/rename)  printf 'both sides renamed it, to different names' ;;
    rename/delete)  printf 'one side renamed it, the other deleted it' ;;
    rename/add)     printf 'one side renamed something to this, the other added it' ;;
    directory/file) printf 'one side made this a directory, the other a file' ;;
    file/directory) printf 'one side made this a file, the other a directory' ;;
    '')             printf 'git did not say which way' ;;
    *)              printf '%s' "$1" ;;
  esac
}

# --- has anybody said so already --------------------------------------------
#
# A waveoff is about one approach, and an approach is a head sha. Push a new
# commit and it is a new approach, which deserves a fresh answer; push nothing
# and a second comment saying the same thing again is nagging, which is not
# what this is for. The marker in the comment is how a later run tells those
# two apart, and it is why the marker carries a sha rather than a date.

marker() { printf '<!-- waveoff %s -->\n' "$1"; }

said() {
  last=$(ask "$1" comments '.comments[].body' \
    | sed -n 's/.*<!-- waveoff \([0-9a-f]\{7,40\}\) -->.*/\1/p' | tail -1)
  if [ -z "$last" ]; then
    printf '  Nobody has waved this one off yet.\n\n'
  elif [ "$last" = "$2" ]; then
    printf '  Already waved off at %s, and that is still the head. Leave it alone.\n\n' "$2"
  else
    printf '  Waved off at %s, but the head is %s now - a new approach.\n\n' "$last" "$2"
  fi
}

case "${1:---roll}" in
  -h|--help) sed -n '2,37p' "$0" | sed 's/^# \{0,1\}//' ;;
  --roll)    roll ;;
  --marker)
    [ $# -eq 2 ] || { printf 'waveoff: --marker needs a pull request number\n' >&2; exit 2; }
    git fetch -q origin "refs/pull/$2/head" 2>/dev/null || {
      printf 'waveoff: could not fetch #%s\n' "$2" >&2; exit 2; }
    marker "$(git rev-parse FETCH_HEAD | cut -c1-7)" ;;
  -*)        printf 'waveoff: unknown option %s\n' "$1" >&2; exit 2 ;;
  *[!0-9]*)  printf 'waveoff: %s is not a pull request number\n' "$1" >&2; exit 2 ;;
  *)         detail "$1" ;;
esac
