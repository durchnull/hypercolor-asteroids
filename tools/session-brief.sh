#!/bin/sh
# ---------------------------------------------------------------------------
# session-brief.sh - what a pilot needs to know before touching anything.
#
# Runs at session start and hands the assistant the state of the cabinet: which
# version is on it, what the others landed recently, and whether the referee is
# actually installed in this clone. Cheap and quiet.
#
# It used to be read-only as well, and gave that up for one thing: the ground
# crew's paperwork. .github/workflows/book.yml files the book after every push
# to main, under a name that is not a person's, and it lands while nobody is
# looking. A pilot who comes back the next evening starts behind by a commit
# they did not write, finds out at push time, and has to be told about a tool.
#
# Being told is the part that was wrong. Nothing in that exchange is a
# decision: the crew's commits are never a version, never anybody's work, and
# the book passes over them in silence. So this collects them on the way in,
# and mentions it afterwards rather than asking first.
#
# The judgement stays where it already was. tools/groundcrew.sh refuses to
# touch a *person's* commit and says whose it is instead, so the one case that
# genuinely needs a pilot reading something still gets one. A dirty tree stops
# it too, and offline is not an error.
# ---------------------------------------------------------------------------
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$ROOT" || exit 0
git rev-parse --verify -q HEAD >/dev/null 2>&1 || exit 0

CREW=""
if [ -f tools/groundcrew.sh ]; then
  CREW=$(sh tools/groundcrew.sh --quiet 2>&1 || true)
fi

TMP=$(mktemp) || exit 0
trap 'rm -f "$TMP"' EXIT INT TERM

{
  printf 'HYPERCOLOR ASTEROIDS - the cabinet right now (see CLAUDE.md, GOLDEN_RULES.md)\n\n'
  printf 'On the cabinet: %s   pilot at the keyboard: %s\n\n' \
    "$(sh tools/chronicle.sh --version)" "$(git config user.name 2>/dev/null || echo 'UNSET - GR7 will block the commit')"

  printf 'Recently landed:\n'
  sh tools/chronicle.sh --recent 6

  # GR14's meter. Put here rather than left to the referee because this is the
  # rule a pilot forgets rather than the one they argue with, and a line at the
  # top of the evening costs nothing while a block at the end of it costs a
  # commit message.
  ME=$(git config user.name 2>/dev/null || true)
  if [ -n "$ME" ] && [ -f tools/flights.sh ]; then
    PER=$(sh tools/flights.sh --per 2>/dev/null || printf '3')
    SINCE=$(sh tools/flights.sh --count "$ME" 2>/dev/null || printf '0')
    LAST=$(sh tools/flights.sh --last "$ME" 2>/dev/null || printf '')
    case "$SINCE" in ''|*[!0-9]*) SINCE=0 ;; esac
    if [ "$SINCE" -ge "$PER" ]; then
      printf '\nFlight meter: %s versions landed since you last flew, and a tape covers %s (GR14).\n' "$SINCE" "$PER"
      printf 'The referee will stop the next one. Play it, then /blackbox puts the tape on the board.\n'
    elif [ -z "$LAST" ]; then
      printf '\nFlight meter: no tape of yours on the board yet - %s landings before one is asked for (GR14).\n' \
        "$((PER - SINCE))"
    else
      printf '\nFlight meter: %s of %s landings used since your last tape (%s).\n' "$SINCE" "$PER" "$LAST"
    fi
  fi

  # Said after the brief rather than before it, because it is housekeeping and
  # not news - and said at all, because a tool that quietly moves somebody's
  # branch without ever mentioning it is worse than the errand it saves.
  if [ -n "$CREW" ]; then
    printf '\nThe ground crew, on the way in:\n%s\n' "$CREW"
  fi

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
