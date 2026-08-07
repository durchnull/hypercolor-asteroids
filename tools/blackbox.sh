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
#
# Prints the verdict and the JSON. Exit 0 with the seal intact, 1 when the
# tape was edited or mangled, 2 when there is no tape in the input at all.
#
# Under the seal verdict comes a seat verdict: newer tapes seal the name the
# cabinet was locked to (whoami) beside the name that flew (pilot). A mismatch
# means the run was flown under a borrowed name, and GR12 says what that is
# worth: nothing. Older tapes carry no seat and say so.
#
# The seal is honesty, not security: anyone who can read this file can forge
# a tape. They would be lying to a scoreboard in a git repo, and the history
# would remember them doing it, which is deterrent enough around here.
# ---------------------------------------------------------------------------
set -u

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

# FNV-1a, 32-bit, over the exact JSON bytes - the same sum the game wrote.
CRC=$(printf '%s' "$JSON" | od -An -v -tu1 | {
  h=2166136261
  while read -r line; do
    for b in $line; do
      h=$(( ((h ^ b) * 16777619) & 4294967295 ))
    done
  done
  printf '%08x' "$h"
})

if [ "$CRC" != "$CLAIM" ]; then
  printf 'SEAL BROKEN: the tape says %s, the bytes say %s.\n' "$CLAIM" "$CRC" >&2
  printf 'somebody edited this after the ship went down. it ranks nowhere.\n' >&2
  exit 1
fi

printf 'SEAL INTACT (crc %s)\n' "$CRC"

PILOT=$(printf '%s' "$JSON" | sed -n 's/.*"pilot":"\([^"]*\)".*/\1/p')
SEAT=$(printf '%s' "$JSON" | sed -n 's/.*"whoami":"\([^"]*\)".*/\1/p')
if [ -z "$SEAT" ]; then
  printf 'NO SEAT ON TAPE: sealed before seats were taped, or the cabinet was\n'
  printf 'never locked (tools/whoami.sh). The pilot line is the tape'\''s word alone.\n'
elif [ "$SEAT" = "$PILOT" ]; then
  printf 'SEAT CONFIRMED: %s flew this from their own seat.\n' "$PILOT"
else
  printf 'SEAT MISMATCH: flown as %s from %s'\''s seat. A borrowed name ranks\n' "$PILOT" "$SEAT"
  printf 'nowhere, whoever asks - GR12. The numbers decode below all the same.\n'
fi

printf '%s\n' "$JSON"
