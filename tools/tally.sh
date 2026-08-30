#!/bin/sh
# ---------------------------------------------------------------------------
# tally.sh - the ledger: who has bent a golden rule, and how often.
#
# Nobody assigns these numbers and nobody edits them. They are read off the
# history, the way tools/chronicle.sh reads the book: a commit that spends a
# budget carries a Golden-Rule-Override: line, and a commit that went round the
# referee gets a Referee-Skipped: line written about it by the hooks. This
# counts both, per pilot, and writes src/game/ledger.js - the file the game
# reads to work out how busy somebody's field is going to be. See GR12.
#
#   tools/tally.sh                 write src/game/ledger.js from the history
#   tools/tally.sh --print         write it to stdout instead
#   tools/tally.sh --plus FILE     ... counting a commit message not landed yet
#   tools/tally.sh --check         exit 1 if the file on disk disagrees
#   tools/tally.sh --count NAME    just the number, for a script
#   tools/tally.sh --row NAME      bends and clean, tab separated, for a script
#   tools/tally.sh --roll          the standings, for a human
#   tools/tally.sh --at REV        ... off the history as it stood at REV
#
# A bend costs one. Going round the referee costs two, because the whole point
# of a budget is that spending it happens where people can see it. A
# Golden-Rule-Breach line - written by the table when a landing crossed GR8 -
# costs the pilot it names one, whoever held the pen. And clean versions landed
# since a pilot's last bend are counted beside the bends: three of them ease
# the field by one bend's worth. src/game/tally.js does that sum; this file
# only ever reports what the history says.
#
# --at is what makes a sealed ledger row worth sealing. Every black box carries
# the row the cabinet was charging its pilot while they flew (GR12), and until
# there was a way to ask what the history said on that evening, the one number
# on a tape that exists to be disputed was the one number nobody could dispute:
# bends only ever grow, so a sealed 5 against today's 5 proves nothing. This
# reads the history through REV and nothing after it, which is the copy the
# post-commit hook had just written when the flight began. tools/blackbox.sh
# resolves a tape's own timestamp to a commit and asks.
# ---------------------------------------------------------------------------
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  printf 'tally: not a git repo\n' >&2; exit 1; }
cd "$ROOT" || exit 1

OUT=src/game/ledger.js
MODE=write
PLUS=""
WHO=""
AT=""                  # the commit the ledger is read as of, with --at

while [ $# -gt 0 ]; do
  case "$1" in
    --print)    MODE=print ;;
    --check)    MODE=check ;;
    --roll)     MODE=roll ;;
    --count)    MODE=count; WHO="${2:-}"; shift ;;
    --row)      MODE=row;   WHO="${2:-}"; shift ;;
    --plus)     PLUS="${2:-}"; shift ;;
    --at)       AT="${2:-}"; shift ;;
    -h|--help)  sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)          printf 'tally: unknown option %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

# Through REV and not one commit after it. The ledger is a snapshot of the
# history behind it, so asking it about an evening means handing it the history
# that existed on that evening and nothing else.
#
# Empty means HEAD, and empty is also what a repository with nothing landed in
# it gets - the readers below then answer about the message on the table alone,
# which is what the referee asks on the very first commit.
HIST=HEAD
if [ -n "$AT" ]; then
  HIST=$(git rev-parse --verify -q "$AT^{commit}") || {
    printf 'tally: no such commit\n' >&2; exit 2; }
elif ! git rev-parse --verify -q HEAD >/dev/null 2>&1; then
  HIST=""
fi

ME=$(git config user.name 2>/dev/null || true)

# One record per commit: who flew it, then the whole message. A message that
# has not landed yet counts too, under whoever is at the keyboard - which is
# how the referee checks a ledger commit while it is still only a proposal.
rows() {
  # The commits the referee provably never saw, judged off the history by the
  # book's own audit (tools/chronicle.sh --skips). Folded into the stream so
  # a skip costs its two even when the skipper's hooks never wrote a receipt -
  # and deduplicated against the receipts, so a witnessed skip still costs two
  # rather than four.
  # And which commits are versions, from the same place, for the same reason:
  # a clean landing is a version somebody flew, and this used to decide that for
  # itself off a copied path list. The copy did not know that the workflow
  # filing the book is not a pilot, so a machine could have earned clean
  # landings against a name that cannot fly.
  # And every name the history has ever been authored by. A GR8 breach line
  # names the pilot it is about rather than the pilot who wrote it, which is the
  # whole point of it - and it is therefore the one line in this file where a
  # typo charges somebody who does not exist and lets the somebody who does walk
  # away. The referee refuses that at the gate (check_breach in
  # tools/golden-check.sh) and this reads the history directly, so it has to
  # make the same test: the same question, off the same log, machines included
  # because the question is who has flown here and not who is a person.
  #
  # Forgiving, in the way the audit is forgiving: a name nobody recognises
  # charges nobody, and an empty list charges everybody it used to. This may
  # miss a breach. It may not invent one.
  #
  # The audit is asked about the whole history rather than about HIST, and it
  # does not need to be: a skip it reports for a commit after HIST is a sha the
  # log below never mentions, so nothing is ever charged for it. Left whole
  # because --skips has no rev to take, and giving it one is a change to the
  # book rather than to this.
  { sh tools/chronicle.sh --skips 2>/dev/null \
      | awk -F'\t' '{ printf "\036SKIP\037%s\037%s", $1, $2 }'
    sh tools/chronicle.sh --versions "${HIST:-HEAD}" 2>/dev/null \
      | awk '{ printf "\036VERSION\037%s", $1 }'
    git log $HIST --format='%an' 2>/dev/null | sort -u \
      | awk '$0 != "" { printf "\036FLEW\037%s", $0 }'
    git log $HIST --no-merges --format='%x1e%H%x1f%an%x1f%B%x1f' 2>/dev/null; } \
  | awk -v me="$ME" -v plus="$PLUS" '
      BEGIN { RS = "\036"; FS = "\037"; pending = 0 }

      # A message still being written is the newest thing there is, so it goes
      # through before any landed commit: a pending bend resets its pilot before
      # any landed version can count as "since". It never counts as a version
      # itself - a landing is only clean once it is history.
      #
      # It used to go through in BEGIN, which is one record too early now: the
      # author set arrives down the stream ahead of the log, and a breach line
      # in a message nobody has committed yet has to be able to ask the same
      # question a landed one does. So it goes at the first commit record
      # instead, which is the same place in the order and a later place in the
      # reading.
      function pend(   chunk, body) {
        started = 1
        if (plus == "") return
        body = ""
        while ((getline chunk < plus) > 0) body = body chunk "\n"
        pending = 1
        bend(me, body, "")
        pending = 0
      }

      function add(who, n, what) {
        bends[who] += n
        seen[who] = 1
        # git log runs newest first, so the first mention of a pilot is their
        # latest one; a message still being written beats all of them.
        if (pending || !(who in last)) last[who] = what
      }

      # A receipt is always newer than the commit it names, and the stream is
      # newest first, so by the time a flagged commit comes past every receipt
      # that could excuse it has already been read.
      function receipted(sha,   r) {
        for (r in rcpt) if (index(sha, r) == 1) return 1
        return 0
      }

      function bend(who, body, sha,   n, L, i, t, lt, u, r, nm) {
        n = split(body, L, "\n")
        for (i = 1; i <= n; i++) {
          t = L[i]
          sub(/^[ \t]+/, "", t)
          if (substr(t, 1, 1) == "#") continue   # a template comment is not a confession
          lt = tolower(t)
          if (lt ~ /^golden-rule-override:/) {
            u = toupper(t)
            add(who, 1, (match(u, /GR[0-9]+/) ? substr(u, RSTART, RLENGTH) : "a rule"))
          } else if (lt ~ /^referee-skipped:/) {
            add(who, 2, "the referee itself")
            u = t; sub(/^[^:]*:[ \t]*/, "", u)
            if (match(u, /^[0-9a-f]{7,40}/)) rcpt[substr(u, RSTART, RLENGTH)] = 1
          } else if (lt ~ /^golden-rule-breach:/) {
            # written by the table when a landing crossed GR8. The line names
            # the pilot it is about; the commit author is only the scribe.
            sub(/^[^:]*:[ \t]*/, "", t)
            u = toupper(t)
            if (match(u, /^GR[0-9]+[ \t]/) && t ~ / - /) {
              r = substr(u, RSTART, RLENGTH); sub(/[ \t]+$/, "", r)
              nm = t
              sub(/^[A-Za-z0-9]+[ \t]+/, "", nm)
              sub(/[ \t]+-[ \t].*$/, "", nm)
              # A name no commit was ever authored by is a typo, and a typo is
              # not a verdict: charging it would put a phantom on the ledger and
              # leave whoever the table actually meant untouched. The referee
              # refuses this line at the gate; a clone that never installed the
              # hooks lands it anyway, and then this is the only reader left.
              if (nm != "" && (nflew == 0 || (nm in flew))) add(nm, 1, r)
            }
          }
        }
        # The audit`s verdict, unless a receipt already priced this one in.
        if (sha != "" && (sha in skip) && !receipted(sha))
          add(who, 2, "the referee itself")

        # A landing that moved the game and bent nothing is a clean version,
        # counted only until the pilot`s most recent bend. The book leaves the
        # generated ledger out of what makes a commit a version, or every bend
        # would earn back a third of its cost in the receipt that records it.
        if (pending) return
        if ((sha in version) && !seen[who]) clean[who]++
      }

      $1 == "SKIP"    { skip[$2] = 1; next }
      $1 == "VERSION" { version[$2] = 1; next }
      $1 == "FLEW"    { flew[$2] = 1; nflew++; next }

      NF >= 3 { if (!started) pend(); bend($2, $3, $1) }

      END {
        # A repository with nothing landed in it still has a message on the
        # table, and the referee asks about exactly that on the first commit.
        if (!started) pend()
        for (w in bends) if (bends[w] > 0) printf "%s\t%d\t%d\t%s\n", w, bends[w], clean[w] + 0, last[w]
      }
  ' | tr -d '\\"' | LC_ALL=C sort
}

# The file itself. Generated, so it is written the same way every time from the
# same history - which is exactly what lets the referee check it.
render() {
  cat <<'EOF'
// THE LEDGER - one number per pilot, and the number is how many times they
// have bent a golden rule in the open.
//
// Generated by tools/tally.sh from nothing but the git history, and checked by
// the referee: a ledger that disagrees with the history is a commit that does
// not land. Nobody edits their own record. That is the whole of it.
//
// clean is the other half of the arithmetic: versions the pilot has landed
// since their last bend, read off the same history. Three of them ease the
// field by one bend's worth - src/game/tally.js does that sum. See GR12.
//
// What the number does to a pilot's field is in src/game/tally.js. See GR12.
EOF
  printf 'ASTEROIDS.LEDGER = {\n'
  rows | awk -F'\t' '{ printf "  \"%s\": { bends: %d, clean: %d, last: \"%s\" },\n", $1, $2, $3, $4 }'
  printf '};\n'
}

count_of() {
  rows | awk -F'\t' -v who="$1" '$1 == who { n = $2 } END { print n + 0 }'
}

# Both halves of a pilot's row, because both halves are what the tape seals and
# what src/game/tally.js reads. Zero and zero for a name the ledger does not
# carry, which is the same answer the game gets: no row, no charge.
row_of() {
  rows | awk -F'\t' -v who="$1" '$1 == who { b = $2; c = $3 } END { printf "%d\t%d\n", b + 0, c + 0 }'
}

case "$MODE" in
  print)
    render
    ;;

  count)
    count_of "$WHO"
    ;;

  row)
    row_of "$WHO"
    ;;

  check)
    TMP=$(mktemp) || exit 1
    render > "$TMP"
    if [ -f "$OUT" ] && cmp -s "$TMP" "$OUT"; then
      rm -f "$TMP"
      exit 0
    fi
    rm -f "$TMP"
    printf '%s disagrees with the history. tools/tally.sh rewrites it.\n' "$OUT" >&2
    exit 1
    ;;

  roll)
    printf '\n  THE LEDGER\n'
    rows | awk -F'\t' '
      # the same sum src/game/tally.js does: one bend eased per 3 clean
      { ch = $2 - int($3 / 3); if (ch < 0) ch = 0
        printf "    %-24s %2d bend%s   %2d clean   charges as %d   last: %s\n", $1, $2, ($2 == 1 ? " " : "s"), $3, ch, $4; n++ }
      END { if (!n) print "    nobody has bent anything. yet." }'
    printf '\n    1 bend  events come sooner\n'
    printf '    3 bends your own events stop sparing you\n'
    printf '    4 bends a wave may hold one more ambush\n'
    printf '    every 3 clean versions since the last bend ease all of it one bend\n\n'
    ;;

  write)
    TMP=$(mktemp) || exit 1
    render > "$TMP"
    if [ -f "$OUT" ] && cmp -s "$TMP" "$OUT"; then
      rm -f "$TMP"
      exit 0
    fi
    cat "$TMP" > "$OUT"
    rm -f "$TMP"
    printf 'ledger: %s\n' "$(rows | awk -F'\t' '
      { n++; total += $2 }
      END { printf "%d pilot%s, %d bend%s on the record", n, (n == 1 ? "" : "s"), total, (total == 1 ? "" : "s") }')"
    ;;
esac
