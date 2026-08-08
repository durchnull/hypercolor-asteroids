#!/bin/sh
# ---------------------------------------------------------------------------
# export.sh - the whole cabinet in one file, book and all.
#
# The game is a manifest of modules and a handful of stylesheets that the
# browser assembles at load time: index.html links the CSS, src/boot.js reads
# src/features.js and injects every module in order. That is all that happens.
# No fetch, no fonts, no CDN - GR2 forbids every one of them, which is exactly
# why this script can exist and is concatenation rather than a bundler. There
# is still no build step: index.html remains the thing you open by
# double-clicking, and this produces a copy for somewhere that will only take
# one file.
#
#   tools/export.sh                     the whole page, to stdout
#   tools/export.sh -o docs/play.html   the whole page, to a file
#   tools/export.sh --artifact          body content only, no <head>
#   tools/export.sh --no-book           the game on its own, no chronicle
#   tools/export.sh --names             real names, not initials
#   tools/export.sh --px 480            bigger plates (default 320)
#
# An export carries initials rather than names, and that is the default rather
# than a flag you have to remember: see "the names" below for what it covers
# and why it is that way round.
#
# --artifact is for a host that supplies its own <!doctype>, <head> and <body>
# and only wants what goes inside. The stylesheet rides at the top of the body,
# which browsers accept, and the page title has to come from the host because
# there is no <head> left to put one in.
#
# Nothing here is a list. The stylesheets come from the <link> tags in
# index.html, the modules from src/features.js, the sidecars from the calls
# that ask for them and the book from whatever docs/ actually holds - so a
# feature appended to the manifest, or a version added to the book, is in the
# next export without anybody remembering this file exists. Where the script
# does have to recognise something, it stops and says so rather than quietly
# shipping half a game.
#
# --- the book -------------------------------------------------------------
#
# docs/ is thirty-odd separate pages that link to each other, and this has to
# come out as one. So the chapters travel as text in a table, and the page
# hands one at a time to an <iframe srcdoc>: a chapter gets its own document,
# which is the only way it keeps its own <body> class, its own stylesheet and
# its own song without any of the three arguing with the game underneath it.
# Turning a page rebuilds that document, so a chapter arrives exactly as
# arriving at a chapter does.
#
# The frame never reaches out of itself and the page never reaches into it -
# a link posts a message and the page answers by handing over the next
# chapter. That way none of it depends on the two documents being allowed to
# touch, which somewhere with a sandbox around it is not a safe bet.
#
# What every chapter shares - the stylesheets, the song, the rail, the plates -
# would be thirty-four copies if it were baked into each one, so it is not:
# a chapter carries @@P:<name>@@ where a shared part goes and the part is put
# in on the way to the frame.
#
# The plates are the reason there is a size flag. They are 1024px paintings
# and there are one per version; a page cannot carry them at that size, so
# they are resized on the way in and 320px is the default. That needs a
# resizer on the machine doing the exporting - sips on a Mac, ImageMagick
# anywhere else. Without one the book is left out rather than shipped
# broken, and the export says so.
#
# GR2 is not bent by any of this: what a resizer is used for is making a copy
# for elsewhere, on the exporter's machine, the same way tools/chronicle-art.sh
# paints a plate on the book-writer's. Nothing is installed, nothing is
# fetched, and the cabinet itself still plays on a plane.
#
# --- what is switched off --------------------------------------------------
#
#   src/game/whoami.local.js  your seat. Untracked and local, so it could never
#                             have travelled anyway - the splash screen asks
#                             who is flying, which is what GR11 says happens
#                             when the file is not there.
#
# and, when the book is not coming, the two doors that lead into it. A link
# into docs/ from a page that has no docs/ next to it is a dead one, so the
# panels that hold them are hidden instead.
# ---------------------------------------------------------------------------
set -eu

die() { printf 'export: %s\n' "$1" >&2; exit 1; }
say() { printf 'export: %s\n' "$1" >&2; }

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

MODE=document
OUT=-
BOOK=auto
NAMES=0
PX=320
Q=62

while [ $# -gt 0 ]; do
  case $1 in
    --artifact) MODE=artifact ;;
    --no-book)  BOOK=no ;;
    --names)    NAMES=1 ;;
    --px)       shift; [ $# -gt 0 ] || die "--px needs a number"; PX=$1 ;;
    -o)         shift; [ $# -gt 0 ] || die "-o needs a path"; OUT=$1 ;;
    -h|--help)  sed -n '3,86p' "$0" | sed 's/^#\{1,\} \{0,1\}//'; exit 0 ;;
    *)          die "unknown argument: $1 (try --help)" ;;
  esac
  shift
done

case $PX in
  ''|*[!0-9]*) die "--px wants a whole number of pixels, got '$PX'" ;;
esac

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT INT HUP TERM

# --- what goes in, read off the files that already say so -------------------

CSS=$(sed -n 's/^[[:space:]]*<link rel="stylesheet" href="\([^"]*\)".*/\1/p' index.html)
[ -n "$CSS" ] || die "no stylesheet links in index.html - has the head changed shape?"

MODULES=$(sed -n 's|^[[:space:]]*"\./\([^"]*\.js\)",.*|src/\1|p' src/features.js)
[ -n "$MODULES" ] || die "no modules found in src/features.js"

# Every generated file the game asks for by name. src/core/sidecar.js exists so
# a module can want one of these and shrug when it is not there; an export
# either has it inline or knows for certain it never will, and either way the
# answer is the same one - settle, and do not go looking.
SIDECARS=$(grep -ho 'A\.sidecar("[^"]*"' src/*/*.js | sed 's/.*"\(.*\)"/\1/' | sort -u)
[ -n "$SIDECARS" ] || die "no A.sidecar() calls in src/ - has the sidecar gone?"

# --- can the book come? -----------------------------------------------------

RESIZE=
for c in sips magick convert; do
  command -v "$c" >/dev/null 2>&1 && { RESIZE=$c; break; }
done

PAGES=
if [ "$BOOK" = no ]; then
  BOOK=0
elif [ ! -f docs/index.html ]; then
  BOOK=0
  say "docs/index.html is not here - run tools/chronicle.sh first, or this is the game on its own"
elif [ -z "$RESIZE" ]; then
  BOOK=0
  say "no image resizer found (looked for sips, magick, convert) - the game goes without the book"
else
  BOOK=1
  # Every page docs/ holds, cover first and the chapters in the order they
  # landed, so the table reads the way the book does.
  PAGES=$(ls docs/*.html |
    sed 's|^docs/||' |
    awk '{ n = ($0 ~ /^v[0-9]+\.html$/) ? substr($0, 2) + 0 : ($0 == "index.html" ? -1 : 1e9)
           printf "%d\t%s\n", n, $0 }' |
    sort -n -k1,1 -k2,2 | cut -f2)
fi

# --- index.html, with the markers where the assembly happens ----------------
#
# Comments in index.html are notes to whoever edits index.html. An export is
# not that file and cannot be edited back into it, so they come out.

awk '
  /^[[:space:]]*<!--/            { c = 1 }
  c                              { if (/-->/) c = 0; next }
  /<link rel="stylesheet"/       { if (!css++) print "@@CSS@@"; next }
  /<script src="src\/boot\.js">/ { print "@@BOOK@@"; print "@@JS@@"; js++; next }
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

# --- the small tools --------------------------------------------------------

# One line out of a file, and a loud stop if it is not there exactly once -
# a silently missed cut ships an export that reaches for a file it cannot have.
without() {
  n=$(grep -c "$2" "$1" || true)
  [ "$n" = "1" ] ||
    die "$1: expected one line matching /$2/, found $n - the export cannot switch that off any more"
  grep -v "$2" "$1"
}

# The same bargain, one line changed rather than dropped. Plain text on both
# sides: what is being swapped here is a fragment of somebody's JavaScript, and
# a delimiter that turns up inside it is not a thing to find out about later.
swap() {
  n=$(grep -cF "$2" "$1" || true)
  [ "$n" = "1" ] ||
    die "$1: expected one line holding '$2', found $n - the export cannot rewrite that any more"
  awk -v find="$2" -v repl="$3" '
    { i = index($0, find)
      if (i) $0 = substr($0, 1, i - 1) repl substr($0, i + length(find))
      print }
  ' "$1"
}

# A file as a JS string expression, one source line per line so the result is
# still something a person can read and grep. Three things have to be escaped
# and only three: the backslash, the quote, and the one sequence that would end
# the <script> element this all has to sit inside.
jsstr() {
  sed -e 's/\\/\\\\/g' \
      -e 's/"/\\"/g' \
      -e 's|</script|<\\/script|g' \
      -e 's/^/"/' \
      -e 's/$/\\n" +/' "$1"
  printf '""'
}

# A picture, resized and inlined. The resizers disagree about everything except
# that the longest edge is the thing worth naming, so that is what is asked of
# each of them.
b64() {
  case $RESIZE in
    sips)    sips -Z "$PX" -s format jpeg -s formatOptions "$Q" "$1" --out "$TMP/img" >/dev/null 2>&1 ;;
    magick)  magick "$1" -resize "${PX}x${PX}>" -quality "$Q" "$TMP/img" >/dev/null 2>&1 ;;
    convert) convert "$1" -resize "${PX}x${PX}>" -quality "$Q" "$TMP/img" >/dev/null 2>&1 ;;
  esac || die "$RESIZE could not resize $1"
  printf 'data:image/jpeg;base64,'
  base64 < "$TMP/img" | tr -d '\n'
}

# --- the names --------------------------------------------------------------
#
# The repository is full of real people. The roster is the plainest case - the
# people holding a key, spelled the way their git config spells them, most of
# whom have never landed anything and are in the export purely as a name on a
# seat card. Nobody agreed to that when the export was a copy for a friend, and
# an artifact has a URL.
#
# So an export carries initials, and --names is how you say you meant it. The
# repository is untouched either way: the credit lives in the history, where
# GR7 keeps it, and this is one copy going somewhere else.
#
# Every name found anywhere gets the same initials everywhere, in one pass over
# the finished page, which is the only way the substitution stays consistent
# with itself: the roster, the ledger, an event's `by:`, a chapter byline, the
# face a seat card looks up by name and the file that face is stored in are all
# the same person, and a rename that caught four of the six would be worse than
# none. GR11 is not touched by it - the runner compares the seat to the `by:`
# and both sides move together, so an author's own trap stays quiet for them.
#
# The clock goes too. A date says when a version landed; thirty-three of them
# stamped to the minute says what time this person tends to stop working.

initials() {
  printf '%s' "$1" | awk '{
    out = ""
    for (i = 1; i <= NF; i++) {
      # the first character, whole, where the first character is several bytes
      c = match($i, /^[\300-\377][\200-\277]*/) ? substr($i, 1, RLENGTH) : substr($i, 1, 1)
      out = out toupper(c) "."
    }
    print out
  }'
}

slug() { printf '%s' "$1" | tr 'A-Z ' 'a-z-'; }

# What a name may not do on its way into a sed script.
esc_lhs() { printf '%s' "$1" | sed 's/[][\\.*^$|]/\\&/g'; }
esc_rhs() { printf '%s' "$1" | sed 's/[\\&|]/\\&/g'; }

# Everywhere a pilot is written down: the history, the guest list, the ledger,
# the events they signed, the faces that have been painted. Longest first, so a
# name that is the front of another name cannot take half of it.
pilots() {
  { git log --format='%an' 2>/dev/null
    awk '/A\.ROSTER *= *\[/ { r = 1; next } r { if (/\]/) r = 0
           else if (match($0, /"[^"]+"/)) print substr($0, RSTART + 1, RLENGTH - 2) }' src/game/roster.js
    sed -n 's/^[[:space:]]*"\([^"]*\)":[[:space:]]*{.*bends.*/\1/p' src/game/ledger.js
    grep -ho 'by: *"[^"]*"' src/events/*.js 2>/dev/null | sed 's/.*"\(.*\)"/\1/'
    [ -f docs/faces/faces.js ] && sed -n 's/.*A\.FACES\["\([^"]*\)"\].*/\1/p' docs/faces/faces.js
  } | sed '/^$/d' | sort -u | awk '{ print length($0) "\t" $0 }' | sort -rn -k1,1 | cut -f2-
}

# The sed script that does it, built once.
#
# Whole names first, then the words they are made of, because the book does not
# only use whole names: a chapter says "David filed the note" where the byline
# said "David Friedrich", and a given name on its own is still a given name.
# Both halves get the whole initials, so the sentence still reads.
#
# A word is only taken when it is a word - letters on neither side - and only
# from three letters up, so an initial or a "de" cannot go through the page
# eating fragments. It is still a blunt instrument: a pilot named Mark would
# cost the book the word "mark". That is the right way round for a page that
# is about to have a URL, and --names is there for when it is not.
redaction() {
  pilots | while IFS= read -r name; do
    [ -n "$name" ] || continue
    ini=$(initials "$name")
    printf 's|%s|%s|g\n' "$(esc_lhs "$name")" "$(esc_rhs "$ini")"
    printf 's|%s|%s|g\n' "$(esc_lhs "$(slug "$name")")" "$(esc_rhs "$(slug "$ini" | tr -d '.')")"
  done

  pilots | while IFS= read -r name; do
    [ -n "$name" ] || continue
    ini=$(esc_rhs "$(initials "$name")")
    for word in $name; do
      # three letters is the floor; awk counts bytes, so a short non-ascii name
      # is simply left to the whole-name pass above
      [ "${#word}" -ge 3 ] || continue
      w=$(esc_lhs "$word")
      printf 's|\\([^A-Za-z]\\)%s\\([^A-Za-z]\\)|\\1%s\\2|g\n' "$w" "$ini"
      printf 's|^%s\\([^A-Za-z]\\)|%s\\1|g\n' "$w" "$ini"
      printf 's|\\([^A-Za-z]\\)%s$|\\1%s|g\n' "$w" "$ini"
    done
  done
  # A byline keeps its date and loses its minute; the panel that counts the
  # minute as a statistic keeps its tile and loses the number.
  #
  # Anchored on what surrounds the time rather than on the element around it:
  # by the time this runs a chapter is a JavaScript string, so its quotes are
  # not quotes any more and class="when" is not there to be matched.
  printf '%s\n' 's| &middot; [0-9][0-9]:[0-9][0-9]</span>|</span>|g'
  printf '%s\n' 's|<b>[0-9][0-9]:[0-9][0-9]</b><span>on the clock</span>|<b>--:--</b><span>on the clock</span>|g'
}

# --- the pieces -------------------------------------------------------------

emit_css() {
  printf '<style>\n'
  for f in $CSS; do
    [ -f "$f" ] || die "index.html links $f, which is not here"
    printf '/* ---- %s ---- */\n' "$f"
    cat "$f"
    printf '\n'
  done
  # A door into a book that did not come is worse than no door. Both panels
  # draw themselves out of data they will not have, so this only hides the two
  # links that would have gone somewhere.
  [ "$BOOK" = 1 ] || printf '/* ---- no book in this export ---- */\n#book, .boardnote { display: none; }\n'
  printf '</style>\n'
}

# A module per script tag, the way boot.js does it, so one broken file still
# only costs its own feature.
emit_module() {
  printf '<script>\n// ---- %s ----\n' "$1"
  case $1 in
    src/game/profile.js) without "$1" 's\.src = "src/game/whoami\.local\.js";' ;;
    *)                   cat "$1" ;;
  esac
  printf '\n</script>\n'
}

# Everything src/core/sidecar.js would have gone looking for, answered here
# instead: the ones that came are already run by the time this lands, the ones
# that did not are never asked for, and a src nobody thought of still falls
# through to the real thing.
emit_sidecars() {
  for s in $SIDECARS; do
    if [ "$BOOK" = 1 ] && [ -f "$s" ]; then
      printf '<script>\n// ---- %s ----\n' "$s"
      cat "$s"
      printf '\n</script>\n'
    fi
  done
  printf '<script>\n// ---- the sidecars, settled at build time ----\n'
  printf '(function (A) {\n  "use strict";\n  var settled = {'
  for s in $SIDECARS; do printf '\n    "%s": 1,' "$s"; done
  cat <<'JS'

  };
  var ask = A.sidecar;
  A.sidecar = function (src, then) {
    if (!(src in settled)) return ask(src, then);
    if (then) then();
  };
})(ASTEROIDS);
JS
  printf '</script>\n'
}

emit_js() {
  printf '<script>\nwindow.ASTEROIDS = {};\n</script>\n'
  emit_module src/features.js
  for f in $MODULES; do
    [ -f "$f" ] || die "src/features.js lists $f, which is not here"
    emit_module "$f"
    [ "$f" = src/core/sidecar.js ] && emit_sidecars
  done
  emit_module src/main.js
}

# --- the book ---------------------------------------------------------------

# One chapter, rebuilt as a document of its own: the links out of the head
# become @@P:@@ markers in the order the page asked for them, the two scripts
# it loads by name go to the foot where their defer used to put them, and the
# frame's own errand-boy goes in at the top where it can hear a key before the
# chapter does.
emit_page() {
  f=docs/$1
  attrs=$(sed -n 's/.*<body\([^>]*\)>.*/\1/p' "$f" | head -1)

  printf '<!doctype html><html lang="en" data-page="%s"><head><meta charset="utf-8">\n' "$1"
  printf '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
  sed -n 's|^<title>\(.*\)</title>.*|<title>\1</title>|p' "$f" | head -1
  sed -n 's|^<link rel="stylesheet" href="\([^"]*\)".*|\1|p' "$f" |
    while IFS= read -r href; do
      case $href in
        ../*) printf '<style>@@P:%s@@</style>\n' "${href#../}" ;;
        *)    printf '<style>@@P:docs/%s@@</style>\n' "$href" ;;
      esac
    done
  printf '</head><body%s>\n' "$attrs"
  printf '<script>@@P:art@@</script>\n<script>@@P:nav@@</script>\n'
  # The body as it stands, less the two scripts it pulls in by name - and with
  # every picture it names turned into a marker like everything else shared, so
  # a plate is carried once for the whole book rather than once per chapter
  # that shows it.
  awk '/<body/ { b = 1; next }
       /^<\/body>/ { b = 0 }
       b && /^<script src="[^"]*"[^>]*><\/script>$/ { next }
       b { gsub(/(art|faces)\/[A-Za-z0-9._-]+\.jpg/, "@@P:&@@"); print }' "$f"
  printf '<script>@@P:docs/chronicle-song.js@@</script>\n'
  printf '<script>@@P:docs/rail.js@@</script>\n'
  printf '</body></html>\n'
}

emit_book() {
  [ "$BOOK" = 1 ] || return 0

  cat <<'CSS'
<style>
/* ---- the book, folded in ---- */
.bookframe { position: fixed; inset: 0; z-index: 90; background: #05060a; }
.bookframe[hidden] { display: none; }
.bookframe iframe { display: block; width: 100%; height: 100%; border: 0; }
/* Left, because a chapter keeps a link to its own plate in the other corner. */
.bookshut {
  position: fixed; top: 12px; left: 14px; z-index: 91;
  font: 600 11px/1 ui-monospace, monospace; letter-spacing: .14em;
  color: #cfe3ff; background: rgba(6, 10, 20, .72); cursor: pointer;
  border: 1px solid rgba(150, 190, 255, .38); border-radius: 3px; padding: 8px 11px;
}
.bookshut:hover { color: #fff; border-color: rgba(180, 215, 255, .8); }
</style>
<div class="bookframe" id="bookframe" hidden>
  <iframe title="The chronicle" referrerpolicy="no-referrer"></iframe>
  <button type="button" class="bookshut" id="bookshut">CLOSE THE BOOK &times;</button>
</div>
CSS

  printf '<script>\n// ---- the chronicle, one file ----\n(function () {\n  "use strict";\n'

  # The plates and the faces, resized and inlined, under the names the book
  # already calls them by.
  printf '  var ART = {'
  n=0
  for d in art faces; do
    [ -d "docs/$d" ] || continue
    for img in docs/$d/*.jpg; do
      [ -f "$img" ] || continue
      printf '\n    "%s": "%s",' "$d/$(basename "$img")" "$(b64 "$img")"
      n=$((n + 1))
    done
  done
  printf '\n  };\n'
  say "$n pictures at ${PX}px"

  # Everything a chapter shares with every other chapter, put in on the way to
  # the frame rather than baked into each of thirty-odd copies.
  printf '  var PARTS = {\n'
  for f in $CSS docs/chronicle.css docs/notes.css; do
    [ -f "$f" ] || continue
    printf '    "%s":\n' "$f"; jsstr "$f"; printf ',\n'
  done
  printf '    "docs/rail.js":\n'; jsstr docs/rail.js; printf ',\n'
  # The song asks the address bar which chapter it is playing for, and inside a
  # srcdoc frame there is no address to ask. So it is told instead, off the one
  # attribute every chapter carries, and the question it used to ask is still
  # the answer when nobody told it anything.
  swap docs/chronicle-song.js \
    'exec(location.pathname)' \
    'exec(document.documentElement.getAttribute("data-page") || location.pathname)' \
    > "$TMP/song.js"
  printf '    "docs/chronicle-song.js":\n'; jsstr "$TMP/song.js"; printf ',\n'
  cat > "$TMP/nav.js" <<'JS'
// The frame's errand-boy, in every chapter.
//
// It does two jobs and neither of them touches the page outside. Every picture
// written into a chapter was turned into a marker before the chapter got here,
// so the only ones left to catch are the rail's, which it builds out of bare
// filenames while it runs. Catching those means the name is exchanged for the
// picture on the way into the element rather than after it is in - an <img>
// starts asking for whatever it was handed the moment it is handed it, and
// here there is nobody to ask.
//
// And a link is not followed: it is called up the chain, and the next chapter
// arrives the way this one did.
(function () {
  "use strict";
  var ART = window.__ART__ || {};

  var src = Object.getOwnPropertyDescriptor(HTMLImageElement.prototype, "src");
  Object.defineProperty(HTMLImageElement.prototype, "src", {
    configurable: true,
    enumerable: src.enumerable,
    get: src.get,
    set: function (v) { src.set.call(this, ART[v] || v); },
  });

  function go(href) { parent.postMessage({ chapter: href }, "*"); }

  document.addEventListener("click", function (e) {
    var a = e.target;
    while (a && a !== document && a.tagName !== "A") a = a.parentNode;
    if (!a || a === document) return;
    var h = a.getAttribute("href");
    if (!h || /^(#|data:|blob:|[a-z]+:)/i.test(h)) return;
    e.preventDefault();
    go(h);
  }, true);

  // The chapter turns its own pages with the arrow keys, by setting
  // location.href. There is nowhere for that to go from in here, so the keys
  // are caught first - and handed back the moment the lightbox is up, because
  // then Escape means the picture rather than the page.
  window.addEventListener("keydown", function (e) {
    var to = { ArrowLeft: ".prev", ArrowRight: ".next", Escape: ".up" }[e.key];
    if (!to) return;
    if (document.documentElement.classList.contains("lit-open")) return;
    var a = document.querySelector(".dock " + to);
    var h = a && a.getAttribute("href");
    if (!h) return;
    e.stopImmediatePropagation();
    e.preventDefault();
    go(h);
  }, true);
})();
JS
  printf '    "nav":\n'; jsstr "$TMP/nav.js"; printf '\n  };\n'

  # The chapters.
  printf '  var CHAPTERS = {\n'
  for p in $PAGES; do
    emit_page "$p" > "$TMP/chapter"
    printf '    "%s":\n' "$p"; jsstr "$TMP/chapter"; printf ',\n'
  done
  printf '    "": ""\n  };\n'
  say "$(printf '%s\n' "$PAGES" | wc -l | tr -d ' ') chapters"

  cat <<'JS'

  // The plates are wanted twice - here, for the panel on the splash screen,
  // and inside the frame, where they are the rail. One copy of the data, then,
  // and the frame's copy is written out of it the first time a page is turned.
  var artsrc = null;
  function part(k) {
    if (k === "art") {
      if (artsrc === null) artsrc = "window.__ART__=" + JSON.stringify(ART) + ";";
      return artsrc;
    }
    return PARTS[k] || ART[k] || "";
  }

  var frame = document.getElementById("bookframe");
  var pane = frame.querySelector("iframe");
  var shut = document.getElementById("bookshut");
  var here = "";

  function show(name) {
    var page = CHAPTERS[name];
    if (!page) return false;
    here = name;
    pane.srcdoc = page.replace(/@@P:([^@]+)@@/g, function (m, k) { return part(k); });
    frame.hidden = false;
    return true;
  }

  function close() {
    frame.hidden = true;
    pane.srcdoc = "";
    here = "";
  }

  // A chapter asking for the next one. Anything climbing out of docs/ is the
  // link back to the cabinet, and the cabinet is what is underneath already.
  window.addEventListener("message", function (e) {
    if (e.source !== pane.contentWindow) return;
    var h = e.data && e.data.chapter;
    if (typeof h !== "string") return;
    h = h.replace(/[?#].*$/, "");
    if (h.slice(0, 3) === "../" || !show(h)) close();
  });

  // Every door the game draws into the book, however it draws it.
  document.addEventListener("click", function (e) {
    var a = e.target;
    while (a && a !== document && a.tagName !== "A") a = a.parentNode;
    if (!a || a === document) return;
    var h = a.getAttribute("href") || "";
    if (h.slice(0, 5) !== "docs/") return;
    e.preventDefault();
    show(h.slice(5));
  });

  shut.addEventListener("click", close);
  window.addEventListener("keydown", function (e) {
    if (e.key === "Escape" && !frame.hidden) close();
  });

  // The splash screen draws plates and faces too, by the names they have in
  // docs/. It draws them by writing HTML, and an <img> in written HTML is
  // asking for its picture before the line that wrote it has finished - too
  // early to go round afterwards putting the pictures in, and the panel throws
  // away a plate whose picture did not come. So the names are exchanged in the
  // text, on the way in, and nothing is ever asked for that is not here.
  //
  // This has to be standing before the first module runs, which is why the
  // book is assembled above the game rather than below it.
  var html = Object.getOwnPropertyDescriptor(Element.prototype, "innerHTML");
  Object.defineProperty(Element.prototype, "innerHTML", {
    configurable: true,
    enumerable: html.enumerable,
    get: html.get,
    set: function (v) {
      html.set.call(this, typeof v === "string"
        ? v.replace(/docs\/((?:art|faces)\/[A-Za-z0-9._-]+\.jpg)/g,
                    function (m, k) { return ART[k] || m; })
        : v);
    },
  });
})();
</script>
JS
}

expand() {
  while IFS= read -r line; do
    case $line in
      @@CSS@@)  emit_css ;;
      @@JS@@)   emit_js ;;
      @@BOOK@@) emit_book ;;
      *)        printf '%s\n' "$line" ;;
    esac
  done < "$TMP/page"
}

# --- out --------------------------------------------------------------------
#
# The names come out of the finished page rather than out of each piece on its
# way in, because the point of them is that they agree with each other. The
# pictures are safe from it: a name has a space or a hyphen in it and base64
# has neither.
#
# Assembled to a file and then read back rather than piped, so that a failure
# anywhere in it is a failure rather than a short page: an export that stopped
# two thirds of the way through the chapters would still open, still play, and
# still look finished.

expand > "$TMP/out"

WHO='real names'
if [ "$NAMES" != 1 ]; then
  redaction > "$TMP/redaction.sed"
  # Twice: a word-boundary match written as "a character either side" eats the
  # character, so two names with only one character between them need a second
  # look. Nothing a pass produces is something a pass matches, so a third would
  # find nothing.
  sed -f "$TMP/redaction.sed" "$TMP/out" |
    sed -f "$TMP/redaction.sed" > "$TMP/redacted" ||
    die "the names could not be taken out, so nothing is being written"

  # Changing a name cannot change how many lines there are. If it did, the
  # substitution is not the only thing that happened, and what is on disk is
  # the part that survived.
  before=$(wc -l < "$TMP/out" | tr -d ' ')
  after=$(wc -l < "$TMP/redacted" | tr -d ' ')
  [ "$before" = "$after" ] ||
    die "redaction lost $((before - after)) of $before lines - refusing to write half a page"

  mv "$TMP/redacted" "$TMP/out"
  WHO="$(pilots | wc -l | tr -d ' ') pilots as initials"
fi

if [ "$OUT" = "-" ]; then
  cat "$TMP/out"
else
  cp "$TMP/out" "$OUT"
  printf 'export: %s, %s bytes, %s modules, %s, %s\n' \
    "$OUT" "$(wc -c < "$OUT" | tr -d ' ')" \
    "$(printf '%s\n' "$MODULES" | wc -l | tr -d ' ')" \
    "$([ "$BOOK" = 1 ] && echo 'book and all' || echo 'no book')" \
    "$WHO" >&2
fi
