#!/bin/sh
# ---------------------------------------------------------------------------
# chronicle.sh - the book, and the numbers it counts.
#
# A version is a commit that changed the game: index.html, src/ or styles/, the
# files that ship in the page you open. Nothing else in this repository is the
# game. Rewriting the rules, ranking a flight, fixing a line in the README -
# real work, all of it, but the cabinet is the same cabinet afterwards, and the
# next pilot has nothing new to find out by playing. So it does not get a
# version. It gets a mention - with one exception. The book filing its own
# pages is not a story: a commit that touched nothing but the book's generated
# files is passed over in silence, on the cover and in the digest alike, unless
# it carries an override, a rule change, a ledger receipt or a breach. The
# history keeps every such commit either way; the book just stops narrating
# its own paperwork.
#
# The numbers are counted, never stored: v1 is the first commit that touched
# the game and the newest is however many there have been since. Nobody assigns
# them, nobody can skip one, and a clone that never installed the hooks arrives
# at exactly the same numbers as everybody else. That is the point - the
# version is a fact about the history, not a file somebody has to remember to
# bump.
#
# Every version also carries a tagline, one line on what happened to the game.
# tools/tagline.sh writes it and docs/taglines.tsv keeps it, once, for good.
#
# The book is one page per version. docs/index.html is the cover - the roster,
# then every entry in order, newest first. docs/v<N>.html is the chapter, and it
# is a page rather than a paragraph: the tagline in letters you can read from
# across the room, the numbers that version made, and a picture of the commit
# itself. Both are generated, both are committed, and a page stands on its own -
# somebody who has never cloned this can be handed a link to v7.
#
# The entries are shelved rather than listed. A book is a run of chapters one
# pilot flew with nobody else landing in between, and the gap is the whole idea:
# fly three, hand the cabinet over, take it back and fly three more, and that is
# two books rather than one, because a turn that belonged to somebody else
# happened in the middle. Books are numbered oldest first like the versions are,
# so book I holds v1 in every clone forever; each one carries the arithmetic of
# its whole run, which is the one thing no single chapter inside it can say. An
# interlude is shelved with whichever book was being written while it happened.
# The cover opens them; the dock at the foot of a chapter is a shelf of spines,
# and pressing one stacks that book up over the dock without turning a page -
# a book opening is not a page turning, and the chapter is a second press.
#
# And every chapter wears its marks: which parts of the cabinet the commit
# moved, drawn rather than listed, in the vocabulary the book already uses out
# loud - the game, the game within, the ui, the music, the controls, the engine,
# the chronicle, the rules, the notes. They are worked out from the paths alone,
# which is what makes them true of every commit ever landed rather than only of
# the ones somebody remembered to tag. Two rules keep them honest: the book
# files its own pages onto every commit there is, so its own output is never a
# mark, and a path is asked what it is for rather than where it sits -
# src/ui/debrief.js is among the panels and belongs to the game within the game.
#
# The picture is not decoration and it is not the same picture twice. Every
# shape is a sector the commit touched, drawn as the thing it is - an event is a
# mine, the rules are a gear, the song is a note, a panel is a panel - sized by
# how much of it moved and coloured by which part of the cabinet it was. The
# diff picks the pilot's move: wreckage is shot down and sheds shards, a new
# arrival rides in on a tow beam and rings while it settles, a file that came
# back lighter than it went has a bite taken out of it, a tuning pass gets a
# reticle where a shot would be, and anything else is the standing order - fire
# at the biggest thing you moved. And the words get a say as well as the diff:
# a tagline about speed earns streaks, a tagline about threes draws two more of
# the thing, and every other tagline earns nothing, which is what keeps it a
# remark. The seed is the commit hash, so a version draws the identical field on
# every machine and in every clone, forever. That is what makes a generated file
# worth committing: rebuild it anywhere and the bytes come back the same.
#
# A chapter can also carry a plate: a painted scene of whatever its tagline says
# happened, asked for once by tools/chronicle-art.sh and kept in docs/art/ from
# then on. That one is not arithmetic and could not be - it is asked for on one
# machine, by somebody who has credentials, and committed like any other picture
# in any other book. Which is why nothing here depends on it: a version with no
# plate has the drawn field and the chapter reads exactly as it did before.
#
# The pilots have faces for the same reason and by the same route, out of
# docs/faces/ and asked for by the same script. A face belongs to a person
# rather than to a commit, so it turns up in all three places this book writes
# somebody's name - the roster on the cover, the line under each version in the
# contents, and the head of every chapter they flew - and it is the identical
# picture in each, because it was only ever painted once. A pilot with no face
# reads as a name, exactly as everybody did before there were any.
#
# The cabinet reads the book too. docs/chronicle.js is the last thing written
# here: the newest chapter, the last few plates and the top of the board, in
# the one shape a page can read without fetching anything (GR2). The splash
# screen draws its doorway out of that file and does without it when a clone
# has never run this tool, exactly as it does without the faces.
#
#   tools/chronicle.sh                rewrite docs/index.html
#   tools/chronicle.sh --version      the version on the cabinet now
#   tools/chronicle.sh --next         the version the next commit becomes, or
#                                     "-" if what is staged leaves the game alone
#   tools/chronicle.sh --recent N     plain text digest of the last N stories,
#                                     walking back however far that takes
#   tools/chronicle.sh --moved [rev]  quietly: did that touch the game?
#   tools/chronicle.sh --game-paths   what counts as the game, one path a line
#   tools/chronicle.sh --versions [r] every version, oldest first, as sha
#   tools/chronicle.sh --pilots [r]   everybody the history calls a person
#   tools/chronicle.sh --run [r]      how many versions in a row one pilot has
#                                     landed, and who - GR15's spine
#   tools/chronicle.sh --is-game P... which of those paths are the game
#   tools/chronicle.sh --marks P...   what a commit touching those paths moved,
#                                     as the badges say it - what a pull
#                                     request gets labelled with
#   tools/chronicle.sh --skips        every commit the referee provably never
#                                     saw, as the ledger reads it
#   tools/chronicle.sh --audit        the same list as the chapters read it,
#                                     and nothing else the builder does
#   tools/chronicle.sh --digest-silence  every commit the digest walks past as
#                                     the book's own filing
#   tools/chronicle.sh --book-silence the same question the builder answers,
#                                     and nothing else the builder does
#
# The last six are the same two questions in six shapes, and this file is the only
# place any of it is answered - tools/flights.sh, tools/tally.sh,
# tools/chronicle-art.sh and tools/tagline.sh all ask rather than keeping a copy.
# tools/lockstep.sh is what makes that a fact rather than a promise.
#
# What a commit can put in the book, all optional, all read from the message:
#
#   Chronicle: a line for the book, written for a reader, not a reviewer
#   Tagline: what happened to the game, in one line, instead of the machine's
#   Golden-Rule-Override: GR4 - <why>      recorded forever, as agreed
#   Rule-Change: <why>                     recorded forever, as agreed
#   Tally: <pilot> - <n>                   not written by a pilot at all: the
#                                          hooks put it on the ledger commit
#                                          they land after somebody bends a
#                                          rule, and the book quotes it
#   Golden-Rule-Breach: GR8 <pilot> - <why>  the table calling a landing across
#                                          the fairness line (GR8). It charges
#                                          the pilot it names, not the scribe,
#                                          and the book says the table spoke
#
# And one thing a commit cannot keep out. Every version is re-refereed as the
# book is written, against the rules that can be proved from the commit alone:
# GR4, GR5, GR6, GR10, GR11. Break one of those and write no override line and
# the commit could not have got past the referee at all - which means somebody
# turned the referee off. That gets an entry too, in the chapter and in the
# roster, and it is the one line in the book that nobody chose to write.
#
# The arithmetic is the referee's own, deliberately in its forgiving form:
# docs/ is generated and never counts against anybody, and anywhere this check
# and tools/golden-check.sh could disagree, this one stays quiet. The book may
# miss a cheat. It may not invent one.
#
# The book speaks asteroid, not git. The numbers come off the history, but a
# chapter is read for fun, so nothing in it says "files changed" or
# "insertions" when it can say what happened to the field instead:
#
#   commit          -> a version, flown by a pilot
#   files changed   -> sectors touched
#   insertions      -> lines aboard
#   deletions       -> lines jettisoned
#   the subject     -> landed as "..."
#   no Chronicle:   -> nobody wrote this one down
#   not a version   -> an interlude: while vN was on the cabinet, ...
#   the book's own paperwork -> nothing at all, anywhere the book speaks
#   which paths moved -> the marks a chapter wears
#   one pilot in a row -> a book, and every book is a shelf
#
# The one exception is machinery somebody has to type: the checkout command
# under each chapter stays literal, because a joke you cannot paste into a
# terminal is not worth the confusion. Nothing else explains itself - the book
# is a book, and how it got written is this file's business, not the reader's.
# Keep new vocabulary in the same register as the rest of the project - dry,
# and no exclamation marks.
# ---------------------------------------------------------------------------
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$ROOT" || exit 0

# The game is what ships in the page you open. Everything else is scaffolding
# around the cabinet, and scaffolding does not get a version number. This list
# is the only definition; tools/tagline.sh and the hooks ask for it rather than
# keeping a second copy that can drift.
GAME='index.html src styles'

# ... except for one file that lives under src/ and is not the game.
# src/game/ledger.js is generated from the history by tools/tally.sh and rides
# along with whatever commit comes next, so it turns up in filing commits that
# changed nothing anybody can play - and one line of it was enough to make such
# a commit a version, with a chapter and a painted plate to itself. Worse, a
# workflow files the book after every push, so the count grew by one per push
# rather than by one per idea.
#
# tools/flights.sh and tools/tally.sh both already made exactly this judgement,
# each with a comment saying so. Neither of them makes it any more: they ask
# --versions below, and this file is where the exception lives.
NOTGAME=':!src/game/ledger.js'

# And not every name in the history is somebody. A workflow files the book's own
# paperwork after every push and has to author that commit as somebody, so an
# account that is not a person is in the log - and read naively it flies versions
# and sits on the roster like anybody else. It did both.
#
# It matters most where a picture is involved: a face is painted once and never
# repainted, so a machine that slips onto the roster is in the book for good.
# tools/chronicle-art.sh used to keep its own copy of this test for exactly that
# reason, and a copy is a promise rather than a fact. It asks --pilots now, and
# this is the only place the question is answered.
#
# Filtered on the address rather than the name, because the name is somebody's
# free choice and the [bot] suffix is github's own mark. The literal name this
# repository's workflow commits under is spelled out beside it, so that a future
# reader can find both ends of the arrangement from either one.
#
# Both names it has ever filed under are spelled out, because the history keeps
# the old ones whatever the workflow is called this year. The address alone
# would catch them all today; the day somebody narrows that test, a name the
# log still carries and this list has forgotten is a machine on the roster.
MACHINE='
function is_machine(who, mail) {
  # Where the address is the last field of a record it arrives carrying the
  # newline that ended it, and the anchored form below would miss on that alone.
  sub(/[[:space:]]+$/, "", mail)
  return (who == "Ground Crew" ||               # .github/workflows/book.yml
          who == "the book" ||                  # what it filed under before
          mail ~ /\[bot\]@/ ||                  # github marks its own
          mail ~ /^actions@github\.com$/)
}
# The roster, in an order every awk agrees on. `for (p in pilots)` hands the
# names back in whatever order the implementation own hash felt like, and the
# three awks this book gets built with do not agree - so the cover listed the
# pilots one way on a mac and another way on the runner, and whoever rebuilt
# last rewrote it for no reason at all. Both ends of the book ask this instead:
# most versions first, and a tie goes to the name.
function roster_order(n, out,   p, i, j, q, c) {
  c = 0
  for (p in n) out[++c] = p
  for (i = 2; i <= c; i++) {
    q = out[i]
    for (j = i - 1; j >= 1 && (n[q] > n[out[j]] || (n[q] == n[out[j]] && q < out[j])); j--)
      out[j + 1] = out[j]
    out[j + 1] = q
  }
  return c
}
'

# The same question asked about one seat rather than about a stream. It used to
# be a second implementation in shell, sitting under the first and asked to stay
# in step with it by a comment. It is the same awk, handed one record - which
# costs a process, so the callers below ask it last and only when the answer can
# still change anything.
US=$(printf '\037')
is_machine() {
  printf '%s\n' "$1" \
    | awk -F'\037' "$MACHINE"'{ found = is_machine($1, $2) } END { exit !found }'
}

# --audit and --book-silence below, neither of which can exit where it is asked
# for: both want a decision that lives inside the builder and none of what the
# builder is for. Set here so that the guards on the build have something to
# read whichever way this was run. QUIET is the pair of them, and it is what
# every step that would leave something behind asks.
AUDIT=0
SILENCE=0

git rev-parse --verify -q HEAD >/dev/null 2>&1 || { echo "no history yet" >&2; exit 0; }

# Every commit that gets a chapter, oldest first - which is the order a capped
# painting run wants, and the order a count wants to be counted in.
#
# --full-history so that path limiting does not quietly simplify a version out
# of the list, and one pass through is_machine because a version is something a
# person landed.
#
# This is the one answer. TOTAL below counts it, --versions prints it,
# tools/flights.sh and tools/tally.sh fold it into their own streams, and
# tools/chronicle-art.sh paints from it. What cannot read it is the awk is_game()
# further down, which is asked about a path inside a stream that is already
# flowing and cannot stop to run git - so that one is a second reader by
# necessity rather than by choice, and tools/lockstep.sh puts the same commits
# to both and fails when they disagree.
versions() {
  git log --format='%H%x1f%an%x1f%ae' --full-history --no-merges --reverse "${1:-HEAD}" \
          -- $GAME "$NOTGAME" 2>/dev/null \
    | awk -F'\037' "$MACHINE"'!is_machine($2, $3) { print $1 }'
}

# The run the cabinet is in: how many versions in a row the pilot who landed
# the newest one has landed, and their name, tab separated.
#
# The book already shelves the history exactly this way - a book is a run of
# chapters one pilot flew with nobody else landing in between - and GR15 asks
# the same question of the referee. So it is asked here rather than counted a
# second time in tools/golden-check.sh, which is the arrangement every other
# derived number in this project is under.
#
# One pass, with the versions folded into the same stream the log comes down,
# the way tools/flights.sh reads its meter: the alternative is a fork per
# commit to ask who wrote it, in a hook, on every landing.
run_of() {
  { versions "${1:-HEAD}" | awk '{ printf "\036V\037%s", $1 }'
    git log "${1:-HEAD}" --no-merges --format='%x1e%H%x1f%an%x1f' 2>/dev/null; } \
  | awk 'BEGIN { RS = "\036"; FS = "\037" }
      $1 == "V" { ver[$2] = 1; next }

      # sha, author, and the newline the trailing separator parks in $3. The
      # log arrives newest first, so the first version down it is the head of
      # the run and the first different name ends it.
      NF >= 3 {
        if (!($1 in ver)) next
        if (who == "") who = $2
        else if ($2 != who) exit
        n++
      }
      END { printf "%d\t%s\n", n + 0, who }'
}

# Everybody the history has ever heard of, machines excepted. The roster on the
# cover, and the list tools/chronicle-art.sh paints a face from.
pilots() {
  git log --format='%an%x1f%ae' "${1:-HEAD}" 2>/dev/null \
    | awk -F'\037' "$MACHINE"'$1 != "" && !is_machine($1, $2) { print $1 }' \
    | sort -u
}

# Did this commit touch the game? With no argument: will the next one?
#
# The cheap half of the question first. Most commits leave the cabinet alone,
# and for those the answer is one command and nobody has to be identified at
# all - which matters because this is asked once per commit by the hooks, by the
# referee and, seventeen times in a row, by tools/lockstep.sh.
moved() {
  if [ -n "${1:-}" ]; then
    hit=$(git diff-tree --root -r --name-only --no-commit-id "$1" -- $GAME "$NOTGAME" 2>/dev/null)
  elif [ -n "$(git diff --cached --name-only HEAD 2>/dev/null)" ]; then
    # Something is staged, so the index is the question being asked - which is
    # also the case inside the hooks, including for git commit -a.
    hit=$(git diff --cached --name-only HEAD -- $GAME "$NOTGAME" 2>/dev/null)
  else
    # Nobody is committing; a pilot is asking mid-flight. Answer about the
    # worktree, untracked files included - a brand new feature is a file git
    # has never heard of.
    hit=$(git status --porcelain -- $GAME "$NOTGAME" 2>/dev/null)
  fi
  [ -n "$hit" ] || return 1

  # And then who flew it, because a machine's commit is not a version whoever is
  # asking. The list above leaves those out and the book declines to file them,
  # so this has to agree or the hooks stamp a number onto a commit that never
  # gets a chapter.
  if [ -n "${1:-}" ]; then
    seat=$(git log -1 --format="%an${US}%ae" "$1" 2>/dev/null)
  else
    seat="$(git config user.name 2>/dev/null)$US$(git config user.email 2>/dev/null)"
  fi
  is_machine "$seat" && return 1
  return 0
}

case "${1:-}" in
  --game-paths) printf '%s\n' $GAME; exit 0 ;;
  --moved)      moved "${2:-}"; exit $? ;;
  # The same function asked about a list, once, in one process. tools/lockstep.sh
  # asks it about every commit in a fixture history, and this file is seven
  # thousand lines for a shell to read before it can answer anything - so the
  # question that gets asked in a loop is worth being able to ask in one.
  --moved-each)
    shift
    for r in "$@"; do
      if moved "$r"; then printf 'yes\t%s\n' "$r"; else printf 'no\t%s\n' "$r"; fi
    done
    exit 0 ;;
  # Every version, oldest first, optionally as of some other tip than HEAD -
  # which is what tools/flights.sh wants when it reads the meter as it stood
  # before a commit landed.
  #
  # This exists because --game-paths was being read as the answer to a different
  # question. A path list says what the game is; it cannot say that the generated
  # ledger under src/ is not the game, and it cannot say that nobody flew the
  # commit a workflow authored. tools/chronicle-art.sh asked it anyway and
  # painted a plate for two commits the book does not file - a Cloudflare call
  # and a picture spent on a chapter that will never exist.
  --versions)   versions "${2:-HEAD}"; exit 0 ;;
  --pilots)     pilots "${2:-HEAD}"; exit 0 ;;
  # How long the current spine is, and whose name is on it. GR15's whole
  # arithmetic, and the referee's only question about it.
  --run)        run_of "${2:-HEAD}"; exit 0 ;;
  # The book builder run for its audit and nothing else: one line per commit it
  # would accuse in a chapter, in the same shape --skips prints. It does not
  # exit here because the audit lives inside the builder, which is most of this
  # file below - so this only sets the flag, and everything the build would
  # write is guarded on it. Nothing is painted, nothing is backfilled, and no
  # page is removed and rewritten.
  #
  # Nothing in here needs it either. tools/lockstep.sh does: the two audits are
  # two readings of one rule, one of which prices a skip at two on the ledger
  # (GR12) while the other accuses somebody in prose, and until this they were
  # kept together by a comment.
  --audit)      AUDIT=1 ;;
  # And the builder's other decision, got at the same way and for the same
  # reason: which commits it passes over in silence as the book's own filing.
  # The digest answers that question too, out of different variables, and
  # tools/lockstep.sh is what stops the two drifting.
  --book-silence) SILENCE=1 ;;
esac
if [ "$AUDIT" = 1 ] || [ "$SILENCE" = 1 ]; then QUIET=1; else QUIET=0; fi

# How many versions deep the history is. The builder below skips exactly the
# commits this leaves out: a counter that numbers what the builder declines to
# file leaves a chapter that renders as nothing at all.
#
# Below the questions above rather than beside them, because it walks the whole
# log and they do not. --moved is asked once per commit by the hooks, by the
# referee and by tools/lockstep.sh, and it has no use for a count.
TOTAL=$(versions | awk 'END { print NR + 0 }')

case "${1:-}" in
  --version)    printf 'v%s\n' "$TOTAL"; exit 0 ;;
  --next)
    if moved; then printf 'v%s\n' "$((TOTAL + 1))"; else printf -- '-\n'; fi
    exit 0 ;;
esac

# The taglines, folded into the same stream the log comes down, so awk can read
# them without having to open a second file in the middle of a record.
taglines() {
  [ -f docs/taglines.tsv ] || return 0
  awk -F'\t' 'NF >= 2 && $1 !~ /^#/ { printf "\036TAG\037%s\037%s", $1, $2 }' docs/taglines.tsv
}

# Who created each file, folded into the stream the same way. Ownership is
# tools/golden-check.sh's owner_of - whoever's commit first added the file -
# derived here for the whole tree in one pass: the log arrives newest first,
# so the last A record seen for a path is its oldest, and that one wins. GR11
# reads it for the event files and GR4 for everything else. --no-renames, which
# is owner_of's answer too: without --follow git stops looking at the commit
# that brought the path, so a file that has been moved belongs to whoever moved
# it, in both readers, from the commit after the move onwards. Inside the move
# itself the two used to part company, and renames() below is where they stop.
owners() {
  git log --format='%x1e%an' --diff-filter=A --name-only --no-renames 2>/dev/null \
    | awk -v RS='\036' '
        {
          n = split($0, L, "\n")
          for (i = 2; i <= n; i++) if (L[i] != "") own[L[i]] = L[1]
        }
        END { for (p in own) printf "\036OWN\037%s\037%s", p, own[p] }'
}

# Every move git would call a rename, folded in the same way once more: the
# commit, the path it left, the path it arrived at.
#
# The log below is read with --no-renames on purpose and stays that way - the
# picture draws an arrival differently from a departure, and the marks a chapter
# wears are of the paths as they are now. But that leaves a move reaching the
# audits as a delete of one file and an add of another, and a delete of somebody
# else's file is a GR4 breach with no override line, which is two on the tally
# (GR12). The referee does not read it that way: check_gr45 in
# tools/golden-check.sh asks where the file came from and weighs it as what it
# was. So a rename that changed not one byte cost its pilot two while the
# referee said clear.
#
# This is how the audits get the referee's own answer without forming a second
# opinion about what a rename is. Both ask git, both with rename detection on,
# and neither counts similar lines for itself.
renames() {
  git log --format='%x1e%H' --diff-filter=R --name-status --find-renames --no-merges 2>/dev/null \
    | awk -v RS='\036' '
        {
          n = split($0, L, "\n")
          for (i = 2; i <= n; i++) {
            if (L[i] !~ /^R/) continue
            split(L[i], f, "\t")
            printf "\036REN\037%s\037%s\037%s", L[1], f[2], f[3]
          }
        }'
}

# The painted plates, folded in the same way again: commit, file, and the line
# the plate is a picture of. A plate whose file has gone missing is not
# mentioned, because a chapter with a broken picture in it is worse than a
# chapter with none - and tools/chronicle-art.sh will paint it again anyway.
plates() {
  [ -f docs/art/index.tsv ] || return 0
  awk -F'\t' 'NF >= 3 && $1 !~ /^#/ {
    if ((getline junk < ("docs/art/" $2)) >= 0) {
      close("docs/art/" $2)
      printf "\036ART\037%s\037%s\037%s", $1, $2, $3
    }
  }' docs/art/index.tsv
}

# The pilots' faces, folded in the same way once more: a name, and the picture
# that belongs to it from now on. Same missing-file rule as the plates, for the
# same reason - except that this one will not be repainted, so a face whose file
# has gone is a name that simply reads as a name again.
faces() {
  [ -f docs/faces/index.tsv ] || return 0
  awk -F'\t' 'NF >= 2 && $1 !~ /^#/ {
    if ((getline junk < ("docs/faces/" $2)) >= 0) {
      close("docs/faces/" $2)
      printf "\036FACE\037%s\037%s", $1, $2
    }
  }' docs/faces/index.tsv
}

# The field guide, folded into the stream the same way once more: which file
# briefs the player about what. A feature that registers a guide tile is a
# thing a pilot meets in the game rather than a file in a tree, and crossing
# these against owners() above is how the book says what somebody built
# without counting lines at anybody.
#
# Read off the worktree rather than off the history, and deliberately: this is
# what is in the cabinet now, not what was ever in it. A tile somebody has
# since deleted is gone from the game, so it is gone from here.
guides() {
  find src -name '*.js' -type f 2>/dev/null | sort | while IFS= read -r p; do
    awk -v p="$p" '
      function str() { return match($0, /"[^"]*"/) ? substr($0, RSTART + 1, RLENGTH - 2) : "" }
      # The briefing the tile carries, taken as text rather than as markup: the
      # guide writes for a panel with a whole screen behind it, and everywhere
      # else it is quoted the words are all that survives. A name assembled at
      # runtime - the song of the night is the one - loses the assembled half
      # the same way its name does, and what is left still reads.
      function brief(   s) {
        s = $0
        sub(/^[[:space:]]*desc:[[:space:]]*/, "", s)
        sub(/,[[:space:]]*$/, "", s)
        sub(/^["`]/, "", s); sub(/["`]$/, "", s)
        gsub(/\$\{[^}]*\}/, "", s)
        gsub(/<[^>]*>/, "", s)
        gsub(/&mdash;/, "\342\200\224", s)
        gsub(/[[:space:]]+/, " ", s)
        sub(/^ /, "", s); sub(/ $/, "", s)
        return s
      }
      # The tile opens, and three fields are worth having: what it is called,
      # where the guide files it, and the sentence a player actually reads. The
      # icon between them is a picture and belongs in an index even less than
      # markup does. One tile per file, everywhere, so this reads to the end of
      # the block and prints once - and the block ends at the brace sitting at
      # the same indent the word "guide" started on.
      /^[[:space:]]*guide:[[:space:]]*\{/ {
        g = 1; ind = index($0, "guide") - 1; nm = ""; gp = ""; ds = ""; next
      }
      g && substr($0, 1, ind) ~ /^ *$/ && substr($0, ind + 1, 1) == "}" { g = 0; next }
      # A name that is built rather than written - the song of the night is the
      # one - keeps the half that is a literal and says there is more to it.
      g && nm == "" && /^[[:space:]]*name:[[:space:]]*"/ {
        nm = str()
        if ($0 !~ /^[[:space:]]*name:[[:space:]]*"[^"]*",?[[:space:]]*$/) {
          sub(/[[:space:]]*$/, "", nm)
          nm = nm "\342\200\246"
        }
        next
      }
      g && gp == "" && /^[[:space:]]*group:[[:space:]]*"/ { gp = str(); next }
      g && ds == "" && /^[[:space:]]*desc:[[:space:]]*["`]/ { ds = brief(); next }
      # Printed once the file has gone by rather than the moment the name is
      # known, because the sentence is the last field of the tile and the icon
      # is in the way. A tile with no group and no briefing is still a tile.
      END { if (nm != "") printf "\036GUIDE\037%s\037%s\037%s\037%s", p, nm, gp, ds }
    ' "$p"
  done
}

# The ambushes, one file per pilot, folded in the same way. GR11 makes this the
# one directory where the author is written into the file rather than worked
# out from the history, so the book reads what the event says about itself -
# and the house, which signs with nobody's name, arrives with that field empty
# and is nobody's on the page for the same reason it is nobody's in the game.
arms() {
  for p in src/events/*.js; do
    [ -f "$p" ] || continue
    awk -v p="$p" '
      function str() { return match($0, /"[^"]*"/) ? substr($0, RSTART + 1, RLENGTH - 2) : "" }
      # One call, and it may carry a list: A.defineEvent([{...}, {...}]) is how
      # a pilot with more than one ambush writes them, and the house has four.
      /defineEvent\(/ { e = 1; id = ""; by = ""; nm = ""; next }
      e && /^[[:space:]]*id:[[:space:]]*"/    { id = str(); next }
      e && /^[[:space:]]*by:[[:space:]]*"/    { by = str(); next }
      e && /^[[:space:]]*name:[[:space:]]*"/  { nm = str(); next }
      e && /^[[:space:]]*blurb:[[:space:]]*"/ {
        if (id != "") printf "\036ARM\037%s\037%s\037%s\037%s\037%s", p, id, by, nm, str()
        id = ""; by = ""; nm = ""
      }
    ' "$p"
  done
}

# The board, folded in the same way: every flight that has ever been ranked, as
# the ranked table says it. tools/flights.sh is the meter and answers a
# different question - how many landings a tape has left to cover - so it is
# asked for that below rather than re-derived here, and this reads the one
# thing it does not print: which evenings a pilot actually flew.
flights_ranked() {
  [ -f docs/RANKINGS.md ] || return 0
  awk -F'|' '
    # The ranked table only: a row whose first cell is nothing but a number.
    # The log under it is the same evenings again in prose, and prose wraps.
    NF >= 8 && $2 ~ /^[[:space:]]*[0-9]+[[:space:]]*$/ {
      for (i = 2; i <= 8; i++) gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
      printf "\036FLY\037%s\037%s\037%s\037%s\037%s\037%s\037%s", $3, $2, $4, $5, $6, $7, $8
    }
  ' docs/RANKINGS.md
}

# And the tapes themselves, which are the only record of what an event has ever
# actually done to anybody. One record per firing: whose ambush it was, which
# one, who was flying and what it cost them. A pilot with no filed tape is
# simply not in here - the archive starts where tools/blackbox.sh --save does,
# and the flights older than it are on the board without one.
firings() {
  for t in docs/tapes/*.json; do
    [ -f "$t" ] || continue
    tr ',' '\n' < "$t" | awk '
      /"pilot":/  { if (match($0, /"pilot":"[^"]*"/)) who = substr($0, RSTART + 9, RLENGTH - 10) }
      /"id":/     { if (match($0, /"id":"[^"]*"/))    id  = substr($0, RSTART + 6, RLENGTH - 7) }
      /"by":/     { if (match($0, /"by":"[^"]*"/))    by  = substr($0, RSTART + 6, RLENGTH - 7) }
      /"wave":/   { if (match($0, /"wave":[0-9]+/))   wv  = substr($0, RSTART + 7, RLENGTH - 7) }
      /"deaths":/ {
        if (match($0, /"deaths":[0-9]+/)) dt = substr($0, RSTART + 9, RLENGTH - 9)
        if (id != "" && by != "") printf "\036FIRE\037%s\037%s\037%s\037%s\037%s", by, id, who, wv, dt
        id = ""; by = ""
      }
    '
  done
}

# What is still in the cabinet, so that owners() above can be asked about the
# tree as it stands rather than as it ever was. A file somebody created and
# somebody else later deleted is not something they own today, and a page that
# said otherwise would be counting ghosts at people.
tree() { git ls-files 2>/dev/null | awk '{ printf "\036TREE\037%s", $0 }'; }

# The two standings the book does not get a vote on. The ledger is
# tools/tally.sh's answer, written into src/game/ledger.js and checked against
# the history at commit time; the flight meter is tools/flights.sh's. Both are
# read here rather than worked out, because a book that formed its own opinion
# about somebody's record would be a second opinion about it - and the whole
# arrangement in this project is that there is only ever one.
ledger_of() {
  [ -f src/game/ledger.js ] || return 0
  awk '
    match($0, /"[^"]*":[[:space:]]*\{/) {
      who = substr($0, RSTART + 1, RLENGTH - 1)
      sub(/":[[:space:]]*\{$/, "", who)
      b = c = 0; last = ""
      if (match($0, /bends:[[:space:]]*[0-9]+/)) b = substr($0, RSTART + 6, RLENGTH - 6) + 0
      if (match($0, /clean:[[:space:]]*[0-9]+/)) c = substr($0, RSTART + 6, RLENGTH - 6) + 0
      if (match($0, /last:[[:space:]]*"[^"]*"/)) {
        last = substr($0, RSTART + 5, RLENGTH - 5)
        gsub(/[":[:space:]]/, "", last)
      }
      printf "\036LED\037%s\037%d\037%d\037%s", who, b, c, last
    }
  ' src/game/ledger.js
}
meters() {
  pilots | while IFS= read -r who; do
    [ -n "$who" ] || continue
    printf '\036MET\037%s\037%s\037%s' "$who" \
      "$(sh tools/flights.sh --count "$who" 2>/dev/null || echo 0)" \
      "$(sh tools/flights.sh --last "$who" 2>/dev/null)"
  done
}

# One record per commit: header fields, then the raw diff, then the numstat.
# --raw is there for one letter: D. A deleted file and a file that only lost
# lines are the same two numbers, and GR6 counts one of them and not the other.
#
# %at rides along because a page says how long the cabinet waited for it, and
# the gap between two versions is arithmetic nothing else in here can do.
# %ae sits between %at and the body rather than beside the name it belongs to,
# so that the four fields ahead of it keep their numbers in the three readers
# below and only the body moves. It cannot go last, however tidy that looks:
# --raw and --numstat print after the format string, so the final field is the
# one that absorbs the diff, and the body has to be the field that does it.
#
# --no-renames, and renames() above is what makes that safe: a move arrives here
# as a departure and an arrival, which is what the picture wants and what the
# marks want, and the audits put the two halves back together from the pairs git
# handed them rather than from a guess.
history() {
  git log --format='%x1e%H%x1f%an%x1f%ad%x1f%s%x1f%at%x1f%ae%x1f%b' \
          --date=format:"$1" --raw --numstat --no-renames --no-merges ${2:+-n "$2"}
}

# Shared by the book and the digest: which parts of the cabinet a path is in,
# and therefore whether the commit that touched it was a version at all.
#
# is_referee is the same list tools/golden-check.sh keeps, because the audit
# below accuses people of breaking GR10 and an accusation has to use the
# referee's own definition or it is just an opinion.
# The other generator in the building. tools/docs.sh renders the notes - the
# README, the rules, this map, the board - into docs/*.html beside the chapters,
# and is_book below has to know them or every rule change wears a notes mark for
# pages nobody wrote by hand.
#
# Asked rather than copied. docs.sh --list prints the paths it owns and derives
# them from the README the way it renders them, so it cannot go stale; a list
# spelled out here would be this project keeping a second opinion about somebody
# else output, which is the arrangement it has argued against everywhere else.
# tools/golden-check.sh already asks the same question of the same tool.
#
# Interpolated into the library rather than handed in with -v, because six awks
# read that library and every one of them wants the answer. Where the tool is
# not there to ask - a scripted fixture, a clone mid-surgery - the pattern falls
# back to something no path matches, and is_book answers exactly as it did
# before any of this.
NOTESRE=$(sh tools/docs.sh --list 2>/dev/null | sed 's/[].[^$*\/]/\\&/g' | paste -sd'|' -)
# Escaped like the paths above, because this is spliced into an awk regex
# literal and a bare slash ends one. Unescaped, the library stopped parsing at
# all and every reader in it answered no to everything - which tools/lockstep.sh
# noticed on the first run, in the one place that has no tools/docs.sh to ask.
[ -n "$NOTESRE" ] || NOTESRE='docs\/no-such-note-was-ever-written'

LIB=$MACHINE'
function is_game(p) {
  # GAME and NOTGAME above, said again in the one language that cannot ask git.
  # The stream is already flowing by the time a path arrives here, so this is
  # the second reader of the question and the only one that had to be: the
  # counter declining to number a commit while the builder still filed it as one
  # is a chapter that renders as nothing at all, and that is how three ledger
  # receipts - the record of somebody bending a rule - went missing from the
  # book on the first attempt at this.
  #
  # Nothing is asked to remember that any more. tools/lockstep.sh puts the same
  # commits to this function and to the pathspec above, and fails when the two
  # answer differently; --is-game below is how it gets to ask.
  if (p == "src/game/ledger.js") return 0
  return (p == "index.html" || p ~ /^src\// || p ~ /^styles\//)
}
function is_book(p) {
  return (p == "docs/index.html" || p == "docs/chronicle.css" ||
          p == "docs/chronicle.js" || p == "docs/chronicle-song.js" ||
          p == "docs/rail.js" || p == "docs/taglines.tsv" ||
          p == "docs/favicon.svg" ||
          p ~ /^docs\/v[0-9]+\.html$/ ||
          p ~ /^docs\/pilot-[a-z0-9-]+\.html$/ ||
          p ~ /^docs\/art\// || p ~ /^docs\/faces\// ||
          p ~ /^('"$NOTESRE"')$/)
}
# The wider question is_filing below actually wants: not "is this a page of the
# book" but "is this something the cabinet wrote about itself". Those are not
# the same list, and the difference is the whole of why the book has been
# narrating its own paperwork.
#
# A filing is not the output of one tool. The post-commit hook rebuilds the book
# and then repaints the strip in tools/badges.sh, so the commit that files the
# pages carries a badge along with them. A badge is not a page, so is_book said
# no, so a filing read as a commit that had done something off-book - and got an
# interlude and a clause on the cover for it. It could not settle either: filing
# the paperwork dirtied the book again, one commit behind, for ever.
#
# The badges stay out of is_book because they are not the book and markof() has
# to go on saying so. This is the one place that needs them folded in, and it is
# the only place that folds them.
function is_filed(p) {
  return (is_book(p) || p ~ /^media\/badges\/.+\.svg$/)
}
# And one path that is evidence of nothing either way. The ledger is written off
# the history like the pages and the strip, so a filing that re-derived it is
# still a filing - but a commit that is nothing but the ledger is the tally
# ticking over, which is something that happened to somebody and has always been
# carried as the story it is. Counting it as filed would silence those two;
# counting it as off-book is what keeps ten filings narrated today. So it counts
# as neither, and is_filing needs no term for it: a commit with nothing in it
# but the ledger has no filed path, and fails on that.
function is_mute(p) { return (p == "src/game/ledger.js") }
function is_stat(l) { return (l ~ /^(-|[0-9]+)\t(-|[0-9]+)\t./) }
function is_raw(l)  { return (l ~ /^:[0-7]+ [0-7]+ [0-9a-f]+ [0-9a-f]+ [A-Z]/) }
# is_referee in tools/golden-check.sh is the list this one has to match, for
# the same reason is_commons below does. The audit re-referees the history off
# a commit alone, so a path the referee treats as its own machinery and this
# treats as game code reads as a GR10 breach that never happened - and charges
# somebody two for it.
function is_referee(p) {
  return (p == "CLAUDE.md" || p == "GOLDEN_RULES.md" || p == ".gitattributes" ||
          p == ".env.example" || p ~ /^tools\// || p ~ /^\.githooks\// ||
          p ~ /^\.github\// ||
          p == ".claude/settings.json" || p ~ /^\.claude\/skills\//)
}
# The shared ground GR5 protects, and is_commons in tools/golden-check.sh is
# the list this one has to match: an audit accusing somebody of gutting the
# commons had better mean the same commons the referee meant.
function is_commons(p) {
  return (p == "index.html" || p == "src/main.js" || p == "src/features.js" ||
          p ~ /^src\/core\// || p ~ /^src\/render\// || p ~ /^src\/input\// ||
          p ~ /^src\/ui\// ||
          p == "src/game/players.js" || p == "src/game/difficulty.js" ||
          p == "src/game/lifecycle.js" || p == "src/game/events.js" ||
          p == "src/game/profile.js" || p == "src/game/tally.js" ||
          p == "src/audio/context.js" || p == "src/audio/buses.js" ||
          p == "styles/tokens.css" || p == "README.md")
}
# What GR4 and GR5 measure a path at all for: the referee leaves its own files
# to GR10, docs/ and the ledger to the machines that write them, and
# src/events/ to GR11, which has no budget to spend.
function is_gutted_ground(p) {
  return (!is_referee(p) && p !~ /^docs\// && p != "src/game/ledger.js" &&
          p !~ /^src\/events\//)
}
# The book filing its own pages is not a story. A commit that touched nothing
# but the generated pages is passed over in silence, on the cover and in the
# digest alike - unless it carries an override, a rule change, a ledger receipt
# or a breach, which keeps its line whatever files it rode in on.
#
# One rule, one function, two callers: the digest below and the interlude branch
# in the builder. They used to be two spellings of it in different variables -
# bookish and offbook at one end, five moved flags at the other - held together
# by a comment at each end asking the other to keep up. --digest-silence and
# --book-silence are the handles now, and tools/lockstep.sh puts the same commits
# to both.
#
# The arguments are what each caller can see for itself; the answer is not. That
# matters at the builder end, which folds one extra term into "event" that the
# digest has no way to answer: its own audit verdict. Unreachable rather than
# harmless - the audit measures nothing under docs/, so a commit whose every
# path is a book file can never carry a verdict - and it stays in as the belt to
# the braces, where the fixture can watch it.
function is_filing(game, bookish, offbook, event) {
  return (!game && bookish && !offbook && !event)
}
# The two halves of a move, put back together. renames() above folds the pairs
# git handed it into the stream and the audits below fill these two arrays from
# them; where a commit moved nothing, both answers are the path itself and
# nothing downstream can tell the difference.
#
#   came   what this path was called before this commit - the path GR4 asks who
#          owns and GR5 asks whether it is commons, exactly as came_from does
#          for tools/golden-check.sh
#   went   where this path ended up in this commit - the bucket its lines are
#          counted into, so a move nets out at the arithmetic the referee reads
#          instead of a whole file deleted and a whole file added
function came(sha, p,   k) { k = sha SUBSEP p; return (k in cameto) ? cameto[k] : p }
function went(sha, p,   k) { k = sha SUBSEP p; return (k in moveto) ? moveto[k] : p }

# --- the marks --------------------------------------------------------------
# What a commit moved, as a reader would name it. sector() in the builder asks
# a different question - where a path sits - and gets a different answer for
# the same file: src/ui/debrief.js sits among the panels and belongs to the
# game within the game. This one is the one a badge is printed from, so it
# answers in the vocabulary the book already uses out loud.
#
# It is down here in the library rather than up in the builder because a second
# reader turned up. --marks below hands it to tools/labels.sh, which prints the
# labels on a pull request; the badge on the chapter and the label on the strip
# are now the same word by construction, which is the only arrangement in which
# two vocabularies stay one. Where they disagreed, they disagreed for a whole
# year and nobody could have noticed from either end.
function markof(p) {
  # The book files its own pages onto every commit there is, so a mark for
  # that would be a mark on everything and would say nothing. Only the hand
  # that writes the generator counts as work on the chronicle.
  if (is_book(p)) return ""
  if (p ~ /^src\/events\// ||
      p == "src/game/events.js"   || p == "src/game/profile.js" ||
      p == "src/game/ledger.js"   || p == "src/game/tally.js" ||
      p == "src/game/blackbox.js" || p == "src/ui/debrief.js")   return "meta"
  if (p ~ /^src\/audio\//)  return "music"
  if (p ~ /^src\/input\//)  return "hands"
  if (p ~ /^src\/core\//)   return "engine"
  if (p ~ /^src\/ui\// || p ~ /^src\/render\// || p ~ /^styles\// ||
      p == "index.html")    return "ui"
  if (p ~ /^src\//)         return "game"
  if (p ~ /^tools\/chronicle/) return "book"
  if (is_referee(p))        return "rules"
  return "notes"
}
# One line per module in src/features.js is what puts a module on the board, so
# the manifest is a game path by any reading and markof above says so. Said out
# loud on a branch, that is the wrong answer nine times in ten. Adding a feature
# here is one new file plus one manifest line (GR3), so a pure src/ui/ panel
# comes out marked "game ui" and an src/audio/ track "game music" - and
# tools/branch.sh takes the loudest, which is always game. The eight other marks
# could only ever win on a branch that registered nothing at all, which is the
# opposite of the commonest change there is.
#
# So the manifest inherits rather than asserts. It carries game only when no
# other game path in the same change carries something better: a manifest line
# beside an src/audio/ file is a music change, a manifest line on its own is
# still a game change, and a manifest line beside src/entities/ is a game change
# either way, because that is what the rock said too.
#
# Deferred rather than decided per path, because markof is handed one path at a
# time and cannot see the company it is in. Both collectors fold through here,
# so the badge on the chapter and the label on the pull request go on being the
# same word by construction.
function is_manifest(p) { return (p == "src/features.js") }
function mark_into(p, seen, held,   mk) {
  if (is_manifest(p)) { held["manifest"] = 1; return }
  if (is_game(p)) held["specific"] = 1
  mk = markof(p)
  if (mk != "") seen[mk] = 1
}
function mark_settle(seen, held) {
  if (held["manifest"] && !held["specific"]) seen[markof("src/features.js")] = 1
}
# What a badge says. Bare, because badges arrive in rows of three and four and
# nine articles in a row is nine words of nothing - the picture and one noun is
# the whole of what a badge is for. A pull request wants the same bare word for
# the same reason: a label reading "the game within" is a sentence fragment
# sitting in a list of nouns.
function markname(k) {
  if (k == "game")   return "game"
  if (k == "meta")   return "game within"
  if (k == "ui")     return "ui"
  if (k == "music")  return "music"
  if (k == "hands")  return "controls"
  if (k == "engine") return "engine"
  if (k == "book")   return "chronicle"
  if (k == "rules")  return "rules"
  return "notes"
}
# The order they are printed in, everywhere, so two chapters wearing the same
# three marks wear them in the same three places - and so a pull request lists
# them the way the chapter it becomes will.
function markorder() { return "game meta ui music hands engine book rules notes" }
'

case "${1:-}" in
  # Which of these paths the awk above calls the game, printed back. Nothing in
  # here needs it and nothing in here uses it; tools/lockstep.sh does, because a
  # reader that cannot be asked a question cannot be caught disagreeing with the
  # pathspec that asks the same one.
  --is-game)
    shift
    if [ $# -gt 0 ]; then printf '%s\n' "$@"; else cat; fi \
      | awk "$LIB"'$0 != "" && is_game($0) { print }'
    exit 0 ;;

  # What the book would put on a chapter built out of these paths, as the badge
  # says it: one word a line, each mark once, in the order the book prints them
  # in. tools/labels.sh is the caller - a pull request wants the same answer in
  # a form github can colour, and this is it being asked for rather than
  # answered a second time somewhere else.
  #
  # A path the book gives no mark to prints nothing, and that includes every
  # page the book writes about itself. A pull request that only moved those is
  # correctly bare: the paperwork is not a thing that happened.
  --marks)
    shift
    # Every mark there is, in the order the book prints them, for the two
    # callers that need the vocabulary rather than an answer about paths:
    # tools/branch.sh validating a directory somebody typed, and anything that
    # wants to list them. Same one home - a second copy of these nine words is
    # a second opinion waiting to happen.
    if [ "${1:-}" = "--all" ]; then
      awk "$LIB"'BEGIN { n = split(markorder(), a, " ")
                         for (i = 1; i <= n; i++) print markname(a[i]); exit }'
      exit 0
    fi
    if [ $# -gt 0 ]; then printf '%s\n' "$@"; else cat; fi \
      | awk "$LIB"'
          $0 != "" { mark_into($0, seen, held) }
          END { mark_settle(seen, held)
                n = split(markorder(), a, " ")
                for (i = 1; i <= n; i++) if (a[i] in seen) print markname(a[i]) }'
    exit 0 ;;

  # The digest, and the digest's own silence printed back. Two modes of one
  # walk on purpose: a handle that ran a second copy of the test would be a
  # handle on nothing. --recent prints rows for a reader; --digest-silence
  # prints the commits that never became a row because they were the book
  # filing itself, as sha and pilot, the shape --skips and --audit print.
  --recent|--digest-silence)
    if [ "${1:-}" = "--digest-silence" ]; then
      n=0; sil=1                      # no window: the whole log, and no rows
    else
      n=${2:-5}; sil=0
      # A number, because the awk below counts rows against it now rather than
      # git counting records against it.
      case $n in ''|*[!0-9]*|0) n=5 ;; esac
    fi
    # Ask for eight and get five. The digest drops the commits that are not
    # stories - a machine filing the book, the paperwork behind a landing - and
    # it used to drop them out of a window of exactly N records, so a busy
    # filing day ate the answer. What a reader asking for eight wants is eight
    # things that happened, however far back that is.
    #
    # So the walk is the whole log and the awk stops when it has enough: git is
    # writing into a pipe, and the reader closing it is what ends the walk. The
    # test for what prints is untouched below, deliberately - this changes how
    # far the digest looks, not what it thinks a story is.
    { taglines; history '%d %b %Y'; } \
      | awk -v RS='\036' -v FS='\037' -v ver="$TOTAL" -v want="$n" -v sil="$sil" "$LIB"'
          $1 == "TAG" { tag[$2] = $3; next }
          NF < 4 { next }
          # Nobody flew it, so there is nothing to tell the next pilot about it.
          # The builder drops the machines in the same place, before either of
          # them asks about the book filing itself.
          is_machine($2, $6) { next }
          {
            game = 0; line = ""; mode = 0; bookish = 0; offbook = 0; event = 0
            n = split($7, b, "\n")
            for (k = 1; k <= n; k++) {
              if (is_stat(b[k])) {
                split(b[k], ns, "\t")
                if (is_game(ns[3])) game = 1
                if (is_filed(ns[3])) bookish = 1
                else if (!is_mute(ns[3])) offbook = 1
                mode = 0; continue
              }
              if (tolower(b[k]) ~ /^[[:space:]]*(golden-rule-override|rule-change|tally|golden-rule-breach):/)
                event = 1
              if (tolower(b[k]) ~ /^[[:space:]]*chronicle:/) {
                sub(/^[^:]*:[[:space:]]*/, "", b[k]); line = b[k]; mode = 1
              } else if (mode && b[k] ~ /^[[:space:]]+[^[:space:]]/) {
                sub(/^[[:space:]]+/, "", b[k]); line = line " " b[k]
              } else mode = 0
            }
            # The book filing its own pages is not a story, in the digest any
            # more than on the cover. is_filing above is the rule, said once;
            # the builder asks it the same question out of its own variables,
            # and tools/lockstep.sh puts the same commits to both.
            if (is_filing(game, bookish, offbook, event)) {
              if (sil) printf "%s\t%s\n", $1, $2
              next
            }
            if (sil) next
            # The pilot wrote it, or the tagline says it, or the subject has to do.
            if (line == "" && game && $1 in tag) line = tag[$1]
            if (line == "") line = $4
            printf "  %-5s %-16s %s\n", (game ? "v" ver : "--"), $2, line
            if (game) ver--
            if (++shown == want) exit
          }'
    exit 0 ;;
esac

# The rules bind from the commit that wrote them down, and not one commit
# earlier. Everything older than GOLDEN_RULES.md was flown before there was
# anything to break, and the audit below leaves it alone - including the commit
# that brought the rules, which no referee could have been running for either.
# Empty means the rules are not in the history yet and nobody is being judged.
RULES=$(git log --diff-filter=A --format='%H' --no-renames -- GOLDEN_RULES.md 2>/dev/null | tail -1)

# The audit above, reduced to a verdict: one line per commit the referee
# provably never saw - full sha, a tab, the pilot who flew it. Read by
# tools/tally.sh, which prices a skip at two (GR12) without depending on the
# skipper's own hooks having written a receipt.
#
# The same arithmetic runs a second time in the book builder below, where it is
# written out as prose in a chapter, and the two used to be held together by a
# comment apiece asking the other to keep up. They are held together now:
# --audit is the handle on the builder's copy, and tools/lockstep.sh puts the
# same commits to both, on a scripted cabinet and on this history, every commit.
# Same forgiving form, same exemptions, and anywhere the two could disagree,
# both stay quiet - which is a claim the fixture makes rather than a hope.
if [ "${1:-}" = "--skips" ]; then
  { owners; renames; history '%d %b %Y'; } \
  | awk -v RS='\036' -v FS='\037' -v rules="$RULES" "$LIB"'
      BEGIN { bound = (rules != "") }
      $1 == "OWN" { owner[$2] = $3; next }
      $1 == "REN" { moveto[$2 SUBSEP $3] = $4; cameto[$2 SUBSEP $4] = $3; next }
      NF < 7 { next }
      # A machine has no seat, no hooks and nothing to confess. The runner that
      # files the book never installed the referee and was never meant to: the
      # push it files was already read a commit at a time on the way in. Charging
      # it two for that would put a name in the ledger that cannot answer, and
      # the ledger is what the field reads to decide how hard to be on somebody.
      is_machine($2, $6) { next }
      {
        if (bound && $1 == rules) bound = 0
        sha = $1; who = $2; rest = $7
        overrides = ""; rulechange = 0; refstrict = 0; nonref = 0; stolen = 0
        acmr = 0; ins = 0; fpn = 0; mode = ""
        split("", deleted); split("", fseen); split("", fadd); split("", fdel)
        n = split(rest, b, "\n")
        for (k = 1; k <= n; k++) {
          t = b[k]; lt = tolower(t)
          if (is_raw(t)) {
            split(t, rw, "\t"); rn = split(rw[1], rf, " ")
            if (rf[rn] ~ /^D/) deleted[rw[2]] = 1
            mode = ""; continue
          }
          if (is_stat(t)) {
            split(t, ns, "\t"); p = ns[3]
            if (is_referee(p)) refstrict = 1
            else if (p !~ /^docs\// && p != "src/game/ledger.js") nonref = 1
            if (p ~ /^src\/events\/.+\.js$/ && (p in owner) && owner[p] != who) stolen = 1
            if (p !~ /^docs\//) {
              if (!(p in deleted)) acmr++
              if (ns[1] != "-") ins += ns[1]
            }
            if (is_gutted_ground(p)) {
              # Both halves of a move count into the path it moved to, which is
              # the file the referee weighed: a departure is the whole file out
              # and an arrival is the whole file in, so the two together net to
              # what the diff actually did to it.
              bk = went(sha, p)
              if (!(bk in fseen)) { fseen[bk] = 1; fp[++fpn] = bk }
              fadd[bk] += (ns[1] == "-" ? 0 : ns[1])
              fdel[bk] += (ns[2] == "-" ? 0 : ns[2])
            }
            mode = ""; continue
          }
          if (lt ~ /^[[:space:]]*golden-rule-override:/) { sub(/^[^:]*:[[:space:]]*/, "", t); overrides = overrides " " t; mode = "o"; continue }
          if (lt ~ /^[[:space:]]*rule-change:/) { rulechange = 1; mode = ""; continue }
          if (mode == "o" && t ~ /^[[:space:]]+[^[:space:]]/) { overrides = overrides " " t; continue }
          mode = ""
        }
        if (!bound) next
        unrec = 0
        if ((ins > 1200 || acmr > 25) && !(refstrict && !nonref) && toupper(overrides) !~ /GR6/) unrec = 1
        if (refstrict && nonref) unrec = 1
        if (refstrict && !rulechange) unrec = 1
        if (stolen) unrec = 1
        # GR4 and GR5, off the same numbers the referee reads: net lines out of
        # a file against its first author, the commons against everybody. Same
        # budgets, overrides honoured, and a file with no known owner is new,
        # which means it is theirs. A file that moved is asked about under the
        # name it had, because that is the name it was owned under: moving a
        # file does not move who it belongs to, here or in front of the referee.
        for (j = 1; j <= fpn; j++) {
          p = fp[j]; src = came(sha, p)
          if (p in deleted) {
            if (is_commons(src)) { if (toupper(overrides) !~ /GR5/) unrec = 1 }
            else if ((src in owner) && owner[src] != who && toupper(overrides) !~ /GR4/) unrec = 1
          } else if (is_commons(src)) {
            if (fdel[p] - fadd[p] > 60 && toupper(overrides) !~ /GR5/) unrec = 1
          } else if ((src in owner) && owner[src] != who && fdel[p] - fadd[p] > 25 && \
                     toupper(overrides) !~ /GR4/) unrec = 1
        }
        if (unrec) printf "%s\t%s\n", sha, who
      }'
  exit 0
fi

# From here down the book is being written, and --audit is not writing one. It
# wants the audit inside the builder and none of what the builder is for, so
# every step that leaves something behind is guarded - most of all the sweep
# below, which would take the chapters away and then be asked to exit without
# putting them back.

# Every version that does not have a line yet gets one now. This is what makes
# the whole arrangement work for a pilot who never ran --install: the hooks are
# a convenience, and a rebuild is the repair.
[ "$QUIET" = 1 ] || sh tools/tagline.sh --backfill >/dev/null 2>&1 || true

# And every version that has no plate yet gets asked for one - after the
# taglines, because the tagline is what the plate is a picture of. It is capped,
# it keeps what it painted, and it exits without a word on a machine that has no
# credentials for it, which is most of them. Nothing below waits on the result.
#
# From main and nowhere else, and that is not a preference. A plate is asked for
# by tagline and comes back a little different every time it is asked, so two
# machines painting the same commit get two pictures - and docs/art/*.jpg is
# binary, so git cannot union them the way it unions every other generated file
# here. That is the one merge conflict this project is able to manufacture for
# itself, in a file neither pilot wrote, and it happens exactly when somebody
# branches while the plates for the last version are still being filed.
#
# So a branch does not paint. Main does, on the next rebuild, which is how they
# have always arrived anyway - "The plates for v34 and v35, filed" is what that
# commit looks like. A detached HEAD is nobody's branch and paints nothing.
PAINTS=0
case "$(git symbolic-ref --quiet --short HEAD 2>/dev/null)" in
  main|master) PAINTS=1 ;;
esac
[ "$QUIET" = 1 ] || [ -n "${ASTEROIDS_NO_ART:-}" ] || [ "$PAINTS" = 0 ] || \
  sh tools/chronicle-art.sh --auto 2>/dev/null || true

[ "$QUIET" = 1 ] || mkdir -p docs

# Every page is written fresh on every rebuild, so a chapter somebody deleted
# comes back and a chapter for a version that no longer exists does not.
[ "$QUIET" = 1 ] || rm -f docs/v[0-9]*.html docs/pilot-*.html

# The tab wears the signet, and the drawing is not copied here: the rock, its
# box, the three lobes and the flat hues are read off src/ui/logo.js - the one
# file the mark belongs to - and printed as the same standalone SVG pin()
# builds for the game's own tab. If the logo ever stops yielding all of it,
# the book builds with no tab icon rather than a wrong one, and head() leaves
# the link out.
FAV=""
if [ "$QUIET" = 0 ] && [ -f src/ui/logo.js ]; then
  awk '
    # the rock spans concatenated string literals; collect until the path closes
    /const ROCK/ { grab = 1 }
    grab {
      line = $0
      while (match(line, /"[^"]*"/)) {
        rock = rock substr(line, RSTART + 1, RLENGTH - 2)
        line = substr(line, RSTART + RLENGTH)
      }
      if (rock ~ /z$/) grab = 0
    }
    /const BOX/ { if (match($0, /"[^"]*"/)) box = substr($0, RSTART + 1, RLENGTH - 2) }
    /const LOBES/ {
      line = $0
      while (match(line, /-?[0-9][0-9.]*/)) {
        num[++nn] = substr(line, RSTART, RLENGTH)
        line = substr(line, RSTART + RLENGTH)
      }
    }
    /const FLAT/ {
      line = $0
      while (match(line, /#[0-9a-fA-F]+/)) {
        flat[++nf] = substr(line, RSTART, RLENGTH)
        line = substr(line, RSTART + RLENGTH)
      }
    }
    # the void behind it, from the one rect pin() paints
    /<rect/ { if (match($0, /fill="#[0-9a-fA-F]+"/)) void = substr($0, RSTART + 6, RLENGTH - 7) }
    function pass(w, o,   i, out) {
      for (i = 1; i <= 3; i++) {
        out = out "<path d=\"" rock "\" stroke=\"" flat[i] "\" stroke-width=\"" w "\""
        if (o < 1) out = out " opacity=\"" o "\""
        out = out " transform=\"translate(" num[2 * i - 1] " " num[2 * i] ")\"/>"
      }
      return out
    }
    END {
      if (rock !~ /^M/ || split(box, b, " ") != 4 || nn != 6 || nf != 4 || void == "") exit
      out = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"" box "\" fill=\"none\" stroke-linejoin=\"round\">"
      out = out "<rect x=\"" b[1] "\" y=\"" b[2] "\" width=\"" b[3] "\" height=\"" b[4] "\" fill=\"" void "\"/>"
      out = out pass(6, 0.35) pass(2.4, 1)
      out = out "<path d=\"" rock "\" stroke=\"" flat[4] "\" stroke-width=\"1.9\"/></svg>"
      print out
    }
  ' src/ui/logo.js > docs/favicon.svg
  if [ -s docs/favicon.svg ]; then FAV=1; else rm -f docs/favicon.svg; fi
fi

{ taglines; owners; renames; plates; faces; guides; arms; flights_ranked; firings
  tree; ledger_of; meters; history '%d %B %Y|%H:%M'; } \
  | awk -v RS='\036' -v FS='\037' -v total="$TOTAL" -v rules="$RULES" -v fav="$FAV" \
        -v auditonly="$AUDIT" -v silenceonly="$SILENCE" "$LIB"'
function esc(s) { gsub(/&/,"\\&amp;",s); gsub(/</,"\\&lt;",s); gsub(/>/,"\\&gt;",s); return s }
function att(s) { s = esc(s); gsub(/"/, "\\&quot;", s); return s }
# JS string literals, a character at a time - the same function the digest at
# the foot of this file uses, for the same reason: gsub would do it in two
# lines and get the backslashes wrong on some awk somewhere; this cannot.
function js(s,   i, c, o) {
  o = ""
  for (i = 1; i <= length(s); i++) {
    c = substr(s, i, 1)
    if (c == "\\")      o = o "\\\\"
    else if (c == "\"") o = o "\\\""
    else if (c == "\r" || c == "\n") o = o " "
    else o = o c
  }
  return o
}
function plural(n) { return n == 1 ? "" : "s" }
# A pilot, wherever their name is written. Painted once by tools/chronicle-art.sh
# and kept from then on, so it is the same face on the cover, in the contents and
# at the top of every chapter they flew - which is the whole point of it being
# painted once. Empty for a pilot who has none, and every place this is used
# reads the same with nothing in it.
#
# alt is deliberately empty: the name is always right beside the picture, and a
# screen reader announcing it twice is worse than not announcing it at all.
# One pilot, one page, and this is the name of it. The faces have been slugged
# this way since the first one was painted, so the pilot whose portrait is
# docs/faces/david-friedrich.jpg has a page at docs/pilot-david-friedrich.html
# and the two cannot drift apart without somebody moving them both.
# One line of the ledger, filed against the chapter it can be read at.
function receipt(who, at, game, subj, why) {
  rcn[who]++
  RCV[who SUBSEP rcn[who]] = at
  RCK[who SUBSEP rcn[who]] = (game > 0 ? "V" : "I")
  RCS[who SUBSEP rcn[who]] = subj
  RCW[who SUBSEP rcn[who]] = why
}
function slug(s) {
  s = tolower(s)
  gsub(/[^a-z0-9]+/, "-", s)
  gsub(/^-+|-+$/, "", s)
  return s
}
# Every place the book prints a name it can now be pressed: the roster on the
# cover, the spine of a book, the corner of the splash a chapter opens with.
# One function for all three, so a name that is not a link anywhere is a name
# this was never asked about.
function plink(p, cls) {
  return "<a class=\"pl" (cls != "" ? " " cls : "") "\" href=\"pilot-" slug(p) ".html\">" \
         face(p) esc(p) "</a>"
}
function face(p,   f) {
  f = mug[p]
  if (f == "") return ""
  return "<img class=\"face\" src=\"faces/" f "\" alt=\"\" loading=\"lazy\" decoding=\"async\">"
}
function ord(n,   t) {
  t = n % 100
  if (t >= 11 && t <= 13) return n "th"
  t = n % 10
  return n (t == 1 ? "st" : (t == 2 ? "nd" : (t == 3 ? "rd" : "th")))
}
function roman(n,   v,s,i,out) {
  split("1000,900,500,400,100,90,50,40,10,9,5,4,1", v, ",")
  split("M,CM,D,CD,C,XC,L,XL,X,IX,V,IV,I", s, ",")
  out = ""
  for (i = 1; i <= 13; i++) while (n >= v[i] + 0) { out = out s[i]; n -= v[i] }
  return out
}
# --- the picture ------------------------------------------------------------
# A version draws its own diff. The seed is the commit hash and every number
# after that is arithmetic, so the same version draws the identical field on
# every machine and in every clone - which is the only honest way to commit a
# generated image. Park-Miller rather than rand(), because rand() is seeded
# differently by every awk there is and the book would churn on every rebuild.
function seed(h,   i, c, x) {
  S = 0
  for (i = 1; i <= 12; i++) {
    c = substr(h, i, 1)
    x = index("0123456789abcdef", c) - 1
    if (x < 0) x = 0
    S = (S * 16 + x) % 2147483647
  }
  if (S <= 0) S += 2147483646
}
function rnd() { S = (S * 16807) % 2147483647; return S / 2147483647 }
function rr(a, b) { return a + (b - a) * rnd() }
function f1(x)    { return sprintf("%.1f", x) }

# Which part of the cabinet a path belongs to, and what colour that part is.
# The tokens are the ones styles/tokens.css hands the game, so the day somebody
# changes the spectrum the whole book turns with it.
function sector(p,   q) {
  if (p == "index.html") return "cabinet"
  if (p ~ /^styles\//)   return "styles"
  if (p ~ /^src\//)      return (split(p, q, "/") >= 3 ? q[2] : "src")
  return "outside"
}
function tint(s) {
  if (s == "entities" || s == "events") return "var(--magenta)"
  if (s == "game")                      return "var(--violet)"
  if (s == "render" || s == "input")    return "var(--cyan)"
  if (s == "audio")                     return "var(--amber)"
  if (s == "ui" || s == "styles")       return "var(--lime)"
  # The rules, the hooks, the notes on the cabinet: real work, but not the
  # game, and a rock that is not the game should not be lit like one.
  if (s == "outside")                   return "var(--dim)"
  return "var(--ink)"
}

# The twelve busiest paths of a commit, biggest first, kept as they arrive.
# Twelve because thirteen rocks is a mess to look at, not because git ran out.
#
# cut is the lines a path lost net, and it is the one of the four that is not a
# yes or a no: it is how much lighter the file came back, so a nick and a
# gutting draw different sizes of the same mark rather than needing a number
# somebody had to choose.
function keep(p, n, gone, born, cut,   i, j, last) {
  for (i = 1; i <= kc; i++) if (n > kn[i]) break
  if (i > 12) return
  last = (kc < 12 ? kc : 11)
  for (j = last; j >= i; j--) {
    kp[j+1] = kp[j]; kn[j+1] = kn[j]; kd[j+1] = kd[j]; kb[j+1] = kb[j]; kg[j+1] = kg[j]
  }
  kp[i] = p; kn[i] = n; kd[i] = gone; kb[i] = born; kg[i] = cut
  if (kc < 12) kc++
}

# The tagline is what a page shouts. A version with no tagline at all is a
# clone that has never run the backfill, and the chapter still has to say
# something, so it borrows from further down the page.
function shout(v) { return VT[v] != "" ? VT[v] : (VL[v] != "" ? VL[v] : VS[v]) }

function caption(v,   s, k, born, gone, bit) {
  if (RC[v] == 0) return "An empty field. Nothing in this one moved."
  born = 0; gone = 0; bit = 0
  for (k = 1; k <= RC[v]; k++) {
    if (RD[v,k]) gone++
    else if (RA[v,k]) born++
    else if (RG[v,k] > 0) bit++
  }
  s = RC[v] " sector" plural(RC[v]) " on the scan, " (RC[v] == 1 ? "drawn" : "each drawn") " as the thing it is"
  if (born) s = s "; " born " of them arrived in this commit"
  if (gone) s = s "; " gone " shot out of the field for good"
  if (bit)  s = s "; " bit " came back lighter than " (bit == 1 ? "it" : "they") " went"
  if (born == 0 && gone == 0 && bit == 0 && VI[v] + VJ[v] < 40)
    s = s "; nothing moved but numbers, and the sights are on " RP[v,1]
  else
    s = s "; the heavy one is " RP[v,1]
  if (VF[v] > RC[v]) s = s ", with " (VF[v] - RC[v]) " smaller left off the scan"
  return s "."
}

# What a path is, not just where it sits. The picture draws an event as a mine
# and the song as a note, so a chapter says what happened before the caption
# gets a word in. Entities the cabinet actually has get their own silhouette;
# anything unrecognised in the field stays a rock, which is what an asteroids
# game would assume anyway.
function kindof(p,   b) {
  if (p ~ /^src\/events\//)   return "mine"
  if (p ~ /^src\/entities\//) {
    b = tolower(p)
    if (b ~ /kraken/)            return "kraken"
    if (b ~ /nuke|bomb/)         return "bomb"
    if (b ~ /portal/)            return "portal"
    if (b ~ /planet/)            return "planet"
    if (b ~ /falcon/)            return "falcon"
    if (b ~ /hook/)              return "hook"
    if (b ~ /bullet|blast|shot/) return "bolts"
    if (b ~ /ship/)              return "fighter"
    return "rock"
  }
  if (p ~ /^src\/game\//)   return "gear"
  if (p ~ /^src\/core\//)   return "atom"
  if (p ~ /^src\/render\//) return "prism"
  if (p ~ /^src\/audio\//)  return "note"
  if (p ~ /^src\/input\//)  return "keycap"
  if (p ~ /^src\/ui\//)     return "panel"
  if (p == "index.html" || p ~ /^styles\//) return "screen"
  return "wrench"
}

# The silhouettes, drawn on the same 24-grid as ico() and stroked the same
# way, so the field and the margin read as one hand. "solid" is the body that
# blots out the stars behind it; "pip" is the little light a thing keeps on;
# "whirl" turns, slowly, because a gear that does not is a decal.
function glyphart(n) {
  if (n == "mine")
    return "<circle class=\"solid\" r=\"6.5\"/>" \
           "<path d=\"M0 -11V-6.5M7.8 -7.8 4.6 -4.6M11 0H6.5M7.8 7.8 4.6 4.6M0 11V6.5M-7.8 7.8 -4.6 4.6M-11 0H-6.5M-7.8 -7.8 -4.6 -4.6\"/>" \
           "<circle class=\"pip\" r=\"1.7\"/>"
  if (n == "gear")
    return "<g class=\"whirl\"><circle class=\"solid\" r=\"7\"/><circle r=\"2.6\"/>" \
           "<path d=\"M7 0H10.5M4.9 4.9 7.4 7.4M0 7V10.5M-4.9 4.9 -7.4 7.4M-7 0H-10.5M-4.9 -4.9 -7.4 -7.4M0 -7V-10.5M4.9 -4.9 7.4 -7.4\"/></g>"
  if (n == "atom")
    return "<circle class=\"pip\" r=\"2\"/><g class=\"whirl\"><ellipse rx=\"11\" ry=\"4.2\"/>" \
           "<ellipse rx=\"11\" ry=\"4.2\" transform=\"rotate(60)\"/><ellipse rx=\"11\" ry=\"4.2\" transform=\"rotate(120)\"/></g>"
  if (n == "prism")
    return "<path class=\"solid\" d=\"M0 -8.5 8 7H-8z\"/><path d=\"M-13 1H-4.7\"/><path d=\"M4.7 1 13 -3.5M4.7 1H13M4.7 1 13 5.5\"/>"
  if (n == "note")
    return "<path d=\"M-4.5 6.5V-6.5L7.5 -8.5V4.5\"/><path d=\"M-4.5 -3.5 7.5 -5.5\"/>" \
           "<circle class=\"solid\" cx=\"-7\" cy=\"6.5\" r=\"2.6\"/><circle class=\"solid\" cx=\"5\" cy=\"4.5\" r=\"2.6\"/>"
  if (n == "keycap")
    return "<rect class=\"solid\" x=\"-9\" y=\"-8\" width=\"18\" height=\"16\" rx=\"2.5\"/><path d=\"M0 4V-3.5M-3.5 0 0 -3.5 3.5 0\"/>"
  if (n == "panel")
    return "<rect class=\"solid\" x=\"-11\" y=\"-8.5\" width=\"22\" height=\"17\" rx=\"1.5\"/>" \
           "<path d=\"M-11 -4.5H11\"/><path d=\"M-8 0H7M-8 4H2\"/><circle class=\"pip\" cx=\"8.7\" cy=\"-6.5\" r=\"0.9\"/>"
  if (n == "screen")
    return "<rect class=\"solid\" x=\"-11\" y=\"-9\" width=\"22\" height=\"18\" rx=\"2.5\"/>" \
           "<rect x=\"-7.5\" y=\"-5.5\" width=\"15\" height=\"11\"/><path class=\"scan\" d=\"M-7.5 -2H7.5M-7.5 1H7.5M-7.5 4H7.5\"/>"
  if (n == "kraken")
    return "<path class=\"solid\" d=\"M-7 0A7 7 0 0 1 7 0z\"/>" \
           "<path d=\"M-7 0C-8.5 3.5 -6 5.5 -7.5 9M-2.3 0C-3.3 4 -1 6 -2 10M2.3 0C1.3 4 3.6 6 2.6 10M7 0C8.5 3.5 6 5.5 7.5 9\"/>" \
           "<circle class=\"pip\" cx=\"-2.6\" cy=\"-2.8\" r=\"0.9\"/><circle class=\"pip\" cx=\"2.6\" cy=\"-2.8\" r=\"0.9\"/>"
  if (n == "bomb")
    return "<circle class=\"solid\" cy=\"2.5\" r=\"7\"/><path d=\"M-2.5 -4.5H2.5\"/><path d=\"M0 -4.5C1 -8 3.5 -8 4.5 -10.5\"/>" \
           "<path class=\"spark\" d=\"M3.2 -11.8 5.8 -9.2M5.8 -11.8 3.2 -9.2\"/>"
  if (n == "portal")
    return "<g class=\"whirl\"><circle r=\"8.5\" stroke-dasharray=\"4.5 3.5\"/></g><circle r=\"4\"/><circle class=\"pip\" r=\"1.2\"/>"
  if (n == "planet")
    return "<circle class=\"solid\" r=\"6.5\"/><ellipse rx=\"11\" ry=\"3.2\" transform=\"rotate(-18)\"/>"
  if (n == "falcon")
    return "<path class=\"solid\" d=\"M0 -8 4 -3 11 7 3 3 0 10 -3 3 -11 7 -4 -3z\"/>"
  if (n == "hook")
    return "<path d=\"M-9 -11 1.5 0.5\"/><path d=\"M1.5 0.5C2.5 5.5 9 6 9.5 1.5C9.8 -1.5 7.5 -3.5 5 -3\"/><path d=\"M5 -3 6.5 -5.5\"/>"
  if (n == "bolts")
    return "<path d=\"M-10 -5H-2M-4 0H4M-2 5H10\"/>"
  if (n == "fighter")
    return "<polygon class=\"solid\" points=\"11,0 -7,-6 -3.5,0 -7,6\"/>"
  return "<g transform=\"rotate(-42)\"><path d=\"M-3.2 -11V-7A3.4 3.4 0 0 0 3.2 -7V-11\"/><path d=\"M0 -3.6V9\"/><circle cx=\"0\" cy=\"10.5\" r=\"1.6\"/></g>"
}

# What the words said, as far as a machine should ever claim to read them. The
# diff says what moved; the tagline says what the pilot thought was happening,
# and a picture that reads only the one is drawing half the commit. Two families
# rather than a vocabulary, because a grammar that garnished every chapter would
# be wallpaper instead of a remark - on this history it fires once in
# twenty-six, which is about right for a joke.
#
# It reads shout(), which is the tagline if there is one, the pilot own line if
# there is not, and the subject if there is neither: the same string the chapter
# shouts in letters you can read from across the room. No clock, no rand - the
# same words draw the same garnish in every clone, forever, like everything else
# down here.
#
# The letter tests either side are not decoration. Without them repair earns a
# pair and breakfast goes fast.
function garnish(v,   t) {
  t = tolower(shout(v))
  if (t ~ /(^|[^a-z])(fast|quick|speed|swift|rush|sooner|hurr|acceler|velocit)/) return "speed"
  if (t ~ /(^|[^a-z])(three|thrice|triple|treble|twice|double|twin|pair|swarm|flock)/) return "echo"
  return ""
}

# One shape, drawn again somewhere else and smaller: what an echo is made of.
# The same two branches picture() has, because a ghost of a rock has to be a
# rock and a ghost of a gear has to be a gear, and a circle standing in for
# either would say nothing at all.
function ghostof(v, k, gx, gy, gr,   j, q, pts, kk, s) {
  kk = kindof(RP[v,k])
  if (kk == "rock") {
    pts = ""
    for (j = 0; j < 9; j++) {
      q = j * 0.6981
      pts = pts f1(gx + cos(q) * gr * rr(0.74, 1.2)) "," f1(gy + sin(q) * gr * rr(0.74, 1.2)) " "
    }
    return "<polygon points=\"" pts "\"/>"
  }
  s = gr / 12
  return "<g transform=\"translate(" f1(gx) "," f1(gy) ") scale(" sprintf("%.2f", s) \
         ")\" stroke-width=\"" sprintf("%.2f", 2.6 / s) "\">" glyphart(kk) "</g>"
}

function picture(v,   out, k, K, j, q, a, c, rb, ang, rad, x, y, r, s, kind, tt, act, tk, bx, by, br, pts, mx, ix, iy, px, py, nx, ny, sa, bf, bj, bs, ba, qx, qy, g) {
  seed(VH[v])
  K = RC[v]
  mx = (RM[v] > 0 ? RM[v] : 1)
  a = rr(0, 6.28318)
  # The field is drawn to fill the frame whether the commit touched one sector
  # or twelve: fewer shapes means they stand further apart and each one is
  # bigger, so a one-file version is a close-up rather than a lonely speck.
  c = 300 / sqrt(K > 0 ? K : 1)
  if (c > 200) c = 200
  if (c < 92)  c = 92
  rb = 0.44 * c
  if (rb > 86) rb = 86
  # What the pilot is doing down there, the diff decides: a commit that
  # deleted something shot it down, one that brought a new file flies it in
  # on a tow beam, one that came back lighter than it went took a bite out of
  # something, a handful of tuned numbers is a sighting pass, and anything else
  # is the standing order - fire at the biggest thing you moved.
  #
  # The bite is the reading that used to be missing. Only a whole file leaving
  # the repository read as damage, so a half-gutted feature and a polished one
  # drew the identical picture. It sits between the sighting pass and the kill
  # on purpose: more than numbers moving, less than a thing leaving the field.
  act = "shot"; tk = 1
  for (k = 1; k <= K; k++) if (RD[v,k]) { act = "kill"; tk = k; break }
  if (act == "shot") for (k = 1; k <= K; k++) if (RA[v,k]) { act = "deploy"; tk = k; break }
  if (act == "shot" && VJ[v] > VI[v])
    for (k = 1; k <= K; k++) if (RG[v,k] > 0) { act = "gnaw"; tk = k; break }
  if (act == "shot" && VI[v] + VJ[v] < 40) act = "tune"
  out = "<svg class=\"art\" viewBox=\"0 0 1400 640\" preserveAspectRatio=\"xMidYMid meet\" aria-hidden=\"true\">"
  out = out "<text class=\"ghost\" x=\"46\" y=\"590\">" roman(v) "</text>"
  for (k = 0; k < 64; k++)
    out = out "<circle class=\"star\" cx=\"" int(rr(10, 1390)) "\" cy=\"" int(rr(10, 630)) \
              "\" r=\"" f1(rr(0.7, 2.2)) "\" style=\"--d:-" f1(rr(0, 4)) "s\"/>"
  # A sunflower spiral: the shapes land evenly without anybody having to solve
  # for overlap, and the busiest sector of the commit sits in the middle of it.
  for (k = 1; k <= K; k++) {
    ang = a + k * 2.39996
    rad = c * sqrt(k - 1)
    x = 700 + cos(ang) * rad + rr(-14, 14)
    y = 312 + sin(ang) * rad * 0.72 + rr(-14, 14)
    r = rb * (0.42 + 0.58 * sqrt(RN[v,k] / mx))
    if (k == tk) { bx = x; by = y; br = r }
    kind = kindof(RP[v,k])
    # How much lighter this one came back, as a fraction of everything that
    # happened to it - so a file that lost three lines out of two hundred takes
    # a nick and a file that lost most of itself takes a chomp, without anybody
    # choosing a threshold. A thing that left the field or arrived in it is
    # already being drawn as that, and is not bitten as well.
    bf = 0
    if (RG[v,k] > 0 && !RD[v,k] && !RA[v,k] && RN[v,k] > 0) {
      bf = RG[v,k] / RN[v,k]
      if (bf > 0.75) bf = 0.75
      if (bf < 0.2)  bf = 0.2
    }
    tt = "<title>" att(RP[v,k]) " &mdash; " \
         (RD[v,k] ? "shot down, " : (RA[v,k] ? "flown in new, " : (bf ? "bitten back, " : ""))) \
         RN[v,k] " line" plural(RN[v,k]) "</title>"
    out = out "<g class=\"drift\" style=\"--d:-" f1(rr(0, 9)) "s;--c:" tint(sector(RP[v,k])) "\">"
    if (kind == "rock") {
      # A rock is bitten in the outline itself, two neighbouring points hauled
      # in towards the middle. It has to be the geometry rather than something
      # laid over the top, because the rock turns and a bite that stayed where
      # it was put while the rock spun under it would read as a smudge on the
      # lens.
      pts = ""
      bj = (bf ? int(rr(0, 9)) : -1)
      for (j = 0; j < 9; j++) {
        q = j * 0.6981
        bs = (j == bj || j == (bj + 1) % 9) ? 1 - bf * 0.75 : 1
        pts = pts f1(x + cos(q) * r * rr(0.74, 1.2) * bs) "," f1(y + sin(q) * r * rr(0.74, 1.2) * bs) " "
      }
      out = out "<polygon class=\"rock" (RD[v,k] ? " gone" : "") "\" points=\"" pts \
                "\" style=\"--s:" f1(rr(18, 46)) "s\">" tt "</polygon>"
    } else {
      # Drawn at radius 12 and scaled to the rock size it would have had, with
      # the stroke divided back out so every silhouette carries the same line.
      s = r / 12
      out = out "<g class=\"glyph " kind (RD[v,k] ? " gone" : "") "\" transform=\"translate(" f1(x) "," f1(y) \
                ") scale(" sprintf("%.2f", s) ")\" stroke-width=\"" sprintf("%.2f", 2.6 / s) "\""
      if (RD[v,k]) out = out " stroke-dasharray=\"" sprintf("%.2f", 5 / s) " " sprintf("%.2f", 8 / s) "\""
      out = out ">" glyphart(kind) tt "</g>"
    }
    # And the piece that came off, for either kind. A silhouette is fixed
    # markup and cannot be deformed the way the rock above just was, so what
    # says the same thing about both is the chip itself, sitting where it came
    # off rather than flying away the way wreckage does. Which is the whole
    # difference between a bite and a kill, said in the vocabulary the field
    # already has: three shards on their way out, or one crumb that stayed.
    if (bf) {
      ba = rr(0, 6.28318)
      qx = x + cos(ba) * (r + 4 + bf * 9); qy = y + sin(ba) * (r + 4 + bf * 9)
      out = out "<path class=\"crumb\" d=\"M" f1(qx) " " f1(qy) \
                "l" f1(rr(5, 11)) " " f1(rr(-4, 4)) "l" f1(rr(-9, -3)) " " f1(rr(4, 9)) "z\"/>"
    }
    if (RD[v,k]) {
      # Wreckage sheds. Three shards, each on its own way out.
      for (j = 0; j < 3; j++) {
        sa = rr(0, 6.28318)
        out = out "<path class=\"shard\" style=\"--d:-" f1(rr(0, 3)) "s;--tx:" f1(cos(sa) * rr(18, 30)) \
                  "px;--ty:" f1(sin(sa) * rr(12, 24)) "px\" d=\"M" f1(x + cos(sa) * r * 0.9) " " f1(y + sin(sa) * r * 0.9) \
                  "l" f1(rr(4, 9)) " " f1(rr(-3, 3)) "l" f1(rr(-7, -2)) " " f1(rr(3, 7)) "z\"/>"
      }
    } else if (RA[v,k]) {
      # A new arrival rings, twice, like a thing still settling into orbit.
      out = out "<circle class=\"born\" cx=\"" f1(x) "\" cy=\"" f1(y) "\" r=\"" f1(r + 7) "\" style=\"--d:0s\"/>" \
                "<circle class=\"born\" cx=\"" f1(x) "\" cy=\"" f1(y) "\" r=\"" f1(r + 7) "\" style=\"--d:-1.4s\"/>"
    }
    out = out "</g>"
  }
  # The pilot, and the move the diff says they made.
  if (K == 0) { bx = 700; by = 312; br = 0; act = "shot" }
  ang = atan2(by - 556, bx - 140)
  nx = 140 + cos(ang) * 32; ny = 556 + sin(ang) * 32
  if (act == "tune") {
    out = out "<line class=\"aim\" x1=\"" f1(nx) "\" y1=\"" f1(ny) "\" x2=\"" f1(bx - cos(ang) * (br + 24)) \
              "\" y2=\"" f1(by - sin(ang) * (br + 24)) "\"/>"
    out = out "<g transform=\"translate(" f1(bx) "," f1(by) ")\"><g class=\"ret\"><circle r=\"" f1(br + 16) "\"/>" \
              "<path d=\"M0 " f1(-br - 23) "V" f1(-br - 9) "M0 " f1(br + 9) "V" f1(br + 23) "M" f1(-br - 23) \
              " 0H" f1(-br - 9) "M" f1(br + 9) " 0H" f1(br + 23) "\"/></g></g>"
  } else if (act == "deploy") {
    px = -sin(ang); py = cos(ang)
    out = out "<line class=\"beam\" x1=\"" f1(nx) "\" y1=\"" f1(ny) "\" x2=\"" f1(bx + px * br * 0.9) \
              "\" y2=\"" f1(by + py * br * 0.9) "\"/>"
    out = out "<line class=\"beam\" x1=\"" f1(nx) "\" y1=\"" f1(ny) "\" x2=\"" f1(bx - px * br * 0.9) \
              "\" y2=\"" f1(by - py * br * 0.9) "\"/>"
  } else {
    ix = bx - cos(ang) * (br + 8); iy = by - sin(ang) * (br + 8)
    out = out "<line class=\"shot\" x1=\"" f1(nx) "\" y1=\"" f1(ny) "\" x2=\"" f1(ix) "\" y2=\"" f1(iy) "\"/>"
    # Six ways for a kill and three for a bite, so the two read apart at a
    # glance: something ended, or something came off.
    if (act == "kill" || act == "gnaw")
      for (j = 0; j < (act == "kill" ? 6 : 3); j++) {
        sa = j * (act == "kill" ? 1.0472 : 0.7854) + rr(-0.25, 0.25)
        out = out "<line class=\"hit\" x1=\"" f1(ix + cos(sa) * 5) "\" y1=\"" f1(iy + sin(sa) * 5) \
                  "\" x2=\"" f1(ix + cos(sa) * rr(14, 24)) "\" y2=\"" f1(iy + sin(sa) * rr(14, 24)) "\"/>"
      }
  }
  out = out "<g class=\"ship\" transform=\"translate(140,556) rotate(" f1(ang * 57.29578) ")\">"
  out = out "<polygon points=\"30,0 -19,-16 -9,0 -19,16\"/></g>"
  # And what the words said, when they said something a picture can hold.
  # Drawn here, after everything the diff decided, so that a chapter whose
  # tagline says nothing draws the field it drew before to the last decimal -
  # the seed hands out no number past this line unless the grammar caught
  # something, which is what lets the grammar grow later without repainting
  # twenty-six chapters that never mentioned speed.
  g = (K > 0 ? garnish(v) : "")
  if (g == "speed") {
    # Three streaks off the back of whatever the pilot was aiming at, pointing
    # the way it came.
    for (j = 0; j < 3; j++) {
      sa = ang + rr(-0.34, 0.34)
      out = out "<line class=\"streak\" style=\"--d:-" f1(rr(0, 0.9)) "s\" x1=\"" \
                f1(bx + cos(sa) * (br + 5)) "\" y1=\"" f1(by + sin(sa) * (br + 5)) "\" x2=\"" \
                f1(bx + cos(sa) * (br + rr(34, 64))) "\" y2=\"" f1(by + sin(sa) * (br + rr(34, 64))) "\"/>"
    }
  } else if (g == "echo") {
    # Two more of it, a third of a turn apart each way, which makes three of
    # the thing altogether. That is the whole joke and it only works if the
    # ghost is the same silhouette as the shape it came off.
    for (j = 1; j <= 2; j++) {
      sa = a + j * 2.0944
      out = out "<g class=\"echo\" style=\"--d:-" f1(j * 0.7) "s;--c:" tint(sector(RP[v,tk])) "\">" \
                ghostof(v, tk, bx + cos(sa) * br * 1.9, by + sin(sa) * br * 1.9 * 0.72, br * 0.62) "</g>"
    }
  }
  # The three things a chapter cannot keep quiet, stamped across the field
  # rather than footnoted under it.
  if (VU[v] != "") out = out stamp("off", "REFEREE OFF", 1060, 116, -13)
  else if (VO[v] != "") out = out stamp("over", "OVERRIDE", 1060, 116, -13)
  if (VL[v] == "")  out = out stamp("untold", "NO LOG", 330, 140, 9)
  return out "</svg>"
}
function stamp(cls, word, x, y, deg) {
  return "<g class=\"stamp " cls "\" transform=\"translate(" x "," y ") rotate(" deg ")\">" \
         "<rect x=\"-158\" y=\"-36\" width=\"316\" height=\"72\" rx=\"4\"/>" \
         "<text x=\"0\" y=\"12\">" word "</text></g>"
}

# --- the small pictures -----------------------------------------------------
# One glyph per thing the book keeps saying, drawn rather than named, so a cel
# is recognisable before it is read. They are stroked in currentColor and they
# are all on the same 24-square grid, which is the entire trick to them looking
# like one set. No file, no font, no request: a chapter is still one page that
# opens from a stick.
function ico(n,   p) {
  if (n == "bolt")           p = "<path d=\"M13 2 4 14h6l-1 8 9-12h-6z\"/>"
  else if (n == "quote")     p = "<path d=\"M4 4h16v12H10l-6 5z\"/><path d=\"M8 9h8M8 12.5h5\"/>"
  else if (n == "gauge")     p = "<path d=\"M3 18a9 9 0 1 1 18 0\"/><path d=\"M12 18l5.5-6.5\"/><circle cx=\"12\" cy=\"18\" r=\"1.6\"/>"
  else if (n == "target")    p = "<circle cx=\"12\" cy=\"12\" r=\"8.5\"/><circle cx=\"12\" cy=\"12\" r=\"3\"/><path d=\"M12 1.5v3M12 19.5v3M1.5 12h3M19.5 12h3\"/>"
  else if (n == "ship")      p = "<path d=\"M21 12 4 20l4-8-4-8z\"/>"
  else if (n == "up")        p = "<path d=\"M12 20V5M6.5 10.5 12 5l5.5 5.5M4 21h16\"/>"
  else if (n == "down")      p = "<path d=\"M12 4v15M6.5 13.5 12 19l5.5-5.5M4 3h16\"/>"
  else if (n == "clock")     p = "<circle cx=\"12\" cy=\"12\" r=\"9\"/><path d=\"M12 6.5V12l3.5 2.5\"/>"
  else if (n == "cal")       p = "<rect x=\"3\" y=\"5\" width=\"18\" height=\"16\" rx=\"1.5\"/><path d=\"M3 10h18M8 3v4M16 3v4\"/>"
  else if (n == "medal")     p = "<circle cx=\"12\" cy=\"15\" r=\"5.6\"/><path d=\"M8.6 3l2.2 5.6M15.4 3l-2.2 5.6\"/>"
  else if (n == "eye")       p = "<path d=\"M2 12s4.2-6 10-6 10 6 10 6-4.2 6-10 6-10-6-10-6z\"/><path d=\"M3 3l18 18\"/>"
  else if (n == "scroll")    p = "<path d=\"M6.5 3h11v18h-11z\"/><path d=\"M9.5 8h5M9.5 12h5M9.5 16h3\"/>"
  else if (n == "hourglass") p = "<path d=\"M6 3h12M6 21h12M7.5 3v3.5L12 12l4.5-5.5V3M7.5 21v-3.5L12 12l4.5 5.5V21\"/>"
  else if (n == "coin")      p = "<circle cx=\"12\" cy=\"12\" r=\"9\"/><path d=\"M12 6.5v11M9.5 9.5h5M9.5 14.5h5\"/>"
  else if (n == "frame")     p = "<rect x=\"3\" y=\"4.5\" width=\"18\" height=\"15\" rx=\"1.5\"/><path d=\"M3 15.5l4.5-4.5 3.5 3.5 3-3 7 7\"/><circle cx=\"8.5\" cy=\"9\" r=\"1.4\"/>"
  else if (n == "grid")      p = "<rect x=\"3.5\" y=\"3.5\" width=\"7\" height=\"7\"/><rect x=\"13.5\" y=\"3.5\" width=\"7\" height=\"7\"/><rect x=\"3.5\" y=\"13.5\" width=\"7\" height=\"7\"/><rect x=\"13.5\" y=\"13.5\" width=\"7\" height=\"7\"/>"
  # The marks. Nine of them, one per part of the cabinet a commit can move. The
  # two loudest borrow their glyphs from what they actually are: the game is the
  # ship above, the same triangle the field is flown with, and the game behind
  # it is a prompt, because every event and every rule in this place was typed at
  # one. The rest are the thing they name.
  else if (n == "prompt")    p = "<path d=\"M4 6.5 10 12l-6 5.5\"/><path d=\"M12.5 17.5h7.5\"/>"
  else if (n == "panel")     p = "<rect x=\"2.5\" y=\"4\" width=\"19\" height=\"16\" rx=\"1.5\"/><path d=\"M2.5 9h19M6 12.5h9M6 16h6\"/><circle cx=\"5.4\" cy=\"6.5\" r=\"0.9\"/>"
  else if (n == "note")      p = "<path d=\"M9 17.5V4.5l11-1.5v13\"/><circle cx=\"6.4\" cy=\"17.5\" r=\"2.6\"/><circle cx=\"17.4\" cy=\"16\" r=\"2.6\"/>"
  else if (n == "pad")       p = "<rect x=\"2\" y=\"7\" width=\"20\" height=\"10\" rx=\"3.5\"/><path d=\"M7 10v4M5 12h4\"/><circle cx=\"16\" cy=\"11\" r=\"1.1\"/><circle cx=\"18.5\" cy=\"13.5\" r=\"1.1\"/>"
  else if (n == "core")      p = "<circle cx=\"12\" cy=\"12\" r=\"2.2\"/><ellipse cx=\"12\" cy=\"12\" rx=\"10\" ry=\"4\"/><ellipse cx=\"12\" cy=\"12\" rx=\"10\" ry=\"4\" transform=\"rotate(60 12 12)\"/><ellipse cx=\"12\" cy=\"12\" rx=\"10\" ry=\"4\" transform=\"rotate(120 12 12)\"/>"
  else if (n == "book")      p = "<path d=\"M12 6.5C10.5 4.8 8 4 4 4.2v13.5C8 17.5 10.5 18.3 12 20\"/><path d=\"M12 6.5C13.5 4.8 16 4 20 4.2v13.5c-4-.2-6.5.6-8 2.3z\"/><path d=\"M12 6.5V20\"/>"
  else if (n == "wrench")    p = "<path d=\"M15.6 3.4a5 5 0 0 0-6.2 6.4L3 16.2 6.8 20l6.4-6.4a5 5 0 0 0 6.4-6.2l-3 3-2.8-2.8z\"/>"
  else return ""
  return "<svg class=\"ic\" viewBox=\"0 0 24 24\" aria-hidden=\"true\">" p "</svg>"
}

# --- the marks, drawn ---------------------------------------------------------
# markof() and markname() are not here any more: they are in the library at the
# top of this file, where tools/labels.sh can reach them through --marks. What
# is left down here is how a mark is drawn and how it reads in a sentence,
# which is the half of it nobody outside the book has any use for.
#
# The same thing in a sentence, where the article is doing work. Only the prose
# uses this; every badge in the book uses the bare word markname() gives.
function marklabel(k) { return "the " markname(k) }
function markglyph(k) {
  # The two loudest parts of the cabinet get the two glyphs the game itself is
  # made of: the ship you fly, and the prompt the rest of us are typing at.
  if (k == "game")   return "ship"
  if (k == "meta")   return "prompt"
  if (k == "ui")     return "panel"
  if (k == "music")  return "note"
  if (k == "hands")  return "pad"
  if (k == "engine") return "core"
  if (k == "book")   return "book"
  if (k == "rules")  return "wrench"
  return "scroll"
}

# A set of marks, collected in whatever order the numstat arrived in, printed
# back in the one order MARKS gives them.
function marksort(seen,   i, n, m, out) {
  n = split(MARKS, m, " ")
  out = ""
  for (i = 1; i <= n; i++) if (m[i] in seen) out = out (out == "" ? "" : " ") m[i]
  return out
}
# The badges themselves. cls "tiny" is the icon-only form for a list; the label
# stays in the markup either way, because a row of pictures with no words in it
# is unreadable to anybody who cannot see the pictures.
function markrow(s, cls,   i, n, m, out) {
  if (s == "") return ""
  n = split(s, m, " ")
  out = "<span class=\"marks" (cls != "" ? " " cls : "") "\">"
  for (i = 1; i <= n; i++)
    out = out "<span class=\"mk mk-" m[i] "\" title=\"" markname(m[i]) "\">" \
              ico(markglyph(m[i])) "<em>" markname(m[i]) "</em></span>"
  return out "</span>"
}
# The same set said out loud, for the prose a summary is written in.
function marksaid(s,   i, n, m, out) {
  n = split(s, m, " ")
  out = ""
  for (i = 1; i <= n; i++) out = out (i == 1 ? "" : (i == n ? " and " : ", ")) marklabel(m[i])
  return out
}

# --- a book -----------------------------------------------------------------
# What a run of chapters was, in a paragraph. The cover has the room for it and
# prints it under the spine; a chapter page does not, and does not get one - a
# reader who is already inside a book does not need it summarised at them.
function gist(b,   s, n, days, mv) {
  n = BE[b] - BS[b] + 1
  s = n " chapter" plural(n) ", " (n == 1 ? "v" BS[b] : "v" BS[b] " through v" BE[b]) ", "
  days = int((VA[BE[b]] - VA[BS[b]]) / 86400)
  s = s (days < 1 ? "all of it inside a day" : "over " days " day" plural(days)) ". "
  s = s BI[b] " line" plural(BI[b]) " aboard and " BJ[b] " jettisoned, across " \
      BF[b] " sector" plural(BF[b])
  mv = marksaid(BM[b])
  s = s (mv == "" ? ". " : "; it moved " mv ". ")
  if (BO[b]) s = s BO[b] " override" plural(BO[b]) " spent, in writing, for good. "
  if (BX[b]) s = s "The referee never saw " BX[b] " of " (BX[b] == 1 ? "them" : "these") ". "
  if (BN[b]) s = s BN[b] " other thing" plural(BN[b]) " happened while it was being written. "
  sub(/[[:space:]]+$/, "", s)
  return s
}
# The label a book wears wherever it is named, on the cover and in the dock.
function bspan(b) { return BS[b] == BE[b] ? "v" BS[b] : "v" BS[b] "&ndash;v" BE[b] }

# One number, its glyph and what it counts. data-n is there for the script to
# count up to on the way past; the tile already reads correctly without it,
# because a page that needs JavaScript to say 99 is a worse page.
function tile(name, n, val, lab) {
  return "<li>" ico(name) "<b" (n != "" ? " data-n=\"" n "\"" : "") ">" val "</b><span>" lab "</span></li>\n"
}

# An override line arrives as "GR5 - because", and the rule it bent is the part
# worth reading from the doorway. The rest is the sentence under it.
function grtag(s) { return (match(s, /GR[0-9]+/) ? substr(s, RSTART, RLENGTH) : "OVERRIDE") }
function grwhy(s) {
  sub(/^[[:space:]]*GR[0-9]+[[:space:]]*[-:]?[[:space:]]*/, "", s)
  return s
}

BEGIN { ver = total; bound = (rules != "")
        MARKS = markorder() }
$1 == "TAG" { tag[$2] = $3; next }
$1 == "OWN" { owner[$2] = $3; next }
$1 == "REN" { moveto[$2 SUBSEP $3] = $4; cameto[$2 SUBSEP $4] = $3; next }
$1 == "ART" { art[$2] = $3; altof[$2] = $4; next }
$1 == "ART" { plate[$2] = $3; plated[$2] = $4; next }
$1 == "FACE" { mug[$2] = $3; next }
# Everything the pilot pages are made of, arriving the same way the plates and
# the faces do - folded into the one stream rather than opened in the middle of
# it. None of it is read before END: a pilot page is about a whole history, so
# there is nothing useful to say about any of it until the history has gone by.
$1 == "GUIDE" { gname[$2] = $3; ggroup[$2] = $4; gdesc[$2] = $5; next }
$1 == "ARM"   { an++; aid[an] = $3; aby[an] = $4; anm[an] = $5; abl[an] = $6; next }
$1 == "FLY"   { fn++; fwho[fn] = $2; frk[fn] = $3; fsc[fn] = $4
                fwv[fn] = $5; ftm[fn] = $6; fac[fn] = $7; fsd[fn] = $8; next }
$1 == "FIRE"  { evfired[$3]++; evkill[$3] += $6; evflew[$3 SUBSEP $4] = 1; next }
$1 == "TREE"  { intree[$2] = 1; next }
$1 == "LED"   { lbend[$2] = $3; lclean[$2] = $4; llast[$2] = $5; next }
$1 == "MET"   { msince[$2] = $3; mflown[$2] = $4; next }
NF < 4 { next }
{
  # Reading newest first, this is where the rules stop existing. The commit that
  # brought them is the last one nobody can be judged for.
  if (bound && $1 == rules) bound = 0

  # Nobody flew it. A machine files the paperwork the book keeps about itself,
  # and the book passes over that filing in silence everywhere it speaks - so it
  # is not a version, not a mention, and not a name on the roster. Dropped here,
  # before the version branch spends a number on it, because the count above has
  # already left it out and the two have to arrive at the same total.
  if (is_machine($2, $6)) next

  who  = $2
  split($3, dt, "|")
  when = dt[1]
  clock = dt[2]
  subj = $4
  rest = $7

  # Trailers, including the wrapped ones: a line indented under a trailer is a
  # continuation of it, which is how anybody sane writes a two-line reason.
  line = ""; overrides = ""; rulechange = ""; tallyline = ""; breach = ""; mode = ""
  gamefiles = 0; files = 0; acmr = 0; ins = 0; del = 0; kc = 0; fpn = 0
  refmoved = 0; docmoved = 0; bookmoved = 0; readmemoved = 0; elsemoved = 0
  filedmoved = 0
  rankmoved = 0
  refstrict = 0; nonref = 0; stolen = 0
  split("", deleted); split("", arrived); split("", fseen); split("", fadd); split("", fdel)
  split("", xown)
  split("", mkseen); split("", mkheld)
  n = split(rest, b, "\n")
  for (k = 1; k <= n; k++) {
    t = b[k]
    lt = tolower(t)
    # The raw diff arrives ahead of the numstat, so by the time the counting
    # starts the book already knows which paths left the repository - and which
    # ones this commit brought into it, because the picture draws the two
    # differently.
    if (is_raw(t)) {
      split(t, rw, "\t")
      rn = split(rw[1], rf, " ")
      if (rf[rn] ~ /^D/) deleted[rw[2]] = 1
      else if (rf[rn] ~ /^A/) arrived[rw[2]] = 1
      mode = ""; continue
    }
    if (is_stat(t)) {
      split(t, ns, "\t")
      p = ns[3]
      mark_into(p, mkseen, mkheld)
      # Whose work this commit landed in, other than the work of the pilot who
      # landed it. GR8 is the rule with no check on it, and this is as close as
      # the history comes to answering it: a version that moved a file somebody
      # else created is the one thing a shared cabinet cannot read off a single
      # diff.
      if (is_game(p) && (p in owner) && owner[p] != who) xown[owner[p]] = 1
      if (is_game(p)) gamefiles++
      else if (p ~ /^tools\// || p ~ /^\.githooks\// || p ~ /^\.claude\// ||
               p ~ /^\.github\// ||
               p == "CLAUDE.md" || p == "GOLDEN_RULES.md") refmoved = 1
      else if (is_book(p)) bookmoved = 1
      # Repainted from the history by the same hook that rebuilt the pages, so a
      # filing that carried one is still a filing. Held apart from bookmoved
      # because the deeds below name the book by that, and a badge is not the
      # book being rewritten.
      else if (is_filed(p)) filedmoved = 1
      # Neither column, and deliberately nothing - is_mute above says why.
      else if (is_mute(p)) { }
      else if (p ~ /^docs\//) {
        docmoved = 1
        # And a narrower name for one of them, read by the deed below and by
        # nothing else. The board is docs but not the book, so a ranked flight
        # has always landed in docmoved and read as the book being rebuilt.
        # Set beside docmoved rather than instead of it, so that the paperwork
        # silence a few lines down - which asks !docmoved - sees exactly what
        # it always saw.
        if (p == "docs/RANKINGS.md") rankmoved = 1
      }
      else if (p == "README.md") readmemoved = 1
      else elsemoved = 1
      # For the audit, and only for it: the two sides GR10 keeps apart. docs/ is
      # on neither, being written by a machine from the history - carrying the
      # rebuilt book along with a rule change is not a rule broken. The ledger
      # is machine-written too, and the referee treats it the same way.
      if (is_referee(p)) refstrict = 1
      else if (p !~ /^docs\// && p != "src/game/ledger.js") nonref = 1
      # GR11 has no budget and no override, so the only question is who made it.
      if (p ~ /^src\/events\/.+\.js$/ && (p in owner) && owner[p] != who)
        stolenpath[++stolen] = p
      # GR4 and GR5 ask per file rather than per commit, so the audit keeps
      # both sides of the numstat for every path they measure - and both halves
      # of a move count into the path it moved to, which is the file the referee
      # weighed. A departure is the whole file out and an arrival is the whole
      # file in; the two together net to what the diff actually did to it.
      if (is_gutted_ground(p)) {
        bk = went($1, p)
        if (!(bk in fseen)) { fseen[bk] = 1; fp[++fpn] = bk }
        fadd[bk] += (ns[1] == "-" ? 0 : ns[1])
        fdel[bk] += (ns[2] == "-" ? 0 : ns[2])
      }
      if (p !~ /^docs\//) {
        files++
        if (!(p in deleted)) acmr++
        if (ns[1] != "-") ins += ns[1]
        if (ns[2] != "-") del += ns[2]
        # A binary file reports both sides as a dash, and nought minus nought is
        # a file that lost nothing, which is the right answer for a picture.
        pa = (ns[1] == "-" ? 0 : ns[1]); pd = (ns[2] == "-" ? 0 : ns[2])
        keep(p, pa + pd, (p in deleted), (p in arrived), pd - pa)
      }
      mode = ""; continue
    }
    if (lt ~ /^[[:space:]]*chronicle:/)            { sub(/^[^:]*:[[:space:]]*/, "", t); line = t; mode = "c"; continue }
    if (lt ~ /^[[:space:]]*golden-rule-override:/) { sub(/^[^:]*:[[:space:]]*/, "", t)
                                                     overrides = overrides (overrides ? " // " : "") t; mode = "o"; continue }
    if (lt ~ /^[[:space:]]*rule-change:/)          { sub(/^[^:]*:[[:space:]]*/, "", t); rulechange = t; mode = "r"; continue }
    if (lt ~ /^[[:space:]]*tally:/)                { sub(/^[^:]*:[[:space:]]*/, "", t); tallyline = t; mode = ""; continue }
    if (lt ~ /^[[:space:]]*golden-rule-breach:/)   { sub(/^[^:]*:[[:space:]]*/, "", t)
                                                     breach = breach (breach ? " // " : "") t; mode = "b"; continue }
    if (lt ~ /^[[:space:]]*tagline:/)              { mode = "t"; continue }   # kept in docs/taglines.tsv, printed from there
    if (mode != "" && t ~ /^[[:space:]]+[^[:space:]]/) {
      sub(/^[[:space:]]+/, "", t)
      if (mode == "c") line = line " " t
      else if (mode == "o") overrides = overrides " " t
      else if (mode == "r") rulechange = rulechange " " t
      else if (mode == "b") breach = breach " " t
      continue
    }
    mode = ""
  }
  # Every path in, so the manifest can now be asked what company it kept.
  mark_settle(mkseen, mkheld)

  # ---- what the referee would have said, had anybody let it look ------------
  # Only the rules a commit can still be judged by on its own, years later: the
  # size budget, the two halves of GR10, whose event file this was, and the
  # gutting budgets - net lines out of a file, measured against its first
  # author (GR4) or against everybody (GR5). Break one of them with no override
  # line and the commit never met the referee at all, because the referee would
  # not have let it past. Somebody switched it off, and that is a thing the
  # book knows how to say.
  unrec = ""
  if (bound) {
    # A commit that is nothing but the rules and their machinery is exempt
    # from the size budget - GR6 says so since the amendments - so the audit
    # must not accuse what the referee now allows.
    if ((ins > 1200 || acmr > 25) && !(refstrict && !nonref) && toupper(overrides) !~ /GR6/) {
      if (ins > 1200 && acmr > 25) how = ins " line" plural(ins) " aboard across " acmr " sector" plural(acmr)
      else if (ins > 1200)         how = ins " line" plural(ins) " aboard"
      else                         how = acmr " sector" plural(acmr) " touched"
      unrec = unrec "It went past GR6, " how ", with nothing written down. "
    }
    if (refstrict && nonref)
      unrec = unrec "The rules and the game moved in the same commit, which GR10 does not allow at any price. "
    if (refstrict && rulechange == "")
      unrec = unrec "The rules were changed with no Rule-Change: line to say why. "
    for (q = 1; q <= stolen; q++)
      unrec = unrec "It touched " esc(owner[stolenpath[q]]) "&rsquo;s event file, " esc(stolenpath[q]) \
                    ", which GR11 leaves to " esc(owner[stolenpath[q]]) " alone. "
    # GR4 and GR5, per file: the same net-lines arithmetic the referee runs,
    # measured against whoever first added the file, overrides honoured. In
    # lockstep with the --skips mode above - same budgets, same exemptions -
    # and tools/lockstep.sh is what makes that a fact rather than a request:
    # --audit is this audit with the book left unwritten, and the two lists are
    # compared on a scripted cabinet and on this history, every commit.
    #
    # A file that moved is asked about under the name it had, the way the
    # referee asks (came_from, GR4). It is named that way too: a chapter saying
    # somebody gutted a path that did not exist until this commit reads as a
    # typo rather than as an accusation.
    for (q = 1; q <= fpn; q++) {
      p = fp[q]; src = came($1, p)
      nm = (src == p) ? esc(p) : esc(p) " (was " esc(src) ")"
      if (p in deleted) {
        if (is_commons(src)) {
          if (toupper(overrides) !~ /GR5/)
            unrec = unrec "It deleted " nm ", which is commons and everybody&rsquo;s, past GR5 with nothing written down. "
        } else if ((src in owner) && owner[src] != who && toupper(overrides) !~ /GR4/)
          unrec = unrec "It deleted " esc(owner[src]) "&rsquo;s " nm " outright, past GR4 with nothing written down. "
      } else if (is_commons(src)) {
        if (fdel[p] - fadd[p] > 60 && toupper(overrides) !~ /GR5/)
          unrec = unrec "It cut " (fdel[p] - fadd[p]) " lines net out of " nm \
                        ", which is commons, past GR5&rsquo;s budget with nothing written down. "
      } else if ((src in owner) && owner[src] != who && fdel[p] - fadd[p] > 25 && \
                 toupper(overrides) !~ /GR4/)
        unrec = unrec "It gutted " esc(owner[src]) "&rsquo;s " nm " by " (fdel[p] - fadd[p]) \
                      " lines net, past GR4&rsquo;s budget with nothing written down. "
    }
    sub(/[[:space:]]+$/, "", unrec)
  }

  # --audit stops here, with the verdict and nothing else - the shape --skips
  # prints, so tools/lockstep.sh can hold the two side by side. Everything below
  # is the book, and the book is not being written on this run.
  if (auditonly) {
    if (unrec != "") printf "%s\t%s\n", $1, who
    next
  }

  # The roster counts both, and counts them for an interlude too: a rule bent
  # while nothing was on the cabinet is still a rule bent.
  if (overrides != "") bent[who]++
  if (unrec != "")     cheat[who]++

  # ---- the filing the book does about itself, passed over in silence --------
  # The book rebuilding itself is not a thing that happened. Every commit leaves
  # docs/ a commit out of date, so the next one carries the rebuilt book - and
  # if that counted as an interlude it would leave the book out of date again,
  # one identical line longer every time, for ever. Nothing is lost by passing
  # over it: the pages it wrote are the book you are reading. A commit that
  # spent an override, altered a rule, went round the referee or was written up
  # by the ledger is still an event, whatever else it touched, and it keeps its
  # note.
  #
  # is_filing above is that rule, and the digest asks it the same question out
  # of its own variables. It used to live inside the interlude branch below,
  # spelled a second way; it is out here now so that both callers can be handed
  # the same commits - --book-silence is this line, printed, and
  # tools/lockstep.sh puts them side by side.
  #
  # unrec is the one term the digest has nothing to answer with, and it cannot
  # change the verdict: the audit measures nothing under docs/, so a commit
  # whose every path is a book file never has one. It is in because a guard
  # that costs nothing and would matter if that ever stopped being true is
  # worth keeping where the fixture can watch it.
  if (is_filing(gamefiles, (bookmoved || filedmoved),
                (docmoved || refmoved || readmemoved || elsemoved),
                (overrides != "" || rulechange != "" || tallyline != "" ||
                 breach != "" || unrec != ""))) {
    if (silenceonly) printf "%s\t%s\n", $1, who
    next
  }
  if (silenceonly) next

  # Everything the pilot pages count that both kinds of commit can carry. A
  # mention belongs to a history as much as a version does - the two are told
  # apart below this line, not above it - so the dates and the marks are
  # gathered up here, where a commit is still only a commit.
  #
  # The log arrives newest first, so the last date written is the oldest one.
  if (!(who in plast)) { plast[who] = when; plastat[who] = $5 }
  pfirst[who] = when; pfirstat[who] = $5
  pmn = split(marksort(mkseen), pmv, " ")
  for (k = 1; k <= pmn; k++) pmk[who SUBSEP pmv[k]]++

  # Every time this pilot spent something, kept where both kinds of commit
  # still pass. A version writes its receipt into its own chapter; a mention
  # writes one into the margin of whichever chapter was on the cabinet while it
  # happened. Both are read at v<ver>.html, which is what lets one list carry
  # the two - and ver is still the number this commit takes, or the number it
  # happened alongside, because the branch below has not run yet.
  #
  # Three things and deliberately not four: an override, a referee that was
  # never asked, and a breach the table called. Altering a rule is none of
  # those. It is the most public thing anybody does here, it costs nothing on
  # the tally, and a hundred of them filed under a heading that says ledger
  # would say the opposite of what the ledger says.
  #
  # One row per override line rather than per commit, because that is how
  # tools/tally.sh charges them: a commit that spent two budgets in one message
  # is two on the ledger, and a list that showed it once would be four receipts
  # under a heading that says five.
  if (overrides != "" || unrec != "" || breach != "") {
    rcc = 0
    if (overrides != "") {
      rcc = split(overrides, rcl, " // ")
      for (rci = 1; rci <= rcc; rci++) receipt(who, ver, gamefiles, subj, grtag(rcl[rci]) " spent, in writing")
    }
    if (unrec != "")  receipt(who, ver, gamefiles, subj, "the referee never saw it")
    if (breach != "") receipt(who, ver, gamefiles, subj, "the table called a breach")
  }

  # ---- an interlude: a commit that left the game exactly as it found it -----
  # A line on the cover, and a note in the margin of whichever version was on
  # the cabinet while it happened. That is the whole of what a mention is: it
  # never gets a number, so it never gets a page.
  if (gamefiles == 0) {
    if (rulechange != "" || refmoved) deed = "changed the rules"
    else if (readmemoved)             deed = "rewrote the notes on the cabinet"
    # Above the book branch, because a flight lands on the board and the book
    # is rebuilt on top of it in the same commit - and of the two things that
    # happened, only one of them is somebody having played the game.
    else if (rankmoved && !elsemoved) deed = "put a flight on the board"
    else if ((docmoved || bookmoved) && !elsemoved)
                                      deed = "rebuilt the book"
    else                              deed = "did some housekeeping"

    if (ver > 0) said = "While v" ver " was on the cabinet, <b>" esc(who) "</b> " deed "."
    else         said = "Before there was a game to change, <b>" esc(who) "</b> " deed "."

    note = "  <p class=\"between\">" said "</p>\n"
    note = note "  <p class=\"subj\">landed as &ldquo;" esc(subj) "&rdquo; &mdash; " esc(when) "</p>\n"
    if (rulechange != "")
      note = note "  <p class=\"lawchange\">The rules themselves were altered: " esc(rulechange) "</p>\n"
    if (overrides != "")
      note = note "  <p class=\"override\">On this day " esc(who) " invoked an override: " esc(overrides) "</p>\n"
    if (tallyline != "")
      note = note "  <p class=\"ledger\">The ledger, written by the machine and not by the pilot: " esc(tallyline) "</p>\n"
    if (breach != "")
      note = note "  <p class=\"override\">On this day the table spoke, and called a landing across the fairness line: " esc(breach) "</p>\n"
    # Already escaped where it quotes anybody - it is assembled, not copied.
    if (unrec != "")
      note = note "  <p class=\"unrecorded\">The referee never saw this one. " unrec "</p>\n"

    IB[ver] = IB[ver] "<article class=\"interlude\">\n" note "</article>\n"
    IBN[ver]++
    # The subject travels to the cover as well as the chapter. A deed is one of
    # five sentences, so two rule changes in a row read as the same line twice -
    # which is exactly how the book writing itself four times went unnoticed.
    # The version on the cabinet at the time rides along too: it is what puts
    # an interlude on the right shelf below, in the book that was being written
    # while it happened. Nothing before v1 has a book to belong to, and 0 is
    # read as the first one.
    # The author rides along as a sixth field. The cover shelves every mention
    # under whichever book was being written at the time, whoever wrote it,
    # which is the true story of the cabinet; a pilot page shelves only the
    # ones that are theirs, because a book of somebody else errands filed under
    # your name is a worse story than no errands at all. entry() reads neither.
    ENT[++en] = "I" SUBSEP said SUBSEP esc(subj) SUBSEP ver SUBSEP marksort(mkseen) SUBSEP who
    interludes[who]++
    next
  }

  # ---- a version -----------------------------------------------------------
  # Kept whole rather than printed. A page has to know what came before it and
  # what came after, and the log arrives newest first, so neither is known yet.
  v = ver--
  pilots[who]++
  if (v > peak[who]) peak[who] = v
  # Counted once per version rather than once per file: landing in four files
  # belonging to one pilot on one evening is a single visit, not four.
  for (xo in xown) { cross[who SUBSEP xo]++; crossv[who SUBSEP xo] = crossv[who SUBSEP xo] " " v }

  VH[v] = $1;    VW[v] = who;  VN[v] = when;   VC[v] = clock; VA[v] = $5
  VS[v] = subj;  VL[v] = line; VT[v] = ($1 in tag) ? tag[$1] : ""
  VP[v] = ($1 in plate) ? plate[$1] : "";  VQ[v] = ($1 in plated) ? plated[$1] : ""
  VF[v] = files; VI[v] = ins;  VJ[v] = del;  VM[v] = marksort(mkseen)
  VO[v] = overrides; VU[v] = unrec; VR[v] = rulechange; VB[v] = breach
  VP[v] = ($1 in art) ? art[$1] : ""; VQ[v] = altof[$1]
  RC[v] = kc;    RM[v] = kn[1]
  for (k = 1; k <= kc; k++) {
    RP[v,k] = kp[k]; RN[v,k] = kn[k]; RD[v,k] = kd[k]; RA[v,k] = kb[k]; RG[v,k] = kg[k]
  }
  ENT[++en] = "V" SUBSEP v
}
# One line of the contents, a version or an interlude, wearing the marks for
# whatever it moved. The same shape inside every book on the shelf, so a reader
# learns it once and then reads down all of them.
function entry(f, e,   v) {
  if (e[1] == "V") {
    v = e[2]
    # No face and no name on a chapter here. The book above it already says
    # whose run this is, in bigger letters and with the portrait, and repeating
    # it down every row of a twenty-six-chapter book was the same answer to a
    # question nobody was still asking.
    printf "<li class=\"cv\"><a href=\"v%s.html\"><b>v%s</b><span>%s</span>%s</a></li>\n", \
           v, v, esc(shout(v)), markrow(VM[v], "tiny") > f
  } else {
    # The sentence is wrapped rather than left loose in the li, so the row can
    # be a grid: a bare run of text with a <b> in the middle of it arrives at a
    # grid container as three anonymous items, and the marks used to be floated
    # past it instead - which on a phone put the icons through the middle of
    # the words they were about.
    printf "<li class=\"ci\"><span class=\"what\">%s</span>%s", e[2], markrow(e[5], "tiny") > f
    if (e[3] != "") printf "<span class=\"said\">&ldquo;%s&rdquo;</span>", e[3] > f
    print "</li>" > f
  }
}

# ---- a pilot, characterised --------------------------------------------------
# The tiles on a pilot page already count everything there is to count, so the
# paragraph beside them is not for counting. It is for saying what the counts
# add up to: which corner of the cabinet somebody keeps standing in, whether
# they hold the floor or land and step back, what they left out there for
# everybody else, and whether they have ever flown the thing they keep
# building. Nothing in here is a number this file worked out - every clause is
# a fact printed in full two cels further down, said in a voice instead of in a
# column.
#
# It is a characterisation and it is allowed an opinion. The opinion is the
# whole point: a page that only listed would be the roster row again, longer.

# What somebody keeps doing, off whichever mark they keep hitting. Nine marks,
# nine ways of being a person about an arcade cabinet.
function archetype(k) {
  if (k == "game")   return "builds the things that come at you"
  if (k == "meta")   return "is here for the game behind the game rather than for the rocks"
  if (k == "ui")     return "cannot walk past a panel without straightening it"
  if (k == "music")  return "hears this cabinet before they look at it"
  if (k == "hands")  return "argues with the controls until they answer back"
  if (k == "engine") return "goes in under the hood and closes it again after"
  if (k == "book")   return "keeps the book, which is how anybody knows any of this happened"
  if (k == "rules")  return "moves the goalposts in writing, where everybody can watch"
  return "writes it down, which is rarer around here than it sounds"
}
# The same thing short enough to wear. A badge is read at a glance and a
# sentence is not, so these are nicknames rather than summaries.
function traitword(k) {
  if (k == "game")   return "rock wrangler"
  if (k == "meta")   return "rules mechanic"
  if (k == "ui")     return "panel botherer"
  if (k == "music")  return "noise merchant"
  if (k == "hands")  return "stick and trigger"
  if (k == "engine") return "under the hood"
  if (k == "book")   return "keeps the book"
  if (k == "rules")  return "goalpost mover"
  return "writes it down"
}
# One badge, in the same furniture the marks wear everywhere else in the book -
# same pill, same palette, so a reader who has learnt one row has learnt this
# one. The colour is borrowed for its mood rather than for its meaning, which
# is the only liberty taken here.
function chip(mk, glyph, word) {
  return "<span class=\"mk mk-" mk "\">" ico(glyph) "<em>" word "</em></span>"
}
function traits(p, longest, topmk, dist, ng, ne, nfl, bestwv, ncr,   out) {
  out = ""
  if (topmk != "") out = out chip(topmk, markglyph(topmk), traitword(topmk))
  if (pilots[p] == 0)     out = out chip("notes", "hourglass", "never landed")
  else if (longest >= 6)  out = out chip("game", "medal", "holds the floor")
  else if (longest <= 1)  out = out chip("book", "clock", "in and out")
  if (dist >= 7)          out = out chip("meta", "grid", "everywhere at once")
  else if (dist <= 2)     out = out chip("meta", "frame", "one corner")
  if (ne > 0)             out = out chip("hands", "eye", "lays traps")
  if (ng >= 5)            out = out chip("ui", "panel", "all over the guide")
  if (nfl == 0)           out = out chip("ui", "ship", "never flown")
  else if (bestwv + 0 >= 8) out = out chip("ui", "ship", "flies deep")
  if (!(p in lbend) || lbend[p] + 0 == 0) out = out chip("music", "scroll", "clean sheet")
  else if (lbend[p] + 0 >= 3)             out = out chip("music", "scroll", "spends the budget")
  if (ncr > 0)            out = out chip("engine", "core", "goes visiting")
  return out == "" ? "" : "<p class=\"marks traits\">" out "</p>"
}
function whois(p, longest, longbook, topmk, secmk, dist, ng, ne, nfl, bestwv, ncr,
               s, i, trap, hi, n, more) {
  s = "<b>" esc(p) "</b> "
  # Somebody with no commits at all has no mark, so there is nothing here to be
  # a characterisation of. Say that, rather than guessing at a person.
  if (topmk == "")
    return s "has not moved a file in this cabinet yet, so the history has no " \
             "opinion about them. It forms one quickly."

  s = s archetype(topmk)
  if (secmk != "" && secmk != topmk) s = s ", and the rest of the time they are in " marklabel(secmk)
  s = s ". "

  # How they take a turn. A long run is somebody who holds the floor; a shelf
  # of single chapters is somebody who lands and gets out of the way.
  if (pilots[p] == 0)
    s = s "They have never taken a version number, which is a quieter way to leave " \
          "fingerprints on a cabinet rather than a lesser one. "
  else if (longest >= 6)
    s = s "They hold the floor &mdash; book " roman(longbook) " ran " longest \
          " chapters deep before anybody else got a turn. "
  else if (longest > 1)
    s = s "They land in short runs and then hand the room back. "
  else
    s = s "They land one at a time and step out of the way. "

  # How much of the cabinet they are willing to stand in, and whether they stay
  # on their own side of it.
  if (dist >= 7)       s = s "There is no corner of this place they have not stood in"
  else if (dist <= 2)  s = s "They keep to one corner, and they keep it well"
  else                 s = s "They work a few corners of the cabinet rather than all of them"
  s = s (ncr > 0 ? ", including corners that belong to other people. " : ". ")

  # What they left out there for everybody else. A guide tile is met by whoever
  # presses ENTER; an ambush is met by everybody except the person who wrote it.
  # The one worth naming is whichever has met the most pilots on the filed
  # tapes, because that is the one somebody reading this has already been
  # killed by. The rest are counted rather than listed - a page that named four
  # ambushes in a paragraph has stopped characterising and started indexing.
  trap = ""; hi = -1
  for (i = 1; i <= an; i++) {
    if (aby[i] != p) continue
    n = (aid[i] in evfired) ? evfired[aid[i]] : 0
    if (n > hi) { hi = n; trap = anm[i] }
  }
  more = (ne > 1 \
          ? "<b>" esc(trap) "</b> is one of " ne " ambushes of theirs out there, and not one " \
            "of them will ever fire at the person who wrote it. " \
          : "<b>" esc(trap) "</b> is out there waiting for everybody but them. ")
  if (ng > 0 && ne > 0)
    s = s (ng >= 5 ? "A great deal of" : "Some of") " what a player meets tonight came out " \
          "of files they created, and " more
  else if (ng > 0)
    s = s (ng >= 5 ? "A great deal of" : "Some of") " what a player meets tonight came out " \
          "of files they created. "
  else if (ne > 0)
    s = s "They have laid an ambush: " more
  else
    s = s "Nothing in the field carries their name yet. "

  # And whether they have ever flown the thing they keep building.
  if (nfl == 0)
    s = s "Nothing of theirs is on the board, which is four minutes of work away. "
  else if (bestwv + 0 >= 8)
    s = s "They fly deep when they fly: wave " esc(bestwv) " on their best evening. "
  else
    s = s "They have flown it as well as built it, which is not true of everybody here. "

  # The ledger, in character. tools/tally.sh owns the number and this owns what
  # anybody is meant to think of it, which is deliberately not very much - GR12
  # is a difficulty setting and reading it out sternly does not improve it.
  if (!(p in lbend) || lbend[p] + 0 == 0)
    return s "The ledger is blank on them. Either they are careful, or the referee is slow."
  if (lbend[p] + 0 >= 3)
    return s "The ledger is not shy about them: " lbend[p] " bends in the open, every one of " \
             "them argued for in writing, which is the deal."
  return s "The ledger has a mark or two on it, which is exactly what a budget is for."
}

# The briefing a field-guide tile carries, cut to something that reads on a
# card. The guide writes for a panel with a whole screen behind it; three of
# these sit side by side here, so the sentence is taken to its first full stop
# and, failing that, to the last whole word inside the limit.
function briefly(s, lim,   i, cut) {
  if (length(s) <= lim) return s
  i = index(substr(s, 1, lim + 1), ". ")
  if (i > 24) return substr(s, 1, i)
  cut = substr(s, 1, lim)
  i = length(cut)
  while (i > 1 && substr(cut, i, 1) != " ") i--
  cut = substr(cut, 1, i - 1)
  sub(/[[:space:][:punct:]]+$/, "", cut)
  return cut "\342\200\246"
}

# The ledger. Read, never worked out: src/game/ledger.js is written by
# tools/tally.sh off the history and checked against it at commit time, and a
# book that formed its own opinion about somebody would be a second one. The
# receipts under it are this stream, which is where the reasons live.
#
# Lifted out of pilotpage() so it can be printed beside the bars rather than
# after the flights: the two are the same question - which part of the cabinet
# somebody stands in, and what the field charges them for standing there.
function ledgercel(f, p, cls,   i, v, t) {
  printf "<section class=\"cel bends%s\">\n", cls > f
  printf "<h2 class=\"tab\">%s the ledger</h2>\n", ico("scroll") > f
  if (p in lbend) {
    print "<ul class=\"stats\">" > f
    printf "%s", tile("scroll", lbend[p], lbend[p], "bend" plural(lbend[p] + 0) " in the open") > f
    printf "%s", tile("up", lclean[p], lclean[p], "clean since the last") > f
    if (llast[p] != "") printf "%s", tile("eye", "", esc(llast[p]), "the last one bent") > f
    print "</ul>" > f
    printf "<p class=\"gist\">Three clean landings ease it by one. Nobody edits " \
           "this number, including the pilot it is about and including when asked (GR12).</p>\n" > f
  }
  # Every version of theirs that had to write something down, linked to the
  # chapter where the reason is. This is the honest half: a page that printed
  # the count and hid the receipts would be worse than one that printed
  # neither.
  # Newest first, which is the order the log handed them over. A receipt on a
  # version reads as the sentence that version is known by; a receipt on a
  # mention reads as the subject line it landed under, because a mention has
  # no sentence of its own and never gets one.
  if (rcn[p] > 0) {
    print "<ul class=\"receipts\">" > f
    for (i = 1; i <= rcn[p]; i++) {
      v = RCV[p SUBSEP i] + 0
      t = (RCK[p SUBSEP i] == "V" ? shout(v) : RCS[p SUBSEP i])
      if (v >= 1)
        printf "<li><a href=\"v%d.html\"><b>v%d</b><span>%s</span><i>%s</i></a></li>\n", \
               v, v, esc(t), esc(RCW[p SUBSEP i]) > f
      else
        printf "<li><span class=\"norec\"><b>&mdash;</b><span>%s</span><i>%s</i></span></li>\n", \
               esc(t), esc(RCW[p SUBSEP i]) > f
    }
    print "</ul>" > f
  }
  print "</section>" > f
}

# ---- one page per pilot ----------------------------------------------------
# The book tells the story of the versions. This one tells the story of a
# person, out of exactly the same stream: what they landed, what they own, what
# they armed the room with, what they flew, and what the field charges them for
# all of it. Every answer on the page is already somewhere above; the page is
# only where they finally meet each other.
#
# Nothing here is a record anybody keeps up to date - a page that had to be
# maintained is wrong inside a week - and nothing here is a number this file
# worked out for itself where another tool already answers the question. The
# ledger is tools/tally.sh, the meter is tools/flights.sh, and both are read.
#
# A section with nothing to say is not written at all. Most of these pages are
# one book and a mention, and a page of empty headings teaches a reader to skim
# past the heading that mattered.
function pilotpage(p,   f, i, j, k, v, b, n, s, t, nb2, run, longest, longbook,
                   days, gl, ng, nf, ne, ncr, hits, kills, mmv, nmk, tot,
                   cnt, oth, e2, topmk, secmk, dist, nfl, bestrk,
                   bestwv, pcls, bcls, chips, ledger) {
  f = "docs/pilot-" slug(p) ".html"

  # The shelf this pilot holds, and the longest run on it - the one number a
  # roster row can never say, because a run is a fact about a shelf rather than
  # about a person.
  nb2 = 0; longest = 0; longbook = 0
  for (b = 1; b <= nb; b++) {
    if (BW[b] != p) continue
    nb2++
    run = BE[b] - BS[b] + 1
    if (run > longest) { longest = run; longbook = b }
  }

  # Everything the sections below print, counted once here at the top rather
  # than where each one happens to need it. The paragraph that opens the page
  # is a characterisation, and a characterisation has to know all of somebody
  # before it writes its first clause - what they keep moving, what they left
  # in the field, whether they have ever flown the thing they are building.
  # Each section still asks its own question; it just no longer has to count
  # to answer it.
  nmk = split(MARKS, mmv, " ")
  tot = 0; topmk = ""; secmk = ""; dist = 0
  for (k = 1; k <= nmk; k++) {
    if (!((p SUBSEP mmv[k]) in pmk)) continue
    dist++
    n = pmk[p SUBSEP mmv[k]]
    if (n > tot) { tot = n; secmk = topmk; topmk = mmv[k] }
    else if (secmk == "" || n > pmk[p SUBSEP secmk]) secmk = mmv[k]
  }

  # What is still in the cabinet with their name on it. Owned means the commit
  # that created the file was theirs, which is the one boundary git can prove -
  # and counted against the tree as it stands, so a file somebody has since
  # deleted is not still on anybody.
  nf = 0
  for (t in owner) if (owner[t] == p && (t in intree)) nf++

  # The half of somebody that is still being played tonight, sorted by the name
  # a player reads rather than by the path it lives at.
  ng = 0
  for (t in gname) if (owner[t] == p && (t in intree)) gl[++ng] = t
  for (i = 2; i <= ng; i++) {
    s = gl[i]; j = i - 1
    while (j >= 1 && gname[gl[j]] > gname[s]) { gl[j + 1] = gl[j]; j-- }
    gl[j + 1] = s
  }

  ne = 0
  for (i = 1; i <= an; i++) if (aby[i] == p) ne++

  # Their flights, and the best of them - which is the row with the lowest rank
  # on the board rather than the highest wave, because the board is the record
  # and it has already decided what best means.
  nfl = 0; bestrk = 0; bestwv = ""
  for (i = 1; i <= fn; i++) {
    if (fwho[i] != p) continue
    nfl++
    if (bestrk == 0 || frk[i] + 0 < bestrk) { bestrk = frk[i] + 0; bestwv = fwv[i] }
  }

  ncr = 0
  for (i = 1; i <= nr; i++) {
    if (roll[i] == p) continue
    if ((p SUBSEP roll[i]) in cross || (roll[i] SUBSEP p) in cross) ncr++
  }

  head(f, esc(p) " &mdash; HYPERCOLOR ASTEROIDS", "page")
  print "<main class=\"ch who\">" > f

  # ---- the splash. The face at the size it was painted, which is the one
  # thing every other page in this book has only ever shown at the size of a
  # thumbnail. A pilot with no face reads as a name, as everywhere else.
  print "<section class=\"cel splash whois\">" > f
  print "<span class=\"dots\" aria-hidden=\"true\"></span>" > f
  print "<div class=\"say\">" > f
  if (mug[p] != "")
    printf "<img class=\"portrait\" src=\"faces/%s\" alt=\"%s\" loading=\"lazy\" decoding=\"async\">", \
           mug[p], att(p) > f
  printf "<div class=\"nameplate\"><p class=\"kicker\">%s the pilot</p><h1 class=\"shout\">%s</h1></div>", \
         ico("bolt"), esc(p) > f
  print "</div>" > f
  printf "<p class=\"credits\"><span class=\"badge\"><b>%d</b><i>version%s</i></span>", \
         pilots[p], plural(pilots[p]) > f
  if (nb2 > 0) printf "<span class=\"ver\">%d book%s</span>", nb2, plural(nb2) > f
  printf "<span class=\"when\">%s &ndash; %s</span></p>", esc(pfirst[p]), esc(plast[p]) > f
  print "</section>" > f

  # ---- who this is. Not what they have: the tiles in the next cel already
  # count every one of those, and a paragraph that reads the same numbers back
  # in words is a second, slower table sitting where the portrait should be.
  # This says what kind of pilot the numbers add up to, and it is allowed an
  # opinion - every clause behind it is a fact somebody can check two cels
  # down, which is the only thing that makes an opinion worth printing.
  print "<section class=\"cel told\">" > f
  printf "<h2 class=\"tab\">%s who this is</h2>\n", ico("quote") > f
  printf "<p class=\"deed\">%s</p>\n", \
         whois(p, longest, longbook, topmk, secmk, dist, ng, ne, nfl, bestwv, ncr) > f
  chips = traits(p, longest, topmk, dist, ng, ne, nfl, bestwv, ncr)
  if (chips != "") printf "%s\n", chips > f
  print "</section>" > f

  # ---- the numbers. The same tiles a chapter uses, asked about a person.
  print "<section class=\"cel figures\">" > f
  printf "<h2 class=\"tab\">%s the numbers</h2>\n", ico("gauge") > f
  print "<ul class=\"stats\">" > f
  printf "%s", tile("medal", pilots[p], pilots[p], "version" plural(pilots[p]) " landed") > f
  printf "%s", tile("book", nb2, nb2, "book" plural(nb2) " held") > f
  if (longest > 0)
    printf "%s", tile("target", longest, longest, "chapter run, longest") > f
  if (interludes[p])
    printf "%s", tile("hourglass", interludes[p], interludes[p], "mention" plural(interludes[p])) > f
  days = int((plastat[p] - pfirstat[p]) / 86400)
  if (days > 0) printf "%s", tile("cal", days, days, "day" plural(days) " in the room") > f
  else          printf "%s", tile("cal", "", "one day", "first to last") > f
  if (nf) printf "%s", tile("core", nf, nf, "file" plural(nf) " theirs") > f
  print "</ul>" > f
  print "</section>" > f

  # ---- what they move, and what it has cost them, side by side. The two are
  # the same question asked twice: the bars say which part of the cabinet
  # somebody keeps standing in, and the ledger says what the field charged them
  # for standing there. They are the widths they are because the bars need a
  # bar worth of room and three tiles do not - and either one alone takes the
  # whole width, because half a row with nothing beside it is a gap.
  ledger = (p in lbend) || bent[p] || cheat[p] || rcn[p]
  pcls = (tot > 0 && ledger) ? " halfwide" : ""
  bcls = (tot > 0 && ledger) ? " halfnarrow" : ""
  if (tot > 0) {
    printf "<section class=\"cel fingerprint%s\">\n", pcls > f
    printf "<h2 class=\"tab\">%s what they move</h2>\n", ico("wrench") > f
    printf "<p class=\"gist\">Every commit of theirs, versions and mentions alike, in the " \
           "nine marks the book puts on a chapter. It is the one thing a count of " \
           "landings cannot say: which part of the cabinet somebody keeps standing in.</p>\n" > f
    print "<ul class=\"prints\">" > f
    for (k = 1; k <= nmk; k++) {
      if (!((p SUBSEP mmv[k]) in pmk)) continue
      n = pmk[p SUBSEP mmv[k]]
      printf "<li class=\"mk mk-%s\">%s<em>%s</em>" \
             "<span class=\"bar\"><i style=\"width:%d%%\"></i></span><b>%d</b></li>\n", \
             mmv[k], ico(markglyph(mmv[k])), marklabel(mmv[k]), int(100 * n / tot + 0.5), n > f
    }
    print "</ul>" > f
    print "</section>" > f
  }
  if (ledger) ledgercel(f, p, bcls)

  # ---- their shelf. The same books the cover opens, with only theirs on it,
  # which is the whole of what a pilot page is for: a run of chapters read
  # down in the order somebody flew them.
  if (nb2 > 0) {
    print "<section class=\"cel shelf-of\">" > f
    printf "<h2 class=\"tab\">%s their books</h2>\n", ico("book") > f
    print "<div class=\"shelf\">" > f
    for (b = nb; b >= 1; b--) {
      if (BW[b] != p) continue
      printf "<details class=\"book\"%s>\n", (b == longbook ? " open" : "") > f
      print "<summary>" > f
      printf "<span class=\"bk\"><b>%s</b><i>book</i></span>", roman(b) > f
      printf "<span class=\"bspan\">%s</span>", bspan(b) > f
      printf "<span class=\"bn\">%d chapter%s</span>", BE[b] - BS[b] + 1, plural(BE[b] - BS[b] + 1) > f
      printf "%s", markrow(BM[b], "tiny") > f
      print "</summary>" > f
      printf "<p class=\"gist\">%s</p>\n", gist(b) > f
      print "<ol class=\"contents\">" > f
      for (i = 1; i <= en; i++) {
        if (EB[i] != b) continue
        split(ENT[i], e2, SUBSEP)
        # A chapter in this book is theirs by definition; a mention shelved
        # beside it is only theirs if they wrote it.
        if (e2[1] != "V" && e2[6] != p) continue
        entry(f, e2)
      }
      print "</ol>" > f
      print "</details>" > f
    }
    print "</div>" > f
    print "</section>" > f
  }

  # ---- what is theirs, in the game rather than in the tree. A file count is
  # a fact about a repository; a guide tile is a thing a player meets on the
  # splash screen and then meets again in the field. This is the half of
  # somebody that is still out there being played tonight. Each card carries
  # the briefing the tile itself carries, cut short: the guide says it in full to somebody
  # about to press ENTER, and here it only has to say which of these a reader
  # already knows by sight.
  if (ng > 0) {
    print "<section class=\"cel theirs\">" > f
    printf "<h2 class=\"tab\">%s what a player meets</h2>\n", ico("panel") > f
    printf "<p class=\"gist\">%d thing%s in the field guide came out of a file %s created, " \
           "and every one of them is still in the cabinet tonight.</p>\n", \
           ng, plural(ng), esc(p) > f
    print "<ul class=\"tiles\">" > f
    for (i = 1; i <= ng; i++) {
      printf "<li><b>%s</b><span>%s</span>", \
             esc(gname[gl[i]]), esc(ggroup[gl[i]] != "" ? ggroup[gl[i]] : "unfiled") > f
      if (gdesc[gl[i]] != "") printf "<em>%s</em>", esc(briefly(gdesc[gl[i]], 100)) > f
      printf "<i>%s</i></li>\n", esc(gl[i]) > f
    }
    print "</ul>" > f
    print "</section>" > f
  }

  # ---- their ambush. GR11 is the one rule with no budget and no override, and
  # the shape of it is worth saying out loud on the page of the person it
  # belongs to: this file is theirs, nobody may touch it, and it will never
  # once fire at them. What it has actually done is off the filed tapes, which
  # is the only record of an event meeting a pilot.
  if (ne > 0) {
    print "<section class=\"cel ambush\">" > f
    printf "<h2 class=\"tab\">%s what they armed the room with</h2>\n", ico("eye") > f
    print "<ul class=\"traps\">" > f
    for (i = 1; i <= an; i++) {
      if (aby[i] != p) continue
      hits = (aid[i] in evfired) ? evfired[aid[i]] : 0
      kills = (aid[i] in evkill) ? evkill[aid[i]] : 0
      printf "<li><b>%s</b><span>%s</span>", esc(anm[i]), esc(abl[i]) > f
      if (hits)
        printf "<i>%d firing%s on the filed tapes, %s</i>", hits, plural(hits), \
               (kills ? kills " ship" plural(kills) " taken" : "not one ship taken") > f
      else
        printf "<i>no filed tape has met it yet</i>" > f
      print "</li>" > f
    }
    print "</ul>" > f
    # Who it is armed against is the roster minus one, and the one is the
    # author. Naming them is the point of the rule rather than a flourish.
    cnt = ""
    for (i = 1; i <= nr; i++) {
      if (roll[i] == p) continue
      cnt = cnt (cnt == "" ? "" : ", ") plink(roll[i])
    }
    if (cnt != "")
      printf "<p class=\"gist\">Armed against %s, and never once against %s. " \
             "That is GR11, which has no override on it.</p>\n", cnt, esc(p) > f
    print "</section>" > f
  }

  # ---- their flights. The board is the record and tools/flights.sh is the
  # meter; this prints the first and reads the second. A pilot who has never
  # put a tape up gets neither, and says so.
  if (nfl > 0 || (p in msince)) {
    print "<section class=\"cel flew\">" > f
    printf "<h2 class=\"tab\">%s what they flew</h2>\n", ico("ship") > f
    if (nfl > 0) {
      print "<table class=\"board\"><thead><tr><th>#</th><th>score</th><th>wave</th>" > f
      print "<th>time</th><th>aim</th><th>the flight in one line</th></tr></thead><tbody>" > f
      for (i = 1; i <= fn; i++) {
        if (fwho[i] != p) continue
        printf "<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n", \
               esc(frk[i]), esc(fsc[i]), esc(fwv[i]), esc(ftm[i]), esc(fac[i]), esc(fsd[i]) > f
      }
      print "</tbody></table>" > f
    } else
      printf "<p class=\"gist\">Nothing of theirs is on the board. A tape comes off " \
             "the game-over screen and nowhere else, so this fills in the evening " \
             "they fly one.</p>\n" > f
    if (p in msince) {
      printf "<p class=\"meter\">The flight meter: <b>%s</b> landing%s used since they last flew", \
             msince[p], plural(msince[p] + 0) > f
      if (mflown[p] != "") printf ", and that flight was %s", esc(mflown[p]) > f
      print ". One sealed tape covers three (GR14).</p>" > f
    }
    print "</section>" > f
  }

  # ---- and the half of GR8 that has nowhere else to appear. Every other
  # section on this page is about what somebody has of their own; this is a
  # cabinet several people share, and a version that landed inside somebody
  # else work is the only thing here that is about the room rather than the
  # person. Named as people, because that is what they are.
  if (ncr > 0) {
    print "<section class=\"cel others\">" > f
    printf "<h2 class=\"tab\">%s what it does to the others</h2>\n", ico("target") > f
    print "<ul class=\"visits\">" > f
    for (i = 1; i <= nr; i++) {
      oth = roll[i]
      if (oth == p) continue
      n = ((p SUBSEP oth) in cross) ? cross[p SUBSEP oth] : 0
      k = ((oth SUBSEP p) in cross) ? cross[oth SUBSEP p] : 0
      if (!n && !k) continue
      printf "<li>%s<span>", plink(oth) > f
      if (n) printf "landed in their work on %d version%s", n, plural(n) > f
      if (n && k) printf " &middot; " > f
      if (k) printf "they landed in this one on %d version%s", k, plural(k) > f
      print "</span></li>" > f
    }
    print "</ul>" > f
    printf "<p class=\"gist\">Tuning somebody else&rsquo;s numbers is allowed and costs " \
           "a few lines; gutting their work is GR4 and costs an override. Which of the " \
           "two happened is in the chapters, not in this count.</p>\n" > f
    print "</section>" > f
  }

  # ---- in their own words. A run of Chronicle lines is a portrait nobody sat
  # for: it is the same person writing down what they did, once a version, for
  # somebody who will read it a year later.
  n = 0
  for (v = total; v >= 1; v--) {
    if (VW[v] != p || VL[v] == "") continue
    if (n++ == 0) {
      print "<section class=\"cel words\">" > f
      printf "<h2 class=\"tab\">%s in their own words</h2>\n", ico("note") > f
      print "<ul class=\"quotes\">" > f
    }
    if (n > 6) break
    printf "<li><a href=\"v%d.html\"><b>v%d</b></a><q>%s</q></li>\n", v, v, esc(VL[v]) > f
  }
  if (n) {
    print "</ul>" > f
    if (n > 6) printf "<p class=\"gist\">The six most recent of %d. The rest are in the books above.</p>\n", n > f
    print "</section>" > f
  }

  print "</main>" > f

  # The dock, and on a pilot page it is a shelf of pilots rather than of books.
  # Same furniture, same place at the foot of the window, one press to anybody
  # else the cabinet has heard of.
  print "<nav class=\"dock whodock\" aria-label=\"the roster\">" > f
  printf "<a class=\"up\" href=\"index.html\" title=\"the contents\">%s<i>all</i></a>\n", ico("grid") > f
  print "<div class=\"rail\">" > f
  for (i = 1; i <= nr; i++) {
    printf "<a class=\"spine%s\" href=\"pilot-%s.html\"%s>", \
           (roll[i] == p ? " here" : ""), slug(roll[i]), \
           (roll[i] == p ? " aria-current=\"page\"" : "") > f
    if (mug[roll[i]] != "")
      printf "<img class=\"face\" src=\"faces/%s\" alt=\"\" loading=\"lazy\" decoding=\"async\">", mug[roll[i]] > f
    printf "<span class=\"nm\">%s</span>", esc(roll[i]) > f
    printf "<span class=\"sp\"><i>%d</i></span></a>\n", pilots[roll[i]] > f
  }
  print "</div>" > f
  print "</nav>" > f
  print "</body></html>" > f
  close(f)
}

# Same tokens, same CRT as the game itself, so the book follows along on its own
# the day somebody changes the spectrum. Every page in here wears them.
function head(f, ttl, cls,   b) {
  print "<!doctype html>" > f
  print "<html lang=\"en\"><head><meta charset=\"utf-8\">" > f
  print "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">" > f
  print "<title>" ttl "</title>" > f
  # the signet, when the build had one to read off the logo (see the favicon
  # block above the awk)
  if (fav != "") print "<link rel=\"icon\" href=\"favicon.svg\" type=\"image/svg+xml\">" > f
  print "<link rel=\"stylesheet\" href=\"../styles/tokens.css\">" > f
  print "<link rel=\"stylesheet\" href=\"../styles/crt.css\">" > f
  print "<link rel=\"stylesheet\" href=\"chronicle.css\">" > f
  # The room it is read in, off until somebody asks for it. Deferred, and it
  # builds its own switch, so a page that never loads it is a page with no
  # promise of sound on it.
  print "<script src=\"chronicle-song.js\" defer></script>" > f
  b = "</head><body"
  if (cls != "") b = b " class=\"" cls "\""
  print b ">" > f
  print "<div class=\"crt vignette\"></div>" > f
  print "<div class=\"crt scanlines\"></div>" > f
  print "<div class=\"crt roll\"></div>" > f
}
END {
  # --audit and --book-silence have already said everything they were asked
  # for, a commit at a time. Nothing below them opens a file that is not a page
  # of the book.
  if (auditonly || silenceonly) exit 0

  # The roster counts versions, not commits. A pilot who has only ever changed
  # the rules has flown none, and the table says so, which is fair and which is
  # also funny.
  for (p in interludes) if (!(p in pilots)) pilots[p] = 0
  roster = ""
  nr = roster_order(pilots, roll)
  for (ri = 1; ri <= nr; ri++) {
    p = roll[ri]
    # One column, two kinds of bending: what somebody wrote down, and what the
    # book had to work out for itself.
    cell = ""
    if (bent[p])  cell = bent[p] " override" plural(bent[p])
    if (cheat[p]) cell = cell (cell ? ", " : "") cheat[p] " unrecorded"
    if (cell == "") cell = "&mdash;"
    roster = roster sprintf("<tr><td>%s</td><td>%d</td><td>%s</td><td>%s%s%s</td></tr>\n", \
             plink(p, "pilot"), pilots[p], \
             (peak[p] ? sprintf("<a href=\"v%d.html\">v%d</a>", peak[p], peak[p]) : "&mdash;"), \
             (cheat[p] ? "<b>" : ""), cell, (cheat[p] ? "</b>" : ""))
  }

  # The rail that sits in the dock at the foot of every chapter: the whole
  # history at a glance, oldest on the left, each version wearing the plate its
  # own page opens with - so a reader recognises a chapter they have already
  # read before they have read its number. Both kinds of trouble are marked, so
  # they can see where the book gets loud before they get there. A version with
  # no plate keeps the halftone the css gives it and reads as a panel somebody
  # meant, the same way its splash does.
  #
  # One copy, in docs/rail.js, rather than a copy baked into every page: a new
  # version used to edit every chapter ever landed just to add its own tick,
  # and now it is one line here. Each page carries an empty dock with its own
  # number on it, and this file builds the furniture - back, the rail, next.
  for (v = 1; v <= total; v++) {
    nth[VW[v]]++
    NT[v] = nth[VW[v]]
  }

  # ---- the books -----------------------------------------------------------
  # A book is a run of chapters one pilot flew with nobody else landing in
  # between, and the gap is the whole point of it: fly three, hand the cabinet
  # over, take it back and fly three more, and that is two books rather than
  # one, because a turn that belonged to somebody else happened in the middle
  # and a shelf that hides it tells the wrong story. Numbered oldest first, the
  # same way the versions are, so book I contains v1 in every clone forever.
  nb = 0
  for (v = 1; v <= total; v++) {
    if (v == 1 || VW[v] != VW[v-1]) { nb++; BS[nb] = v; BW[nb] = VW[v] }
    BE[nb] = v; BK[v] = nb
    BF[nb] += VF[v]; BI[nb] += VI[v]; BJ[nb] += VJ[v]
    if (VO[v] != "") BO[nb]++
    if (VU[v] != "") BX[nb]++
    nm = split(VM[v], mm, " ")
    for (k = 1; k <= nm; k++) bmk[nb SUBSEP mm[k]] = 1
  }
  nm = split(MARKS, mm, " ")
  for (bi = 1; bi <= nb; bi++) {
    BM[bi] = ""
    for (k = 1; k <= nm; k++)
      if ((bi SUBSEP mm[k]) in bmk) BM[bi] = BM[bi] (BM[bi] == "" ? "" : " ") mm[k]
  }
  # Which shelf every entry on the cover belongs to. A version is in its own
  # book; an interlude is in whichever book was being written while it
  # happened, which is the book of the version that was on the cabinet at the
  # time. Anything older than v1 predates every book and goes on the first one.
  for (i = 1; i <= en; i++) {
    split(ENT[i], e, SUBSEP)
    if (e[1] == "V") EB[i] = BK[e[2] + 0]
    else {
      EB[i] = (e[4] + 0 >= 1 ? BK[e[4] + 0] : (nb ? 1 : 0))
      if (EB[i]) BN[EB[i]]++
    }
  }

  rj = "docs/rail.js"
  print "// Generated by tools/chronicle.sh - the dock at the foot of every" > rj
  print "// chapter: back and next the size of a thing you press, and between" > rj
  print "// them the shelf, every book there has ever been. A book is a run of" > rj
  print "// chapters one pilot flew without anybody else landing in between;" > rj
  print "// press one and its chapters stack up above the shelf, and it takes a" > rj
  print "// second press - on a chapter - to leave the page you are on. One copy" > rj
  print "// for the whole book rather than one baked into each page, so a new" > rj
  print "// version is a new line here instead of an edit to every chapter ever" > rj
  print "// landed. Do not edit: every rebuild writes it fresh." > rj
  print "(function () {" > rj
  print "  \"use strict\"" > rj
  print "  // one line per version: [plate, the shout, \"bent\"/\"off\"/\"\", its book, its marks]" > rj
  print "  var T = [" > rj
  for (v = 1; v <= total; v++)
    printf "    [\"%s\", \"%s\", \"%s\", %d, \"%s\"],\n", js(VP[v]), js(shout(v)), \
           (VU[v] != "" ? "off" : (VO[v] != "" ? "bent" : "")), BK[v], js(markrow(VM[v], "tiny")) > rj
  print "  ]" > rj
  # A book wears every mark its chapters wear, once each - which is the one
  # thing a spine can say about a run of six chapters in the width of a thumb.
  print "  // one line per book: [numeral, the pilot, their face, first, last, its marks, their page]" > rj
  print "  var B = [" > rj
  for (bi = 1; bi <= nb; bi++)
    printf "    [\"%s\", \"%s\", \"%s\", %d, %d, \"%s\", \"%s\"],\n", roman(bi), js(BW[bi]), js(mug[BW[bi]]), \
           BS[bi], BE[bi], js(markrow(BM[bi], "tiny")), js("pilot-" slug(BW[bi]) ".html") > rj
  print "  ]" > rj
  print "  var dock = document.querySelector(\"nav.dock[data-here]\")" > rj
  print "  if (!dock || !T.length) return" > rj
  print "  var here = +dock.getAttribute(\"data-here\")" > rj
  print "  var doc = document.documentElement" > rj
  print "  function shout(v) { return \"v\" + v + \" \\u00b7 \" + T[v - 1][1] }" > rj
  print "  function span(d) { return d[3] === d[4] ? \"v\" + d[3] : \"v\" + d[3] + \"\\u2013v\" + d[4] }" > rj
  print "  function turn(v, dir, edge) {" > rj
  print "    var live = v >= 1 && v <= T.length" > rj
  print "    var e = document.createElement(live ? \"a\" : \"span\")" > rj
  print "    e.className = \"turn \" + dir + (live ? \"\" : \" none\")" > rj
  print "    if (live) { e.href = \"v\" + v + \".html\"; e.rel = dir; e.title = shout(v) }" > rj
  print "    var arw = \"<span class=\\\"arw\\\">\" + (dir === \"prev\" ? \"\\u25c0\" : \"\\u25b6\") + \"</span>\"" > rj
  print "    var lab = \"<span class=\\\"lab\\\"><i>\" + (dir === \"prev\" ? \"back\" : \"next\") + \"</i><b>\" + (live ? \"v\" + v : edge) + \"</b></span>\"" > rj
  print "    e.innerHTML = dir === \"prev\" ? arw + lab : lab + arw" > rj
  print "    return e" > rj
  print "  }" > rj
  print "  dock.appendChild(turn(here - 1, \"prev\", \"the first\"))" > rj
  print "  var up = document.createElement(\"a\")" > rj
  print "  up.className = \"up\"" > rj
  print "  up.href = \"index.html\"" > rj
  print "  up.title = \"the contents\"" > rj
  printf "  up.innerHTML = \"%s<i>all</i>\"\n", js(ico("grid")) > rj
  print "  dock.appendChild(up)" > rj
  # The shelf. One spine per book, oldest on the left, the way the rail of
  # ticks it replaced ran - and the book this chapter is in is marked, so a
  # reader knows where they are standing before they press anything.
  print "  var rail = document.createElement(\"div\")" > rj
  print "  rail.className = \"rail\"" > rj
  print "  for (var b = 1; b <= B.length; b++) rail.appendChild(spine(b))" > rj
  print "  dock.appendChild(rail)" > rj
  print "  dock.appendChild(turn(here + 1, \"next\", \"on the cabinet\"))" > rj
  print "  var tray = document.createElement(\"div\")" > rj
  print "  tray.className = \"tray\"" > rj
  print "  tray.id = \"tray\"" > rj
  print "  tray.hidden = true" > rj
  print "  dock.appendChild(tray)" > rj
  print "  var open = 0" > rj
  print "  function spine(b) {" > rj
  print "    var d = B[b - 1]" > rj
  print "    var e = document.createElement(\"button\")" > rj
  print "    e.type = \"button\"" > rj
  print "    e.className = \"spine\" + (b === T[here - 1][3] ? \" here\" : \"\")" > rj
  print "    e.setAttribute(\"aria-expanded\", \"false\")" > rj
  print "    e.setAttribute(\"aria-controls\", \"tray\")" > rj
  print "    e.title = \"book \" + d[0] + \" \\u00b7 \" + d[1] + \" \\u00b7 \" + span(d)" > rj
  print "    if (d[2]) {" > rj
  print "      var img = e.appendChild(document.createElement(\"img\"))" > rj
  print "      img.className = \"face\"" > rj
  print "      img.src = \"faces/\" + d[2]" > rj
  print "      img.alt = \"\"" > rj
  print "      img.loading = \"lazy\"" > rj
  print "      img.decoding = \"async\"" > rj
  print "    }" > rj
  print "    var t = e.appendChild(document.createElement(\"span\"))" > rj
  print "    t.className = \"sp\"" > rj
  print "    t.appendChild(document.createElement(\"b\")).textContent = d[0]" > rj
  print "    t.appendChild(document.createElement(\"i\")).textContent = span(d)" > rj
  print "    var w = e.appendChild(document.createElement(\"span\"))" > rj
  print "    w.className = \"nm\"" > rj
  print "    w.textContent = d[1]" > rj
  print "    if (d[5]) e.insertAdjacentHTML(\"beforeend\", d[5])" > rj
  print "    e.addEventListener(\"click\", function () { toggle(b) })" > rj
  print "    return e" > rj
  print "  }" > rj
  # A chapter, stacked. The same plate its own page opens with, so a reader
  # recognises one they have already read before they have read its number.
  print "  function leaf(v) {" > rj
  print "    var t = T[v - 1]" > rj
  print "    var a = document.createElement(\"a\")" > rj
  print "    a.className = \"leaf\" + (t[2] ? \" \" + t[2] : \"\") + (v === here ? \" here\" : \"\")" > rj
  print "    a.href = \"v\" + v + \".html\"" > rj
  # The sentence is cut off by whatever room the marks left it, and on a phone
  # that is most of it, so the whole of it stays reachable.
  print "    a.title = shout(v)" > rj
  print "    if (v === here) a.setAttribute(\"aria-current\", \"page\")" > rj
  print "    var th = a.appendChild(document.createElement(\"span\"))" > rj
  print "    th.className = \"thumb\"" > rj
  print "    if (t[0]) {" > rj
  print "      var img = th.appendChild(document.createElement(\"img\"))" > rj
  print "      img.src = \"art/\" + t[0]" > rj
  print "      img.alt = \"\"" > rj
  print "      img.loading = \"lazy\"" > rj
  print "      img.decoding = \"async\"" > rj
  print "    }" > rj
  print "    a.appendChild(document.createElement(\"b\")).textContent = \"v\" + v" > rj
  print "    var s = a.appendChild(document.createElement(\"span\"))" > rj
  print "    s.className = \"line\"" > rj
  print "    s.textContent = t[1]" > rj
  print "    if (t[4]) a.insertAdjacentHTML(\"beforeend\", t[4])" > rj
  print "    return a" > rj
  print "  }" > rj
  print "  function toggle(b) {" > rj
  print "    if (open === b) { shut(); return }" > rj
  print "    var d = B[b - 1]" > rj
  print "    open = b" > rj
  print "    tray.textContent = \"\"" > rj
  print "    var h = tray.appendChild(document.createElement(\"p\"))" > rj
  print "    h.className = \"tray-head\"" > rj
  print "    h.appendChild(document.createElement(\"b\")).textContent = \"BOOK \" + d[0]" > rj
  # Whoever flew this book, and the way into the rest of what they have done.
  print "    var wh = h.appendChild(document.createElement(\"a\"))" > rj
  print "    wh.className = \"pl\"" > rj
  print "    wh.href = d[6]" > rj
  print "    wh.textContent = d[1]" > rj
  print "    h.appendChild(document.createElement(\"i\")).textContent = span(d)" > rj
  print "    var stack = tray.appendChild(document.createElement(\"div\"))" > rj
  print "    stack.className = \"stack\"" > rj
  print "    for (var v = d[3]; v <= d[4]; v++) stack.appendChild(leaf(v))" > rj
  print "    tray.hidden = false" > rj
  print "    doc.classList.add(\"tray-open\")" > rj
  print "    mark()" > rj
  print "    var now = stack.querySelector(\".here\") || stack.firstChild" > rj
  print "    if (now) now.focus({ preventScroll: true })" > rj
  print "  }" > rj
  print "  function shut() {" > rj
  print "    if (!open) return" > rj
  print "    var was = rail.children[open - 1]" > rj
  print "    open = 0" > rj
  print "    tray.hidden = true" > rj
  print "    tray.textContent = \"\"" > rj
  print "    doc.classList.remove(\"tray-open\")" > rj
  print "    mark()" > rj
  print "    if (was) was.focus({ preventScroll: true })" > rj
  print "  }" > rj
  print "  function mark() {" > rj
  print "    for (var i = 0; i < rail.children.length; i++)" > rj
  print "      rail.children[i].setAttribute(\"aria-expanded\", i + 1 === open ? \"true\" : \"false\")" > rj
  print "  }" > rj
  # Escape puts the tray away rather than leaving the chapter, and a click
  # anywhere that is not the dock does the same. The page script defers to
  # this while the tray is up, the same way it defers to the plate.
  print "  addEventListener(\"keydown\", function (e) {" > rj
  print "    if (open && e.key === \"Escape\") { e.stopPropagation(); shut() }" > rj
  print "  })" > rj
  print "  addEventListener(\"click\", function (e) {" > rj
  print "    if (open && !dock.contains(e.target)) shut()" > rj
  print "  })" > rj
  # The shelf opens on the book you are reading rather than on the first one
  # ever written. This used to sit in every page and rode here with the rail.
  print "  var now = rail.querySelector(\".here\")" > rj
  print "  if (now) rail.scrollLeft = now.offsetLeft - (rail.clientWidth - now.offsetWidth) / 2" > rj
  print "})()" > rj
  close(rj)

  # ---- the cover -----------------------------------------------------------
  cover = "docs/index.html"
  head(cover, "HYPERCOLOR ASTEROIDS &mdash; the chronicle", "")
  print "<main>" > cover
  print "<h1>THE CHRONICLE</h1>" > cover
  print "<p class=\"sub\">Being a true and complete account of HYPERCOLOR ASTEROIDS," > cover
  print "in " total " version" (total == 1 ? "" : "s") ", as told by the pilots who flew it." > cover
  print "A version is a commit that changed the game and it gets a page to itself;" > cover
  print "everything else that happened is noted in passing, including every rule" > cover
  print "anybody bent &mdash; whether or not they were the one who wrote it down.</p>" > cover
  print "<p class=\"prompt\"><a href=\"../index.html\">&#9654; PLAY THE CURRENT BUILD</a>" > cover
  if (total > 0)
    print "<a class=\"read\" href=\"v" total ".html\">&#9654; READ THE LATEST CHAPTER</a>" > cover
  print "</p>" > cover
  print "<section class=\"panel roster\">" > cover
  print "<h2>THE PILOTS</h2>" > cover
  print "<table><thead><tr><th>pilot</th><th>versions</th><th>latest</th><th>rules bent</th></tr></thead><tbody>" > cover
  printf "%s", roster > cover
  print "</tbody></table>" > cover
  print "</section>" > cover
  print "<h2 class=\"heading\">THE BOOKS</h2>" > cover
  print "<p class=\"shelfnote\">A book is a run of chapters one pilot flew with" > cover
  print "nobody else landing in between. Hand the cabinet over and take it back" > cover
  print "later and that is two books, not one &mdash; somebody else&rsquo;s turn" > cover
  print "happened in the middle. Open one and read down it; the marks say which" > cover
  print "parts of the cabinet it moved.</p>" > cover
  if (nb == 0) {
    # Nothing has been flown yet, so there is no shelf - only whatever happened
    # before there was a game to change, in the order it happened.
    print "<ol class=\"contents\">" > cover
    for (i = 1; i <= en; i++) { split(ENT[i], e, SUBSEP); entry(cover, e) }
    print "</ol>" > cover
  } else {
    print "<div class=\"shelf\">" > cover
    for (bi = nb; bi >= 1; bi--) {
      # The book on the cabinet is the one a reader came for, so it is the one
      # that is already open. Everything under it is a shelf, and a shelf is
      # something you choose to take a book off.
      printf "<details class=\"book\"%s>\n", (bi == nb ? " open" : "") > cover
      print "<summary>" > cover
      printf "<span class=\"bk\"><b>%s</b><i>book</i></span>", roman(bi) > cover
      printf "%s", plink(BW[bi], "by") > cover
      printf "<span class=\"bspan\">%s</span>", bspan(bi) > cover
      printf "<span class=\"bn\">%d chapter%s</span>", BE[bi] - BS[bi] + 1, plural(BE[bi] - BS[bi] + 1) > cover
      printf "%s", markrow(BM[bi], "tiny") > cover
      print "</summary>" > cover
      printf "<p class=\"gist\">%s</p>\n", gist(bi) > cover
      print "<ol class=\"contents\">" > cover
      for (i = 1; i <= en; i++) {
        if (EB[i] != bi) continue
        split(ENT[i], e, SUBSEP)
        entry(cover, e)
      }
      print "</ol>" > cover
      print "</details>" > cover
    }
    print "</div>" > cover
  }
  print "</main>" > cover
  print "</body></html>" > cover
  close(cover)

  # ---- one page per version ------------------------------------------------
  # A chapter is a page of cels rather than one screenful: the tagline as a
  # splash with the plate behind it, the narration next to the numbers, the
  # drawn commit under both, and a cel apiece for anything the book had to
  # write down. Nothing here is wider than a comfortable line of prose, which
  # is why there are several blocks instead of one - and the next chapter is
  # still one arrow key away.
  for (v = 1; v <= total; v++) {
    f = "docs/v" v ".html"
    head(f, "v" v " &mdash; HYPERCOLOR ASTEROIDS", "page")
    # Three facts the layout needs before it starts: whether the book had to
    # write anything down, whether anything happened alongside, and whether so
    # much happened alongside that it has outgrown the margin. Any of them
    # missing and its neighbour takes the room instead of leaving a hole.
    kept = (VU[v] != "" || VO[v] != "" || VR[v] != "" || VB[v] != "")
    printf "<main class=\"ch%s%s%s\">\n", (kept ? " has-record" : ""), \
           ((v in IB) ? " has-aside" : ""), (IBN[v] >= 3 ? " long-aside" : "") > f

    # The splash. One version is one sentence, and this is it, at the size that
    # sentence deserves - with the plate behind it if this chapter has one, and
    # a field of halftone dots if it does not. Nothing below changes either way.
    # The credits ride on it rather than on a bar of their own: a chapter opens
    # on a picture, and who flew it and when belongs in the corner of that
    # picture the way a comic signs its first panel.
    printf "<section class=\"cel splash%s\">", (VP[v] != "" ? " plated" : "") > f
    if (VP[v] != "")
      printf "<img class=\"plate-img\" src=\"art/%s\" alt=\"%s\" loading=\"lazy\" decoding=\"async\">", \
             VP[v], att(VQ[v] != "" ? VQ[v] : shout(v)) > f
    print "<span class=\"dots\" aria-hidden=\"true\"></span>" > f
    # The marks, right under the sentence, because which part of the cabinet a
    # version moved is the second thing a reader wants and the sentence is the
    # first. Labelled here and icon-only in a list: this is the one place a
    # reader gets taught what the little pictures mean.
    printf "<div class=\"say\"><p class=\"kicker\">%s what changed</p><h1 class=\"shout\">%s</h1>%s</div>", \
           ico("bolt"), esc(shout(v)), markrow(VM[v], "big") > f
    printf "<p class=\"credits\"><span class=\"badge\"><b>%s</b><i>chapter</i></span>", roman(v) > f
    printf "<span class=\"ver\">v%s</span>", v > f
    printf "%s<span class=\"when\">%s &middot; %s</span></p>", \
           plink(VW[v], "who"), esc(VN[v]), VC[v] > f
    if (VP[v] != "")
      printf "<a class=\"plate-full\" href=\"art/%s\">%s painted for this chapter</a>", VP[v], ico("frame") > f
    print "</section>" > f

    print "<section class=\"cel told\">" > f
    printf "<h2 class=\"tab\">%s what happened</h2>\n", ico("quote") > f
    if (VL[v] == "")
      printf "<p class=\"deed untold\">Nobody wrote this one down. The flight recorder kept the subject line: &ldquo;%s&rdquo;</p>\n", \
             esc(VS[v]) > f
    else {
      printf "<p class=\"deed\">%s</p>\n", esc(VL[v]) > f
      if (VL[v] != VS[v]) printf "<p class=\"subj\">landed as &ldquo;%s&rdquo;</p>\n", esc(VS[v]) > f
    }
    print "</section>" > f

    print "<section class=\"cel figures\">" > f
    printf "<h2 class=\"tab\">%s the numbers</h2>\n", ico("gauge") > f
    print "<ul class=\"stats\">" > f
    printf "%s", tile("target", VF[v], VF[v], "sector" plural(VF[v]) " touched") > f
    printf "%s", tile("up", VI[v], VI[v], "line" plural(VI[v]) " aboard") > f
    printf "%s", tile("down", VJ[v], VJ[v], "jettisoned") > f
    printf "%s", tile("clock", "", VC[v], "on the clock") > f
    if (v > 1) {
      gap = int((VA[v] - VA[v-1]) / 86400)
      printf "%s", tile("cal", gap, gap, "day" plural(gap) " after v" (v - 1)) > f
    } else
      printf "%s", tile("cal", "", "first", "coin in the slot") > f
    printf "%s", tile("medal", "", ord(NT[v]), "version by " esc(VW[v])) > f
    print "</ul>" > f
    print "</section>" > f

    print "<figure class=\"cel frame\">" > f
    printf "<h2 class=\"tab\">%s the commit, drawn</h2>\n", ico("ship") > f
    printf "%s<figcaption>%s</figcaption>\n", picture(v), esc(caption(v)) > f
    print "</figure>" > f

    # The margin, beside the drawn field: everything that happened around this
    # version rather than in it. A chapter with a quiet week either side has no
    # margin at all, and the field takes the whole width instead.
    if (kept || (v in IB)) print "<div class=\"margin\">" > f

    # The three things a chapter cannot keep quiet, each in a cel of its own
    # with the rule it bent in letters you can read from the doorway. The
    # referee-off one comes first, because it decides how much of the rest a
    # reader should believe. Assembled, not copied, so it is escaped already.
    if (kept) {
      print "<section class=\"record\">" > f
      if (VU[v] != "") {
        printf "<article class=\"cel loud off\"><h2 class=\"tab\">%s the referee never saw this</h2>", ico("eye") > f
        printf "<p class=\"klaxon\">OFF</p><p class=\"reason\">%s</p></article>\n", VU[v] > f
      }
      if (VO[v] != "") {
        nov = split(VO[v], ovs, " // ")
        for (k = 1; k <= nov; k++) {
          printf "<article class=\"cel loud over\"><h2 class=\"tab\">%s override</h2>", ico("bolt") > f
          printf "<p class=\"klaxon\">%s</p><p class=\"reason\">%s</p>", esc(grtag(ovs[k])), esc(grwhy(ovs[k])) > f
          printf "<p class=\"byline\">spent by %s, in writing, for good</p></article>\n", esc(VW[v]) > f
        }
      }
      if (VR[v] != "") {
        printf "<article class=\"cel loud law\"><h2 class=\"tab\">%s the rules themselves</h2>", ico("scroll") > f
        printf "<p class=\"klaxon\">AMENDED</p><p class=\"reason\">%s</p></article>\n", esc(VR[v]) > f
      }
      if (VB[v] != "") {
        printf "<article class=\"cel loud over\"><h2 class=\"tab\">%s the table spoke</h2>", ico("eye") > f
        printf "<p class=\"klaxon\">GR8</p><p class=\"reason\">%s</p>", esc(VB[v]) > f
        printf "<p class=\"byline\">a breach called by the table, on the pilot it names</p></article>\n" > f
      }
      print "</section>" > f
    }

    if (v in IB)
      printf "<section class=\"cel meanwhile\"><h2 class=\"tab\">%s meanwhile</h2>\n%s</section>\n", \
             ico("hourglass"), IB[v] > f
    if (kept || (v in IB)) print "</div>" > f

    # The one line that stays literal: it is meant to be pasted into a terminal.
    printf "<p class=\"cel play\">%s Drop a coin in this one: <code>git checkout %s</code></p>\n", \
           ico("coin"), substr(VH[v], 1, 8) > f
    print "</main>" > f
    # The dock. Everything a reader might want next, parked at the foot of the
    # window rather than at the foot of the page: somebody who decides halfway
    # down that they have had enough of this chapter should not have to scroll
    # to the end to say so. The furniture itself - back and next the size of a
    # thing you press, and between them every chapter there has ever been - is
    # built by docs/rail.js, one copy for the whole book, so this page only
    # says which chapter it is. It used to be baked in right here, and every
    # landing edited every page ever written just to add its own tick.
    printf "<nav class=\"dock\" data-here=\"%d\" aria-label=\"turn the page\"></nav>\n", v > f
    print "<script src=\"rail.js\" defer></script>" > f
    # The arrow keys, because a book of pages that only turn by mouse is a
    # worse book, and because this cabinet is played on a keyboard. And the
    # cels, which land one at a time as you scroll onto them and count their
    # numbers up when they do. Everything the script does is decoration: with
    # it switched off the page is the same page, already right, just still.
    print "<script>" > f
    # A page turn is the wrong thing to do while the plate is up in front of
    # the page, so while it is up the keyboard belongs to it and Escape puts
    # it away rather than leaving the chapter.
    print "addEventListener(\"keydown\", function (e) {" > f
    print "  if (document.documentElement.classList.contains(\"lit-open\")) {" > f
    print "    if (e.key === \"Escape\") drop()" > f
    print "    return" > f
    print "  }" > f
    # A book is open in the dock, so the keyboard belongs to it: rail.js takes
    # Escape and puts it away. Same arrangement as the plate above, and for the
    # same reason - a page turning under something the reader just opened is a
    # surprise nobody asked for.
    print "  if (document.documentElement.classList.contains(\"tray-open\")) return" > f
    print "  var to = { ArrowLeft: \".prev\", ArrowRight: \".next\", Escape: \".up\" }[e.key]" > f
    print "  var a = to ? document.querySelector(\".dock \" + to) : null" > f
    print "  if (a && a.href) location.href = a.href" > f
    print "})" > f
    print "document.documentElement.className = \"js\"" > f
    print "var cels = document.querySelectorAll(\".cel\")" > f
    print "function land(cel) {" > f
    print "  cel.classList.add(\"in\")" > f
    print "  var ns = cel.querySelectorAll(\"b[data-n]\"), i" > f
    print "  for (i = 0; i < ns.length; i++) count(ns[i])" > f
    print "}" > f
    print "function count(el) {" > f
    print "  var to = +el.getAttribute(\"data-n\"), t0 = 0" > f
    print "  if (!(to > 1)) return" > f
    print "  requestAnimationFrame(function step(t) {" > f
    print "    if (!t0) t0 = t" > f
    print "    var k = Math.min(1, (t - t0) / 700)" > f
    print "    el.textContent = Math.round(to * (1 - Math.pow(1 - k, 3)))" > f
    print "    if (k < 1) requestAnimationFrame(step)" > f
    print "  })" > f
    print "}" > f
    print "if (matchMedia(\"(prefers-reduced-motion: reduce)\").matches || !window.IntersectionObserver) {" > f
    print "  for (var i = 0; i < cels.length; i++) cels[i].classList.add(\"in\")" > f
    print "} else {" > f
    print "  var io = new IntersectionObserver(function (seen) {" > f
    print "    for (var i = 0; i < seen.length; i++) if (seen[i].isIntersecting) {" > f
    print "      land(seen[i].target)" > f
    print "      io.unobserve(seen[i].target)" > f
    print "    }" > f
    print "  }, { rootMargin: \"0px 0px -6% 0px\" })" > f
    print "  for (var j = 0; j < cels.length; j++) io.observe(cels[j])" > f
    print "}" > f
    # The plate in full. The splash already has the picture in it, cropped to
    # the panel by object-fit, so opening it is not a new picture arriving -
    # it is the same one leaving the panel. Everything below is the arithmetic
    # for that: where the crop sits on the screen, and how much bigger the
    # whole plate is than the part of it you were already looking at.
    print "var pf = document.querySelector(\".plate-full\")" > f
    print "var pb = document.querySelector(\".plate-img\")" > f
    print "var sp = document.querySelector(\".splash\")" > f
    print "var lit = null, flight = null" > f
    print "function lift(e) {" > f
    # A middle click or a held modifier still means what it has always meant:
    # the href is a real file and somebody may want it in its own tab.
    print "  if (lit || e.button > 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return" > f
    print "  e.preventDefault()" > f
    print "  lit = document.createElement(\"div\")" > f
    print "  lit.className = \"lit\"" > f
    print "  lit.setAttribute(\"role\", \"dialog\")" > f
    print "  lit.setAttribute(\"aria-modal\", \"true\")" > f
    print "  lit.setAttribute(\"aria-label\", \"the plate painted for this chapter\")" > f
    print "  var img = lit.appendChild(document.createElement(\"img\"))" > f
    print "  var cap = lit.appendChild(document.createElement(\"p\"))" > f
    print "  var x = lit.appendChild(document.createElement(\"button\"))" > f
    print "  img.alt = pb ? pb.alt : \"\"" > f
    print "  img.src = pf.getAttribute(\"href\")" > f
    print "  cap.className = \"lit-cap\"" > f
    print "  cap.textContent = img.alt" > f
    print "  x.className = \"lit-x\"" > f
    print "  x.type = \"button\"" > f
    print "  x.textContent = \"×\"" > f
    print "  x.setAttribute(\"aria-label\", \"close\")" > f
    print "  x.title = \"close (esc)\"" > f
    print "  document.body.appendChild(lit)" > f
    print "  document.documentElement.classList.add(\"lit-open\")" > f
    print "  x.focus()" > f
    print "  lit.addEventListener(\"click\", drop)" > f
    print "  if (img.complete && img.naturalWidth) fly(img)" > f
    print "  else img.addEventListener(\"load\", function () { fly(img) })" > f
    print "}" > f
    # One scale for both axes, so nothing stretches on the way out, and a clip
    # that starts at the edges of the panel, so for the first frame the plate is
    # exactly the crop that was already there and nothing appears outside a
    # panel it has not left yet.
    print "function fly(img) {" > f
    # the browser has to have seen it arrive dark before it will bother
    # animating it lighting up
    print "  void lit.offsetWidth" > f
    print "  lit.classList.add(\"on\")" > f
    print "  if (!img.animate || !pb || !sp) return" > f
    print "  if (matchMedia(\"(prefers-reduced-motion: reduce)\").matches) return" > f
    print "  var b = pb.getBoundingClientRect(), p = sp.getBoundingClientRect()" > f
    print "  var f = img.getBoundingClientRect()" > f
    print "  if (!f.width || !img.naturalWidth) return" > f
    print "  var cx = b.left + b.width / 2, cy = b.top + b.height / 2" > f
    print "  var cover = Math.max(b.width / img.naturalWidth, b.height / img.naturalHeight)" > f
    print "  var s = img.naturalWidth * cover / f.width" > f
    print "  var edge = function (n) { return Math.max(0, n).toFixed(1) + \"px\" }" > f
    print "  flight = img.animate([{" > f
    print "    transform: \"translate(\" + (cx - f.left - f.width / 2) + \"px,\" +" > f
    print "               (cy - f.top - f.height / 2) + \"px) scale(\" + s + \")\"," > f
    print "    clipPath: \"inset(\" + edge(f.height / 2 + (p.top - cy) / s) + \" \" +" > f
    print "              edge(f.width / 2 - (p.right - cx) / s) + \" \" +" > f
    print "              edge(f.height / 2 - (p.bottom - cy) / s) + \" \" +" > f
    print "              edge(f.width / 2 + (p.left - cx) / s) + \")\"" > f
    print "  }, {" > f
    print "    transform: \"none\", clipPath: \"inset(0px 0px 0px 0px)\"" > f
    print "  }], { duration: 560, easing: \"cubic-bezier(0.4, 0, 0.15, 1)\" })" > f
    print "}" > f
    # Put away the same way it arrived, backwards, because a plate that drops
    # back into its own panel tells you where it came from.
    print "function drop() {" > f
    print "  if (!lit) return" > f
    print "  var gone = lit" > f
    print "  lit = null" > f
    print "  gone.classList.remove(\"on\")" > f
    print "  document.documentElement.classList.remove(\"lit-open\")" > f
    print "  pf.focus()" > f
    print "  if (flight && flight.playState !== \"idle\") {" > f
    print "    flight.reverse()" > f
    print "    flight.onfinish = function () { gone.parentNode && gone.parentNode.removeChild(gone) }" > f
    print "  } else setTimeout(function () { gone.parentNode && gone.parentNode.removeChild(gone) }, 420)" > f
    print "  flight = null" > f
    print "}" > f
    print "if (pf) pf.addEventListener(\"click\", lift)" > f
    print "</script>" > f
    print "</body></html>" > f
    close(f)
  }

  # ---- one page per pilot --------------------------------------------------
  # Last, because it is the only page that wants every other page to have been
  # decided first: which books are whose, which chapter carries which receipt,
  # and what the shelf looks like. The roster order above is the order these
  # are written in, so the pages and the table on the cover agree about who
  # comes first without either of them being asked twice.
  for (ri = 1; ri <= nr; ri++) pilotpage(roll[ri])
}'
BUILT=$?

# The audit was the whole of what --audit wanted, and the stylesheet, the room
# and the sidecar below all write files. Out here rather than at the top of the
# script because the audit is inside the builder and there is no reaching it
# without coming this far.
[ "$QUIET" = 1 ] && exit 0

# Every page in the book was written by the one awk above, and awk is not
# supposed to be able to die. gawk 5.2.1 - which is what /usr/bin/awk is on the
# github runner - dies anyway, partway through a chapter, with its heap in
# pieces. An awk program cannot address memory, so it cannot corrupt any: the
# defect is the reader's rather than the book's, and there is nothing here to
# fix. What made it expensive was that this script did not look. It announced
# "37 versions, a page each" over a corpse, the ground crew committed the
# nought-byte page that was left behind, and v37 was gone off the shelf in
# front of everybody.
#
# So the writer's status is read, and every page it promised is opened. A book
# missing a page does not get filed. Stale is recoverable; wrong is the one
# nobody notices.
if [ "$BUILT" != 0 ]; then
  printf 'chronicle: the builder died (exit %s) and the book is half written.\n' "$BUILT" >&2
  printf '           Do not commit docs/ as it stands. If this is gawk, it is\n' >&2
  printf '           gawk - mawk and the bsd awk both finish this history.\n' >&2
  exit 1
fi
GAP=''
[ -s docs/index.html ] || GAP=' the cover'
PAGE=1
while [ "$PAGE" -le "$TOTAL" ]; do
  [ -s "docs/v$PAGE.html" ] || GAP="$GAP v$PAGE"
  PAGE=$((PAGE + 1))
done
if [ -n "$GAP" ]; then
  printf 'chronicle: the builder finished and still left nothing at:%s\n' "$GAP" >&2
  printf '           Do not commit docs/ as it stands.\n' >&2
  exit 1
fi

cat > docs/chronicle.css <<'CSS'
/* THE CHRONICLE.
   The same cabinet, printed. Palette, font and CRT come from the game's own
   styles/tokens.css and styles/crt.css, which are loaded ahead of this file —
   so when somebody changes the spectrum, the book changes with it. All this
   file does is teach that language to a page you scroll instead of play.

   Generated by tools/chronicle.sh. Editing it by hand lasts until the next
   commit. */

/* tokens.css locks the viewport for a canvas; a book has to scroll. */
html, body { height: auto; overflow: visible; }
body {
  user-select: text;
  -webkit-user-select: text;
  padding: 0 1.25rem 6rem;
}
main {
  position: relative;
  z-index: 1;
  max-width: 44rem;
  margin: 0 auto;
  padding-top: clamp(3rem, 12vh, 7rem);
}

/* The title, borrowed straight off the splash screen. */
h1 {
  font-size: clamp(1.9rem, 7.5vw, 3.6rem);
  font-weight: 600;
  letter-spacing: 0.4em;
  margin-right: -0.4em;
  text-wrap: balance;
  background: linear-gradient(100deg,
    #ff3ec8, #ffb020, #b6ff3d, #21f3ff, #a04bff, #ff3ec8);
  background-size: 300% 100%;
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
  filter: drop-shadow(0 0 16px rgba(255, 62, 200, 0.5));
  animation: slide 6s linear infinite;
}
@keyframes slide {
  from { background-position: 0% 50%; }
  to { background-position: 300% 50%; }
}

.sub {
  color: var(--dim);
  font-size: 0.8rem;
  line-height: 1.9;
  letter-spacing: 0.08em;
  margin-top: 1.1rem;
  max-width: 34rem;
}
/* The two ways in. A row on anything wide enough to hold both, and two rows
   the moment it is not - each of them one unbreakable phrase, so a narrow
   screen never gets THE LATEST on one line and CHAPTER on the next. */
.prompt {
  display: flex;
  flex-wrap: wrap;
  gap: 0.7rem 2rem;
  margin: 1.6rem 0 3.2rem;
  font-size: 0.8rem;
  letter-spacing: 0.3em;
}
.prompt a { white-space: nowrap; }
/* The splash screen blinks this; a link you are meant to click does not. */
.prompt a {
  color: var(--lime);
  text-decoration: none;
  text-shadow: 0 0 12px currentColor;
}
.prompt a:hover { text-shadow: 0 0 20px currentColor; }
.heading {
  font-size: 0.6rem;
  font-weight: 500;
  letter-spacing: 0.34em;
  color: var(--magenta);
  text-shadow: 0 0 10px currentColor;
  margin: 3.4rem 0 1.4rem;
}
/* The one paragraph that says what a book is. It is under the heading rather
   than in it because the heading is a marquee and this is an explanation, and
   a reader only needs it once. */
.shelfnote {
  max-width: 62ch;
  margin: -0.7rem 0 0;
  font-size: 0.68rem;
  line-height: 1.7;
  color: var(--dim);
  text-wrap: pretty;
}

/* An instrument panel, same brackets as the field guide on the splash. */
.panel {
  position: relative;
  padding: 1.1rem 1.3rem 1.2rem;
  background: rgba(12, 5, 24, 0.66);
  border: 1px solid rgba(33, 243, 255, 0.35);
  box-shadow: 0 0 26px rgba(160, 75, 255, 0.28),
              inset 0 0 34px rgba(33, 243, 255, 0.06);
}
.panel::before,
.panel::after {
  content: "";
  position: absolute;
  width: 13px;
  height: 13px;
  border: 1px solid var(--magenta);
}
.panel::before { top: -1px; left: -1px; border-right: none; border-bottom: none; }
.panel::after { bottom: -1px; right: -1px; border-left: none; border-top: none; }
.panel h2 {
  font-size: 0.6rem;
  font-weight: 500;
  letter-spacing: 0.34em;
  color: var(--magenta);
  text-shadow: 0 0 10px currentColor;
  margin-bottom: 0.85rem;
  padding-bottom: 0.6rem;
  border-bottom: 1px dashed rgba(160, 75, 255, 0.35);
}

.roster { animation: cycle 9s linear infinite; }
.roster table { width: 100%; border-collapse: collapse; font-size: 0.72rem; }
.roster th {
  text-align: left;
  font-weight: 400;
  letter-spacing: 0.18em;
  color: var(--dim);
  padding: 0.3rem 0.4rem;
}
.roster td {
  padding: 0.42rem 0.4rem;
  letter-spacing: 0.06em;
  border-top: 1px solid rgba(160, 75, 255, 0.18);
  font-variant-numeric: tabular-nums;
}
.roster td:first-child { color: var(--ink); }
.roster .pilot { display: flex; align-items: center; gap: 0.5rem; }
.roster td:nth-child(2) { color: var(--amber); }
.roster a { color: var(--cyan); text-decoration: none; }

/* The contents. Read the taglines straight down and you have the whole story
   of the cabinet; click one and you get the version it belongs to, whole. */
/* the row gap does the spacing now, and a margin as well as a gap puts the
   second one half an inch in from the first the moment they stack */
.prompt .read { color: var(--amber); }
.contents { list-style: none; }
.contents li { border-top: 1px solid rgba(160, 75, 255, 0.16); }
/* The number, the sentence, and the marks hard against the right edge — so the
   marks read down the page as their own column rather than trailing whatever
   length the sentence happened to be. */
.cv a {
  display: grid;
  grid-template-columns: 3.4rem minmax(0, 1fr) auto;
  gap: 0.9rem;
  align-items: baseline;
  padding: 0.62rem 0.3rem;
  text-decoration: none;
}
.cv .marks { justify-content: flex-end; }
.cv a:hover { background: rgba(160, 75, 255, 0.13); }
.cv b { font-size: 0.7rem; font-weight: 500; letter-spacing: 0.16em; color: var(--cyan); }
/* The tagline, and only the tagline. It used to be every span in the row,
   which was true right up until the marks arrived wearing spans of their own
   and came out amber and three sizes too big. */
.cv a > span:not(.marks) {
  font-size: 0.85rem;
  line-height: 1.55;
  color: var(--amber);
  text-wrap: pretty;
}
.cv a:hover > span:not(.marks) { text-shadow: 0 0 12px rgba(255, 176, 32, 0.5); }
/* The pilots' faces. One each, painted once by tools/chronicle-art.sh, and the
   same one everywhere their name is written — which is the reason it is worth
   painting at all. Round, because a portrait among all these straight lines
   should not read as one more panel, and because the helmet fills the frame
   and crops well. A pilot with no face costs nothing: the name simply sits
   where it always did. */
.face {
  flex: none;
  width: 3.1rem;
  height: 3.1rem;
  border-radius: 50%;
  object-fit: cover;
  background: #05010c;
  border: 1px solid rgba(160, 75, 255, 0.55);
  box-shadow: 0 0 10px rgba(160, 75, 255, 0.4);
}
/* A mention, in the margin of whichever version was on the cabinet while it
   happened. Two columns, the same shape a chapter row uses one line up: the
   sentence, and the marks hard against the right in a column of their own. The
   marks used to be floated instead, which reads correctly right up until the
   sentence is narrower than the float - and then the icons are standing in the
   middle of the words. A phone is always that narrow. */
.ci {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  align-items: start;
  gap: 0.2rem 0.7rem;
  padding: 0.5rem 0.3rem 0.5rem 4.3rem;
  font-size: 0.66rem;
  line-height: 1.6;
  color: var(--dim);
}
.ci b { color: var(--violet); font-weight: 500; }
.ci .what { grid-column: 1; }
/* Quieter than the deed above it and in the same proportion the chapter uses,
   because it is here to tell two interludes apart rather than to be read. */
.ci .said {
  display: block;
  margin-top: 0.2rem;
  font-size: 0.6rem;
  letter-spacing: 0.14em;
  color: var(--dim);
  opacity: 0.8;
}

/* --- the marks -------------------------------------------------------------
   Which parts of the cabinet a commit moved, drawn rather than listed. There
   are nine of them and most chapters wear two, so the row is short by
   arithmetic rather than by being cut off somewhere.

   Every mark carries its own words in the markup, in both forms. The tiny one
   hides them from the eye and not from a screen reader, because a row of
   little pictures with nothing behind them is a row of nothing at all to
   anybody who cannot see little pictures.

   The colours are ranked rather than assigned. This book is read for two
   questions before any other — did somebody change the game, and did somebody
   change the game behind it — so those two take the two loudest things in the
   spectrum and everything else takes what is left. The rules and the notes are
   dim on purpose, and for the same reason the drawn field will not light a
   rock that is not the game: real work, but not the thing you came to read
   about. */
.marks { display: flex; flex-wrap: wrap; align-items: center; gap: 0.34rem; }
.mk {
  display: inline-flex;
  align-items: center;
  gap: 0.36rem;
  padding: 0.16rem 0.5rem 0.16rem 0.4rem;
  border: 1px solid currentColor;
  border-radius: 999px;
  background: rgba(5, 1, 12, 0.55);
  color: var(--dim);
  font-size: 0.52rem;
  letter-spacing: 0.18em;
  text-transform: uppercase;
  white-space: nowrap;
}
.mk .ic { flex: none; width: 0.84rem; height: 0.84rem; }
.mk em { font-style: normal; }
/* the two loudest, and they are loud on purpose */
.mk-game   { color: var(--magenta); }
.mk-meta   { color: var(--lime); }
.mk-ui     { color: var(--cyan); }
.mk-music  { color: var(--amber); }
.mk-hands  { color: var(--violet); }
.mk-engine { color: var(--mint); }
.mk-book   { color: var(--ink); }
/* the rules and the notes are real work and not the game, and the field draws
   that distinction in exactly this colour */
.mk-rules, .mk-notes { color: var(--dim); }

/* On the splash, where the badges are met for the first time and are the only
   place in the book that says what they mean. */
.marks.big { margin-top: 1rem; gap: 0.45rem; }
.marks.big .mk {
  padding: 0.26rem 0.68rem 0.26rem 0.55rem;
  font-size: 0.58rem;
  box-shadow: 0 0 14px rgba(5, 1, 12, 0.8), inset 0 0 12px rgba(255, 255, 255, 0.04);
  text-shadow: 0 0 10px currentColor;
}
.marks.big .mk .ic { width: 0.95rem; height: 0.95rem; }

/* In a list, where a reader is scanning down a column and the words would be
   a second column arguing with the first. */
.marks.tiny { gap: 0.22rem; }
.marks.tiny .mk { padding: 0.2rem; border-radius: 50%; }
.marks.tiny em {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
}
/* An interlude keeps to the same right-hand column the chapters use. Half a
   column aligned and half of it trailing whatever length the sentence was
   reads as a mistake rather than as two kinds of entry. Placed rather than
   floated, for the reason written where .ci is defined. */
.ci .marks { grid-column: 2; grid-row: 1; justify-content: flex-end; }
.ci .said { grid-column: 1 / -1; }

/* --- the shelf -------------------------------------------------------------
   A book is a run of chapters one pilot flew with nobody else landing in
   between, and the shelf is every book there has been, newest on top. The one
   on the cabinet is open, because that is the one somebody arriving came for;
   everything under it is a spine you choose to pull.

   <details> does the whole of the opening and closing, so the shelf works on a
   page with the script switched off — which is the same promise every other
   moving part of this book makes. */
.shelf { display: grid; gap: 0.7rem; margin-top: 0.9rem; }
.book {
  border: 1px solid rgba(160, 75, 255, 0.32);
  background: linear-gradient(to right, rgba(160, 75, 255, 0.09), rgba(160, 75, 255, 0.02));
}
.book[open] { border-color: rgba(160, 75, 255, 0.6); }
.book > summary {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 0.55rem 0.95rem;
  padding: 0.7rem 0.9rem;
  cursor: pointer;
  list-style: none;
}
.book > summary::-webkit-details-marker { display: none; }
.book > summary::before {
  content: "\25b6";
  flex: none;
  font-size: 0.6rem;
  color: var(--violet);
  transition: transform 0.18s;
}
.book[open] > summary::before { transform: rotate(90deg); }
.book > summary:hover { background: rgba(160, 75, 255, 0.13); }
.bk { display: flex; align-items: baseline; gap: 0.45rem; }
.bk b {
  font-size: 1.15rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  color: var(--violet);
  text-shadow: 0 0 16px currentColor;
}
.bk i {
  font-style: normal;
  font-size: 0.46rem;
  letter-spacing: 0.3em;
  text-transform: uppercase;
  color: var(--dim);
}
.by {
  display: flex;
  align-items: center;
  gap: 0.55rem;
  margin-right: auto;
  font-size: 0.66rem;
  letter-spacing: 0.14em;
  color: var(--ink);
}
.by .face { width: 2.1rem; height: 2.1rem; }
.bspan {
  padding: 0.12rem 0.46rem;
  border: 1px solid rgba(33, 243, 255, 0.45);
  font-size: 0.56rem;
  letter-spacing: 0.18em;
  color: var(--cyan);
  font-variant-numeric: tabular-nums;
}
.bn {
  font-size: 0.56rem;
  letter-spacing: 0.18em;
  text-transform: uppercase;
  color: var(--dim);
}
/* What the book was, in a paragraph — the arithmetic of the whole run, which
   is the one thing no single chapter inside it can say. */
.gist {
  max-width: 62ch;
  margin: 0 0.9rem 0.4rem;
  padding-left: 0.85rem;
  border-left: 1px solid rgba(255, 176, 32, 0.4);
  font-size: 0.66rem;
  line-height: 1.7;
  color: var(--dim);
  text-wrap: pretty;
}
.book .contents { padding: 0 0.9rem 0.5rem; }

/* --- one version, one comic page ------------------------------------------
   A chapter used to be one screenful read in a single look, and it fought the
   prose for room the whole time. It is a page of cels now: a splash for the
   tagline, the narration beside the numbers, the drawn commit under both, and
   a cel apiece for anything the book had to write down. No block of prose in
   here is wider than 600px, which is the whole reason there are several of
   them — a chapter is a handful of short things rather than one wide one.

   Everything sits on the same twelve columns, so the cels line up without
   anybody having to place them, and a cel with no neighbour this week takes
   the width its neighbour is not using. */
/* The dock is fixed to the foot of the window, so the page ends above it
   rather than under it: the last cel of a chapter is as readable as the
   first. */
body.page { padding: 0 0 clamp(6.5rem, 4rem + 6vh, 8.5rem); }
html { scroll-padding-bottom: 6rem; }
.page main {
  max-width: 82rem;
  margin: 0 auto;
  padding: clamp(0.8rem, 2.4vh, 1.6rem) clamp(0.7rem, 2.4vw, 2rem) 0;
  display: grid;
  grid-template-columns: repeat(12, 1fr);
  gap: clamp(0.6rem, 1.1vw, 1rem);
  align-content: start;
}

/* A cel: hard border, black ink dropped behind it, a corner of the spectrum
   leaking in at the top. It arrives as you scroll onto it — the script adds
   .in, and adds it to everything at once for anybody who asked for less
   motion, so nothing is ever left hidden behind an animation. */
.cel {
  position: relative;
  grid-column: span 12;
  padding: 1.35rem 1.2rem 1.1rem;
  background: linear-gradient(168deg, rgba(160, 75, 255, 0.1), rgba(7, 3, 15, 0.88) 46%);
  border: 2px solid rgba(160, 75, 255, 0.45);
  box-shadow: 5px 5px 0 rgba(0, 0, 0, 0.7), 0 0 26px rgba(160, 75, 255, 0.16);
}
/* Hidden only once the script has said it is there to unhide them. A page that
   needs JavaScript to show its own words is not a page, and the book is read
   in whatever somebody happens to have open. */
.js .cel {
  opacity: 0;
  transform: translateY(16px);
  transition: opacity 0.45s ease, transform 0.5s cubic-bezier(0.2, 0.85, 0.3, 1);
}
.js .cel.in { opacity: 1; transform: none; }
.cel:hover { border-color: rgba(33, 243, 255, 0.5); }
/* A cel inside the margin is not on the twelve columns any more, and asking
   for all of them there makes its grid build eleven tracks nobody wanted. */
.margin > .cel, .record > .cel { grid-column: auto; }

/* The label of a cel, sitting on its top edge the way a comic captions a
   panel. The glyph does most of the work: a reader knows which cel this is
   before they have read the word. */
.tab {
  position: absolute;
  top: -0.66rem;
  left: 0.85rem;
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  padding: 0.14rem 0.55rem;
  background: var(--void);
  border: 2px solid currentColor;
  color: var(--violet);
  font-size: 0.5rem;
  font-weight: 500;
  letter-spacing: 0.28em;
  text-transform: uppercase;
  text-shadow: 0 0 10px currentColor;
  white-space: nowrap;
}
.ic {
  flex: none;
  width: 1em;
  height: 1em;
  fill: none;
  stroke: currentColor;
  stroke-width: 1.7;
  stroke-linecap: round;
  stroke-linejoin: round;
}
.tab .ic { width: 0.85rem; height: 0.85rem; }

/* Who flew it and when, signed into the bottom corner of the splash — where a
   comic signs a panel, and the one corner the sentence never reaches, because
   the sentence is capped at 17ch and pinned to the left. Stacked, so it reads
   down the corner as four short facts rather than across it as one long line
   arguing with the sentence for the same inch. */
.credits {
  position: absolute;
  z-index: 2;
  right: clamp(1.2rem, 3.6vw, 2.6rem);
  bottom: clamp(1.2rem, 3.6vw, 2.6rem);
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 0.4rem;
  text-align: right;
}
.badge { display: flex; align-items: baseline; gap: 0.5rem; }
.badge b {
  font-size: 1.45rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  color: var(--violet);
  text-shadow: 0 0 18px currentColor;
}
.badge i {
  font-style: normal;
  font-size: 0.5rem;
  letter-spacing: 0.3em;
  text-transform: uppercase;
  color: var(--dim);
}
.ver {
  padding: 0.1rem 0.42rem;
  border: 1px solid rgba(33, 243, 255, 0.45);
  font-size: 0.56rem;
  letter-spacing: 0.2em;
  color: var(--cyan);
}
.credits .who {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.6rem;
  letter-spacing: 0.22em;
  text-transform: uppercase;
  color: var(--cyan);
}
/* Whoever flew it, on their own chapter's splash — smaller than it was on a
   bar of its own, because the sentence underneath is the loud thing here. */
.credits .who .face {
  width: 2.3rem;
  height: 2.3rem;
  border-color: rgba(33, 243, 255, 0.55);
  box-shadow: 0 0 12px rgba(33, 243, 255, 0.35);
}
.credits .when {
  font-size: 0.56rem;
  letter-spacing: 0.14em;
  color: var(--dim);
  font-variant-numeric: tabular-nums;
}

/* --- the splash -----------------------------------------------------------
   One version is one sentence, and this is where it gets said at the size it
   deserves. The plate goes behind it when the chapter has one — painted once
   by tools/chronicle-art.sh and kept in docs/art/ from then on — and the
   halftone dots are there either way, so a chapter with no plate reads as a
   panel somebody meant rather than as one short of a picture. */
.splash {
  min-height: clamp(14rem, 42vh, 24rem);
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  overflow: hidden;
  padding: clamp(1.2rem, 3.6vw, 2.6rem);
  border-color: rgba(255, 62, 200, 0.4);
  background: radial-gradient(120% 100% at 82% 4%, rgba(160, 75, 255, 0.3), transparent 62%), #05010c;
}
.plate-img {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
  opacity: 0.62;
  /* the book is a CRT and the plate did not come off one, so it is sent
     through the same glass as everything else on the page */
  filter: saturate(1.18) contrast(1.06);
  animation: breathe 34s ease-in-out infinite alternate;
}
@keyframes breathe {
  from { transform: scale(1.03); }
  to { transform: scale(1.14) translate(-1.6%, -1.4%); }
}
/* Halftone. A comic is dots before it is anything else, and these ones drift,
   which is the cheapest way there is to make a still page look like it runs. */
.dots {
  position: absolute;
  inset: -12%;
  background-image: radial-gradient(rgba(255, 62, 200, 0.55) 1.1px, transparent 1.3px);
  background-size: 7px 7px;
  opacity: 0.2;
  animation: halftone 18s linear infinite;
}
@keyframes halftone { to { transform: translate(7px, 7px); } }
/* the scanline layer sits behind main, so the splash gets its own, along with
   the scrim that keeps the tagline legible over whatever was painted */
.splash::after {
  content: "";
  position: absolute;
  inset: 0;
  pointer-events: none;
  background:
    linear-gradient(to top, rgba(5, 1, 12, 0.95) 4%, rgba(5, 1, 12, 0.4) 52%, rgba(5, 1, 12, 0.15)),
    repeating-linear-gradient(to bottom, rgba(0, 0, 0, 0.3) 0 1px, transparent 1px 3px);
}
.say { position: relative; z-index: 2; }
.kicker {
  display: flex;
  align-items: center;
  gap: 0.45rem;
  margin-bottom: 0.7rem;
  font-size: 0.54rem;
  letter-spacing: 0.34em;
  text-transform: uppercase;
  color: var(--lime);
  text-shadow: 0 0 14px currentColor;
}
/* What happened to the game, in letters you can read from the other side of
   the room. Every version has one, and on a page it is the whole headline. */
.shout {
  font-size: clamp(1.75rem, 5.4vw, 4.2rem);
  font-weight: 600;
  line-height: 1.04;
  /* the cover title is spaced out like a marquee; a sentence is not */
  letter-spacing: 0;
  margin-right: 0;
  max-width: 17ch;
  text-wrap: balance;
  background: linear-gradient(100deg,
    #ff3ec8, #ffb020, #b6ff3d, #21f3ff, #a04bff, #ff3ec8);
  background-size: 300% 100%;
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
  filter: drop-shadow(0 3px 0 rgba(0, 0, 0, 0.85)) drop-shadow(0 0 24px rgba(255, 62, 200, 0.35));
  animation: slide 9s linear infinite;
}
.plate-full {
  position: absolute;
  z-index: 2;
  top: 0.7rem;
  right: 0.75rem;
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.24rem 0.5rem;
  background: rgba(7, 3, 15, 0.75);
  border: 1px solid rgba(33, 243, 255, 0.45);
  color: var(--cyan);
  font-size: 0.5rem;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  text-decoration: none;
}
.plate-full:hover { border-color: var(--cyan); box-shadow: 0 0 16px rgba(33, 243, 255, 0.3); }
/* with the script running the link does not go anywhere, so it says so */
.js .plate-full { cursor: zoom-in; }

/* --- the plate, in full ---------------------------------------------------
   The link under the splash still points at the picture, and with the script
   off the browser does the old obvious thing with it. With the script on the
   chapter stays where it is and the plate climbs out of the panel it was
   behind instead — uncropped, over the page it belongs to, and gone again on
   a click, on Escape, or on the button in the corner. */
.lit {
  position: fixed;
  inset: 0;
  z-index: 40;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: clamp(0.7rem, 2vh, 1.2rem);
  padding: clamp(1rem, 4vw, 3rem);
  cursor: zoom-out;
  background: radial-gradient(120% 90% at 50% 45%, rgba(20, 4, 40, 0.86), rgba(3, 1, 8, 0.97));
  opacity: 0;
  transition: opacity 420ms ease;
}
.lit.on { opacity: 1; }
/* the book is a CRT, and a picture held up in front of it is behind the same
   glass as everything else on the page */
.lit::after {
  content: "";
  position: absolute;
  inset: 0;
  pointer-events: none;
  background: repeating-linear-gradient(to bottom, rgba(0, 0, 0, 0.32) 0 1px, transparent 1px 3px);
}
.lit img {
  max-width: 100%;
  max-height: 80vh;
  object-fit: contain;
  border: 1px solid rgba(255, 62, 200, 0.45);
  box-shadow: 0 0 70px rgba(160, 75, 255, 0.35);
  /* the same glass the plate wears in the panel it came out of */
  filter: saturate(1.18) contrast(1.06);
}
.lit-cap {
  position: relative;
  max-width: 46rem;
  text-align: center;
  color: var(--dim);
  font-size: 0.62rem;
  line-height: 1.8;
  letter-spacing: 0.14em;
  text-wrap: balance;
}
.lit-cap:empty { display: none; }
/* the caption and the way out arrive after the plate has landed, so the first
   half-second is the picture and nothing else */
.lit-cap, .lit-x {
  opacity: 0;
  transform: translateY(0.4rem);
  transition: opacity 260ms ease, transform 260ms ease;
}
.lit.on .lit-cap, .lit.on .lit-x {
  opacity: 1;
  transform: none;
  transition-delay: 300ms;
}
.lit-x {
  position: absolute;
  top: clamp(0.6rem, 2vw, 1.3rem);
  right: clamp(0.6rem, 2vw, 1.3rem);
  width: 2.1rem;
  height: 2.1rem;
  display: grid;
  place-items: center;
  padding: 0;
  background: rgba(7, 3, 15, 0.75);
  border: 1px solid rgba(33, 243, 255, 0.45);
  color: var(--cyan);
  font: inherit;
  font-size: 1.1rem;
  line-height: 1;
  cursor: pointer;
}
.lit-x:hover { border-color: var(--cyan); box-shadow: 0 0 16px rgba(33, 243, 255, 0.3); }
/* the page underneath does not scroll while the plate is up, or the zoom it
   flies back into would have moved by the time it got there */
.lit-open, .lit-open body { overflow: hidden; }

/* --- the narration --------------------------------------------------------
   The pilot's own sentence about what they did, in what a comic would call a
   caption box. Capped at 600px, because that is where a line of monospace
   stops being comfortable — and that cap is what makes the rest of the page
   divide into cels in the first place. */
.told { grid-column: span 5; }
.deed {
  max-width: 600px;
  font-size: clamp(0.92rem, 1.3vw, 1.12rem);
  line-height: 1.6;
  color: var(--ink);
  text-wrap: pretty;
}
.deed::first-letter {
  float: left;
  padding: 0.04em 0.09em 0 0;
  font-size: 2.6em;
  line-height: 0.82;
  color: var(--amber);
  text-shadow: 0 0 20px rgba(255, 176, 32, 0.5);
}

/* --- the numbers ----------------------------------------------------------
   Six tiles, each with its glyph, each counting up as the cel lands. They are
   the same six facts a chapter always carried; they have just stopped being a
   footnote about themselves. */
.figures { grid-column: span 7; }
.stats {
  list-style: none;
  display: grid;
  /* three and three, so the six of them read as a block rather than as a row
     that ran out */
  grid-template-columns: repeat(3, minmax(0, 1fr));
  grid-auto-rows: minmax(3.2rem, 1fr);
  gap: 0.45rem;
}
/* The six of them fill the cel, so the numbers stand level with the narration
   in the cel beside them rather than bunching at the top of a tall panel. Only
   here: the ledger uses the same tiles with a paragraph and a list of receipts
   underneath, and a list told to be as tall as its parent takes the whole cel
   and leaves everything after it standing outside the border. */
.figures .stats { height: 100%; }
.stats li {
  display: grid;
  grid-template-columns: auto 1fr;
  column-gap: 0.6rem;
  align-content: center;
  padding: 0.5rem 0.6rem;
  background: rgba(160, 75, 255, 0.09);
  border: 1px solid rgba(160, 75, 255, 0.28);
  border-left: 3px solid var(--cyan);
  transition: background 0.2s, border-left-color 0.2s;
}
.stats li:hover { background: rgba(255, 62, 200, 0.11); border-left-color: var(--magenta); }
.stats .ic {
  grid-row: 1 / 3;
  align-self: center;
  width: 1.7rem;
  height: 1.7rem;
  color: var(--cyan);
  opacity: 0.8;
}
.stats li:hover .ic { color: var(--magenta); opacity: 1; }
.stats b {
  font-size: 1.3rem;
  font-weight: 500;
  line-height: 1.15;
  color: var(--cyan);
  font-variant-numeric: tabular-nums;
  text-shadow: 0 0 16px rgba(33, 243, 255, 0.35);
}
.stats span {
  font-size: 0.48rem;
  line-height: 1.4;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--dim);
}

/* The commit, drawn: one shape per sector it touched, drawn as the thing it
   is — an event is a mine, the rules are a gear, the song is a note, a panel is
   a panel — sized by how much of that sector moved and coloured by which part
   of the cabinet it was. The diff picks the pilot's move: wreckage is shot
   down and sheds shards, a new arrival rides in on a tow beam and rings while
   it settles, a tuning pass gets a reticle where a shot would be, and
   anything else is the standing order — fire at the biggest thing you moved.
   None of it is random — tools/chronicle.sh seeds it with the commit hash, so
   a version looks the same in every clone forever. */
/* Seven columns rather than twelve: the field is drawn on a 1400x640 board, so
   at full width it turns into a wall of empty space with three rocks in it.
   Beside the margin it is a picture. With nothing in the margin it takes the
   whole row back. */
/* align-self, so a version with five things in its margin does not stretch the
   field into a black rectangle with one rock adrift in it. The picture keeps
   the height its own shape asks for and the margin runs on past it. */
.frame {
  grid-column: span 7;
  align-self: start;
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
  padding-bottom: 0.8rem;
}
.frame .art { display: block; width: 100%; height: auto; }
.ch:not(.has-record):not(.has-aside) .frame,
.ch.long-aside .frame { grid-column: span 12; }
.ch:not(.has-record):not(.has-aside) .frame .art,
.ch.long-aside .frame .art { max-height: 52vh; }
.frame figcaption {
  font-size: 0.55rem;
  letter-spacing: 0.1em;
  color: var(--dim);
  text-align: center;
}
.art .star {
  fill: var(--ink);
  opacity: 0.5;
  animation: twinkle 3.4s ease-in-out infinite alternate;
  animation-delay: var(--d);
}
.art .drift {
  transform-box: fill-box;
  transform-origin: 50% 50%;
  animation: drift 14s ease-in-out infinite alternate;
  animation-delay: var(--d);
}
.art .rock {
  fill: rgba(7, 3, 15, 0.5);
  stroke: var(--c);
  stroke-width: 2.2;
  transform-box: fill-box;
  transform-origin: 50% 50%;
  animation: spin var(--s) linear infinite;
  filter: drop-shadow(0 0 6px var(--c));
}
.art .rock.gone { fill: none; stroke-dasharray: 5 8; opacity: 0.4; filter: none; }
/* The rest of the field's vocabulary. A glyph is a sector drawn as what it
   is; its stroke arrives pre-divided by the group's scale so every silhouette
   carries the same line the rocks do. "solid" blots out the stars behind a
   body, "pip" is the light a thing keeps on, "whirl" turns because a gear
   that does not is a decal. */
.art .glyph {
  fill: none;
  stroke: var(--c);
  stroke-linecap: round;
  stroke-linejoin: round;
  filter: drop-shadow(0 0 6px var(--c));
}
.art .glyph .solid { fill: rgba(7, 3, 15, 0.5); }
.art .glyph .pip { fill: var(--c); stroke: none; animation: pip 1.6s ease-in-out infinite alternate; }
.art .glyph .spark { animation: pip 0.9s ease-in-out infinite alternate; }
.art .glyph .scan { opacity: 0.55; }
.art .glyph .whirl {
  transform-box: fill-box;
  transform-origin: 50% 50%;
  animation: spin 26s linear infinite;
}
.art .glyph.gone { opacity: 0.4; filter: none; }
.art .glyph.gone .solid { fill: none; }
.art .glyph.gone .pip { animation: none; opacity: 0.5; }
/* Dead machinery stops. A wreck that keeps turning is not a wreck. */
.art .glyph.gone .whirl, .art .glyph.gone .spark { animation: none; }
/* What the diff did, marked on the thing it did it to: a new arrival rings
   while it settles, wreckage sheds shards on their own way out. */
.art .born {
  fill: none;
  stroke: var(--c);
  stroke-width: 1.6;
  opacity: 0;
  transform-box: fill-box;
  transform-origin: 50% 50%;
  animation: bornring 2.8s linear infinite;
  animation-delay: var(--d);
}
.art .shard {
  fill: none;
  stroke: var(--c);
  stroke-width: 1.6;
  transform-box: fill-box;
  animation: shardfly 3.2s ease-out infinite;
  animation-delay: var(--d);
}
/* The pilot's move, when it is not the standing shot: the quiet aim line and
   slow reticle of a tuning pass, the tow beam hauling a new arrival in, the
   burst where a kill connected. */
.art .aim { stroke: var(--lime); stroke-width: 1.6; opacity: 0.25; }
.art .ret {
  fill: none;
  stroke: var(--lime);
  stroke-width: 2;
  opacity: 0.8;
  filter: drop-shadow(0 0 6px var(--lime));
  transform-box: fill-box;
  transform-origin: 50% 50%;
  animation: spin 40s linear infinite;
}
.art .beam {
  stroke: var(--cyan);
  stroke-width: 2;
  stroke-dasharray: 5 11;
  opacity: 0.6;
  animation: march 1.4s linear infinite;
}
.art .hit {
  stroke: var(--lime);
  stroke-width: 2.4;
  filter: drop-shadow(0 0 6px var(--lime));
  animation: pip 0.8s ease-in-out infinite alternate;
}
.art .ship {
  fill: none;
  stroke: var(--lime);
  stroke-width: 2.6;
  filter: drop-shadow(0 0 8px var(--lime));
}
.art .shot {
  stroke: var(--lime);
  stroke-width: 2;
  stroke-dasharray: 9 15;
  opacity: 0.55;
  animation: march 1.1s linear infinite;
}
/* A file that came back lighter than it went has had a piece taken out of it.
   A rock loses it out of the outline itself, because a rock is drawn fresh
   every time and can be; a silhouette is fixed markup and cannot, so it loses
   it beside itself instead. Either way the chip stays where it came off - a
   shard flies away and means the thing is gone, and this one is not. */
.art .crumb {
  fill: none;
  stroke: var(--c);
  stroke-width: 1.6;
  stroke-linejoin: round;
  opacity: 0.55;
  filter: drop-shadow(0 0 4px var(--c));
}
/* And what the words said, when the tagline said something a picture can hold:
   speed lines off whatever the pilot was aiming at, or two more of the thing
   when the line says there was more than one of them. Garnish rather than
   grammar - it fires on about one chapter in twenty-six, and that is the
   intended rate. */
.art .streak {
  stroke: var(--lime);
  stroke-width: 2.4;
  stroke-linecap: round;
  opacity: 0.5;
  filter: drop-shadow(0 0 6px var(--lime));
  animation: streak 1.1s ease-out infinite;
  animation-delay: var(--d);
}
.art .echo {
  fill: none;
  stroke: var(--c);
  stroke-width: 1.8;
  stroke-linecap: round;
  stroke-linejoin: round;
  opacity: 0.3;
  animation: echopulse 3.6s ease-in-out infinite alternate;
  animation-delay: var(--d);
}
.art .ghost { font: 700 400px var(--mono); fill: var(--violet); opacity: 0.07; }
.art .stamp rect { fill: none; stroke: currentColor; stroke-width: 3; opacity: 0.75; }
.art .stamp text {
  fill: currentColor;
  font: 600 40px var(--mono);
  letter-spacing: 0.18em;
  text-anchor: middle;
}
.art .stamp.off { color: var(--magenta); }
.art .stamp.over { color: var(--amber); }
.art .stamp.untold { color: var(--dim); opacity: 0.6; }
@keyframes spin { to { transform: rotate(360deg); } }
@keyframes drift { to { transform: translate(14px, -11px); } }
@keyframes twinkle { to { opacity: 0.12; } }
@keyframes march { to { stroke-dashoffset: -48; } }
@keyframes pip { to { opacity: 0.25; } }
@keyframes streak { from { opacity: 0.7; } to { opacity: 0; } }
@keyframes echopulse { to { opacity: 0.1; } }
@keyframes bornring {
  0% { transform: scale(0.55); opacity: 0.9; }
  100% { transform: scale(1.5); opacity: 0; }
}
@keyframes shardfly {
  0% { transform: translate(0, 0); opacity: 0.9; }
  100% { transform: translate(var(--tx), var(--ty)); opacity: 0; }
}

/* --- what the book had to write down --------------------------------------
   The loud cels. A rule bent in writing, a rule changed outright, or a commit
   the referee never got to look at — each with the rule itself in letters that
   carry, because the whole point of a budget is that spending it is visible
   from the doorway. */
/* The margin runs down the side of the drawn field and holds everything that
   happened around this version rather than in it. */
.margin {
  grid-column: span 5;
  display: grid;
  gap: clamp(0.6rem, 1.1vw, 1rem);
}
/* A version that had three other things happen while it was on the cabinet has
   more margin than there is margin. It comes out from beside the field and
   runs underneath it in columns, where the notes read as a stack of cards
   rather than as one long wall down the side. */
.ch.long-aside .margin { grid-column: span 12; }
.ch.long-aside .meanwhile {
  columns: 22rem;
  column-gap: clamp(0.8rem, 1.6vw, 1.6rem);
}
.ch.long-aside .interlude { break-inside: avoid; margin: 0 0 0.9rem; }
.record {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(100%, 20rem), 1fr));
  gap: clamp(0.6rem, 1.1vw, 1rem);
}
.loud { color: var(--amber); }
.loud .tab { color: inherit; }
/* The burst a comic puts behind a noise, turning slowly enough to be noticed
   rather than watched. Masked rather than clipped, because clipping the cel
   would take the corner off its own label with it. */
.loud::before {
  content: "";
  position: absolute;
  top: 0;
  right: 0;
  width: 9rem;
  height: 9rem;
  background: conic-gradient(from 0deg, currentColor 0 5deg, transparent 5deg 30deg);
  -webkit-mask-image: radial-gradient(closest-side, #000 28%, transparent 76%);
  mask-image: radial-gradient(closest-side, #000 28%, transparent 76%);
  opacity: 0.16;
  pointer-events: none;
  animation: spin 70s linear infinite;
}
.klaxon {
  position: relative;
  font-size: clamp(1.7rem, 3.6vw, 2.9rem);
  font-weight: 600;
  line-height: 1;
  letter-spacing: 0.04em;
  text-shadow: 3px 3px 0 rgba(0, 0, 0, 0.8), 0 0 28px currentColor;
}
.reason {
  max-width: 600px;
  margin-top: 0.55rem;
  font-size: 0.7rem;
  line-height: 1.75;
  color: var(--ink);
}
.byline {
  margin-top: 0.5rem;
  font-size: 0.52rem;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  color: var(--dim);
}
.loud.over { border-color: rgba(255, 176, 32, 0.6); }
.loud.law { color: var(--violet); border-color: rgba(160, 75, 255, 0.65); }
/* The other two are a pilot saying what they did. This one is the book saying
   it for them, because nobody wrote it down and the referee was not running.
   It is the one cel on the page that flashes, and it flashes on purpose. */
.loud.off {
  color: var(--magenta);
  border-color: var(--magenta);
  background: linear-gradient(168deg, rgba(255, 62, 200, 0.16), rgba(7, 3, 15, 0.88) 52%);
  animation: alarm 2.6s ease-in-out infinite;
}
@keyframes alarm {
  50% { box-shadow: 5px 5px 0 rgba(0, 0, 0, 0.7), 0 0 40px rgba(255, 62, 200, 0.45); }
}

/* --- the dock ---------------------------------------------------------------
   Forward, back, and out — bolted to the bottom of the window instead of the
   bottom of the page, because a reader halfway down a chapter is exactly the
   reader most likely to want the next one. The arrow keys do the same thing;
   see the script at the foot of every page. */
.dock {
  position: fixed;
  z-index: 5;
  inset: auto 0 0 0;
  display: grid;
  grid-template-columns: auto auto minmax(0, 1fr) auto;
  align-items: stretch;
  gap: clamp(0.3rem, 1vw, 0.75rem);
  padding: 0.45rem clamp(0.45rem, 1.8vw, 1.2rem);
  background: linear-gradient(to top, rgba(7, 3, 15, 0.98), rgba(9, 4, 20, 0.9));
  border-top: 1px solid rgba(160, 75, 255, 0.5);
  box-shadow: 0 -12px 34px rgba(7, 3, 15, 0.85);
  backdrop-filter: blur(6px);
}

/* The two a reader actually wants, at the size of something you press. */
.turn {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.3rem 0.75rem;
  border: 1px solid rgba(182, 255, 61, 0.45);
  background: rgba(182, 255, 61, 0.06);
  color: var(--lime);
  text-decoration: none;
  white-space: nowrap;
}
.turn:hover {
  color: var(--ink);
  border-color: var(--lime);
  background: rgba(182, 255, 61, 0.16);
  box-shadow: 0 0 18px rgba(182, 255, 61, 0.25);
}
.turn .arw { font-size: 1.1rem; line-height: 1; text-shadow: 0 0 12px currentColor; }
.turn .lab { display: grid; gap: 0.1rem; text-align: left; }
.turn.next .lab { text-align: right; }
.turn .lab i {
  font-style: normal;
  font-size: 0.46rem;
  letter-spacing: 0.28em;
  text-transform: uppercase;
  color: var(--dim);
}
.turn .lab b { font-size: 0.78rem; font-weight: 500; letter-spacing: 0.1em; }
/* The first chapter and the one on the cabinet each have one edge with nothing
   past it. The button stays where it was, unlit, so the row does not shuffle. */
.turn.none {
  border-color: rgba(154, 134, 189, 0.22);
  background: none;
  color: rgba(154, 134, 189, 0.45);
}
.turn.none .lab b { font-size: 0.6rem; letter-spacing: 0.16em; }
.up {
  display: grid;
  place-items: center;
  gap: 0.14rem;
  padding: 0 0.6rem;
  border: 1px solid rgba(160, 75, 255, 0.4);
  color: var(--violet);
  text-decoration: none;
}
.up .ic { width: 0.95rem; height: 0.95rem; }
.up i { font-style: normal; font-size: 0.44rem; letter-spacing: 0.22em; text-transform: uppercase; }
.up:hover { color: var(--ink); border-color: var(--cyan); }

/* Every book there has ever been, oldest first, always in reach. It used to be
   every version, and by about thirty of them the row had stopped being a shelf
   and started being a filmstrip nobody could aim at. A book is a run of
   chapters one pilot flew with nobody else landing in between, which is a
   coarser thing to press and a truer thing to name — and the chapters are one
   press away rather than none, which is the trade.

   More books than window and this scrolls sideways — which it will, and which
   is why it is the only part of the dock allowed to move. */
.rail {
  position: relative;
  display: flex;
  align-items: center;
  gap: 4px;
  overflow-x: auto;
  overflow-y: hidden;
  overscroll-behavior-x: contain;
  justify-content: safe center;
  scrollbar-width: thin;
  scrollbar-color: rgba(160, 75, 255, 0.5) transparent;
  -webkit-mask-image: linear-gradient(to right, transparent, #000 1.2rem, #000 calc(100% - 1.2rem), transparent);
  mask-image: linear-gradient(to right, transparent, #000 1.2rem, #000 calc(100% - 1.2rem), transparent);
}
.rail::-webkit-scrollbar { height: 3px; }
.rail::-webkit-scrollbar-thumb { background: rgba(160, 75, 255, 0.5); }
/* One spine per book. The numeral is what it is called, the range is what is
   inside it, and the face is whose run it was — which is the fact the shelf
   exists to show, and the one the old row of numbered thumbnails never did. */
.spine {
  flex: none;
  display: flex;
  align-items: center;
  gap: 0.45rem;
  height: 2.4rem;
  padding: 0 0.5rem;
  border: 1px solid rgba(160, 75, 255, 0.3);
  background: linear-gradient(to top, rgba(160, 75, 255, 0.16), rgba(11, 4, 24, 0.9));
  color: var(--dim);
  font: inherit;
  cursor: pointer;
}
.spine .face {
  width: 1.6rem;
  height: 1.6rem;
  border-color: rgba(160, 75, 255, 0.5);
  box-shadow: none;
}
.spine .sp { display: grid; gap: 0.02rem; text-align: left; }
.spine .sp b {
  font-size: 0.66rem;
  font-weight: 600;
  letter-spacing: 0.1em;
  color: var(--violet);
}
.spine .sp i {
  font-style: normal;
  font-size: 0.46rem;
  letter-spacing: 0.1em;
  font-variant-numeric: tabular-nums;
}
.spine .nm {
  max-width: 7rem;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 0.5rem;
  letter-spacing: 0.14em;
  text-transform: uppercase;
}
/* Every mark its chapters wear, once each. On a spine this is the only thing
   that says what the run was about, so it sits at the end where the eye lands
   after the numeral — and it is the reason a shelf beats a row of numbers. */
.spine .marks { flex-wrap: nowrap; margin-left: 0.1rem; }
.spine:hover { border-color: var(--cyan); color: var(--ink); }
.spine.here { border-color: var(--cyan); box-shadow: 0 0 0 1px var(--cyan), 0 0 16px rgba(33, 243, 255, 0.3); }
.spine.here .sp b { color: var(--cyan); }
.spine[aria-expanded="true"] {
  border-color: var(--amber);
  color: var(--ink);
  background: linear-gradient(to top, rgba(255, 176, 32, 0.22), rgba(11, 4, 24, 0.9));
}
.spine[aria-expanded="true"] .sp b { color: var(--amber); }

/* The book, pulled off the shelf. It stacks above the dock rather than
   replacing it, so the shelf you pulled it from is still under your thumb —
   and nothing has been navigated yet, which is the whole point: a book opening
   is not a page turning. Press a chapter for that. */
.tray {
  position: absolute;
  inset: auto 0 100% 0;
  max-height: min(58vh, 30rem);
  overflow-y: auto;
  overscroll-behavior: contain;
  padding: 0.6rem clamp(0.45rem, 1.8vw, 1.2rem) 0.7rem;
  background: linear-gradient(to top, rgba(9, 4, 20, 0.99), rgba(7, 3, 15, 0.97));
  border-top: 1px solid rgba(255, 176, 32, 0.5);
  box-shadow: 0 -18px 40px rgba(7, 3, 15, 0.9);
  backdrop-filter: blur(6px);
}
.tray-head {
  display: flex;
  align-items: baseline;
  gap: 0.7rem;
  margin-bottom: 0.5rem;
  padding-bottom: 0.4rem;
  border-bottom: 1px dashed rgba(255, 176, 32, 0.3);
  font-size: 0.54rem;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  color: var(--dim);
}
.tray-head b { font-size: 0.7rem; font-weight: 600; color: var(--amber); }
.tray-head span { color: var(--ink); }
.tray-head i { font-style: normal; margin-left: auto; color: var(--cyan); font-variant-numeric: tabular-nums; }
/* Stacked, oldest at the top, the way the run was flown. */
.stack { display: grid; gap: 3px; }
.leaf {
  display: grid;
  grid-template-columns: 3.2rem 2.6rem minmax(0, 1fr) auto;
  align-items: center;
  gap: 0.7rem;
  padding: 0.24rem 0.4rem 0.24rem 0.24rem;
  border: 1px solid rgba(160, 75, 255, 0.24);
  color: var(--dim);
  text-decoration: none;
}
.leaf .thumb {
  height: 2.1rem;
  overflow: hidden;
  /* the halftone a chapter with no plate falls back to, under the plate a
     chapter with one covers it with */
  background: radial-gradient(rgba(255, 62, 200, 0.5) 1px, transparent 1.2px) 0 0 / 6px 6px, #0b0418;
}
.leaf .thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  opacity: 0.75;
  /* a plate is a square and a thumbnail is not, so it arrives cropped and
     often cropped to the darkest part of itself - lifted here, because a
     thumbnail nobody can make out is a blank tile with extra steps */
  filter: saturate(1.25) contrast(1.05) brightness(1.25);
  transition: opacity 0.15s, transform 0.35s;
}
.leaf b {
  font-size: 0.6rem;
  font-weight: 500;
  letter-spacing: 0.1em;
  font-variant-numeric: tabular-nums;
}
.leaf .line {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 0.68rem;
  letter-spacing: 0.04em;
  color: var(--amber);
}
/* Hard against the right edge, so a stack of six chapters reads as a column of
   marks somebody can scan down rather than six ragged tails. */
.leaf .marks { flex-wrap: nowrap; justify-content: flex-end; }
.leaf:hover { border-color: var(--cyan); color: var(--ink); background: rgba(33, 243, 255, 0.08); }
.leaf:hover .thumb img { opacity: 1; transform: scale(1.06); }
.leaf.bent { border-color: rgba(255, 176, 32, 0.6); }
.leaf.bent b { color: var(--amber); }
.leaf.off { border-color: var(--magenta); }
.leaf.off b { color: var(--magenta); }
.leaf.here { border-color: var(--cyan); box-shadow: inset 0 0 0 1px rgba(33, 243, 255, 0.4); }
.leaf.here b { color: var(--cyan); }

/* A version whose pilot wrote no Chronicle line reads as a gap in the record,
   and looks like one, so the next person can see what a missing chapter costs. */
.deed.untold {
  color: var(--dim);
  font-size: 0.86rem;
  font-style: italic;
}
.deed.untold::first-letter { float: none; font-size: 1em; color: inherit; text-shadow: none; }
.subj {
  max-width: 600px;
  margin-top: 0.7rem;
  padding-top: 0.5rem;
  border-top: 1px dashed rgba(160, 75, 255, 0.3);
  font-size: 0.62rem;
  line-height: 1.6;
  letter-spacing: 0.12em;
  color: var(--dim);
}
/* Something happened that was not a version: the rules moved, the book was
   rebuilt, somebody tidied. It goes in the record because everything goes in
   the record, but it never took a number, so it does not take a page either —
   it sits in the margin of whichever version was on the cabinet at the time. */
.interlude {
  padding-left: 0.9rem;
  border-left: 2px dashed rgba(160, 75, 255, 0.3);
}
.interlude + .interlude { margin-top: 0.8rem; }
.between {
  max-width: 600px;
  font-size: 0.78rem;
  line-height: 1.7;
  letter-spacing: 0.04em;
  color: var(--ink);
}
.between b { color: var(--violet); font-weight: 500; }
.interlude .subj { margin-top: 0.35rem; padding-top: 0; border: none; font-size: 0.58rem; }

/* The four things the book records whether you like it or not, here in the
   margin where the interludes live. On the chapter itself they get a cel each. */
.override, .lawchange, .unrecorded, .ledger {
  max-width: 600px;
  margin-top: 0.6rem;
  padding: 0.45rem 0.7rem;
  font-size: 0.66rem;
  line-height: 1.65;
  border-left: 2px solid currentColor;
}
.override { color: var(--magenta); background: rgba(255, 62, 200, 0.07); }
.lawchange { color: var(--amber); background: rgba(255, 176, 32, 0.07); }
.ledger { color: var(--violet); background: rgba(160, 75, 255, 0.07); }

/* The other two are a pilot saying what they did. This one is the book saying
   it for them, because nobody wrote it down and the referee was not running.
   It reads at full brightness on purpose: the declared ones are colour on the
   page, this one is the page talking. */
.unrecorded {
  color: var(--ink);
  background: rgba(255, 62, 200, 0.16);
  border-left-color: var(--magenta);
  text-shadow: 0 0 12px rgba(255, 62, 200, 0.45);
}
.roster td:last-child b { color: var(--ink); font-weight: 500; }

.play {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.4rem 0.55rem;
  padding: 0.7rem 1rem;
  font-size: 0.62rem;
  letter-spacing: 0.1em;
  color: var(--dim);
}
.play .ic { width: 1.1rem; height: 1.1rem; color: var(--lime); }
.play code {
  color: var(--lime);
  background: rgba(182, 255, 61, 0.08);
  border: 1px solid rgba(182, 255, 61, 0.25);
  padding: 0.14rem 0.5rem;
  user-select: all;
}

/* --- the room ---------------------------------------------------------------
   The book has a soundtrack and it is on. docs/chronicle-song.js builds this
   switch itself rather than finding it printed in the page, so a reader with
   the script off is never offered a sound that cannot arrive — same bargain as
   everything else the script does. Top right, out of the way of the dock, and
   small enough that a reader who does not want it never thinks about it. */
.song {
  position: fixed;
  z-index: 6;
  top: clamp(0.4rem, 1.5vw, 0.9rem);
  right: clamp(0.4rem, 1.5vw, 0.9rem);
  display: flex;
  align-items: center;
  gap: 0.45rem;
  padding: 0.36rem 0.62rem;
  font-family: inherit;
  font-size: 0.48rem;
  letter-spacing: 0.26em;
  text-transform: uppercase;
  color: var(--dim);
  background: rgba(7, 3, 15, 0.72);
  border: 1px solid rgba(33, 243, 255, 0.24);
  cursor: pointer;
  backdrop-filter: blur(6px);
}
.song:hover { color: var(--ink); border-color: var(--cyan); }
.song.on {
  color: var(--cyan);
  border-color: rgba(33, 243, 255, 0.65);
  box-shadow: 0 0 18px rgba(33, 243, 255, 0.2);
}
/* Four bars, flat while it is silent, because a meter that moves with nothing
   coming out of the speakers is the kind of decoration this book does not do. */
.eq { display: flex; align-items: flex-end; gap: 2px; height: 0.68rem; }
.eq i { width: 2px; height: 20%; background: currentColor; }
.song.on .eq i { animation: eq 2.1s ease-in-out infinite; }
.song.on .eq i:nth-child(2) { animation-duration: 3.4s; animation-delay: -0.9s; }
.song.on .eq i:nth-child(3) { animation-duration: 2.7s; animation-delay: -1.6s; }
.song.on .eq i:nth-child(4) { animation-duration: 4.1s; animation-delay: -0.4s; }
/* Lit, and waiting for the browser to allow a noise at all. Three classes on
   purpose: this outranks the reduced-motion rule below, which parks the bars
   at the height that means sound is coming out. */
.song.on.waiting .eq i { animation: none; height: 20%; }
@keyframes eq {
  0%, 100% { height: 20%; }
  50% { height: 100%; }
}

/* Below the width where two cels side by side stop being two cels and start
   being two columns of four words, there is one column. */
/* --- the pilots -----------------------------------------------------------
   One page per person, built out of the same furniture as a chapter, because
   it is built out of the same stream: a splash with the face where the plate
   goes, cels, stats, a shelf. Only three things here are new — a bar per mark,
   a board of flights, and a dock that is a shelf of people rather than books. */

/* Every name the book prints is now a way into the rest of what that person
   did. It inherits its colour on purpose: a roster that turned every name cyan
   would read as a table of links rather than as a table of pilots. */
.pl { color: inherit; text-decoration: none; }
.pl:hover, .pl:focus-visible { color: var(--magenta); text-shadow: 0 0 12px currentColor; }
.roster .pl { display: flex; align-items: center; gap: 0.5rem; color: var(--ink); }
.tray-head .pl { color: var(--ink); }

/* A pilot page is eleven cels of nine different shapes, where a chapter is
   five of three — so the row gap a chapter reads well at leaves this one
   looking like one long panel with lines drawn across it. The label of a cel
   sits half out of its own top edge, and that half needs somewhere to be: the
   gap here is the tab's height plus room around it, so no heading is ever
   reading as the last line of the cel above it. */
.page main.who {
  row-gap: clamp(1.9rem, 3.4vh, 2.9rem);
  column-gap: clamp(0.7rem, 1.3vw, 1.15rem);
  padding-top: clamp(1.2rem, 3vh, 2rem);
}
/* The same reason, one level down: every cel here opens with a heading that is
   sitting on the border, so the first thing inside it starts below where that
   heading ends rather than beside it. */
.ch.who > .cel { padding-top: 1.6rem; }
.ch.who .gist { margin-top: 0.2rem; }

/* What they move and what it cost them, side by side and deliberately not the
   same width: nine bars need a bar's worth of room to be read across, three
   tiles and a list of receipts do not. Either one turns up without the other
   often enough — a pilot with a blank ledger, a pilot who has only ever
   mentioned — and then it takes the whole twelve, because half a row with
   nothing beside it is a gap rather than a column. */
.halfwide { grid-column: span 7; }
.halfnarrow { grid-column: span 5; }

/* The face at the size it was painted. Every other page in this book shows it
   at the size of a thumbnail, and a portrait stretched across a splash the way
   a plate is would be a band of colour rather than a person - so this one is
   framed beside the name instead of laid behind it. */
.whois { min-height: clamp(13rem, 30vh, 19rem); }
.whois .say { display: flex; align-items: center; gap: clamp(1rem, 3vw, 2rem); }
.portrait {
  flex: none;
  width: clamp(5rem, 12vw, 8.5rem);
  height: clamp(5rem, 12vw, 8.5rem);
  border-radius: 50%;
  object-fit: cover;
  background: #05010c;
  border: 1px solid rgba(255, 62, 200, 0.6);
  box-shadow: 0 0 30px rgba(255, 62, 200, 0.35), inset 0 0 20px rgba(5, 1, 12, 0.8);
  filter: saturate(1.18) contrast(1.06);
}
.nameplate { min-width: 0; }
.ch.who .credits .badge b { color: var(--amber); }

/* The characterisation, and the badges under it. The paragraph is the one
   place in the book that has an opinion about a person rather than a count of
   them, so it is set at reading size instead of at caption size — and the
   badges are the same pills the marks wear everywhere else, because a reader
   who has learnt one row of them has learnt this one. */
/* A chapter puts one sentence beside six numbers, so the numbers get the wide
   half. This is a paragraph, and a paragraph wants the wide half instead - so
   the two swap over here, and the tiles go two across and three down rather
   than shrinking to a narrower version of the same shape. */
.ch.who .told { grid-column: span 7; }
.ch.who .figures { grid-column: span 5; }
.ch.who .figures .stats { grid-template-columns: repeat(2, minmax(0, 1fr)); }
.ch.who .deed { font-size: clamp(0.8rem, 1.05vw, 0.95rem); line-height: 1.75; }
.ch.who .deed b { color: var(--cyan); font-weight: 500; }
/* The drop cap belongs to a chapter, where the deed is one sentence under a
   plate and the letter is the way in. Six sentences in a five-column cel is a
   paragraph, and a paragraph with a capital the height of four lines in it is
   a poster. */
.ch.who .deed::first-letter { float: none; font-size: inherit; color: inherit;
  padding: 0; line-height: inherit; text-shadow: none; }
.traits { margin-top: 1.15rem; }

/* What somebody keeps moving, as nine bars rather than nine numbers. Each bar
   is measured against that pilot's own busiest mark rather than against
   anybody else's, because this says what kind of pilot they are and not how
   they rank. The colours are the mark colours — .mk carries them, so the pill
   styling is what gets undone here and the palette is not restated. */
.prints { list-style: none; display: grid; gap: 0.3rem; margin-top: 0.9rem; }
.prints .mk {
  display: grid;
  grid-template-columns: 0.9rem minmax(5.5rem, 8rem) minmax(0, 1fr) 2rem;
  align-items: center;
  gap: 0.6rem;
  width: 100%;
  padding: 0.3rem 0.45rem;
  border: 0;
  border-left: 2px solid currentColor;
  border-radius: 0;
  background: rgba(5, 1, 12, 0.4);
}
.prints .mk em { letter-spacing: 0.16em; }
.prints .bar { display: block; height: 0.42rem; background: rgba(160, 75, 255, 0.16); }
.prints .bar i { display: block; height: 100%; background: currentColor; opacity: 0.75; }
.prints b {
  font-size: 0.7rem;
  text-align: right;
  color: var(--ink);
  font-variant-numeric: tabular-nums;
}

/* What a player actually meets: the field-guide tiles that came out of a file
   this pilot created. A file count is a fact about a repository; this is the
   half of somebody that is still being played tonight.

   Three across, because a tile is a card rather than a row: the name, where
   the guide files it, the sentence a player reads and the file it came out of,
   stacked. A single column of these was a list of filenames with headings, and
   sixteen of them was most of the page. */
.tiles {
  list-style: none;
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 0.55rem;
  margin-top: 1rem;
}
/* A column rather than fixed rows, because a tile that never wrote a briefing
   is three children and one that did is four - and the path goes to the foot
   of the card either way. */
.tiles li {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 0.34rem;
  padding: 0.7rem 0.75rem 0.65rem;
  border: 1px solid rgba(33, 243, 255, 0.22);
  border-left: 2px solid var(--cyan);
  background: rgba(33, 243, 255, 0.05);
}
.tiles li:hover { background: rgba(33, 243, 255, 0.1); border-color: rgba(33, 243, 255, 0.45); }
.tiles b { font-size: 0.74rem; letter-spacing: 0.16em; color: var(--cyan); }
.tiles span {
  font-size: 0.5rem;
  letter-spacing: 0.24em;
  text-transform: uppercase;
  color: var(--dim);
  justify-self: start;
}
/* The briefing, cut short by briefly() rather than by a line clamp: a sentence
   that stops at a word somebody chose reads better than one a box cut off. */
.tiles em {
  font-style: normal;
  font-size: 0.6rem;
  line-height: 1.65;
  color: var(--ink);
  text-wrap: pretty;
}
.tiles i {
  margin-top: auto;
  padding-top: 0.15rem;
  font-style: normal;
  font-size: 0.5rem;
  letter-spacing: 0.06em;
  color: var(--dim);
  opacity: 0.75;
  overflow-wrap: anywhere;
}

/* The ambush they armed the room with. GR11 has no override on it, so this is
   the one section on the page that is about a rule rather than about a record. */
.traps { list-style: none; display: grid; gap: 0.5rem; margin-top: 0.9rem; }
.traps li {
  display: grid;
  gap: 0.24rem;
  padding: 0.6rem 0.7rem;
  border: 1px solid rgba(255, 62, 200, 0.35);
  background: rgba(255, 62, 200, 0.06);
}
.traps b { font-size: 0.8rem; letter-spacing: 0.2em; color: var(--magenta); }
.traps span { font-size: 0.6rem; letter-spacing: 0.12em; color: var(--ink); }
.traps i {
  font-style: normal;
  font-size: 0.54rem;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: var(--dim);
}

/* Their flights, straight off the board, and the meter underneath read from
   tools/flights.sh rather than counted here. */
.board { width: 100%; border-collapse: collapse; margin-top: 0.9rem; font-size: 0.62rem; }
.board th {
  text-align: left;
  font-weight: 400;
  letter-spacing: 0.18em;
  color: var(--dim);
  padding: 0.3rem 0.4rem;
}
.board td {
  padding: 0.42rem 0.4rem;
  border-top: 1px solid rgba(160, 75, 255, 0.18);
  color: var(--ink);
  font-variant-numeric: tabular-nums;
  vertical-align: top;
}
.board td:nth-child(2) { color: var(--amber); }
.board td:last-child { color: var(--dim); letter-spacing: 0.02em; }
.meter {
  margin-top: 0.8rem;
  font-size: 0.6rem;
  letter-spacing: 0.1em;
  color: var(--dim);
}
.meter b { color: var(--amber); }

/* The receipts under the ledger. The count is tools/tally.sh's answer and sits
   in the tiles above; these are the chapters where the reasons are, because a
   page that printed the number and hid the reasons would be worse than one
   that printed neither. */
.receipts { list-style: none; display: grid; gap: 3px; margin-top: 0.9rem; }
.receipts a, .receipts .norec {
  display: grid;
  grid-template-columns: 2.6rem minmax(0, 1fr) auto;
  align-items: baseline;
  gap: 0.7rem;
  padding: 0.42rem 0.55rem;
  background: rgba(255, 176, 32, 0.07);
  border-left: 2px solid var(--amber);
  color: var(--ink);
  text-decoration: none;
}
.receipts a:hover { background: rgba(255, 176, 32, 0.16); }
.receipts b { color: var(--amber); font-size: 0.66rem; letter-spacing: 0.1em; }
.receipts span { font-size: 0.6rem; color: var(--ink); }
.receipts i {
  font-style: normal;
  font-size: 0.5rem;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  color: var(--dim);
  white-space: nowrap;
}

/* The cabinet is shared, and this is the only place on the page that says so. */
.visits { list-style: none; display: grid; gap: 0.35rem; margin-top: 0.9rem; }
.visits li {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.3rem 0.7rem;
  padding: 0.42rem 0.55rem;
  border-left: 2px solid var(--violet);
  background: rgba(160, 75, 255, 0.08);
}
.visits .pl { font-size: 0.66rem; letter-spacing: 0.14em; color: var(--ink); }
/* A name in running prose brings its face with it, and there it has to be the
   size of the words rather than the size of a portrait. */
.gist .pl, .visits .pl { display: inline-flex; align-items: center; gap: 0.3rem; }
.gist .pl .face, .visits .pl .face { width: 1.3rem; height: 1.3rem; }
.visits span { font-size: 0.56rem; letter-spacing: 0.08em; color: var(--dim); }

/* A run of Chronicle lines is a portrait nobody sat for. */
.quotes { list-style: none; display: grid; gap: 0.5rem; margin-top: 0.9rem; }
.quotes li { display: grid; grid-template-columns: 2.6rem minmax(0, 1fr); gap: 0.7rem; align-items: baseline; }
.quotes a { color: var(--cyan); text-decoration: none; font-size: 0.66rem; letter-spacing: 0.1em; }
.quotes q { font-size: 0.68rem; line-height: 1.6; color: var(--ink); quotes: "\201C" "\201D"; }

/* The dock, and on a pilot page the shelf in it is a shelf of people. Same
   furniture, same corner of the window, one press to anybody else the cabinet
   has ever heard of. */
.whodock .spine { min-width: 8.5rem; }
.whodock .spine .nm {
  max-width: none;
  font-size: 0.56rem;
  letter-spacing: 0.14em;
  color: var(--ink);
}
.whodock .spine .sp i {
  font-style: normal;
  font-size: 0.5rem;
  letter-spacing: 0.16em;
  color: var(--cyan);
  font-variant-numeric: tabular-nums;
}
.whodock .spine[aria-current="page"] { border-color: var(--magenta); }

@media (max-width: 62rem) {
  .told, .figures, .frame, .margin { grid-column: span 12; }
  /* said again at the specificity the pilot page swapped them over at, because
     a media query does not outrank a longer selector */
  .ch.who .told, .ch.who .figures { grid-column: span 12; }
  /* the pair stops being a pair before either half gets narrow enough that a
     nine-letter mark and its bar are fighting over the same inch */
  .halfwide, .halfnarrow { grid-column: span 12; }
  .tiles { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  .shout { max-width: none; }
  /* the sentence takes the whole width down here, so the corner it was
     keeping clear is gone: the credits fall back under it, still to the right */
  .credits {
    position: static;
    margin-top: 0.9rem;
  }
  .stats { grid-template-columns: repeat(2, minmax(0, 1fr)); }
}
/* Narrow enough that the words on the two buttons are competing with the
   thumbnails for the same inch, and the arrows say it on their own. */
@media (max-width: 46rem) {
  .turn { padding: 0.3rem 0.5rem; }
  .turn .lab i { display: none; }
  .turn .lab b { font-size: 0.66rem; }
  .turn.none .lab { display: none; }
  .up i { display: none; }
  .up { padding: 0 0.45rem; }
  /* the face and the numeral say whose book it is; the name spelled out is
     the first thing that can go */
  .spine .nm { display: none; }
  /* except in the roster, where it is the only thing that says anything. A
     book has a numeral and a plate; a pilot has a portrait that was painted
     from a description and a name that is the whole of who they are, so the
     dock on a pilot page keeps the words and loses the picture instead. */
  .whodock .spine .nm { display: block; }
  .whodock .spine .face { display: none; }
  .whodock .spine { min-width: 0; }
}
@media (max-width: 34rem) {
  /* the bars say it on their own, the same way the arrows do */
  .song .lab { display: none; }
  .song { padding: 0.4rem 0.5rem; }
  .roster table { font-size: 0.62rem; }
  /* The marks stop being a column and become a row of their own, under the
     words they are about. A column of icons costs a quarter of the width here,
     and it takes it off the one thing on the row anybody is reading - which is
     how a four-word tagline ended up set over three lines beside two pictures. */
  .cv a { grid-template-columns: 2.9rem minmax(0, 1fr); gap: 0.35rem 0.5rem; }
  .cv .marks { grid-column: 2; justify-content: flex-start; }
  .ci { padding-left: 0.3rem; grid-template-columns: minmax(0, 1fr); }
  .ci .marks { grid-column: 1; grid-row: auto; justify-content: flex-start; }
  .book > summary { gap: 0.4rem 0.6rem; padding: 0.6rem; }
  .by .face { width: 1.7rem; height: 1.7rem; }
  .gist, .book .contents { margin-inline: 0.6rem; padding-inline: 0; }
  /* padding-inline: 0 above takes the words up against the rule in the margin,
     and the rule is what says this is an aside rather than a paragraph */
  .gist { padding-left: 0.6rem; }
  .leaf { grid-template-columns: 2.6rem 2.2rem minmax(0, 1fr) auto; gap: 0.5rem; }
  /* four stacked lines is a lot of corner on a phone; tightened up they are
     still four lines somebody can read at a glance */
  .credits { gap: 0.28rem; }
  .stats { grid-template-columns: 1fr 1fr; }
  .stats span { font-size: 0.44rem; }
  .turn .lab { display: none; }
  .spine { padding: 0 0.35rem; gap: 0.3rem; }
  .spine .face { display: none; }
  /* A phone reads a pilot page as one column of eleven cels, one under the
     next, and at that width the gap between two of them is the only thing
     saying they are two. It is the tab's own height again, plus the room a
     thumb needs to not think they are one panel. */
  .page main.who { row-gap: 2.3rem; }
  .ch.who > .cel { padding: 1.7rem 0.9rem 1.15rem; }
  .tiles { grid-template-columns: minmax(0, 1fr); }
  .traits { gap: 0.3rem; }
  /* nine marks against a bar and a number is four columns too many here: the
     bar goes and the number does the saying */
  .prints .mk { grid-template-columns: 0.9rem minmax(0, 1fr) 2rem; gap: 0.5rem; }
  .prints .bar { display: none; }
  .board { font-size: 0.56rem; }
  .board th:nth-child(4), .board td:nth-child(4),
  .board th:nth-child(5), .board td:nth-child(5) { display: none; }
}
@media (prefers-reduced-motion: reduce) {
  h1, .shout, .roster, .art *, .dots, .plate-img, .loud, .loud::before { animation: none; }
  .js .cel { opacity: 1; transform: none; transition: none; }
  /* the plate still opens, it just does not fly there */
  .lit { transition: none; }
  /* the sound plays, the meter holds still - it was only ever saying so */
  .song.on .eq i { animation: none; height: 60%; }
  /* the book still opens, the arrow just points the other way at once */
  .book > summary::before { transition: none; }
  .leaf .thumb img { transition: none; }
}
CSS

# --- the room it is read in --------------------------------------------------
#
# The book's soundtrack, written the way everything else here is written: no
# audio file, no fetch, no dependency (GR2), just oscillators and a noise
# buffer. It is off until a reader asks for it and it says so in the file
# itself. Emitted from here rather than kept beside the pages for the same
# reason docs/chronicle.css is: the book is generated, all of it, so a clone
# that runs this tool has the whole book and not most of one.
cat > docs/chronicle-song.js <<'JS'
/* THE ROOM THE BOOK IS READ IN.
   Generated by tools/chronicle.sh. Editing it by hand lasts until the next
   commit; the copy that matters is the heredoc in that script.

   The cabinet is loud. The book is not, so this is not the cabinet's band
   playing quieter — it is the other end of the same evening: one chord every
   eight seconds, a heartbeat you only notice when it stops, and an arpeggio
   several rooms away. Fifty-six beats a minute, which is slower than reading.

   Three things about it are deliberate and one of them is the whole point.

   It comes up on, and it does not start over. The room is playing unless the
   reader says otherwise, and the switch remembers an off for as long as they
   want one. What it will not do is make a noise on a page nobody has touched
   yet — that is the browser's rule and it is a good one — so the switch comes
   up lit and the room waits for the next click or arrow key, which on this
   book is the same keystroke that turned the page. And turning a page is not
   stopping the music: the step the piece had got to rides along in the tab's
   own storage with the time it was true at, so the next chapter comes in
   where the piece would be by now rather than at the top of it.

   It is written, not stored. Same reason as everything else here (GR2): no
   audio file, no fetch, no dependency — an oscillator, a filter, and a noise
   buffer folded into a reverb. The whole soundtrack is this file, and this
   file opens from a USB stick in ten years.

   It costs nothing to leave on. Nothing here runs per frame. A timer wakes up
   four times a second, schedules the next second and a half into the audio
   clock, and goes back to sleep; the browser's audio thread does the rest at
   its own pace. A page with the sound on scrolls exactly as fast as one
   without it.

   And it is visible. A ring of light fades and scales up in the panel the
   chapter opens with, off to the side of the sentence, where it hangs and
   drifts and answers the music. It is drawn off a tap in the graph, so what
   it answers is what is coming out rather than a clock. Off is the same
   backwards.

   Each chapter gets its own key and its own progression, off its own number,
   so v3 always sounds like v3 — and where the reader arrives from somewhere
   else in the book, the harmony changes under a piece that keeps its place.
   The chapter's own offset into the progression is only where it begins when
   nobody arrived from anywhere: the first page of a sitting.

   And every third chapter has a music box in the room with it, wound once a
   cycle. Twice a minute at the outside, off the chord, gone before it has
   outstayed anything — a reader who never works out which pages have it just
   finds some of them nicer than the others. */

(function () {
  "use strict";

  var Ctx = window.AudioContext || window.webkitAudioContext;
  if (!Ctx) return;

  // ---- the tempo ----------------------------------------------------------
  // A step is an eighth note and it is the smallest thing in here, which at
  // this tempo is over half a second. Everything else is counted in steps.

  var BPM = 56;
  var STEP = 30 / BPM;          // 0.536s
  var BAR = STEP * 8;
  var CHORD = BAR * 2;          // one chord is two bars, and it feels like it
  var CYCLE = 64;               // steps in the whole progression: 34 seconds
  var LEVEL = 0.34;             // the ceiling, reached over four seconds

  // ---- which chapter ------------------------------------------------------
  // The cover is chapter zero and gets A minor, which is the house key.

  var m = /v(\d+)\.html/.exec(location.pathname);
  var CH = m ? +m[1] : 0;

  // Deterministic per page: the same chapter makes the same choices in the
  // same order forever, so a reader who comes back recognises the room.
  function seeded(a) {
    return function () {
      a |= 0; a = a + 0x6d2b79f5 | 0;
      var t = Math.imul(a ^ a >>> 15, 1 | a);
      t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
      return ((t ^ t >>> 14) >>> 0) / 4294967296;
    };
  }
  var rnd = seeded(CH * 2654435761 + 7);

  // ---- the harmony --------------------------------------------------------
  // Roots are MIDI, same as src/audio/themes.js, and picked so no two chapters
  // in a row share one. A chord is an offset from the key and a voicing; the
  // offsets above a tritone drop an octave, which is what keeps the pad from
  // leaping about between chords.

  var KEYS = [45, 40, 47, 42, 38, 44, 41, 36, 46, 43];
  var VOICES = {
    min9: [0, 3, 7, 14],
    min7: [0, 3, 7, 10],
    maj7: [0, 4, 7, 11],
    maj9: [0, 4, 7, 14],
    sus2: [0, 2, 7, 12],
    sus4: [0, 5, 7, 12]
  };
  var PROGS = [
    [[0, "min9"], [8, "maj7"], [3, "maj9"], [10, "sus2"]],   // i VI III VII
    [[0, "min7"], [10, "sus2"], [8, "maj9"], [10, "maj7"]],  // i VII VI VII
    [[0, "min9"], [5, "min7"], [8, "maj7"], [7, "sus4"]],    // i iv VI v
    [[8, "maj9"], [10, "sus2"], [0, "min9"], [0, "min7"]],   // VI VII i i
    [[0, "min7"], [3, "maj9"], [8, "maj7"], [5, "min7"]]     // i III VI iv
  ];
  // Where in the two bars the arpeggio lands. Never on every beat: the gaps
  // are the atmosphere and the notes are only there to prove there is a key.
  var ARPS = [
    [0, 3, 6, 10, 13],
    [2, 5, 8, 11, 14],
    [0, 4, 7, 12],
    [1, 3, 8, 10, 15]
  ];

  var key = KEYS[CH % KEYS.length];
  var prog = PROGS[CH % PROGS.length];
  var arps = ARPS[CH % ARPS.length];

  function mtof(n) { return 440 * Math.pow(2, (n - 69) / 12); }
  function chord(i) {
    var c = prog[i % 4], off = c[0];
    if (off > 6) off -= 12;
    return { root: key + off, voice: VOICES[c[1]] };
  }
  // The bass note is the chord's, folded into one octave and kept there. Off a
  // low enough key the arithmetic otherwise arrives at thirty-six hertz, which
  // is not a note on a laptop, it is a hum on somebody's desk.
  function low(root) {
    var n = root - 12;
    while (n < 31) n += 12;
    while (n > 42) n -= 12;
    return n;
  }

  // ---- the rig ------------------------------------------------------------
  // Built once, the first time somebody asks for sound, and kept. Four places
  // to send a voice: dry, the plate reverb, the echo, and the chorus the pad
  // alone goes through.

  var ctx = null, out = null, dry = null, send = null, echo = null, wide = null;
  var noise = null, timer = null, air = null, eye = null;
  var playing = false, at = 0, step = (CH % 4) * 16, noted = -9;

  // A context made at the foot of this file to ask the browser a question, and
  // kept in case the answer was no. Nothing is built on it until it can run —
  // every oscillator started on a context the browser has parked is another
  // line of it saying so in the reader's console, and no music either way.
  var spare = null;

  function build() {
    ctx = spare || new Ctx();
    spare = null;

    // A gentle ceiling rather than a loud mix. Nothing in here should ever be
    // the loudest thing on somebody's desk.
    var lid = ctx.createDynamicsCompressor();
    lid.threshold.value = -20;
    lid.knee.value = 26;
    lid.ratio.value = 4;
    lid.attack.value = 0.02;
    lid.release.value = 0.45;
    lid.connect(ctx.destination);

    out = ctx.createGain();
    out.gain.value = 0;
    // Everything the room makes goes past a tap on its way to the ceiling, so
    // the ring in the chapter's opening panel is drawing the music rather than
    // a picture of music. An analyser is a pass-through: it is heard by nobody,
    // it changes nothing, and it sits in the path rather than hanging off it
    // so the browser has a reason to keep filling it.
    eye = ctx.createAnalyser();
    eye.fftSize = 1024;
    // Its own smoothing, before the orb does any of its own. Between the two
    // of them a band answers a note rather than answering a frame.
    eye.smoothingTimeConstant = 0.75;
    out.connect(eye);
    eye.connect(lid);

    dry = ctx.createGain();
    dry.gain.value = 0.9;
    dry.connect(out);

    // The plate. Noise under an exponential decay, run through a one-pole
    // lowpass on the way into the buffer so the tail is dark rather than
    // fizzy — a bright reverb on a page of text reads as a fault.
    var verb = ctx.createConvolver();
    verb.buffer = plate(3.8);
    var vLo = ctx.createBiquadFilter();
    vLo.type = "lowpass";
    vLo.frequency.value = 2600;
    send = ctx.createGain();
    send.gain.value = 0.5;
    send.connect(verb);
    verb.connect(vLo);
    vLo.connect(out);

    // A dotted eighth, which at this tempo is four fifths of a second, damped
    // a little more on every pass so it walks away rather than stops.
    var d = ctx.createDelay(2);
    d.delayTime.value = STEP * 1.5;
    var fb = ctx.createGain();
    fb.gain.value = 0.42;
    var dLo = ctx.createBiquadFilter();
    dLo.type = "lowpass";
    dLo.frequency.value = 2000;
    echo = ctx.createGain();
    echo.gain.value = 0.34;
    echo.connect(d);
    d.connect(dLo);
    dLo.connect(fb);
    fb.connect(d);
    dLo.connect(out);
    dLo.connect(send);

    wide = chorus();
    noise = hiss(3);
    room();
  }

  // The impulse: two channels of noise, decaying, slightly different, with a
  // few milliseconds of nothing at the front so the reverb arrives after the
  // note rather than with it.
  function plate(secs) {
    var n = Math.floor(ctx.sampleRate * secs);
    var pre = Math.floor(ctx.sampleRate * 0.03);
    var buf = ctx.createBuffer(2, n, ctx.sampleRate);
    for (var c = 0; c < 2; c++) {
      var d = buf.getChannelData(c), last = 0;
      for (var i = pre; i < n; i++) {
        var k = (i - pre) / (n - pre);
        last += 0.22 * ((Math.random() * 2 - 1) - last);
        d[i] = last * Math.pow(1 - k, 3.4);
      }
    }
    return buf;
  }

  function hiss(secs) {
    var n = Math.floor(ctx.sampleRate * secs);
    var buf = ctx.createBuffer(2, n, ctx.sampleRate);
    for (var c = 0; c < 2; c++) {
      var d = buf.getChannelData(c);
      for (var i = 0; i < n; i++) d[i] = Math.random() * 2 - 1;
    }
    return buf;
  }

  // Two short modulated delays, one per ear, which is the cheapest way there
  // is to make four sawtooths sound like they are in a room together.
  function chorus() {
    var input = ctx.createGain();
    input.connect(dry);
    for (var i = 0; i < 2; i++) {
      var d = ctx.createDelay(0.1);
      d.delayTime.value = 0.013 + i * 0.008;
      var lfo = ctx.createOscillator();
      lfo.type = "sine";
      lfo.frequency.value = 0.11 + i * 0.06;
      var amt = ctx.createGain();
      amt.gain.value = 0.0035;
      lfo.connect(amt);
      amt.connect(d.delayTime);
      lfo.start();
      input.connect(d);
      d.connect(pan(i ? 0.55 : -0.55)).connect(out);
    }
    return input;
  }

  function pan(x) {
    if (!ctx.createStereoPanner) return ctx.createGain();
    var p = ctx.createStereoPanner();
    p.pan.value = x;
    return p;
  }

  // The floor under everything: tape hiss that swells on its own clock, and a
  // low wind that has no clock at all. Started once and never stopped — it is
  // what makes the gaps between the chords sound like a place.
  function room() {
    var h = ctx.createBufferSource();
    h.buffer = noise;
    h.loop = true;
    var bp = ctx.createBiquadFilter();
    bp.type = "bandpass";
    bp.frequency.value = 1500;
    bp.Q.value = 0.4;
    var hg = ctx.createGain();
    hg.gain.value = 0.02;
    var swell = ctx.createOscillator();
    swell.frequency.value = 0.043;
    var sa = ctx.createGain();
    sa.gain.value = 0.013;
    swell.connect(sa);
    sa.connect(hg.gain);
    swell.start();
    h.connect(bp);
    bp.connect(hg);
    hg.connect(out);
    h.start();

    var w = ctx.createBufferSource();
    w.buffer = noise;
    w.loop = true;
    w.playbackRate.value = 0.7;
    var lo = ctx.createBiquadFilter();
    lo.type = "lowpass";
    lo.frequency.value = 240;
    lo.Q.value = 1.4;
    var drift = ctx.createOscillator();
    drift.frequency.value = 0.017;
    var da = ctx.createGain();
    da.gain.value = 90;
    drift.connect(da);
    da.connect(lo.frequency);
    drift.start();
    var wg = ctx.createGain();
    wg.gain.value = 0.055;
    w.connect(lo);
    lo.connect(wg);
    wg.connect(out);
    wg.connect(send);
    w.start();
    air = h;
  }

  // ---- the voices ---------------------------------------------------------

  // Two sawtooths seven cents apart, opened and closed again over the length
  // of the chord. The filter is doing most of the work; the notes are only
  // there to tell it which chord it is being atmospheric about.
  function pad(t, f, dur, amp) {
    var g = ctx.createGain();
    var lp = ctx.createBiquadFilter();
    lp.type = "lowpass";
    lp.Q.value = 0.9;
    lp.frequency.setValueAtTime(340, t);
    lp.frequency.linearRampToValueAtTime(1500, t + dur * 0.55);
    lp.frequency.linearRampToValueAtTime(480, t + dur + 3);
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(amp, t + 2.4);
    g.gain.setValueAtTime(amp, t + dur);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur + 3.2);
    for (var i = 0; i < 2; i++) {
      var o = ctx.createOscillator();
      o.type = "sawtooth";
      o.frequency.value = f;
      o.detune.value = i ? 7 : -7;
      o.connect(lp);
      o.start(t);
      o.stop(t + dur + 3.4);
    }
    lp.connect(g);
    g.connect(wide);
    g.connect(send);
  }

  // One note, held under the whole chord, with a second an octave up quiet
  // enough that it only tells you which note it was.
  function bass(t, f, dur) {
    var g = ctx.createGain();
    var lp = ctx.createBiquadFilter();
    lp.type = "lowpass";
    lp.frequency.value = 300;
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(0.3, t + 0.9);
    g.gain.setValueAtTime(0.3, t + dur - 0.6);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur + 1.4);
    var a = ctx.createOscillator();
    a.type = "triangle";
    a.frequency.value = f;
    var b = ctx.createOscillator();
    b.type = "sine";
    b.frequency.value = f * 2;
    var bg = ctx.createGain();
    bg.gain.value = 0.22;
    a.connect(lp);
    b.connect(bg);
    bg.connect(lp);
    lp.connect(g);
    g.connect(dry);
    a.start(t); a.stop(t + dur + 1.6);
    b.start(t); b.stop(t + dur + 1.6);
  }

  // The arpeggio, several rooms away: a square through a filter that shuts
  // behind it, most of it arriving as echo rather than as note.
  function pluck(t, f, amp) {
    var g = ctx.createGain();
    var lp = ctx.createBiquadFilter();
    lp.type = "lowpass";
    lp.Q.value = 7;
    lp.frequency.setValueAtTime(Math.min(9000, f * 7), t);
    lp.frequency.exponentialRampToValueAtTime(Math.max(220, f * 1.1), t + 0.5);
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(amp, t + 0.014);
    g.gain.exponentialRampToValueAtTime(0.0001, t + 1.2);
    var o = ctx.createOscillator();
    o.type = "square";
    o.frequency.value = f;
    o.connect(lp);
    lp.connect(g);
    g.connect(dry);
    g.connect(echo);
    g.connect(send);
    o.start(t);
    o.stop(t + 1.3);
  }

  // A sine and its third partial, high up, all tail. This is the one thing in
  // the piece that is allowed to sound like a melody, and it gets four notes a
  // minute to do it in.
  function bell(t, f, amp) {
    var g = ctx.createGain();
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(amp, t + 0.05);
    g.gain.exponentialRampToValueAtTime(0.0001, t + 4.2);
    var a = ctx.createOscillator();
    a.frequency.value = f;
    var b = ctx.createOscillator();
    b.frequency.value = f * 3.01;
    var bg = ctx.createGain();
    bg.gain.value = 0.16;
    a.connect(g);
    b.connect(bg);
    bg.connect(g);
    g.connect(dry);
    g.connect(send);
    g.connect(echo);
    a.start(t); a.stop(t + 4.4);
    b.start(t); b.stop(t + 4.4);
  }

  // The heartbeat. Not a drum — nothing here keeps time for anybody — just a
  // low thump under the bar so the room has a pulse to it.
  function pulse(t, amp) {
    var g = ctx.createGain();
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(amp, t + 0.012);
    g.gain.exponentialRampToValueAtTime(0.0001, t + 0.85);
    var o = ctx.createOscillator();
    o.frequency.setValueAtTime(82, t);
    o.frequency.exponentialRampToValueAtTime(38, t + 0.18);
    o.connect(g);
    g.connect(dry);
    o.start(t);
    o.stop(t + 0.9);
  }

  // Noise climbing a filter into the turn of the progression. The one gesture
  // in here that a synthwave record would recognise.
  function sweep(t, dur) {
    var s = ctx.createBufferSource();
    s.buffer = noise;
    s.loop = true;
    var bp = ctx.createBiquadFilter();
    bp.type = "bandpass";
    bp.Q.value = 1.6;
    bp.frequency.setValueAtTime(300, t);
    bp.frequency.exponentialRampToValueAtTime(4200, t + dur);
    var g = ctx.createGain();
    g.gain.setValueAtTime(0.0001, t);
    g.gain.linearRampToValueAtTime(0.05, t + dur * 0.8);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur + 0.6);
    s.connect(bp);
    bp.connect(g);
    g.connect(dry);
    g.connect(send);
    s.start(t);
    s.stop(t + dur + 0.7);
  }

  // ---- the visitor --------------------------------------------------------
  // Every chapter already has its own key and its own progression. Every third
  // one gets a thing more: a music box, wound and let go once a cycle. It is
  // the only voice in here allowed to be conspicuous — brighter than the pad,
  // quicker than anything else, and it ends on a note it holds rather than on a
  // note it resolves.
  //
  // Once every half minute is the entire discipline. A charm that arrives every
  // bar is a ringtone; one that arrives while somebody is halfway down a
  // paragraph is a thing they look up for, and looking up is the whole point of
  // it. It is built off the chord it lands in, so it can be the loudest idea in
  // the piece for a second and a half and still not be an interruption.
  //
  // One page in three, which is the rate a reader can feel. Rarer and it is a
  // rumour; commoner and it is the house style. The cover is chapter zero and
  // divides by everything, so it is left out by hand: it is not a third
  // chapter, it is not a chapter.
  var BOXED = CH > 0 && CH % 3 === 0;

  // How many notes, which is the chapter's own business and does not change:
  // v3 has four of them, v6 five, v9 three, and round again from there.
  var NOTES = 3 + Math.floor(CH / 3) % 3;

  // Where it sits. The figure is built off whatever chord it lands in, and some
  // keys put the top of it two octaves over the rest of the piece, so the whole
  // thing is folded down under a ceiling — in one piece, because folding a
  // single note out of a climb makes it something other than a climb, and by
  // one amount for the whole chapter, worked out off the highest chord in the
  // progression, because a charm that changes register between one cycle and
  // the next is two charms.
  //
  // C7 is where a music box stops being charming and starts being a smoke
  // alarm, and it is the partial rather than the note that gets there first.
  var CEIL = 96;

  function ceiling() {
    var top = 0, d = 0, i, c, li = NOTES - 1;
    for (i = 0; i < 4; i++) {
      c = chord(i);
      top = Math.max(top, c.root + 42 + c.voice[li % c.voice.length] +
                          12 * Math.floor(li / c.voice.length));
    }
    while (top - d > CEIL) d += 12;
    return d;
  }
  var DROP = ceiling();

  // Where in the cycle it lands, and it moves: four spots, one per time round,
  // three different chords between them, and none of them on the turn of a
  // chord or on the beat the heart is on. A charm that arrives in the same
  // place every time stops being a charm and becomes a clock.
  //
  // Four boxes to four cycles is fixed arithmetic, so spreading them out is
  // only ever a choice about which waits are long: these are twenty-four to
  // forty-three seconds apart, which is as even as it gets without putting the
  // thing in the same corner every time.
  var SPOTS = [10, 26, 42, 22];

  // One tine. A sine, a twelfth above it that dies well before it does — which
  // is most of what makes struck metal sound struck — and a filter closing over
  // the tail so the note darkens as it goes instead of only getting quieter.
  function tine(t, f, amp, hold) {
    var g = ctx.createGain();
    var lp = ctx.createBiquadFilter();
    lp.type = "lowpass";
    lp.frequency.setValueAtTime(Math.min(12000, f * 6), t);
    lp.frequency.exponentialRampToValueAtTime(Math.max(400, f * 1.4), t + hold);
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(amp, t + 0.008);
    g.gain.exponentialRampToValueAtTime(0.0001, t + hold);
    var a = ctx.createOscillator();
    a.frequency.value = f;
    var b = ctx.createOscillator();
    b.frequency.value = f * 3.02;
    var bg = ctx.createGain();
    bg.gain.setValueAtTime(0.42, t);
    bg.gain.exponentialRampToValueAtTime(0.0001, t + hold * 0.3);
    a.connect(lp);
    b.connect(bg);
    bg.connect(lp);
    lp.connect(g);
    g.connect(dry);
    g.connect(send);
    // The dotted-eighth echo makes a run of these sound like a box in a room.
    // The note that hangs stays out of it — repeating a three-second tail four
    // times is not a charm, it is a fault.
    if (hold < 2) g.connect(echo);
    a.start(t); a.stop(t + hold + 0.1);
    b.start(t); b.stop(t + hold + 0.1);
  }

  // The winding: three clicks of filtered noise, a mechanism rather than a
  // note. It is what tells a reader that something is about to happen, and it
  // is quiet enough that a reader who misses it has lost nothing. Each click
  // starts somewhere else in the buffer, because three copies of the same three
  // milliseconds is one click stuttering.
  function cog(t, from) {
    var s = ctx.createBufferSource();
    s.buffer = noise;
    var hp = ctx.createBiquadFilter();
    hp.type = "highpass";
    hp.frequency.value = 2800;
    var g = ctx.createGain();
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(0.022, t + 0.003);
    g.gain.exponentialRampToValueAtTime(0.0001, t + 0.05);
    s.connect(hp);
    hp.connect(g);
    g.connect(dry);
    g.connect(send);
    s.start(t, from);
    s.stop(t + 0.08);
  }

  // The figure. Notes off the chord, climbing, a third of a step apart so it
  // arrives faster than anything else in the piece, and the last one thrown an
  // octave over the rest and left ringing.
  function box(t, c) {
    for (var w = 0; w < 3; w++) cog(t + w * 0.085, 0.11 + w * 0.43);
    for (var i = 0; i < NOTES; i++) {
      var deg = c.voice[i % c.voice.length] + 12 * Math.floor(i / c.voice.length);
      var last = i === NOTES - 1;
      tine(t + 0.42 + i * STEP / 3,
           mtof(c.root + 30 + deg + (last ? 12 : 0) - DROP),
           last ? 0.07 : 0.05,
           last ? 3.4 : 1.1);
    }
  }

  // ---- the arrangement ----------------------------------------------------
  // Four chords, and then the same four chords again with something different
  // switched on. A cycle is thirty-four seconds, so a reader who stays for one
  // chapter hears three or four of them and never quite the same one twice.

  function plan(i, t) {
    var n = ((i % CYCLE) + CYCLE) % CYCLE;
    var cyc = Math.floor(i / CYCLE);
    var pos = n % 16;
    var c = chord(Math.floor(n / 16));
    var lift = cyc % 4 === 3 ? 12 : 0;   // every fourth time round, up an octave
    var thin = cyc % 4 === 0;            // and every fourth time round, it steps back

    if (pos === 0) {
      for (var v = 0; v < c.voice.length; v++)
        pad(t, mtof(c.root + 12 + lift + c.voice[v]), CHORD, 0.055);
      bass(t, mtof(low(c.root)), CHORD);
    }
    if (!thin && (pos === 0 || pos === 8)) pulse(t, pos ? 0.1 : 0.16);
    // Stepping back is not stopping: the arpeggio keeps its first note of each
    // chord, so the thin cycles still have somewhere to be rather than sounding
    // like the sound came off.
    for (var a = 0; a < arps.length; a++)
      if (arps[a] === pos && (!thin || a === 0)) {
        var deg = c.voice[(a + cyc) % c.voice.length];
        pluck(t, mtof(c.root + 24 + deg + (rnd() < 0.22 ? 12 : 0)), 0.075);
      }
    if (cyc > 0 && pos === 12 && rnd() < 0.4)
      bell(t, mtof(c.root + 36 + c.voice[Math.floor(rnd() * 4)]), 0.05);
    if (cyc % 2 === 1 && n === 60) sweep(t, 2.1);
    // The thin cycle is where the box has the most room, so it is not spared
    // the way the pulse and the arpeggio are.
    if (BOXED && n === SPOTS[cyc % SPOTS.length]) box(t, c);
  }

  // Wake up four times a second, fill the next second and a half of the audio
  // clock, go back to sleep. Everything above happens on that thread, not this
  // one, which is why a page with the sound on scrolls like a page without it.
  function tick() {
    var now = ctx.currentTime;
    // A tab nobody is looking at gets its timers throttled to one a minute,
    // and comes back owing the audio clock a minute of music. Scheduling that
    // in the past means playing it all at once, so the piece skips the wait
    // instead and comes back in phase, in the middle of wherever it got to.
    if (at < now) {
      var skip = Math.ceil((now - at) / STEP);
      step += skip;
      at += skip * STEP;
    }
    var horizon = now + 1.6;
    while (at < horizon) {
      plan(step, at);
      step++;
      at += STEP;
    }
    // The next page needs to know where this one got to. Storage does not
    // need telling four times a second to answer that; twice every three
    // seconds is closer than a page turn will ever notice.
    if (now - noted > 1.5) { noted = now; keep(); }
  }

  // ---- on and off ---------------------------------------------------------

  var KEY = "hypercolor.room";
  function remember(v) { try { localStorage.setItem(KEY, v); } catch (e) {} }
  function remembered() { try { return localStorage.getItem(KEY); } catch (e) { return null; } }

  // Where the piece got to, and when that was true. It goes in the tab's own
  // storage and not the browser's, because this is one sitting rather than a
  // habit, and a second window is a second room. What comes back is not the
  // step it left off on but the step it would be on now — the room keeps
  // playing while the page loads, the same way it keeps playing while a
  // chapter is read. Past ten minutes of nothing that stops being true and
  // the chapter starts where its own number says.
  var POS = "hypercolor.room.at";
  var CARRY = 600;

  function keep() {
    if (!timer) return;   // nothing is running, so there is no middle to be in
    // step and at are the front of the scheduling horizon, up to a second and
    // a half ahead of anything anybody can hear. What gets written down is
    // where the piece is, not where the scheduler has run on to.
    var here = step - (at - ctx.currentTime) / STEP;
    try { sessionStorage.setItem(POS, Math.round(here) + " " + Date.now()); } catch (e) {}
  }

  function carried() {
    var s;
    try { s = sessionStorage.getItem(POS); } catch (e) { return null; }
    if (!s) return null;
    var p = s.split(" "), n = +p[0], gap = (Date.now() - +p[1]) / 1000;
    if (!isFinite(n) || !isFinite(gap) || gap < 0 || gap > CARRY) return null;
    return Math.round(n + gap / STEP);
  }

  function on() {
    if (!ctx) build();
    playing = true;
    mark();
    remember("on");
    var p = ctx.resume();
    if (p && p.then) p.then(armed, armed); else armed();
  }

  // A page reached by clicking a link has no permission to make a noise yet,
  // however clearly the reader said so on the page before. So if the context
  // will not start, wait for the next thing they do — a click, or the arrow
  // key that turns the page — and start then. Nothing is asked of them twice.
  function armed() {
    if (!playing || !ctx) return;
    if (ctx.state !== "running") { wait(); return; }
    if (timer) return;
    // Asked here rather than at load, because between the two the reader may
    // have taken a while to touch anything, and the room did not wait.
    var pick = carried();
    if (pick !== null) step = pick;
    var t = ctx.currentTime;
    at = t + 0.15;
    out.gain.cancelScheduledValues(t);
    out.gain.setValueAtTime(out.gain.value, t);
    out.gain.linearRampToValueAtTime(LEVEL, t + 2.4);
    // The pad takes two and a half seconds to arrive and a reader who has just
    // pressed a button deserves an answer sooner than that, so the room says
    // one note back. It is in the key it is about to be in, which is the only
    // reason it is a note and not a beep.
    var c = chord(Math.floor((((step % CYCLE) + CYCLE) % CYCLE) / 16));
    bell(at, mtof(c.root + 36 + c.voice[0]), 0.045);
    tick();
    timer = setInterval(tick, 250);
    mark();                 // it is a room now rather than the promise of one
    show();                 // and a room this one is allowed to have a face
  }

  function wait() {
    var go = function () {
      removeEventListener("pointerdown", go);
      removeEventListener("keydown", go);
      if (playing) on();
    };
    addEventListener("pointerdown", go);
    addEventListener("keydown", go);
  }

  function off() {
    playing = false;
    remember("off");
    mark();
    fade();               // the ring scales back down to nothing and goes
    if (!ctx) return;
    keep();               // where it stopped, while there is still a timer to ask
    var t = ctx.currentTime;
    out.gain.cancelScheduledValues(t);
    out.gain.setValueAtTime(out.gain.value, t);
    out.gain.linearRampToValueAtTime(0, t + 1.2);
    clearInterval(timer);
    timer = null;
    setTimeout(function () { if (!playing && ctx) ctx.suspend(); }, 1500);
  }

  // ---- the orb ------------------------------------------------------------
  // Four bars in the corner were the whole picture of the room, and they were
  // never a picture of anything: they danced on a timer whether or not a note
  // was playing. There is a truthful picture available for the cost of one
  // node, so the book draws that as well — and it draws it as an object rather
  // than as a meter. A ring of light hangs in the panel a chapter opens with,
  // off to the side of the sentence, and it breathes with what is actually
  // coming out of the speakers. The switch keeps its bars and stays where it
  // is; the ring is the honest reading, next to the sentence, where the eye
  // already is.
  //
  // Turning it on fades and scales the ring up out of nothing. Turning it off
  // is the same backwards.
  //
  // The rings are the waveform and the body is the spectrum, and the object
  // hears one thing at two speeds rather than carrying two readings that
  // argue. The rings wiggle at the speed of the wire. The rock, the threads
  // and the scanlines swell at the speed of a note — every band rising
  // quickly and falling slowly, the way an instrument does.
  //
  // The case against a time-domain trace was that it twitches, and it was a
  // fair one: the window it is read through is not locked to the note, so
  // every frame is a different slice of the same chord and the line reads as
  // interference rather than as music. The answer is the one an oscilloscope
  // has used since there were oscilloscopes. Do not draw whatever happened to
  // be in the buffer at the moment it was asked for — wait for the wave to
  // cross the middle going up, and start reading there. The window is then
  // pinned to the note rather than to the clock: the trace holds still for as
  // long as the note is held, and it moves when the music moves and not
  // before. It is a dozen lines, and it is the whole difference between a
  // waveform and a hash.
  //
  // The three rings are three readings of that one trace, each following it
  // less closely than the last, which is what a wave with a wake looks like.
  // A slower ring is not a slower wave, it is the same wave a moment ago.
  //
  // What the trace is measured against is found rather than fixed. This piece
  // is quiet on purpose and a reader has no knob for it, so the scale rides a
  // peak that jumps to a louder bar at once and takes seconds to come back
  // down. The clamp on that is where the honesty is kept: a silent gap is not
  // opened out into a storm, it simply goes round.
  //
  // It is symmetrical on purpose. Half a ring of bands, mirrored, so the
  // shape closes on itself and has an axis. A ring without one is an
  // equaliser bent round until its ends meet; a ring with one is an object,
  // and this one is meant to be looked at rather than read.
  //
  // What the object is, though, is a rock. This is the chronicle of a game
  // about shooting them, and the thing in the panel had every part of one
  // except the part that says so: a circle is a lens, and a lens is not what
  // the cabinet is full of. So the body is cut — twelve corners at twelve
  // fixed radii, the spread src/entities/asteroids.js rolls its own inside.
  // The cut is fixed, where the cabinet rolls a fresh rock for every one it
  // throws, because a book with a face should wear the same face on every page
  // of it. The breathing is not fixed: the corners ride the same mirrored bands
  // the rings do, so a lopsided shape still swells along the object's axis, and
  // the rock and the light around it are plainly one thing hearing one thing.
  // It sits inside the rings with the light behind it, and it wears its own
  // scanlines — every page of this book lays them over its panels and the ring
  // is drawn above them, so the body draws its own, bright where the light is
  // and gone by the far side.
  //
  // And it is a solid, which is the one thing in this panel worth a third
  // dimension. Everything else here is flat on purpose — a ring is a ring from
  // wherever you stand — but a rock cut flat is a badge of a rock, and it gave
  // itself away the moment it turned: an outline spinning in its own plane is a
  // coin, and the eye knows a coin. So the twelve corners are the twelve corners
  // of an icosahedron rather than twelve points round a circle. Subdivide it
  // once for eighty faces, tumble it on three axes at three speeds with no
  // common multiple, throw away everything pointing away from the reader, and
  // put a short lens in front of it so the near side of the body is larger than
  // the far side. The table of radii never changed. It stopped being read as a
  // silhouette and started being read as a shape, and that is the whole edit.
  //
  // And it is a rock made of glass, which is a decision about which rock. The
  // cabinet's are hollow outlines with nothing on the near face at all, and
  // that is right for something you are meant to shoot before it reaches you;
  // this one is meant to be looked at for the length of a chapter, so it gets
  // faces: eighty of them, flat-shaded off one light, in a ramp that runs from
  // the violet of the rings to the amber of the star behind it. The edges are
  // still where most of the light lives, in the same three colours on the same
  // three thirds of the spectrum. Its outline is not drawn from a table any
  // more — it is found, every frame, as the edges where a face turned towards
  // the reader meets one turned away, which is why the shape of it changes as
  // the thing rolls. And because it is glass, the edges round the back are
  // drawn too, faintly, which is the difference between a solid and a shell.
  // Craters were the other way to say all this and they said something else:
  // a rock with pits in it is a moon.
  //
  // And what is behind it is a star rather than a tint. A shape lit from inside
  // by the average of the spectrum reads as a lamp on a dimmer; the same light
  // with a small hard centre in it, warm where it is brightest, reads as
  // something burning. Amber is the one warm colour this project already owns
  // (--amber, styles/tokens.css), so that is the colour of the hot part and the
  // flare over it is gilded to match, and the rest of the object stays the
  // three neons it was.
  //
  // And it hangs in weather rather than in nothing. Eight clouds of gas in the
  // colours already in the panel, some behind everything and some drifting
  // across the front of the rock, wandering at eight speeds with no multiple
  // between them and breathing on the slowest of the three envelopes. The
  // blending is not a setting, it is the argument: everything in here is drawn
  // in lighter, so two clouds crossing make the colour between them rather than
  // the nearer of the two, and where one passes over the star the star wins
  // because it is brighter. A specimen on a black card was what the object had
  // been until then.
  //
  // It is the busiest thing in this book by a wide margin and it is still
  // cheap, which is worth saying plainly rather than implying. A few dozen
  // gradients and strokes go into a canvas the size of a postcard, once a
  // frame, and only ever between the room arriving and the room leaving —
  // there is no loop at all when the switch is off, a hidden tab is not
  // animated because that is what requestAnimationFrame already promises, the
  // panel it hangs in is measured about once a second rather than sixty
  // times, and nothing in here allocates on a beat. Every page of this book
  // still scrolls the same with it up as without it.

  var still = !!(window.matchMedia &&
                 window.matchMedia("(prefers-reduced-motion: reduce)").matches);

  var RING = 64;                 // points round the circle
  var BANDS = RING / 2;          // distinct bands; the far side is the mirror
  var RAYS = 32;                 // threads in the corona, on the same axis
  var HUES = ["33, 243, 255", "160, 75, 255", "255, 62, 200"];
  // Standing back a notch each, now the rock is the loudest shape in the panel:
  // three rings as bright as the body turn a rock into a rock in a cage.
  var DIMS = [0.85, 0.62, 0.48];
  // Where each ring sits, how closely it follows the trace, how fast the
  // spectrum under it answers — rise, then fall — and how slowly it turns.
  // The cyan one is nearly the wire itself, the magenta one is a moment
  // behind it, and one of the three goes the other way. Three readings of one
  // wave at three speeds is what stops a circle looking like a dial.
  var RINGS = [
    { r: 1.00, lag: 0.80, up: 0.38, dn: 0.090, spin:  0.00013 },
    { r: 0.84, lag: 0.40, up: 0.24, dn: 0.060, spin: -0.00009 },
    { r: 1.16, lag: 0.20, up: 0.15, dn: 0.040, spin:  0.00021 }
  ];
  // The trace, and the four numbers that decide what it looks like.
  // SPAN is how much of the wire one reading covers, and it is the timebase
  // knob. This piece sits between 130 and 200 cycles a second, so six
  // milliseconds is about one turn of the note — which is what an
  // oscilloscope is set to when it is being read rather than measured. It was
  // twice this to begin with and that was the wrong answer for a reason worth
  // keeping: thirty-two points across two cycles of a pad with harmonics on it
  // lands two or three points on each turn of the harmonic, and a wave sampled
  // that thinly comes back as a comb. Half the window is twice the detail.
  // SWING is how far a trough pulls the ring off the round, and it is larger
  // than the old spectrum figure because a trace is signed — it goes inwards
  // as readily as out, so the same excursion costs half as much shape.
  var SPAN = 256;                // samples in one window: about 6ms of wire
  var SWING = 0.34;              // how far the trace pulls a ring off the round
  var QUIET = 0.02;              // below this the trace is silence, not signal
  var REACH = 7;                 // and nothing is ever opened out further
  var LO = 1, HI = 150;          // the bins worth looking at: 45 Hz to 7 kHz
  var TOP = 20;                  // the first band that counts as the bright end
  // Rings that leave. One is thrown outwards whenever the room does something
  // — a chord landing, the pulse on the beat, a pluck — and it carries away
  // the shape the spectrum had at the moment it was born, so what crosses the
  // panel is the print of that note rather than a circle. They thin and fade
  // as they go, they overlap each other, and there are never more than a
  // handful because the pool is fixed and nothing here allocates on a beat.
  var WAVES = 6;
  // A few points of light going round at their own speeds, lit by the top of
  // the spectrum. Nothing is reported by these; they are the difference
  // between a diagram of an object and an object.
  var GLINTS = 5;
  // The body. Twelve corners cut once and kept — the note at the top of this
  // section is where the argument for cutting them at all lives.
  // The spread is the cabinet's own — 0.72 to 1.18 of the radius, the range
  // src/entities/asteroids.js rolls its corners inside — because narrower than
  // that and twelve corners read as a ball somebody has nudged.
  var ROCK = [1.00, 0.82, 1.17, 0.73, 0.94, 1.12, 0.79, 1.06, 0.87, 1.18, 0.72, 0.98];
  // Nearly the whole object. The rock is the thing and the rings are the light
  // around it, which only works if it is the biggest shape in the panel: at
  // three quarters of the radius it read as a pip in the middle of three
  // circles, and the circles were the object.
  var BODY = 0.9;
  // How far in front of the body the reader is standing, in radii. Nine and
  // there is no lens at all and the rock might as well be flat again; three
  // and the near corner comes at the reader like a fist. Five is the distance
  // at which it looks like an object photographed rather than an object
  // diagrammed, and it is also what decides how much of the rock is visible at
  // once: two fifths of a surface, never quite half, which is what standing in
  // front of a real one buys you.
  var LENS = 5;
  // Facet edges are drawn in three colours rather than one, which is the whole
  // reason the face reads as glass and not as wireframe. Two of them are the
  // book's own; the third is the star's, so the rock is carrying the light it
  // is lit by.
  var EDGE = ["33, 243, 255", "255, 62, 200", "255, 176, 32"];
  // The faces, from the ones with their backs to the light to the ones staring
  // into it — the rings' violet at one end and the star's amber at the other,
  // so the body is lit by the two things that are actually in the panel with
  // it. Six steps and not a colour per face: a flat-shaded face is one colour
  // whatever you do, so all quantising costs is that neighbours sometimes
  // agree, and what it buys is six fills a frame instead of forty.
  var SHADE = ["58, 30, 122", "104, 40, 168", "168, 56, 172",
               "230, 92, 132", "255, 152, 74", "255, 214, 152"];
  var SLATS = 9;                 // scanlines across the body
  var SUN = "255, 176, 32";      // --amber: the one warm colour in the project

  var cv = null, cg = null, host = null, adrift = false, bins = null;
  var lev = [], raw = new Float32Array(BANDS), soft = new Float32Array(BANDS);
  var px = new Float32Array(RING), py = new Float32Array(RING);
  var en = new Float32Array(3);          // a third of the spectrum per colour
  // Named for what they are and not for what they hold, because the mesh
  // above already owns "tone" and a second one would quietly become an
  // array of eighty face shades halfway down this function.
  var wire = null;                       // the wire itself, one window of it
  var trace = new Float32Array(BANDS);   // this frame's reading, folded down
  var tr = [], gauge = 0;                // one per ring, and what they scale to
  var wave = [], fast = 0, slow = 0, since = 9, cast = 0, cold = true, warm = 0;
  var raf = 0, last = 0, life = 0, gone = 0, glow = 0;
  var hx = 0, hy = 0, cx = 0, cy = 0, R = 0, took = -9e9;
  // What it was last drawn at, rather than what it was told to be. R is the
  // size of the berth it was given and the object is a good deal smaller than
  // that for the first second of its life, so a fingertip is tested against
  // this one.
  var sz = 0;

  // Where it hangs. A chapter opens with a panel that has the sentence in one
  // corner of it and a lot of painted sky to the right of that, which is the
  // only place on any page of this book with room for an object. The cover and
  // the notes have no such panel, so there it keeps to the corner under the
  // switch, small, and out of the way of the words.
  function place() {
    var w = cv.clientWidth, h = cv.clientHeight;
    if (adrift) {
      hx = w / 2; hy = h / 2;
      // A fifth rather than the near-third it was, and the box it is in got
      // bigger by about as much — so the rock is the size it always was and
      // the room around it is not. What hangs off this object goes a long way
      // out: the shock ring alone reaches past one and a half of it on a loud
      // bar, and the flares and the halo further. At the old ratio every one
      // of them met the edge of the canvas and stopped dead, which reads as a
      // circle drawn round the thing rather than as light coming off it. The
      // berth here is a little over four rocks across, which is what the piece
      // needs at its loudest.
      R = Math.min(w, h) * 0.21;
      return;
    }
    var box = cv.getBoundingClientRect();
    var say = host.querySelector(".say");
    var cred = host.querySelector(".credits");
    var full = host.querySelector(".plate-full");
    var l = say ? say.getBoundingClientRect().right - box.left + 16 : w * 0.5;
    var r = w - 10, t = 10;
    var b = cred ? cred.getBoundingClientRect().top - box.top - 12 : h - 10;
    // The link to the full plate lives in that corner and is drawn over
    // everything, so the ring starts below it rather than behind it.
    if (full) t = Math.max(t, full.getBoundingClientRect().bottom - box.top + 10);
    // Too tight to hang anything in — a narrow window, where the sentence has
    // the panel to itself. It goes in the corner over the painting instead,
    // and small, which is what the painting is behind the words for.
    if (r - l < 74 || b - t < 74) { l = w * 0.52; r = w - 8; b = h * 0.55; }
    hx = (l + r) / 2;
    hy = (t + b) / 2;
    R = Math.max(22, Math.min(92, Math.min(r - l, b - t) * 0.26));
  }

  function fit() {
    var dpr = Math.min(2, window.devicePixelRatio || 1);
    cv.width = Math.max(1, Math.round(cv.clientWidth * dpr));
    cv.height = Math.max(1, Math.round(cv.clientHeight * dpr));
    cg.setTransform(dpr, 0, 0, dpr, 0, 0);
    place();
  }

  function resize() {
    if (!cv) return;
    took = -9e9;
    fit();
    if (still) paint();
  }

  // Built by the script and dressed by it too. Everything else in this book
  // keeps its clothes in a stylesheet, but there are two of those — the
  // chapters read one and the notes read the other — and eight declarations
  // for an element nobody can select is not worth saying twice.
  function make() {
    host = document.querySelector(".cel.splash");
    adrift = !host;
    cv = document.createElement("canvas");
    cv.className = "orb";
    cv.setAttribute("aria-hidden", "true");
    var s = cv.style;
    s.pointerEvents = "none";        // it is a readout, not a lid
    if (adrift) {
      s.position = "fixed";
      s.zIndex = "4";
      s.top = "2.6rem";
      s.right = "0.2rem";
      // Room for what comes off it, not for a bigger rock — see place(), which
      // takes a smaller share of this box than it used to by exactly enough to
      // leave the object the size it was. Held against the viewport as well as
      // in rems, because a phone has no twelve rems to spare in a corner and
      // the light coming off a stamp does not need them.
      s.width = s.height = "min(12rem, 44vw)";
      // And whatever still reaches the edge is feathered there rather than
      // cut. Room alone was never going to finish this: the weather has no
      // size of its own and no shape either, so however wide the canvas is it
      // fills it and then meets the corners, and a cloud with corners is a
      // rectangle of gas hanging over the roster. The rock and its rings sit
      // well inside the solid part; what fades is the sky they are in, which
      // is the part that was pretending to be square.
      s.webkitMaskImage = s.maskImage =
        "radial-gradient(closest-side, #000 56%, rgba(0,0,0,0.5) 80%, transparent 100%)";
      document.body.appendChild(cv);
    } else {
      s.position = "absolute";
      s.left = "0";
      s.top = "0";
      s.width = "100%";
      s.height = "100%";
      s.zIndex = "1";                // over the painting, under the sentence
      host.appendChild(cv);
    }
    cg = cv.getContext("2d");
    var i;
    cold = true;                     // no history yet, so nothing to compare to
    // And no room yet either, only a room arriving. out.gain climbs from
    // nothing to LEVEL over two and a half seconds, and a detector watching
    // for the bright end to get louder cannot tell that ramp from a bar full
    // of struck notes: it reads the arrival as one continuous onset and
    // throws a ring every fifth of a second for the whole of it, which is a
    // fistful of rings for a room that has not done anything yet. So it
    // listens through the arrival and reports none of it, and starts counting
    // when the room is at the level it means to stay at.
    warm = 2.6;
    gauge = 0;
    mist();                          // the weather, built once and reused
    for (i = 0; i < RINGS.length; i++) {
      lev.push(new Float32Array(BANDS));
      tr.push(new Float32Array(BANDS));
    }
    // Spent, all of them, until the room throws one.
    for (i = 0; i < WAVES; i++)
      wave.push({ t: 1, amp: 0, hue: 0, hand: false, sh: new Float32Array(BANDS) });
    fit();
    addEventListener("resize", resize);
    // Only while there is something to poke. Both handlers are on the window
    // rather than on the canvas because the canvas is not a lid — see the poke
    // below, where the argument for that lives, and where the second of these
    // explains why one press needs two events.
    addEventListener("pointerdown", prod, true);
    addEventListener("mousedown", bite, true);
    // And a hand on its way in, which is a different question from a hand
    // arriving — see the field. The third of these is for the reader who
    // changes tab with the cursor sitting on the thing: there is no next frame
    // in a tab nobody is looking at, so the departure has to be an event.
    addEventListener("pointermove", feel, true);
    addEventListener("pointerout", flee, true);
    addEventListener("blur", flee);
  }

  function tear() {
    hush();
    if (!cv) return;
    removeEventListener("resize", resize);
    removeEventListener("pointerdown", prod, true);
    removeEventListener("mousedown", bite, true);
    removeEventListener("pointermove", feel, true);
    removeEventListener("pointerout", flee, true);
    removeEventListener("blur", flee);
    if (cv.parentNode) cv.parentNode.removeChild(cv);
    cv = null; cg = null; host = null; bins = null; lev = []; NEB = null;
    tr = []; wire = null; gauge = 0;
    life = 0; gone = 0; glow = 0;
    sz = 0; sx = sy = svx = svy = 0; gx = gy = gvx = gvy = 0;
    // Nothing to be near any more, and the field goes with the object rather
    // than outliving it in the graph.
    hover = false; near = 0; charge(0);
  }

  // Half a ring of bands, spaced by ear rather than by bin — an octave is an
  // octave wide wherever it sits, so the bass end gets the room it deserves
  // instead of one point of it — and then smoothed twice. Once round the ring,
  // which is what stops it spiking, and once in time, which is what stops it
  // flickering. The time one is not symmetrical: a band jumps most of the way
  // to a new note and takes seconds to come back down, because that is what
  // the note itself does.
  function hem(i) { return i < 0 ? 0 : i > BANDS - 1 ? BANDS - 1 : i; }

  function listen(dt) {
    var i, k;
    if (!eye) return;
    if (!bins) bins = new Uint8Array(eye.frequencyBinCount);
    eye.getByteFrequencyData(bins);
    var sum = 0;
    for (k = 0; k < BANDS; k++) {
      var a = Math.round(LO * Math.pow(HI / LO, k / BANDS));
      var b = Math.max(a + 1, Math.round(LO * Math.pow(HI / LO, (k + 1) / BANDS)));
      var peak = 0;
      for (i = a; i < b && i < bins.length; i++) if (bins[i] > peak) peak = bins[i];
      // The ear is not linear and neither is this: the square root opens out
      // the quiet end, which is where nearly all of this piece lives.
      raw[k] = Math.sqrt(peak / 255);
      sum += raw[k];
    }
    // Five taps and not three: neighbouring bands here are the better part of
    // an octave apart, and a narrower blur leaves a polygon wearing a curve.
    // Clamped at the ends rather than wrapped, because the ends are the two
    // poles of the mirror and each of them is its own neighbour.
    for (k = 0; k < BANDS; k++)
      soft[k] = (raw[hem(k - 2)] + raw[hem(k - 1)] * 4 + raw[k] * 6 +
                 raw[hem(k + 1)] * 4 + raw[hem(k + 2)]) / 16;
    for (i = 0; i < RINGS.length; i++) {
      // Per second rather than per frame, so a 120Hz screen does not make the
      // room twice as jumpy as a 60Hz one.
      var up = 1 - Math.pow(1 - RINGS[i].up, dt * 60);
      var dn = 1 - Math.pow(1 - RINGS[i].dn, dt * 60);
      var L = lev[i];
      for (k = 0; k < BANDS; k++)
        L[k] += (soft[k] - L[k]) * (soft[k] > L[k] ? up : dn);
    }

    // The same tap read the other way, for the rings. A window of samples
    // rather than a window of bands, and the whole of what makes it usable is
    // where the window starts.
    if (!wire) wire = new Uint8Array(eye.fftSize);
    eye.getByteTimeDomainData(wire);
    // The trigger. 128 is the middle of a byte-encoded wave, and a rise
    // through it is the same place in the cycle every time — which is why the
    // trace holds still while a note is held instead of shivering at the
    // frame rate. Hunted for only in the part of the buffer with a whole
    // window left behind it, so a crossing found near the end is not one.
    // Nothing found means silence or a wave that never came back, and reading
    // from the top of the buffer is the right answer to both.
    var head = wire.length - SPAN, start = 0;
    for (i = 1; i < head; i++)
      if (wire[i - 1] < 128 && wire[i] >= 128) { start = i; break; }
    // Folded down to the half ring the mirror wants, by averaging and not by
    // picking: sixteen samples to a point is a low-pass filter for free, and
    // it is the reason a trace this small reads as a wave and not as a comb.
    var wide = SPAN / BANDS, mean = 0;
    for (k = 0; k < BANDS; k++) {
      var from = start + k * wide, upto = from + wide, v = 0;
      for (i = from; i < upto; i++) v += wire[i] - 128;
      trace[k] = v / (wide * 128);
      mean += trace[k];
    }
    // And its own middle taken out of it. A window this short does not always
    // hold a whole turn of the note, so a reading can sit entirely above the
    // middle or entirely below it — and an offset on a trace does not change
    // the ring's shape, it changes the ring's size, which is a job this
    // reading has already given away to the level. Taking the mean out leaves
    // the wave and nothing else, which is the same trick the rings that leave
    // play on the spectrum a few lines further down, for the same reason.
    mean /= BANDS;
    var loud = 0;
    for (k = 0; k < BANDS; k++) {
      v = trace[k] - mean;
      trace[k] = v;
      if (v > loud) loud = v; else if (-v > loud) loud = -v;
    }
    // What it is measured against: up at once, down over seconds. A bar that
    // gets louder is answered immediately, and one that goes quiet is not
    // hauled back up to fill the ring for a few seconds yet. QUIET is the
    // floor under the division and REACH the ceiling over it, and between
    // them they are the reason silence draws a circle rather than drawing the
    // noise floor at full size.
    gauge += (loud - gauge) * (loud > gauge ? 1 - Math.pow(0.4, dt * 60)
                                            : 1 - Math.pow(0.988, dt * 60));
    var open = Math.min(REACH, 1 / Math.max(QUIET, gauge));
    for (k = 0; k < BANDS; k++) {
      var w = trace[k] * open;
      trace[k] = w > 1 ? 1 : w < -1 ? -1 : w;
    }
    // And the three rings follow it at three distances. Plain and symmetrical
    // where the spectrum's envelopes are neither, because a trace is signed: a
    // filter that rose faster than it fell would quietly drag a wave off its
    // own middle and the rings would sit permanently swollen.
    for (i = 0; i < RINGS.length; i++) {
      var f = 1 - Math.pow(1 - RINGS[i].lag, dt * 60);
      var T = tr[i];
      for (k = 0; k < BANDS; k++) T[k] += (trace[k] - T[k]) * f;
    }

    // The rings that leave come off the top of the spectrum and nothing else. The pad and
    // the bass are always there — they are the room, and a room does not throw
    // rings — so what launches one is the bright end: the arpeggio, the bell
    // that lands on the twelfth step, the pulse on the beat. Two envelopes on
    // that number at two speeds, and where the quick one gets clear of the
    // slow one, something was struck. That is the whole detector, and a quiet
    // bar honestly shows nothing leaving.
    var top = 0;
    for (k = TOP; k < BANDS; k++) top += raw[k];
    top /= BANDS - TOP;
    // The first read is not a comparison, and neither is any read taken while
    // the room is still arriving. Both envelopes start at nothing, so a chord
    // already hanging in the air when the orb appears clears the slow one by a
    // mile. Worse, out.gain climbs from nothing to LEVEL over two and a half
    // seconds, and every frame of that climb is louder than the one before it,
    // so the slow envelope is cleared again and again the whole way up: a ring
    // thrown every fifth of a second for a room that has not played a note yet
    // — which is what switching the sound on used to look like. So through the
    // arrival both envelopes are simply told where the level is, and the
    // detector starts once they are level with each other and with the room.
    if (cold || warm > 0) {
      if (cold) { cold = false; glow = sum / BANDS; }
      else glow += (sum / BANDS - glow) * (1 - Math.pow(0.92, dt * 60));
      warm -= dt;
      fast = slow = top;
      since = 0;
      return;
    }
    fast += (top - fast) * (1 - Math.pow(0.55, dt * 60));
    slow += (top - slow) * (1 - Math.pow(0.982, dt * 60));
    glow += (sum / BANDS - glow) * (1 - Math.pow(0.92, dt * 60));
    since += dt;
    if (since > 0.18 && fast > slow * 1.14 + 0.01) throw_(top);
  }

  // Out goes another one, on the oldest slot there is. A pool and not a queue:
  // the beat is not a place to be making arrays.
  //
  // A ring goes out when the room does something, and one goes out when the
  // reader pokes the thing. The slot remembers which of those it was, because a
  // ring somebody caused ought to be the one in the panel behaving differently
  // from the rest.
  function throw_(amp, hand) {
    since = 0;
    var old = wave[0];
    for (var i = 1; i < WAVES; i++) if (wave[i].t > old.t) old = wave[i];
    old.t = 0;
    old.amp = Math.min(1, 0.35 + amp * 2.2);
    old.hue = (cast++) % HUES.length;
    old.hand = !!hand;
    // What it carries is the spectrum with its own average taken out, so the
    // lobes go outward and inward from the circle rather than all one way.
    var k, m = 0;
    for (k = 0; k < BANDS; k++) m += soft[k];
    m /= BANDS;
    for (k = 0; k < BANDS; k++) old.sh[k] = (soft[k] - m) * 1.8;
  }

  // Half the points are read forwards and half backwards. That is the mirror,
  // and the mirror is why the shape has an axis and closes without a seam.
  function band(k) { return k < BANDS ? k : RING - 1 - k; }

  // A closed curve through the points rather than a polygon between them: the
  // corners are where a ring stops looking like light and starts looking like
  // a chart.
  function loop() {
    cg.beginPath();
    cg.moveTo((px[RING - 1] + px[0]) / 2, (py[RING - 1] + py[0]) / 2);
    for (var k = 0; k < RING; k++) {
      var j = (k + 1) % RING;
      cg.quadraticCurveTo(px[k], py[k], (px[k] + px[j]) / 2, (py[k] + py[j]) / 2);
    }
    cg.closePath();
  }

  // Shiny is one light crossing the object, which is one gradient turning
  // slowly rather than a second pass over everything. Four strokes over the
  // one path — two wide and dim for the halo, one for the colour, a hairline
  // for the filament — which is the cabinet's bloom done by hand, and cheaper
  // than a canvas shadow by a wide margin.
  // The rock is stroked by the same light as the rings, and the only thing it
  // asks for is its corners back: mitred joins, because a rock with the corners
  // rounded off it is a pebble and the cabinet does not throw pebbles.
  function shine(c, now, rr, al, turn, t, sharp) {
    var a = now * 0.00034 + turn;
    var ax = Math.cos(a) * rr * 1.5, ay = Math.sin(a) * rr * 1.5;
    var gr = cg.createLinearGradient(cx - ax, cy - ay, cx + ax, cy + ay);
    gr.addColorStop(0, "rgba(" + c + ", 0.14)");
    gr.addColorStop(0.4, "rgba(" + c + ", 0.7)");
    gr.addColorStop(0.5, "rgba(242, 233, 255, 1)");
    gr.addColorStop(0.6, "rgba(" + c + ", 0.7)");
    gr.addColorStop(1, "rgba(" + c + ", 0.14)");
    cg.strokeStyle = gr;
    cg.lineCap = "round";
    cg.lineJoin = sharp ? "miter" : "round";
    // And the thickness is the music too. A ring that only changes shape is a
    // reading; one that also thickens where the room is loud and draws down to
    // a filament in the gaps between chords is the room breathing. The halo
    // passes move least, because a glow that doubles is a flash.
    cg.lineWidth = 10 + t * 7;    cg.globalAlpha = al * 0.05; cg.stroke();
    cg.lineWidth = 5 + t * 4.5;   cg.globalAlpha = al * 0.11; cg.stroke();
    cg.lineWidth = 1.5 + t * 3.2; cg.globalAlpha = al * 0.4;  cg.stroke();
    cg.lineWidth = 0.6 + t * 1.5; cg.globalAlpha = al;        cg.stroke();
    // A lens does not put every colour in the same place, and the same ring
    // drawn a hair either side in the two ends of the spectrum is what that
    // looks like. It is under a pixel of offset and it is the difference
    // between a line and a thing seen through glass.
    cg.lineWidth = 0.8;
    cg.globalAlpha = al * 0.4;
    cg.strokeStyle = "rgba(33, 243, 255, 1)";
    cg.translate(0.9, -0.5);  cg.stroke(); cg.translate(-0.9, 0.5);
    cg.strokeStyle = "rgba(255, 62, 200, 1)";
    cg.translate(-0.9, 0.5);  cg.stroke(); cg.translate(0.9, -0.5);
  }

  // The glare. Anything looking at something this bright streaks, so it does:
  // one long spike across the object and two shorter ones over it, six arms
  // between them, turning very slowly and lit by the level rather than by a
  // clock. It is the one part of this that is not the object — it is what the
  // object does to whatever is looking at it.
  function glare(now, rr, al) {
    var v = Math.min(1, 0.16 + glow * 1.7);
    var turn = now * 0.00008;
    // Kept inside the canvas it is drawn on. A flare that runs off the edge
    // does not read as a flare, it reads as a line somebody forgot to finish,
    // and the corner of a notes page has a lot less room than a chapter's
    // opening panel does.
    var room = Math.min(cx, cy, cv.clientWidth - cx, cv.clientHeight - cy) * 0.96;
    for (var i = 0; i < 3; i++) {
      var a = turn + i * 1.0472;
      var len = Math.min(room, rr * (i ? 1.9 : 3.6) * v);
      var co = Math.cos(a) * len, si = Math.sin(a) * len;
      var gr = cg.createLinearGradient(cx - co, cy - si, cx + co, cy + si);
      gr.addColorStop(0, "rgba(242, 233, 255, 0)");
      gr.addColorStop(0.42, "rgba(160, 75, 255, 0.45)");
      // Warm where it crosses the star and neon at both ends of it, because a
      // flare is the colour of the thing that caused it in the middle and the
      // colour of the glass everywhere else.
      gr.addColorStop(0.47, "rgba(" + SUN + ", 0.8)");
      gr.addColorStop(0.5, "rgba(255, 255, 255, 1)");
      gr.addColorStop(0.53, "rgba(" + SUN + ", 0.8)");
      gr.addColorStop(0.58, "rgba(33, 243, 255, 0.45)");
      gr.addColorStop(1, "rgba(242, 233, 255, 0)");
      cg.strokeStyle = gr;
      cg.beginPath();
      cg.moveTo(cx - co, cy - si);
      cg.lineTo(cx + co, cy + si);
      cg.lineWidth = 7;   cg.globalAlpha = al * v * 0.07; cg.stroke();
      cg.lineWidth = 1.6; cg.globalAlpha = al * v * 0.3;  cg.stroke();
    }
  }

  // Glass, and two things do all of the work. A highlight sitting off centre
  // where the light is, which is the near wall of the sphere catching it, and
  // a thin crescent opposite, which is the same light arriving at the far one.
  // Both travel with the angle the rings are shining along, so the object is
  // lit from one place rather than from several, which is the whole difference
  // between glossy and merely bright.
  function gloss(now, rr, al) {
    var a = now * 0.00034 + 3.14159;
    var lx = cx + Math.cos(a) * rr * 0.42, ly = cy + Math.sin(a) * rr * 0.42;
    var k = al * (0.15 + glow * 0.5);
    var gr = cg.createRadialGradient(lx, ly, 0, lx, ly, rr * 0.74);
    gr.addColorStop(0, "rgba(255, 255, 255, " + k.toFixed(3) + ")");
    gr.addColorStop(0.4, "rgba(242, 233, 255, " + (k * 0.3).toFixed(3) + ")");
    gr.addColorStop(1, "rgba(242, 233, 255, 0)");
    cg.globalAlpha = 1;
    cg.fillStyle = gr;
    cg.beginPath();
    cg.arc(lx, ly, rr * 0.74, 0, 6.28318);
    cg.fill();

    var b = a + 3.14159;
    var fx = cx + Math.cos(b) * rr, fy = cy + Math.sin(b) * rr;
    var g2 = cg.createRadialGradient(fx, fy, 0, fx, fy, rr * 1.25);
    g2.addColorStop(0, "rgba(255, 255, 255, 1)");
    g2.addColorStop(1, "rgba(255, 255, 255, 0)");
    cg.strokeStyle = g2;
    cg.beginPath();
    cg.arc(cx, cy, rr * 0.92, b - 0.9, b + 0.9);
    cg.lineWidth = 6;   cg.globalAlpha = al * 0.09; cg.stroke();
    cg.lineWidth = 1.6; cg.globalAlpha = al * 0.42; cg.stroke();
  }

  function ring(i, now, rr, al) {
    var cfg = RINGS[i], T = tr[i], L = lev[i], k, m = 0;
    for (k = 0; k < BANDS; k++) m += L[k];
    m /= BANDS;
    // Shape from the trace, size from the level. The wave is what pushes the
    // ring off the round — outwards where the wire is above the middle and
    // inwards where it is below, which is the part a reader actually sees as
    // sound — and the spectrum underneath only breathes the radius and the
    // thickness. Keeping the two jobs apart is what stops a loud bar simply
    // inflating the ring: a ring that changes size with the music says the
    // same thing a lamp on a dimmer says, and a ring that changes shape with
    // it says which music.
    var base = rr * (cfg.r + m * 0.14), sw = rr * SWING, spin = now * cfg.spin;
    // And the hand, which is the one thing in this panel that is neither the
    // music nor a press — see the field, below. The reach is in proportion to
    // the ring's own radius, so three rings leaning at one cursor stay nested
    // instead of crossing each other on the way out to it. And it flickers
    // rather than holds, faster and deeper the closer the hand is, because a
    // field that is merely bent is a dent and a field that is bent and
    // unsteady is a charge.
    var reach = near > 0
      ? rr * BEND * cfg.r * near *
        (1 + Math.sin(now * (0.01 + near * 0.05) + i * 2.1) * 0.09 * near)
      : 0;
    for (k = 0; k < RING; k++) {
      var a = spin + k / RING * 6.28318;
      var d = base + T[band(k)] * sw;
      // A cone pointing at the hand, and nothing at all on the far side of the
      // ring: a shape that swells in every direction is a thing inflating and
      // not a thing reaching. Two powers blended rather than one raised, which
      // is a multiply where a pow would be — wide and soft while the hand is
      // only in the neighbourhood, drawn to a point once it is on the rim,
      // which is the difference between leaning and about to arc.
      if (reach > 0) {
        var w = Math.cos(a - bear);
        if (w > 0) {
          var w2 = w * w;
          d += reach * (w2 + near * (w2 * w2 * w2 - w2));
        }
      }
      px[k] = cx + Math.cos(a) * d;
      py[k] = cy + Math.sin(a) * d;
    }
    loop();
    // The light gathers while the hand is near, and it does it by lifting the
    // level the ring is already drawn at rather than by adding a second pass.
    // What a reader sees is the same ring charged, not a ring with a highlight
    // bolted onto it.
    shine(HUES[i], now, rr, al * DIMS[i], i * 0.7,
          Math.min(1, m * 2.2 + near * 0.3));
  }

  // The light inside it, in two parts. The wide one is the whole level and
  // nothing else — no band, no number — and it is what makes the thing look lit
  // from within rather than drawn. The tight one is the star: a small disc with
  // white at the middle of it and amber on the way out, falling off fast enough
  // to have an edge. A glow that only spreads is a haze; a glow with something
  // hard in the middle of it is a source, and the rock in front of it is being
  // lit by that rather than tinted by it.
  function core(rr, al) {
    var k = al * (0.1 + glow * 0.55);
    var gr = cg.createRadialGradient(cx, cy, 0, cx, cy, rr * 2.05);
    gr.addColorStop(0, "rgba(255, 249, 236, " + (k * 0.62).toFixed(3) + ")");
    gr.addColorStop(0.16, "rgba(" + SUN + ", " + (k * 0.4).toFixed(3) + ")");
    gr.addColorStop(0.42, "rgba(160, 75, 255, " + (k * 0.32).toFixed(3) + ")");
    gr.addColorStop(1, "rgba(33, 243, 255, 0)");
    cg.globalAlpha = 1;
    cg.fillStyle = gr;
    cg.beginPath();
    cg.arc(cx, cy, rr * 2.05, 0, 6.28318);
    cg.fill();

    // Kept modest on purpose. Everything in here is drawn in lighter, so a
    // centre much brighter than this stops being a star and starts being a hole
    // in the panel with the rings sticking out of it.
    var h = al * (0.16 + glow * 0.42);
    var g2 = cg.createRadialGradient(cx, cy, 0, cx, cy, rr * 0.6);
    g2.addColorStop(0, "rgba(255, 255, 255, " + h.toFixed(3) + ")");
    g2.addColorStop(0.34, "rgba(255, 226, 168, " + (h * 0.6).toFixed(3) + ")");
    g2.addColorStop(0.72, "rgba(" + SUN + ", " + (h * 0.22).toFixed(3) + ")");
    g2.addColorStop(1, "rgba(" + SUN + ", 0)");
    cg.fillStyle = g2;
    cg.beginPath();
    cg.arc(cx, cy, rr * 0.6, 0, 6.28318);
    cg.fill();
  }

  // Which band a thread, or a corner of the rock, is standing in. Half of them
  // read forwards and half back, the same way the rings do, so anything hung
  // round the object shares its axis instead of cutting across it.
  // Clamped, because an odd count has a middle: nine scanlines fold about the
  // fifth one, which lands half a band past the top of the spectrum and would
  // read a band that is not there.
  function mir(j, n) {
    var h = n / 2;
    return hem(Math.round((j < h ? j : n - 1 - j) / (h - 1) * (BANDS - 1)));
  }

  // A thread of light out of every other band, so the thing has an edge that
  // moves. Faint on purpose: it is what a reader sees while they are not
  // looking at it. Each one fades in off nothing and back out into nothing —
  // a thread hanging in the air rather than a spoke bolted on at both ends —
  // and that is one gradient apiece, which is what an end that stops rather
  // than an end that is cut costs.
  function corona(now, rr, al) {
    var L = lev[0], sp = now * 0.00007;
    cg.lineWidth = 1.4;
    cg.lineCap = "butt";
    for (var j = 0; j < RAYS; j++) {
      var v = L[mir(j, RAYS)];
      var a = sp + (j + 0.5) / RAYS * 6.28318;
      var co = Math.cos(a), si = Math.sin(a);
      var i0 = rr * 1.3, i1 = i0 + (0.12 + v) * rr * 0.37;
      var x0 = cx + co * i0, y0 = cy + si * i0;
      var x1 = cx + co * i1, y1 = cy + si * i1;
      var gr = cg.createLinearGradient(x0, y0, x1, y1);
      gr.addColorStop(0, "rgba(242, 233, 255, 0)");
      gr.addColorStop(0.3, "rgba(242, 233, 255, 1)");
      gr.addColorStop(0.6, "rgba(242, 233, 255, 0.8)");
      gr.addColorStop(1, "rgba(242, 233, 255, 0)");
      cg.strokeStyle = gr;
      cg.globalAlpha = al * (0.18 + v * 0.55);
      cg.beginPath();
      cg.moveTo(x0, y0);
      cg.lineTo(x1, y1);
      cg.stroke();
    }
  }

  // ---- the clouds ---------------------------------------------------------
  // Gas, because the object was hanging in nothing and a rock hanging in
  // nothing is a specimen on a black card. Eight clouds, some of them behind
  // everything and some of them drifting across the front of the rock, in the
  // four colours this panel already owns and no others.
  //
  // The whole of what makes them read as gas rather than as eight lamps is the
  // profile: bright at the middle, then a fall so steep it is nearly a wall,
  // then a long shelf of almost nothing that reaches twice as far again. One
  // of those on its own is a smudge. Eight of them overlapping, at eight sizes,
  // wandering at eight speeds that share no multiple, and every one of them
  // squashed and turned so that not one is a circle — that is weather.
  //
  // Blended by being drawn in lighter with the rest of it, which is not a
  // setting so much as the whole argument. Nothing in this panel covers
  // anything: two clouds crossing make the colour between them rather than the
  // nearer of the two, the rock behind one is dimmed by nothing and lit by it,
  // and where a cloud passes over the star the star wins, because it is
  // brighter. That is how light actually behaves, and it is the reason this
  // panel has never once needed to work out what is in front of what.
  //
  // They cost nothing to speak of. Four gradients built once when the canvas
  // is — at the origin and at unit radius, so a cloud is placed and sized by
  // the transform rather than by a new gradient every frame — and twenty-four
  // fills a frame between the lot of them.
  var NEB = null;
  // Where each one hangs and what it answers. Fixed, like the rock's twelve
  // radii and for the same reason: a book with a face wears the same face on
  // every page of it.
  //   at: where it starts   r: how far out   s: how big   c: which colour
  //   sp: how fast it wanders   w: the phase of its own breathing
  //   k: the band it listens to   fore: in front of the rock, or behind it all
  // Big, and overlapping each other and the object. Clouds small enough to have
  // a shape of their own read as eight lozenges in orbit; the size is what
  // turns eight of them into one sky with the orb inside it.
  var CLOUD = [
    { at: 0.55, r: 1.15, s: 2.00, c: 1, sp:  0.000029, w: 2.4, k: 2,  fore: 0 },
    { at: 2.10, r: 1.55, s: 1.60, c: 0, sp: -0.000041, w: 1.7, k: 9,  fore: 0 },
    { at: 3.60, r: 0.95, s: 2.30, c: 2, sp:  0.000023, w: 3.1, k: 17, fore: 0 },
    { at: 5.05, r: 1.75, s: 1.40, c: 1, sp: -0.000019, w: 0.9, k: 25, fore: 0 },
    { at: 1.35, r: 2.00, s: 1.70, c: 0, sp:  0.000037, w: 4.0, k: 30, fore: 0 },
    { at: 4.35, r: 0.80, s: 1.15, c: 2, sp: -0.000051, w: 1.2, k: 6,  fore: 1 },
    { at: 0.15, r: 0.90, s: 0.95, c: 3, sp:  0.000044, w: 2.8, k: 21, fore: 1 },
    { at: 2.85, r: 1.05, s: 1.10, c: 1, sp: -0.000033, w: 5.2, k: 13, fore: 1 }
  ];

  function mist() {
    var i, c;
    NEB = [];
    for (i = 0; i < 4; i++) {
      c = i < 3 ? HUES[i] : SUN;
      var g = cg.createRadialGradient(0, 0, 0, 0, 0, 1);
      // No hard step anywhere along it, which is the only thing standing
      // between a cloud and a disc. The first attempt put a wall a third of the
      // way out — bright inside it, nearly nothing past it — and every one of
      // the eight came out with a rim on it and read as a lozenge with a lamp
      // in. Gas has no rim: it thins the whole way and it is still thinning
      // where it stops.
      //
      // The brightest part of it is not the middle either, for the same reason.
      // A peak at dead centre survives being scaled down to a lobe the size of
      // a full stop, and a cloud with a full stop in it is a cloud with a fault
      // in it; a peak a fifth of the way out has nothing small enough to leave
      // behind.
      g.addColorStop(0, "rgba(255, 248, 240, 0.26)");
      g.addColorStop(0.2, "rgba(" + c + ", 0.42)");
      g.addColorStop(0.42, "rgba(" + c + ", 0.19)");
      g.addColorStop(0.66, "rgba(" + c + ", 0.07)");
      g.addColorStop(0.86, "rgba(" + c + ", 0.018)");
      g.addColorStop(1, "rgba(" + c + ", 0)");
      NEB.push(g);
    }
  }

  // Drawn twice a frame, once for what is behind the object and once for what
  // is in front of it, so the thing is inside the weather rather than pasted on
  // top of a picture of it. The ones in front are a fifth the strength: a cloud
  // you cannot read the rock through is a smear over the one thing in the panel
  // worth looking at.
  function clouds(now, rr, al, fore) {
    var L = lev[2], i;
    for (i = 0; i < CLOUD.length; i++) {
      var c = CLOUD[i];
      if (c.fore !== fore) continue;
      var v = L[c.k];
      var a = c.at + now * c.sp;
      // In and out as well as round. A cloud going round at a fixed distance is
      // a moon, and this panel already has something in orbit.
      var d = rr * c.r * (1 + Math.sin(now * 0.00013 + c.w) * 0.17 + v * 0.22);
      var s = rr * c.s * (0.8 + v * 0.55);
      // A floor under it, and the floor is most of the reading. This piece is
      // one chord every eight seconds and the level spends most of its life
      // near nothing; weather that only exists on the loud part is a panel
      // that is empty for six seconds in every eight.
      var k = Math.min(1, (0.42 + v * 1.05) * (0.55 + glow * 1.1));
      cg.globalAlpha = al * k * (fore ? 0.26 : 0.52);
      cg.fillStyle = NEB[c.c];
      // And when the thing gets poked, the weather goes with it — further than
      // the rock does and later, because it is gas. cx already carries the
      // rock's share of the shove, so what is added here is the difference
      // between the gas and the rock rather than the shove again.
      //
      // A share each, off the cloud's own size: the big diffuse ones are pushed
      // furthest, which is both the way gas behaves and the only way eight of
      // them read as weather being disturbed rather than as a photograph being
      // slid sideways.
      var f = 0.6 + c.s * 0.5;
      var ox = (gx * f - sx) * R, oy = (gy * f - sy) * R;
      // Everything from here is in the cloud's own frame, where it is one unit
      // across — which is the whole trick, because the four gradients were
      // built one unit across too and a gradient is painted in whatever space
      // it is painted in. Place it and size it with the brush and none of them
      // ever has to be built again.
      cg.save();
      cg.translate(cx + ox + Math.cos(a) * d, cy + oy + Math.sin(a) * d);
      // Turned and squashed, and the squash gives out on a loud band, so a
      // cloud rounds up as the room fills and goes back to a streak after.
      cg.rotate(a * 0.6 + c.w);
      cg.scale(s, s * (0.6 + v * 0.28));
      cg.beginPath();
      cg.arc(0, 0, 1, 0, 6.28318);
      cg.fill();
      // Two more lobes off the first, each smaller and off in its own
      // direction, because a cloud with one centre in it is a lamp with a soft
      // shade on. Moving the brush moves the light with it, so a lobe is one
      // more fill and nothing else — no gradient, no path, no arithmetic.
      cg.translate(0.5, -0.34);
      cg.scale(0.66, 0.66);
      cg.globalAlpha *= 0.82;
      cg.beginPath();
      cg.arc(0, 0, 1, 0, 6.28318);
      cg.fill();
      cg.translate(-0.8, 0.62);
      cg.scale(0.85, 0.85);
      cg.globalAlpha *= 0.82;
      cg.beginPath();
      cg.arc(0, 0, 1, 0, 6.28318);
      cg.fill();
      cg.restore();
    }
  }

  // ---- the rock -----------------------------------------------------------
  // A solid, cut once at load and kept. Twelve corners is what the flat rock
  // was cut to and twelve corners is what an icosahedron has, so the table of
  // radii did not change when the shape did: ROCK is read as twelve radii in
  // space instead of twelve round a circle, and the note at the top of this
  // section is where the argument for going round lives.
  //
  // Subdivided once, because twenty faces is a die and eighty is a rock. Every
  // corner the subdivision adds sits half way along the edge it came from and
  // takes the mean of the two radii either end of it, which is why a body with
  // eighty faces on it still reads as the same twelve numbers.

  // The twelve, at the corners of three golden rectangles, and the twenty
  // faces between them. Both tables are the textbook's; what this file does
  // with them afterwards is the part worth reading.
  var PHI = 1.6180339887;
  var ICO = [
    [-1, PHI, 0], [1, PHI, 0], [-1, -PHI, 0], [1, -PHI, 0],
    [0, -1, PHI], [0, 1, PHI], [0, -1, -PHI], [0, 1, -PHI],
    [PHI, 0, -1], [PHI, 0, 1], [-PHI, 0, -1], [-PHI, 0, 1]
  ];
  var TRI = [
    [0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
    [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
    [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
    [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]
  ];

  // Forty-two corners, eighty faces, a hundred and twenty edges. A corner keeps
  // a heading, a radius and a band; a face keeps three corners; an edge keeps
  // two corners and the face on either side of it, which is the one thing the
  // outline is ever found from.
  var NV = 0, NF = 0, NE = 0;
  var ux, uy, uz, ur, ub;
  var f0, f1, f2, d0, d1, dl, dr;
  // And the same again, rewritten once a frame: where each corner turned to,
  // where it landed on the glass, and for each face whether the reader can see
  // it and how lit it is when they can.
  var wx, wy, wz, qx, qy, vis, tone;

  function carve() {
    var vs = [], fs = [], mid = {}, i, f;

    function corner(x, y, z, r) {
      var d = Math.sqrt(x * x + y * y + z * z);
      vs.push([x / d, y / d, z / d, r]);
      return vs.length - 1;
    }

    // Remembered on the way, because the two triangles either side of an edge
    // have to come out holding the same corner rather than one each: a mesh
    // with its seams unsewn has no edges to find an outline along.
    //
    // Half way along the edge, and half way between the two radii — but not
    // exactly. A midpoint that only ever splits the difference smooths the
    // twelve numbers into a dome by the second row of triangles, and a dome
    // with eighty panels on it is a planetarium rather than a rock. So each one
    // is knocked off the mean by a figure read out of the same table, at the
    // pair of corners it sits between. It is fixed like everything else about
    // this body, it is half the size of the twelve, and it is the whole of the
    // difference between a geodesic and a thing that has been hit.
    function half(a, b) {
      var lo = a < b ? a : b, hi = a < b ? b : a, key = lo * 64 + hi;
      if (key in mid) return mid[key];
      var p = vs[a], q = vs[b];
      var lump = 1 + (ROCK[(lo * 5 + hi * 7) % ROCK.length] - 0.95) * 0.55;
      return (mid[key] = corner(p[0] + q[0], p[1] + q[1], p[2] + q[2],
                                (p[3] + q[3]) / 2 * lump));
    }

    for (i = 0; i < ICO.length; i++) corner(ICO[i][0], ICO[i][1], ICO[i][2], ROCK[i]);
    for (i = 0; i < TRI.length; i++) {
      var t = TRI[i], ab = half(t[0], t[1]), bc = half(t[1], t[2]), ca = half(t[2], t[0]);
      fs.push([t[0], ab, ca], [t[1], bc, ab], [t[2], ca, bc], [ab, bc, ca]);
    }

    NV = vs.length;
    NF = fs.length;
    ux = new Float32Array(NV); uy = new Float32Array(NV); uz = new Float32Array(NV);
    ur = new Float32Array(NV); ub = new Uint8Array(NV);
    for (i = 0; i < NV; i++) {
      ux[i] = vs[i][0]; uy[i] = vs[i][1]; uz[i] = vs[i][2]; ur[i] = vs[i][3];
      // Which band a corner stands in: its latitude, mirrored north to south
      // the way everything else hung on this object is mirrored. The bass sits
      // round the waist and the bright end at the two poles, so a chord landing
      // fattens the rock about its middle — and it fattens it in the body's own
      // frame rather than the reader's, so the swelling rolls round with the
      // rock instead of staying stuck to the panel.
      ub[i] = Math.round(Math.abs(vs[i][1]) * (BANDS - 1));
    }

    f0 = new Uint8Array(NF); f1 = new Uint8Array(NF); f2 = new Uint8Array(NF);
    for (f = 0; f < NF; f++) {
      var i0 = fs[f][0], i1 = fs[f][1], i2 = fs[f][2];
      // Every face wound so its normal points out of the body, worked out here
      // rather than trusted from the table above. Which way a face is turned is
      // the whole of how the far side of the rock gets thrown away, and one
      // triangle wound backwards is a hole in the thing for as long as it faces
      // the reader.
      var ox = ux[i0] * ur[i0], oy = uy[i0] * ur[i0], oz = uz[i0] * ur[i0];
      var ax = ux[i1] * ur[i1] - ox, ay = uy[i1] * ur[i1] - oy, az = uz[i1] * ur[i1] - oz;
      var bx = ux[i2] * ur[i2] - ox, by = uy[i2] * ur[i2] - oy, bz = uz[i2] * ur[i2] - oz;
      if ((ay * bz - az * by) * ox + (az * bx - ax * bz) * oy +
          (ax * by - ay * bx) * oz < 0) { var s = i1; i1 = i2; i2 = s; }
      f0[f] = i0; f1[f] = i1; f2[f] = i2;
    }

    // The edges, each one found twice — once from the face on its left and once
    // from the face on its right — which is exactly how it learns both.
    var seen = {}, c0 = [], c1 = [], lf = [], rf = [];
    for (f = 0; f < NF; f++) {
      var v = [f0[f], f1[f], f2[f]];
      for (i = 0; i < 3; i++) {
        var p = v[i], q = v[(i + 1) % 3];
        var k = (p < q ? p : q) * 64 + (p < q ? q : p);
        if (k in seen) { rf[seen[k]] = f; continue; }
        seen[k] = c0.length;
        c0.push(p); c1.push(q); lf.push(f); rf.push(f);
      }
    }
    NE = c0.length;
    d0 = new Uint8Array(c0); d1 = new Uint8Array(c1);
    dl = new Uint8Array(lf); dr = new Uint8Array(rf);

    wx = new Float32Array(NV); wy = new Float32Array(NV); wz = new Float32Array(NV);
    qx = new Float32Array(NV); qy = new Float32Array(NV);
    vis = new Uint8Array(NF); tone = new Uint8Array(NF);
  }

  carve();

  // The rock, turned and put on the glass. It is the only place in this file
  // where anything is in three dimensions at all — everything after it reads
  // qx and qy and never asks what happened.
  //
  // Three angles at three speeds with no common multiple between them, which is
  // the difference between tumbling and spinning: the axis it turns about is
  // itself turning, the way a rock in free fall does and a wheel does not. All
  // three are slow. A body this lumpy is legible at the speed of a minute hand
  // and unreadable at anything much faster, and the panel it hangs in is
  // something a reader has open for the length of a chapter.
  function tumble(now, base, L, m) {
    var i, f;
    var a = now * 0.000103, b = now * 0.000067, c = now * 0.000041;
    var sa = Math.sin(a), ca = Math.cos(a);
    var sb = Math.sin(b), cb = Math.cos(b);
    var sc = Math.sin(c), cc = Math.cos(c);
    // Rz·Ry·Rx multiplied out once rather than three passes over forty-two
    // corners: nine numbers, and nothing allocated to hold them.
    var m00 = cc * cb, m01 = cc * sb * sa - sc * ca, m02 = cc * sb * ca + sc * sa;
    var m10 = sc * cb, m11 = sc * sb * sa + cc * ca, m12 = sc * sb * ca - cc * sa;
    var m20 = -sb,     m21 = cb * sa,                m22 = cb * ca;
    var eye = base * LENS;
    for (i = 0; i < NV; i++) {
      // Off the fastest of the three envelopes, so the corners visibly go in
      // and out with the spectrum instead of the body merely trembling.
      var d = base * (ur[i] + (L[ub[i]] - m) * 0.7);
      var x = ux[i] * d, y = uy[i] * d, z = uz[i] * d;
      var X = m00 * x + m01 * y + m02 * z;
      var Y = m10 * x + m11 * y + m12 * z;
      var Z = m20 * x + m21 * y + m22 * z;
      wx[i] = X; wy[i] = Y; wz[i] = Z;
      // The lens: one divide per corner, and most of what tells a reader they
      // are looking at a solid rather than at the outline of one. The near side
      // of the body comes out a quarter larger than the far side, so a face
      // rolling towards them grows on the way round.
      var s = eye / (eye - Z);
      qx[i] = cx + X * s;
      qy[i] = cy + Y * s;
    }
    // Where the light is standing: the same angle the rings shine along, leaned
    // a little towards the reader so the body has a near side as well as a lit
    // one. Written out already unit length, because it is a constant with a
    // turning handle on it and not a vector anybody needs to measure.
    var at = now * 0.00034;
    var lx = Math.cos(at) * 0.851, ly = Math.sin(at) * 0.851, lz = 0.527;
    for (f = 0; f < NF; f++) {
      var j0 = f0[f], j1 = f1[f], j2 = f2[f];
      var ex = wx[j1] - wx[j0], ey = wy[j1] - wy[j0], ez = wz[j1] - wz[j0];
      var gx = wx[j2] - wx[j0], gy = wy[j2] - wy[j0], gz = wz[j2] - wz[j0];
      var nx = ey * gz - ez * gy, ny = ez * gx - ex * gz, nz = ex * gy - ey * gx;
      var mx = (wx[j0] + wx[j1] + wx[j2]) / 3;
      var my = (wy[j0] + wy[j1] + wy[j2]) / 3;
      var mz = (wz[j0] + wz[j1] + wz[j2]) / 3;
      // Facing the reader, which with a lens in the way is not the same
      // question as pointing along the view: a face out near the edge of the
      // body can have its back to an eye it is still leaning towards. So the
      // test is against the line to the eye rather than against the axis, and
      // what it leaves standing is two fifths of the surface rather than half,
      // which is what looking at a real one buys you.
      vis[f] = nx * -mx + ny * -my + nz * (eye - mz) > 0 ? 1 : 0;
      var len = Math.sqrt(nx * nx + ny * ny + nz * nz) || 1;
      var v = (nx * lx + ny * ly + nz * lz) / len;
      tone[f] = v <= 0 ? 0 : Math.min(SHADE.length - 1, (v * SHADE.length) | 0);
    }
  }

  // The near side of the body as one shape, for the scanlines that want the
  // outline rather than the mesh. Overlapping triangles under the non-zero rule
  // are their own union, so this is the silhouette without anybody having to
  // work out where the silhouette is.
  function hull() {
    cg.beginPath();
    for (var f = 0; f < NF; f++) {
      if (!vis[f]) continue;
      cg.moveTo(qx[f0[f]], qy[f0[f]]);
      cg.lineTo(qx[f1[f]], qy[f1[f]]);
      cg.lineTo(qx[f2[f]], qy[f2[f]]);
      cg.closePath();
    }
  }

  // The glass, and the plainest reading in the whole object. Bright bands across
  // the body, one per band of the spectrum, each as long as its band is loud and
  // clipped to the rock — so a loud bar fills it out to the outline and a quiet
  // one leaves nothing but a stripe in the middle. It is a spectrum lying on its
  // side inside a rock, which is what a rock lit from within by music ought to
  // look like when you look straight at it. The colour still runs along the
  // light rather than across it, so the bands fade out on the side facing away.
  //
  // They are the one thing on the body that does not turn with it. These are
  // the room's reading laid over the rock rather than a marking on it, and a
  // reading that rolled away out of sight would be one you could not take.
  function slats(now, base, al) {
    var a = now * 0.00034;
    var co = Math.cos(a) * base, si = Math.sin(a) * base;
    var gr = cg.createLinearGradient(cx - co, cy - si, cx + co, cy + si);
    gr.addColorStop(0, "rgba(33, 243, 255, 0.12)");
    gr.addColorStop(0.55, "rgba(255, 244, 224, 0.55)");
    gr.addColorStop(1, "rgba(" + SUN + ", 0.16)");
    cg.save();
    cg.clip();
    cg.strokeStyle = gr;
    cg.lineWidth = 1;
    // Under the mesh rather than beside it: the facets are what the near face is
    // for, and bands bright enough to compete with them turn the whole body into
    // one lit slab.
    cg.globalAlpha = al * (0.1 + glow * 0.34);
    cg.beginPath();
    for (var i = 0; i < SLATS; i++) {
      // Mirrored, like everything else hung on this object, so the loudest
      // bands sit across the middle of the rock and the quiet ends of the
      // spectrum are the stripes nearest its top and bottom.
      var w = base * (0.3 + lev[0][mir(i, SLATS)] * 1.3);
      var y = cy + (i / (SLATS - 1) - 0.5) * base * 2.1;
      cg.moveTo(cx - w, y);
      cg.lineTo(cx + w, y);
    }
    cg.stroke();
    cg.restore();
  }

  // The faces, flat-shaded, one fill per step of the ramp. Everything in this
  // panel is drawn in lighter, so nothing in here can put a shadow anywhere: a
  // face with its back to the light is not darkened, it is simply given almost
  // nothing, and the star behind the rock goes on burning through it. Which is
  // the right answer for a rock made of glass and would be the wrong one for
  // any other kind.
  function facets(al) {
    var t, f, any, k = al * (0.06 + glow * 0.46);
    for (t = 0; t < SHADE.length; t++) {
      any = false;
      cg.beginPath();
      for (f = 0; f < NF; f++) {
        if (!vis[f] || tone[f] !== t) continue;
        cg.moveTo(qx[f0[f]], qy[f0[f]]);
        cg.lineTo(qx[f1[f]], qy[f1[f]]);
        cg.lineTo(qx[f2[f]], qy[f2[f]]);
        cg.closePath();
        any = true;
      }
      if (!any) continue;
      cg.fillStyle = "rgba(" + SHADE[t] + ", 1)";
      // Bent rather than straight, so the step from the darkest face to the
      // next one is a good deal smaller than the step into the brightest. A
      // linear ramp over six steps reads as six terraces; this one reads as a
      // curve somebody has quantised, which is what it is.
      cg.globalAlpha = k * (0.08 + Math.pow(t / (SHADE.length - 1), 1.8) * 0.92);
      cg.fill();
    }
  }

  // The mesh: facets, not craters. A rock with pits in it is a moon, and the one
  // this was drawn from is a rock made of glass — the light living in the edges
  // rather than on the faces, in the three colours it always wore and on the
  // three thirds of the spectrum it always answered. Three gradients and seven
  // strokes for a hundred and twenty edges: a bucket per colour, and none of
  // them a path of its own.
  //
  // The far side goes first and faintly. It is the one thing in here drawn from
  // behind the body, it is the reason the rock reads as glass rather than as a
  // shell, and it is kept dim enough that a reader takes it for depth instead of
  // for clutter.
  function wires(now, base, al) {
    var c, e, gr;
    var a = now * 0.00034;
    var co = Math.cos(a) * base, si = Math.sin(a) * base;
    cg.lineCap = "round";
    cg.lineJoin = "round";
    cg.beginPath();
    for (e = 0; e < NE; e++) {
      if (vis[dl[e]] || vis[dr[e]]) continue;
      cg.moveTo(qx[d0[e]], qy[d0[e]]);
      cg.lineTo(qx[d1[e]], qy[d1[e]]);
    }
    cg.strokeStyle = "rgba(160, 75, 255, 1)";
    cg.lineWidth = 0.7;
    cg.globalAlpha = al * (0.07 + glow * 0.14);
    cg.stroke();
    for (c = 0; c < 3; c++) {
      cg.beginPath();
      for (e = c; e < NE; e += 3) {
        if (!vis[dl[e]] && !vis[dr[e]]) continue;
        cg.moveTo(qx[d0[e]], qy[d0[e]]);
        cg.lineTo(qx[d1[e]], qy[d1[e]]);
      }
      // One gradient per colour laid along the light the rest of the object
      // shines by, so the edges on the near side of the rock are white-hot and
      // the ones round the far side are structure and nothing more.
      gr = cg.createLinearGradient(cx - co, cy - si, cx + co, cy + si);
      gr.addColorStop(0, "rgba(" + EDGE[c] + ", 0.1)");
      gr.addColorStop(0.6, "rgba(" + EDGE[c] + ", 0.85)");
      // White where the light actually strikes and coloured again past it. Pearl
      // all the way to the lit edge looked right on one colour and washed all
      // three of them out together, which is three gradients spent on grey.
      gr.addColorStop(0.9, "rgba(242, 233, 255, 1)");
      gr.addColorStop(1, "rgba(" + EDGE[c] + ", 1)");
      cg.strokeStyle = gr;
      // Thickness on its own third of the spectrum as well as brightness. An
      // edge that only brightens is a lamp; one that also fattens is a string.
      cg.lineWidth = 2.2 + en[c] * 2.6;
      cg.globalAlpha = al * (0.03 + en[c] * 0.16);
      cg.stroke();
      cg.lineWidth = 0.6 + en[c] * 1.2;
      cg.globalAlpha = al * (0.2 + en[c] * 0.68);
      cg.stroke();
    }
  }

  // Where the near side ends. An edge with a face on the reader's side of it
  // and a face on the far side is the outline of the body at this instant, and
  // it is found rather than read off a table, which is the whole of why the
  // shape of the thing changes as it rolls. It gets the same four-stroke bloom
  // the rings get and its corners left sharp, because the flat rock's rim had
  // both and losing them would have been the price of going round.
  function brink(now, base, al, t) {
    cg.beginPath();
    for (var e = 0; e < NE; e++) {
      if (vis[dl[e]] === vis[dr[e]]) continue;
      cg.moveTo(qx[d0[e]], qy[d0[e]]);
      cg.lineTo(qx[d1[e]], qy[d1[e]]);
    }
    shine("33, 243, 255", now, base, al, 2.2, t, true);
  }

  function rock(now, rr, al) {
    var L = lev[0], M = lev[1], c, k, m = 0;
    for (k = 0; k < BANDS; k++) m += L[k];
    m /= BANDS;
    var base = rr * BODY * (1 + m * 0.1);
    tumble(now, base, L, m);
    // A third of the spectrum each for the three colours of the mesh, off the
    // second envelope where the body itself rides the first, so the inside of
    // the rock is a beat behind its outline: cyan on the bass, magenta on the
    // middle, amber on the bright end. A mesh where every line pulses on the
    // same number is a mesh on a dimmer, and the reason for having three
    // colours was to have three things to watch.
    var t = BANDS / 3;
    for (c = 0; c < 3; c++) {
      en[c] = 0;
      for (k = Math.round(c * t); k < Math.round((c + 1) * t); k++) en[c] += M[k];
      en[c] /= t;
    }
    hull();
    slats(now, base, al);
    facets(al);
    wires(now, base, al);
    brink(now, base, al, Math.min(1, m * 2.2));
  }

  // The rings on their way out. Each keeps the shape it was born with and
  // takes it outwards, thinning and fading and turning a little as it goes, so
  // a chord that landed three seconds ago is still crossing the panel while
  // the next one lands on top of it.
  function waves(now, rr, al, dt) {
    for (var w = 0; w < WAVES; w++) {
      var v = wave[w];
      if (v.t >= 1) continue;
      v.t = Math.min(1, v.t + dt / 2.4);
      var e = 1 - Math.pow(1 - v.t, 2.2);        // away quickly, then coasting
      var base = rr * (0.86 + e * 2);
      // The hand-thrown one breathes on its way across: three swells, each
      // shallower than the last, over the two and a half seconds it takes to
      // cross the panel. It is the same ring as all the others and it is doing
      // one thing they are not, which is how a reader works out that the thing
      // answered them rather than the music happening to land as they clicked.
      if (v.hand) base *= 1 + Math.sin(v.t * 18.85) * 0.06 * (1 - v.t);
      // The lobes it left with stay lobes most of the way out, and they go
      // both ways round the circle, so what crosses the panel is wavy rather
      // than a circle with a texture on it.
      var bend = rr * (0.32 - v.t * 0.14);
      for (var k = 0; k < RING; k++) {
        var a = k / RING * 6.28318 + v.t * 0.55;
        var d = base + v.sh[band(k)] * bend;
        px[k] = cx + Math.cos(a) * d;
        py[k] = cy + Math.sin(a) * d;
      }
      loop();
      var c = HUES[v.hue], f = al * v.amp * Math.pow(1 - v.t, 1.6);
      var a2 = now * 0.00034 + v.t * 2.4;
      var ax = Math.cos(a2) * base * 1.2, ay = Math.sin(a2) * base * 1.2;
      var gr = cg.createLinearGradient(cx - ax, cy - ay, cx + ax, cy + ay);
      gr.addColorStop(0, "rgba(" + c + ", 0.25)");
      gr.addColorStop(0.45, "rgba(" + c + ", 1)");
      gr.addColorStop(0.5, "rgba(242, 233, 255, 1)");
      gr.addColorStop(0.55, "rgba(" + c + ", 1)");
      gr.addColorStop(1, "rgba(" + c + ", 0.25)");
      cg.strokeStyle = gr;
      var t = 1.1 + (1 - v.t) * 1.6;             // thinning as it goes
      cg.lineWidth = t * 5; cg.globalAlpha = f * 0.09; cg.stroke();
      cg.lineWidth = t * 2; cg.globalAlpha = f * 0.24; cg.stroke();
      cg.lineWidth = t;     cg.globalAlpha = f * 0.85; cg.stroke();
    }
  }

  function glints(now, rr, al) {
    cg.strokeStyle = "rgba(242, 233, 255, 1)";
    cg.fillStyle = "rgba(242, 233, 255, 1)";
    cg.lineWidth = 1;
    for (var i = 0; i < GLINTS; i++) {
      var a = now * (0.00022 + i * 0.00009) + i * 1.9;
      var d = rr * (1.05 + (i % 3) * 0.26);
      var v = lev[0][BANDS - 1 - i * 3];
      var s = (0.35 + v * 1.6) * rr * 0.08;
      var x = cx + Math.cos(a) * d, y = cy + Math.sin(a) * d;
      cg.globalAlpha = al * (0.22 + v * 0.7);
      cg.beginPath();
      cg.moveTo(x - s, y); cg.lineTo(x + s, y);
      cg.moveTo(x, y - s); cg.lineTo(x, y + s);
      cg.stroke();
      cg.beginPath();
      cg.arc(x, y, 1.1, 0, 6.28318);
      cg.fill();
    }
  }

  // The one circle in here that stays a circle. It used to be the one line that
  // answered nothing, on the argument that an object needs something that holds
  // still — but a readout with a dead line in it invites the reader to wonder
  // which of the others are honest. So it keeps its shape and gives up its
  // radius: it stands off further while the room is loud, like the last ring of
  // a bell, and it is the only thing in here that reports the level and nothing
  // else at all.
  function halo(now, rr, al) {
    cg.beginPath();
    // The ceiling on how far it stands off is the corner of a notes page, where
    // the whole object lives in a canvas the size of a stamp: a ring that leaves
    // the canvas on a loud bar is not a ring, it is four arcs.
    cg.arc(cx, cy, rr * (1.5 + glow * 0.2), 0, 6.28318);
    var a = now * 0.00034 + 1.9;
    var ax = Math.cos(a) * rr * 1.7, ay = Math.sin(a) * rr * 1.7;
    var gr = cg.createLinearGradient(cx - ax, cy - ay, cx + ax, cy + ay);
    gr.addColorStop(0, "rgba(160, 75, 255, 0.04)");
    gr.addColorStop(0.5, "rgba(242, 233, 255, 0.8)");
    gr.addColorStop(1, "rgba(160, 75, 255, 0.04)");
    cg.strokeStyle = gr;
    cg.lineWidth = 6; cg.globalAlpha = al * 0.05; cg.stroke();
    cg.lineWidth = 1; cg.globalAlpha = al * 0.3;  cg.stroke();
  }

  function draw(now, dt) {
    cg.clearRect(0, 0, cv.clientWidth, cv.clientHeight);
    // Arriving, it overshoots a little and settles, which is the difference
    // between a thing appearing and a switch being thrown. Leaving, it goes
    // straight down to nothing: it is not being switched off, it is going.
    var e = 1 - Math.pow(1 - life, 3);
    var grow = e + Math.sin(e * Math.PI) * 0.1;
    var al = Math.min(1, life * 1.7);
    if (gone > 0) {
      grow = Math.pow(1 - gone, 1.7);
      al = Math.pow(1 - gone, 1.2);
    }
    // It floats. Two slow circles at odds with each other on each axis, so it
    // never repeats anywhere a reader could catch it repeating.
    cx = hx + (Math.sin(now * 0.00021) * 0.13 + Math.sin(now * 0.00013) * 0.07) * R;
    cy = hy + (Math.cos(now * 0.00017) * 0.11 + Math.sin(now * 0.00029) * 0.05) * R;
    // Added to the drift rather than replacing it, so a thing that has been
    // shoved goes on floating while it recovers. The rock, the rings, the
    // corona and the light are all measured off cx and cy, which is why they go
    // as one thing and not as a rock leaving the middle of its own light. The
    // weather takes the same shove off a spring of its own — see the poke.
    shift(dt);
    cx += sx * R;
    cy += sy * R;
    // And it throbs on the bottom of the spectrum, because that is where this
    // piece keeps its heartbeat.
    var bass = (lev[0][0] + lev[0][1] + lev[0][2] + lev[0][3]) / 4;
    var rr = R * grow * (1 + Math.sin(now * 0.00043) * 0.02 + bass * 0.13 + kick(dt));
    sz = rr;
    // Where the hand is, asked once a frame and after the object has finished
    // deciding where it is: the rings lean at a cursor measured off this
    // frame's middle rather than off last frame's.
    sense(dt);
    cg.globalCompositeOperation = "lighter";
    clouds(now, rr, al, 0);
    core(rr, al);
    waves(now, rr, al, dt);
    glare(now, rr, al);
    corona(now, rr, al);
    for (var i = RINGS.length - 1; i >= 0; i--) ring(i, now, rr, al);
    rock(now, rr, al);
    clouds(now, rr, al, 1);
    gloss(now, rr, al);
    halo(now, rr, al);
    glints(now, rr, al);
    cg.globalCompositeOperation = "source-over";
    cg.globalAlpha = 1;
  }

  function beat(now) {
    raf = 0;
    if (!cv) return;
    var dt = last ? Math.min(0.05, (now - last) / 1000) : 0.016;
    last = now;
    if (now - took > 900) { took = now; place(); }

    if (gone > 0) gone = Math.min(1, gone + dt / 0.62);
    else if (life < 1) life = Math.min(1, life + dt / 0.9);

    listen(dt);
    draw(now, dt);

    if (gone >= 1) { tear(); return; }
    raf = requestAnimationFrame(beat);
  }

  function run() { if (!raf) { last = 0; raf = requestAnimationFrame(beat); } }

  // A reader who asked for less motion gets the same object holding still: it
  // is there, it is lit, and it says the room is on, which is all the four
  // bars in the corner ever said either.
  function paint() {
    place();
    for (var i = 0; i < RINGS.length; i++)
      for (var k = 0; k < BANDS; k++) {
        lev[i][k] = 0.34 + Math.sin(k / BANDS * 6.28318) * 0.16;
        // One frame of the trace, held. Three plain circles would be the
        // honest reading of a wave nobody is allowed to see move, and it would
        // also be the one shape this object is not. Each ring is turned a
        // little further back than the last, which is where the wake went.
        var t = k / BANDS * 6.28318 - i * 0.5;
        tr[i][k] = Math.sin(t * 2.5) * 0.66 + Math.sin(t * 5) * 0.24;
      }
    glow = 0.32;
    life = 1;
    gone = 0;
    draw(0, 0);
  }

  // The room arrived, by whatever route: a hand on the switch, or a page that
  // came in with the answer already in storage. Both get the entrance, because
  // a chapter arriving is the moment for one.
  function show() {
    if (cv) return;
    make();
    life = 0;
    gone = 0;
    // A frame's wait before the still one is drawn, because the panel it
    // measures itself against has only just been laid out. The moving one
    // measures again as it goes and never notices.
    if (still) requestAnimationFrame(function () { if (cv) paint(); });
    else run();
    mouth();
  }

  function fade() {
    hush();
    if (!cv) return;
    if (still) { tear(); return; }
    gone = 0.001;
    run();
  }

  // ---- the poke -----------------------------------------------------------
  // Everything else in this panel answers the music. This one thing answers the
  // reader, and it answers the way a thing floating in a tank answers a hand on
  // the glass: it is not a button, it does not do anything, it moves.
  //
  // The canvas keeps pointer-events: none. It is a readout and not a lid, and
  // it is a readout laid over the whole panel — a rock that swallowed clicks
  // would be swallowing them for the plate and the credits underneath it as
  // well. So the disc is tested against the pointer instead, on the window, and
  // no click is ever eaten: whatever the reader hit, they still hit it. A click
  // that landed on furniture is a click on the furniture however much rock
  // happens to be drifting over it at that moment, which is why this hands the
  // event straight back if there is a link or a button under it. The one thing
  // taken away from a press that did land on the object is the caret it would
  // have dropped into the sentence behind, and the argument for that is with
  // the handler that does it.
  //
  // Three things arrive together, because that is what one event looks like
  // from the outside: it shoves off, it growls about it, and it spills a ring.
  // None of the three is a state and there is nothing to be in the middle of,
  // so a reader who pokes it four times gets four of each, and the only thing
  // stopping the fourth one sending it off the page is that the shove does not
  // accumulate past the speed of one shove.
  //
  // And a reader who asked for less motion gets the growl and nothing else.
  // There is no frame loop at all for that reader — the object is a still
  // picture — so a spring would settle in one jump and a ring would be a circle
  // painted at radius nought. The rock still answers; it answers with the one
  // part of this that does not move.

  var PROD = 7;                            // the shove, in radii per second. It
                                           // peaks about a seventh of a radius
                                           // out, a twelfth of a second after
                                           // the press, and is back where it
                                           // started inside a second: enough to
                                           // see it flinch and not enough to
                                           // lose the thing off its own panel
  var PSTIFF = 190, PDAMP = 17;            // slacker than the thought's spring
                                           // and damped harder, because the two
                                           // are different events: a thought is
                                           // felt from the inside and springs
                                           // back, and a shove is felt from the
                                           // outside and is drifted back out of
  // And a second spring for the weather, because the rock and the gas around it
  // are not the same kind of thing and moving them on one number said they were.
  // The first pass did move the clouds — they hang off the same middle as
  // everything else — but a nine-pixel step in a soft lobe two hundred pixels
  // across is not a step anybody can see, so the panel read as a rock jumping
  // out of a sky that stayed where it was.
  //
  // Slacker and slower: it goes further, it gets there a little after the rock
  // does, and it is still drifting back when the rock has finished. That is the
  // difference between weather and scenery, and it costs four numbers.
  var GUST = 10;                           // the shove the gas takes
  var GSTIFF = 95, GDAMP = 12;             // half the rock's spring, near enough
  var sx = 0, sy = 0, svx = 0, svy = 0;    // how far off it has been pushed, in
                                           // radii, and how fast it is going
  var gx = 0, gy = 0, gvx = 0, gvy = 0;    // and the same for the weather
  var poked = -9e9;                        // and when, so that a pointer that
                                           // reports one press as two events
                                           // does not make two of everything

  // The same second-order system the thought uses, on the two axes the thought
  // was not using. Written as a spring rather than as a curve for the same
  // reason it was there: a curve has to be told how long to take, and a spring
  // only has to be told how hard it was hit — so a poke on the rim and a poke
  // through the middle are one piece of code and two different motions.
  function shift(dt) {
    if (!sx && !sy && !svx && !svy && !gx && !gy && !gvx && !gvy) return;
    svx += (-PSTIFF * sx - PDAMP * svx) * dt;
    svy += (-PSTIFF * sy - PDAMP * svy) * dt;
    sx += svx * dt;
    sy += svy * dt;
    gvx += (-GSTIFF * gx - GDAMP * gvx) * dt;
    gvy += (-GSTIFF * gy - GDAMP * gvy) * dt;
    gx += gvx * dt;
    gy += gvy * dt;
    if (Math.abs(sx) + Math.abs(sy) < 0.0006 &&
        Math.abs(svx) + Math.abs(svy) < 0.006) sx = sy = svx = svy = 0;
    if (Math.abs(gx) + Math.abs(gy) < 0.0006 &&
        Math.abs(gvx) + Math.abs(gvy) < 0.006) gx = gy = gvx = gvy = 0;
  }

  // The complaint. Something that has watched this cabinet get built in four
  // hundred universes has been prodded by somebody who has been reading for four
  // minutes, and it has a view about that.
  //
  // Anger, in a room this quiet, is not volume. It is three things the rest of
  // the piece never does. It is low — the chord's own bass note, the one the
  // pad is already sitting on, folded into the octave the piece keeps its
  // bottom in. It is rough — two sawtooths where everything else here is sines
  // and filtered noise, with the growl rate wobbling on top of them, which is
  // the difference between a note and a throat. And it sags — the whole thing
  // bends a tone and a half downwards while it dies, because a pitch that falls
  // is a complaint and a pitch that rises is a question.
  //
  // It is still in the key, and that is deliberate rather than timid: the root
  // is the room's, so the growl belongs to the room. What does not belong to
  // anything is the second saw, a semitone over the first. That interval is the
  // rudest one there is and it is the only part of this that is out of the
  // chord, which makes it the part carrying the opinion.
  //
  // Drier than anything else in here. The reverb is what makes this piece sound
  // like a large room, and a large room is exactly what a thing snapping at you
  // from a foot away is not in. A third of the usual send, and it stays close.
  var grr = 0;                             // which poke this is, so that four in
                                           // a row are four growls rather than
                                           // one growl four times

  function snarl(t) {
    var c = chord(Math.floor((((step % CYCLE) + CYCLE) % CYCLE) / 16));
    // The octave over the room's own bass note, and the octave is the whole
    // trick. On the bass note itself this was inaudible and the reason was not
    // the level: the pad is already sitting on that note with four voices, so a
    // growl there is a growl inside something louder, and what came out was the
    // pad getting very slightly fatter for half a second. One octave up is a
    // hole in this arrangement — under the chord, over the bass — and a thing
    // that nothing else is doing is heard at a third of the volume of a thing
    // competing.
    var f = mtof(low(c.root) + 12);
    var i, o;
    var env = ctx.createGain();           // the envelope
    env.gain.setValueAtTime(0.0001, t);
    env.gain.exponentialRampToValueAtTime(0.11, t + 0.007);
    env.gain.exponentialRampToValueAtTime(0.0001, t + 0.52);
    var am = ctx.createGain();             // and the throat in it
    am.gain.value = 0.72;
    var lfo = ctx.createOscillator();
    lfo.type = "triangle";
    lfo.frequency.value = 23 + (grr++ % 3) * 5;
    var amt = ctx.createGain();
    amt.gain.value = 0.28;
    lfo.connect(amt);
    amt.connect(am.gain);
    var lp = ctx.createBiquadFilter();
    lp.type = "lowpass";
    // Open enough to keep four or five harmonics of a sawtooth and closing onto
    // the fundamental as it dies. Shut tighter than this and the teeth go with
    // it: what is left is a sine with a wobble on it, which is a hum rather
    // than a complaint.
    lp.Q.value = 2.2;
    lp.frequency.setValueAtTime(2600, t);
    lp.frequency.exponentialRampToValueAtTime(520, t + 0.42);
    for (i = 0; i < 2; i++) {
      o = ctx.createOscillator();
      o.type = "sawtooth";
      // The second one a semitone up, and it arrives a hair late so the two of
      // them start as one thing going wrong rather than as a chord.
      var b = i ? 1.0595 : 1;
      o.frequency.setValueAtTime(f * b, t + i * 0.012);
      o.frequency.exponentialRampToValueAtTime(f * b * 0.84, t + 0.36);
      o.connect(lp);
      o.start(t + i * 0.012);
      o.stop(t + 0.56);
    }
    lp.connect(am);
    am.connect(env);
    env.connect(dry);
    var wet = ctx.createGain();
    wet.gain.value = 0.34;
    env.connect(wet);
    wet.connect(send);
    lfo.start(t);
    lfo.stop(t + 0.56);
    // The air at the front of it. Sixty milliseconds of noise is what turns a
    // low sound into a low sound made by something — the consonant the growl
    // needs to be heard as a growl rather than as a fault in the speakers.
    if (!noise) return;
    var s = ctx.createBufferSource();
    s.buffer = noise;
    s.loop = true;
    var bp = ctx.createBiquadFilter();
    bp.type = "bandpass";
    bp.Q.value = 1.1;
    bp.frequency.setValueAtTime(2400, t);
    bp.frequency.exponentialRampToValueAtTime(700, t + 0.1);
    var g = ctx.createGain();
    g.gain.setValueAtTime(0.0001, t);
    g.gain.linearRampToValueAtTime(0.03, t + 0.012);
    g.gain.exponentialRampToValueAtTime(0.0001, t + 0.13);
    s.connect(bp);
    bp.connect(g);
    g.connect(dry);
    s.start(t);
    s.stop(t + 0.16);
  }

  // Did that land on the object, and where. Two events want the answer and they
  // want it from the same disc, so it is asked once and here: the press that
  // moves the thing, and the press the browser would otherwise have started
  // selecting a paragraph with.
  //
  // Where the object is on the reader's screen is not where its canvas is: it
  // drifts around inside its own box, and on the cover and the notes that box is
  // a fixed corner of the window. One rect per press is nothing.
  //
  // The disc is the rings and not the halo. The halo stands a long way off on a
  // loud bar, and a target that grows when the music does is a target that
  // moves.
  function caught(e) {
    if (!cv || !sz || gone > 0) return null;
    if (e.button > 0) return null;         // a right-click is a menu, not a poke
    if (reach(e)) return null;             // furniture first, always
    var b = cv.getBoundingClientRect();
    var dx = b.left + cx - e.clientX, dy = b.top + cy - e.clientY;
    var d = Math.sqrt(dx * dx + dy * dy);
    if (d > sz * 1.25) return null;
    return { d: d, dx: dx, dy: dy };
  }

  // A poke is not a text cursor. The rock hangs over a panel with a sentence in
  // it, and a reader who prodded the thing twice got a word of that sentence
  // selected for their trouble — the browser being right about a press on a
  // paragraph and wrong about this one. So a press that landed on the object is
  // taken out of that: no caret, no word, no drag-select started under a thing
  // that is plainly not text.
  //
  // On mousedown rather than on the pointerdown that does everything else,
  // because cancelling a pointerdown does nothing for a mouse: mousedown is not
  // a compatibility event there, it is the original, and the caret belongs to
  // it. What a finger would lose to this is not a selection but the page
  // scrolling, and a touch never gets here — the mousedown a tap eventually
  // produces arrives long after the scroll it did not do.
  function bite(e) { if (caught(e) && e.cancelable) e.preventDefault(); }

  function prod(e) {
    if (!awake()) return;
    var g = caught(e);
    if (!g) return;
    var t = ctx.currentTime;
    if (t - poked < 0.09) return;
    poked = t;
    snarl(t);
    if (still) return;
    // Away from the finger, and hardest at the edge. A shove through the middle
    // of a thing is mostly a shove into it, and a thing shoved into does not go
    // anywhere much. Dead centre there is no direction in it at all, and that
    // one goes up, which reads as a thing bobbing rather than as a thing with a
    // bug in it.
    var d = g.d, dx = g.dx, dy = g.dy;
    if (d < 1) { dx = 0; dy = -1; d = 1; }
    var k = 0.45 + 0.55 * Math.min(1, d / sz);
    svx += dx / d * PROD * k;
    svy += dy / d * PROD * k;
    var v = Math.sqrt(svx * svx + svy * svy);
    if (v > PROD) { svx = svx / v * PROD; svy = svy / v * PROD; }
    gvx += dx / d * GUST * k;
    gvy += dy / d * GUST * k;
    v = Math.sqrt(gvx * gvx + gvy * gvy);
    if (v > GUST) { gvx = gvx / v * GUST; gvy = gvy / v * GUST; }
    // And it spills one, carrying whatever the spectrum was doing at the moment
    // it was touched. The room's own rings report the room; this one reports the
    // room and the reader at once, which is the only honest thing it could
    // carry.
    throw_(0.2 + fast, true);
  }

  // ---- the field ----------------------------------------------------------
  // The poke answers a hand that has arrived. This answers one on its way,
  // which is a different thing to be: a reader whose cursor wanders across the
  // panel finds that the object knew about it before they got there, and finds
  // out how close they are by how hard it is straining.
  //
  // It is drawn the way the rest of this object is drawn, which is to say as a
  // shape rather than as a highlight. The three rings lean into a lobe pointing
  // at the cursor, each in proportion to its own radius; the far side of them
  // is left exactly where it was. What sells it as a charge rather than as
  // jelly is that the lobe narrows as the hand closes and never quite holds
  // still.
  //
  // And it is heard, which is where most of it actually lives. A field you can
  // only see is a decoration; one you can find with your eyes shut is a field.
  // The voice is built the first time a hand comes near and then never rebuilt:
  // two sawtooths a few cents apart, so the pair beats slowly against itself
  // instead of sitting there being a test tone, under a lowpass that is a hum
  // at arm's length and a rasp at the rim; a narrow band of noise wandering
  // above them, which is the crackle; and a square wave chopping the whole
  // thing at a rate that belongs to a wire rather than to a key, which is the
  // teeth. The filter carries nearly all of the word "closer" — the level
  // barely moves next to four octaves of cutoff opening.
  //
  // The last inch is the loud one, on purpose. Every number here comes off the
  // square or the cube of the reading rather than the reading itself, so across
  // most of the field there is a hum a reader might not consciously notice, and
  // the last third of the way in is where it turns into something. A field with
  // a linear falloff announces exactly where its edge was, and an edge is the
  // one thing this should not have.
  //
  // Tuned to the chord in the air, like everything else in this book a reader
  // can cause: the drone sits an octave over the room's own bass note, in the
  // hole this arrangement keeps between the bass and the chord, so a cursor
  // parked over the panel for a minute is a note held in the key rather than an
  // alarm going off. And it is downstream of the same gain everything else is,
  // which means the one switch there is still switches it off. Somebody who
  // silenced the room did not silence it in order to be buzzed at instead.
  //
  // A reader who asked for less motion gets the sound and not the lean, which
  // is the bargain the poke already struck. There is no frame loop for them, so
  // the hand is read where it is reported and the object holds the shape it was
  // painted in.

  var FIELD = 3.2;   // how far out a hand is felt, in drawn radii. Nearer than
                     // three and the object only notices a cursor already on
                     // top of it, which is a button; much further and the whole
                     // panel hums at anybody merely reading the page
  var BEND = 0.34;   // how far the lobe reaches past the ring at the rim, in
                     // radii. About a third, because the rings already swing by
                     // a third on the music, and a lean that dwarfs the wave
                     // turns a readout into a puppet
  var CHASE = 0.14;  // how fast the reading follows the hand, per frame at
                     // sixty. Slower than the eye and quicker than the drift: a
                     // cursor flicked across the panel leaves a lean trailing
                     // after it rather than throwing a switch
  var FIZZ = 0.05;   // and the ceiling on the whole voice, which is under the
                     // growl and a long way under the pad

  var tipx = 0, tipy = 0;                  // the hand, where the window keeps it
  var hover = false;                       // and whether there is one at all
  var near = 0, bear = 0;                  // the reading: how close, and which
                                           // way
  var fizz = null;                         // the voice, built once and kept

  // Where the hand is in the object's own terms. The canvas box is measured
  // every frame here rather than on place()'s once-a-second clock, and the
  // difference between the two is the point: the berth the object hangs in is
  // the same berth a second later, but the distance to a cursor is wrong the
  // moment the page scrolls under it. One rect off a tree nothing has written
  // to is a lookup rather than a layout, and it is only ever asked while a hand
  // is in play — a reader on a phone, or one going through the book on the
  // arrow keys, never pays for it at all.
  function sense(dt) {
    var want = 0, to = bear;
    if (hover && cv && sz && gone <= 0) {
      var b = cv.getBoundingClientRect();
      var dx = tipx - (b.left + cx), dy = tipy - (b.top + cy);
      var d = Math.sqrt(dx * dx + dy * dy);
      var far = sz * FIELD;
      if (d < far) {
        want = Math.min(1, (far - d) / (sz * (FIELD - 1)));
        // Eased at both ends, so there is no seam where the field begins and
        // none where it stops getting closer either.
        want = want * want * (3 - 2 * want);
      }
      // Dead centre has no direction in it, and an angle worked out from two
      // pixels is a lobe that spins. It keeps the one it had.
      if (d > 0.5) to = Math.atan2(dy, dx);
    }
    var k = dt > 0 ? 1 - Math.pow(1 - CHASE, dt * 60) : 0;
    near += (want - near) * k;
    if (near < 0.001) near = 0;
    // The short way round. A cursor crossing behind the object would otherwise
    // send the lean the long way, and the lobe would sweep the entire ring to
    // get somewhere it could have reached over the top.
    var da = to - bear;
    while (da >  3.14159) da -= 6.28318;
    while (da < -3.14159) da += 6.28318;
    bear += da * k;
    charge(near);
  }

  // A move, and only a real one. A finger dragged across a page is a scroll and
  // not a hand hovering over anything, and whatever it happens to pass over
  // should not start humming at it — the same line the tick on the furniture
  // already draws.
  function feel(e) {
    if (e.pointerType === "touch") return;
    hover = true;
    tipx = e.clientX;
    tipy = e.clientY;
    // No frame loop to feel it in, so it is felt here instead, and without the
    // lag: a lag is motion. Nothing is drifting for this reader either, which
    // is the only thing a reading taken between moves could have missed.
    if (still && cv) sense(9);
  }

  function flee(e) {
    // pointerout fires for every element a cursor crosses on its way over a
    // page. The one that means the hand has gone is the one with nothing on the
    // other side of it.
    if (e && e.type === "pointerout" && e.relatedTarget) return;
    hover = false;
    // Down at once rather than on the next frame. A window losing focus is
    // usually a reader who has gone somewhere else, and there is no next frame
    // in a hidden tab to notice with; where the frames do keep coming, the
    // reading eases out over the next third of a second and this write is
    // overtaken before anybody hears it.
    charge(0);
    if (still && cv) sense(9);
  }

  // Built the first time a hand comes near enough to be worth building for, and
  // then kept for as long as the room is. Nothing in here is created on a move:
  // it is four oscillators and a loop of noise that start once and never stop,
  // and what a cursor changes is six numbers.
  function spark() {
    var t = ctx.currentTime;
    var lvl = ctx.createGain();
    lvl.gain.value = 0;

    // The teeth. A square rather than a sine, and at a rate that belongs to a
    // wire rather than to the key: this is the one sound in the book allowed to
    // be electrical instead of instrumental, and being chopped is most of what
    // makes a tone read that way. The depth starts shut, so the far half of the
    // field is a smooth low drone and only the near half has anything in it.
    var teeth = ctx.createGain();
    teeth.gain.value = 0.7;
    var chop = ctx.createOscillator();
    chop.type = "square";
    chop.frequency.value = 41;
    var bit = ctx.createGain();
    bit.gain.value = 0;
    chop.connect(bit);
    bit.connect(teeth.gain);
    chop.start(t);

    // The drone under it. Two sawtooths about three cents apart, which is one
    // slow beat every couple of seconds and is heard as the thing being alive
    // rather than as two notes. The filter above them does the work; the notes
    // themselves never move except when the chord does.
    var lp = ctx.createBiquadFilter();
    lp.type = "lowpass";
    lp.frequency.value = 220;
    lp.Q.value = 0.8;
    var a = ctx.createOscillator();
    var b = ctx.createOscillator();
    a.type = "sawtooth";
    b.type = "sawtooth";
    a.frequency.value = 110;
    b.frequency.value = 110.2;
    a.connect(lp);
    b.connect(lp);
    a.start(t);
    b.start(t);
    lp.connect(teeth);

    // The crackle: a narrow band of noise wandering up and down on a clock of
    // its own, because a band sitting still is a kettle and a band that moves
    // is a discharge.
    var arc = ctx.createGain();
    arc.gain.value = 0;
    var bp = ctx.createBiquadFilter();
    bp.type = "bandpass";
    bp.frequency.value = 2600;
    bp.Q.value = 7;
    var roam = ctx.createOscillator();
    roam.type = "triangle";
    roam.frequency.value = 1.7;
    var ra = ctx.createGain();
    ra.gain.value = 1300;
    roam.connect(ra);
    ra.connect(bp.frequency);
    roam.start(t);
    var n = ctx.createBufferSource();
    n.buffer = noise;
    n.loop = true;
    n.connect(bp);
    bp.connect(arc);
    arc.connect(teeth);
    n.start(t);

    teeth.connect(lvl);
    lvl.connect(dry);
    // A little room on it and no more. A thing you can feel from three inches
    // away is not at the other end of a hall, and the reverb in here is what
    // makes everything else sound like it is.
    var wet = ctx.createGain();
    wet.gain.value = 0.22;
    lvl.connect(wet);
    wet.connect(send);

    fizz = { lvl: lvl.gain, lp: lp.frequency, q: lp.Q, bit: bit.gain,
             chop: chop.frequency, arc: arc.gain, a: a.frequency, b: b.frequency,
             root: -1, at: -9, was: -1 };
  }

  // Six numbers off one reading, glided in the audio thread rather than
  // stepped, because a gain written once a frame is a gain that zippers.
  //
  // Three gates in front of them, in the order that costs least. An object
  // nobody is anywhere near does not reach this line at all; a reader with the
  // cursor resting on the panel pays for the chord it is tuned to and nothing
  // else; and a hand actually moving is bounded at thirty writes a second,
  // which is under a frame's worth and above anything an ear could pick out.
  function charge(p) {
    if (!ctx || ctx.state !== "running" || !noise || !dry) return;
    if (!fizz) {
      if (p < 0.02) return;
      spark();
    }
    if (p === 0 && fizz.was === 0) return;
    var t = ctx.currentTime;
    if (t - fizz.at < 0.03) return;
    fizz.at = t;
    // Asked every time rather than when the hand moves, because the chord
    // changes on its own clock and a drone left on the last one is the only
    // wrong note this could put in the room. In the key, like everything else a
    // reader can cause in here, and in the hole the growl found: over the bass,
    // under the chord, where nothing else in the arrangement is standing.
    var c = chord(Math.floor((((step % CYCLE) + CYCLE) % CYCLE) / 16));
    if (c.root !== fizz.root) {
      fizz.root = c.root;
      var f = mtof(low(c.root) + 12);
      fizz.a.setTargetAtTime(f, t, 0.25);
      fizz.b.setTargetAtTime(f * 1.0018, t, 0.25);
    }
    // And a hand holding still moves none of the rest. The threshold is well
    // under what a glide of sixty milliseconds would smooth out anyway, so what
    // it saves is writes and not detail.
    if (Math.abs(p - fizz.was) < 0.004) return;
    fizz.was = p;
    var p2 = p * p;
    fizz.lvl.setTargetAtTime(p2 * FIZZ, t, 0.06);
    fizz.lp.setTargetAtTime(220 + p2 * 3600, t, 0.06);
    fizz.q.setTargetAtTime(0.8 + p * 4, t, 0.06);
    fizz.bit.setTargetAtTime(p2 * 0.62, t, 0.06);
    fizz.chop.setTargetAtTime(41 + p * 26, t, 0.08);
    // The crackle arrives last of all, on the cube, so it is a thing that
    // happens in the final inch and not a hiss laid over the whole approach.
    fizz.arc.setTargetAtTime(p2 * p * 0.22, t, 0.06);
  }

  // ---- the voice ----------------------------------------------------------
  // The thing in the panel has been a meter, then an object, then a rock with
  // weather round it, and at every step it got harder to look at without
  // wondering what it makes of all this. So it thinks, visibly, every twenty
  // seconds or so, and holds the thought for about as long as one takes to
  // read.
  //
  // Who is thinking matters more than the mechanism does. It is something old
  // enough to have watched this cabinet get built in several universes and to
  // have been unimpressed in each of them, and that register is the only one in
  // which a book can be rude about the people writing it and stay funny: the
  // observation is about pilots in general, or about the twenty-third century,
  // and the pilot reading it is welcome to conclude it is about them. It keeps
  // the house voice while it does it — flat, dry, no exclamation marks —
  // because an ancient being that shouts is a mascot.
  //
  // It is drawn in comic grammar because the panel it hangs in is a comic cel:
  // plate, halftone, hard border, ink dropped behind it. And it is a thought
  // rather than a speech, which is a decision about manners rather than about
  // shape. A spike pointing at the rock would mean the rock is addressing you;
  // two puffs trailing back to it mean the rock is thinking and you are near
  // enough to catch it. Nothing in this panel asked for a reader. The being is
  // not performing, it has simply been here a long time and has opinions, and
  // overhearing those is funnier than being told them.
  //
  // White paper and no outline, which is the one thing in this book that is
  // neither lit nor bordered. Everything on the page glows because everything
  // on the page is on a screen inside a screen, and a thought is not part of
  // that machinery. An outline is what a shape needs to hold its own against a
  // background, and white against a neon plate does not need one.
  //
  // Arriving, it grows out of the thinker: the origin it scales about is the
  // rock rather than its own middle, its width opens from a third to all of it,
  // and the sentence writes itself in a character at a time behind that. Three
  // things on one curve, and what they add up to is a thought forming rather
  // than a panel being shown. Leaving is the same backwards, into whatever
  // corner the rock has drifted to by then.
  //
  // Two of the facts it uses are read off the page rather than kept here: who
  // flew this chapter and which number it is, both already printed in the
  // credits under the sentence. Same argument the signet makes — the fact is on
  // the page, so read it instead of holding a copy that can go stale. A page
  // with no credits, the cover and the notes, simply never has a thought that
  // wanted one.
  //
  // It runs on a timer of its own rather than on the frame, it allocates one
  // element for as long as the room is on and a line's worth of spans when a
  // line arrives, and it exists only while the room does. A reader who asked
  // for less motion gets the orb holding still and thinking nothing, which is
  // the answer that reader already gets from everything else in here.

  var SKIN = "#f2f6ff";                    // paper, cooled a shade to sit on a
                                           // page lit by a cathode ray tube
  var INK = "#0b0418";                     // and what is written on it
  var ROUND = 18;                          // the corner the paper is cut with
  var CURL = 0.45;                         // and the corner the puffs are, as a
                                           // share of their own height. Not the
                                           // balloon's corner scaled: a corner
                                           // scaled down with everything else
                                           // stops reading as a corner, so the
                                           // small ones are rounded almost to
                                           // the ends to keep the shape they
                                           // are a copy of
  // The trail back to the thinker, as fractions of the balloon rather than as
  // sizes. They are the same shape it is — same proportions, same corner, the
  // corner scaled with everything else — because a thought coming apart into
  // circles is a thought coming apart into something else, and two smaller
  // copies of the thing itself say what is happening without being explained.
  var PUFF = [0.32, 0.18];
  var LAP = 2;                             // and each laps over the one behind
                                           // it by that much, so they read as
                                           // one thought in pieces rather than
                                           // as three shapes. Enough to touch
                                           // and no more: a puff mostly buried
                                           // in the one behind it is not a
                                           // trail, it is a blot
  var RUN = [];                            // where each of their middles lands
  var STALK = 0.35;                        // where it leaves the balloon: left
                                           // of its middle, which is where a
                                           // comic has always hung one
  var STROKE = 13;                         // milliseconds a character waits for
                                           // the character in front of it
  var OPEN = 0.3;                          // the width it opens from

  // Fifty-odd observations from something with no stake in any of this. {who}
  // is the pilot who flew the chapter and {ch} is its number; a line that asks
  // for either is only offered on a page that can answer.
  var LINES = [
    "I have watched this cabinet get built in four hundred universes. In one of them the rocks shoot back, and it is not an improvement.",
    "I am older than the idea of a corner. This shape is a courtesy.",
    "I have outlived nine suns and one build system. The suns lasted longer.",
    "Every civilisation I have visited eventually invents a game about hitting rocks. Each of them is certain it invented it.",
    "In the next universe over this song is in a major key, and the pilots there are insufferable.",
    "There is a timeline where nobody added the kraken. It is a calmer book and a worse one.",
    "I attended the heat death of a galaxy. Fewer particles than you would hope for.",
    "Entropy takes everything in the end. The third rock usually gets there first, and from behind.",
    "In universe 6,441 this is a spreadsheet. The competition is precisely as bitter.",
    "Somewhere the phosphor never fades. Nothing there is ever quite over, and it is exhausting.",
    "I have stood at the edge of three universes. Two of them had a border two pixels wide, like this one.",
    "A species gets fire, then writing, then the concept of a cooldown. The order took me by surprise.",
    "Time is a flat circle in most places. Here it has a slight wobble, somewhere around v17.",
    "I have seen how this book ends. It is not at the last chapter, which I thought was well judged.",
    "The rocks do not know they are the antagonists. Very few things do.",
    "Somebody spent an entire evening choosing this magenta. They were right to, and nobody will ever thank them.",
    "This rock has twelve corners. I have counted them roughly nine million times and the number holds.",
    "Nothing here picks an absolute colour. Everything picks an offset from a hue that will not sit still. I find it restful.",
    "A vector line has no thickness. Somebody gave this one a glow regardless, which is the whole project in a single decision.",
    "The trails are not a trick of the eye. The layer is faded rather than cleared, which is one way of saying the past is still slightly here.",
    "Two seats, one keyboard. I have seen empires founded on less and lost over rather more.",
    "There is an atom bomb in the cabinet and you are given two. Restraint is the entire genre.",
    "Twelve rules, six of which cannot be bent. Six is more than most civilisations manage.",
    "The referee is a shell script. Do not let that reassure you.",
    "Somebody will read this commit in four hundred years and still not know why the number is 0.72.",
    "A budget spent in writing is still spent. The ledger noticed. The field will bring it up later.",
    "I have read every commit message in this repository. Three of them were load-bearing jokes.",
    "The tally forgives after three clean landings. I forgive nothing, but then nothing enforces me.",
    "One surprise per commit is a rule written by somebody who had just shipped six.",
    "The best event in this cabinet was laid by the one pilot it can never fire at. Petty, elegant, working as intended.",
    "This book is generated by a shell script. Do not tell it. It believes it is literature.",
    "Every feature here is one file and one line in a list. I have watched empires come apart for want of that arrangement.",
    "Somebody is about to retune a number in somebody else's file. Balance is everybody's business, apparently.",
    "The history cannot be rewritten here. I have visited places where it can, and I do not recommend the food.",
    "A commit that changes the game gets a number. A commit that files the paperwork gets silence. I approve of the silence.",
    "There is no build step. In eleven universes out of twelve that is the difference between a game and a folder of regret.",
    "Pilots come in two kinds: the ones who add a feature, and the ones who quietly retune everybody else's at two in the morning.",
    "Every project has one person who names things beautifully and one who names them tmp2. Here they are the same person.",
    "There is always one pilot who reads the rules before building. It is never the one who needed to.",
    "Somebody will refactor this. It will be whoever wrote it, and they will be annoyed at themselves in the third person.",
    "I have met {who} in eleven timelines. In all eleven, {who} said one small change, after midnight.",
    "{who} flew this chapter. In three universes out of four, {who} even played it first.",
    "The pilot who writes the most careful comments is the pilot who broke it last time. This holds in every universe I have checked.",
    "Somebody is going to blame the physics. It is never the physics.",
    "In another timeline {who} shipped this a week earlier and it was worse. Slowness is underrated.",
    "The most dangerous sentence in any universe is: while I am in here anyway.",
    "I am technically a readout. The opinions are a side effect.",
    "Somebody switched the sound on. Very few readers do. I notice every one of them.",
    "I exist only while the room is on. A limited engagement, but the lighting is exceptional.",
    "Nobody needs to mind me. I am largely here for the acoustics.",
    "Chapter {ch}. I already know how it goes and I am not going to spoil it.",
    "{ch} versions. The pyramids took longer and do considerably less.",
    "I answer to the music rather than to a clock, which is more than can be said for most oracles.",
    "I have nothing to sell anybody, which should distinguish me from most things that appear in a bubble."
  ];

  // A thought landing is felt by the thing having it: the rock swells, springs
  // back past where it started, and settles. That is a second-order system
  // rather than a curve, and it is written as one on purpose — a curve has to
  // be told how long to take, and a spring only has to be told how hard it was
  // hit. draw() adds what this returns to the radius, which is why the whole
  // object goes with it: the rings, the corona, the weather, all of it, because
  // they are all measured off that one number.
  var JOLT = 4.2;                          // the shove, in radii per second
  var STIFF = 340, DAMP = 13;              // stiff and lightly damped, so it
                                           // overshoots once and is done in
                                           // under a second
  var jolt = 0, jolted = 0;                // how far out it is, and how fast

  function kick(dt) {
    if (!jolt && !jolted) return 0;
    // Velocity first and then position off the new velocity, which is the one
    // ordering of these two lines that does not blow up at a long frame.
    jolted += (-STIFF * jolt - DAMP * jolted) * dt;
    jolt += jolted * dt;
    if (Math.abs(jolt) < 0.0004 && Math.abs(jolted) < 0.004) jolt = jolted = 0;
    return jolt;
  }

  // And it is heard as well as seen. The swell and the noise are one event —
  // the thing has a thought, and the thought displaces something.
  //
  // What it displaces is water, which is a decision about what the rock is. A
  // chime would make it an instrument and a voice would make it a character;
  // three bubbles make it a large old thing that has been sitting in something
  // for a while, which is the register the sentences are already in. It is the
  // only sound in this file with no metre on it at all: it arrives whenever the
  // thought does, off a timer that has never heard of the tempo.
  //
  // Tuned all the same, to the chord the scheduler is standing in. A bubble
  // that is in the key reads as part of the room; the same bubble a semitone
  // out reads as a notification, and the reader goes looking for what they
  // clicked on.
  function blub(t, f, amp) {
    var g = ctx.createGain();
    var lp = ctx.createBiquadFilter();
    lp.type = "lowpass";
    lp.frequency.setValueAtTime(f * 4, t);
    lp.frequency.exponentialRampToValueAtTime(f * 1.5, t + 0.2);
    var o = ctx.createOscillator();
    // The rise is the whole bubble. Held flat it is a beep, and falling it is a
    // drip, and neither of those is charming about anything.
    o.frequency.setValueAtTime(f * 0.45, t);
    o.frequency.exponentialRampToValueAtTime(f, t + 0.08);
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(amp, t + 0.014);
    g.gain.exponentialRampToValueAtTime(0.0001, t + 0.24);
    o.connect(lp);
    lp.connect(g);
    g.connect(dry);
    g.connect(send);
    o.start(t);
    o.stop(t + 0.28);
  }

  // Three of them, climbing and getting smaller, which is what a bubble does on
  // the way up. Low: the octave over the chord's root rather than the register
  // the box plays in, because this is underneath the music and not on top of
  // it. If the room is not running there is nothing to be underneath and it
  // says nothing — the panel is silent then anyway.
  function burble() {
    if (!ctx || !dry || !playing) return;
    var c = chord(Math.floor((((step % CYCLE) + CYCLE) % CYCLE) / 16));
    var t = ctx.currentTime + 0.02;
    var deg = [0, 7, 12], amp = [0.085, 0.07, 0.05], at = [0, 0.1, 0.175];
    for (var i = 0; i < 3; i++)
      blub(t + at[i], mtof(c.root + 12 + deg[i]), amp[i]);
  }

  // bub is the frame the whole thought is hung in and the thing that scales;
  // pane is the paper inside it, which is the part whose width opens; sen is
  // the sentence, pinned to the width it was laid out at so that opening the
  // paper uncovers the words rather than re-wrapping them sixty times.
  var bub = null, pane = null, sen = null, puff = [], bag = [], pend = 0, brim = 0;

  function facts() {
    var f = { ch: CH > 0 ? String(CH) : "", who: "" };
    var el = document.querySelector(".credits .who");
    if (el) f.who = (el.textContent || "").trim().split(/\s+/)[0] || "";
    return f;
  }

  // A line whose blanks cannot be filled on this page is not a line on this
  // page. Nothing is patched with a placeholder — an oracle that says "chapter
  // undefined" is a bug wearing a costume.
  function dress(s, f) {
    if (s.indexOf("{who}") >= 0 && !f.who) return "";
    if (s.indexOf("{ch}") >= 0 && !f.ch) return "";
    return s.split("{who}").join(f.who).split("{ch}").join(f.ch);
  }

  // A bag rather than a die: everything gets thought once before anything gets
  // thought twice, so a reader who stays for a whole chapter never sees the
  // same observation come round again. Math.random and not the chapter's own
  // seed, which is the one place in this file that wants a different answer
  // every time — the music is meant to be the same v3 whenever you open it, and
  // the being is meant not to be.
  function refill() {
    var f = facts(), i, j, t;
    bag = [];
    for (i = 0; i < LINES.length; i++) {
      t = dress(LINES[i], f);
      if (t) bag.push(t);
    }
    for (i = bag.length - 1; i > 0; i--) {
      j = Math.floor(Math.random() * (i + 1));
      t = bag[i]; bag[i] = bag[j]; bag[j] = t;
    }
  }

  // Wherever the rock has got to, in whatever coordinates the balloon is hung
  // in — the panel's for a chapter, the window's for the fixed corner the cover
  // and the notes put it in.
  function whence() {
    var b;
    if (!adrift) return { x: cx || hx, y: cy || hy };
    b = cv.getBoundingClientRect();
    return { x: (b.left + b.right) / 2, y: (b.top + b.bottom) / 2 };
  }

  // The thought grows out of the thinker and collapses back into it, so the
  // origin it scales about is the rock. Kept apart from spot() because leaving
  // needs the origin brought up to date and must not move the balloon while it
  // is still being read.
  function aim() {
    if (!bub || !cv) return;
    var o = whence();
    bub.style.transformOrigin =
      Math.round(o.x - parseFloat(bub.style.left)) + "px " +
      Math.round(o.y - parseFloat(bub.style.top)) + "px";
  }

  // Measured at the width it wants and then pinned there. Everything after this
  // — the opening, the placing, the trail — works off one number that does not
  // move while it is being animated.
  function size(open) {
    if (!bub || !cv) return;
    var max = adrift ? Math.min(272, document.documentElement.clientWidth - 20)
                     : Math.min(300, cv.clientWidth * 0.6);
    // Measured back at the origin, because a box that shrinks to fit its
    // contents also shrinks to fit the room left in front of it, and this one
    // is usually still parked against the right-hand edge from last time. On
    // the cover, where it lives in the corner, that came out as a column one
    // word wide. spot() puts it back where it belongs a moment later.
    bub.style.left = "0px";
    bub.style.top = "0px";
    bub.style.width = "";
    pane.style.width = "";
    pane.style.maxWidth = Math.round(max) + "px";
    sen.style.width = "";
    brim = pane.offsetWidth;
    sen.style.width = sen.offsetWidth + "px";
    bub.style.width = brim + "px";
    pane.style.width = Math.round(brim * (open ? 1 : OPEN)) + "px";
  }

  // How far above or below the balloon each puff's middle falls, and how far
  // the whole trail reaches. Both depend on how tall the balloon turned out to
  // be this time, because the puffs are that balloon scaled down and it is a
  // different size for every sentence. Heights the whole way: the trail leaves
  // the top edge or the bottom one, and the sideways part of it is a lean that
  // spot() adds rather than a distance anything is spaced by.
  function trail(bh) {
    var i, last = 0, run = 0;
    for (i = 0; i < PUFF.length; i++) {
      run += (last + PUFF[i]) * bh / 2 - LAP;
      RUN[i] = run;
      last = PUFF[i];
    }
    return run + last * bh / 2 + 6;        // the far edge, and a little air
  }

  // Over the rock if there is room over the rock, under it otherwise, and never
  // across an edge of a panel that clips whatever leaves it.
  function spot() {
    if (!bub || !cv) return;
    var L, T, up, w, h, b, el, lid, o = whence();
    var bw = bub.offsetWidth, bh = bub.offsetHeight, reach = trail(bh);
    if (adrift) {
      b = cv.getBoundingClientRect();
      w = document.documentElement.clientWidth;
      T = b.bottom - 2;
      L = Math.max(10, Math.min(b.right - bw, w - bw - 10));
    } else {
      b = cv.getBoundingClientRect();
      w = cv.clientWidth; h = cv.clientHeight;
      // Two things in this panel are drawn over it: the link to the full plate
      // in the top corner and the chapter's own sentence along the foot. Where
      // a circle of radius R fits is place()'s question; this is the smaller
      // one of what a paragraph must not sit on, and its answer differs above
      // the rock and below it.
      el = host.querySelector(".plate-full");
      lid = el ? el.getBoundingClientRect().bottom - b.top + 8 : 6;
      up = o.y - R - bh - reach >= lid;
      T = up ? o.y - R - bh - reach : o.y + R + reach;
      T = Math.max(lid, Math.min(T, h - bh - 6));
      // The trail leaves from a third or so in from the left, so the balloon is
      // offset by that much rather than centred: it is the puffs that should
      // line up under the rock, not the middle of the paper.
      L = o.x - bw * STALK;
      el = up ? null : host.querySelector(".say");
      if (el) L = Math.max(L, el.getBoundingClientRect().right - b.left + 12);
      L = Math.max(6, Math.min(L, w - bw - 6));
    }
    bub.style.left = Math.round(L) + "px";
    bub.style.top = Math.round(T) + "px";
    aim();

    // The trail leaves from that same point, on whichever edge faces
    // the rock, and walks towards it — so the two of them lead back to the
    // thinker from whatever side the balloon ended up on, and go on leading
    // back to it as the rock drifts.
    //
    // Walked in the vertical, and leaning sideways by however far off the rock
    // has got to. What holds three wide flat shapes apart on a page is the room
    // between their tops and their bottoms, and a run paid out along a trail
    // heading off at forty degrees spends most of itself sideways, where the
    // puffs overlap anyway and nothing is separated by it. The lean is held
    // short of the horizontal for the moment the rock is level with the paper,
    // when the arithmetic would otherwise post the puffs off the far edge of
    // the panel.
    var ax = bw * STALK, ay = o.y < T + bh / 2 ? 0 : bh;
    var dx = o.x - (L + ax), dy = o.y - (T + ay);
    var down = dy < 0 ? -1 : 1;
    var lean = Math.max(-1.4, Math.min(1.4, dx / (Math.abs(dy) || 1)));
    for (var i = 0; i < puff.length; i++) {
      var k = PUFF[i], pw = bw * k, ph = bh * k, q = puff[i].style;
      // Held inside the balloon's own width. A puff is a third of the paper
      // wide, and centring the widest of them on a stalk a tenth in would hang
      // it off the left-hand edge, which reads as a mistake rather than as a
      // trail.
      var mx = Math.min(Math.max(ax + lean * RUN[i], pw / 2), bw - pw / 2);
      q.width = Math.round(pw) + "px";
      q.height = Math.round(ph) + "px";
      q.borderRadius = Math.max(3, Math.round(ph * CURL)) + "px";
      q.left = Math.round(mx - pw / 2) + "px";
      q.top = Math.round(ay + down * RUN[i] - ph / 2) + "px";
    }
  }

  // A thought does not arrive finished. Each character waits on the one in
  // front of it and then fades, which at thirteen milliseconds apart reads as
  // the sentence being written rather than as a sentence animating. Spaces stay
  // ordinary text so the browser can still break a line wherever it likes.
  function write(line) {
    var i, ch, el, n = 0;
    while (sen.firstChild) sen.removeChild(sen.firstChild);
    for (i = 0; i < line.length; i++) {
      ch = line.charAt(i);
      if (ch === " ") { sen.appendChild(document.createTextNode(" ")); continue; }
      el = document.createElement("span");
      el.textContent = ch;
      el.style.opacity = "0";
      // The paper is given a moment to start opening before the first letter
      // lands on it, because a thought written before it is thought is a
      // subtitle.
      el.style.transition = "opacity 0.22s linear " + (140 + n * STROKE) + "ms";
      sen.appendChild(el);
      n++;
    }
  }

  function speak() {
    pend = 0;
    if (!bub) return;
    if (!bag.length) refill();
    var line = bag.pop();
    if (!line) return;                    // a page that can answer nothing
    write(line);
    size(0);
    spot();                               // and this is what settles the layout
    bub.style.opacity = "1";
    bub.style.transform = "none";
    pane.style.width = brim + "px";
    jolted = JOLT;                        // and the rock notices it thought
    burble();                             // out loud, as it turns out
    for (var i = 0; i < sen.children.length; i++) sen.children[i].style.opacity = "1";
    // As long as it takes to read it, and a beat either side of that. Nobody
    // should have to hurry for a joke they did not ask for.
    pend = setTimeout(lull, Math.min(15000, 3600 + line.length * 52));
  }

  function lull() {
    pend = 0;
    if (!bub) return;
    aim();                                // back into wherever the rock is now
    bub.style.opacity = "0";
    bub.style.transform = "scale(0.06)";
    pane.style.width = Math.round(brim * OPEN) + "px";
    pend = setTimeout(speak, 9000 + Math.random() * 13000);
  }

  // The panel it hangs in can change shape under it. Re-measure, re-place, and
  // do not close a thought somebody is halfway through reading.
  function again() {
    if (!bub) return;
    size(bub.style.opacity === "1");
    spot();
  }

  function mouth() {
    if (bub || still || !cv) return;
    var home = adrift ? document.body : host;
    // A panel too narrow to hold a sentence beside a rock gets the rock. On a
    // phone the chapter's own sentence has already taken the panel, which is
    // the right call and this does not argue with it.
    if (!home || (!adrift && cv.clientWidth < 340)) return;

    bub = document.createElement("div");
    // Decoration, and decoration that arrives unannounced every twenty seconds.
    // Read out, it would interrupt the chapter a reader actually came for.
    bub.setAttribute("aria-hidden", "true");
    var s = bub.style;
    s.position = adrift ? "fixed" : "absolute";
    s.left = "0px";
    s.top = "0px";
    s.zIndex = adrift ? "5" : "3";
    s.pointerEvents = "none";             // it is a thought, not furniture
    s.opacity = "0";
    s.transform = "scale(0.06)";
    // Out of the rock and back into it. The curve is the one a cel arrives on
    // in chronicle.css, because a thought opening in a panel of cels should
    // move the way the panel did.
    s.transition = "opacity 0.4s ease, transform 0.46s cubic-bezier(0.2, 0.85, 0.3, 1)";

    pane = document.createElement("div");
    var p = pane.style;
    p.overflow = "hidden";                // so opening it uncovers the sentence
    p.padding = "0.62rem 0.85rem";
    p.borderRadius = ROUND + "px";        // and the puffs take the same corner
    p.background = SKIN;
    p.color = INK;
    p.fontSize = "0.7rem";
    p.lineHeight = "1.55";
    p.letterSpacing = "0.01em";
    // No outline and no shadow. What holds the shape against the plate is the
    // same thing that holds every other shape in this book against it: it is
    // lit. A white bloom, close in and then broad, so the paper looks like the
    // brightest thing in the panel rather than like a cutout laid on top of it.
    p.boxShadow = "0 0 14px rgba(255, 255, 255, 0.6), 0 0 42px rgba(255, 255, 255, 0.28)";
    p.transition = "width 0.44s cubic-bezier(0.2, 0.85, 0.3, 1)";
    bub.appendChild(pane);

    sen = document.createElement("span");
    sen.style.display = "block";
    sen.style.textWrap = "pretty";
    pane.appendChild(sen);

    for (var i = 0; i < PUFF.length; i++) {
      var el = document.createElement("i"), q = el.style;
      q.position = "absolute";
      q.background = SKIN;
      q.boxShadow = "0 0 10px rgba(255, 255, 255, 0.6), 0 0 24px rgba(255, 255, 255, 0.28)";
      puff.push(el);
      bub.appendChild(el);
    }

    home.appendChild(bub);
    addEventListener("resize", again);
    // Long enough that the rock has finished arriving and been looked at. A
    // thing that starts thinking the moment it appears is a pop-up.
    pend = setTimeout(speak, 4000 + Math.random() * 5000);
  }

  function hush() {
    if (pend) { clearTimeout(pend); pend = 0; }
    if (!bub) return;
    removeEventListener("resize", again);
    if (bub.parentNode) bub.parentNode.removeChild(bub);
    bub = null; pane = null; sen = null; puff = []; bag = [];
  }

  // ---- the switch ---------------------------------------------------------
  // Built by the script rather than printed into the page, because a button
  // that promises sound to a reader with the script switched off is a lie. S
  // does the same thing, since this cabinet is played on a keyboard.

  var btn = document.createElement("button");
  btn.type = "button";
  btn.className = "song";
  btn.innerHTML = '<span class="eq" aria-hidden="true"><i></i><i></i><i></i><i></i></span>' +
                  '<span class="lab">sound</span>';

  // Three states rather than two, because for the first few seconds of most
  // pages the true answer is neither. The room is on and the browser has not
  // let it in yet; bars dancing over silence is the switch telling a small lie
  // about a room that has not arrived.
  function mark() {
    btn.classList.toggle("on", playing);
    btn.classList.toggle("waiting", playing && !awake());
    btn.setAttribute("aria-pressed", playing ? "true" : "false");
    btn.title = !playing ? "the room this is read in (s)"
      : awake() ? "quiet, then (s)"
      : "waiting for a click or a key (s)";
  }

  btn.addEventListener("click", function () { playing ? off() : on(); });
  addEventListener("keydown", function (e) {
    if (e.key !== "s" && e.key !== "S") return;
    if (e.metaKey || e.ctrlKey || e.altKey) return;
    playing ? off() : on();
  });

  // Back through the history to a page the browser kept whole: the graph came
  // back suspended, and the reader already said yes to all of this.
  addEventListener("pageshow", function (e) {
    if (e.persisted && playing) armed();
  });

  // The last word on where the piece was, written on the way out of the page
  // rather than a second and a half before it. pagehide and not unload: it is
  // the one the browser still fires when the page goes into the back-forward
  // cache, which is most of the turning of these pages.
  addEventListener("pagehide", keep);

  // ---- the furniture ------------------------------------------------------
  // The room answers a hand as well as a clock.
  //
  // Same argument the cabinet makes on its splash screen (src/ui/clicks.js): a
  // page you can point at things on should say something when you do, and a
  // book of ten chapters with a rail of plates along the foot of every one of
  // them is a page you point at a lot. Two differences, both of them because
  // this is a book rather than an arcade machine.
  //
  // It is quieter than anything else in here by a wide margin, and it is
  // tuned to whatever chord is currently hanging in the air rather than to a
  // key of its own — the note under your cursor is a degree of the chord the
  // pad is already holding, so pointing at things cannot put a wrong note in
  // the room however fast you do it.
  //
  // And it follows the one switch there is. Somebody who turned the room off
  // did not turn it off in order to be clicked at instead.

  // A degree of the chord in the air at this moment.
  function furniture(deg, lift) {
    var c = chord(Math.floor(((((step % CYCLE) + CYCLE) % CYCLE)) / 16));
    var v = c.voice;
    return mtof(c.root + lift + v[((deg % v.length) + v.length) % v.length]);
  }

  // Under the cursor: a fingertip on the rim of a glass, most of it arriving
  // as room rather than as note.
  function tap(f) {
    var t = ctx.currentTime;
    var g = ctx.createGain();
    var o = ctx.createOscillator();
    o.type = "sine";
    o.frequency.value = f;
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(0.03, t + 0.006);
    g.gain.exponentialRampToValueAtTime(0.0001, t + 0.26);
    o.connect(g);
    g.connect(dry);
    g.connect(send);
    o.start(t);
    o.stop(t + 0.28);
  }

  // Everything a reader can arrive at, by shape rather than by name, so a page
  // that grows a control next year gets this without being told.
  var LIVE = "a[href], button";
  var lastEl = null, lastAt = 0;

  function awake() { return playing && ctx && ctx.state === "running"; }

  // Where a thing sits, as a degree: its place among its own kind. The rail of
  // plates at the foot of a chapter is the whole history in a row, so running
  // a cursor along it arpeggiates the chord — which is the one bit of this
  // anybody is ever going to do on purpose.
  function degreeOf(el) {
    var kin = el.parentElement ? el.parentElement.children : [];
    for (var i = 0; i < kin.length; i++) if (kin[i] === el) return i;
    return 0;
  }

  function reach(e) {
    var el = e.target && e.target.closest ? e.target.closest(LIVE) : null;
    return el && !el.classList.contains("song") ? el : null;
  }

  addEventListener("pointerover", function (e) {
    if (e.pointerType === "touch" || !awake()) return;
    var el = reach(e);
    if (!el || el === lastEl) return;
    var now = ctx.currentTime;
    if (now - lastAt < 0.045) return;      // a fast sweep is a run, not a buzz
    lastEl = el;
    lastAt = now;
    tap(furniture(degreeOf(el), 24));
  }, true);

  // The same tick for a keyboard. This book is turned with the arrow keys and
  // read by people who tab through it.
  addEventListener("focusin", function (e) {
    if (!awake()) return;
    var el = reach(e);
    if (!el) return;
    lastEl = el;
    tap(furniture(degreeOf(el), 24));
  }, true);

  addEventListener("pointerdown", function (e) {
    if (!awake()) return;
    var el = reach(e);
    if (!el) return;
    lastEl = null;                          // coming back over it should answer again
    pluck(ctx.currentTime, furniture(degreeOf(el), 12), 0.05);
    // Turning a page moves air. It is the same sweep the piece uses to get
    // itself round the turn of the progression, which is the joke.
    if (el.classList.contains("turn")) sweep(ctx.currentTime, 0.45);
  }, true);

  mark();
  document.body.appendChild(btn);
  // On unless somebody said otherwise, and a reader who said yes on the last
  // page has said yes. Whether that can be honoured on arrival is the
  // browser's call rather than ours, so the room asks it. Making a context is
  // free and silent and it answers on the spot: one handed back already
  // running is a browser that trusts this book — one it has been read in
  // before, one told to allow it, a file opened off a disk — and then the
  // piece starts on its own, which is what a lit switch is supposed to mean.
  //
  // Where it comes back parked there is nothing to be done but wait, and
  // asking anyway only earns a console full of the browser saying so. So the
  // switch stays lit and gets honest about it: the bars hold still, the
  // tooltip says what it is waiting for, and the next thing the reader does —
  // a click, the arrow key that turns the page — starts the room. Nothing is
  // asked of them twice, and the context they are waiting on is the one they
  // get.
  if (remembered() !== "off") {
    playing = true;
    spare = new Ctx();
    if (spare.state === "running") on(); else wait();
    mark();
  }
})();
JS

# --- the sidecar ------------------------------------------------------------
#
# The book is a book, and the splash screen is a doorway to it. A doorway with
# a picture in it is worth walking through, so this writes what the cabinet
# needs to draw one: the last few painted plates, the newest chapter, and the
# top of the board.
#
# It is a script rather than data because there is no fetch in this project and
# there is not going to be (GR2), which is the same reason docs/faces/faces.js
# is a script. Same contract as that file, too: the game asks for it, does
# without it if it is not there, and never lists it in the manifest. A clone
# that has never run this tool gets the splash it always had.
#
# Everything in it is already committed somewhere else - the history, the
# taglines, the plates, the board. Nothing is invented here and nothing is
# authoritative here; it is the same facts, in the one shape a page can read.

# The board out of docs/RANKINGS.md, folded into the same stream as everything
# else. Row order is the file's, which is score order, which is the whole point
# of that table. The columns are read by position because the header names them
# and the header is the first row we skip.
board() {
  [ -f docs/RANKINGS.md ] || return 0
  awk -F'|' '
    function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
    /^##[ \t]/ { inboard = (index($0, "THE BOARD") > 0); next }
    !inboard || $0 !~ /^\|/ { next }
    { rows++ }
    rows <= 2 { next }                                  # the header, then its rule
    {
      printf "\036RANK\037%s\037%s\037%s\037%s\037%s\037%s\037%s",
             trim($2), trim($3), trim($4), trim($5), trim($6), trim($7), trim($8)
    }
  ' docs/RANKINGS.md
}

{ taglines; plates; board
  git log --format='%x1e%H%x1f%an%x1f%ad%x1f%ae' --date=format:'%d %B %Y' \
          --no-merges --full-history HEAD -- $GAME "$NOTGAME" 2>/dev/null
} | awk -v RS='\036' -v FS='\037' -v total="$TOTAL" "$MACHINE"'
# JS string literals, a character at a time. gsub would do it in two lines and
# get the backslashes wrong on some awk somewhere; this cannot.
function js(s,   i, c, o) {
  o = ""
  for (i = 1; i <= length(s); i++) {
    c = substr(s, i, 1)
    if (c == "\\")      o = o "\\\\"
    else if (c == "\"") o = o "\\\""
    else if (c == "\r" || c == "\n") o = o " "
    else o = o c
  }
  return o
}
function trim(s) { sub(/^[ \t\r\n]+/, "", s); sub(/[ \t\r\n]+$/, "", s); return s }
BEGIN { v = total + 0 }
$1 == "TAG"  { tag[$2] = $3; next }
$1 == "ART"  { art[$2] = $3; alt[$2] = $4; next }
$1 == "RANK" { rc++; for (k = 2; k <= 8; k++) R[rc, k] = $k; next }
# The same silence the book keeps, in the window the splash screen reads through
# it: a machine is not a pilot here either, and PC below is what counts them.
is_machine($2, $4) { next }
NF >= 3 {
  # a version, newest first, so the number counts down from the newest.
  # The last field of a git record carries the newline that ends it.
  PC[trim($2)]++
  if (v < 1) next
  VW[v] = trim($2); VD[v] = trim($3); VT[v] = ($1 in tag) ? tag[$1] : ""
  VP[v] = ($1 in art) ? art[$1] : "";  VA[v] = ($1 in art) ? alt[$1] : ""
  v--
  next
}
END {
  print "// Generated by tools/chronicle.sh from the history, docs/taglines.tsv,"
  print "// docs/art/index.tsv and docs/RANKINGS.md - the splash screen'"'"'s window"
  print "// into the book. src/ui/book.js and src/ui/board.js load this if it is"
  print "// there and do without it if it is not, so it is never in the manifest"
  print "// and never has to exist. Do not edit: every rebuild writes it fresh."
  print "(function (A) {"
  print "  \"use strict\";"
  print "  A.CHRONICLE = {"
  printf "    versions: %d,\n", total
  if (total >= 1) {
    printf "    latest: { v: %d, pilot: \"%s\", date: \"%s\", line: \"%s\"", \
           total, js(VW[total]), js(VD[total]), js(VT[total])
    if (VP[total] != "") printf ", plate: \"%s\", alt: \"%s\"", js(VP[total]), js(VA[total])
    print " },"
  }
  # The strip along the top of the panel. Four is what it has room for, and
  # the first of them is the newest chapter whether or not anybody has painted
  # it - which is the whole point, and was not true until this line changed.
  #
  # Plates are only painted from main, by somebody whose .env has the
  # credentials, so a run of versions can easily land with none. Filling the
  # strip with the newest four *painted* versions meant the panel led with v37
  # while the cabinet was on v43: a lead chapter six versions stale, on the
  # splash screen, saying it was the news. The lead is the news now, and the
  # three behind it are the gallery - the most recent plates there are, which
  # is what the strip was always for.
  #
  # An entry with no file is a version nobody has painted. src/ui/book.js draws
  # it as a plate-shaped card with its number and its line in it, the same
  # bargain the whole panel already strikes: no data is a layout, not a hole.
  print "    plates: ["
  n = 0
  for (v = total; v >= 1 && n < 4; v--) {
    if (v != total && VP[v] == "") continue
    n++
    printf "      { v: %d,%s alt: \"%s\", line: \"%s\" },\n", v, \
           (VP[v] != "" ? " file: \"" js(VP[v]) "\"," : ""), js(VA[v]), js(VT[v])
  }
  print "    ],"
  # The one service-record fact a page cannot count for itself: versions
  # landed per pilot, counted exactly the way the cover counts them. Events
  # and board flights the splash already knows (the registry, A.BOARD).
  print "    roster: {"
  nr = roster_order(PC, roll)
  for (ri = 1; ri <= nr; ri++) printf "      \"%s\": %d,\n", js(roll[ri]), PC[roll[ri]]
  print "    }"
  print "  };"
  # The board as the file has it - score order, the words included. A tape is
  # the only way onto that table and nothing here is going to be a second way.
  print "  A.BOARD = ["
  for (k = 1; k <= rc; k++) {
    printf "    { rank: \"%s\", pilot: \"%s\", score: \"%s\", wave: \"%s\", time: \"%s\", hits: \"%s\", line: \"%s\" },\n", \
           js(R[k, 2]), js(R[k, 3]), js(R[k, 4]), js(R[k, 5]), js(R[k, 6]), js(R[k, 7]), js(R[k, 8])
  }
  print "  ];"
  print "})(ASTEROIDS);"
}' > docs/chronicle.js

printf 'chronicle: %s version%s, a page each, the cover at docs/index.html,\n' \
  "$TOTAL" "$([ "$TOTAL" = 1 ] || echo s)"
printf '           docs/chronicle.js for the splash screen to read, and\n'
printf '           docs/chronicle-song.js for the room it is read in.\n'
