#!/bin/sh
# ---------------------------------------------------------------------------
# badges.sh - the numbers on the front page, read rather than typed.
#
# The README opens with a strip of badges: how many pilots are in here, how
# many events are armed, how many versions have landed, how many flights are
# taped. Every one of those is something the history already knows, and a
# number somebody types is a number that starts lying on the next commit. That
# is the argument the ledger rests on (GR12); this is the same argument one
# screen earlier, where a stranger reads it first and checks it hardest.
#
# So nobody edits these, including whoever is asked to. This paints them, from
# the places that already answer: tools/chronicle.sh for the versions and the
# roster, src/events/ for the arsenal, docs/RANKINGS.md for the tapes,
# GOLDEN_RULES.md for the rules, LICENSE for the licence.
#
#   tools/badges.sh            repaint the strip into media/badges/
#   tools/badges.sh --check    say what would change, write nothing
#   tools/badges.sh --list     every path this tool owns, one per line
#
# A badge is only written when what it renders to differs from what is already
# on disk, so a run that changes nothing touches nothing and says so. The
# post-commit hook runs it the way it runs the book and the ledger: into the
# working tree, to ride along with whatever lands next.
#
# The SVG is written here rather than fetched from a badge service, for the
# reason everything else in this repository is (GR2): the cabinet plays on a
# plane, and so does its front page. The colours are the cabinet's own, out of
# styles/tokens.css, so a badge is the colour the thing it counts is
# everywhere else.
#
# And the strip has a second half, which for a long time nothing looked at. The
# README writes each badge as  ![pilots: 3](media/badges/pilots.svg)  and the
# number in that alt text is typed by a person - the exact thing the paragraph
# at the top says nobody does. It went stale and nothing noticed, because the
# picture underneath it was right: the SVGs said 3, 8, 44 and 12 while the alt
# text still said 1, 6, 32 and 3. A reader with images off, a screen reader and
# github's own search index all read the alt text instead of the picture, so
# for every one of them the front page had been lying for months.
#
# The tool owns both halves now. It rewrites the value between the colon and
# the bracket and touches nothing else on the line, which is what lets the
# strip sit in a README everybody else is free to rewrite around it.
# ---------------------------------------------------------------------------
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  printf 'badges: not a git repo\n' >&2; exit 1; }
cd "$ROOT" || exit 1

OUT=media/badges
README=README.md
MODE=${1:-write}

WORK=$(mktemp -d 2>/dev/null) || { printf 'badges: no temp directory\n' >&2; exit 1; }
trap 'rm -rf "$WORK"' EXIT INT TERM

# --- what the numbers are ---------------------------------------------------
#
# Each of these asks somebody else. None of them counts anything itself, which
# is why two of them are one line: the question has a home and this is not it.

count() { grep -c . 2>/dev/null || true; }

versions() { sh tools/chronicle.sh --versions 2>/dev/null | count; }
pilots()   { sh tools/chronicle.sh --pilots   2>/dev/null | count; }

# Ambushes, not files. A pilot's file holds as many events as they felt like
# writing, and the badge answers what a stranger is actually asking - how many
# things in here are waiting for them. The house counts: its events fire for
# everybody, author included, which is more than can be said for anyone's.
events() {
  grep -h '^ *id: "' src/events/*.js 2>/dev/null | count
}

# One sealed tape, one line in the log, one checksum comment underneath it.
# The comment is what the flight meter reads, so it is what this counts.
flights() { grep -c '^<!-- crc ' docs/RANKINGS.md 2>/dev/null || printf '0\n'; }

rules()   { grep -c '^## GR' GOLDEN_RULES.md 2>/dev/null || printf '0\n'; }
licence() { head -1 LICENSE 2>/dev/null | awk '{print $1}'; }

# The strip itself, once: name, label, value, colour. Written to a file rather
# than answered twice, because both halves below read it and every one of those
# values costs a walk of the history - a second reading of this table would be
# a second walk for the same six numbers.
table() {
  printf '%s\t%s\t%s\t%s\n' \
    pilots   "pilots"       "$(pilots)"        "#ff3ec8" \
    events   "events armed" "$(events)"        "#b6ff3d" \
    versions "versions"     "$(versions)"      "#ffb020" \
    flights  "flights"      "$(flights) taped" "#a04bff" \
    rules    "golden rules" "$(rules)"         "#3dffb0" \
    licence  "licence"      "$(licence)"       "#9a86bd"
}

# --- the badge --------------------------------------------------------------
#
# Flat, two boxes, no gradient and no rounding: the shape everybody already
# reads as a badge. 11px Verdana runs about 6.6px a character and textLength
# pins each half either way, so the box is the right width whatever font the
# reader turns out to have.

svg() {
  label=$1 value=$2 fill=$3
  lt=$(awk -v n="${#label}" 'BEGIN { printf "%d", n * 6.6 }')
  vt=$(awk -v n="${#value}" 'BEGIN { printf "%d", n * 6.6 }')
  lw=$((lt + 20)); vw=$((vt + 20)); w=$((lw + vw)); vx=$((lw + 10))
  cat <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="$w" height="20" role="img" aria-label="$label: $value">
  <title>$label: $value</title>
  <rect width="$lw" height="20" fill="#07030f"/>
  <rect x="$lw" width="$vw" height="20" fill="$fill"/>
  <g font-family="Verdana,DejaVu Sans,sans-serif" font-size="11">
    <text x="10" y="14" fill="#9a86bd" textLength="$lt">$label</text>
    <text x="$vx" y="14" fill="#07030f" font-weight="bold" textLength="$vt">$value</text>
  </g>
</svg>
EOF
}

CHANGED=0

badge() {
  file=$OUT/$1.svg
  new=$(svg "$2" "$3" "$4")
  old=$(cat "$file" 2>/dev/null)
  [ "$new" = "$old" ] && return 0
  CHANGED=$((CHANGED + 1))
  case $MODE in
    --check) printf 'would write %s\n' "$file" ;;
    *)       mkdir -p "$OUT"; printf '%s\n' "$new" > "$file"; printf 'wrote %s\n' "$file" ;;
  esac
}

# --- the other half: the alt text -------------------------------------------
#
# One pass over the README, rewriting every  ![<label>: <value>](media/badges/
# <name>.svg)  reference to the label and the value this run just painted.
# Anchored on the image path rather than on the alt text, because the alt text
# is precisely the part that cannot be trusted to say anything in particular -
# it is the half that went wrong. A reference to a badge this tool does not
# paint is left exactly as it was, and so is every other character of the line.
#
# The report names both sides rather than only saying that something moved,
# because the whole failure was that nobody could see the two disagreeing.
alt_text() {
  [ -f "$README" ] || return 0
  awk -v OUTF="$WORK/readme" -F'\t' '
    NR == FNR { lab[$1] = $2; val[$1] = $3; next }
    {
      out = ""; rest = $0
      while (match(rest, /!\[[^]]*\]\(media\/badges\/[a-z]+\.svg\)/)) {
        ref = substr(rest, RSTART, RLENGTH)
        out = out substr(rest, 1, RSTART - 1)
        rest = substr(rest, RSTART + RLENGTH)
        nm = ref; sub(/^.*\/badges\//, "", nm); sub(/\.svg\)$/, "", nm)
        if (nm in lab) {
          want = "![" lab[nm] ": " val[nm] "](media/badges/" nm ".svg)"
          if (ref != want) print "  " ref "  ->  " want
          ref = want
        }
        out = out ref
      }
      print out rest > OUTF
    }' "$1" "$README" > "$WORK/said"

  cmp -s "$README" "$WORK/readme" && return 0
  CHANGED=$((CHANGED + 1))
  case $MODE in
    --check) printf 'would write %s\n' "$README" ;;
    *)       cat "$WORK/readme" > "$README"; printf 'wrote %s\n' "$README" ;;
  esac
  cat "$WORK/said"
}

strip() {
  table > "$WORK/table"
  while IFS='	' read -r n l v c; do
    [ -n "$n" ] || continue
    badge "$n" "$l" "$v" "$c"
  done < "$WORK/table"
  alt_text "$WORK/table"
}

case $MODE in
  -h|--help)
    sed -n '2,43p' "$0" | sed 's/^# \{0,1\}//'
    ;;
  --list)
    # The six files this tool writes whole. The README is not one of them: it
    # owns six substrings of somebody else's front page, which is a different
    # relationship and not one a list of paths can say.
    for n in pilots events versions flights rules licence; do printf '%s/%s.svg\n' "$OUT" "$n"; done
    ;;
  --check|write)
    strip
    # Quiet when there was nothing to do, and a zero either way: a strip that
    # is already true is not a failure, and the hook that runs this reads the
    # status rather than the prose.
    if [ "$CHANGED" -eq 0 ]; then printf 'badges: the strip already says what is true.\n'; fi
    ;;
  *)
    printf 'badges: unknown option %s\n' "$MODE" >&2; exit 2
    ;;
esac
