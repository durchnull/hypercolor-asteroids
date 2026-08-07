#!/bin/sh
# ---------------------------------------------------------------------------
# export.sh - the whole cabinet in one file.
#
# The game is a manifest of modules and a handful of stylesheets that the
# browser assembles at load time: index.html links the CSS, src/boot.js reads
# src/features.js and injects every module in order. That is all that happens.
# No fetch, no images, no fonts, no CDN - GR2 forbids every one of them, which
# is exactly why this script can exist and is concatenation rather than a
# bundler. There is still no build step: index.html remains the thing you open
# by double-clicking, and this produces a copy for somewhere that will only
# take one file.
#
#   tools/export.sh                     the whole page, to stdout
#   tools/export.sh -o docs/play.html   the whole page, to a file
#   tools/export.sh --artifact          body content only, no <head>
#
# --artifact is for a host that supplies its own <!doctype>, <head> and <body>
# and only wants what goes inside. The stylesheet rides at the top of the body,
# which browsers accept, and the page title has to come from the host because
# there is no <head> left to put one in.
#
# Nothing here is a list. The stylesheets come from the <link> tags in
# index.html and the modules from src/features.js, so a feature appended to the
# manifest is in the next export without anybody remembering this file exists.
# Where the script does have to recognise something, it stops and says so
# rather than quietly shipping half a game.
#
# Two optional extras are switched off in an export, and both are things that
# only exist when a particular file is sitting next to the page:
#
#   src/game/whoami.local.js  your seat. Untracked and local, so it could never
#                             have travelled anyway - the splash screen asks
#                             who is flying, which is what GR11 says happens
#                             when the file is not there.
#   docs/faces/faces.js       the painted portraits. A face is a picture of a
#                             person and sending one somewhere is their call,
#                             not this script's. The picker reads exactly as it
#                             did before there were faces.
#
# Both are loaded by appending a <script> at runtime, so switching one off is
# deleting the line that sets its src: the element is still appended, has no
# src and no text, and the browser does nothing at all with it.
#
# The link to the book goes too. It is a relative href into docs/, and an
# export has no docs/ next to it.
# ---------------------------------------------------------------------------
set -eu

die() { printf 'export: %s\n' "$1" >&2; exit 1; }

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

MODE=document
OUT=-

while [ $# -gt 0 ]; do
  case $1 in
    --artifact) MODE=artifact ;;
    -o)         shift; [ $# -gt 0 ] || die "-o needs a path"; OUT=$1 ;;
    -h|--help)  sed -n '3,45p' "$0" | sed 's/^#\{1,\} \{0,1\}//'; exit 0 ;;
    *)          die "unknown argument: $1 (try --help)" ;;
  esac
  shift
done

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT INT HUP TERM

# --- what goes in, read off the two files that already say so ---------------

CSS=$(sed -n 's/^[[:space:]]*<link rel="stylesheet" href="\([^"]*\)".*/\1/p' index.html)
[ -n "$CSS" ] || die "no stylesheet links in index.html - has the head changed shape?"

MODULES=$(sed -n 's|^[[:space:]]*"\./\([^"]*\.js\)",.*|src/\1|p' src/features.js)
[ -n "$MODULES" ] || die "no modules found in src/features.js"

# --- index.html, with two markers where the assembly happens ----------------
#
# Comments in index.html are notes to whoever edits index.html. An export is
# not that file and cannot be edited back into it, so they come out.

awk '
  /^[[:space:]]*<!--/            { c = 1 }
  c                              { if (/-->/) c = 0; next }
  /<p class="book">/             { b = 1 }
  b                              { if (/<\/p>/) b = 0; next }
  /<link rel="stylesheet"/       { if (!css++) print "@@CSS@@"; next }
  /<script src="src\/boot\.js">/ { print "@@JS@@"; js++; next }
                                 { print }
  END { if (!css || !js) exit 3 }
' index.html > "$TMP/page" ||
  die "index.html is not the shape this expects: it needs stylesheet links and a src/boot.js script tag"

# --artifact keeps only what lives inside <body>, and the stylesheet moves in
# with it because there is nowhere else for it to go.
if [ "$MODE" = artifact ]; then
  { printf '@@CSS@@\n'
    awk '/<body>/ { b = 1; next } /<\/body>/ { b = 0 } b' "$TMP/page"
  } > "$TMP/inner"
  mv "$TMP/inner" "$TMP/page"
fi

# --- the pieces -------------------------------------------------------------

emit_css() {
  printf '<style>\n'
  for f in $CSS; do
    [ -f "$f" ] || die "index.html links $f, which is not here"
    printf '/* ---- %s ---- */\n' "$f"
    cat "$f"
    printf '\n'
  done
  printf '</style>\n'
}

# One line out of a file, and a loud stop if it is not there exactly once -
# a silently missed cut ships an export that reaches for a file it cannot have.
without() {
  n=$(grep -c "$2" "$1" || true)
  [ "$n" = "1" ] ||
    die "$1: expected one line matching /$2/, found $n - the export cannot switch that off any more"
  grep -v "$2" "$1"
}

# A module per script tag, the way boot.js does it, so one broken file still
# only costs its own feature.
emit_module() {
  printf '<script>\n// ---- %s ----\n' "$1"
  case $1 in
    src/game/profile.js) without "$1" 's\.src = "src/game/whoami\.local\.js";' ;;
    src/ui/profile.js)   without "$1" 'f\.src = "docs/faces/faces\.js";' ;;
    *)                   cat "$1" ;;
  esac
  printf '\n</script>\n'
}

emit_js() {
  printf '<script>\nwindow.ASTEROIDS = {};\n</script>\n'
  emit_module src/features.js
  for f in $MODULES; do
    [ -f "$f" ] || die "src/features.js lists $f, which is not here"
    emit_module "$f"
  done
  emit_module src/main.js
}

expand() {
  while IFS= read -r line; do
    case $line in
      @@CSS@@) emit_css ;;
      @@JS@@)  emit_js ;;
      *)       printf '%s\n' "$line" ;;
    esac
  done < "$TMP/page"
}

# --- out --------------------------------------------------------------------

if [ "$OUT" = "-" ]; then
  expand
else
  expand > "$OUT"
  printf 'export: %s, %s bytes, %s modules\n' \
    "$OUT" "$(wc -c < "$OUT" | tr -d ' ')" \
    "$(printf '%s\n' "$MODULES" | wc -l | tr -d ' ')" >&2
fi
