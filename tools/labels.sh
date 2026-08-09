#!/bin/sh
# ---------------------------------------------------------------------------
# labels.sh - what a change is about, in the words the book already uses.
#
# tools/chronicle.sh has a function called kindof() that decides what to draw
# for a path: a trap is a mine, the song is a note, a panel is a panel, a rule
# is a wrench. That is the only classification this project has ever had, and
# it is a good one, because it is about what a path *is* rather than where it
# happens to sit.
#
# A pull request wants the same answer in a form github can colour, so this
# reads the same buckets and prints label names for them. The flight strip
# workflow puts them on. Nothing here keeps a second opinion about what a path
# is - if a bucket ever moves, it moves in kindof() and then here, and the two
# lists sit ten lines apart in this file so nobody can pretend not to have seen
# it.
#
#   tools/labels.sh                what the working tree's changes are about
#   tools/labels.sh <range>        the same question about a range of commits
#   tools/labels.sh --paths        paths on stdin, one per line
#   tools/labels.sh --list         every label, its colour and what it means
#   tools/labels.sh --install      create them on the remote (needs gh)
#
# The label names are the pilot's words rather than the book's glyph names. A
# label reading "gear" tells a reader nothing and "game" tells them where to
# look; the glyph is kept in the description so the two readings stay tied to
# each other rather than drifting into two vocabularies.
# ---------------------------------------------------------------------------
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) && cd "$ROOT" || :

# name  colour  description. The colours are the cabinet's, roughly - a trap is
# the red the mines flash, the book is the brown of a thing on a shelf.
table() {
  cat <<'EOF'
events	e8175d	src/events/ - somebody's trap. The book draws it as a mine.
entities	ff7a18	src/entities/ - things in the field. Rocks, kraken, portals, the Falcon.
game	ffd23f	src/game/ - the rules of a flight. The book draws it as a gear.
ui	2ee6a8	src/ui/ - panels. Hud, lobby, overlays, the field guide.
core	1fb6ff	src/core/ - the registry, the loop, the state, the manifest. An atom.
render	8b5cf6	src/render/ - phosphor, bloom, palette, the CRT. A prism.
audio	ff4ecd	src/audio/ - the graph, the song, the one-shots. A note.
input	a3e635	src/input/ - both seats and the touch buttons. A keycap.
screen	00c9b1	The page the cabinet opens as, and the sheet that dresses it.
rules	4b5563	The rules and everything that enforces them. GR10 territory.
book	b08968	docs/ - the chronicle, the plates, the rankings, the paperwork.
EOF
}

# The same buckets kindof() draws, in the same order, answering with a word a
# reader can act on. A path nobody classified gets nothing rather than a
# catch-all: an "other" label on half the pull requests is noise wearing a
# colour.
bucket() {
  case "$1" in
    src/events/*)    printf 'events\n' ;;
    src/entities/*)  printf 'entities\n' ;;
    src/game/*)      printf 'game\n' ;;
    src/core/*)      printf 'core\n' ;;
    src/render/*)    printf 'render\n' ;;
    src/audio/*)     printf 'audio\n' ;;
    src/input/*)     printf 'input\n' ;;
    src/ui/*)        printf 'ui\n' ;;
    # The manifest and the loader. kindof() calls them a wrench because they
    # are not in a subdirectory; a reviewer reading "core" is better served,
    # and CLAUDE.md describes them in the same breath as src/core/ anyway.
    src/*.js)        printf 'core\n' ;;
    # A bucket nobody has drawn yet. Nothing, rather than a guess that would
    # read as certainty on the pull request.
    src/*)           ;;
    docs/*)          printf 'book\n' ;;
    CLAUDE.md|GOLDEN_RULES.md|.gitattributes) printf 'rules\n' ;;
    tools/*|.githooks/*|.github/*|.claude/*)  printf 'rules\n' ;;
    # Whatever is left of the game surface once everything under src/ has been
    # answered above: the page the cabinet opens as, and what dresses it.
    #
    # Which paths those *are* is not this file's question. tools/chronicle.sh
    # owns it, GAME below is it asking rather than remembering, and
    # tools/lockstep.sh is the reason nobody here gets to keep a second copy -
    # it caught the first draft of this line doing exactly that.
    *)
      for g in $GAME; do
        case "$1" in "$g"|"$g"/*) printf 'screen\n'; return ;; esac
      done
      ;;
  esac
}

GAME=$(sh tools/chronicle.sh --game-paths 2>/dev/null || :)

from_stdin() {
  while IFS= read -r p; do
    [ -n "$p" ] && bucket "$p"
  done | sort -u
}

case "${1:---worktree}" in
  -h|--help)
    sed -n '2,28p' "$0" | sed 's/^# \{0,1\}//'
    ;;

  --list)
    table | while IFS='	' read -r name colour desc; do
      printf '  %-10s #%s  %s\n' "$name" "$colour" "$desc"
    done
    ;;

  # Once per repository, and safe to run again - --force updates a label that
  # is already there rather than failing on it, so a colour or a sentence can
  # be corrected without anybody deleting anything.
  --install)
    command -v gh >/dev/null 2>&1 || {
      printf 'labels: needs the gh cli to talk to github\n' >&2; exit 1; }
    table | while IFS='	' read -r name colour desc; do
      gh label create "$name" --color "$colour" --description "$desc" --force \
        >/dev/null 2>&1 && printf '  %s\n' "$name"
    done
    ;;

  --paths)
    from_stdin
    ;;

  --worktree)
    # What is uncommitted plus what is staged, which is the question a pilot
    # mid-branch is actually asking.
    { git diff --name-only HEAD 2>/dev/null; git diff --cached --name-only 2>/dev/null; } \
      | from_stdin
    ;;

  -*)
    printf 'labels: unknown option %s\n' "$1" >&2; exit 2
    ;;

  *)
    git diff --name-only "$1" 2>/dev/null | from_stdin
    ;;
esac
