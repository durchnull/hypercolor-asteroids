#!/bin/sh
# ---------------------------------------------------------------------------
# chronicle-art.sh - one painted plate per version, and only ever one.
#
# Every chapter in the book already has a picture: tools/chronicle.sh draws the
# commit itself, a rock per sector, seeded off the hash. That one is arithmetic
# and it comes back identical on every machine forever.
#
# This is the other kind. A model is handed the version's tagline and asked to
# paint the scene, once, and the result is kept in docs/art/ and committed like
# any other plate in a book. It is not redrawn on the next rebuild, it is not
# redrawn on the next clone, and nobody has to have credentials for the book to
# build - a version with no plate simply has no plate, and the drawn picture
# carries the chapter as it always did.
#
# Idempotence is the whole design and it is on disk, not in a cache:
#
#   docs/art/<sha8>.jpg    the plate, named for the commit it belongs to
#   docs/art/index.tsv     sha, file, alt text - append-only, like the taglines
#
# A commit is asked for exactly once, ever. Once its line is in the manifest and
# the file it names is on disk, this script has nothing left to do for it. That
# is also why the file is named for the commit rather than for the version: a
# version number is counted off the history and could in principle shift, a
# commit hash is the commit.
#
# About the network, which is the one thing this project does not do. GR2 says
# the cabinet plays on a plane, and it still does: nothing here runs in the
# game, nothing here runs in a browser, and the plates are ordinary files in the
# repository by the time any reader sees them. This script runs on the machine
# of whoever is writing the book, needs credentials that only they have, and
# exits quietly and successfully when it has none. The book that ships has no
# idea any of this happened.
#
#   tools/chronicle-art.sh              plates for every version that lacks one
#   tools/chronicle-art.sh --auto       the same, capped - what a rebuild calls
#   tools/chronicle-art.sh --one <rev>  just that one
#   tools/chronicle-art.sh --force      paint again over what is already there
#   tools/chronicle-art.sh --check      say whether it is wired up, paint nothing
#   tools/chronicle-art.sh --list       what has been painted so far
#   tools/chronicle-art.sh --prune      forget manifest lines whose file is gone
#
# Credentials live in .env at the top of the repository, which is not committed
# and must never be. Anything already in the environment wins over the file:
#
#   CLOUDFLARE_ACCOUNT_ID=...
#   CLOUDFLARE_API_TOKEN=cfat_...
#
# CF_ACCOUNT_ID and CF_API_TOKEN are read too, for whoever named them that way.
# The token needs one permission, Account > Workers AI > Read, and the model is
# on Cloudflare's free daily allocation - a version costs a fraction of a day's
# worth, and the script only ever asks once per version anyway.
#
# Knobs, all optional, all environment:
#
#   ASTEROIDS_ART_MODEL   default @cf/black-forest-labs/flux-1-schnell
#   ASTEROIDS_ART_MAX     plates per --auto run, default 3
#   ASTEROIDS_ART_STYLE   replaces the house style in front of the tagline
#   ASTEROIDS_NO_ART=1    do nothing at all, for a rebuild that should be quick
# ---------------------------------------------------------------------------
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$ROOT" || exit 0

# The same definition tools/chronicle.sh keeps, asked for rather than copied,
# so a plate is painted for exactly the commits that get a chapter.
GAME=$(sh tools/chronicle.sh --game-paths 2>/dev/null | tr '\n' ' ')
[ -n "$GAME" ] || GAME='index.html src styles'

DIR=docs/art
MANIFEST=$DIR/index.tsv
MODEL=${ASTEROIDS_ART_MODEL:-@cf/black-forest-labs/flux-1-schnell}
CAP=${ASTEROIDS_ART_MAX:-3}
# Overridable so that the whole path from request to committed plate can be run
# against a file:// fixture on a machine with no credentials and no network,
# which is how the parsing in here gets tested at all.
API=${ASTEROIDS_ART_API:-https://api.cloudflare.com/client/v4}

# What the plate looks like, and it is the same sentence for every version so
# that a run of chapters reads as one book rather than a folder of pictures.
# The field, not the cabinet: ask a model for arcade cabinet art and it paints
# a cabinet with a marquee, and a marquee is lettering. Which is the other half
# of this - a model asked for a word paints something word-shaped and spells it
# wrong, so the plate is told at some length that there are no words in it.
STYLE=${ASTEROIDS_ART_STYLE:-'A scene in deep black space drawn as thin glowing vector lines, in the style of a 1980s vector arcade screen: luminous magenta, cyan, violet and amber wireframe outlines, heavy phosphor bloom, drifting jagged asteroid polygons, faint horizontal scanlines. No text anywhere in the image, no letters, no words, no numbers, no captions, no signage, no logo, no watermark, no user interface, no frame, no border.'}

US=$(printf '\037')

say()  { printf 'chronicle-art: %s\n' "$1" >&2; }
quit() { say "$1"; exit 0; }

# --- the .env file ----------------------------------------------------------
# Read one key, without sourcing anything. A .env is somebody's private file and
# it is not a shell script; treating it as one is how a stray backtick in a
# secret ends up being executed.
env_get() {
  [ -f .env ] || return 1
  awk -v k="$1" '
    /^[[:space:]]*#/ { next }
    { line = $0
      sub(/^[[:space:]]*/, "", line)
      sub(/^export[[:space:]]+/, "", line) }
    index(line, k "=") == 1 {
      v = substr(line, length(k) + 2)
      sub(/\r$/, "", v)
      sub(/[[:space:]]+$/, "", v)
      if (length(v) > 1) {
        f = substr(v, 1, 1); l = substr(v, length(v), 1)
        if ((f == "\"" && l == "\"") || (f == "'\''" && l == "'\''"))
          v = substr(v, 2, length(v) - 2)
      }
      print v; exit
    }' .env
}

pick() {   # pick VAR ALT - first of the two that has a value, env before .env
  eval "v=\${$1:-}"
  [ -n "$v" ] || eval "v=\${$2:-}"
  [ -n "$v" ] || v=$(env_get "$1" 2>/dev/null || true)
  [ -n "$v" ] || v=$(env_get "$2" 2>/dev/null || true)
  printf '%s' "$v"
}

ACCOUNT=$(pick CLOUDFLARE_ACCOUNT_ID CF_ACCOUNT_ID)
TOKEN=$(pick CLOUDFLARE_API_TOKEN CF_API_TOKEN)

# --- base64, whichever one this machine has ---------------------------------
# Probed by making it do the job rather than by asking its version, because the
# flags differ between the BSD one and the GNU one and lying about it is free.
DECODER=''
find_decoder() {
  [ -n "$DECODER" ] && return 0
  for c in "base64 -d" "base64 -D" "base64 --decode" "openssl base64 -d -A"; do
    if [ "$(printf 'aGVsbG8=' | $c 2>/dev/null)" = "hello" ]; then
      DECODER=$c; return 0
    fi
  done
  return 1
}

# --- what kind of file did we just get --------------------------------------
sniff() {
  case $(od -An -tx1 -N4 "$1" 2>/dev/null | tr -d ' \n') in
    ffd8ff*)  printf 'jpg'  ;;
    89504e47) printf 'png'  ;;
    52494646) printf 'webp' ;;
    *)        printf ''     ;;
  esac
}

# --- the manifest -----------------------------------------------------------
manifest_file() {   # the plate kept for this sha, if any
  [ -f "$MANIFEST" ] || return 1
  awk -F'\t' -v s="$1" '$1 == s { print $2; found = 1; exit }
                        END { exit !found }' "$MANIFEST"
}

manifest_init() {
  mkdir -p "$DIR"
  [ -f "$MANIFEST" ] && return 0
  {
    printf '# THE PLATES\n#\n'
    printf '# One line per version that has a painted plate in docs/art/, written by\n'
    printf '# tools/chronicle-art.sh the one time it asked for that version and read by\n'
    printf '# tools/chronicle.sh into the chapter. Append-only: a line in here is what\n'
    printf '# stops the same commit ever being painted twice, so it is not rewritten and\n'
    printf '# it is not reordered. A version with no line simply has no plate.\n#\n'
    printf '# commit\tfile\talt text\n'
  } > "$MANIFEST"
}

# Tabs, newlines and the separators the book streams records with, all gone, so
# a line in here is always one line and always three fields.
clean() {
  printf '%s' "$1" | tr '\t\n\036\037' '    ' | sed -e 's/  */ /g' -e 's/^ //' -e 's/ $//'
}

# --- the prompt -------------------------------------------------------------
# The tagline is what the book shouts across the top of the chapter, so it is
# what the plate is of. Subject line if there is no tagline yet; the pilot and
# the version never go in, because a model asked to paint a name paints the
# letters and GR9 is not improved by a chapter with somebody's name spelled
# wrong across it in neon.
scene_of() {
  s=''
  [ -f docs/taglines.tsv ] && s=$(awk -F'\t' -v h="$1" '$1 == h { print $2; exit }' docs/taglines.tsv)
  [ -n "$s" ] || s=$(git log -1 --format='%s' "$1" 2>/dev/null)
  printf '%s' "$s"
}

json_escape() {
  awk 'BEGIN {
    s = ARGV[1]; ARGV[1] = ""
    gsub(/\\/, "\\\\", s)
    gsub(/"/, "\\\"", s)
    gsub(/\r/, " ", s)
    gsub(/\n/, " ", s)
    gsub(/\t/, " ", s)
    printf "%s", s
  }' "$1"
}

# A seed the commit decides, so asking twice for the same version - which only
# happens under --force - is asking the same question rather than a new one.
seed_of() {
  h=$(printf '%s' "$1" | cut -c1-7)
  printf '%d' "0x$h" 2>/dev/null || printf '1'
}

# The base64 payload out of the wrapper, by hand and without a JSON parser,
# because there is no JSON parser in this repository and there is not going to
# be one (GR2). index/substr rather than a regexp: the value is one very long
# line and a backtracking match on it is the slowest way to be wrong.
extract_image() {
  awk '{
    p = index($0, "\"image\"")
    if (p == 0) next
    r = substr($0, p + 7)
    a = index(r, "\"")
    if (a == 0) next
    r = substr(r, a + 1)
    b = index(r, "\"")
    if (b == 0) next
    printf "%s", substr(r, 1, b - 1)
    exit
  }' "$1"
}

# What went wrong, in the words the API used, trimmed to something readable.
extract_error() {
  m=$(awk '{
    p = index($0, "\"message\"")
    if (p == 0) next
    r = substr($0, p + 9)
    a = index(r, "\"")
    if (a == 0) next
    r = substr(r, a + 1)
    b = index(r, "\"")
    if (b == 0) next
    printf "%s", substr(r, 1, b - 1)
    exit
  }' "$1")
  [ -n "$m" ] || m=$(cut -c1-160 < "$1" | tr -d '\n')
  printf '%s' "$m"
}

# --- one plate --------------------------------------------------------------
# Returns 0 if a plate landed, 1 if the API said no, 2 if there was nothing to
# do. Only a 1 counts against the run's patience.
paint() {
  sha=$1
  short=$(printf '%s' "$sha" | cut -c1-8)

  if [ "$FORCE" = 0 ]; then
    have=$(manifest_file "$sha" 2>/dev/null || true)
    if [ -n "$have" ] && [ -f "$DIR/$have" ]; then
      return 2
    fi
  fi

  scene=$(scene_of "$sha")
  [ -n "$scene" ] || scene='An empty field. Nothing in this one moved.'
  prompt="$STYLE The scene: $scene"
  esc=$(json_escape "$prompt")
  seed=$(seed_of "$sha")

  printf '{"prompt":"%s","seed":%s,"steps":4}' "$esc" "$seed" > "$TMP/body.json"

  code=$(curl -sS -o "$TMP/resp" -w '%{http_code}' \
         --connect-timeout 15 --max-time 120 \
         -X POST \
         -H "Authorization: Bearer $TOKEN" \
         -H "Content-Type: application/json" \
         --data-binary @"$TMP/body.json" \
         "$API/accounts/$ACCOUNT/ai/run/$MODEL" \
         2>"$TMP/curl.err") || {
    say "$short - could not reach cloudflare: $(tr -d '\n' < "$TMP/curl.err" | cut -c1-120)"
    return 1
  }

  # Some models hand back the bytes and some hand back base64 in a wrapper.
  # Both are an image, so look at what arrived rather than at the content type
  # or the status - a picture that opens is a picture that opens, and the code
  # is only worth quoting once there is no picture to be had.
  ext=$(sniff "$TMP/resp")
  if [ -n "$ext" ]; then
    mv "$TMP/resp" "$TMP/plate"
  else
    b64=$(extract_image "$TMP/resp")
    if [ -n "$b64" ] && find_decoder; then
      printf '%s' "$b64" | $DECODER > "$TMP/plate" 2>/dev/null
      ext=$(sniff "$TMP/plate")
    fi
    if [ -z "$ext" ]; then
      [ -n "$b64" ] && [ -z "$DECODER" ] && \
        { say 'no base64 on this machine, and no openssl either'; return 1; }
      say "$short - cloudflare said $code: $(extract_error "$TMP/resp")"
      return 1
    fi
  fi

  manifest_init
  out="$short.$ext"
  cp "$TMP/plate" "$DIR/$out" || return 1

  # --force paints over the file; the manifest still only ever gets one line
  # per commit, because two lines for one commit is a book that cannot decide.
  if [ -f "$MANIFEST" ] && manifest_file "$sha" >/dev/null 2>&1; then
    awk -F'\t' -v s="$sha" '$1 != s' "$MANIFEST" > "$TMP/man" && cp "$TMP/man" "$MANIFEST"
  fi
  printf '%s\t%s\t%s\n' "$sha" "$out" "$(clean "$scene")" >> "$MANIFEST"

  size=$(wc -c < "$DIR/$out" | tr -d ' ')
  say "$short - $out, ${size} bytes"
  return 0
}

# --- credentials, or a quiet exit -------------------------------------------
configured() {
  [ -n "$ACCOUNT" ] && [ -n "$TOKEN" ] && command -v curl >/dev/null 2>&1
}

why_not() {
  command -v curl >/dev/null 2>&1 || { printf 'no curl on this machine'; return; }
  [ -n "$ACCOUNT" ] || { printf 'CLOUDFLARE_ACCOUNT_ID is not set, in the environment or in .env'; return; }
  [ -n "$TOKEN" ]   || { printf 'CLOUDFLARE_API_TOKEN is not set, in the environment or in .env'; return; }
  printf 'ready'
}

# --- the run ----------------------------------------------------------------
FORCE=0
AUTO=0
ONE=''

while [ $# -gt 0 ]; do
  case $1 in
    --force)    FORCE=1 ;;
    --auto)     AUTO=1 ;;
    --one)      shift; ONE=${1:-} ; [ -n "$ONE" ] || { say '--one needs a commit'; exit 2; } ;;
    --all)      CAP=0 ;;
    --check)
      printf 'chronicle-art: %s\n' "$(why_not)"
      printf '  model    %s\n' "$MODEL"
      printf '  plates   %s in %s\n' "$(ls "$DIR" 2>/dev/null | grep -c '\.\(jpg\|png\|webp\)$')" "$DIR"
      printf '  .env     %s\n' "$([ -f .env ] && printf 'present' || printf 'not there')"
      exit 0 ;;
    --list)
      [ -f "$MANIFEST" ] || quit 'nothing painted yet'
      awk -F'\t' '$1 !~ /^#/ && NF >= 3 { printf "  %s  %-14s %s\n", substr($1,1,8), $2, $3 }' "$MANIFEST"
      exit 0 ;;
    --prune)
      # A plate somebody deleted is a plate that gets painted again next time.
      [ -f "$MANIFEST" ] || exit 0
      awk -F'\t' -v d="$DIR" '
        /^#/ { print; next }
        NF < 2 { next }
        { cmd = "test -f " d "/" $2; if (system(cmd) == 0) print; else gone++ }
        END { if (gone) printf "chronicle-art: %d line%s forgotten\n", gone, (gone == 1 ? "" : "s") | "cat 1>&2" }
      ' "$MANIFEST" > "$MANIFEST.new" && mv "$MANIFEST.new" "$MANIFEST"
      exit 0 ;;
    -h|--help)
      sed -n '2,60p' "$0" | sed 's/^# \{0,1\}//' ; exit 0 ;;
    -*)  say "unknown option $1"; exit 2 ;;
    *)   ONE=$1 ;;
  esac
  shift
done

[ -n "${ASTEROIDS_NO_ART:-}" ] && exit 0
git rev-parse --verify -q HEAD >/dev/null 2>&1 || exit 0

if ! configured; then
  # The quiet exit, and it is the important one: a pilot with no credentials
  # rebuilds the book exactly as before and is not told off for it.
  [ "$AUTO" = 1 ] && exit 0
  quit "$(why_not) - no plates painted, and the book does not mind"
fi

TMP=$(mktemp -d) || exit 0
trap 'rm -rf "$TMP"' EXIT INT TERM

LIST="$TMP/versions"
if [ -n "$ONE" ]; then
  h=$(git rev-parse --verify -q "$ONE^{commit}") || { say "no such version: $ONE"; exit 2; }
  printf '%s\n' "$h" > "$LIST"
else
  # Oldest first, so the manifest reads in the order the versions happened and
  # a capped run always fills the earliest gap rather than a random one.
  git rev-list --full-history --no-merges --reverse HEAD -- $GAME 2>/dev/null > "$LIST"
fi

[ "$AUTO" = 1 ] || CAP=${CAP:-0}
[ "$AUTO" = 1 ] && [ "$CAP" = 0 ] && CAP=3

made=0
failed=0
while IFS= read -r h; do
  [ -n "$h" ] || continue
  paint "$h"
  case $? in
    0) made=$((made + 1)) ;;
    1) failed=$((failed + 1)) ;;
  esac
  # Three refusals in a row is a wrong token or a spent allocation, not bad
  # luck, and hammering it helps nobody.
  [ "$failed" -ge 3 ] && { say 'giving up for now - the book builds without them'; break; }
  [ "$CAP" -gt 0 ] && [ "$made" -ge "$CAP" ] && break
done < "$LIST"

if [ "$made" -gt 0 ]; then
  printf 'chronicle-art: %d plate%s painted, in %s\n' "$made" \
         "$([ "$made" = 1 ] || printf 's')" "$DIR"
fi
exit 0
