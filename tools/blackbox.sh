#!/bin/sh
# ---------------------------------------------------------------------------
# blackbox.sh - read a tape recovered from the game-over screen.
#
# The game seals every finished flight into a block of BB1: lines with an
# FNV-1a checksum over the JSON inside (src/game/blackbox.js writes it, and
# this file is the other half of that pair). A pilot copies the block, pastes
# it to claude, and claude runs this to get the flight back out:
#
#   tools/blackbox.sh tape.txt      read a saved tape
#   pbpaste | tools/blackbox.sh     read one straight off the clipboard
#   tools/blackbox.sh --save t.txt  read it, and file the flight under docs/tapes/
#   tools/blackbox.sh --sum FILE    the FNV-1a sum over a file's exact bytes
#
# Prints the verdict and the JSON. Exit 0 with the seal intact, 1 when the
# tape was edited or mangled, 2 when there is no tape in the input at all.
#
# Under the seal verdict comes a seat verdict: newer tapes seal the name the
# cabinet was locked to (whoami) beside the name that flew (pilot). A mismatch
# means the run was flown under a borrowed name, and GR12 says what that is
# worth: nothing. Older tapes carry no seat and say so.
#
# Under that comes the ambush reel: newer tapes carry every event that fired -
# id, author, wave - and how many ships went down while it was live. That is
# the pilot-vs-pilot half of the flight, and the half the rankings quote when
# an event earns its author a public kill. Older tapes have no reel and say so.
#
# The seal is honesty, not security: anyone who can read this file can forge
# a tape. They would be lying to a scoreboard in a git repo, and the history
# would remember them doing it, which is deterrent enough around here.
#
# What --save is for. The board keeps a sentence and the tape's checksum, and
# for a long time it kept nothing else - so a row that had landed could never
# be read back, by anybody, ever. Every other number here is derived and
# re-derivable: the ledger off the history, the meter off the board's own
# commits, the versions off the commits. The board was the one scoreboard that
# was not. --save writes the decoded flight to docs/tapes/<crc>.json, exactly
# the bytes the sum was taken over, so the referee can recompute it later and
# so can anybody with this script. The BB1 block itself still never enters the
# repository - GR16 is about where a tape comes from, and the answer is still
# the glass.
# ---------------------------------------------------------------------------
set -u

TAPES=docs/tapes
SAVE=0

# FNV-1a, 32-bit, over the exact bytes on stdin - the same sum the game wrote,
# and the only implementation of it on this side of the glass. tools/tally.sh
# reads the ledger, tools/chronicle.sh reads the book and this reads the seal;
# the referee asks rather than keeping a second copy, so there is one answer to
# what a flight's sum is and it lives here.
fnv1a() {
  od -An -v -tu1 | {
    h=2166136261
    while read -r line; do
      for b in $line; do
        h=$(( ((h ^ b) * 16777619) & 4294967295 ))
      done
    done
    printf '%08x' "$h"
  }
}

case "${1:-}" in
  --sum)
    [ $# -ge 2 ] && [ -f "$2" ] || {
      printf 'blackbox: --sum needs a file\n' >&2; exit 2; }
    fnv1a < "$2"
    printf '\n'
    exit 0 ;;
  --save)
    SAVE=1
    shift ;;
  -h|--help)
    sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
    exit 0 ;;
esac

TAPE=$(cat "${1:--}")

BODY=$(printf '%s\n' "$TAPE" | awk '$1 ~ /^BB1:[0-9a-f]+$/ { printf "%s", $2 }')
CLAIM=$(printf '%s\n' "$TAPE" | awk '$1 == "BB1:CRC" { print $2; exit }')

if [ -z "$BODY" ] || [ -z "$CLAIM" ]; then
  printf 'no tape here: expected BB1: body lines and a BB1:CRC seal.\n' >&2
  exit 2
fi

# macOS base64 spells decode -D on older releases, -d everywhere else
if printf 'eQ==' | base64 -d >/dev/null 2>&1; then DECODE="-d"; else DECODE="-D"; fi

JSON=$(printf '%s' "$BODY" | base64 $DECODE 2>/dev/null)
if [ -z "$JSON" ]; then
  printf 'the tape is mangled: the body does not decode.\n' >&2
  exit 1
fi

CRC=$(printf '%s' "$JSON" | fnv1a)

if [ "$CRC" != "$CLAIM" ]; then
  printf 'SEAL BROKEN: the tape says %s, the bytes say %s.\n' "$CLAIM" "$CRC" >&2
  printf 'somebody edited this after the ship went down. it ranks nowhere.\n' >&2
  exit 1
fi

printf 'SEAL INTACT (crc %s)\n' "$CRC"

PILOT=$(printf '%s' "$JSON" | sed -n 's/.*"pilot":"\([^"]*\)".*/\1/p')
SEAT=$(printf '%s' "$JSON" | sed -n 's/.*"whoami":"\([^"]*\)".*/\1/p')

# Has this name ever flown from a locked seat before? The filed flights are the
# record that answers it: one of them carrying both this pilot and a whoami is
# proof that this cabinet was locked at least once under this name. That is
# what ages a missing seat. "No seat" used to mean two things at once - an old
# tape, or a lock somebody removed on the way to borrowing a name - and the
# reader could not tell them apart, so it asked politely about both. With a
# confirmed flight already on file it is no longer a fair question.
flown_locked() {
  [ -d "$TAPES" ] || return 1
  [ -n "$PILOT" ] || return 1
  for t in "$TAPES"/*.json; do
    [ -f "$t" ] || continue
    grep -qF "\"pilot\":\"$PILOT\"" "$t" || continue
    grep -qF "\"whoami\":\"$PILOT\"" "$t" && return 0
  done
  return 1
}

if [ -z "$SEAT" ]; then
  if flown_locked; then
    printf 'SEAT UNPROVEN: this tape carries no seat, and %s has flown from a\n' "$PILOT"
    printf 'locked one before - docs/tapes/ has the flight. An unlocked cabinet\n'
    printf 'under a name that locks its own is the shape of a borrowed name, not\n'
    printf 'of an old tape. Treat it as GR12 does until the pilot says otherwise.\n'
  else
    printf 'NO SEAT ON TAPE: sealed before seats were taped, or the cabinet was\n'
    printf 'never locked (tools/whoami.sh). The pilot line is the tape'\''s word alone.\n'
  fi
elif [ "$SEAT" = "$PILOT" ]; then
  printf 'SEAT CONFIRMED: %s flew this from their own seat.\n' "$PILOT"
else
  printf 'SEAT MISMATCH: flown as %s from %s'\''s seat. A borrowed name ranks\n' "$PILOT" "$SEAT"
  printf 'nowhere, whoever asks - GR12. The numbers decode below all the same.\n'
fi

# What the field was charging while this was flown. The ledger is generated
# from the history and the referee checks it, but it is read off the working
# tree at play time - so the tape seals the number it actually flew under, and
# a field quietly talked down is a thing the board can see. Older tapes have no
# ledger and say nothing, which is not a gap to fill in by asking.
BENDS=$(printf '%s' "$JSON" | sed -n 's/.*"ledger":{"bends":\([0-9]*\).*/\1/p')
CLEAN=$(printf '%s' "$JSON" | sed -n 's/.*"ledger":{"bends":[0-9]*,"clean":\([0-9]*\).*/\1/p')
TS=$(printf '%s' "$JSON" | sed -n 's/.*"ts":"\([^"]*\)".*/\1/p')

# ... and then the thing sealing it was for. The row above was printed straight
# off the tape and stopped there, which made it the one number on a tape that
# exists to be disputed and could not be. Bends only ever grow, so holding a
# sealed 5 against today's 5 proves nothing about the evening it was sealed on:
# the question is what the history said *then*, and tools/tally.sh --at answers
# it off the same history everything else here is read off.
#
# The tape's own timestamp picks the commit - the newest one that had landed
# when the ship went down, which is the ledger the post-commit hook had just
# written into the tree the game then read. Forgiving where it cannot know: no
# repository, no commit before the flight, or a tape from before the ledger was
# sealed, and it says nothing rather than guessing.
#
# It does not change the verdict on the seal, and should not. A pilot who flew
# on a branch carrying a bend that main had not seen disagrees with the history
# honestly, and so does one who talked their own field down. This says which
# two numbers are in front of the room; the room decides.
if [ -n "$BENDS" ]; then
  printf 'THE FIELD IT FLEW: %s bends, %s clean, as the cabinet read them.\n' "$BENDS" "$CLEAN"
  ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || ROOT=""
  if [ -n "$ROOT" ] && [ -n "$TS" ] && [ -n "$PILOT" ]; then
    WHEN=$(git log -1 --format='%h' --before="$TS" 2>/dev/null)
    if [ -n "$WHEN" ]; then
      SAID=$(sh "$ROOT/tools/tally.sh" --at "$WHEN" --row "$PILOT" 2>/dev/null)
      WB=${SAID%%	*}; WC=${SAID#*	}
      if [ -z "$SAID" ]; then :
      elif [ "$WB" = "$BENDS" ] && [ "$WC" = "$CLEAN" ]; then
        printf 'FIELD CONFIRMED: the history at %s said the same.\n' "$WHEN"
      else
        printf 'FIELD DISPUTED: the history at %s said %s bends and %s clean. The\n' "$WHEN" "$WB" "$WC"
        printf 'ledger is the generated one, and the tape is what the game read.\n'
      fi
    fi
  fi
fi

# The ambush reel. The JSON is machine-written with its keys in a fixed
# order, which is the only reason a shell script gets to read it like this.
case "$JSON" in
  *'"events":[]'*)
    printf 'NO AMBUSHES: the field held its fire for the whole flight.\n' ;;
  *'"events":['*)
    printf 'THE AMBUSHES, as taped:\n'
    printf '%s' "$JSON" | awk '{
      if (!match($0, /"events":\[.*\]/)) next
      s = substr($0, RSTART, RLENGTH)
      while (match(s, /\{"id":"[^"]*","by":"[^"]*","wave":[0-9]+,"deaths":[0-9]+\}/)) {
        o = substr(s, RSTART, RLENGTH)
        s = substr(s, RSTART + RLENGTH)
        split(o, f, "\"")
        wave = o; sub(/.*"wave":/, "", wave); sub(/,.*/, "", wave)
        d = o; sub(/.*"deaths":/, "", d); sub(/[^0-9].*/, "", d)
        printf "  %s (%s), wave %s - %s\n", f[4], f[8], wave, \
               (d + 0 > 0 ? "died inside, " d " down" : "flown clear")
      }
    }' ;;
  *)
    printf 'NO EVENT REEL: sealed before tapes watched the other pilots.\n' ;;
esac

# File it, so the row it becomes can be read back. Written with no trailing
# newline, because the sum was taken over these bytes and nothing else - the
# file is the tape's own evidence, not a pretty-printed copy of it.
if [ "$SAVE" = 1 ]; then
  ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    printf 'blackbox: --save needs a git repo\n' >&2; exit 1; }
  mkdir -p "$ROOT/$TAPES" || exit 1
  if [ -f "$ROOT/$TAPES/$CRC.json" ]; then
    printf 'ALREADY ON FILE: %s/%s.json - this evening is already a row.\n' "$TAPES" "$CRC"
  else
    printf '%s' "$JSON" > "$ROOT/$TAPES/$CRC.json" || exit 1
    printf 'FILED: %s/%s.json - the referee can recompute this one.\n' "$TAPES" "$CRC"
  fi
fi

printf '%s\n' "$JSON"
