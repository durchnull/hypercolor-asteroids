#!/bin/sh
# ---------------------------------------------------------------------------
# flights.sh - the meter: how many versions a pilot has landed since they flew.
#
# GR14 says a sealed flight buys three landings. Nobody writes that number down
# and nobody edits it: it is read off the history the way tools/tally.sh reads
# the ledger and tools/chronicle.sh reads the book. A flight is a commit that
# put a tape on the board in docs/RANKINGS.md; which commits are versions is
# tools/chronicle.sh's answer and this asks for it. Count one since the other,
# per pilot, and that is the whole of it.
#
#   tools/flights.sh                 the standings, for a human
#   tools/flights.sh --count NAME    versions NAME has landed since flying
#   tools/flights.sh --last NAME     that pilot's most recent flight, or nothing
#   tools/flights.sh --per           versions one tape buys - GR14's constant
#   tools/flights.sh --staged        ... counting a tape staged but not committed
#   tools/flights.sh --dirty         ... counting one in the working tree
#   tools/flights.sh --at REV        the meter as it stood when REV landed
#
# A flight is credited to the pilot the board line names, not to whoever held
# the pen - the same way a GR8 breach names the pilot it is about. Couriering a
# friend's tape puts it on their meter, which is the honest answer.
#
# The meter starts where the rule does: the commit that first added this file.
# Before it there was no promise to keep, so nothing before it is counted, and a
# clone that never installed the hooks arrives at the same numbers as everybody
# else.
#
# A line on the board counts as a flight when it carries the tape's own
# checksum under it - `<!-- crc xxxxxxxx -->`, which tools/blackbox.sh prints
# and the ranking ritual files - and only the first time that checksum reaches
# the board. Two evenings cannot be one tape and one tape cannot be two
# evenings.
#
# That is still honesty rather than security, the same posture the seal has:
# eight hex digits are eight hex digits, and anybody who can read this file can
# see what shape one is. What it buys is that a receipt for an evening nobody
# spent has to be a number nobody has used, in a public file, in a repository
# that remembers who wrote every line of it - rather than a sentence.
# ---------------------------------------------------------------------------
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  printf 'flights: not a git repo\n' >&2; exit 1; }
cd "$ROOT" || exit 1

BOARD=docs/RANKINGS.md
PER=3                  # versions one sealed tape buys. GR14, and its only home.
MODE=roll
WHO=""
PEND=none              # none | staged | dirty | at
AT=""                  # the commit the meter is read as of, with --at
HIST=HEAD              # the history to read it off

while [ $# -gt 0 ]; do
  case "$1" in
    --roll)     MODE=roll ;;
    --count)    MODE=count; WHO="${2:-}"; shift ;;
    --last)     MODE=last;  WHO="${2:-}"; shift ;;
    --per)      printf '%s\n' "$PER"; exit 0 ;;
    --staged)   PEND=staged ;;
    --dirty)    PEND=dirty ;;
    --at)       PEND=at; AT="${2:-}"; shift ;;
    -h|--help)  sed -n '2,27p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)          printf 'flights: unknown option %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

# --at asks what the meter said to the pilot who was about to land REV, so the
# history it reads is the one that existed then - everything up to REV's parent
# - and REV's own board line is the pending tape, exactly as a staged one is.
# That keeps the rule's own sentence true for a commit being read back later:
# flying, ranking and landing in one sitting is one sitting.
if [ "$PEND" = at ]; then
  AT=$(git rev-parse --verify -q "$AT^{commit}") || {
    printf 'flights: no such commit\n' >&2; exit 2; }
  HIST=$(git rev-parse --verify -q "$AT^") || HIST=""
fi

if [ -z "$HIST" ] || ! git rev-parse --verify -q "$HIST" >/dev/null 2>&1; then
  # No history, no meter. Whatever is being asked, the answer is nothing yet -
  # and --at the very first commit lands here too, which is the right answer for
  # the same reason: nothing had been landed before it.
  case "$MODE" in count) printf '0\n' ;; esac
  exit 0
fi

EPOCH=$(git log "$HIST" --diff-filter=A --format='%H' -- tools/flights.sh 2>/dev/null | tail -1)

# One row per tape ever put on the board, newest first: sha, pilot, the numbers
# the log line already carries, and the crc of the tape it came off. Read out of
# the diff rather than out of the file as it stands, because when a tape landed
# is the whole question - and the board line is the record, so nothing has to be
# trusted twice.
#
# The log is append-only and one line is one tape, so a pilot's newest row is
# their last flight. That is all this is asked for; how many rows they have is
# the board's business, not the meter's.
#
# An entry counts only with a `<!-- crc xxxxxxxx -->` marker under it, and only
# the first time that crc reaches the board. The ritual has always written the
# marker (tools/blackbox.sh prints the sum, the skill files it, and it is what
# stops one evening being pasted twice); until now nothing read it, so a pilot
# who could not be bothered to play could clear their own meter by typing a
# sentence. It is still not security - anybody who can read this file can read
# eight hex digits off somebody else's row - but a forged receipt now has to
# invent a number that is not on the board rather than write itself a line, and
# re-using one is visible to everybody who looks.
board_flights() {
  git log "$HIST" --format='%x1e%H' --unified=0 -p -- "$BOARD" 2>/dev/null | awk '
    # An entry and its receipt are matched by commit and not by adjacency. They
    # are written adjacent and they read that way in the file, but the log is
    # append-only at the top and every entry looks like every other entry, so
    # git is entitled to describe a second one as a receipt inserted above the
    # first - and it does. Pairing them in the order each arrives leaves the
    # meter reading a flight as unsealed because a diff was minimal.
    function close_out(   i, n) {
      n = (ne < nc ? ne : nc)     # an entry with no receipt is a sentence
      for (i = 1; i <= n; i++) {  # somebody typed; a receipt with no entry is
        row[++rows] = ent[i] "\t" crc[i]   # a comment. Neither is an evening.
        seal[rows] = crc[i]
      }
      ne = 0; nc = 0
    }

    substr($0, 1, 1) == "\036" { close_out(); sha = substr($0, 2); next }

    /^\+\*\*/ {
      line = substr($0, 4)            # past the "+**"
      sub(/\*\*.*$/, "", line)        # and stopping at the closing stars
      n = split(line, f, " · ")
      if (n < 5) next
      for (i = 1; i <= 5; i++) gsub(/^[ \t]+|[ \t]+$/, "", f[i])
      if (f[2] == "") next
      ent[++ne] = sha "\t" f[2] "\t" f[1] "\t" f[3] "\t" f[4] "\t" f[5]
      next
    }

    /^\+<!-- crc [0-9a-f]+ -->/ { crc[++nc] = $3 }

    END {
      close_out()

      # Newest first is the order everything downstream wants, but which
      # landing owns a crc is decided oldest first: the evening is the first
      # time that sum reached the board, and every appearance after it is the
      # same evening being read out again.
      for (i = rows; i >= 1; i--) {
        if (seal[i] in taken) continue
        taken[seal[i]] = 1
        keep[i] = 1
      }
      for (i = 1; i <= rows; i++) if (i in keep) print row[i]
    }'
}

# Does the change nobody has committed yet put a tape on the board for a pilot?
# The referee asks this so that flying, ranking and landing in one sitting is
# one sitting rather than a rule violation.
#
# Same two conditions the committed rows are held to, because a receipt that
# only had to be honest after the fact would be no receipt at the one moment it
# is being spent.
pending_flight() {
  [ "$PEND" = none ] && return 1
  taken=$(board_flights | awk -F'\t' '$7 != "" { printf " %s", $7 }')
  case "$PEND" in
    staged) git diff --cached --unified=0 -- "$BOARD" 2>/dev/null ;;
    at)     git diff --unified=0 "$AT^" "$AT" -- "$BOARD" 2>/dev/null ;;
    *)      git diff --unified=0 HEAD -- "$BOARD" 2>/dev/null ;;
  esac | awk -v who="$1" -v taken="$taken " '
    /^\+\*\*/ {
      line = substr($0, 4); sub(/\*\*.*$/, "", line)
      n = split(line, f, " · ")
      if (n < 2) next
      gsub(/^[ \t]+|[ \t]+$/, "", f[2])
      ent[++ne] = f[2]
      next
    }
    /^\+<!-- crc [0-9a-f]+ -->/ { crc[++nc] = $3 }
    END {
      # Zipped, not paired off as they arrive - same reason as above, and one
      # diff rather than a log of them, so this is the whole of it.
      n = (ne < nc ? ne : nc)
      for (i = 1; i <= n; i++)
        if (ent[i] == who && index(taken, " " crc[i] " ") == 0) found = 1
      exit(found ? 0 : 1)
    }'
}

# pilot, versions since they last flew, then the last flight itself: date,
# score, wave, time - or empty when they never have.
#
# Which commits are versions is not decided here. This used to keep its own copy
# of the judgement, with a comment asking it to stay in step with two others; it
# asks tools/chronicle.sh instead, folded into the stream ahead of the log the
# way the board's own flights are. That is not tidiness: the copy was already
# wrong. It knew about the generated ledger and not about the machine that files
# it, so the workflow that rebuilds the book after every push had a row on the
# meter and versions to its name, and nothing in here could have noticed.
rows() {
  { sh tools/chronicle.sh --versions "$HIST" 2>/dev/null \
      | awk '{ printf "\036VERSION\037%s", $1 }'
    board_flights | awk -F'\t' '
      { printf "\036FLIGHT\037%s\037%s\037%s\037%s\037%s\037%s", $1, $2, $3, $4, $5, $6 }'
    git log "$HIST" --no-merges --format='%x1e%H%x1f%an%x1f' 2>/dev/null; } \
  | awk -v epoch="$EPOCH" '
      BEGIN { RS = "\036"; FS = "\037" }

      $1 == "VERSION" { version[$2] = 1; next }

      # Flights come past first and newest first, so the first row for a pilot
      # is their latest. Held by sha rather than by author: whoever committed
      # the ranking, the meter that clears is the one belonging to the pilot
      # the line names.
      $1 == "FLIGHT" {
        if ($3 in flown) next
        flown[$3] = $4 " \037 " $5 " \037 " $6 " \037 " $7
        at[$2] = ($2 in at ? at[$2] "\n" : "") $3
        next
      }

      # sha, then author
      NF >= 3 {
        sha = $1; who = $2
        ver = (sha in version)
        if (ver) seen[who] = 1

        # The tape clears the meter before the same commit spends it, so a
        # pilot who flew, ranked and landed in one commit is square.
        if (sha in at) {
          n = split(at[sha], L, "\n")
          for (i = 1; i <= n; i++) closed[L[i]] = 1
        }
        if (epoch != "" && sha == epoch) past = 1

        if (!past && ver && epoch != "" && !closed[who]) since[who]++
      }

      END {
        for (w in flown) seen[w] = 1
        for (w in seen)
          printf "%s\t%d\t%s\n", w, since[w] + 0, (w in flown ? flown[w] : "")
      }
  ' | LC_ALL=C sort
}

case "$MODE" in
  count)
    if [ -n "$WHO" ] && pending_flight "$WHO"; then printf '0\n'; exit 0; fi
    rows | awk -F'\t' -v who="$WHO" '$1 == who { n = $2 } END { print n + 0 }'
    ;;

  last)
    rows | awk -F'\t' -v who="$WHO" -v S="$(printf '\037')" '
      $1 == who && $3 != "" { gsub(S, "·", $3); print $3; found = 1 }
      END { exit(found ? 0 : 1) }'
    ;;

  roll)
    printf '\n  THE FLIGHT METER   one tape buys %s landings (GR14)\n' "$PER"
    if [ -z "$EPOCH" ]; then
      printf '\n    the rule has not landed yet - nothing is counted before it does.\n\n'
      exit 0
    fi
    rows | awk -F'\t' -v per="$PER" -v S="$(printf '\037')" '
      { flew = $3; if (flew == "") flew = "never flown"; else gsub(S, "·", flew)
        verdict = ($2 >= per ? "GROUNDED" : $2 == per - 1 ? "last one" : "clear")
        printf "    %-24s %d since flying   %-8s   last: %s\n", $1, $2, verdict, flew
        n++ }
      END { if (!n) print "    nobody has landed anything. yet." }'
    printf '\n    %s or more since flying and the referee stops the next version\n' "$PER"
    printf '    play it, paste the tape, /blackbox puts it on the board\n\n'
    ;;
esac
