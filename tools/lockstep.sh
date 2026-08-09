#!/bin/sh
# ---------------------------------------------------------------------------
# lockstep.sh - one question, one answer, and something that checks.
#
# "Does this commit count as a version?" decides the number on the cabinet, the
# chapter in the book, the plate that gets painted, the clean landing on the
# ledger and the meter under GR14. For a long time it was answered in seven
# places, in two languages, across five scripts, and every one of them carried a
# comment asking the others to keep up. A comment is a promise. This project
# already knows what to do about promises nobody checks.
#
# Six of the seven now ask tools/chronicle.sh instead of answering. The seventh
# could not: the book reads the log as a stream, and by the time a path reaches
# the awk that classifies it there is no stopping to run git. So there are two
# readers left, both in that one file - the GAME/NOTGAME pathspec and the awk
# is_game() - and this puts the same commits to both and fails when they differ.
#
# There is a second question of the same shape, and it is the expensive one:
# "would the referee have let this commit past?" The book re-referees the
# history as it writes, once for the ledger (chronicle.sh --skips, which
# tools/tally.sh prices at two under GR12) and once for the chapters (the
# builder own audit, which accuses somebody in prose). Two readers again, in
# the same file again, kept together by a comment asking each to remember the
# other. So the same treatment: --audit is the handle on the second, and this
# puts the same commits to both.
#
# And a third, the smallest of them: "is this commit the book filing its own
# pages, and therefore not a thing that happened?" The cover answers it in the
# builder, the digest answers it again on its own walk, and that one was a rule
# written twice in different variables rather than one audit written twice. It
# is one function now - is_filing, which both ends call - so what is left to
# drift is the arguments each end hands it, and --digest-silence and
# --book-silence are the handles that put the same commits to both.
#
#   tools/lockstep.sh              the fixture, then this history
#   tools/lockstep.sh --history    ... and ask --moved about every commit, which
#                                  is a fork per commit and takes a moment
#   tools/lockstep.sh -v           say what each reader said, case by case
#
# Exit 0 = the readers agree. Exit 1 = they do not, and the book, the meter and
# the ledger are about to disagree about what happened.
#
# Three parts, cheapest first:
#
#   one home    nothing outside chronicle.sh answers any of the three any more.
#               A grep, because the failure this catches is somebody writing a
#               fresh copy rather than an existing copy going stale.
#   the fixture a scripted cabinet whose commits separate every clause of the
#               rule - the ledger exception, the machine authors, a path that
#               starts with the letters src and is not src/ - with the expected
#               answer written beside each one, and the audits' expected
#               verdict beside that. So it is a specification as well as a
#               comparison: three readers agreeing on the wrong answer still
#               fails, and two audits agreeing on the wrong one does too. That
#               second half is not hypothetical - both of them called a
#               byte-identical rename a GR4 breach until the landing before
#               this one, and a comparison on its own would have gone green
#               through the whole of it.
#   this history the same comparison over the real log, which is the one that
#               matters and the one that is always true right up until it is not.
#
# The fixture's machine is not invented. Its name and address are read out of
# .github/workflows/book.yml, which is where the workflow that files the book
# says who it commits as - so renaming the machine there and forgetting to tell
# chronicle.sh fails here rather than three pushes later, on the cover.
#
# No dependencies, like everything else in tools/ (GR2): sh, git and awk. No
# network, and nothing outside a temporary directory is written.
# ---------------------------------------------------------------------------
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  printf 'lockstep: not a git repo\n' >&2; exit 1; }
cd "$ROOT" || exit 1

BOOK=tools/chronicle.sh
[ -f "$BOOK" ] || { printf 'lockstep: no %s to check\n' "$BOOK" >&2; exit 1; }

VERBOSE=0
DEEP=0
for a in "$@"; do
  case "$a" in
    -v|--verbose) VERBOSE=1 ;;
    --history)    DEEP=1 ;;
    -h|--help)    sed -n '2,41p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)            printf 'lockstep: unknown option %s\n' "$a" >&2; exit 2 ;;
  esac
done

if [ -t 1 ]; then
  R=$(printf '\033[31m'); G=$(printf '\033[32m'); D=$(printf '\033[2m'); Z=$(printf '\033[0m')
else
  R=''; G=''; D=''; Z=''
fi

BAD=0
say()  { printf '%s\n' "$*"; }
ok()   { [ "$VERBOSE" = 1 ] && printf '  %sok%s   %s\n' "$G" "$Z" "$*"; return 0; }
bad()  { BAD=$((BAD + 1)); printf '  %sno%s   %s\n' "$R" "$Z" "$*"; }
note() { printf '       %s%s%s\n' "$D" "$*" "$Z"; }

# The real repository is read once, here, and then this stops being able to see
# it. A hook runs with git's environment exported into it, and every one of
# those variables is inherited by the cabinet below - which would then be a
# window onto this repository rather than a cabinet of its own. tools/referee-
# test.sh learned this the painful way and the list is the same one.
GIT_ENV_UNSET='GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY
GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_QUARANTINE_PATH GIT_PREFIX
GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_AUTHOR_DATE
GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL GIT_COMMITTER_DATE
GIT_CONFIG GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM GIT_CONFIG_COUNT
GIT_REFLOG_ACTION GIT_EDITOR'

WORK=$(mktemp -d) || exit 1
trap 'rm -rf "$WORK"' EXIT INT TERM

# ---------------------------------------------------------------------------
# one home
#
# What a second answer looks like: the game's three paths written out where a
# script can test against them, or one of the machine's names written out where
# a script can compare against it. Prose is not a reader, so comment lines are
# not read - a rule explained in a header is the point of a header.
#
# Two files are allowed to hold it. chronicle.sh is where the question lives.
# This file is where the expected answers live, and they have to be written
# down somewhere for the fixture to mean anything - which is also why the
# fixture is a specification rather than only a comparison: a copy hidden in
# here would have to be the right copy to survive the part below.
# ---------------------------------------------------------------------------
one_home() {
  say 'one home'
  : > "$WORK/copies"
  for f in tools/*.sh .githooks/* .github/workflows/*.yml; do
    [ -f "$f" ] || continue
    case "$f" in tools/chronicle.sh | tools/lockstep.sh) continue ;; esac
    # book.yml is the machine rather than a reader of the test for it. It is
    # still read for the game's paths, and the fixture below reads its seat.
    seat=1; case "$f" in .github/workflows/book.yml) seat=0 ;; esac
    awk -v f="$f" -v seat="$seat" '
      { t = $0; sub(/^[[:space:]]+/, "", t) }
      substr(t, 1, 1) == "#" { next }
      # The game, spelled out rather than asked for. styles carries a slash or a
      # quote so that a stylesheet link is not mistaken for a rule, and an awk
      # regex is allowed its backslash.
      (/styles\\?\// || /[ '"'"'"]styles['"'"'"]/) && (/index\.html/ || /src\\?\//) {
        print f ":" FNR ": " $0; next
      }
      # The machine, named rather than asked about.
      seat == 1 && /Ground Crew|actions@github\.com|\[bot\]@|"the book"/ {
        print f ":" FNR ": " $0
      }
    ' "$f" >> "$WORK/copies"
  done
  if [ -s "$WORK/copies" ]; then
    while IFS= read -r hit; do bad "a second answer: $hit"; done < "$WORK/copies"
    note "ask $BOOK - --game-paths, --versions, --pilots, --moved, --is-game"
  else
    ok 'nothing outside the book answers either question'
  fi
}

# ---------------------------------------------------------------------------
# the fixture
#
# A cabinet built out of plumbing rather than porcelain: no worktree to write,
# no hooks to fire, and it costs about as much as one ordinary git commit does.
# The tools under test are the ones in this working tree, run with the fixture
# as their repository, so what is checked is what is about to be committed.
# ---------------------------------------------------------------------------

# Who the workflow that files the book commits as, read from the workflow
# rather than typed in here. Empty if the file has changed shape, in which case
# the fixture falls back to the names the history already carries and says so.
machine_seat() {
  [ -f .github/workflows/book.yml ] || return 1
  mn=$(sed -n 's/.*git config  *user\.name  *"\([^"]*\)".*/\1/p' .github/workflows/book.yml | tail -1)
  me=$(sed -n 's/.*git config  *user\.email  *"\([^"]*\)".*/\1/p' .github/workflows/book.yml | tail -1)
  [ -n "$mn" ] && [ -n "$me" ] || return 1
  printf '%s\037%s\n' "$mn" "$me"
}

# expected | author | email | paths | gone | blob | audit | silent
#
# The last four are empty on almost every line and mean: a fresh blob of its
# own, nothing removed, the audits are to say nothing about it, and both ends
# of the book are to speak about it.
#
#   gone   paths this commit deletes
#   blob   the case whose content this one carries, rather than a new blob.
#          Which is the whole of what makes a move a move: git calls two
#          identical blobs under two names a rename, and a fixture that wrote a
#          fresh blob would be testing a delete and an add wearing the word.
#   audit  "flag" where the two audits must accuse this commit. Empty is a
#          claim as well - the fixture would rather say clear and be wrong than
#          say nothing and pass.
#   silent "yes" where the digest and the builder must both pass over this
#          commit without a word, as the book filing its own pages. Empty is a
#          claim in the same way: it says the commit gets a line at both ends.
#
# Every clause of the rule gets a line, and the lines that look pointless are
# the ones that were not: src2/ is there because ^src/ and a pathspec of "src"
# disagree about it in principle, and the ledger appears alone and in company
# because those are two different answers.
#
# The last two carry a machine's name over an ordinary address, on purpose. Every
# machine in this history is caught twice over - by the name it files under and
# by the [bot] mark github puts on its address - so a fixture that only ever
# shows both together tests neither. chronicle.sh keeps the retired names
# deliberately, against the day somebody decides the address is enough. These
# two lines are what makes that decision a conversation rather than a commit.
#
# The referee files sit alone in their own commits, with the Rule-Change: line
# GR10 asks for. Not decoration: tools/tally.sh re-referees this history through
# the book's own audit, and a fixture that breaks a red line by accident charges
# its pilot for it and moves the clean landings the ledger check counts.
#
# The last two lines are the audits' pair, and they are Bo's on purpose: he is
# on neither the meter's list nor the ledger's, so putting him two deep in the
# red moves none of the numbers above. He carries off Ada's commons outright
# and no override line, which both audits have to call - a check where nothing
# is ever flagged is one that passes while broken. Then he moves Ada's rock to
# a new name and changes not one byte of it, which neither audit may call, and
# which both of them called until the landing before this one.
cases() {
  cat <<EOF
no|Ada Vex|ada@example.com|tools/flights.sh tools/tally.sh GOLDEN_RULES.md
yes|Ada Vex|ada@example.com|index.html
no|Ada Vex|ada@example.com|README.md
yes|Ada Vex|ada@example.com|src/entities/rock.js
yes|Ada Vex|ada@example.com|styles/tokens.css
no|Ada Vex|ada@example.com|src/game/ledger.js
yes|Ada Vex|ada@example.com|src/game/ledger.js src/game/waves.js
no|Ada Vex|ada@example.com|docs/index.html docs/v1.html||||yes
no|Ada Vex|ada@example.com|src2/nothing.js srcish.txt
no|Ada Vex|ada@example.com|tools/whatever.sh
yes|Ada Vex|ada@example.com|src/events/ada.js docs/index.html
yes|Bo Renn|bo@example.com|src/ui/hud.js
no|Bo Renn|bo@example.com|docs/RANKINGS.md
no|$MACHINE_NAME|$MACHINE_MAIL|src/entities/comet.js
no|the book|41898282+github-actions[bot]@users.noreply.github.com|index.html
no|Ground Crew|actions@github.com|styles/crt.css
no|dependabot[bot]|49699333+dependabot[bot]@users.noreply.github.com|src/main.js
no|the book|thebook@example.com|src/render/bloom.js
no|Ground Crew|crew@example.com|src/audio/riff.js
yes|Bo Renn|bo@example.com||index.html||flag
yes|Bo Renn|bo@example.com|src/entities/boulder.js|src/entities/rock.js|4|
no|Ada Vex|ada@example.com|docs/index.html docs/v2.html
EOF
}

# Which cases are nothing but referee files, and so need GR10's line in the
# message. Kept beside the table rather than inside it, because it is the
# fixture's own paperwork and not part of the question being asked.
rule_change_case() {
  case "$1" in 1 | 10) return 0 ;; esac
  return 1
}

# And which case carries a ledger receipt. Same reason it is out here, and it
# exists for one clause of one rule: the silence over the book filing itself
# lifts for a commit that spent an override, altered a rule, went round the
# referee or was written up by the ledger, whatever files it rode in on. The
# case above it is the identical shape of commit without the trailer, so the
# pair says both halves of the clause rather than half of it. A receipt on a
# docs-only commit is contrived, which is the point: a fixture that only ever
# showed the reachable shapes would leave the exception untested.
tally_case() {
  case "$1" in 22) return 0 ;; esac
  return 1
}

build_cabinet() {
  CAB=$WORK/cabinet
  mkdir -p "$CAB/tools" || return 1
  : > "$WORK/expected"
  : > "$WORK/cases.idx"
  for t in chronicle.sh flights.sh tally.sh; do
    [ -f "tools/$t" ] && cp "tools/$t" "$CAB/tools/$t"
  done

  # The whole history written out as one fast-import stream. A commit apiece
  # through the porcelain was most of what this check used to cost, and the
  # tools it exercises never look at a worktree - only at the log.
  #
  # The blank line before a trailer is load-bearing. Without one git calls the
  # whole message a subject, %b comes back empty, and the book's audit reads a
  # rule change as a rule changed without saying why - which charges the
  # fixture's own pilot two and moves every number the ledger check counts.
  {
    n=0
    cases | while IFS='|' read -r want who mail paths gone blob audit silent; do
      n=$((n + 1))
      when=$((1750000000 + n * 3600))
      # A case that names another case's blob is carrying that content rather
      # than content of its own, which is the only way to write a move: git
      # calls two identical blobs under two names a rename and two different
      # ones a delete and an add, and those are the two answers this is here
      # to tell apart.
      printf 'blob\nmark :%d\ndata <<LOCKSTEP\nfixture %d\nLOCKSTEP\n\n' "$n" "$n"
      printf 'commit refs/heads/main\nmark :%d\n' "$((100 + n))"
      printf 'author %s <%s> %d +0000\n' "$who" "$mail" "$when"
      printf 'committer %s <%s> %d +0000\n' "$who" "$mail" "$when"
      printf 'data <<LOCKSTEP\ncase %d\n' "$n"
      # Case 2 lands on the ledger, so tools/tally.sh has a pilot whose clean
      # versions can be counted. Near the bottom, so most of Ada's are above it.
      [ "$n" = 2 ] && printf '\nGolden-Rule-Override: GR6 - the fixture needs a pilot on the ledger\n'
      rule_change_case "$n" && printf '\nRule-Change: the fixture own scaffolding\n'
      tally_case "$n" && printf '\nTally: Ada Vex - 1\n'
      printf 'LOCKSTEP\n'
      for p in $paths; do printf 'M 100644 :%d %s\n' "${blob:-$n}" "$p"; done
      for p in $gone; do printf 'D %s\n' "$p"; done
      printf '\n'
      # A deleted path is a path the commit touched, and every reader below has
      # to be asked about the same list the log will hand it.
      printf '%d\t%s\t%s\t%s\t%s\t%s\n' "$n" "$want" "$who" "$paths $gone" "$audit" "$silent" \
        >> "$WORK/cases.idx"
    done
  } > "$WORK/stream"

  ( cd "$CAB" || exit 1
    # shellcheck disable=SC2086
    unset $GIT_ENV_UNSET 2>/dev/null || true
    git init -q . >/dev/null 2>&1 || exit 1
    git fast-import --quiet --export-marks="$WORK/marks" < "$WORK/stream" || exit 1
    git symbolic-ref HEAD refs/heads/main
  ) || return 1

  # The marks file is how the stream says which commit each case became.
  awk -F'\t' '
      NR == FNR { split($0, a, " "); m = a[1]; sub(/^:/, "", m); sha[m] = a[2]; next }
      { print sha[100 + $1] "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 }
  ' "$WORK/marks" "$WORK/cases.idx" > "$WORK/expected"
  [ -s "$WORK/expected" ]
}

# The three readers, asked about one commit.
#
#   pathspec  the GAME/NOTGAME list, through git, as --versions prints it
#   moved     the same list through a different git command, one commit at a time
#   is_game   the awk the book classifies a streamed path with, plus --pilots,
#             which is the only place the machine test can be got at
ask_readers() {
  cab=$1; expected=$2; out=$3
  ( cd "$cab" || exit 1
    # shellcheck disable=SC2086
    unset $GIT_ENV_UNSET 2>/dev/null || true
    sh "$ROOT/$BOOK" --versions > "$WORK/r.versions" 2>/dev/null
    sh "$ROOT/$BOOK" --pilots   > "$WORK/r.pilots"   2>/dev/null
    # Every path in the fixture, classified in one pass. is_game answers about a
    # path and knows nothing about commits, so asking it once about all of them
    # is the same question as asking it seventeen times.
    awk -F'\t' '{ n = split($4, L, " "); for (i = 1; i <= n; i++) print L[i] }' "$expected" \
      | sort -u | sh "$ROOT/$BOOK" --is-game > "$WORK/r.game" 2>/dev/null
    # And --moved about every commit, in one process rather than one each. It is
    # the same function either way; the difference is how long a shell spends
    # reading seven thousand lines of book-builder before it can answer.
    # shellcheck disable=SC2046
    sh "$ROOT/$BOOK" --moved-each $(awk -F'\t' '{ print $1 }' "$expected") \
      > "$WORK/r.moved" 2>/dev/null

    # Four answers and the table they are checked against, joined in one pass.
    # A shell loop here is a handful of greps per case and it was most of what
    # this file cost to run.
    awk -F'\t' -v v="$WORK/r.versions" -v p="$WORK/r.pilots" \
               -v g="$WORK/r.game" -v m="$WORK/r.moved" '
        FILENAME == v { listed[$0] = 1; next }
        FILENAME == p { pilot[$0]  = 1; next }
        FILENAME == g { game[$0]   = 1; next }
        FILENAME == m { mvd[$2]    = $1; next }
        {
          a = (($1 in listed) ? "yes" : "no")
          b = (($1 in mvd) ? mvd[$1] : "?")
          c = "no"
          if ($3 in pilot) {
            n = split($4, L, " ")
            for (i = 1; i <= n; i++) if (L[i] in game) { c = "yes"; break }
          }
          printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n", $1, $2, a, b, c, $3, $4
        }
    ' "$WORK/r.versions" "$WORK/r.pilots" "$WORK/r.game" "$WORK/r.moved" "$expected"
  ) > "$out"
}

compare() {
  while IFS="$(printf '\t')" read -r sha want a b c who paths; do
    label="$who: $paths"
    if [ "$a" = "$b" ] && [ "$b" = "$c" ] && [ "$c" = "$want" ]; then
      ok "$want   $label"
      continue
    fi
    if [ "$a" = "$b" ] && [ "$b" = "$c" ]; then
      bad "all three readers say $a, the rule says $want   -   $label"
    else
      bad "the readers disagree   -   $label"
      note "pathspec=$a  moved=$b  is_game=$c  expected=$want  ($(printf '%.8s' "$sha"))"
    fi
  done < "$1"
}

fixture() {
  say ''
  say 'the fixture'

  if seat=$(machine_seat); then
    MACHINE_NAME=${seat%%"$(printf '\037')"*}
    MACHINE_MAIL=${seat#*"$(printf '\037')"}
  else
    MACHINE_NAME='Ground Crew'
    MACHINE_MAIL='actions@github.com'
    note 'no user.name/user.email found in .github/workflows/book.yml - using the names the history carries'
  fi

  if ! build_cabinet; then
    bad 'the cabinet would not build'
    return
  fi
  ask_readers "$WORK/cabinet" "$WORK/expected" "$WORK/answers"
  compare "$WORK/answers"

  # The count on the cabinet is the list, counted. They cannot drift while that
  # is true, and this is what says it stayed true.
  want=$(awk -F'\t' '$2 == "yes" { n++ } END { print n + 0 }' "$WORK/expected")
  got=$( cd "$WORK/cabinet" && sh "$ROOT/$BOOK" --version 2>/dev/null )
  if [ "$got" = "v$want" ]; then ok "the cabinet is on v$want"
  else bad "--version says ${got:-nothing} where the versions list has $want in it"; fi

  audits "$WORK/cabinet" "$WORK/expected"
  silences "$WORK/cabinet" "$WORK/expected"
  meter
  ledger
}

# tools/flights.sh no longer decides what a version is, and this is what makes
# that a fact rather than a line in a comment: the meter is read for every pilot
# in the fixture and has to match the versions they landed after the epoch. The
# first fixture commit adds tools/flights.sh, so the epoch is the bottom of the
# history and everything above it counts.
meter() {
  [ -f "$WORK/cabinet/tools/flights.sh" ] || return 0
  # Two pilots rather than all five, because these are the two that carry
  # information and each one costs a shell reading tools/chronicle.sh twice
  # over: the pilot who landed most of the fixture's versions, and the machine,
  # whose commit in here touches src/ and whose meter therefore has to read
  # zero. That second row is the bug this whole file came out of.
  printf '%s\n%s\n' 'Ada Vex' "$MACHINE_NAME" | sort -u > "$WORK/whos"
  while IFS= read -r who; do
    want=$(awk -F'\t' -v w="$who" '$2 == "yes" && $3 == w { n++ } END { print n + 0 }' "$WORK/expected")
    got=$( cd "$WORK/cabinet" || exit
           # shellcheck disable=SC2086
           unset $GIT_ENV_UNSET 2>/dev/null || true
           sh tools/flights.sh --count "$who" 2>/dev/null )
    case ${got:-x} in ''|*[!0-9]*) got=- ;; esac
    if [ "$got" = "$want" ]; then ok "the meter has $who at $want"
    else bad "the meter has $who at $got, the versions list has $want"; fi
  done < "$WORK/whos"
}

# The other question, and the other pair of readers. The book re-referees every
# commit it files, twice: --skips reduces the verdict to a list tools/tally.sh
# prices at two a line (GR12), and the builder writes the same verdict out as
# prose in the chapter. Same budgets, same exemptions, same forgiving form -
# said in two comments and, until now, by nobody who could be wrong out loud.
#
# The expectation is checked as well as the agreement, because two copies of one
# mistake agree perfectly. It is what the rename case is for: both audits read a
# move as a burial, both said flag, and a comparison would have called that
# lockstep right up to the day somebody looked at their ledger.
audits() {
  cab=$1; expected=$2
  ( cd "$cab" || exit 1
    # shellcheck disable=SC2086
    unset $GIT_ENV_UNSET 2>/dev/null || true
    sh "$ROOT/$BOOK" --skips > "$WORK/a.skips" 2>/dev/null
    sh "$ROOT/$BOOK" --audit > "$WORK/a.audit" 2>/dev/null
  )
  awk -F'\t' -v s="$WORK/a.skips" -v b="$WORK/a.audit" '
      FILENAME == s { skips[$1] = 1; next }
      FILENAME == b { book[$1]  = 1; next }
      {
        printf "%s\t%s\t%s\t%s\t%s\n",
               (($1 in skips) ? "flag " : "clear"), (($1 in book) ? "flag " : "clear"),
               ($5 == "flag" ? "flag " : "clear"), $3, $4
      }
  ' "$WORK/a.skips" "$WORK/a.audit" "$expected" > "$WORK/a.rows"

  while IFS="$(printf '\t')" read -r a b want who paths; do
    label="$who:$paths"
    if [ "$a" = "$b" ] && [ "$b" = "$want" ]; then
      ok "$want $label"
    elif [ "$a" = "$b" ]; then
      bad "both audits say $a, the rule says $want   -   $label"
    else
      bad "--skips says $a and --audit says $b   -   $label"
    fi
  done < "$WORK/a.rows"
}

# The third pair, and the smallest question of the three: which commits the book
# passes over without a word, being nothing but the pages it wrote about itself.
# The cover answers it in the builder and the digest answers it again on its own
# walk, and until this they were one rule spelled twice - bookish and offbook at
# one end, five moved flags and five trailer tests at the other - with a comment
# at each end asking the other to keep up.
#
# The rule is one function now, so what is left to drift is the arguments each
# end hands it, and that is what this compares. The expectation is checked too,
# for the reason the audits are: one rule called twice with the same wrong
# argument agrees with itself perfectly.
silences() {
  cab=$1; expected=$2
  ( cd "$cab" || exit 1
    # shellcheck disable=SC2086
    unset $GIT_ENV_UNSET 2>/dev/null || true
    sh "$ROOT/$BOOK" --digest-silence > "$WORK/s.digest" 2>/dev/null
    sh "$ROOT/$BOOK" --book-silence   > "$WORK/s.book"   2>/dev/null
  )
  awk -F'\t' -v d="$WORK/s.digest" -v b="$WORK/s.book" '
      FILENAME == d { digest[$1] = 1; next }
      FILENAME == b { book[$1]   = 1; next }
      {
        printf "%s\t%s\t%s\t%s\t%s\n",
               (($1 in digest) ? "quiet " : "spoken"), (($1 in book) ? "quiet " : "spoken"),
               ($6 == "yes" ? "quiet " : "spoken"), $3, $4
      }
  ' "$WORK/s.digest" "$WORK/s.book" "$expected" > "$WORK/s.rows"

  while IFS="$(printf '\t')" read -r a b want who paths; do
    label="$who:$paths"
    if [ "$a" = "$b" ] && [ "$b" = "$want" ]; then
      ok "$want $label"
    elif [ "$a" = "$b" ]; then
      bad "both ends say $a, the rule says $want   -   $label"
    else
      bad "the digest says $a and the book says $b   -   $label"
    fi
  done < "$WORK/s.rows"
}

# The same again for tools/tally.sh, which counts clean landings off the same
# answer. Case 2 carries an override, so Ada is on the ledger and everything she
# landed above it is a clean version - the bend's own commit included in neither
# count, which is the arithmetic GR12 describes.
ledger() {
  [ -f "$WORK/cabinet/tools/tally.sh" ] || return 0
  want=$(awk -F'\t' 'NR > 2 && $2 == "yes" && $3 == "Ada Vex" { n++ } END { print n + 0 }' "$WORK/expected")
  got=$( cd "$WORK/cabinet" || exit
         # shellcheck disable=SC2086
         unset $GIT_ENV_UNSET 2>/dev/null || true
         sh tools/tally.sh --print 2>/dev/null \
           | sed -n 's/.*"Ada Vex".*clean: \([0-9]*\).*/\1/p' )
  if [ "${got:-}" = "$want" ]; then ok "the ledger has Ada Vex on $want clean landings"
  else bad "the ledger has Ada Vex on ${got:-nothing} clean landings, the versions list has $want"; fi
}

# ---------------------------------------------------------------------------
# this history
#
# The fixture is the cases somebody thought of. This is the one that has to be
# true, and it costs four commands however long the history gets: the versions
# list, the roster, every path the log has ever mentioned put to is_game, and
# then one pass to see whether the two readers picked the same commits.
#
# --history adds --moved, one fork per commit, which is the only reader that
# cannot be asked in bulk.
# ---------------------------------------------------------------------------
this_history() {
  say ''
  say 'this history'
  git rev-parse --verify -q HEAD >/dev/null 2>&1 || { ok 'no history yet'; return; }

  sh "$BOOK" --versions > "$WORK/h.versions" 2>/dev/null
  sh "$BOOK" --pilots   > "$WORK/h.pilots"   2>/dev/null
  git log --format='%x1e%H%x1f%an%x1f' --name-only --no-merges --full-history HEAD \
      2>/dev/null > "$WORK/h.log"

  awk -v RS='\036' -v FS='\037' 'NF >= 3 { n = split($3, L, "\n"); for (i = 1; i <= n; i++) if (L[i] != "") print L[i] }' \
      "$WORK/h.log" | sort -u | sh "$BOOK" --is-game > "$WORK/h.game" 2>/dev/null

  awk -v RS='\036' -v FS='\037' '
      BEGIN {
        while ((getline p < ARGV[1]) > 0) game[p] = 1
        while ((getline w < ARGV[2]) > 0) pilot[w] = 1
        while ((getline s < ARGV[3]) > 0) listed[s] = 1
        ARGV[1] = ARGV[2] = ARGV[3] = ""
      }
      NF >= 3 {
        sha = $1; who = $2
        hit = 0
        n = split($3, L, "\n")
        for (i = 1; i <= n; i++) if (L[i] != "" && (L[i] in game)) { hit = 1; break }
        byawk = (hit && (who in pilot))
        if (byawk != (sha in listed))
          printf "%s\t%s\t%s\t%s\n", sha, (sha in listed ? "yes" : "no"), (byawk ? "yes" : "no"), who
        seen++
      }
      END { printf "=%d\n", seen + 0 }
  ' "$WORK/h.game" "$WORK/h.pilots" "$WORK/h.versions" "$WORK/h.log" > "$WORK/h.diff"

  n=$(sed -n 's/^=//p' "$WORK/h.diff")
  v=$(awk 'END { print NR + 0 }' "$WORK/h.versions")
  if grep -q '	' "$WORK/h.diff"; then
    grep '	' "$WORK/h.diff" | while IFS="$(printf '\t')" read -r sha a c who; do
      bad "$(printf '%.8s' "$sha") - pathspec=$a is_game=$c   $who: $(git log -1 --format='%s' "$sha" 2>/dev/null)"
    done
    # A subshell counted those, so the tally has to come back across the pipe.
    BAD=$((BAD + $(grep -c '	' "$WORK/h.diff")))
  else
    ok "${n:-0} commits, and both readers picked the same $v of them"
  fi

  # And the other pair, over the same log. No expectation to check against out
  # here - what the referee would have said about a commit landed two years ago
  # is what the audits say it is - so this is the comparison alone, which is
  # exactly the half the fixture above cannot be trusted to do on its own.
  sh "$BOOK" --skips 2>/dev/null | sort > "$WORK/h.skips"
  sh "$BOOK" --audit 2>/dev/null | sort > "$WORK/h.audit"
  if cmp -s "$WORK/h.skips" "$WORK/h.audit"; then
    ok "both audits flagged the same $(awk 'END { print NR + 0 }' "$WORK/h.skips") of them"
  else
    # Whichever side has it, named by the side that does not.
    comm -3 "$WORK/h.skips" "$WORK/h.audit" \
      | while IFS="$(printf '\t')" read -r one two three; do
          if [ -n "$three" ]; then sha=$two; who=$three; which='--audit alone'
          else                     sha=$one; who=$two;   which='--skips alone'; fi
          bad "$(printf '%.8s' "$sha") - flagged by $which   $who: $(git log -1 --format='%s' "$sha" 2>/dev/null)"
        done
    BAD=$((BAD + $(comm -3 "$WORK/h.skips" "$WORK/h.audit" | grep -c .)))
  fi

  # And the third pair, the same way. Nothing to check the answer against out
  # here either: whether a commit was the book filing itself is a fact about
  # what it touched, and both ends are looking at the same commit.
  sh "$BOOK" --digest-silence 2>/dev/null | sort > "$WORK/h.digest"
  sh "$BOOK" --book-silence   2>/dev/null | sort > "$WORK/h.book"
  if cmp -s "$WORK/h.digest" "$WORK/h.book"; then
    ok "both ends passed over the same $(awk 'END { print NR + 0 }' "$WORK/h.digest") of them in silence"
  else
    comm -3 "$WORK/h.digest" "$WORK/h.book" \
      | while IFS="$(printf '\t')" read -r one two three; do
          if [ -n "$three" ]; then sha=$two; who=$three; which='the book alone'
          else                     sha=$one; who=$two;   which='the digest alone'; fi
          bad "$(printf '%.8s' "$sha") - passed over by $which   $who: $(git log -1 --format='%s' "$sha" 2>/dev/null)"
        done
    BAD=$((BAD + $(comm -3 "$WORK/h.digest" "$WORK/h.book" | grep -c .)))
  fi

  [ "$DEEP" = 1 ] || return 0

  # --moved, one commit at a time, which is how the hooks ask it and the only
  # reader that cannot be asked in bulk.
  git log --format='%H' --no-merges --full-history HEAD 2>/dev/null > "$WORK/h.all"
  miss=0
  while IFS= read -r sha; do
    if sh "$BOOK" --moved "$sha" >/dev/null 2>&1; then b=yes; else b=no; fi
    if grep -qxF "$sha" "$WORK/h.versions"; then a=yes; else a=no; fi
    [ "$a" = "$b" ] && continue
    bad "$(printf '%.8s' "$sha") - pathspec=$a moved=$b   $(git log -1 --format='%an: %s' "$sha" 2>/dev/null)"
    miss=$((miss + 1))
  done < "$WORK/h.all"
  [ "$miss" = 0 ] && ok "--moved agrees about all $(awk 'END { print NR }' "$WORK/h.all") of them"
}

one_home
fixture
this_history

say ''
if [ "$BAD" = 0 ]; then
  printf '  %sin lockstep%s - one question, one answer.\n\n' "$G" "$Z"
  exit 0
fi
printf '  %s%d disagreement%s%s - the book, the meter and the ledger are about to\n' \
       "$R" "$BAD" "$([ "$BAD" = 1 ] || echo s)" "$Z"
printf '  tell different stories about what happened.\n\n'
exit 1
