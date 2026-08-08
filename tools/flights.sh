#!/bin/sh
# ---------------------------------------------------------------------------
# flights.sh - the meter: how many versions a pilot has landed since they flew.
#
# GR14 says a sealed flight buys three landings. Nobody writes that number down
# and nobody edits it: it is read off the history the way tools/tally.sh reads
# the ledger and tools/chronicle.sh reads the book. A flight is a commit that
# put a tape on the board in docs/RANKINGS.md; a version is a commit that moved
# index.html, src/ or styles/. Count one since the other, per pilot, and that is
# the whole of it.
#
#   tools/flights.sh                 the standings, for a human
#   tools/flights.sh --count NAME    versions NAME has landed since flying
#   tools/flights.sh --last NAME     that pilot's most recent flight, or nothing
#   tools/flights.sh --per           versions one tape buys - GR14's constant
#   tools/flights.sh --staged        ... counting a tape staged but not committed
#   tools/flights.sh --dirty         ... counting one in the working tree
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
# A line on the board is taken as a flight, and anybody willing to type one by
# hand can clear their own meter. That is the same posture the seal has
# (tools/blackbox.sh): honesty rather than security. They would be writing
# themselves a receipt for an evening they did not spend, in a public file, in a
# repository that remembers who wrote every line of it.
# ---------------------------------------------------------------------------
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  printf 'flights: not a git repo\n' >&2; exit 1; }
cd "$ROOT" || exit 1

BOARD=docs/RANKINGS.md
PER=3                  # versions one sealed tape buys. GR14, and its only home.
MODE=roll
WHO=""
PEND=none              # none | staged | dirty

while [ $# -gt 0 ]; do
  case "$1" in
    --roll)     MODE=roll ;;
    --count)    MODE=count; WHO="${2:-}"; shift ;;
    --last)     MODE=last;  WHO="${2:-}"; shift ;;
    --per)      printf '%s\n' "$PER"; exit 0 ;;
    --staged)   PEND=staged ;;
    --dirty)    PEND=dirty ;;
    -h|--help)  sed -n '2,26p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)          printf 'flights: unknown option %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

git rev-parse --verify -q HEAD >/dev/null 2>&1 || {
  # No history, no meter. Whatever is being asked, the answer is nothing yet.
  case "$MODE" in count) printf '0\n' ;; esac
  exit 0
}

EPOCH=$(git log --diff-filter=A --format='%H' -- tools/flights.sh 2>/dev/null | tail -1)

# One row per tape ever put on the board, newest first: sha, pilot, and the
# numbers the log line already carries. Read out of the diff rather than out of
# the file as it stands, because when a tape landed is the whole question - and
# the board line is the record, so nothing has to be trusted twice.
#
# The log is append-only and one line is one tape, so a pilot's newest row is
# their last flight. That is all this is asked for; how many rows they have is
# the board's business, not the meter's.
board_flights() {
  git log --format='%x1e%H' --unified=0 -p -- "$BOARD" 2>/dev/null | awk '
    substr($0, 1, 1) == "\036" { sha = substr($0, 2); next }
    /^\+\*\*/ {
      line = substr($0, 4)            # past the "+**"
      sub(/\*\*.*$/, "", line)        # and stopping at the closing stars
      n = split(line, f, " · ")
      if (n < 5) next
      for (i = 1; i <= 5; i++) gsub(/^[ \t]+|[ \t]+$/, "", f[i])
      if (f[2] == "") next
      printf "%s\t%s\t%s\t%s\t%s\t%s\n", sha, f[2], f[1], f[3], f[4], f[5]
    }'
}

# Does the change nobody has committed yet put a tape on the board for a pilot?
# The referee asks this so that flying, ranking and landing in one sitting is
# one sitting rather than a rule violation.
pending_flight() {
  [ "$PEND" = none ] && return 1
  if [ "$PEND" = staged ]; then
    git diff --cached --unified=0 -- "$BOARD" 2>/dev/null
  else
    git diff --unified=0 HEAD -- "$BOARD" 2>/dev/null
  fi | awk -v who="$1" '
    /^\+\*\*/ {
      line = substr($0, 4); sub(/\*\*.*$/, "", line)
      n = split(line, f, " · ")
      if (n < 2) next
      gsub(/^[ \t]+|[ \t]+$/, "", f[2])
      if (f[2] == who) found = 1
    }
    END { exit(found ? 0 : 1) }'
}

# pilot, versions since they last flew, then the last flight itself: date,
# score, wave, time - or empty when they never have.
#
# A landing here is a version somebody built. The book counts the ledger's own
# receipts as versions too, which is the book's business; a receipt the hooks
# wrote is nobody's evening at the keyboard and does not spend a tape, exactly
# as tools/tally.sh does not let one earn a clean landing back.
rows() {
  { board_flights | awk -F'\t' '
      { printf "\036FLIGHT\037%s\037%s\037%s\037%s\037%s\037%s", $1, $2, $3, $4, $5, $6 }'
    git log --no-merges --format='%x1e%H%x1f%an%x1f' --name-only 2>/dev/null; } \
  | awk -v epoch="$EPOCH" '
      BEGIN { RS = "\036"; FS = "\037" }

      # A commit is a version if it moved the page somebody opens. The ledger is
      # generated and rides along with whatever comes next, so it never makes a
      # commit a version - the same judgement tools/tally.sh makes.
      function isversion(files,   n, L, i, t) {
        n = split(files, L, "\n")
        for (i = 1; i <= n; i++) {
          t = L[i]
          if (t == "" || t == "src/game/ledger.js") continue
          if (t == "index.html" || t ~ /^src\// || t ~ /^styles\//) return 1
        }
        return 0
      }

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

      # sha, author, then the file list git wrote after the format string
      NF >= 3 {
        sha = $1; who = $2
        ver = isversion($3)
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
