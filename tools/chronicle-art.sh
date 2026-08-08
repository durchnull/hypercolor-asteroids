#!/bin/sh
# ---------------------------------------------------------------------------
# chronicle-art.sh - the painted pictures, and only ever one of each.
#
# Two subjects, one machine. A plate for every version, and a face for every
# pilot who has ever landed anything.
#
# Every chapter in the book already has a picture: tools/chronicle.sh draws the
# commit itself, a rock per sector, seeded off the hash. That one is arithmetic
# and it comes back identical on every machine forever.
#
# These are the other kind. A model is handed the version's tagline and asked to
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
#   docs/faces/<slug>.jpg  the face, named for the pilot it belongs to
#   docs/faces/index.tsv   pilot, file, what was asked for
#   docs/faces/faces.js    the same list, for a cabinet that cannot read a TSV
#
# A commit is asked for exactly once, ever. Once its line is in the manifest and
# the file it names is on disk, this script has nothing left to do for it. That
# is also why the file is named for the commit rather than for the version: a
# version number is counted off the history and could in principle shift, a
# commit hash is the commit.
#
# A pilot is asked for once and rather more finally than that. A plate can be
# painted again - --force does it, --prune re-arms it, and both are fine,
# because a version is a fact about the history and asking twice about a fact
# costs nothing. A face is not a fact about the history. It is what somebody
# looks like in here from now on, it turns up next to their name on the cover
# and in every chapter they flew, and a portrait that can be rerolled until it
# flatters is not a portrait. So there is no --force for a face, no --prune for
# a face, and the manifest line alone is the lock: once a pilot has a line they
# are done, whether or not the file it names is still on disk. The only way to
# take a face back is to delete both by hand and commit having done it, in the
# open, where the history keeps it - which is the same deal every other rule in
# this project offers, and it is deliberately not a flag.
#
# The pilot's name is never sent anywhere. It picks the seed and nothing else:
# every face is asked for with the identical sentence, so the roster reads as
# one crew rather than a folder of strangers, and the seed is what makes a face
# theirs. It also means two clones that paint the same pilot before either
# commits arrive at the same face rather than at an argument.
#
# About the network, which is the one thing this project does not do. GR2 says
# the cabinet plays on a plane, and it still does: nothing here runs in the
# game, nothing here runs in a browser, and the plates are ordinary files in the
# repository by the time any reader sees them. This script runs on the machine
# of whoever is writing the book, needs credentials that only they have, and
# exits quietly and successfully when it has none. The book that ships has no
# idea any of this happened.
#
#   tools/chronicle-art.sh              everything that lacks a picture
#   tools/chronicle-art.sh --auto       the same, capped - what a rebuild calls
#   tools/chronicle-art.sh --plates     only the versions
#   tools/chronicle-art.sh --faces      only the pilots
#   tools/chronicle-art.sh --one <rev>  just that version
#   tools/chronicle-art.sh --face <who> just that pilot, if they have none yet
#   tools/chronicle-art.sh --force      paint a plate again. Never a face.
#   tools/chronicle-art.sh --check      say whether it is wired up, paint nothing
#   tools/chronicle-art.sh --list       what has been painted so far
#   tools/chronicle-art.sh --prune      forget plate lines whose file is gone
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
#   ASTEROIDS_FACE_MAX    faces per --auto run, default 2
#   ASTEROIDS_FACE_STYLE  replaces the sentence every face is asked for with
#   ASTEROIDS_NO_ART=1    do nothing at all, for a rebuild that should be quick
# ---------------------------------------------------------------------------
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$ROOT" || exit 0

DIR=docs/art
MANIFEST=$DIR/index.tsv
FDIR=docs/faces
FMANIFEST=$FDIR/index.tsv
MODEL=${ASTEROIDS_ART_MODEL:-@cf/black-forest-labs/flux-1-schnell}
CAP=${ASTEROIDS_ART_MAX:-3}
FCAP=${ASTEROIDS_FACE_MAX:-2}
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
# And what a pilot looks like. The same sentence for every one of them, for the
# same reason the plates share theirs: a roster of portraits that agree on the
# light is a crew, and a roster that does not is a folder. Head and shoulders,
# because it sits at the size of a line of text next to a name and anything
# further away is a smudge - and no name in it, ever, for the reason above the
# plates carry too.
FACE=${ASTEROIDS_FACE_STYLE:-'A head-and-shoulders portrait of a person in a space suit, facing the viewer, the helmet visor down and the face behind it lit from inside, drawn as thin glowing vector lines on deep black, in the style of a 1980s vector arcade screen: luminous magenta, cyan, violet and amber wireframe outlines, heavy phosphor bloom, faint horizontal scanlines, centred, one figure only, plain black background. No text anywhere in the image, no letters, no words, no numbers, no captions, no signage, no logo, no watermark, no user interface, no frame, no border.'}

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
manifest_file() {   # manifest_file MANIFEST KEY - the picture kept for it, if any
  [ -f "$1" ] || return 1
  awk -F'\t' -v s="$2" '$1 == s { print $2; found = 1; exit }
                        END { exit !found }' "$1"
}

manifest_init() {   # manifest_init DIR MANIFEST
  mkdir -p "$1"
  [ -f "$2" ] && return 0
  if [ "$2" = "$FMANIFEST" ]; then
    {
      printf '# THE FACES\n#\n'
      printf '# One line per pilot who has a painted face in docs/faces/, written by\n'
      printf '# tools/chronicle-art.sh the one time it asked about them and read by\n'
      printf '# tools/chronicle.sh into every place their name appears. This line is the\n'
      printf '# lock, and it is a firmer one than the plates have: a pilot with a line\n'
      printf '# here is never asked about again, file or no file, flag or no flag. There\n'
      printf '# is no --force and no --prune for a face. See the top of the script.\n#\n'
      printf '# pilot\tfile\twhat was asked for\n'
    } > "$2"
  else
    {
      printf '# THE PLATES\n#\n'
      printf '# One line per version that has a painted plate in docs/art/, written by\n'
      printf '# tools/chronicle-art.sh the one time it asked for that version and read by\n'
      printf '# tools/chronicle.sh into the chapter. Append-only: a line in here is what\n'
      printf '# stops the same commit ever being painted twice, so it is not rewritten and\n'
      printf '# it is not reordered. A version with no line simply has no plate.\n#\n'
      printf '# commit\tfile\talt text\n'
    } > "$2"
  fi
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

# The same idea for a pilot, and the only thing about them that reaches the
# model. cksum rather than something prettier because it is POSIX and it is the
# same number on every machine, which is what makes a face a fact about a name
# instead of a fact about who happened to run this first.
seed_of_name() {
  n=$(printf '%s' "$1" | cksum 2>/dev/null | awk '{ print $1 }')
  case ${n:-} in ''|*[!0-9]*) n=1 ;; esac
  printf '%d' $((n % 2147483647))
}

# --- the pilots -------------------------------------------------------------
# Everybody the history has ever heard of, which is the same roster the book
# puts on the cover - a pilot who has only ever changed the rules has flown no
# versions and still has a name in here, so they still get a face.
#
# A workflow files the book's own paperwork after a push, and it has to author
# that commit as somebody - so an account that is not a person appears in the
# history and, read naively, asks for a portrait like anybody else. It got one,
# once. That matters more here than anywhere else in the book: a plate can be
# repainted and a face cannot, by anybody, ever, so a machine that slips into
# this list is in it for good.
#
# Which is exactly why the test is no longer in this file. It was, and it was
# one of three copies, each carrying a comment asking the other two to keep up.
# The version list already comes from tools/chronicle.sh; the roster comes from
# there now too, and the question has one answer. If that call ever fails there
# is no roster and nothing is painted, which is the direction this file wants
# to fail in.
pilots() {
  sh tools/chronicle.sh --pilots 2>/dev/null
}

slug_of() {
  s=$(printf '%s' "$1" | tr 'A-Z' 'a-z' \
      | sed -e 's/[^a-z0-9]\{1,\}/-/g' -e 's/^-*//' -e 's/-*$//')
  [ -n "$s" ] || s=pilot
  printf '%s' "$s"
}

# Two pilots whose names slug down to the same string get a file each. It will
# happen once, to somebody, and be baffling if it is not handled here. A taken
# filename can only ever belong to another pilot, because nobody is painted
# twice.
free_stem() {
  s=$1; t=$s; n=1
  while [ -f "$FDIR/$t.jpg" ] || [ -f "$FDIR/$t.png" ] || [ -f "$FDIR/$t.webp" ]; do
    n=$((n + 1)); t="$s-$n"
  done
  printf '%s' "$t"
}

# --- the faces, for the cabinet ---------------------------------------------
# The splash screen puts a pilot's face on their seat, and it cannot read a TSV
# to find out which file that is: there is no fetch in this project and there is
# not going to be one (GR2). So the manifest is written out a second time as a
# script the page can simply load - rebuilt from the manifest every time, never
# edited, and one assignment per line so that two clones which each painted a
# pilot merge without anybody having to think about it.
write_faces_js() {
  [ -f "$FMANIFEST" ] || return 0
  {
    printf '// Generated by tools/chronicle-art.sh from docs/faces/index.tsv.\n'
    printf '// One line per pilot who has a face. src/ui/profile.js loads this if it\n'
    printf '// is there and does without it if it is not, so it is never in the\n'
    printf '// manifest and never required to exist.\n'
    printf '(function (A) {\n'
    printf '  "use strict";\n'
    printf '  A.FACES = A.FACES || {};\n'
    awk -F'\t' '$1 !~ /^#/ && NF >= 2 {
      k = $1; v = $2
      gsub(/\\/, "\\\\", k); gsub(/"/, "\\\"", k)
      gsub(/\\/, "\\\\", v); gsub(/"/, "\\\"", v)
      printf "  A.FACES[\"%s\"] = \"%s\";\n", k, v
    }' "$FMANIFEST" | sort
    printf '})(ASTEROIDS);\n'
  } > "$FDIR/faces.js"
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

# --- one picture --------------------------------------------------------------
# The half that talks to the model, and the only half that does. Both subjects
# come through here: hand it where the picture goes, which manifest files it,
# what it is filed under, what to call the file, what to ask and with which
# seed. Whether to ask at all is the caller's business, because that is the one
# place the two subjects disagree and it is the whole of how they disagree.
#
# Returns 0 if a picture landed and 1 if the API said no. Only a 1 counts
# against the run's patience.
ask() {   # ask DIR MANIFEST KEY STEM PROMPT SEED NOTE
  a_dir=$1; a_man=$2; a_key=$3; a_stem=$4; a_prompt=$5; a_seed=$6; a_note=$7

  esc=$(json_escape "$a_prompt")
  printf '{"prompt":"%s","seed":%s,"steps":4}' "$esc" "$a_seed" > "$TMP/body.json"

  code=$(curl -sS -o "$TMP/resp" -w '%{http_code}' \
         --connect-timeout 15 --max-time 120 \
         -X POST \
         -H "Authorization: Bearer $TOKEN" \
         -H "Content-Type: application/json" \
         --data-binary @"$TMP/body.json" \
         "$API/accounts/$ACCOUNT/ai/run/$MODEL" \
         2>"$TMP/curl.err") || {
    say "$a_stem - could not reach cloudflare: $(tr -d '\n' < "$TMP/curl.err" | cut -c1-120)"
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
      say "$a_stem - cloudflare said $code: $(extract_error "$TMP/resp")"
      return 1
    fi
  fi

  manifest_init "$a_dir" "$a_man"
  out="$a_stem.$ext"
  cp "$TMP/plate" "$a_dir/$out" || return 1

  # --force paints over the file; the manifest still only ever gets one line
  # per commit, because two lines for one commit is a book that cannot decide.
  # A face never arrives here twice at all, so for those this is a no-op that
  # costs nothing and would be a bug worth seeing if it ever fired.
  if [ -f "$a_man" ] && manifest_file "$a_man" "$a_key" >/dev/null 2>&1; then
    awk -F'\t' -v s="$a_key" '$1 != s' "$a_man" > "$TMP/man" && cp "$TMP/man" "$a_man"
  fi
  printf '%s\t%s\t%s\n' "$a_key" "$out" "$(clean "$a_note")" >> "$a_man"

  size=$(wc -c < "$a_dir/$out" | tr -d ' ')
  say "$a_stem - $out, ${size} bytes"
  return 0
}

# --- one plate --------------------------------------------------------------
# Returns 0 if a plate landed, 1 if the API said no, 2 if there was nothing to
# do.
paint() {
  sha=$1
  short=$(printf '%s' "$sha" | cut -c1-8)

  if [ "$FORCE" = 0 ]; then
    have=$(manifest_file "$MANIFEST" "$sha" 2>/dev/null || true)
    if [ -n "$have" ] && [ -f "$DIR/$have" ]; then
      return 2
    fi
  fi

  scene=$(scene_of "$sha")
  [ -n "$scene" ] || scene='An empty field. Nothing in this one moved.'
  ask "$DIR" "$MANIFEST" "$sha" "$short" \
      "$STYLE The scene: $scene" "$(seed_of "$sha")" "$scene"
}

# --- one face ---------------------------------------------------------------
# The line is the lock, and it is the only lock: not the file, not a flag. A
# plate whose picture went missing is painted again next time round, because a
# version is a fact about the history and asking again about a fact costs
# nothing. This is not that. A pilot is asked about once, and if the answer is
# ever lost then the honest thing is a pilot with no face, not a second pilot
# wearing the first one's name.
portrait() {
  who=$1
  manifest_file "$FMANIFEST" "$who" >/dev/null 2>&1 && return 2

  mkdir -p "$FDIR"
  stem=$(free_stem "$(slug_of "$who")")
  ask "$FDIR" "$FMANIFEST" "$who" "$stem" \
      "$FACE" "$(seed_of_name "$who")" \
      "A pilot in a space suit, seeded from the name and asked for once."
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
WHO=''
DO_PLATES=1
DO_FACES=1

while [ $# -gt 0 ]; do
  case $1 in
    --force)    FORCE=1 ;;
    --auto)     AUTO=1 ;;
    --one)      shift; ONE=${1:-} ; [ -n "$ONE" ] || { say '--one needs a commit'; exit 2; }
                DO_FACES=0 ;;
    --face)     shift; WHO=${1:-} ; [ -n "$WHO" ] || { say '--face needs a pilot'; exit 2; }
                DO_PLATES=0 ;;
    --plates)   DO_FACES=0 ;;
    --faces)    DO_PLATES=0 ;;
    --all)      CAP=0; FCAP=0 ;;
    --check)
      printf 'chronicle-art: %s\n' "$(why_not)"
      printf '  model    %s\n' "$MODEL"
      printf '  plates   %s in %s\n' "$(ls "$DIR" 2>/dev/null | grep -c '\.\(jpg\|png\|webp\)$')" "$DIR"
      printf '  faces    %s in %s, of %s pilot%s in the history\n' \
             "$(ls "$FDIR" 2>/dev/null | grep -c '\.\(jpg\|png\|webp\)$')" "$FDIR" \
             "$(pilots | wc -l | tr -d ' ')" "$([ "$(pilots | wc -l | tr -d ' ')" = 1 ] || printf 's')"
      printf '  .env     %s\n' "$([ -f .env ] && printf 'present' || printf 'not there')"
      exit 0 ;;
    --list)
      n=0
      if [ -f "$MANIFEST" ]; then
        printf '  plates\n'
        awk -F'\t' '$1 !~ /^#/ && NF >= 3 { printf "    %s  %-14s %s\n", substr($1,1,8), $2, $3 }' "$MANIFEST"
        n=1
      fi
      if [ -f "$FMANIFEST" ]; then
        printf '  faces\n'
        awk -F'\t' '$1 !~ /^#/ && NF >= 2 { printf "    %-20s %s\n", $1, $2 }' "$FMANIFEST"
        n=1
      fi
      [ "$n" = 1 ] || quit 'nothing painted yet'
      exit 0 ;;
    --prune)
      # A plate somebody deleted is a plate that gets painted again next time.
      # The faces are not offered the same mercy on purpose: forgetting a line
      # in there is how a pilot would get a second face, so their manifest is
      # left exactly as it is and this only ever touches the plates.
      [ -f "$MANIFEST" ] || exit 0
      awk -F'\t' -v d="$DIR" '
        /^#/ { print; next }
        NF < 2 { next }
        { cmd = "test -f " d "/" $2; if (system(cmd) == 0) print; else gone++ }
        END { if (gone) printf "chronicle-art: %d line%s forgotten\n", gone, (gone == 1 ? "" : "s") | "cat 1>&2" }
      ' "$MANIFEST" > "$MANIFEST.new" && mv "$MANIFEST.new" "$MANIFEST"
      exit 0 ;;
    -h|--help)
      sed -n '2,89p' "$0" | sed 's/^# \{0,1\}//' ; exit 0 ;;
    -*)  say "unknown option $1"; exit 2 ;;
    *)   ONE=$1; DO_FACES=0 ;;
  esac
  shift
done

# Said once, where somebody who typed it will read it, rather than silently
# doing half of what they asked for.
if [ "$FORCE" = 1 ] && [ "$DO_FACES" = 1 ] && [ "$DO_PLATES" = 0 ]; then
  quit 'there is no --force for a face. A pilot is painted once - see the top of this script'
fi

[ -n "${ASTEROIDS_NO_ART:-}" ] && exit 0
git rev-parse --verify -q HEAD >/dev/null 2>&1 || exit 0

if ! configured; then
  # The quiet exit, and it is the important one: a pilot with no credentials
  # rebuilds the book exactly as before and is not told off for it.
  [ "$AUTO" = 1 ] && exit 0
  quit "$(why_not) - nothing painted, and the book does not mind"
fi

TMP=$(mktemp -d) || exit 0
trap 'rm -rf "$TMP"' EXIT INT TERM

[ "$AUTO" = 1 ] && [ "$CAP" = 0 ] && CAP=3

made=0
faced=0
failed=0

# --- the plates -------------------------------------------------------------
if [ "$DO_PLATES" = 1 ]; then
  LIST="$TMP/versions"
  if [ -n "$ONE" ]; then
    h=$(git rev-parse --verify -q "$ONE^{commit}") || { say "no such version: $ONE"; exit 2; }
    printf '%s\n' "$h" > "$LIST"
  else
    # Oldest first, so the manifest reads in the order the versions happened and
    # a capped run always fills the earliest gap rather than a random one.
    #
    # Asked for outright rather than worked out from a path list, which is what
    # this used to do. A path list is not the whole rule: it cannot say that the
    # generated ledger under src/ is not the game, nor that nobody flew the
    # commit a workflow authored, and this painted two plates for commits the
    # book files no chapter for before it was asked the question properly. A
    # plate is painted for exactly the commits that get a chapter, and there is
    # one script that knows which those are.
    sh tools/chronicle.sh --versions 2>/dev/null > "$LIST"
  fi

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
fi

# --- the faces --------------------------------------------------------------
# After the plates, and capped lower, because there are only ever as many of
# these as there are people and the list stops growing the moment everybody has
# one. A run that gives up on the plates gives up here too: the same token is
# the reason for both.
if [ "$DO_FACES" = 1 ] && [ "$failed" -lt 3 ]; then
  ROSTER="$TMP/pilots"
  if [ -n "$WHO" ]; then
    printf '%s\n' "$WHO" > "$ROSTER"
  else
    pilots > "$ROSTER"
  fi
  [ "$AUTO" = 1 ] && [ "$FCAP" = 0 ] && FCAP=2

  while IFS= read -r p; do
    [ -n "$p" ] || continue
    portrait "$p"
    case $? in
      0) faced=$((faced + 1)) ;;
      1) failed=$((failed + 1)) ;;
    esac
    [ "$failed" -ge 3 ] && { say 'giving up for now - a pilot with no face is only a pilot with no face'; break; }
    [ "$FCAP" -gt 0 ] && [ "$faced" -ge "$FCAP" ] && break
  done < "$ROSTER"
fi

# Rewritten from the manifest rather than appended to, so it is always exactly
# what the manifest says, a hand-edit of it does not survive contact, and a
# clone that somehow lost it gets it back on the next rebuild. Cheap enough to
# do every run, and identical bytes are not a change as far as git is concerned.
write_faces_js

if [ "$made" -gt 0 ]; then
  printf 'chronicle-art: %d plate%s painted, in %s\n' "$made" \
         "$([ "$made" = 1 ] || printf 's')" "$DIR"
fi
if [ "$faced" -gt 0 ]; then
  printf 'chronicle-art: %d face%s painted, in %s - once each, and that is that\n' "$faced" \
         "$([ "$faced" = 1 ] || printf 's')" "$FDIR"
fi
exit 0
