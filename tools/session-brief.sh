#!/bin/sh
# ---------------------------------------------------------------------------
# session-brief.sh - what a pilot needs to know before touching anything.
#
# Runs at session start and hands the assistant the state of the cabinet: which
# version is on it, what the others landed recently, and whether the referee is
# actually installed in this clone. Cheap, quiet, and read-only.
# ---------------------------------------------------------------------------
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$ROOT" || exit 0
git rev-parse --verify -q HEAD >/dev/null 2>&1 || exit 0

TMP=$(mktemp) || exit 0
trap 'rm -f "$TMP"' EXIT INT TERM

{
  printf 'HYPERCOLOR ASTEROIDS - the cabinet right now (see CLAUDE.md, GOLDEN_RULES.md)\n\n'
  printf 'On the cabinet: %s   pilot at the keyboard: %s\n\n' \
    "$(sh tools/chronicle.sh --version)" "$(git config user.name 2>/dev/null || echo 'UNSET - GR7 will block the commit')"

  printf 'Recently landed:\n'
  sh tools/chronicle.sh --recent 6

  if [ "$(git config core.hooksPath 2>/dev/null)" != ".githooks" ]; then
    printf '\nThe referee is NOT installed in this clone. Run tools/golden-check.sh --install\n'
    printf 'before landing anything, and tell the user you did.\n'
  fi

  dirty=$(git status --porcelain | wc -l | tr -d ' ')
  [ "$dirty" -gt 0 ] && printf '\n%s files are already dirty in the working tree - read them before you build on top.\n' "$dirty"

  printf '\nBefore changing the game: skim GOLDEN_RULES.md, and consider /scout.\n'
} > "$TMP"

sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' "$TMP" \
  | awk 'BEGIN{ORS="";print "{\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",\"additionalContext\":\""}
         {print (NR>1?"\\n":"") $0}
         END{print "\"}}\n"}'
