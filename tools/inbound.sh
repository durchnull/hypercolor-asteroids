#!/bin/sh
# ---------------------------------------------------------------------------
# inbound.sh - what the room sees when work arrives from somewhere else.
#
# The hooks referee a pilot who is present. Work that arrives as a pull request
# comes from a clone that may never have installed them, so nothing has been
# refereed at all until somebody does it here. This reads a range the way the
# room would: one commit at a time, each judged as its own author, and prints
# what it found in a shape a person can skim.
#
#   tools/inbound.sh                 this branch against main
#   tools/inbound.sh A..B            an explicit range
#   tools/inbound.sh --markdown A..B the same, for a pull request summary
#
# Exit 0 = nothing a rule would have stopped. Exit 1 = something would have
# been refused at commit time, and landed anyway because nobody was checking.
#
# It is deliberately not the last word. A red line is a red line and this says
# so, but the budgets, the nudges and the whole of GR8 are for the people
# reading, which is the only place they have ever lived. The point of printing
# it is that nobody has to read the diff to find out what happened - GR9 has
# opinions about reading the diff.
#
# No dependencies, like everything else in tools/ (GR2): sh, git, sed and awk.
# ---------------------------------------------------------------------------
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  printf 'inbound: not a git repo\n' >&2; exit 1; }
cd "$ROOT" || exit 1

MD=0
RANGE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --markdown) MD=1 ;;
    -h|--help)  sed -n '2,23p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)         printf 'inbound: unknown option %s\n' "$1" >&2; exit 2 ;;
    *)          RANGE="$1" ;;
  esac
  shift
done

if [ -z "$RANGE" ]; then
  base=$(git merge-base main HEAD 2>/dev/null) || {
    printf 'inbound: no main to compare against - give me a range\n' >&2; exit 2; }
  RANGE="$base..HEAD"
fi

REVS=$(git rev-list --reverse --no-merges "$RANGE" 2>/dev/null) || {
  printf 'inbound: %s is not a range git knows\n' "$RANGE" >&2; exit 2; }

TMP=$(mktemp -d) || exit 1
trap 'rm -rf "$TMP"' EXIT INT TERM

if [ -z "$REVS" ]; then
  printf 'nothing to referee in %s.\n' "$RANGE"
  exit 0
fi

# --- printing ----------------------------------------------------------------
#
# One writer, two shapes. Markdown goes in a pull request summary where nobody
# has a terminal; plain goes to whoever ran this before pushing.

h1() { if [ "$MD" = 1 ]; then printf '## %s\n\n' "$1"; else printf '\n  %s\n\n' "$1"; fi; }
p()  { if [ "$MD" = 1 ]; then printf '%s\n\n' "$1"; else printf '  %s\n\n' "$1"; fi; }
li() { if [ "$MD" = 1 ]; then printf -- '- %s\n' "$1"; else printf '    - %s\n' "$1"; fi; }
pre() {
  if [ "$MD" = 1 ]; then printf '```\n'; cat "$1"; printf '```\n\n'
  else sed 's/^/    /' "$1"; printf '\n'; fi
}
endli() { [ "$MD" = 1 ] && printf '\n'; return 0; }

# --- the referee, once per commit ---------------------------------------------

BLOCKED=0
: > "$TMP/rows"
: > "$TMP/loud"

for r in $REVS; do
  sha=$(git log -1 --format='%h' "$r")
  who=$(git log -1 --format='%an' "$r")
  sub=$(git log -1 --format='%s' "$r")

  sh tools/golden-check.sh --rev "$r" > "$TMP/say" 2>&1
  code=$?

  if [ "$code" != 0 ]; then
    verdict='REFUSED'; BLOCKED=1
    { printf '\n%s  %s\n%s\n' "$sha" "$sub" "$who"; cat "$TMP/say"; } >> "$TMP/loud"
  elif grep -q '^ ? ' "$TMP/say" 2>/dev/null; then
    verdict='nudged'
    { printf '\n%s  %s\n%s\n' "$sha" "$sub" "$who"; cat "$TMP/say"; } >> "$TMP/loud"
  else
    verdict='clear'
  fi

  printf '%s\t%s\t%s\t%s\n' "$sha" "$who" "$verdict" "$sub" >> "$TMP/rows"
done

# --- what it says -------------------------------------------------------------

n=$(wc -l < "$TMP/rows" | tr -d ' ')
pilots=$(awk -F'\t' '{ print $2 }' "$TMP/rows" | sort -u | paste -sd, - | sed 's/,/, /g')

h1 "The referee, after the fact"
p "$n commit(s) from $pilots, each read as its own author against its own message."

if [ "$MD" = 1 ]; then
  printf '| commit | pilot | subject | verdict |\n|---|---|---|---|\n'
  awk -F'\t' '{ printf "| `%s` | %s | %s | %s |\n", $1, $2, $4, $3 }' "$TMP/rows"
  printf '\n'
else
  awk -F'\t' '{ printf "    %-9s %-18s %-9s %s\n", $1, $2, $3, $4 }' "$TMP/rows"
  printf '\n'
fi

# --- what it spent ------------------------------------------------------------
#
# Budgets are not failures and this does not treat them as any. They are the
# thing GR12 exists to make impossible to do quietly, so they get printed where
# the room reads rather than buried in a log nobody opens.

: > "$TMP/spent"
for r in $REVS; do
  who=$(git log -1 --format='%an' "$r")
  git log -1 --format='%B' "$r" \
    | sed -n -e 's/^[[:space:]]*[Gg]olden-[Rr]ule-[Oo]verride:[[:space:]]*/override · /p' \
             -e 's/^[[:space:]]*[Rr]ule-[Cc]hange:[[:space:]]*/rule change · /p' \
             -e 's/^[[:space:]]*[Gg]olden-[Rr]ule-[Bb]reach:[[:space:]]*/breach · /p' \
    | while IFS= read -r line; do printf '%s (%s)\n' "$line" "$who"; done >> "$TMP/spent"
done

if [ -s "$TMP/spent" ]; then
  h1 "What it spent, in the open"
  while IFS= read -r line; do li "$line"; done < "$TMP/spent"
  endli
  p "Every override costs one on the tally (GR12). That is the price and it is the whole price - nothing here is undone, and the number is a difficulty setting rather than a scolding."
fi

# --- the meter ----------------------------------------------------------------

if [ -f tools/flights.sh ]; then
  per=$(sh tools/flights.sh --per 2>/dev/null) || per=3
  : > "$TMP/meter"
  awk -F'\t' '{ print $2 }' "$TMP/rows" | sort -u | while IFS= read -r who; do
    # What counts as a version is tools/chronicle.sh's question, and this asks
    # it one commit at a time rather than keeping a path list of its own. It
    # also gets the root commit right, which a diff against r^ does not.
    landed=0
    for r in $REVS; do
      [ "$(git log -1 --format='%an' "$r")" = "$who" ] || continue
      sh tools/chronicle.sh --moved "$r" 2>/dev/null && landed=$((landed + 1))
    done
    [ "$landed" = 0 ] && continue
    m=$(sh tools/flights.sh --count "$who" 2>/dev/null) || m=0
    printf '%s\t%s\t%s\n' "$who" "$landed" "$m" >> "$TMP/meter"
  done

  if [ -s "$TMP/meter" ]; then
    h1 "The meter (GR14)"
    while IFS="$(printf '\t')" read -r who landed m; do
      li "$who lands $landed version(s) here, and the board says $m since they last flew - one tape buys $per."
    done < "$TMP/meter"
    endli
    p "A sealed tape on docs/RANKINGS.md is the only evidence this project takes that anybody played anything. Paste yours and /blackbox puts it on the board."
  fi
fi

# --- the detail ---------------------------------------------------------------

if [ -s "$TMP/loud" ]; then
  h1 "What the referee actually said"
  pre "$TMP/loud"
fi

if [ "$BLOCKED" = 1 ]; then
  p "At least one of those would have been refused at commit time. That is not a merge button being taken away - it is the room being told, which is the only enforcement this project has ever had (GR12)."
  exit 1
fi

p "Nothing here would have been refused at commit time."
exit 0
