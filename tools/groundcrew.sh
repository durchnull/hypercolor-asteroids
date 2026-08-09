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
# by a commit nobody wrote. Collecting it is three uninteresting steps: take
# it, settle the generated files it argues with, file the result. All three are
# in the way of landing a version and none of them is anybody's work.
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
# **It merges rather than rebases, and that is not a preference.** A rebase
# checks the worktree out to each commit it replays, hooks included - so an old
# commit gets the .githooks/post-commit *it* shipped with, which rebuilds the
# book, which dirties the tree, which stops the replay dead on the next commit.
# The guard that now sits at the top of that hook cannot fix a copy that landed
# before it was written, and never will. A merge touches the hooks once, at the
# end, from the tip, where the fixed one lives. The union merge drivers in
# .gitattributes make the generated files land without a question, and the
# rebuild below throws away whatever nonsense they landed as - before the merge
# is sealed rather than after, because the referee reads a merge's ledger as
# strictly as anybody else's and a union of two ledgers is not what the history
# says (GR12).
#
# The merge commit is the price and it is a fair one: nobody's history is
# rewritten, and the book passes over a merge in silence the way it passes over
# every other piece of its own filing.
#
# What it will not do, and this is the whole of its judgement: **it only ever
# rebases over commits the book does not call a person's.** tools/chronicle.sh
# --pilots is the roster and it already knows a machine from a pilot; anything
# authored by somebody on that list is real work, and CLAUDE.md is explicit
# that you do not build on somebody's fresh work without reading it. So a
# person's commit stops this dead and prints their subject line instead.
#
# GR7 is not in play at all, which is the other quiet advantage of merging: not
# one existing commit changes its sha, so there is nothing here that could
# rewrite a history somebody else is already holding.
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
  printf '  git pull yourself, because this tool does not get to take another\n'
  printf '  pilot'\''s work on your behalf without you having read a line of it.\n'
  printf '  Not --rebase: replaying anything here runs old post-commit hooks\n'
  printf '  that rebuild the book and stop the replay dead. This house merges.\n\n'
  exit 1
fi

if [ "$MODE" = check ]; then
  printf '\n  %s paperwork commit(s) waiting from the ground crew:\n\n' "$BEHIND"
  git log "HEAD..$UP" --no-merges --format='    %h  %s' 2>/dev/null
  printf '\n  tools/groundcrew.sh takes them.\n\n'
  exit 1
fi

# --- take it ----------------------------------------------------------------

# Their work is theirs. A merge that has to stop and ask about a generated file
# should not also be holding somebody's half-finished edit hostage.
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  printf '\n  the working tree is dirty, and the merge would take it along.\n'
  printf '  commit or stash first, then run this again.\n\n'
  exit 1
fi

WAS=$(git rev-parse HEAD)
say '\n  the ground crew filed %s while you were flying. taking it.\n' "$BEHIND"

# Staged rather than sealed, and the rebuild goes in before the seal. What the
# union drivers make of a generated file is not something to commit and then
# apologise for one commit later: the ledger in particular comes out of a union
# with two lines where the history says one, and the referee reads a merge's
# ledger exactly as strictly as anybody else's (GR12) - so the old order got
# the merge refused by the commit-msg hook every single time, with a red line,
# after the working tree had already been changed.
#
# Rebuild first and the merge lands already saying what the history says.
if ! git merge --no-commit --no-ff "$UP" >/dev/null 2>&1; then
  git merge --abort >/dev/null 2>&1
  git reset --hard "$WAS" >/dev/null 2>&1
  printf '\n  the merge did not go through, and nothing was changed - you are\n'
  printf '  exactly where you started. git merge origin/%s by hand to see why.\n\n' "$BRANCH"
  exit 1
fi

# Whatever the union drivers just made of the generated files, thrown away and
# written again. This is the one rebuild, and it is why a conflict in docs/ was
# never worth stopping anybody for.
sh "$BOOK" >/dev/null 2>&1 || :
sh tools/tally.sh >/dev/null 2>&1 || :
git add -A -- docs src/game/ledger.js >/dev/null 2>&1 || :

if ! git commit -q --no-edit -m "The ground crew's paperwork, collected" >/dev/null 2>&1; then
  git merge --abort >/dev/null 2>&1
  git reset --hard "$WAS" >/dev/null 2>&1
  printf '\n  the merge was taken and the referee would not seal it, so nothing\n'
  printf '  was changed - you are exactly where you started. git merge\n'
  printf '  origin/%s by hand to see what it objected to.\n\n' "$BRANCH"
  exit 1
fi

# And the merge commit is a commit, so the book is a commit out of date again
# the moment it lands - the post-commit hook says so by leaving the pages in
# the tree. That is the ordinary state of every landing here and it files the
# same way. Often there is nothing: a merge that changed no generated file
# leaves nothing to file.
if [ -n "$(git status --porcelain -- docs src/game/ledger.js 2>/dev/null)" ]; then
  git add -A -- docs src/game/ledger.js >/dev/null 2>&1
  git commit -q -m "The paperwork from the ground crew's filing, filed" >/dev/null 2>&1 || :
  say '  the book was rebuilt over the top and filed.\n'
fi

say '  collected, and nothing of yours moved. clear to push.\n\n'
exit 0
