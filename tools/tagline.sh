#!/bin/sh
# ---------------------------------------------------------------------------
# tagline.sh - one line per version, saying what happened to the game.
#
# A version number tells you how far down the history you are standing. It does
# not tell you what you are about to fly into. The tagline does, in one dry
# sentence, and it is written the moment the version lands so that nobody has
# to reconstruct it from a diff six months later.
#
#   tools/tagline.sh                  what the staged change would be called
#   tools/tagline.sh <rev>            the tagline of a version
#   tools/tagline.sh --record <rev>   keep it, if it is not kept already
#   tools/tagline.sh --backfill       keep one for every version that lacks one
#   tools/tagline.sh --list           the whole record, oldest first
#
# Where a line comes from, first one wins:
#
#   1. docs/taglines.tsv, if this version already has one. Written once and
#      never rewritten - that is what persisting means, and it is why you can
#      open the file and put a better line in by hand. Yours stays.
#   2. a  Tagline: <line>  trailer in the commit message. The pilot's own
#      words always beat the machine's.
#   3. this script, reading what the commit did to the game.
#
# The generator is deterministic: same change, same parent, same pilot, same
# line. It has to be, because the hook shows you the line in the commit
# template before the commit exists, and it would be a poor joke if the version
# then landed under a different one.
#
# Nothing here reaches the network and nothing here needs installing - GR2
# applies to the referee as much as to the game. The jokes are therefore made
# of sh, awk and a checksum, which is its own kind of funny.
# ---------------------------------------------------------------------------
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$ROOT" || exit 0

FILE=docs/taglines.tsv

# One definition of what the game is, and it lives in chronicle.sh, because
# that is the script that decides what counts as a version.
GAME=$(sh tools/chronicle.sh --game-paths 2>/dev/null | tr '\n' ' ')
[ -n "$GAME" ] || GAME='index.html src styles'

# --- the record -------------------------------------------------------------

lookup() {
  [ -f "$FILE" ] || return 1
  awk -F'\t' -v h="$1" '$1 == h { print $2; found = 1; exit } END { exit !found }' "$FILE"
}

ensure_file() {
  [ -f "$FILE" ] && return 0
  mkdir -p docs
  cat > "$FILE" <<'HEAD'
# THE TAGLINES
#
# One line per version of ASTEROIDS // HYPERCOLOR, saying what happened to the
# game. Appended by tools/tagline.sh when a version lands, read by
# tools/chronicle.sh into the book, and never rewritten: once a line is in
# here it is the record, even after the script that first wrote it changes its
# mind about jokes.
#
# Which is the invitation. If the machine gave your version a limp line, edit
# it here and it stays edited. If you would rather not leave it to chance, put
# a  Tagline: <line>  in the commit message and that is what lands.
#
# <commit>	<what happened to the game>
HEAD
}

# The line as it is written into the commit message by a pilot who did not want
# to leave it to the machine. Indented continuations belong to the trailer, the
# same way they do everywhere else in this project.
from_message() {
  git log -1 --format='%B' "$1" 2>/dev/null | awk '
    tolower($0) ~ /^[[:space:]]*tagline:/ {
      sub(/^[^:]*:[[:space:]]*/, ""); line = $0; mode = 1; next }
    mode && /^[[:space:]]+[^[:space:]]/ {
      sub(/^[[:space:]]+/, ""); line = line " " $0; next }
    { mode = 0 }
    END { if (line != "") print line }'
}

# --- what the change was ----------------------------------------------------

# Everything the generator gets to know, gathered the same way whether the
# commit exists yet or not, so the preview and the real thing agree.
survey() {
  if [ -n "${1:-}" ]; then
    STAT=$(git diff-tree --root -r --numstat --no-renames --no-commit-id "$1" -- $GAME 2>/dev/null)
    NEW=$(git diff-tree --root -r --name-only --no-renames --no-commit-id \
          --diff-filter=A "$1" -- $GAME 2>/dev/null)
    PARENT=$(git rev-parse "$1^" 2>/dev/null || printf 'the beginning')
    WHO=$(git log -1 --format='%an' "$1" 2>/dev/null)
    [ -n "$STAT" ]
    return
  fi

  PARENT=$(git rev-parse HEAD 2>/dev/null || printf 'the beginning')
  WHO=$(git config user.name 2>/dev/null || printf 'somebody')

  if [ -n "$(git diff --cached --name-only HEAD 2>/dev/null)" ]; then
    # Something is staged, so that is the commit being asked about - which is
    # the case inside the hooks, and the reason the line shown in the commit
    # template is the line that lands.
    STAT=$(git diff --cached --numstat --no-renames HEAD -- $GAME 2>/dev/null)
    NEW=$(git diff --cached --name-only --no-renames --diff-filter=A HEAD -- $GAME 2>/dev/null)
    [ -n "$STAT" ]
    return
  fi

  # Nobody is committing; a pilot is asking mid-flight. A feature that is still
  # a brand new file is a file git has never heard of, so it has to be counted
  # by hand or the answer is always "nothing happened".
  STAT=$(git diff --numstat --no-renames HEAD -- $GAME 2>/dev/null)
  NEW=$(git diff --name-only --no-renames --diff-filter=A HEAD -- $GAME 2>/dev/null)
  UNTRACKED=$(git ls-files --others --exclude-standard -- $GAME 2>/dev/null)
  for f in $UNTRACKED; do
    [ -f "$f" ] || continue
    STAT=$(printf '%s\n%s\t0\t%s' "$STAT" "$(wc -l < "$f" | tr -d ' ')" "$f")
    NEW=$(printf '%s\n%s' "$NEW" "$f")
  done
  STAT=$(printf '%s\n' "$STAT" | grep -v '^[[:space:]]*$' || true)
  NEW=$(printf '%s\n' "$NEW" | grep -v '^[[:space:]]*$' || true)
  [ -n "$STAT" ]
}

generate() {
  survey "${1:-}" || return 1

  # Deterministic, and identical for the preview and the commit: the parent is
  # HEAD either way, and so is everything else that goes in here.
  SEED=$(printf '%s\n%s\n%s\n' "$PARENT" "$WHO" "$STAT" | cksum | awk '{ print $1 }')

  # The list of new files goes through the environment rather than -v, which
  # cannot carry a newline and fails the whole tagline when a commit adds more
  # than one file - which is most of them.
  printf '%s\n' "$STAT" | NEWFILES="$NEW" awk -v seed="$SEED" '
function add(k, s) { count[k]++; pool[k, count[k]] = s }
function pick(k, s,   n) { n = count[k]; return n ? pool[k, (s % n) + 1] : "" }

# Where in the cabinet a path lives. The vocabulary the taglines are written in
# is this list, so a new area of the game wants a line here and a pool below.
function area(p) {
  if (p ~ /^src\/events\//)   return "events"
  if (p ~ /^src\/entities\//) return "entities"
  if (p ~ /^src\/audio\//)    return "audio"
  if (p ~ /^src\/render\//)   return "look"
  if (p ~ /^styles\//)        return "look"
  if (p ~ /^src\/ui\//)       return "ui"
  if (p ~ /^src\/input\//)    return "input"
  if (p == "src/game/difficulty.js" || p == "src/game/waves.js") return "harder"
  if (p ~ /^src\/game\//)     return "rules"
  return "machine"
}

BEGIN {
  # A trap that was not there this morning.
  add("trap", "Somebody laid a trap and walked away whistling.")
  add("trap", "A new ambush went into the waves, armed against everybody except the pilot who wrote it.")
  add("trap", "There is something waiting in the field now, and it knows whose seat you are in.")
  add("trap", "A trap was set by somebody who will never meet it.")
  add("trap", "The field acquired a grudge, and the grudge has a name on it.")
  add("trap", "Somebody spent an evening arranging for yours to go worse.")

  # A trap that was already out there, tightened.
  add("events", "An old ambush was taken apart and put back meaner.")
  add("events", "Somebody went back to their trap and tightened it.")
  add("events", "A trap that was already out there got a second thought.")
  add("events", "The ambush was retuned by the one pilot it will never fire at.")
  add("events", "Somebody adjusted a trap they are personally immune to.")
  add("events", "An existing grudge was brought up to date.")

  # Something in the field that was not in the field before.
  add("arrival", "Something new is out there, and nobody announced it.")
  add("arrival", "The field gained an occupant. It did not ask first.")
  add("arrival", "There is one more thing in the dark than there was yesterday.")
  add("arrival", "A new shape joined the rocks and declined to introduce itself.")
  add("arrival", "Something else out there now moves on its own schedule.")
  add("arrival", "The cabinet grew another moving part with opinions.")

  add("entities", "The residents of the field were quietly rearranged.")
  add("entities", "Something out there behaves differently now and will not say so.")
  add("entities", "The rocks were given notes on their performance.")
  add("entities", "An existing menace came back from revisions.")
  add("entities", "The things in the dark were issued new instructions.")
  add("entities", "Somebody adjusted what was already out there, and it noticed.")

  add("harder", "It got harder. It was always going to get harder.")
  add("harder", "The waves were renegotiated, and not in the player'"'"'s favour.")
  add("harder", "Somebody moved the difficulty and did not say which way.")
  add("harder", "The schedule of unpleasant things was revised.")
  add("harder", "The curve got steeper somewhere on the way up.")
  add("harder", "The field is less patient than it was this morning.")

  add("rules", "The rules of the field changed while nobody was flying.")
  add("rules", "Somebody rewrote a rule the game had been taking for granted.")
  add("rules", "The bookkeeping of the cabinet moved a foot to the left.")
  add("rules", "What counts as fair was quietly re-argued.")
  add("rules", "A rule was taken out, looked at, and put back differently.")
  add("rules", "The cabinet keeps score with slightly different arithmetic now.")

  add("audio", "The cabinet learned a new noise.")
  add("audio", "Something in the score was retuned, audibly.")
  add("audio", "The song went away and came back with ideas.")
  add("audio", "The speakers have something to add.")
  add("audio", "The soundtrack picked up a habit.")
  add("audio", "A new noise arrived, and it is not optional.")

  add("look", "The spectrum drifted somewhere else.")
  add("look", "The phosphor is a different colour of wrong now.")
  add("look", "The cabinet was repainted while it was still switched on.")
  add("look", "Everything looks slightly more like itself.")
  add("look", "The glow was adjusted by somebody with opinions about glow.")
  add("look", "The picture changed. The game denies that it did.")

  add("ui", "The panels say something different now.")
  add("ui", "The instrument panel developed an opinion.")
  add("ui", "Somebody rewrote what the cabinet tells you.")
  add("ui", "The screen mentions something it used to keep to itself.")
  add("ui", "The furniture on the glass was moved.")
  add("ui", "The HUD is more forthcoming than it used to be.")

  add("input", "The controls answer to something new.")
  add("input", "A key that did nothing now does something.")
  add("input", "Both seats were handed another verb.")
  add("input", "The stick learned a trick.")
  add("input", "Somebody taught the keyboard a new word.")
  add("input", "There is one more thing your hands can do.")

  add("machine", "Somebody went in under the hood and closed it again.")
  add("machine", "The machinery moved. The game denies everything.")
  add("machine", "Deep maintenance, carried out with the coin still in the slot.")
  add("machine", "The plumbing was rerouted and nothing caught fire.")
  add("machine", "Somebody adjusted the parts nobody is meant to notice.")
  add("machine", "The engine was opened, poked, and shut.")

  add("jettison", "Lines went out of the airlock and did not come back.")
  add("jettison", "The cabinet weighs less than it did.")
  add("jettison", "Something was taken out, and nobody has missed it yet.")
  add("jettison", "A quantity of code was jettisoned, on purpose.")
  add("jettison", "There is less of it, and it is better for that.")
  add("jettison", "Somebody removed more than they added, and meant to.")

  # The second thing that happened, when two things happened.
  add("also_events", "There is a trap in it as well.")
  add("also_events", "An ambush came along with it.")
  add("also_events", "It arrived with a grudge attached.")
  add("also_entities", "Something new came with it.")
  add("also_entities", "It brought company.")
  add("also_entities", "There is a new shape in it too.")
  add("also_harder", "It also got harder.")
  add("also_harder", "The difficulty came along for the ride.")
  add("also_harder", "It is meaner as well.")
  add("also_rules", "The rules moved with it.")
  add("also_rules", "A rule shifted as well.")
  add("also_rules", "The bookkeeping followed.")
  add("also_audio", "It is louder, too.")
  add("also_audio", "The noise changed as well.")
  add("also_audio", "The score came with it.")
  add("also_look", "It looks different, too.")
  add("also_look", "The colours moved as well.")
  add("also_look", "The picture followed.")
  add("also_ui", "The panels caught up.")
  add("also_ui", "The HUD says so, too.")
  add("also_ui", "The screen was told as well.")
  add("also_input", "The controls moved with it.")
  add("also_input", "Your hands are involved as well.")
  add("also_input", "The keys changed too.")
  add("also_machine", "The machinery moved with it.")
  add("also_machine", "Something under the hood came along.")
  add("also_machine", "The plumbing followed.")

  # Ties go to whatever is most interesting to fly into.
  order = "events entities harder rules audio look ui input machine"
  n = split(order, rank, " ")
  for (i = 1; i <= n; i++) prio[rank[i]] = n - i

  m = split(ENVIRON["NEWFILES"], f, "\n")
  for (i = 1; i <= m; i++) if (f[i] != "") fresh[area(f[i])]++
}

# added, removed, path. Binary files come through as dashes and weigh nothing.
$0 ~ /^(-|[0-9]+)\t(-|[0-9]+)\t./ {
  a = ($1 == "-") ? 0 : $1
  d = ($2 == "-") ? 0 : $2
  k = area($3)
  weight[k] += a + d
  totadd += a
  totdel += d
}

END {
  if (totadd + totdel == 0 && length(weight) == 0) exit 1

  for (k in weight) {
    if (weight[k] > best || (weight[k] == best && prio[k] > prio[bestk])) {
      second = best; secondk = bestk
      best = weight[k]; bestk = k
    } else if (weight[k] > second) {
      second = weight[k]; secondk = k
    }
  }

  # What the pilot will notice first, in the order they would notice it: a new
  # trap, then a new thing in the field, then a commit that mostly took things
  # away, then whatever moved most.
  if (fresh["events"])        primary = "trap"
  else if (fresh["entities"]) primary = "arrival"
  else if (totdel > 2 * totadd && totdel > 40) primary = "jettison"
  else                        primary = (bestk == "") ? "machine" : bestk

  line = pick(primary, seed)

  # A second area, but only if it is a real second area and not the rounding
  # error left over from the first.
  if (secondk != "" && second >= 5 && secondk != bestk && secondk != primary) {
    also = pick("also_" secondk, int(seed / 7))
    if (also != "") line = line " " also
  }

  print line
}'
}

# --- what the pilot asked for -----------------------------------------------

record() {
  h=$(git rev-parse --verify -q "$1") || return 1
  sh tools/chronicle.sh --moved "$h" || return 1     # no version, no tagline
  existing=$(lookup "$h") && [ -n "$existing" ] && { printf '%s\n' "$existing"; return 0; }
  t=$(from_message "$h")
  [ -n "$t" ] || t=$(generate "$h") || return 1
  [ -n "$t" ] || return 1
  ensure_file
  printf '%s\t%s\n' "$h" "$t" >> "$FILE"
  printf '%s\n' "$t"
}

case "${1:-}" in
  --record)
    [ -n "${2:-}" ] || { echo "tagline: --record needs a commit" >&2; exit 2; }
    record "$2" ;;

  --backfill)
    # Oldest first, so the file reads in the order the versions happened. This
    # is what makes the whole thing survive a clone that never installed the
    # hooks: whatever was missed is written the next time anybody rebuilds.
    written=0
    PENDING=$(mktemp) || exit 0
    trap 'rm -f "$PENDING"' EXIT INT TERM
    git rev-list --full-history --no-merges --reverse HEAD -- $GAME 2>/dev/null > "$PENDING"
    while IFS= read -r h; do
      [ -n "$h" ] || continue
      lookup "$h" >/dev/null 2>&1 && continue
      record "$h" >/dev/null 2>&1 && written=$((written + 1))
    done < "$PENDING"
    [ "$written" -gt 0 ] && printf 'taglines: %s written\n' "$written"
    exit 0 ;;

  --list)
    [ -f "$FILE" ] || { echo "nothing kept yet" >&2; exit 0; }
    awk -F'\t' 'NF >= 2 && $1 !~ /^#/ { printf "  %s  %s\n", substr($1, 1, 8), $2 }' "$FILE" ;;

  -h|--help)
    sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//' ;;

  '')
    generate ;;

  -*)
    printf 'tagline: unknown option %s\n' "$1" >&2; exit 2 ;;

  *)
    h=$(git rev-parse --verify -q "$1") || { printf 'tagline: no such version: %s\n' "$1" >&2; exit 2; }
    lookup "$h" && exit 0
    t=$(from_message "$h")
    [ -n "$t" ] && { printf '%s\n' "$t"; exit 0; }
    generate "$h" ;;
esac
