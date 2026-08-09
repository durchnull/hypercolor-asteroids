#!/bin/sh
# ---------------------------------------------------------------------------
# groundcrew.sh - take the ground crew's paperwork off the pilot's hands.
#
# .github/workflows/book.yml rebuilds the book after every push to main and
# commits the result as "Ground Crew". Those commits are pure paperwork: they
# only ever touch generated files, they are never a version, and the book
# passes over them in silence. Nobody reads them and nobody should have to.
#
# But they land on main while a pilot is working, and then the pilot is behind
# by a commit nobody wrote. Pulling it is a rebase; a rebase over generated
# files is a pile of union merges that mean nothing until the book is rebuilt;
# and the rebuild only settles once the replay is finished. Three steps, none
# of them interesting, all of them in the way of landing a version.
#
# So: this does the three steps.
#
#   tools/groundcrew.sh            fetch, take the paperwork, rebuild, report
#   tools/groundcrew.sh --check    say what is waiting and change nothing
#   tools/groundcrew.sh --quiet    only speak when something happened
#
# Exit 0 = clear, whether or not anything was waiting. Exit 1 = something is
# waiting that this must not touch, and the pilot has to look at it.
#
# What it will not do, and this is the whole of its judgement: **it only ever
# rebases over commits the book does not call a person's.** tools/chronicle.sh
# --pilots is the roster and it already knows a machine from a pilot; anything
# authored by somebody on that list is real work, and CLAUDE.md is explicit
# that you do not build on somebody's fresh work without reading it. So a
# person's commit stops this dead and prints their subject line instead.
#
# GR7 is not bent by the rebase. Rebasing onto origin/main rewrites exactly the
# commits that are not on origin/main - the ones nobody else has - and leaves
# every commit anybody else could be holding exactly where it is. The pre-push
# hook checks that independently and would refuse if this were wrong.
#
# GR2's ban on the network is about the cabinet, not about git: this talks to
# the same remote `git push` does, and to nothing else. Offline is not an error
# here. A fetch that cannot reach anything says so once and exits clear, and
# the pilot carries on landing exactly as they would on a plane.
# ---------------------------------------------------------------------------
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  printf 'groundcrew: not a git repo\n' >&2; exit 1; }
cd "$ROOT" || exit 1

BOOK=tools/chronicle.sh
MODE=take
QUIET=0

while [ $# -gt 0 ]; do
  case "$1" in
    --check) MODE=check ;;
    --quiet) QUIET=1 ;;
    -h|--help) sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) printf 'groundcrew: unknown option %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

say() { [ "$QUIET" = 1 ] || printf "$@"; }

# No remote, no ground crew. A clone somebody made to read the code is not
# waiting on anybody's paperwork.
git remote get-url origin >/dev/null 2>&1 || exit 0

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0
case "$BRANCH" in
  main|master) ;;
  # A working branch answers to whatever its pull request does. The crew only
  # ever pushes to main, so there is nothing of theirs to collect here.
  *) exit 0 ;;
esac

# --- what is waiting --------------------------------------------------------

if ! git fetch --quiet origin "$BRANCH" 2>/dev/null; then
  say '\n  the ground crew could not be reached. carry on; this is not an error.\n\n'
  exit 0
fi

UP=$(git rev-parse --verify -q "origin/$BRANCH") || exit 0
BEHIND=$(git rev-list --count "HEAD..$UP" 2>/dev/null) || exit 0
case "$BEHIND" in ''|*[!0-9]*) exit 0 ;; esac

if [ "$BEHIND" = 0 ]; then
  say '  nothing waiting from the ground crew.\n'
  exit 0
fi

# Everybody the book calls a person, as of the far end - so a pilot whose very
# first commit is one of the ones waiting still reads as a pilot rather than as
# a machine.
git log "HEAD..$UP" --no-merges --format='%an' 2>/dev/null | LC_ALL=C sort -u > "$ROOT/.git/gc-authors" || exit 1
sh "$BOOK" --pilots "$UP" 2>/dev/null | LC_ALL=C sort -u > "$ROOT/.git/gc-pilots" || :
PEOPLE=$(LC_ALL=C comm -12 "$ROOT/.git/gc-authors" "$ROOT/.git/gc-pilots")
rm -f "$ROOT/.git/gc-authors" "$ROOT/.git/gc-pilots"

if [ -n "$PEOPLE" ]; then
  printf '\n  %s commit(s) waiting on origin/%s, and not all of it is paperwork:\n\n' \
         "$BEHIND" "$BRANCH"
  git log "HEAD..$UP" --no-merges --format='    %h  %an%n          %s' 2>/dev/null
  printf '\n  Somebody flew that. Read it before you build on top of it - then\n'
  printf '  git pull --rebase yourself, because this tool does not get to\n'
  printf '  replay another pilot'\''s work behind your back.\n\n'
  exit 1
fi

if [ "$MODE" = check ]; then
  printf '\n  %s paperwork commit(s) waiting from the ground crew:\n\n' "$BEHIND"
  git log "HEAD..$UP" --no-merges --format='    %h  %s' 2>/dev/null
  printf '\n  tools/groundcrew.sh takes them.\n\n'
  exit 1
fi

# --- take it ----------------------------------------------------------------

# Their work is theirs. This replays commits; it does not get to carry
# somebody's half-finished edit through a rebase with them.
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  printf '\n  the working tree is dirty, and a replay would drag it along.\n'
  printf '  commit or stash first, then run this again.\n\n'
  exit 1
fi

AHEAD=$(git rev-list --count "$UP..HEAD" 2>/dev/null) || AHEAD=0
say '\n  the ground crew filed %s while you were flying. taking it.\n' "$BEHIND"

if ! git rebase "$UP" >/dev/null 2>&1; then
  git rebase --abort >/dev/null 2>&1
  printf '\n  the replay did not go through, and nothing was changed - you are\n'
  printf '  exactly where you started. git rebase origin/%s by hand to see why.\n\n' "$BRANCH"
  exit 1
fi

# The pages the replay walked past. post-commit deliberately writes nothing
# mid-rebase, so this is the one rebuild, against a history that is now true.
sh "$BOOK" >/dev/null 2>&1 || :
sh tools/tally.sh >/dev/null 2>&1 || :

if [ -n "$(git status --porcelain -- docs src/game/ledger.js 2>/dev/null)" ]; then
  git add -A -- docs src/game/ledger.js >/dev/null 2>&1
  git commit -q -m "The paperwork from the ground crew's $BEHIND, filed" >/dev/null 2>&1 || :
  say '  the book was rebuilt over the top and filed.\n'
fi

say '  %s of your own commits replayed. clear to push.\n\n' "$AHEAD"
exit 0
