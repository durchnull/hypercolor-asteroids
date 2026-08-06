#!/bin/sh
# ---------------------------------------------------------------------------
# whoami.sh - tell the cabinet who you are.
#
# Writes your git identity into src/game/whoami.local.js, which is untracked
# and never leaves this machine. With it there, the splash screen stops asking
# who is flying and locks the seat to you — which means your own events go
# quiet and everybody else's are armed, which is the whole point.
#
#   tools/whoami.sh          write it from git config user.name
#   tools/whoami.sh --clear  remove it, and get the picker back
#
# This is identity, not security. It is a file; you could obviously edit it.
# You would only be spoiling your own surprises, so nobody has bothered.
# ---------------------------------------------------------------------------
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "not a git repo" >&2; exit 1; }
cd "$ROOT" || exit 1

OUT=src/game/whoami.local.js

if [ "${1:-}" = "--clear" ]; then
  rm -f "$OUT"
  printf 'seat unlocked: the splash screen will ask again.\n'
  exit 0
fi

ME=$(git config user.name 2>/dev/null || true)
if [ -z "$ME" ]; then
  printf 'git config user.name is not set, so there is nobody to be.\n' >&2
  printf 'set it first:  git config user.name "Your Name"\n' >&2
  exit 1
fi

# One string, quoted the same way git gave it to us.
ESCAPED=$(printf '%s' "$ME" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')

cat > "$OUT" <<EOF
// Written by tools/whoami.sh. Untracked, local to this machine, and safe to
// delete — without it the splash screen simply asks who is flying.
//
// This is the seat lock: the pilot named here cannot be ambushed by their own
// events, only by everybody else's.
ASTEROIDS.LOCAL_PILOT = "$ESCAPED";
EOF

printf 'seat locked to %s\n' "$ME"
printf 'your own events will not fire for you. everyone else, though.\n'
