#!/bin/sh
# ---------------------------------------------------------------------------
# docs.sh - the notes, rendered.
#
# The book (tools/chronicle.sh) tells you what happened. The notes tell you how
# the thing works: the README, the golden rules, the architecture map, the
# rankings, the brief the referee reads. All markdown, all perfectly readable
# in a clone - and completely unreadable at a URL, where a browser hands a .md
# file over as plain text and walks away.
#
# So this renders them, into docs/, in the same clothes the book wears.
#
#   tools/docs.sh              write every note into docs/
#   tools/docs.sh --check      say what would change, write nothing
#   tools/docs.sh --staged     render the notes as the index has them, not the
#                              working tree - what a commit hook wants
#   tools/docs.sh --list       every path this tool owns, one per line
#
# A note is only written when what it renders to differs from what is already
# on disk, so a run that changes nothing touches nothing and says so.
#
# Which notes? The ones the README links to, plus the README. That is the
# front door of this project and it already names its own contents, so a note
# nobody links to is a note nobody was going to read - and a new one joins the
# set the moment somebody mentions it from the front page.
#
# The markdown is converted here rather than by a library, for the same reason
# there is no library anywhere else in this repository (GR2). It handles what
# these files actually use - headings, paragraphs, lists, tables, fenced code,
# quotes, rules, links, images, bold, italic, inline code - and nothing else.
# If somebody writes markdown it does not know, the worst case is that the
# construct arrives on the page as the literal characters they typed, which is
# a bad paragraph rather than a broken site.
#
# Links are rewritten, because the notes move: a note written at the top of the
# repository ends up one directory down in docs/, and anything it pointed at
# has to be pointed at again from there. A link to another .md becomes a link
# to the page this script makes out of it.
#
# Everything here is generated and nothing here is hand-edited. Both the pages
# and docs/notes.css are written from scratch on every run, so the way to
# change how a note looks is to change this file.
# ---------------------------------------------------------------------------
set -eu

die() { printf 'docs: %s\n' "$1" >&2; exit 1; }

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

CHECK=0
LIST=0
STAGED=0
while [ $# -gt 0 ]; do
  case $1 in
    --check)   CHECK=1 ;;
    --list)    LIST=1 ;;
    --staged)  STAGED=1 ;;
    -h|--help) sed -n '3,34p' "$0" | sed 's/^#\{1,\} \{0,1\}//'; exit 0 ;;
    *)         die "unknown argument: $1 (try --help)" ;;
  esac
  shift
done

OUT=docs
[ -d "$OUT" ] || die "no $OUT/ here - run this from the repository"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT INT HUP TERM
mkdir -p "$TMP/src"

# The text of a note as it will be committed. --staged reads it out of the
# index rather than off the disk, so a hook renders the pages that belong to
# the commit being made and not to whatever else is lying about unstaged. It
# is the same distinction the referee draws, for the same reason.
materialize() {  # $1 = path in the repository -> prints a path to its text
  m="$TMP/src/$(printf '%s' "$1" | tr / _)"
  if [ -f "$m" ]; then printf '%s' "$m"; return 0; fi
  if [ "$STAGED" = 1 ] && git show ":$1" > "$m" 2>/dev/null; then
    :
  elif [ -f "$1" ]; then
    cp "$1" "$m"
  else
    die "$1 is neither staged nor here"
  fi
  printf '%s' "$m"
}

# --- which notes -----------------------------------------------------------
# The README, then everything it links to that is markdown, in the order it
# mentions them. Anything named twice is rendered once.

{
  printf 'README.md\n'
  grep -oE '\]\([^)]*\.md\)' "$(materialize README.md)" | sed 's/^](//; s/)$//'
} | awk '!seen[$0]++' > "$TMP/set"

while IFS= read -r f; do
  materialize "$f" > /dev/null
done < "$TMP/set"

# docs/ARCHITECTURE.md -> architecture, GOLDEN_RULES.md -> golden-rules
slug_of() {
  printf '%s' "${1##*/}" | sed 's/\.md$//' | tr 'A-Z_' 'a-z-'
}

# The first "# " heading, which is what the note calls itself.
title_of() {
  sed -n 's/^# \{1,\}//p' "$1" | head -1
}

# Every path this tool owns, which is what the referee has to know in order to
# leave them alone. Derived like the rest of this, so it cannot go stale.
if [ "$LIST" = 1 ]; then
  printf '%s/notes.css\n' "$OUT"
  while IFS= read -r f; do
    printf '%s/%s.html\n' "$OUT" "$(slug_of "$f")"
  done < "$TMP/set"
  exit 0
fi

# --- the nav that every note carries ---------------------------------------

# sh has no local variables, and this runs inside the loop that writes the
# pages - so every name in here is its own, or it would eat the caller's.
nav_for() {  # $1 = slug of the page being written
  printf '<nav class="flip" aria-label="the notes">\n'
  while IFS= read -r nav_f; do
    nav_s=$(slug_of "$nav_f")
    # The file's own name, not its heading: the README and the brief both call
    # themselves after the game, and two identical entries is not a contents.
    nav_t=$(printf '%s' "$nav_s" | tr 'a-z-' 'A-Z ')
    if [ "$nav_s" = "$1" ]; then
      printf '<span class="here">%s</span>\n' "$nav_t"
    else
      printf '<a href="%s.html">%s</a>\n' "$nav_s" "$nav_t"
    fi
  done < "$TMP/set"
  printf '<a class="out" href="index.html">THE CHRONICLE</a>\n'
  printf '<a class="out" href="../index.html">PLAY</a>\n'
  printf '</nav>\n'
}

# --- markdown -> html ------------------------------------------------------
#
# Block structure first, one line at a time; the inline pass runs on whatever
# text each block ends up holding. Code spans are lifted out before anything
# else touches a line and put back last, so a `*` or a `<` inside backticks
# arrives on the page as a `*` or a `<`.

render() {  # $1 = markdown file, $2 = directory it lives in ("" = repo root)
  awk -v srcdir="$2" '
    function esc(s) {
      gsub(/&/, "\\&amp;", s); gsub(/</, "\\&lt;", s); gsub(/>/, "\\&gt;", s)
      return s
    }
    function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }

    # A note that was written at the top of the repository is being read from
    # docs/, so everything it points at has moved one directory further away -
    # except the things that were already in docs/, which have arrived.
    function relink(u,   base) {
      if (u ~ /^([a-z]+:|#|\/)/) return u
      if (u ~ /\.md$/) {
        base = u; sub(/.*\//, "", base); sub(/\.md$/, "", base)
        return tolower(gensub_(base)) ".html"
      }
      if (srcdir == "") {
        if (u ~ /^docs\//) { sub(/^docs\//, "", u); return u }
        return "../" u
      }
      return u
    }
    function gensub_(s) { gsub(/_/, "-", s); return s }

    function slug(s) {
      s = tolower(s); gsub(/[^a-z0-9]+/, "-", s)
      sub(/^-+/, "", s); sub(/-+$/, "", s); return s
    }

    # <b> and <i>, by pairs of delimiters rather than by backreference, which
    # awk does not have. An unpaired delimiter is left exactly as typed.
    function pairs(s, d, tag,   dl, a, b, out) {
      dl = length(d); out = ""
      while (1) {
        a = index(s, d); if (!a) break
        b = index(substr(s, a + dl), d); if (!b) break
        out = out substr(s, 1, a - 1) "<" tag ">" substr(s, a + dl, b - 1) "</" tag ">"
        s = substr(s, a + dl + b - 1 + dl)
      }
      return out s
    }

    function anchors(s,   out, whole, p, txt, url, img) {
      out = ""
      while (match(s, /!?\[[^]]*\]\([^)]*\)/)) {
        whole = substr(s, RSTART, RLENGTH)
        out = out substr(s, 1, RSTART - 1)
        s = substr(s, RSTART + RLENGTH)
        img = (substr(whole, 1, 1) == "!")
        if (img) whole = substr(whole, 2)
        p = index(whole, "](")
        txt = substr(whole, 2, p - 2)
        url = relink(substr(whole, p + 2, length(whole) - p - 2))
        if (img) out = out "<img src=\"" url "\" alt=\"" txt "\" loading=\"lazy\" decoding=\"async\">"
        else     out = out "<a href=\"" url "\">" txt "</a>"
      }
      return out s
    }

    function inline(s,   n, i, code, m) {
      s = esc(s)
      n = 0
      while (match(s, /`[^`]+`/)) {
        n++
        code[n] = substr(s, RSTART + 1, RLENGTH - 2)
        s = substr(s, 1, RSTART - 1) SUBSEP n SUBSEP substr(s, RSTART + RLENGTH)
      }
      s = anchors(s)
      s = pairs(s, "**", "b")
      s = pairs(s, "*", "i")
      for (i = 1; i <= n; i++) {
        m = SUBSEP i SUBSEP
        while (index(s, m)) {
          s = substr(s, 1, index(s, m) - 1) "<code>" code[i] "</code>" \
              substr(s, index(s, m) + length(m))
        }
      }
      return s
    }

    function endpara() { if (para) { print "</p>"; para = 0 } }
    function endlist()  { if (list)  { print "</li></" list ">"; list = "" } }
    function endquote() { if (quote) { print "</blockquote>"; quote = 0 } }
    function endtable(  i, j, n, cells, tag) {
      if (!rows) return
      print "<div class=\"scroll\"><table>"
      for (i = 1; i <= rows; i++) {
        if (i == 2 && row[i] ~ /^[ |:-]+$/) continue
        tag = (i == 1) ? "th" : "td"
        if (i == 1) print "<thead>"
        if (i == 3) print "<tbody>"
        n = split(row[i], cells, "|")
        printf "<tr>"
        for (j = 1; j <= n; j++) {
          if (j == 1 && trim(cells[j]) == "") continue
          if (j == n && trim(cells[j]) == "") continue
          printf "<%s>%s</%s>", tag, inline(trim(cells[j])), tag
        }
        print "</tr>"
        if (i == 1) print "</thead>"
      }
      if (rows >= 3) print "</tbody>"
      print "</table></div>"
      rows = 0
    }
    function endall() { endpara(); endlist(); endquote(); endtable() }

    /^```/ {
      if (fence) { print "</code></pre>"; fence = 0 }
      else {
        endall(); fence = 1
        lang = trim(substr($0, 4))
        printf "<pre><code%s>\n", lang ? " class=\"lang-" lang "\"" : ""
      }
      next
    }
    fence { print esc($0); next }

    /^[ \t]*$/ { endall(); next }

    /^#{1,6} / {
      endall()
      n = index($0, " ") - 1
      t = substr($0, n + 2)
      printf "<h%d id=\"%s\">%s</h%d>\n", n, slug(t), inline(t), n
      next
    }

    /^(---+|===+|\*\*\*+)[ \t]*$/ { endall(); print "<hr>"; next }

    /^\|/ { endpara(); endlist(); endquote(); row[++rows] = $0; next }

    /^> ?/ {
      endpara(); endlist(); endtable()
      if (!quote) { print "<blockquote>"; quote = 1 }
      t = $0; sub(/^> ?/, "", t)
      print "<p>" inline(t) "</p>"
      next
    }

    /^[-*] / {
      endpara(); endquote(); endtable()
      if (list && list != "ul") endlist()
      if (!list) { print "<ul>"; list = "ul" }
      else print "</li>"
      printf "<li>%s", inline(substr($0, 3))
      next
    }

    /^[0-9]+\. / {
      endpara(); endquote(); endtable()
      if (list && list != "ol") endlist()
      if (!list) { print "<ol>"; list = "ol" }
      else print "</li>"
      printf "<li>%s", inline(substr($0, index($0, ". ") + 2))
      next
    }

    # A wrapped continuation of whatever is open - a list item that ran long,
    # or a paragraph. Markdown says the indent belongs to the item above it.
    list && /^[ \t]+[^ \t]/ { printf " %s", inline(trim($0)); next }

    {
      endquote(); endtable()
      if (!para) { print "<p>"; para = 1 }
      print inline($0)
    }

    END { if (fence) print "</code></pre>"; endall() }
  ' "$1"
}

# awk without gensub is the common case, so the one substitution that needed it
# is done above by hand. Nothing here uses a GNU extension.

# --- the stylesheet, written with the pages ---------------------------------

write_css() {
  cat <<'CSS'
/* Written by tools/docs.sh. The notes, wearing the book's clothes.
   Do not edit: every run of the tool writes this file from scratch. */
html, body { height: auto; overflow: visible; }
body {
  user-select: text;
  -webkit-user-select: text;
  line-height: 1.65;
  font-size: 15px;
  padding: 0 1.2rem 6rem;
}
main { max-width: 46rem; margin: 0 auto; position: relative; z-index: 1; }

.plate {
  display: flex; justify-content: space-between; align-items: baseline;
  gap: 1rem; flex-wrap: wrap;
  margin: 3.5rem 0 2.5rem; padding-bottom: .6rem;
  border-bottom: 1px solid color-mix(in srgb, var(--violet) 45%, transparent);
  font-size: .72rem; letter-spacing: .22em; text-transform: uppercase;
}
.plate .kind { color: var(--magenta); }
.plate .of   { color: var(--dim); }

h1, h2, h3, h4, h5, h6 { line-height: 1.25; scroll-margin-top: 2rem; }
h1 {
  font-size: clamp(1.9rem, 6vw, 3rem); letter-spacing: .04em;
  margin: 1.5rem 0 2rem; color: var(--amber);
}
h2 {
  font-size: 1.15rem; letter-spacing: .16em; text-transform: uppercase;
  margin: 3rem 0 1rem; color: var(--cyan);
}
h3 { font-size: 1rem; letter-spacing: .08em; margin: 2rem 0 .75rem; color: var(--lime); }
h4, h5, h6 { font-size: .95rem; margin: 1.5rem 0 .5rem; color: var(--dim); }

p, ul, ol, blockquote, pre, .scroll { margin: 0 0 1.1rem; }
ul, ol { padding-left: 1.4rem; }
li { margin: .35rem 0; }
li::marker { color: var(--violet); }

a { color: var(--cyan); text-underline-offset: 3px; }
a:hover { color: var(--magenta); }

b, strong { color: var(--ink); }
i, em { color: var(--dim); font-style: italic; }

code {
  font-size: .88em; color: var(--lime);
  background: color-mix(in srgb, var(--violet) 16%, transparent);
  padding: .1em .35em; border-radius: 3px;
}
pre {
  background: color-mix(in srgb, var(--violet) 10%, transparent);
  border-left: 2px solid var(--violet);
  padding: .9rem 1rem; overflow-x: auto;
}
pre code { background: none; padding: 0; color: var(--ink); }

blockquote {
  border-left: 2px solid var(--magenta);
  padding: .2rem 0 .2rem 1rem; color: var(--dim);
}
blockquote p { margin: 0; }

hr { border: 0; border-top: 1px dashed color-mix(in srgb, var(--dim) 50%, transparent); margin: 2.5rem 0; }

img { max-width: 100%; height: auto; display: block; margin: 1.5rem 0; border-radius: 2px; }

.scroll { overflow-x: auto; }
table { border-collapse: collapse; width: 100%; font-size: .9rem; }
th, td { text-align: left; padding: .5rem .8rem; vertical-align: top; border-bottom: 1px solid color-mix(in srgb, var(--dim) 25%, transparent); }
th { color: var(--cyan); font-weight: normal; letter-spacing: .12em; text-transform: uppercase; font-size: .72rem; }

.flip {
  display: flex; flex-wrap: wrap; gap: .4rem 1.2rem; align-items: baseline;
  margin-top: 4rem; padding-top: 1rem;
  border-top: 1px solid color-mix(in srgb, var(--violet) 45%, transparent);
  font-size: .72rem; letter-spacing: .16em; text-transform: uppercase;
}
.flip .here { color: var(--amber); }
.flip .out  { margin-left: auto; color: var(--lime); }
.flip .out:hover { color: var(--magenta); }

@media (max-width: 34rem) {
  body { font-size: 14px; padding: 0 .9rem 4rem; }
  .flip .out { margin-left: 0; }
}
CSS
}

# --- write ------------------------------------------------------------------

changed=0
report() {  # $1 = path, $2 = candidate file
  if [ -f "$1" ] && cmp -s "$2" "$1"; then return 0; fi
  changed=$((changed + 1))
  [ "$CHECK" = 1 ] && { printf 'would write %s\n' "$1"; return 0; }
  cp "$2" "$1"
  printf 'wrote %s\n' "$1"
}

write_css > "$TMP/notes.css"
report "$OUT/notes.css" "$TMP/notes.css"

while IFS= read -r f; do
  src=$(materialize "$f")
  s=$(slug_of "$f")
  t=$(title_of "$src")
  [ -n "$t" ] || t=$(printf '%s' "$s" | tr 'a-z-' 'A-Z ')
  d=${f%/*}
  [ "$d" = "$f" ] && d=""

  {
    printf '<!doctype html>\n<html lang="en"><head><meta charset="utf-8">\n'
    printf '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
    # The README calls itself after the game, so it would otherwise say it twice.
    if [ "$t" = "ASTEROIDS // HYPERCOLOR" ]; then
      printf '<title>%s</title>\n' "$t"
    else
      printf '<title>%s &mdash; ASTEROIDS // HYPERCOLOR</title>\n' "$t"
    fi
    printf '<link rel="stylesheet" href="../styles/tokens.css">\n'
    printf '<link rel="stylesheet" href="../styles/crt.css">\n'
    printf '<link rel="stylesheet" href="notes.css">\n'
    printf '</head><body class="notes">\n'
    printf '<div class="crt vignette"></div>\n'
    printf '<div class="crt scanlines"></div>\n'
    printf '<div class="crt roll"></div>\n'
    printf '<main>\n'
    printf '<header class="plate"><span class="kind">THE NOTES</span>'
    printf '<span class="of">%s</span></header>\n' "$f"
    render "$src" "$d"
    nav_for "$s"
    printf '</main>\n</body></html>\n'
  } > "$TMP/page"

  report "$OUT/$s.html" "$TMP/page"
done < "$TMP/set"

if [ "$CHECK" = 1 ]; then
  [ "$changed" = 0 ] && printf 'the notes are up to date.\n'
  exit 0
fi
notes=$(wc -l < "$TMP/set" | tr -d ' ')
printf 'docs: %s note%s, %s file%s written.\n' \
  "$notes"   "$([ "$notes" = 1 ]   || printf s)" \
  "$changed" "$([ "$changed" = 1 ] || printf s)"
