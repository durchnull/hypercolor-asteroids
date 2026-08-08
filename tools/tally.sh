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
#   tools/tally.sh --roll          the standings, for a human
#
# A bend costs one. Going round the referee costs two, because the whole point
# of a budget is that spending it happens where people can see it. A
# Golden-Rule-Breach line - written by the table when a landing crossed GR8 -
# costs the pilot it names one, whoever held the pen. And clean versions landed
# since a pilot's last bend are counted beside the bends: three of them ease
# the field by one bend's worth. src/game/tally.js does that sum; this file
# only ever reports what the history says.
# ---------------------------------------------------------------------------
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  printf 'tally: not a git repo\n' >&2; exit 1; }
cd "$ROOT" || exit 1

OUT=src/game/ledger.js
MODE=write
PLUS=""
WHO=""

while [ $# -gt 0 ]; do
  case "$1" in
    --print)    MODE=print ;;
    --check)    MODE=check ;;
    --roll)     MODE=roll ;;
    --count)    MODE=count; WHO="${2:-}"; shift ;;
    --plus)     PLUS="${2:-}"; shift ;;
    -h|--help)  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)          printf 'tally: unknown option %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

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
  { sh tools/chronicle.sh --skips 2>/dev/null \
      | awk -F'\t' '{ printf "\036SKIP\037%s\037%s", $1, $2 }'
    sh tools/chronicle.sh --versions 2>/dev/null \
      | awk '{ printf "\036VERSION\037%s", $1 }'
    git log --no-merges --format='%x1e%H%x1f%an%x1f%B%x1f' 2>/dev/null; } \
  | awk -v me="$ME" -v plus="$PLUS" '
      # A message still being written is the newest thing there is, so it goes
      # through first: a pending bend resets its pilot before any landed
      # version can count as "since". It never counts as a version itself -
      # a landing is only clean once it is history.
      BEGIN {
        RS = "\036"; FS = "\037"; pending = 0
        if (plus != "") {
          body = ""
          while ((getline chunk < plus) > 0) body = body chunk "\n"
          pending = 1
          bend(me, body, "", "")
          pending = 0
        }
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
              if (nm != "") add(nm, 1, r)
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

      NF >= 3 { bend($2, $3, $1) }

      END {
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

case "$MODE" in
  print)
    render
    ;;

  count)
    count_of "$WHO"
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
