#!/bin/sh
# ---------------------------------------------------------------------------
# labels.sh - what a change is about, in the words the book already uses.
#
# The book puts marks on a chapter: nine small badges saying what that commit
# moved - the game, the game within it, the ui, the music, the controls, the
# engine, the chronicle, the rules, the notes. They are the first thing a
# reader sees on the cover and the first thing a pilot sees on a chapter.
#
# A pull request wants the same answer in a form github can colour, so this
# asks for it and prints label names. It does not classify anything: the
# question lives in tools/chronicle.sh, --marks is the handle on it, and this
# file is a colour chart and a gh call. The badge on the chapter and the label
# on the strip are therefore the same word, which they were not for the first
# thirty-two versions - this used to mirror kindof(), the function that picks
# the silhouette for the plate art, and kindof() answers where a path sits
# rather than what a commit moved. Two vocabularies, both defensible, quietly
# disagreeing about src/render/ on every pull request that touched it.
#
#   tools/labels.sh                what the working tree's changes are about
#   tools/labels.sh <range>        the same question about a range of commits
#   tools/labels.sh --paths        paths on stdin, one per line
#   tools/labels.sh --list         every label, its colour and what it means
#   tools/labels.sh --install      create them on the remote (needs gh)
#   tools/labels.sh --retired      labels this file no longer prints, for
#                                  somebody deciding what to delete
# ---------------------------------------------------------------------------
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) && cd "$ROOT" || :

# name  colour  description, and the names are markname() in tools/chronicle.sh
# - a label this file spells differently is a label the strip cannot add.
#
# The colours are the cabinet's own, out of styles/tokens.css, so a mark is the
# same colour on the chapter and on the pull request. Two of them are the same
# grey on purpose: the rules and the notes are real work and not the game, and
# the book has drawn that distinction in exactly this colour since the marks
# existed. Descriptions stay under a hundred characters, which is all github
# keeps.
table() {
  cat <<'EOF'
game	ff3ec8	src/ - the field and the rules of a flight. The book draws it as the ship you fly.
game within	b6ff3d	The events, the seat, the tally, the tape. The game the pilots play on each other.
ui	21f3ff	Panels, phosphor, the palette, the page itself. What the pilot actually looks at.
music	ffb020	src/audio/ - the graph, the song, the one-shots.
controls	a04bff	src/input/ - both seats and the touch buttons.
engine	3dffb0	src/core/ - the registry, the loop, the state everything else hangs off.
chronicle	f2e9ff	The hand that writes the book. Not the pages it wrote - those are not an event.
rules	9a86bd	The rules and everything that enforces them. GR10 territory.
notes	9a86bd	Real work that is neither the game nor the book. The readme, the plans, the rest.
EOF
}

# What the eleven buckets this file used to print were called. Kept because a
# label is not only a colour on a list - it is on every pull request that ever
# wore it, and deleting one is a decision somebody should make while looking at
# the names rather than from memory. Nothing reads this but a person.
retired() {
  cat <<'EOF'
events
entities
core
render
audio
input
screen
book
EOF
}

# The one question, asked. Paths in, marks out, already deduplicated and in the
# order the book prints them - so a pull request lists them the way the chapter
# it becomes will.
from_stdin() {
  sh tools/chronicle.sh --marks
}

case "${1:---worktree}" in
  -h|--help)
    sed -n '2,27p' "$0" | sed 's/^# \{0,1\}//'
    ;;

  --list)
    table | while IFS='	' read -r name colour desc; do
      printf '  %-12s #%s  %s\n' "$name" "$colour" "$desc"
    done
    ;;

  --retired)
    retired | while IFS= read -r name; do printf '  %s\n' "$name"; done
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
    # What is uncommitted, what is staged and what is not tracked yet, which is
    # the question a pilot mid-branch is actually asking. The third of those
    # was missing and mattered: a feature here is a new file (GR3), so the one
    # change most worth previewing was the one that read as empty.
    { git diff --name-only HEAD 2>/dev/null
      git diff --cached --name-only 2>/dev/null
      git ls-files --others --exclude-standard 2>/dev/null; } \
      | from_stdin
    ;;

  -*)
    printf 'labels: unknown option %s\n' "$1" >&2; exit 2
    ;;

  *)
    git diff --name-only "$1" 2>/dev/null | from_stdin
    ;;
esac
