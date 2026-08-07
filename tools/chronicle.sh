#!/bin/sh
# ---------------------------------------------------------------------------
# chronicle.sh - the book, and the numbers it counts.
#
# A version is a commit that changed the game: index.html, src/ or styles/, the
# files that ship in the page you open. Nothing else in this repository is the
# game. Rewriting the rules, regenerating this book, fixing a line in the
# README - real work, all of it, but the cabinet is the same cabinet
# afterwards, and the next pilot has nothing new to find out by playing. So it
# does not get a version. It gets a mention.
#
# The numbers are counted, never stored: v1 is the first commit that touched
# the game and the newest is however many there have been since. Nobody assigns
# them, nobody can skip one, and a clone that never installed the hooks arrives
# at exactly the same numbers as everybody else. That is the point - the
# version is a fact about the history, not a file somebody has to remember to
# bump.
#
# Every version also carries a tagline, one line on what happened to the game.
# tools/tagline.sh writes it and docs/taglines.tsv keeps it, once, for good.
#
# The book is one page per version. docs/index.html is the cover - the roster,
# then every entry in order, newest first. docs/v<N>.html is the chapter, and it
# is a page rather than a paragraph: the tagline in letters you can read from
# across the room, the numbers that version made, and a picture of the commit
# itself. Both are generated, both are committed, and a page stands on its own -
# somebody who has never cloned this can be handed a link to v7.
#
# The picture is not decoration and it is not the same picture twice. Every rock
# is a sector the commit touched, sized by how much of it moved and coloured by
# which part of the cabinet it was; a dashed one left the repository; the pilot
# is underneath taking a shot at the biggest thing they moved. The seed is the
# commit hash, so a version draws the identical field on every machine and in
# every clone, forever. That is what makes a generated file worth committing:
# rebuild it anywhere and the bytes come back the same.
#
# A chapter can also carry a plate: a painted scene of whatever its tagline says
# happened, asked for once by tools/chronicle-art.sh and kept in docs/art/ from
# then on. That one is not arithmetic and could not be - it is asked for on one
# machine, by somebody who has credentials, and committed like any other picture
# in any other book. Which is why nothing here depends on it: a version with no
# plate has the drawn field and the chapter reads exactly as it did before.
#
# The pilots have faces for the same reason and by the same route, out of
# docs/faces/ and asked for by the same script. A face belongs to a person
# rather than to a commit, so it turns up in all three places this book writes
# somebody's name - the roster on the cover, the line under each version in the
# contents, and the head of every chapter they flew - and it is the identical
# picture in each, because it was only ever painted once. A pilot with no face
# reads as a name, exactly as everybody did before there were any.
#
# The cabinet reads the book too. docs/chronicle.js is the last thing written
# here: the newest chapter, the last few plates and the top of the board, in
# the one shape a page can read without fetching anything (GR2). The splash
# screen draws its doorway out of that file and does without it when a clone
# has never run this tool, exactly as it does without the faces.
#
#   tools/chronicle.sh                rewrite docs/index.html
#   tools/chronicle.sh --version      the version on the cabinet now
#   tools/chronicle.sh --next         the version the next commit becomes, or
#                                     "-" if what is staged leaves the game alone
#   tools/chronicle.sh --recent N     plain text digest of the last N commits
#   tools/chronicle.sh --moved [rev]  quietly: did that touch the game?
#   tools/chronicle.sh --game-paths   what counts as the game, one path a line
#
# What a commit can put in the book, all optional, all read from the message:
#
#   Chronicle: a line for the book, written for a reader, not a reviewer
#   Tagline: what happened to the game, in one line, instead of the machine's
#   Golden-Rule-Override: GR4 - <why>      recorded forever, as agreed
#   Rule-Change: <why>                     recorded forever, as agreed
#   Tally: <pilot> - <n>                   not written by a pilot at all: the
#                                          hooks put it on the ledger commit
#                                          they land after somebody bends a
#                                          rule, and the book quotes it
#
# And one thing a commit cannot keep out. Every version is re-refereed as the
# book is written, against the rules that can be proved from the commit alone:
# GR6, GR10, GR11. Break one of those and write no override line and the commit
# could not have got past the referee at all - which means somebody turned the
# referee off. That gets an entry too, in the chapter and in the roster, and it
# is the one line in the book that nobody chose to write.
#
# The arithmetic is the referee's own, deliberately in its forgiving form:
# docs/ is generated and never counts against anybody, and anywhere this check
# and tools/golden-check.sh could disagree, this one stays quiet. The book may
# miss a cheat. It may not invent one.
#
# The book speaks asteroid, not git. The numbers come off the history, but a
# chapter is read for fun, so nothing in it says "files changed" or
# "insertions" when it can say what happened to the field instead:
#
#   commit          -> a version, flown by a pilot
#   files changed   -> sectors touched
#   insertions      -> lines aboard
#   deletions       -> lines jettisoned
#   the subject     -> landed as "..."
#   no Chronicle:   -> nobody wrote this one down
#   not a version   -> an interlude: while vN was on the cabinet, ...
#
# The one exception is machinery somebody has to type: the checkout command
# under each chapter stays literal, because a joke you cannot paste into a
# terminal is not worth the confusion. Nothing else explains itself - the book
# is a book, and how it got written is this file's business, not the reader's.
# Keep new vocabulary in the same register as the rest of the project - dry,
# and no exclamation marks.
# ---------------------------------------------------------------------------
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$ROOT" || exit 0

# The game is what ships in the page you open. Everything else is scaffolding
# around the cabinet, and scaffolding does not get a version number. This list
# is the only definition; tools/tagline.sh and the hooks ask for it rather than
# keeping a second copy that can drift.
GAME='index.html src styles'

git rev-parse --verify -q HEAD >/dev/null 2>&1 || { echo "no history yet" >&2; exit 0; }

# How many versions deep the history is. --full-history so that path limiting
# does not quietly simplify a version out of the count.
TOTAL=$(git rev-list --count --full-history --no-merges HEAD -- $GAME)

# Did this commit touch the game? With no argument: will the next one?
moved() {
  if [ -n "${1:-}" ]; then
    [ -n "$(git diff-tree --root -r --name-only --no-commit-id "$1" -- $GAME 2>/dev/null)" ]
  elif [ -n "$(git diff --cached --name-only HEAD 2>/dev/null)" ]; then
    # Something is staged, so the index is the question being asked - which is
    # also the case inside the hooks, including for git commit -a.
    [ -n "$(git diff --cached --name-only HEAD -- $GAME 2>/dev/null)" ]
  else
    # Nobody is committing; a pilot is asking mid-flight. Answer about the
    # worktree, untracked files included - a brand new feature is a file git
    # has never heard of.
    [ -n "$(git status --porcelain -- $GAME 2>/dev/null)" ]
  fi
}

case "${1:-}" in
  --game-paths) printf '%s\n' $GAME; exit 0 ;;
  --moved)      moved "${2:-}"; exit $? ;;
  --version)    printf 'v%s\n' "$TOTAL"; exit 0 ;;
  --next)
    if moved; then printf 'v%s\n' "$((TOTAL + 1))"; else printf -- '-\n'; fi
    exit 0 ;;
esac

# The taglines, folded into the same stream the log comes down, so awk can read
# them without having to open a second file in the middle of a record.
taglines() {
  [ -f docs/taglines.tsv ] || return 0
  awk -F'\t' 'NF >= 2 && $1 !~ /^#/ { printf "\036TAG\037%s\037%s", $1, $2 }' docs/taglines.tsv
}

# Who created each event file, folded into the stream the same way. GR11 is
# ownership per file and the book has to arrive at the same answer the referee
# did, so this is tools/golden-check.sh's owner_of, verbatim: whoever's commit
# first added the file.
owners() {
  git log --diff-filter=A --pretty=format: --name-only --no-renames \
          -- 'src/events/*.js' 2>/dev/null \
    | sort -u \
    | while IFS= read -r f; do
        [ -n "$f" ] || continue
        o=$(git log --follow --diff-filter=A --format='%an' -- "$f" 2>/dev/null | tail -1)
        [ -n "$o" ] && printf '\036OWN\037%s\037%s' "$f" "$o"
      done
}

# The painted plates, folded in the same way again: commit, file, and the line
# the plate is a picture of. A plate whose file has gone missing is not
# mentioned, because a chapter with a broken picture in it is worse than a
# chapter with none - and tools/chronicle-art.sh will paint it again anyway.
plates() {
  [ -f docs/art/index.tsv ] || return 0
  awk -F'\t' 'NF >= 3 && $1 !~ /^#/ {
    if ((getline junk < ("docs/art/" $2)) >= 0) {
      close("docs/art/" $2)
      printf "\036ART\037%s\037%s\037%s", $1, $2, $3
    }
  }' docs/art/index.tsv
}

# The pilots' faces, folded in the same way once more: a name, and the picture
# that belongs to it from now on. Same missing-file rule as the plates, for the
# same reason - except that this one will not be repainted, so a face whose file
# has gone is a name that simply reads as a name again.
faces() {
  [ -f docs/faces/index.tsv ] || return 0
  awk -F'\t' 'NF >= 2 && $1 !~ /^#/ {
    if ((getline junk < ("docs/faces/" $2)) >= 0) {
      close("docs/faces/" $2)
      printf "\036FACE\037%s\037%s", $1, $2
    }
  }' docs/faces/index.tsv
}

# One record per commit: header fields, then the raw diff, then the numstat.
# --raw is there for one letter: D. A deleted file and a file that only lost
# lines are the same two numbers, and GR6 counts one of them and not the other.
#
# %at rides along because a page says how long the cabinet waited for it, and
# the gap between two versions is arithmetic nothing else in here can do.
history() {
  git log --format='%x1e%H%x1f%an%x1f%ad%x1f%s%x1f%at%x1f%b' \
          --date=format:"$1" --raw --numstat --no-renames --no-merges ${2:+-n "$2"}
}

# Shared by the book and the digest: which parts of the cabinet a path is in,
# and therefore whether the commit that touched it was a version at all.
#
# is_referee is the same list tools/golden-check.sh keeps, because the audit
# below accuses people of breaking GR10 and an accusation has to use the
# referee's own definition or it is just an opinion.
LIB='
function is_game(p) { return (p == "index.html" || p ~ /^src\// || p ~ /^styles\//) }
function is_book(p) {
  return (p == "docs/index.html" || p == "docs/chronicle.css" ||
          p == "docs/chronicle.js" || p == "docs/chronicle-song.js" ||
          p == "docs/taglines.tsv" || p ~ /^docs\/v[0-9]+\.html$/ ||
          p ~ /^docs\/art\// || p ~ /^docs\/faces\//)
}
function is_stat(l) { return (l ~ /^(-|[0-9]+)\t(-|[0-9]+)\t./) }
function is_raw(l)  { return (l ~ /^:[0-7]+ [0-7]+ [0-9a-f]+ [0-9a-f]+ [A-Z]/) }
function is_referee(p) {
  return (p == "CLAUDE.md" || p == "GOLDEN_RULES.md" || p == ".gitattributes" ||
          p == ".env.example" || p ~ /^tools\// || p ~ /^\.githooks\// ||
          p == ".claude/settings.json" || p ~ /^\.claude\/skills\//)
}
'

case "${1:-}" in
  --recent)
    n=${2:-5}
    { taglines; history '%d %b %Y' "$n"; } \
      | awk -v RS='\036' -v FS='\037' -v ver="$TOTAL" "$LIB"'
          $1 == "TAG" { tag[$2] = $3; next }
          NF < 4 { next }
          {
            game = 0; line = ""; mode = 0
            n = split($6, b, "\n")
            for (k = 1; k <= n; k++) {
              if (is_stat(b[k])) { split(b[k], ns, "\t"); if (is_game(ns[3])) game = 1; mode = 0; continue }
              if (tolower(b[k]) ~ /^[[:space:]]*chronicle:/) {
                sub(/^[^:]*:[[:space:]]*/, "", b[k]); line = b[k]; mode = 1
              } else if (mode && b[k] ~ /^[[:space:]]+[^[:space:]]/) {
                sub(/^[[:space:]]+/, "", b[k]); line = line " " b[k]
              } else mode = 0
            }
            # The pilot wrote it, or the tagline says it, or the subject has to do.
            if (line == "" && game && $1 in tag) line = tag[$1]
            if (line == "") line = $4
            printf "  %-5s %-16s %s\n", (game ? "v" ver : "--"), $2, line
            if (game) ver--
          }'
    exit 0 ;;
esac

# The rules bind from the commit that wrote them down, and not one commit
# earlier. Everything older than GOLDEN_RULES.md was flown before there was
# anything to break, and the audit below leaves it alone - including the commit
# that brought the rules, which no referee could have been running for either.
# Empty means the rules are not in the history yet and nobody is being judged.
RULES=$(git log --diff-filter=A --format='%H' --no-renames -- GOLDEN_RULES.md 2>/dev/null | tail -1)

# Every version that does not have a line yet gets one now. This is what makes
# the whole arrangement work for a pilot who never ran --install: the hooks are
# a convenience, and a rebuild is the repair.
sh tools/tagline.sh --backfill >/dev/null 2>&1 || true

# And every version that has no plate yet gets asked for one - after the
# taglines, because the tagline is what the plate is a picture of. It is capped,
# it keeps what it painted, and it exits without a word on a machine that has no
# credentials for it, which is most of them. Nothing below waits on the result.
[ -n "${ASTEROIDS_NO_ART:-}" ] || sh tools/chronicle-art.sh --auto 2>/dev/null || true

mkdir -p docs

# Every page is written fresh on every rebuild, so a chapter somebody deleted
# comes back and a chapter for a version that no longer exists does not.
rm -f docs/v[0-9]*.html

{ taglines; owners; plates; faces; history '%d %B %Y|%H:%M'; } \
  | awk -v RS='\036' -v FS='\037' -v total="$TOTAL" -v rules="$RULES" "$LIB"'
function esc(s) { gsub(/&/,"\\&amp;",s); gsub(/</,"\\&lt;",s); gsub(/>/,"\\&gt;",s); return s }
function att(s) { s = esc(s); gsub(/"/, "\\&quot;", s); return s }
function plural(n) { return n == 1 ? "" : "s" }
# A pilot, wherever their name is written. Painted once by tools/chronicle-art.sh
# and kept from then on, so it is the same face on the cover, in the contents and
# at the top of every chapter they flew - which is the whole point of it being
# painted once. Empty for a pilot who has none, and every place this is used
# reads the same with nothing in it.
#
# alt is deliberately empty: the name is always right beside the picture, and a
# screen reader announcing it twice is worse than not announcing it at all.
function face(p,   f) {
  f = mug[p]
  if (f == "") return ""
  return "<img class=\"face\" src=\"faces/" f "\" alt=\"\" loading=\"lazy\" decoding=\"async\">"
}
function ord(n,   t) {
  t = n % 100
  if (t >= 11 && t <= 13) return n "th"
  t = n % 10
  return n (t == 1 ? "st" : (t == 2 ? "nd" : (t == 3 ? "rd" : "th")))
}
function roman(n,   v,s,i,out) {
  split("1000,900,500,400,100,90,50,40,10,9,5,4,1", v, ",")
  split("M,CM,D,CD,C,XC,L,XL,X,IX,V,IV,I", s, ",")
  out = ""
  for (i = 1; i <= 13; i++) while (n >= v[i] + 0) { out = out s[i]; n -= v[i] }
  return out
}
# --- the picture ------------------------------------------------------------
# A version draws its own diff. The seed is the commit hash and every number
# after that is arithmetic, so the same version draws the identical field on
# every machine and in every clone - which is the only honest way to commit a
# generated image. Park-Miller rather than rand(), because rand() is seeded
# differently by every awk there is and the book would churn on every rebuild.
function seed(h,   i, c, x) {
  S = 0
  for (i = 1; i <= 12; i++) {
    c = substr(h, i, 1)
    x = index("0123456789abcdef", c) - 1
    if (x < 0) x = 0
    S = (S * 16 + x) % 2147483647
  }
  if (S <= 0) S += 2147483646
}
function rnd() { S = (S * 16807) % 2147483647; return S / 2147483647 }
function rr(a, b) { return a + (b - a) * rnd() }
function f1(x)    { return sprintf("%.1f", x) }

# Which part of the cabinet a path belongs to, and what colour that part is.
# The tokens are the ones styles/tokens.css hands the game, so the day somebody
# changes the spectrum the whole book turns with it.
function sector(p,   q) {
  if (p == "index.html") return "cabinet"
  if (p ~ /^styles\//)   return "styles"
  if (p ~ /^src\//)      return (split(p, q, "/") >= 3 ? q[2] : "src")
  return "outside"
}
function tint(s) {
  if (s == "entities" || s == "events") return "var(--magenta)"
  if (s == "game")                      return "var(--violet)"
  if (s == "render" || s == "input")    return "var(--cyan)"
  if (s == "audio")                     return "var(--amber)"
  if (s == "ui" || s == "styles")       return "var(--lime)"
  # The rules, the hooks, the notes on the cabinet: real work, but not the
  # game, and a rock that is not the game should not be lit like one.
  if (s == "outside")                   return "var(--dim)"
  return "var(--ink)"
}

# The twelve busiest paths of a commit, biggest first, kept as they arrive.
# Twelve because thirteen rocks is a mess to look at, not because git ran out.
function keep(p, n, gone,   i, j, last) {
  for (i = 1; i <= kc; i++) if (n > kn[i]) break
  if (i > 12) return
  last = (kc < 12 ? kc : 11)
  for (j = last; j >= i; j--) { kp[j+1] = kp[j]; kn[j+1] = kn[j]; kd[j+1] = kd[j] }
  kp[i] = p; kn[i] = n; kd[i] = gone
  if (kc < 12) kc++
}

# The tagline is what a page shouts. A version with no tagline at all is a
# clone that has never run the backfill, and the chapter still has to say
# something, so it borrows from further down the page.
function shout(v) { return VT[v] != "" ? VT[v] : (VL[v] != "" ? VL[v] : VS[v]) }

function caption(v,   s) {
  if (RC[v] == 0) return "An empty field. Nothing in this one moved."
  s = RC[v] " rock" plural(RC[v]) ", one for each sector; the heavy one is " RP[v,1]
  if (VF[v] > RC[v]) s = s ", with " (VF[v] - RC[v]) " smaller ones left off the scan"
  return s "."
}

function picture(v,   out, k, K, j, a, c, rb, ang, rad, x, y, r, br, bx, by, pts, mx) {
  seed(VH[v])
  K = RC[v]
  mx = (RM[v] > 0 ? RM[v] : 1)
  a = rr(0, 6.28318)
  # The field is drawn to fill the frame whether the commit touched one sector
  # or twelve: fewer rocks means they stand further apart and each one is
  # bigger, so a one-file version is a close-up rather than a lonely speck.
  c = 300 / sqrt(K > 0 ? K : 1)
  if (c > 200) c = 200
  if (c < 92)  c = 92
  rb = 0.44 * c
  if (rb > 86) rb = 86
  out = "<svg class=\"art\" viewBox=\"0 0 1400 640\" preserveAspectRatio=\"xMidYMid meet\" aria-hidden=\"true\">"
  out = out "<text class=\"ghost\" x=\"46\" y=\"590\">" roman(v) "</text>"
  for (k = 0; k < 64; k++)
    out = out "<circle class=\"star\" cx=\"" int(rr(10, 1390)) "\" cy=\"" int(rr(10, 630)) \
              "\" r=\"" f1(rr(0.7, 2.2)) "\" style=\"--d:-" f1(rr(0, 4)) "s\"/>"
  # A sunflower spiral: the rocks land evenly without anybody having to solve
  # for overlap, and the busiest sector of the commit sits in the middle of it.
  for (k = 1; k <= K; k++) {
    ang = a + k * 2.39996
    rad = c * sqrt(k - 1)
    x = 700 + cos(ang) * rad + rr(-14, 14)
    y = 312 + sin(ang) * rad * 0.72 + rr(-14, 14)
    r = rb * (0.42 + 0.58 * sqrt(RN[v,k] / mx))
    if (k == 1) { bx = x; by = y; br = r }
    pts = ""
    for (j = 0; j < 9; j++) {
      ang = j * 0.6981
      pts = pts f1(x + cos(ang) * r * rr(0.74, 1.2)) "," f1(y + sin(ang) * r * rr(0.74, 1.2)) " "
    }
    out = out "<g class=\"drift\" style=\"--d:-" f1(rr(0, 9)) "s\">"
    out = out "<polygon class=\"rock" (RD[v,k] ? " gone" : "") "\" points=\"" pts \
              "\" style=\"--s:" f1(rr(18, 46)) "s;--c:" tint(sector(RP[v,k])) "\">"
    out = out "<title>" att(RP[v,k]) " &mdash; " RN[v,k] " line" plural(RN[v,k]) "</title></polygon></g>"
  }
  # The pilot, aiming at the biggest thing they moved.
  if (K == 0) { bx = 700; by = 312; br = 0 }
  ang = atan2(by - 556, bx - 140)
  out = out "<line class=\"shot\" x1=\"" f1(140 + cos(ang) * 32) "\" y1=\"" f1(556 + sin(ang) * 32) \
            "\" x2=\"" f1(bx - cos(ang) * (br + 8)) "\" y2=\"" f1(by - sin(ang) * (br + 8)) "\"/>"
  out = out "<g class=\"ship\" transform=\"translate(140,556) rotate(" f1(ang * 57.29578) ")\">"
  out = out "<polygon points=\"30,0 -19,-16 -9,0 -19,16\"/></g>"
  # The three things a chapter cannot keep quiet, stamped across the field
  # rather than footnoted under it.
  if (VU[v] != "") out = out stamp("off", "REFEREE OFF", 1060, 116, -13)
  else if (VO[v] != "") out = out stamp("over", "OVERRIDE", 1060, 116, -13)
  if (VL[v] == "")  out = out stamp("untold", "NO LOG", 330, 140, 9)
  return out "</svg>"
}
function stamp(cls, word, x, y, deg) {
  return "<g class=\"stamp " cls "\" transform=\"translate(" x "," y ") rotate(" deg ")\">" \
         "<rect x=\"-158\" y=\"-36\" width=\"316\" height=\"72\" rx=\"4\"/>" \
         "<text x=\"0\" y=\"12\">" word "</text></g>"
}

# --- the small pictures -----------------------------------------------------
# One glyph per thing the book keeps saying, drawn rather than named, so a cel
# is recognisable before it is read. They are stroked in currentColor and they
# are all on the same 24-square grid, which is the entire trick to them looking
# like one set. No file, no font, no request: a chapter is still one page that
# opens from a stick.
function ico(n,   p) {
  if (n == "bolt")           p = "<path d=\"M13 2 4 14h6l-1 8 9-12h-6z\"/>"
  else if (n == "quote")     p = "<path d=\"M4 4h16v12H10l-6 5z\"/><path d=\"M8 9h8M8 12.5h5\"/>"
  else if (n == "gauge")     p = "<path d=\"M3 18a9 9 0 1 1 18 0\"/><path d=\"M12 18l5.5-6.5\"/><circle cx=\"12\" cy=\"18\" r=\"1.6\"/>"
  else if (n == "target")    p = "<circle cx=\"12\" cy=\"12\" r=\"8.5\"/><circle cx=\"12\" cy=\"12\" r=\"3\"/><path d=\"M12 1.5v3M12 19.5v3M1.5 12h3M19.5 12h3\"/>"
  else if (n == "ship")      p = "<path d=\"M21 12 4 20l4-8-4-8z\"/>"
  else if (n == "up")        p = "<path d=\"M12 20V5M6.5 10.5 12 5l5.5 5.5M4 21h16\"/>"
  else if (n == "down")      p = "<path d=\"M12 4v15M6.5 13.5 12 19l5.5-5.5M4 3h16\"/>"
  else if (n == "clock")     p = "<circle cx=\"12\" cy=\"12\" r=\"9\"/><path d=\"M12 6.5V12l3.5 2.5\"/>"
  else if (n == "cal")       p = "<rect x=\"3\" y=\"5\" width=\"18\" height=\"16\" rx=\"1.5\"/><path d=\"M3 10h18M8 3v4M16 3v4\"/>"
  else if (n == "medal")     p = "<circle cx=\"12\" cy=\"15\" r=\"5.6\"/><path d=\"M8.6 3l2.2 5.6M15.4 3l-2.2 5.6\"/>"
  else if (n == "eye")       p = "<path d=\"M2 12s4.2-6 10-6 10 6 10 6-4.2 6-10 6-10-6-10-6z\"/><path d=\"M3 3l18 18\"/>"
  else if (n == "scroll")    p = "<path d=\"M6.5 3h11v18h-11z\"/><path d=\"M9.5 8h5M9.5 12h5M9.5 16h3\"/>"
  else if (n == "hourglass") p = "<path d=\"M6 3h12M6 21h12M7.5 3v3.5L12 12l4.5-5.5V3M7.5 21v-3.5L12 12l4.5 5.5V21\"/>"
  else if (n == "coin")      p = "<circle cx=\"12\" cy=\"12\" r=\"9\"/><path d=\"M12 6.5v11M9.5 9.5h5M9.5 14.5h5\"/>"
  else if (n == "frame")     p = "<rect x=\"3\" y=\"4.5\" width=\"18\" height=\"15\" rx=\"1.5\"/><path d=\"M3 15.5l4.5-4.5 3.5 3.5 3-3 7 7\"/><circle cx=\"8.5\" cy=\"9\" r=\"1.4\"/>"
  else if (n == "grid")      p = "<rect x=\"3.5\" y=\"3.5\" width=\"7\" height=\"7\"/><rect x=\"13.5\" y=\"3.5\" width=\"7\" height=\"7\"/><rect x=\"3.5\" y=\"13.5\" width=\"7\" height=\"7\"/><rect x=\"13.5\" y=\"13.5\" width=\"7\" height=\"7\"/>"
  else return ""
  return "<svg class=\"ic\" viewBox=\"0 0 24 24\" aria-hidden=\"true\">" p "</svg>"
}

# One number, its glyph and what it counts. data-n is there for the script to
# count up to on the way past; the tile already reads correctly without it,
# because a page that needs JavaScript to say 99 is a worse page.
function tile(name, n, val, lab) {
  return "<li>" ico(name) "<b" (n != "" ? " data-n=\"" n "\"" : "") ">" val "</b><span>" lab "</span></li>\n"
}

# An override line arrives as "GR5 - because", and the rule it bent is the part
# worth reading from the doorway. The rest is the sentence under it.
function grtag(s) { return (match(s, /GR[0-9]+/) ? substr(s, RSTART, RLENGTH) : "OVERRIDE") }
function grwhy(s) {
  sub(/^[[:space:]]*GR[0-9]+[[:space:]]*[-:]?[[:space:]]*/, "", s)
  return s
}

BEGIN { ver = total; bound = (rules != "") }
$1 == "TAG" { tag[$2] = $3; next }
$1 == "OWN" { owner[$2] = $3; next }
$1 == "ART" { art[$2] = $3; altof[$2] = $4; next }
$1 == "ART" { plate[$2] = $3; plated[$2] = $4; next }
$1 == "FACE" { mug[$2] = $3; next }
NF < 4 { next }
{
  # Reading newest first, this is where the rules stop existing. The commit that
  # brought them is the last one nobody can be judged for.
  if (bound && $1 == rules) bound = 0
  who  = $2
  split($3, dt, "|")
  when = dt[1]
  clock = dt[2]
  subj = $4
  rest = $6

  # Trailers, including the wrapped ones: a line indented under a trailer is a
  # continuation of it, which is how anybody sane writes a two-line reason.
  line = ""; overrides = ""; rulechange = ""; tallyline = ""; mode = ""
  gamefiles = 0; files = 0; acmr = 0; ins = 0; del = 0; kc = 0
  refmoved = 0; docmoved = 0; bookmoved = 0; readmemoved = 0; elsemoved = 0
  refstrict = 0; nonref = 0; stolen = 0
  split("", deleted)
  n = split(rest, b, "\n")
  for (k = 1; k <= n; k++) {
    t = b[k]
    lt = tolower(t)
    # The raw diff arrives ahead of the numstat, so by the time the counting
    # starts the book already knows which paths left the repository.
    if (is_raw(t)) {
      split(t, rw, "\t")
      rn = split(rw[1], rf, " ")
      if (rf[rn] ~ /^D/) deleted[rw[2]] = 1
      mode = ""; continue
    }
    if (is_stat(t)) {
      split(t, ns, "\t")
      p = ns[3]
      if (is_game(p)) gamefiles++
      else if (p ~ /^tools\// || p ~ /^\.githooks\// || p ~ /^\.claude\// ||
               p == "CLAUDE.md" || p == "GOLDEN_RULES.md") refmoved = 1
      else if (is_book(p)) bookmoved = 1
      else if (p ~ /^docs\//) docmoved = 1
      else if (p == "README.md") readmemoved = 1
      else elsemoved = 1
      # For the audit, and only for it: the two sides GR10 keeps apart. docs/ is
      # on neither, being written by a machine from the history - carrying the
      # rebuilt book along with a rule change is not a rule broken.
      if (is_referee(p)) refstrict = 1
      else if (p !~ /^docs\//) nonref = 1
      # GR11 has no budget and no override, so the only question is who made it.
      if (p ~ /^src\/events\/.+\.js$/ && (p in owner) && owner[p] != who)
        stolenpath[++stolen] = p
      if (p !~ /^docs\//) {
        files++
        if (!(p in deleted)) acmr++
        if (ns[1] != "-") ins += ns[1]
        if (ns[2] != "-") del += ns[2]
        keep(p, (ns[1] == "-" ? 0 : ns[1]) + (ns[2] == "-" ? 0 : ns[2]), (p in deleted))
      }
      mode = ""; continue
    }
    if (lt ~ /^[[:space:]]*chronicle:/)            { sub(/^[^:]*:[[:space:]]*/, "", t); line = t; mode = "c"; continue }
    if (lt ~ /^[[:space:]]*golden-rule-override:/) { sub(/^[^:]*:[[:space:]]*/, "", t)
                                                     overrides = overrides (overrides ? " // " : "") t; mode = "o"; continue }
    if (lt ~ /^[[:space:]]*rule-change:/)          { sub(/^[^:]*:[[:space:]]*/, "", t); rulechange = t; mode = "r"; continue }
    if (lt ~ /^[[:space:]]*tally:/)                { sub(/^[^:]*:[[:space:]]*/, "", t); tallyline = t; mode = ""; continue }
    if (lt ~ /^[[:space:]]*tagline:/)              { mode = "t"; continue }   # kept in docs/taglines.tsv, printed from there
    if (mode != "" && t ~ /^[[:space:]]+[^[:space:]]/) {
      sub(/^[[:space:]]+/, "", t)
      if (mode == "c") line = line " " t
      else if (mode == "o") overrides = overrides " " t
      else if (mode == "r") rulechange = rulechange " " t
      continue
    }
    mode = ""
  }

  # ---- what the referee would have said, had anybody let it look ------------
  # Only the rules a commit can still be judged by on its own, years later: the
  # size budget, the two halves of GR10, and whose event file this was. Break
  # one of them with no override line and the commit never met the referee at
  # all, because the referee would not have let it past. Somebody switched it
  # off, and that is a thing the book knows how to say.
  unrec = ""
  if (bound) {
    if ((ins > 1200 || acmr > 25) && toupper(overrides) !~ /GR6/) {
      if (ins > 1200 && acmr > 25) how = ins " line" plural(ins) " aboard across " acmr " sector" plural(acmr)
      else if (ins > 1200)         how = ins " line" plural(ins) " aboard"
      else                         how = acmr " sector" plural(acmr) " touched"
      unrec = unrec "It went past GR6, " how ", with nothing written down. "
    }
    if (refstrict && nonref)
      unrec = unrec "The rules and the game moved in the same commit, which GR10 does not allow at any price. "
    if (refstrict && rulechange == "")
      unrec = unrec "The rules were changed with no Rule-Change: line to say why. "
    for (q = 1; q <= stolen; q++)
      unrec = unrec "It touched " esc(owner[stolenpath[q]]) "&rsquo;s event file, " esc(stolenpath[q]) \
                    ", which GR11 leaves to " esc(owner[stolenpath[q]]) " alone. "
    sub(/[[:space:]]+$/, "", unrec)
  }

  # The roster counts both, and counts them for an interlude too: a rule bent
  # while nothing was on the cabinet is still a rule bent.
  if (overrides != "") bent[who]++
  if (unrec != "")     cheat[who]++

  # ---- an interlude: a commit that left the game exactly as it found it -----
  # A line on the cover, and a note in the margin of whichever version was on
  # the cabinet while it happened. That is the whole of what a mention is: it
  # never gets a number, so it never gets a page.
  if (gamefiles == 0) {
    # The book rebuilding itself is not a thing that happened. Every commit
    # leaves docs/ a commit out of date, so the next one carries the rebuilt
    # book - and if that counted as an interlude it would leave the book out of
    # date again, one identical line longer every time, for ever. Nothing is
    # lost by passing over it: the pages it wrote are the book you are reading.
    # A commit that spent an override, altered a rule, went round the referee or
    # was written up by the ledger is still an event, whatever else it touched,
    # and it keeps its note.
    if (bookmoved && !docmoved && !refmoved && !readmemoved && !elsemoved &&
        overrides == "" && rulechange == "" && unrec == "" && tallyline == "")
      next

    if (rulechange != "" || refmoved) deed = "changed the rules"
    else if (readmemoved)             deed = "rewrote the notes on the cabinet"
    else if ((docmoved || bookmoved) && !elsemoved)
                                      deed = "rebuilt the book"
    else                              deed = "did some housekeeping"

    if (ver > 0) said = "While v" ver " was on the cabinet, <b>" esc(who) "</b> " deed "."
    else         said = "Before there was a game to change, <b>" esc(who) "</b> " deed "."

    note = "  <p class=\"between\">" said "</p>\n"
    note = note "  <p class=\"subj\">landed as &ldquo;" esc(subj) "&rdquo; &mdash; " esc(when) "</p>\n"
    if (rulechange != "")
      note = note "  <p class=\"lawchange\">The rules themselves were altered: " esc(rulechange) "</p>\n"
    if (overrides != "")
      note = note "  <p class=\"override\">On this day " esc(who) " invoked an override: " esc(overrides) "</p>\n"
    if (tallyline != "")
      note = note "  <p class=\"ledger\">The ledger, written by the machine and not by the pilot: " esc(tallyline) "</p>\n"
    # Already escaped where it quotes anybody - it is assembled, not copied.
    if (unrec != "")
      note = note "  <p class=\"unrecorded\">The referee never saw this one. " unrec "</p>\n"

    IB[ver] = IB[ver] "<article class=\"interlude\">\n" note "</article>\n"
    IBN[ver]++
    # The subject travels to the cover as well as the chapter. A deed is one of
    # four sentences, so two rule changes in a row read as the same line twice -
    # which is exactly how the book writing itself four times went unnoticed.
    ENT[++en] = "I" SUBSEP said SUBSEP esc(subj)
    interludes[who]++
    next
  }

  # ---- a version -----------------------------------------------------------
  # Kept whole rather than printed. A page has to know what came before it and
  # what came after, and the log arrives newest first, so neither is known yet.
  v = ver--
  pilots[who]++
  if (v > peak[who]) peak[who] = v

  VH[v] = $1;    VW[v] = who;  VN[v] = when;   VC[v] = clock; VA[v] = $5
  VS[v] = subj;  VL[v] = line; VT[v] = ($1 in tag) ? tag[$1] : ""
  VP[v] = ($1 in plate) ? plate[$1] : "";  VQ[v] = ($1 in plated) ? plated[$1] : ""
  VF[v] = files; VI[v] = ins;  VJ[v] = del
  VO[v] = overrides; VU[v] = unrec; VR[v] = rulechange
  VP[v] = ($1 in art) ? art[$1] : ""; VQ[v] = altof[$1]
  RC[v] = kc;    RM[v] = kn[1]
  for (k = 1; k <= kc; k++) { RP[v,k] = kp[k]; RN[v,k] = kn[k]; RD[v,k] = kd[k] }
  ENT[++en] = "V" SUBSEP v
}
# Same tokens, same CRT as the game itself, so the book follows along on its own
# the day somebody changes the spectrum. Every page in here wears them.
function head(f, ttl, cls,   b) {
  print "<!doctype html>" > f
  print "<html lang=\"en\"><head><meta charset=\"utf-8\">" > f
  print "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">" > f
  print "<title>" ttl "</title>" > f
  print "<link rel=\"stylesheet\" href=\"../styles/tokens.css\">" > f
  print "<link rel=\"stylesheet\" href=\"../styles/crt.css\">" > f
  print "<link rel=\"stylesheet\" href=\"chronicle.css\">" > f
  # The room it is read in, off until somebody asks for it. Deferred, and it
  # builds its own switch, so a page that never loads it is a page with no
  # promise of sound on it.
  print "<script src=\"chronicle-song.js\" defer></script>" > f
  b = "</head><body"
  if (cls != "") b = b " class=\"" cls "\""
  print b ">" > f
  print "<div class=\"crt vignette\"></div>" > f
  print "<div class=\"crt scanlines\"></div>" > f
  print "<div class=\"crt roll\"></div>" > f
}
END {
  # The roster counts versions, not commits. A pilot who has only ever changed
  # the rules has flown none, and the table says so, which is fair and which is
  # also funny.
  for (p in interludes) if (!(p in pilots)) pilots[p] = 0
  roster = ""
  for (p in pilots) {
    # One column, two kinds of bending: what somebody wrote down, and what the
    # book had to work out for itself.
    cell = ""
    if (bent[p])  cell = bent[p] " override" plural(bent[p])
    if (cheat[p]) cell = cell (cell ? ", " : "") cheat[p] " unrecorded"
    if (cell == "") cell = "&mdash;"
    roster = roster sprintf("<tr><td><span class=\"pilot\">%s%s</span></td><td>%d</td><td>%s</td><td>%s%s%s</td></tr>\n", \
             face(p), esc(p), pilots[p], \
             (peak[p] ? sprintf("<a href=\"v%d.html\">v%d</a>", peak[p], peak[p]) : "&mdash;"), \
             (cheat[p] ? "<b>" : ""), cell, (cheat[p] ? "</b>" : ""))
  }

  # The rail that sits in the dock at the foot of every chapter: the whole
  # history at a glance, oldest on the left, each version wearing the plate its
  # own page opens with - so a reader recognises a chapter they have already
  # read before they have read its number. Both kinds of trouble are marked, so
  # they can see where the book gets loud before they get there. A version with
  # no plate keeps the halftone the css gives it and reads as a panel somebody
  # meant, the same way its splash does.
  for (v = 1; v <= total; v++) {
    nth[VW[v]]++
    NT[v] = nth[VW[v]]
    TICK[v] = "<a class=\"tick" (VU[v] != "" ? " off" : (VO[v] != "" ? " bent" : "")) \
              "\" href=\"v" v ".html\" title=\"v" v " &middot; " att(shout(v)) "\">" \
              (VP[v] != "" ? "<img src=\"art/" VP[v] "\" alt=\"\" loading=\"lazy\" decoding=\"async\">" : "") \
              "<b>" v "</b></a>"
  }

  # ---- the cover -----------------------------------------------------------
  cover = "docs/index.html"
  head(cover, "HYPERCOLOR ASTEROIDS &mdash; the chronicle", "")
  print "<main>" > cover
  print "<h1>THE CHRONICLE</h1>" > cover
  print "<p class=\"sub\">Being a true and complete account of HYPERCOLOR ASTEROIDS," > cover
  print "in " total " version" (total == 1 ? "" : "s") ", as told by the pilots who flew it." > cover
  print "A version is a commit that changed the game and it gets a page to itself;" > cover
  print "everything else that happened is noted in passing, including every rule" > cover
  print "anybody bent &mdash; whether or not they were the one who wrote it down.</p>" > cover
  print "<p class=\"prompt\"><a href=\"../index.html\">&#9654; PLAY THE CURRENT BUILD</a>" > cover
  if (total > 0)
    print "<a class=\"read\" href=\"v" total ".html\">&#9654; READ THE LATEST CHAPTER</a>" > cover
  print "</p>" > cover
  print "<section class=\"panel roster\">" > cover
  print "<h2>THE PILOTS</h2>" > cover
  print "<table><thead><tr><th>pilot</th><th>versions</th><th>latest</th><th>rules bent</th></tr></thead><tbody>" > cover
  printf "%s", roster > cover
  print "</tbody></table>" > cover
  print "</section>" > cover
  print "<h2 class=\"heading\">THE VERSIONS</h2>" > cover
  print "<ol class=\"contents\">" > cover
  for (i = 1; i <= en; i++) {
    split(ENT[i], e, SUBSEP)
    if (e[1] == "V") {
      v = e[2]
      printf "<li class=\"cv\"><a href=\"v%s.html\"><b>v%s</b><span>%s</span><i>%s%s</i></a></li>\n", \
             v, v, esc(shout(v)), face(VW[v]), esc(VW[v]) > cover
    } else {
      printf "<li class=\"ci\">%s", e[2] > cover
      if (e[3] != "") printf "<span>&ldquo;%s&rdquo;</span>", e[3] > cover
      print "</li>" > cover
    }
  }
  print "</ol>" > cover
  print "</main>" > cover
  print "</body></html>" > cover
  close(cover)

  # ---- one page per version ------------------------------------------------
  # A chapter is a page of cels rather than one screenful: the tagline as a
  # splash with the plate behind it, the narration next to the numbers, the
  # drawn commit under both, and a cel apiece for anything the book had to
  # write down. Nothing here is wider than a comfortable line of prose, which
  # is why there are several blocks instead of one - and the next chapter is
  # still one arrow key away.
  for (v = 1; v <= total; v++) {
    f = "docs/v" v ".html"
    head(f, "v" v " &mdash; HYPERCOLOR ASTEROIDS", "page")
    # Three facts the layout needs before it starts: whether the book had to
    # write anything down, whether anything happened alongside, and whether so
    # much happened alongside that it has outgrown the margin. Any of them
    # missing and its neighbour takes the room instead of leaving a hole.
    kept = (VU[v] != "" || VO[v] != "" || VR[v] != "")
    printf "<main class=\"ch%s%s%s\">\n", (kept ? " has-record" : ""), \
           ((v in IB) ? " has-aside" : ""), (IBN[v] >= 3 ? " long-aside" : "") > f

    # The splash. One version is one sentence, and this is it, at the size that
    # sentence deserves - with the plate behind it if this chapter has one, and
    # a field of halftone dots if it does not. Nothing below changes either way.
    # The credits ride on it rather than on a bar of their own: a chapter opens
    # on a picture, and who flew it and when belongs in the corner of that
    # picture the way a comic signs its first panel.
    printf "<section class=\"cel splash%s\">", (VP[v] != "" ? " plated" : "") > f
    if (VP[v] != "")
      printf "<img class=\"plate-img\" src=\"art/%s\" alt=\"%s\" loading=\"lazy\" decoding=\"async\">", \
             VP[v], att(VQ[v] != "" ? VQ[v] : shout(v)) > f
    print "<span class=\"dots\" aria-hidden=\"true\"></span>" > f
    printf "<div class=\"say\"><p class=\"kicker\">%s what changed</p><h1 class=\"shout\">%s</h1></div>", \
           ico("bolt"), esc(shout(v)) > f
    printf "<p class=\"credits\"><span class=\"badge\"><b>%s</b><i>chapter</i></span>", roman(v) > f
    printf "<span class=\"ver\">v%s</span>", v > f
    printf "<span class=\"who\">%s%s</span><span class=\"when\">%s &middot; %s</span></p>", \
           face(VW[v]), esc(VW[v]), esc(VN[v]), VC[v] > f
    if (VP[v] != "")
      printf "<a class=\"plate-full\" href=\"art/%s\">%s painted for this chapter</a>", VP[v], ico("frame") > f
    print "</section>" > f

    print "<section class=\"cel told\">" > f
    printf "<h2 class=\"tab\">%s what happened</h2>\n", ico("quote") > f
    if (VL[v] == "")
      printf "<p class=\"deed untold\">Nobody wrote this one down. The flight recorder kept the subject line: &ldquo;%s&rdquo;</p>\n", \
             esc(VS[v]) > f
    else {
      printf "<p class=\"deed\">%s</p>\n", esc(VL[v]) > f
      if (VL[v] != VS[v]) printf "<p class=\"subj\">landed as &ldquo;%s&rdquo;</p>\n", esc(VS[v]) > f
    }
    print "</section>" > f

    print "<section class=\"cel figures\">" > f
    printf "<h2 class=\"tab\">%s the numbers</h2>\n", ico("gauge") > f
    print "<ul class=\"stats\">" > f
    printf "%s", tile("target", VF[v], VF[v], "sector" plural(VF[v]) " touched") > f
    printf "%s", tile("up", VI[v], VI[v], "line" plural(VI[v]) " aboard") > f
    printf "%s", tile("down", VJ[v], VJ[v], "jettisoned") > f
    printf "%s", tile("clock", "", VC[v], "on the clock") > f
    if (v > 1) {
      gap = int((VA[v] - VA[v-1]) / 86400)
      printf "%s", tile("cal", gap, gap, "day" plural(gap) " after v" (v - 1)) > f
    } else
      printf "%s", tile("cal", "", "first", "coin in the slot") > f
    printf "%s", tile("medal", "", ord(NT[v]), "version by " esc(VW[v])) > f
    print "</ul>" > f
    print "</section>" > f

    print "<figure class=\"cel frame\">" > f
    printf "<h2 class=\"tab\">%s the commit, drawn</h2>\n", ico("ship") > f
    printf "%s<figcaption>%s</figcaption>\n", picture(v), esc(caption(v)) > f
    print "</figure>" > f

    # The margin, beside the drawn field: everything that happened around this
    # version rather than in it. A chapter with a quiet week either side has no
    # margin at all, and the field takes the whole width instead.
    if (kept || (v in IB)) print "<div class=\"margin\">" > f

    # The three things a chapter cannot keep quiet, each in a cel of its own
    # with the rule it bent in letters you can read from the doorway. The
    # referee-off one comes first, because it decides how much of the rest a
    # reader should believe. Assembled, not copied, so it is escaped already.
    if (kept) {
      print "<section class=\"record\">" > f
      if (VU[v] != "") {
        printf "<article class=\"cel loud off\"><h2 class=\"tab\">%s the referee never saw this</h2>", ico("eye") > f
        printf "<p class=\"klaxon\">OFF</p><p class=\"reason\">%s</p></article>\n", VU[v] > f
      }
      if (VO[v] != "") {
        nov = split(VO[v], ovs, " // ")
        for (k = 1; k <= nov; k++) {
          printf "<article class=\"cel loud over\"><h2 class=\"tab\">%s override</h2>", ico("bolt") > f
          printf "<p class=\"klaxon\">%s</p><p class=\"reason\">%s</p>", esc(grtag(ovs[k])), esc(grwhy(ovs[k])) > f
          printf "<p class=\"byline\">spent by %s, in writing, for good</p></article>\n", esc(VW[v]) > f
        }
      }
      if (VR[v] != "") {
        printf "<article class=\"cel loud law\"><h2 class=\"tab\">%s the rules themselves</h2>", ico("scroll") > f
        printf "<p class=\"klaxon\">AMENDED</p><p class=\"reason\">%s</p></article>\n", esc(VR[v]) > f
      }
      print "</section>" > f
    }

    if (v in IB)
      printf "<section class=\"cel meanwhile\"><h2 class=\"tab\">%s meanwhile</h2>\n%s</section>\n", \
             ico("hourglass"), IB[v] > f
    if (kept || (v in IB)) print "</div>" > f

    # The one line that stays literal: it is meant to be pasted into a terminal.
    printf "<p class=\"cel play\">%s Drop a coin in this one: <code>git checkout %s</code></p>\n", \
           ico("coin"), substr(VH[v], 1, 8) > f
    print "</main>" > f
    # The dock. Everything a reader might want next, parked at the foot of the
    # window rather than at the foot of the page: somebody who decides halfway
    # down that they have had enough of this chapter should not have to scroll
    # to the end to say so. Back and next are the size of a thing you press;
    # between them is every chapter there has ever been, and when there are
    # more of those than there is window, the middle scrolls and the two
    # buttons do not move.
    print "<nav class=\"dock\" aria-label=\"turn the page\">" > f
    if (v > 1)
      printf "<a class=\"turn prev\" rel=\"prev\" href=\"v%d.html\" title=\"v%d &middot; %s\"><span class=\"arw\">&#9664;</span><span class=\"lab\"><i>back</i><b>v%d</b></span></a>\n", \
             v - 1, v - 1, att(shout(v - 1)), v - 1 > f
    else
      print "<span class=\"turn prev none\"><span class=\"arw\">&#9664;</span><span class=\"lab\"><i>back</i><b>the first</b></span></span>" > f
    printf "<a class=\"up\" href=\"index.html\" title=\"the contents\">%s<i>all</i></a>\n", ico("grid") > f
    print "<div class=\"rail\">" > f
    for (k = 1; k <= total; k++) {
      t = TICK[k]
      if (k == v) {
        sub(/class="tick/, "class=\"tick here", t)
        sub(/<a /, "<a aria-current=\"page\" ", t)
      }
      print t > f
    }
    print "</div>" > f
    if (v < total)
      printf "<a class=\"turn next\" rel=\"next\" href=\"v%d.html\" title=\"v%d &middot; %s\"><span class=\"lab\"><i>next</i><b>v%d</b></span><span class=\"arw\">&#9654;</span></a>\n", \
             v + 1, v + 1, att(shout(v + 1)), v + 1 > f
    else
      print "<span class=\"turn next none\"><span class=\"lab\"><i>next</i><b>on the cabinet</b></span><span class=\"arw\">&#9654;</span></span>" > f
    print "</nav>" > f
    # The arrow keys, because a book of pages that only turn by mouse is a
    # worse book, and because this cabinet is played on a keyboard. And the
    # cels, which land one at a time as you scroll onto them and count their
    # numbers up when they do. Everything the script does is decoration: with
    # it switched off the page is the same page, already right, just still.
    print "<script>" > f
    # A page turn is the wrong thing to do while the plate is up in front of
    # the page, so while it is up the keyboard belongs to it and Escape puts
    # it away rather than leaving the chapter.
    print "addEventListener(\"keydown\", function (e) {" > f
    print "  if (document.documentElement.classList.contains(\"lit-open\")) {" > f
    print "    if (e.key === \"Escape\") drop()" > f
    print "    return" > f
    print "  }" > f
    print "  var to = { ArrowLeft: \".prev\", ArrowRight: \".next\", Escape: \".up\" }[e.key]" > f
    print "  var a = to ? document.querySelector(\".dock \" + to) : null" > f
    print "  if (a && a.href) location.href = a.href" > f
    print "})" > f
    print "document.documentElement.className = \"js\"" > f
    # The rail opens on the chapter you are reading rather than on the first
    # one ever landed. Only the rail scrolls, and only sideways, so a reader
    # who never looks down there does not notice this happening.
    print "var rail = document.querySelector(\".rail\")" > f
    print "var here = rail && rail.querySelector(\".here\")" > f
    print "if (here) rail.scrollLeft = here.offsetLeft - (rail.clientWidth - here.offsetWidth) / 2" > f
    print "var cels = document.querySelectorAll(\".cel\")" > f
    print "function land(cel) {" > f
    print "  cel.classList.add(\"in\")" > f
    print "  var ns = cel.querySelectorAll(\"b[data-n]\"), i" > f
    print "  for (i = 0; i < ns.length; i++) count(ns[i])" > f
    print "}" > f
    print "function count(el) {" > f
    print "  var to = +el.getAttribute(\"data-n\"), t0 = 0" > f
    print "  if (!(to > 1)) return" > f
    print "  requestAnimationFrame(function step(t) {" > f
    print "    if (!t0) t0 = t" > f
    print "    var k = Math.min(1, (t - t0) / 700)" > f
    print "    el.textContent = Math.round(to * (1 - Math.pow(1 - k, 3)))" > f
    print "    if (k < 1) requestAnimationFrame(step)" > f
    print "  })" > f
    print "}" > f
    print "if (matchMedia(\"(prefers-reduced-motion: reduce)\").matches || !window.IntersectionObserver) {" > f
    print "  for (var i = 0; i < cels.length; i++) cels[i].classList.add(\"in\")" > f
    print "} else {" > f
    print "  var io = new IntersectionObserver(function (seen) {" > f
    print "    for (var i = 0; i < seen.length; i++) if (seen[i].isIntersecting) {" > f
    print "      land(seen[i].target)" > f
    print "      io.unobserve(seen[i].target)" > f
    print "    }" > f
    print "  }, { rootMargin: \"0px 0px -6% 0px\" })" > f
    print "  for (var j = 0; j < cels.length; j++) io.observe(cels[j])" > f
    print "}" > f
    # The plate in full. The splash already has the picture in it, cropped to
    # the panel by object-fit, so opening it is not a new picture arriving -
    # it is the same one leaving the panel. Everything below is the arithmetic
    # for that: where the crop sits on the screen, and how much bigger the
    # whole plate is than the part of it you were already looking at.
    print "var pf = document.querySelector(\".plate-full\")" > f
    print "var pb = document.querySelector(\".plate-img\")" > f
    print "var sp = document.querySelector(\".splash\")" > f
    print "var lit = null, flight = null" > f
    print "function lift(e) {" > f
    # A middle click or a held modifier still means what it has always meant:
    # the href is a real file and somebody may want it in its own tab.
    print "  if (lit || e.button > 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return" > f
    print "  e.preventDefault()" > f
    print "  lit = document.createElement(\"div\")" > f
    print "  lit.className = \"lit\"" > f
    print "  lit.setAttribute(\"role\", \"dialog\")" > f
    print "  lit.setAttribute(\"aria-modal\", \"true\")" > f
    print "  lit.setAttribute(\"aria-label\", \"the plate painted for this chapter\")" > f
    print "  var img = lit.appendChild(document.createElement(\"img\"))" > f
    print "  var cap = lit.appendChild(document.createElement(\"p\"))" > f
    print "  var x = lit.appendChild(document.createElement(\"button\"))" > f
    print "  img.alt = pb ? pb.alt : \"\"" > f
    print "  img.src = pf.getAttribute(\"href\")" > f
    print "  cap.className = \"lit-cap\"" > f
    print "  cap.textContent = img.alt" > f
    print "  x.className = \"lit-x\"" > f
    print "  x.type = \"button\"" > f
    print "  x.textContent = \"×\"" > f
    print "  x.setAttribute(\"aria-label\", \"close\")" > f
    print "  x.title = \"close (esc)\"" > f
    print "  document.body.appendChild(lit)" > f
    print "  document.documentElement.classList.add(\"lit-open\")" > f
    print "  x.focus()" > f
    print "  lit.addEventListener(\"click\", drop)" > f
    print "  if (img.complete && img.naturalWidth) fly(img)" > f
    print "  else img.addEventListener(\"load\", function () { fly(img) })" > f
    print "}" > f
    # One scale for both axes, so nothing stretches on the way out, and a clip
    # that starts at the edges of the panel, so for the first frame the plate is
    # exactly the crop that was already there and nothing appears outside a
    # panel it has not left yet.
    print "function fly(img) {" > f
    # the browser has to have seen it arrive dark before it will bother
    # animating it lighting up
    print "  void lit.offsetWidth" > f
    print "  lit.classList.add(\"on\")" > f
    print "  if (!img.animate || !pb || !sp) return" > f
    print "  if (matchMedia(\"(prefers-reduced-motion: reduce)\").matches) return" > f
    print "  var b = pb.getBoundingClientRect(), p = sp.getBoundingClientRect()" > f
    print "  var f = img.getBoundingClientRect()" > f
    print "  if (!f.width || !img.naturalWidth) return" > f
    print "  var cx = b.left + b.width / 2, cy = b.top + b.height / 2" > f
    print "  var cover = Math.max(b.width / img.naturalWidth, b.height / img.naturalHeight)" > f
    print "  var s = img.naturalWidth * cover / f.width" > f
    print "  var edge = function (n) { return Math.max(0, n).toFixed(1) + \"px\" }" > f
    print "  flight = img.animate([{" > f
    print "    transform: \"translate(\" + (cx - f.left - f.width / 2) + \"px,\" +" > f
    print "               (cy - f.top - f.height / 2) + \"px) scale(\" + s + \")\"," > f
    print "    clipPath: \"inset(\" + edge(f.height / 2 + (p.top - cy) / s) + \" \" +" > f
    print "              edge(f.width / 2 - (p.right - cx) / s) + \" \" +" > f
    print "              edge(f.height / 2 - (p.bottom - cy) / s) + \" \" +" > f
    print "              edge(f.width / 2 + (p.left - cx) / s) + \")\"" > f
    print "  }, {" > f
    print "    transform: \"none\", clipPath: \"inset(0px 0px 0px 0px)\"" > f
    print "  }], { duration: 560, easing: \"cubic-bezier(0.4, 0, 0.15, 1)\" })" > f
    print "}" > f
    # Put away the same way it arrived, backwards, because a plate that drops
    # back into its own panel tells you where it came from.
    print "function drop() {" > f
    print "  if (!lit) return" > f
    print "  var gone = lit" > f
    print "  lit = null" > f
    print "  gone.classList.remove(\"on\")" > f
    print "  document.documentElement.classList.remove(\"lit-open\")" > f
    print "  pf.focus()" > f
    print "  if (flight && flight.playState !== \"idle\") {" > f
    print "    flight.reverse()" > f
    print "    flight.onfinish = function () { gone.parentNode && gone.parentNode.removeChild(gone) }" > f
    print "  } else setTimeout(function () { gone.parentNode && gone.parentNode.removeChild(gone) }, 420)" > f
    print "  flight = null" > f
    print "}" > f
    print "if (pf) pf.addEventListener(\"click\", lift)" > f
    print "</script>" > f
    print "</body></html>" > f
    close(f)
  }
}'

cat > docs/chronicle.css <<'CSS'
/* THE CHRONICLE.
   The same cabinet, printed. Palette, font and CRT come from the game's own
   styles/tokens.css and styles/crt.css, which are loaded ahead of this file —
   so when somebody changes the spectrum, the book changes with it. All this
   file does is teach that language to a page you scroll instead of play.

   Generated by tools/chronicle.sh. Editing it by hand lasts until the next
   commit. */

/* tokens.css locks the viewport for a canvas; a book has to scroll. */
html, body { height: auto; overflow: visible; }
body {
  user-select: text;
  -webkit-user-select: text;
  padding: 0 1.25rem 6rem;
}
main {
  position: relative;
  z-index: 1;
  max-width: 44rem;
  margin: 0 auto;
  padding-top: clamp(3rem, 12vh, 7rem);
}

/* The title, borrowed straight off the splash screen. */
h1 {
  font-size: clamp(1.9rem, 7.5vw, 3.6rem);
  font-weight: 600;
  letter-spacing: 0.4em;
  margin-right: -0.4em;
  text-wrap: balance;
  background: linear-gradient(100deg,
    #ff3ec8, #ffb020, #b6ff3d, #21f3ff, #a04bff, #ff3ec8);
  background-size: 300% 100%;
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
  filter: drop-shadow(0 0 16px rgba(255, 62, 200, 0.5));
  animation: slide 6s linear infinite;
}
@keyframes slide {
  from { background-position: 0% 50%; }
  to { background-position: 300% 50%; }
}

.sub {
  color: var(--dim);
  font-size: 0.8rem;
  line-height: 1.9;
  letter-spacing: 0.08em;
  margin-top: 1.1rem;
  max-width: 34rem;
}
.prompt {
  margin: 1.6rem 0 3.2rem;
  font-size: 0.8rem;
  letter-spacing: 0.3em;
}
/* The splash screen blinks this; a link you are meant to click does not. */
.prompt a {
  color: var(--lime);
  text-decoration: none;
  text-shadow: 0 0 12px currentColor;
}
.prompt a:hover { text-shadow: 0 0 20px currentColor; }
.heading {
  font-size: 0.6rem;
  font-weight: 500;
  letter-spacing: 0.34em;
  color: var(--magenta);
  text-shadow: 0 0 10px currentColor;
  margin: 3.4rem 0 1.4rem;
}

/* An instrument panel, same brackets as the field guide on the splash. */
.panel {
  position: relative;
  padding: 1.1rem 1.3rem 1.2rem;
  background: rgba(12, 5, 24, 0.66);
  border: 1px solid rgba(33, 243, 255, 0.35);
  box-shadow: 0 0 26px rgba(160, 75, 255, 0.28),
              inset 0 0 34px rgba(33, 243, 255, 0.06);
}
.panel::before,
.panel::after {
  content: "";
  position: absolute;
  width: 13px;
  height: 13px;
  border: 1px solid var(--magenta);
}
.panel::before { top: -1px; left: -1px; border-right: none; border-bottom: none; }
.panel::after { bottom: -1px; right: -1px; border-left: none; border-top: none; }
.panel h2 {
  font-size: 0.6rem;
  font-weight: 500;
  letter-spacing: 0.34em;
  color: var(--magenta);
  text-shadow: 0 0 10px currentColor;
  margin-bottom: 0.85rem;
  padding-bottom: 0.6rem;
  border-bottom: 1px dashed rgba(160, 75, 255, 0.35);
}

.roster { animation: cycle 9s linear infinite; }
.roster table { width: 100%; border-collapse: collapse; font-size: 0.72rem; }
.roster th {
  text-align: left;
  font-weight: 400;
  letter-spacing: 0.18em;
  color: var(--dim);
  padding: 0.3rem 0.4rem;
}
.roster td {
  padding: 0.42rem 0.4rem;
  letter-spacing: 0.06em;
  border-top: 1px solid rgba(160, 75, 255, 0.18);
  font-variant-numeric: tabular-nums;
}
.roster td:first-child { color: var(--ink); }
.roster .pilot { display: flex; align-items: center; gap: 0.5rem; }
.roster td:nth-child(2) { color: var(--amber); }
.roster a { color: var(--cyan); text-decoration: none; }

/* The contents. Read the taglines straight down and you have the whole story
   of the cabinet; click one and you get the version it belongs to, whole. */
.prompt a + a { margin-left: 1.5rem; }
.prompt .read { color: var(--amber); }
.contents { list-style: none; }
.contents li { border-top: 1px solid rgba(160, 75, 255, 0.16); }
.cv a {
  display: grid;
  grid-template-columns: 3.4rem 1fr auto;
  gap: 0.9rem;
  align-items: baseline;
  padding: 0.62rem 0.3rem;
  text-decoration: none;
}
.cv a:hover { background: rgba(160, 75, 255, 0.13); }
.cv b { font-size: 0.7rem; font-weight: 500; letter-spacing: 0.16em; color: var(--cyan); }
.cv span {
  font-size: 0.85rem;
  line-height: 1.55;
  color: var(--amber);
  text-wrap: pretty;
}
.cv a:hover span { text-shadow: 0 0 12px rgba(255, 176, 32, 0.5); }
.cv i {
  font-style: normal;
  font-size: 0.6rem;
  letter-spacing: 0.12em;
  color: var(--dim);
  display: inline-flex;
  align-items: center;
  gap: 0.45rem;
}

/* The pilots' faces. One each, painted once by tools/chronicle-art.sh, and the
   same one everywhere their name is written — which is the reason it is worth
   painting at all. Round, because a portrait among all these straight lines
   should not read as one more panel, and because the helmet fills the frame
   and crops well. A pilot with no face costs nothing: the name simply sits
   where it always did. */
.face {
  flex: none;
  width: 3.1rem;
  height: 3.1rem;
  border-radius: 50%;
  object-fit: cover;
  background: #05010c;
  border: 1px solid rgba(160, 75, 255, 0.55);
  box-shadow: 0 0 10px rgba(160, 75, 255, 0.4);
}
.ci {
  padding: 0.5rem 0.3rem 0.5rem 4.3rem;
  font-size: 0.66rem;
  line-height: 1.6;
  color: var(--dim);
}
.ci b { color: var(--violet); font-weight: 500; }
/* Quieter than the deed above it and in the same proportion the chapter uses,
   because it is here to tell two interludes apart rather than to be read. */
.ci span {
  display: block;
  margin-top: 0.2rem;
  font-size: 0.6rem;
  letter-spacing: 0.14em;
  color: var(--dim);
  opacity: 0.8;
}

/* --- one version, one comic page ------------------------------------------
   A chapter used to be one screenful read in a single look, and it fought the
   prose for room the whole time. It is a page of cels now: a splash for the
   tagline, the narration beside the numbers, the drawn commit under both, and
   a cel apiece for anything the book had to write down. No block of prose in
   here is wider than 600px, which is the whole reason there are several of
   them — a chapter is a handful of short things rather than one wide one.

   Everything sits on the same twelve columns, so the cels line up without
   anybody having to place them, and a cel with no neighbour this week takes
   the width its neighbour is not using. */
/* The dock is fixed to the foot of the window, so the page ends above it
   rather than under it: the last cel of a chapter is as readable as the
   first. */
body.page { padding: 0 0 clamp(6.5rem, 4rem + 6vh, 8.5rem); }
html { scroll-padding-bottom: 6rem; }
.page main {
  max-width: 82rem;
  margin: 0 auto;
  padding: clamp(0.8rem, 2.4vh, 1.6rem) clamp(0.7rem, 2.4vw, 2rem) 0;
  display: grid;
  grid-template-columns: repeat(12, 1fr);
  gap: clamp(0.6rem, 1.1vw, 1rem);
  align-content: start;
}

/* A cel: hard border, black ink dropped behind it, a corner of the spectrum
   leaking in at the top. It arrives as you scroll onto it — the script adds
   .in, and adds it to everything at once for anybody who asked for less
   motion, so nothing is ever left hidden behind an animation. */
.cel {
  position: relative;
  grid-column: span 12;
  padding: 1.35rem 1.2rem 1.1rem;
  background: linear-gradient(168deg, rgba(160, 75, 255, 0.1), rgba(7, 3, 15, 0.88) 46%);
  border: 2px solid rgba(160, 75, 255, 0.45);
  box-shadow: 5px 5px 0 rgba(0, 0, 0, 0.7), 0 0 26px rgba(160, 75, 255, 0.16);
}
/* Hidden only once the script has said it is there to unhide them. A page that
   needs JavaScript to show its own words is not a page, and the book is read
   in whatever somebody happens to have open. */
.js .cel {
  opacity: 0;
  transform: translateY(16px);
  transition: opacity 0.45s ease, transform 0.5s cubic-bezier(0.2, 0.85, 0.3, 1);
}
.js .cel.in { opacity: 1; transform: none; }
.cel:hover { border-color: rgba(33, 243, 255, 0.5); }
/* A cel inside the margin is not on the twelve columns any more, and asking
   for all of them there makes its grid build eleven tracks nobody wanted. */
.margin > .cel, .record > .cel { grid-column: auto; }

/* The label of a cel, sitting on its top edge the way a comic captions a
   panel. The glyph does most of the work: a reader knows which cel this is
   before they have read the word. */
.tab {
  position: absolute;
  top: -0.66rem;
  left: 0.85rem;
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  padding: 0.14rem 0.55rem;
  background: var(--void);
  border: 2px solid currentColor;
  color: var(--violet);
  font-size: 0.5rem;
  font-weight: 500;
  letter-spacing: 0.28em;
  text-transform: uppercase;
  text-shadow: 0 0 10px currentColor;
  white-space: nowrap;
}
.ic {
  flex: none;
  width: 1em;
  height: 1em;
  fill: none;
  stroke: currentColor;
  stroke-width: 1.7;
  stroke-linecap: round;
  stroke-linejoin: round;
}
.tab .ic { width: 0.85rem; height: 0.85rem; }

/* Who flew it and when, signed into the bottom corner of the splash — where a
   comic signs a panel, and the one corner the sentence never reaches, because
   the sentence is capped at 17ch and pinned to the left. Stacked, so it reads
   down the corner as four short facts rather than across it as one long line
   arguing with the sentence for the same inch. */
.credits {
  position: absolute;
  z-index: 2;
  right: clamp(1.2rem, 3.6vw, 2.6rem);
  bottom: clamp(1.2rem, 3.6vw, 2.6rem);
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 0.4rem;
  text-align: right;
}
.badge { display: flex; align-items: baseline; gap: 0.5rem; }
.badge b {
  font-size: 1.45rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  color: var(--violet);
  text-shadow: 0 0 18px currentColor;
}
.badge i {
  font-style: normal;
  font-size: 0.5rem;
  letter-spacing: 0.3em;
  text-transform: uppercase;
  color: var(--dim);
}
.ver {
  padding: 0.1rem 0.42rem;
  border: 1px solid rgba(33, 243, 255, 0.45);
  font-size: 0.56rem;
  letter-spacing: 0.2em;
  color: var(--cyan);
}
.credits .who {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.6rem;
  letter-spacing: 0.22em;
  text-transform: uppercase;
  color: var(--cyan);
}
/* Whoever flew it, on their own chapter's splash — smaller than it was on a
   bar of its own, because the sentence underneath is the loud thing here. */
.credits .who .face {
  width: 2.3rem;
  height: 2.3rem;
  border-color: rgba(33, 243, 255, 0.55);
  box-shadow: 0 0 12px rgba(33, 243, 255, 0.35);
}
.credits .when {
  font-size: 0.56rem;
  letter-spacing: 0.14em;
  color: var(--dim);
  font-variant-numeric: tabular-nums;
}

/* --- the splash -----------------------------------------------------------
   One version is one sentence, and this is where it gets said at the size it
   deserves. The plate goes behind it when the chapter has one — painted once
   by tools/chronicle-art.sh and kept in docs/art/ from then on — and the
   halftone dots are there either way, so a chapter with no plate reads as a
   panel somebody meant rather than as one short of a picture. */
.splash {
  min-height: clamp(14rem, 42vh, 24rem);
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  overflow: hidden;
  padding: clamp(1.2rem, 3.6vw, 2.6rem);
  border-color: rgba(255, 62, 200, 0.4);
  background: radial-gradient(120% 100% at 82% 4%, rgba(160, 75, 255, 0.3), transparent 62%), #05010c;
}
.plate-img {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
  opacity: 0.62;
  /* the book is a CRT and the plate did not come off one, so it is sent
     through the same glass as everything else on the page */
  filter: saturate(1.18) contrast(1.06);
  animation: breathe 34s ease-in-out infinite alternate;
}
@keyframes breathe {
  from { transform: scale(1.03); }
  to { transform: scale(1.14) translate(-1.6%, -1.4%); }
}
/* Halftone. A comic is dots before it is anything else, and these ones drift,
   which is the cheapest way there is to make a still page look like it runs. */
.dots {
  position: absolute;
  inset: -12%;
  background-image: radial-gradient(rgba(255, 62, 200, 0.55) 1.1px, transparent 1.3px);
  background-size: 7px 7px;
  opacity: 0.2;
  animation: halftone 18s linear infinite;
}
@keyframes halftone { to { transform: translate(7px, 7px); } }
/* the scanline layer sits behind main, so the splash gets its own, along with
   the scrim that keeps the tagline legible over whatever was painted */
.splash::after {
  content: "";
  position: absolute;
  inset: 0;
  pointer-events: none;
  background:
    linear-gradient(to top, rgba(5, 1, 12, 0.95) 4%, rgba(5, 1, 12, 0.4) 52%, rgba(5, 1, 12, 0.15)),
    repeating-linear-gradient(to bottom, rgba(0, 0, 0, 0.3) 0 1px, transparent 1px 3px);
}
.say { position: relative; z-index: 2; }
.kicker {
  display: flex;
  align-items: center;
  gap: 0.45rem;
  margin-bottom: 0.7rem;
  font-size: 0.54rem;
  letter-spacing: 0.34em;
  text-transform: uppercase;
  color: var(--lime);
  text-shadow: 0 0 14px currentColor;
}
/* What happened to the game, in letters you can read from the other side of
   the room. Every version has one, and on a page it is the whole headline. */
.shout {
  font-size: clamp(1.75rem, 5.4vw, 4.2rem);
  font-weight: 600;
  line-height: 1.04;
  /* the cover title is spaced out like a marquee; a sentence is not */
  letter-spacing: 0;
  margin-right: 0;
  max-width: 17ch;
  text-wrap: balance;
  background: linear-gradient(100deg,
    #ff3ec8, #ffb020, #b6ff3d, #21f3ff, #a04bff, #ff3ec8);
  background-size: 300% 100%;
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
  filter: drop-shadow(0 3px 0 rgba(0, 0, 0, 0.85)) drop-shadow(0 0 24px rgba(255, 62, 200, 0.35));
  animation: slide 9s linear infinite;
}
.plate-full {
  position: absolute;
  z-index: 2;
  top: 0.7rem;
  right: 0.75rem;
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.24rem 0.5rem;
  background: rgba(7, 3, 15, 0.75);
  border: 1px solid rgba(33, 243, 255, 0.45);
  color: var(--cyan);
  font-size: 0.5rem;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  text-decoration: none;
}
.plate-full:hover { border-color: var(--cyan); box-shadow: 0 0 16px rgba(33, 243, 255, 0.3); }
/* with the script running the link does not go anywhere, so it says so */
.js .plate-full { cursor: zoom-in; }

/* --- the plate, in full ---------------------------------------------------
   The link under the splash still points at the picture, and with the script
   off the browser does the old obvious thing with it. With the script on the
   chapter stays where it is and the plate climbs out of the panel it was
   behind instead — uncropped, over the page it belongs to, and gone again on
   a click, on Escape, or on the button in the corner. */
.lit {
  position: fixed;
  inset: 0;
  z-index: 40;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: clamp(0.7rem, 2vh, 1.2rem);
  padding: clamp(1rem, 4vw, 3rem);
  cursor: zoom-out;
  background: radial-gradient(120% 90% at 50% 45%, rgba(20, 4, 40, 0.86), rgba(3, 1, 8, 0.97));
  opacity: 0;
  transition: opacity 420ms ease;
}
.lit.on { opacity: 1; }
/* the book is a CRT, and a picture held up in front of it is behind the same
   glass as everything else on the page */
.lit::after {
  content: "";
  position: absolute;
  inset: 0;
  pointer-events: none;
  background: repeating-linear-gradient(to bottom, rgba(0, 0, 0, 0.32) 0 1px, transparent 1px 3px);
}
.lit img {
  max-width: 100%;
  max-height: 80vh;
  object-fit: contain;
  border: 1px solid rgba(255, 62, 200, 0.45);
  box-shadow: 0 0 70px rgba(160, 75, 255, 0.35);
  /* the same glass the plate wears in the panel it came out of */
  filter: saturate(1.18) contrast(1.06);
}
.lit-cap {
  position: relative;
  max-width: 46rem;
  text-align: center;
  color: var(--dim);
  font-size: 0.62rem;
  line-height: 1.8;
  letter-spacing: 0.14em;
  text-wrap: balance;
}
.lit-cap:empty { display: none; }
/* the caption and the way out arrive after the plate has landed, so the first
   half-second is the picture and nothing else */
.lit-cap, .lit-x {
  opacity: 0;
  transform: translateY(0.4rem);
  transition: opacity 260ms ease, transform 260ms ease;
}
.lit.on .lit-cap, .lit.on .lit-x {
  opacity: 1;
  transform: none;
  transition-delay: 300ms;
}
.lit-x {
  position: absolute;
  top: clamp(0.6rem, 2vw, 1.3rem);
  right: clamp(0.6rem, 2vw, 1.3rem);
  width: 2.1rem;
  height: 2.1rem;
  display: grid;
  place-items: center;
  padding: 0;
  background: rgba(7, 3, 15, 0.75);
  border: 1px solid rgba(33, 243, 255, 0.45);
  color: var(--cyan);
  font: inherit;
  font-size: 1.1rem;
  line-height: 1;
  cursor: pointer;
}
.lit-x:hover { border-color: var(--cyan); box-shadow: 0 0 16px rgba(33, 243, 255, 0.3); }
/* the page underneath does not scroll while the plate is up, or the zoom it
   flies back into would have moved by the time it got there */
.lit-open, .lit-open body { overflow: hidden; }

/* --- the narration --------------------------------------------------------
   The pilot's own sentence about what they did, in what a comic would call a
   caption box. Capped at 600px, because that is where a line of monospace
   stops being comfortable — and that cap is what makes the rest of the page
   divide into cels in the first place. */
.told { grid-column: span 5; }
.deed {
  max-width: 600px;
  font-size: clamp(0.92rem, 1.3vw, 1.12rem);
  line-height: 1.6;
  color: var(--ink);
  text-wrap: pretty;
}
.deed::first-letter {
  float: left;
  padding: 0.04em 0.09em 0 0;
  font-size: 2.6em;
  line-height: 0.82;
  color: var(--amber);
  text-shadow: 0 0 20px rgba(255, 176, 32, 0.5);
}

/* --- the numbers ----------------------------------------------------------
   Six tiles, each with its glyph, each counting up as the cel lands. They are
   the same six facts a chapter always carried; they have just stopped being a
   footnote about themselves. */
.figures { grid-column: span 7; }
.stats {
  list-style: none;
  display: grid;
  /* three and three, so the six of them read as a block rather than as a row
     that ran out */
  grid-template-columns: repeat(3, minmax(0, 1fr));
  grid-auto-rows: minmax(3.2rem, 1fr);
  gap: 0.45rem;
  height: 100%;
}
.stats li {
  display: grid;
  grid-template-columns: auto 1fr;
  column-gap: 0.6rem;
  align-content: center;
  padding: 0.5rem 0.6rem;
  background: rgba(160, 75, 255, 0.09);
  border: 1px solid rgba(160, 75, 255, 0.28);
  border-left: 3px solid var(--cyan);
  transition: background 0.2s, border-left-color 0.2s;
}
.stats li:hover { background: rgba(255, 62, 200, 0.11); border-left-color: var(--magenta); }
.stats .ic {
  grid-row: 1 / 3;
  align-self: center;
  width: 1.7rem;
  height: 1.7rem;
  color: var(--cyan);
  opacity: 0.8;
}
.stats li:hover .ic { color: var(--magenta); opacity: 1; }
.stats b {
  font-size: 1.3rem;
  font-weight: 500;
  line-height: 1.15;
  color: var(--cyan);
  font-variant-numeric: tabular-nums;
  text-shadow: 0 0 16px rgba(33, 243, 255, 0.35);
}
.stats span {
  font-size: 0.48rem;
  line-height: 1.4;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--dim);
}

/* The commit, drawn: one rock per sector it touched, sized by how much of that
   sector moved, coloured by which part of the cabinet it was, dashed if it left
   the repository altogether. The ship is the pilot, taking a shot at the
   biggest thing they moved. None of it is random — tools/chronicle.sh seeds it
   with the commit hash, so a version looks the same in every clone forever. */
/* Seven columns rather than twelve: the field is drawn on a 1400x640 board, so
   at full width it turns into a wall of empty space with three rocks in it.
   Beside the margin it is a picture. With nothing in the margin it takes the
   whole row back. */
/* align-self, so a version with five things in its margin does not stretch the
   field into a black rectangle with one rock adrift in it. The picture keeps
   the height its own shape asks for and the margin runs on past it. */
.frame {
  grid-column: span 7;
  align-self: start;
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
  padding-bottom: 0.8rem;
}
.frame .art { display: block; width: 100%; height: auto; }
.ch:not(.has-record):not(.has-aside) .frame,
.ch.long-aside .frame { grid-column: span 12; }
.ch:not(.has-record):not(.has-aside) .frame .art,
.ch.long-aside .frame .art { max-height: 52vh; }
.frame figcaption {
  font-size: 0.55rem;
  letter-spacing: 0.1em;
  color: var(--dim);
  text-align: center;
}
.art .star {
  fill: var(--ink);
  opacity: 0.5;
  animation: twinkle 3.4s ease-in-out infinite alternate;
  animation-delay: var(--d);
}
.art .drift {
  transform-box: fill-box;
  transform-origin: 50% 50%;
  animation: drift 14s ease-in-out infinite alternate;
  animation-delay: var(--d);
}
.art .rock {
  fill: rgba(7, 3, 15, 0.5);
  stroke: var(--c);
  stroke-width: 2.2;
  transform-box: fill-box;
  transform-origin: 50% 50%;
  animation: spin var(--s) linear infinite;
  filter: drop-shadow(0 0 6px var(--c));
}
.art .rock.gone { fill: none; stroke-dasharray: 5 8; opacity: 0.4; filter: none; }
.art .ship {
  fill: none;
  stroke: var(--lime);
  stroke-width: 2.6;
  filter: drop-shadow(0 0 8px var(--lime));
}
.art .shot {
  stroke: var(--lime);
  stroke-width: 2;
  stroke-dasharray: 9 15;
  opacity: 0.55;
  animation: march 1.1s linear infinite;
}
.art .ghost { font: 700 400px var(--mono); fill: var(--violet); opacity: 0.07; }
.art .stamp rect { fill: none; stroke: currentColor; stroke-width: 3; opacity: 0.75; }
.art .stamp text {
  fill: currentColor;
  font: 600 40px var(--mono);
  letter-spacing: 0.18em;
  text-anchor: middle;
}
.art .stamp.off { color: var(--magenta); }
.art .stamp.over { color: var(--amber); }
.art .stamp.untold { color: var(--dim); opacity: 0.6; }
@keyframes spin { to { transform: rotate(360deg); } }
@keyframes drift { to { transform: translate(14px, -11px); } }
@keyframes twinkle { to { opacity: 0.12; } }
@keyframes march { to { stroke-dashoffset: -48; } }

/* --- what the book had to write down --------------------------------------
   The loud cels. A rule bent in writing, a rule changed outright, or a commit
   the referee never got to look at — each with the rule itself in letters that
   carry, because the whole point of a budget is that spending it is visible
   from the doorway. */
/* The margin runs down the side of the drawn field and holds everything that
   happened around this version rather than in it. */
.margin {
  grid-column: span 5;
  display: grid;
  gap: clamp(0.6rem, 1.1vw, 1rem);
}
/* A version that had three other things happen while it was on the cabinet has
   more margin than there is margin. It comes out from beside the field and
   runs underneath it in columns, where the notes read as a stack of cards
   rather than as one long wall down the side. */
.ch.long-aside .margin { grid-column: span 12; }
.ch.long-aside .meanwhile {
  columns: 22rem;
  column-gap: clamp(0.8rem, 1.6vw, 1.6rem);
}
.ch.long-aside .interlude { break-inside: avoid; margin: 0 0 0.9rem; }
.record {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(100%, 20rem), 1fr));
  gap: clamp(0.6rem, 1.1vw, 1rem);
}
.loud { color: var(--amber); }
.loud .tab { color: inherit; }
/* The burst a comic puts behind a noise, turning slowly enough to be noticed
   rather than watched. Masked rather than clipped, because clipping the cel
   would take the corner off its own label with it. */
.loud::before {
  content: "";
  position: absolute;
  top: 0;
  right: 0;
  width: 9rem;
  height: 9rem;
  background: conic-gradient(from 0deg, currentColor 0 5deg, transparent 5deg 30deg);
  -webkit-mask-image: radial-gradient(closest-side, #000 28%, transparent 76%);
  mask-image: radial-gradient(closest-side, #000 28%, transparent 76%);
  opacity: 0.16;
  pointer-events: none;
  animation: spin 70s linear infinite;
}
.klaxon {
  position: relative;
  font-size: clamp(1.7rem, 3.6vw, 2.9rem);
  font-weight: 600;
  line-height: 1;
  letter-spacing: 0.04em;
  text-shadow: 3px 3px 0 rgba(0, 0, 0, 0.8), 0 0 28px currentColor;
}
.reason {
  max-width: 600px;
  margin-top: 0.55rem;
  font-size: 0.7rem;
  line-height: 1.75;
  color: var(--ink);
}
.byline {
  margin-top: 0.5rem;
  font-size: 0.52rem;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  color: var(--dim);
}
.loud.over { border-color: rgba(255, 176, 32, 0.6); }
.loud.law { color: var(--violet); border-color: rgba(160, 75, 255, 0.65); }
/* The other two are a pilot saying what they did. This one is the book saying
   it for them, because nobody wrote it down and the referee was not running.
   It is the one cel on the page that flashes, and it flashes on purpose. */
.loud.off {
  color: var(--magenta);
  border-color: var(--magenta);
  background: linear-gradient(168deg, rgba(255, 62, 200, 0.16), rgba(7, 3, 15, 0.88) 52%);
  animation: alarm 2.6s ease-in-out infinite;
}
@keyframes alarm {
  50% { box-shadow: 5px 5px 0 rgba(0, 0, 0, 0.7), 0 0 40px rgba(255, 62, 200, 0.45); }
}

/* --- the dock ---------------------------------------------------------------
   Forward, back, and out — bolted to the bottom of the window instead of the
   bottom of the page, because a reader halfway down a chapter is exactly the
   reader most likely to want the next one. The arrow keys do the same thing;
   see the script at the foot of every page. */
.dock {
  position: fixed;
  z-index: 5;
  inset: auto 0 0 0;
  display: grid;
  grid-template-columns: auto auto minmax(0, 1fr) auto;
  align-items: stretch;
  gap: clamp(0.3rem, 1vw, 0.75rem);
  padding: 0.45rem clamp(0.45rem, 1.8vw, 1.2rem);
  background: linear-gradient(to top, rgba(7, 3, 15, 0.98), rgba(9, 4, 20, 0.9));
  border-top: 1px solid rgba(160, 75, 255, 0.5);
  box-shadow: 0 -12px 34px rgba(7, 3, 15, 0.85);
  backdrop-filter: blur(6px);
}

/* The two a reader actually wants, at the size of something you press. */
.turn {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.3rem 0.75rem;
  border: 1px solid rgba(182, 255, 61, 0.45);
  background: rgba(182, 255, 61, 0.06);
  color: var(--lime);
  text-decoration: none;
  white-space: nowrap;
}
.turn:hover {
  color: var(--ink);
  border-color: var(--lime);
  background: rgba(182, 255, 61, 0.16);
  box-shadow: 0 0 18px rgba(182, 255, 61, 0.25);
}
.turn .arw { font-size: 1.1rem; line-height: 1; text-shadow: 0 0 12px currentColor; }
.turn .lab { display: grid; gap: 0.1rem; text-align: left; }
.turn.next .lab { text-align: right; }
.turn .lab i {
  font-style: normal;
  font-size: 0.46rem;
  letter-spacing: 0.28em;
  text-transform: uppercase;
  color: var(--dim);
}
.turn .lab b { font-size: 0.78rem; font-weight: 500; letter-spacing: 0.1em; }
/* The first chapter and the one on the cabinet each have one edge with nothing
   past it. The button stays where it was, unlit, so the row does not shuffle. */
.turn.none {
  border-color: rgba(154, 134, 189, 0.22);
  background: none;
  color: rgba(154, 134, 189, 0.45);
}
.turn.none .lab b { font-size: 0.6rem; letter-spacing: 0.16em; }
.up {
  display: grid;
  place-items: center;
  gap: 0.14rem;
  padding: 0 0.6rem;
  border: 1px solid rgba(160, 75, 255, 0.4);
  color: var(--violet);
  text-decoration: none;
}
.up .ic { width: 0.95rem; height: 0.95rem; }
.up i { font-style: normal; font-size: 0.44rem; letter-spacing: 0.22em; text-transform: uppercase; }
.up:hover { color: var(--ink); border-color: var(--cyan); }

/* Every version there has ever been, oldest first, always in reach, each one
   wearing the plate its own chapter opens with. Both kinds of trouble are
   marked, so a reader can see where the book gets loud before they get there.
   More chapters than window and this scrolls sideways — which it will, and
   which is why it is the only part of the dock allowed to move. */
.rail {
  position: relative;
  display: flex;
  align-items: center;
  gap: 4px;
  overflow-x: auto;
  overflow-y: hidden;
  overscroll-behavior-x: contain;
  justify-content: safe center;
  scrollbar-width: thin;
  scrollbar-color: rgba(160, 75, 255, 0.5) transparent;
  -webkit-mask-image: linear-gradient(to right, transparent, #000 1.2rem, #000 calc(100% - 1.2rem), transparent);
  mask-image: linear-gradient(to right, transparent, #000 1.2rem, #000 calc(100% - 1.2rem), transparent);
}
.rail::-webkit-scrollbar { height: 3px; }
.rail::-webkit-scrollbar-thumb { background: rgba(160, 75, 255, 0.5); }
.tick {
  position: relative;
  flex: none;
  display: block;
  width: clamp(2.6rem, 4.4vw, 3.3rem);
  height: 2.4rem;
  overflow: hidden;
  border: 1px solid rgba(160, 75, 255, 0.3);
  /* the halftone a chapter with no plate falls back to, under the plate a
     chapter with one covers it with */
  background: radial-gradient(rgba(255, 62, 200, 0.5) 1px, transparent 1.2px) 0 0 / 6px 6px, #0b0418;
  color: var(--dim);
  text-decoration: none;
}
.tick img {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
  opacity: 0.72;
  /* a plate is a square and a thumbnail is not, so it arrives cropped and
     often cropped to the darkest part of itself - lifted here, because a
     thumbnail nobody can make out is a blank tile with extra steps */
  filter: saturate(1.25) contrast(1.05) brightness(1.25);
  transition: opacity 0.15s, transform 0.35s;
}
.tick b {
  position: absolute;
  inset: auto 0 0 0;
  padding: 0.06rem 0;
  background: linear-gradient(to top, rgba(5, 1, 12, 0.92), rgba(5, 1, 12, 0));
  font-size: 0.54rem;
  font-weight: 500;
  text-align: center;
  letter-spacing: 0.06em;
  font-variant-numeric: tabular-nums;
}
.tick:hover { border-color: var(--cyan); color: var(--ink); }
.tick:hover img { opacity: 0.95; transform: scale(1.08); }
.tick.bent { border-color: rgba(255, 176, 32, 0.6); color: var(--amber); }
.tick.off { border-color: var(--magenta); color: var(--magenta); }
.tick.here { border-color: var(--cyan); box-shadow: 0 0 0 1px var(--cyan), 0 0 16px rgba(33, 243, 255, 0.3); }
.tick.here img { opacity: 0.9; }
.tick.here b { background: var(--cyan); color: var(--void); }

/* A version whose pilot wrote no Chronicle line reads as a gap in the record,
   and looks like one, so the next person can see what a missing chapter costs. */
.deed.untold {
  color: var(--dim);
  font-size: 0.86rem;
  font-style: italic;
}
.deed.untold::first-letter { float: none; font-size: 1em; color: inherit; text-shadow: none; }
.subj {
  max-width: 600px;
  margin-top: 0.7rem;
  padding-top: 0.5rem;
  border-top: 1px dashed rgba(160, 75, 255, 0.3);
  font-size: 0.62rem;
  line-height: 1.6;
  letter-spacing: 0.12em;
  color: var(--dim);
}
/* Something happened that was not a version: the rules moved, the book was
   rebuilt, somebody tidied. It goes in the record because everything goes in
   the record, but it never took a number, so it does not take a page either —
   it sits in the margin of whichever version was on the cabinet at the time. */
.interlude {
  padding-left: 0.9rem;
  border-left: 2px dashed rgba(160, 75, 255, 0.3);
}
.interlude + .interlude { margin-top: 0.8rem; }
.between {
  max-width: 600px;
  font-size: 0.78rem;
  line-height: 1.7;
  letter-spacing: 0.04em;
  color: var(--ink);
}
.between b { color: var(--violet); font-weight: 500; }
.interlude .subj { margin-top: 0.35rem; padding-top: 0; border: none; font-size: 0.58rem; }

/* The four things the book records whether you like it or not, here in the
   margin where the interludes live. On the chapter itself they get a cel each. */
.override, .lawchange, .unrecorded, .ledger {
  max-width: 600px;
  margin-top: 0.6rem;
  padding: 0.45rem 0.7rem;
  font-size: 0.66rem;
  line-height: 1.65;
  border-left: 2px solid currentColor;
}
.override { color: var(--magenta); background: rgba(255, 62, 200, 0.07); }
.lawchange { color: var(--amber); background: rgba(255, 176, 32, 0.07); }
.ledger { color: var(--violet); background: rgba(160, 75, 255, 0.07); }

/* The other two are a pilot saying what they did. This one is the book saying
   it for them, because nobody wrote it down and the referee was not running.
   It reads at full brightness on purpose: the declared ones are colour on the
   page, this one is the page talking. */
.unrecorded {
  color: var(--ink);
  background: rgba(255, 62, 200, 0.16);
  border-left-color: var(--magenta);
  text-shadow: 0 0 12px rgba(255, 62, 200, 0.45);
}
.roster td:last-child b { color: var(--ink); font-weight: 500; }

.play {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.4rem 0.55rem;
  padding: 0.7rem 1rem;
  font-size: 0.62rem;
  letter-spacing: 0.1em;
  color: var(--dim);
}
.play .ic { width: 1.1rem; height: 1.1rem; color: var(--lime); }
.play code {
  color: var(--lime);
  background: rgba(182, 255, 61, 0.08);
  border: 1px solid rgba(182, 255, 61, 0.25);
  padding: 0.14rem 0.5rem;
  user-select: all;
}

/* --- the room ---------------------------------------------------------------
   The book has a soundtrack and it is on. docs/chronicle-song.js builds this
   switch itself rather than finding it printed in the page, so a reader with
   the script off is never offered a sound that cannot arrive — same bargain as
   everything else the script does. Top right, out of the way of the dock, and
   small enough that a reader who does not want it never thinks about it. */
.song {
  position: fixed;
  z-index: 6;
  top: clamp(0.4rem, 1.5vw, 0.9rem);
  right: clamp(0.4rem, 1.5vw, 0.9rem);
  display: flex;
  align-items: center;
  gap: 0.45rem;
  padding: 0.36rem 0.62rem;
  font-family: inherit;
  font-size: 0.48rem;
  letter-spacing: 0.26em;
  text-transform: uppercase;
  color: var(--dim);
  background: rgba(7, 3, 15, 0.72);
  border: 1px solid rgba(33, 243, 255, 0.24);
  cursor: pointer;
  backdrop-filter: blur(6px);
}
.song:hover { color: var(--ink); border-color: var(--cyan); }
.song.on {
  color: var(--cyan);
  border-color: rgba(33, 243, 255, 0.65);
  box-shadow: 0 0 18px rgba(33, 243, 255, 0.2);
}
/* Four bars, flat while it is silent, because a meter that moves with nothing
   coming out of the speakers is the kind of decoration this book does not do. */
.eq { display: flex; align-items: flex-end; gap: 2px; height: 0.68rem; }
.eq i { width: 2px; height: 20%; background: currentColor; }
.song.on .eq i { animation: eq 2.1s ease-in-out infinite; }
.song.on .eq i:nth-child(2) { animation-duration: 3.4s; animation-delay: -0.9s; }
.song.on .eq i:nth-child(3) { animation-duration: 2.7s; animation-delay: -1.6s; }
.song.on .eq i:nth-child(4) { animation-duration: 4.1s; animation-delay: -0.4s; }
/* Lit, and waiting for the browser to allow a noise at all. Three classes on
   purpose: this outranks the reduced-motion rule below, which parks the bars
   at the height that means sound is coming out. */
.song.on.waiting .eq i { animation: none; height: 20%; }
@keyframes eq {
  0%, 100% { height: 20%; }
  50% { height: 100%; }
}

/* Below the width where two cels side by side stop being two cels and start
   being two columns of four words, there is one column. */
@media (max-width: 62rem) {
  .told, .figures, .frame, .margin { grid-column: span 12; }
  .shout { max-width: none; }
  /* the sentence takes the whole width down here, so the corner it was
     keeping clear is gone: the credits fall back under it, still to the right */
  .credits {
    position: static;
    margin-top: 0.9rem;
  }
  .stats { grid-template-columns: repeat(2, minmax(0, 1fr)); }
}
/* Narrow enough that the words on the two buttons are competing with the
   thumbnails for the same inch, and the arrows say it on their own. */
@media (max-width: 46rem) {
  .turn { padding: 0.3rem 0.5rem; }
  .turn .lab i { display: none; }
  .turn .lab b { font-size: 0.66rem; }
  .turn.none .lab { display: none; }
  .up i { display: none; }
  .up { padding: 0 0.45rem; }
}
@media (max-width: 34rem) {
  /* the bars say it on their own, the same way the arrows do */
  .song .lab { display: none; }
  .song { padding: 0.4rem 0.5rem; }
  .roster table { font-size: 0.62rem; }
  .cv a { grid-template-columns: 2.9rem 1fr; }
  .cv i { display: none; }
  .ci { padding-left: 0.3rem; }
  /* four stacked lines is a lot of corner on a phone; tightened up they are
     still four lines somebody can read at a glance */
  .credits { gap: 0.28rem; }
  .stats { grid-template-columns: 1fr 1fr; }
  .stats span { font-size: 0.44rem; }
  .turn .lab { display: none; }
  .tick { width: 2.6rem; height: 2.1rem; }
}
@media (prefers-reduced-motion: reduce) {
  h1, .shout, .roster, .art *, .dots, .plate-img, .loud, .loud::before { animation: none; }
  .js .cel { opacity: 1; transform: none; transition: none; }
  /* the plate still opens, it just does not fly there */
  .lit { transition: none; }
  /* the sound plays, the meter holds still - it was only ever saying so */
  .song.on .eq i { animation: none; height: 60%; }
}
CSS

# --- the room it is read in --------------------------------------------------
#
# The book's soundtrack, written the way everything else here is written: no
# audio file, no fetch, no dependency (GR2), just oscillators and a noise
# buffer. It is off until a reader asks for it and it says so in the file
# itself. Emitted from here rather than kept beside the pages for the same
# reason docs/chronicle.css is: the book is generated, all of it, so a clone
# that runs this tool has the whole book and not most of one.
cat > docs/chronicle-song.js <<'JS'
/* THE ROOM THE BOOK IS READ IN.
   Generated by tools/chronicle.sh. Editing it by hand lasts until the next
   commit; the copy that matters is the heredoc in that script.

   The cabinet is loud. The book is not, so this is not the cabinet's band
   playing quieter — it is the other end of the same evening: one chord every
   eight seconds, a heartbeat you only notice when it stops, and an arpeggio
   several rooms away. Fifty-six beats a minute, which is slower than reading.

   Three things about it are deliberate and one of them is the whole point.

   It comes up on, and it does not start over. The room is playing unless the
   reader says otherwise, and the switch remembers an off for as long as they
   want one. What it will not do is make a noise on a page nobody has touched
   yet — that is the browser's rule and it is a good one — so the switch comes
   up lit and the room waits for the next click or arrow key, which on this
   book is the same keystroke that turned the page. And turning a page is not
   stopping the music: the step the piece had got to rides along in the tab's
   own storage with the time it was true at, so the next chapter comes in
   where the piece would be by now rather than at the top of it.

   It is written, not stored. Same reason as everything else here (GR2): no
   audio file, no fetch, no dependency — an oscillator, a filter, and a noise
   buffer folded into a reverb. The whole soundtrack is this file, and this
   file opens from a USB stick in ten years.

   It costs nothing to leave on. Nothing here runs per frame. A timer wakes up
   four times a second, schedules the next second and a half into the audio
   clock, and goes back to sleep; the browser's audio thread does the rest at
   its own pace. A page with the sound on scrolls exactly as fast as one
   without it.

   Each chapter gets its own key and its own progression, off its own number,
   so v3 always sounds like v3 — and where the reader arrives from somewhere
   else in the book, the harmony changes under a piece that keeps its place.
   The chapter's own offset into the progression is only where it begins when
   nobody arrived from anywhere: the first page of a sitting. */

(function () {
  "use strict";

  var Ctx = window.AudioContext || window.webkitAudioContext;
  if (!Ctx) return;

  // ---- the tempo ----------------------------------------------------------
  // A step is an eighth note and it is the smallest thing in here, which at
  // this tempo is over half a second. Everything else is counted in steps.

  var BPM = 56;
  var STEP = 30 / BPM;          // 0.536s
  var BAR = STEP * 8;
  var CHORD = BAR * 2;          // one chord is two bars, and it feels like it
  var CYCLE = 64;               // steps in the whole progression: 34 seconds
  var LEVEL = 0.34;             // the ceiling, reached over four seconds

  // ---- which chapter ------------------------------------------------------
  // The cover is chapter zero and gets A minor, which is the house key.

  var m = /v(\d+)\.html/.exec(location.pathname);
  var CH = m ? +m[1] : 0;

  // Deterministic per page: the same chapter makes the same choices in the
  // same order forever, so a reader who comes back recognises the room.
  function seeded(a) {
    return function () {
      a |= 0; a = a + 0x6d2b79f5 | 0;
      var t = Math.imul(a ^ a >>> 15, 1 | a);
      t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
      return ((t ^ t >>> 14) >>> 0) / 4294967296;
    };
  }
  var rnd = seeded(CH * 2654435761 + 7);

  // ---- the harmony --------------------------------------------------------
  // Roots are MIDI, same as src/audio/themes.js, and picked so no two chapters
  // in a row share one. A chord is an offset from the key and a voicing; the
  // offsets above a tritone drop an octave, which is what keeps the pad from
  // leaping about between chords.

  var KEYS = [45, 40, 47, 42, 38, 44, 41, 36, 46, 43];
  var VOICES = {
    min9: [0, 3, 7, 14],
    min7: [0, 3, 7, 10],
    maj7: [0, 4, 7, 11],
    maj9: [0, 4, 7, 14],
    sus2: [0, 2, 7, 12],
    sus4: [0, 5, 7, 12]
  };
  var PROGS = [
    [[0, "min9"], [8, "maj7"], [3, "maj9"], [10, "sus2"]],   // i VI III VII
    [[0, "min7"], [10, "sus2"], [8, "maj9"], [10, "maj7"]],  // i VII VI VII
    [[0, "min9"], [5, "min7"], [8, "maj7"], [7, "sus4"]],    // i iv VI v
    [[8, "maj9"], [10, "sus2"], [0, "min9"], [0, "min7"]],   // VI VII i i
    [[0, "min7"], [3, "maj9"], [8, "maj7"], [5, "min7"]]     // i III VI iv
  ];
  // Where in the two bars the arpeggio lands. Never on every beat: the gaps
  // are the atmosphere and the notes are only there to prove there is a key.
  var ARPS = [
    [0, 3, 6, 10, 13],
    [2, 5, 8, 11, 14],
    [0, 4, 7, 12],
    [1, 3, 8, 10, 15]
  ];

  var key = KEYS[CH % KEYS.length];
  var prog = PROGS[CH % PROGS.length];
  var arps = ARPS[CH % ARPS.length];

  function mtof(n) { return 440 * Math.pow(2, (n - 69) / 12); }
  function chord(i) {
    var c = prog[i % 4], off = c[0];
    if (off > 6) off -= 12;
    return { root: key + off, voice: VOICES[c[1]] };
  }
  // The bass note is the chord's, folded into one octave and kept there. Off a
  // low enough key the arithmetic otherwise arrives at thirty-six hertz, which
  // is not a note on a laptop, it is a hum on somebody's desk.
  function low(root) {
    var n = root - 12;
    while (n < 31) n += 12;
    while (n > 42) n -= 12;
    return n;
  }

  // ---- the rig ------------------------------------------------------------
  // Built once, the first time somebody asks for sound, and kept. Four places
  // to send a voice: dry, the plate reverb, the echo, and the chorus the pad
  // alone goes through.

  var ctx = null, out = null, dry = null, send = null, echo = null, wide = null;
  var noise = null, timer = null, air = null;
  var playing = false, at = 0, step = (CH % 4) * 16, noted = -9;

  // A context made at the foot of this file to ask the browser a question, and
  // kept in case the answer was no. Nothing is built on it until it can run —
  // every oscillator started on a context the browser has parked is another
  // line of it saying so in the reader's console, and no music either way.
  var spare = null;

  function build() {
    ctx = spare || new Ctx();
    spare = null;

    // A gentle ceiling rather than a loud mix. Nothing in here should ever be
    // the loudest thing on somebody's desk.
    var lid = ctx.createDynamicsCompressor();
    lid.threshold.value = -20;
    lid.knee.value = 26;
    lid.ratio.value = 4;
    lid.attack.value = 0.02;
    lid.release.value = 0.45;
    lid.connect(ctx.destination);

    out = ctx.createGain();
    out.gain.value = 0;
    out.connect(lid);

    dry = ctx.createGain();
    dry.gain.value = 0.9;
    dry.connect(out);

    // The plate. Noise under an exponential decay, run through a one-pole
    // lowpass on the way into the buffer so the tail is dark rather than
    // fizzy — a bright reverb on a page of text reads as a fault.
    var verb = ctx.createConvolver();
    verb.buffer = plate(3.8);
    var vLo = ctx.createBiquadFilter();
    vLo.type = "lowpass";
    vLo.frequency.value = 2600;
    send = ctx.createGain();
    send.gain.value = 0.5;
    send.connect(verb);
    verb.connect(vLo);
    vLo.connect(out);

    // A dotted eighth, which at this tempo is four fifths of a second, damped
    // a little more on every pass so it walks away rather than stops.
    var d = ctx.createDelay(2);
    d.delayTime.value = STEP * 1.5;
    var fb = ctx.createGain();
    fb.gain.value = 0.42;
    var dLo = ctx.createBiquadFilter();
    dLo.type = "lowpass";
    dLo.frequency.value = 2000;
    echo = ctx.createGain();
    echo.gain.value = 0.34;
    echo.connect(d);
    d.connect(dLo);
    dLo.connect(fb);
    fb.connect(d);
    dLo.connect(out);
    dLo.connect(send);

    wide = chorus();
    noise = hiss(3);
    room();
  }

  // The impulse: two channels of noise, decaying, slightly different, with a
  // few milliseconds of nothing at the front so the reverb arrives after the
  // note rather than with it.
  function plate(secs) {
    var n = Math.floor(ctx.sampleRate * secs);
    var pre = Math.floor(ctx.sampleRate * 0.03);
    var buf = ctx.createBuffer(2, n, ctx.sampleRate);
    for (var c = 0; c < 2; c++) {
      var d = buf.getChannelData(c), last = 0;
      for (var i = pre; i < n; i++) {
        var k = (i - pre) / (n - pre);
        last += 0.22 * ((Math.random() * 2 - 1) - last);
        d[i] = last * Math.pow(1 - k, 3.4);
      }
    }
    return buf;
  }

  function hiss(secs) {
    var n = Math.floor(ctx.sampleRate * secs);
    var buf = ctx.createBuffer(2, n, ctx.sampleRate);
    for (var c = 0; c < 2; c++) {
      var d = buf.getChannelData(c);
      for (var i = 0; i < n; i++) d[i] = Math.random() * 2 - 1;
    }
    return buf;
  }

  // Two short modulated delays, one per ear, which is the cheapest way there
  // is to make four sawtooths sound like they are in a room together.
  function chorus() {
    var input = ctx.createGain();
    input.connect(dry);
    for (var i = 0; i < 2; i++) {
      var d = ctx.createDelay(0.1);
      d.delayTime.value = 0.013 + i * 0.008;
      var lfo = ctx.createOscillator();
      lfo.type = "sine";
      lfo.frequency.value = 0.11 + i * 0.06;
      var amt = ctx.createGain();
      amt.gain.value = 0.0035;
      lfo.connect(amt);
      amt.connect(d.delayTime);
      lfo.start();
      input.connect(d);
      d.connect(pan(i ? 0.55 : -0.55)).connect(out);
    }
    return input;
  }

  function pan(x) {
    if (!ctx.createStereoPanner) return ctx.createGain();
    var p = ctx.createStereoPanner();
    p.pan.value = x;
    return p;
  }

  // The floor under everything: tape hiss that swells on its own clock, and a
  // low wind that has no clock at all. Started once and never stopped — it is
  // what makes the gaps between the chords sound like a place.
  function room() {
    var h = ctx.createBufferSource();
    h.buffer = noise;
    h.loop = true;
    var bp = ctx.createBiquadFilter();
    bp.type = "bandpass";
    bp.frequency.value = 1500;
    bp.Q.value = 0.4;
    var hg = ctx.createGain();
    hg.gain.value = 0.02;
    var swell = ctx.createOscillator();
    swell.frequency.value = 0.043;
    var sa = ctx.createGain();
    sa.gain.value = 0.013;
    swell.connect(sa);
    sa.connect(hg.gain);
    swell.start();
    h.connect(bp);
    bp.connect(hg);
    hg.connect(out);
    h.start();

    var w = ctx.createBufferSource();
    w.buffer = noise;
    w.loop = true;
    w.playbackRate.value = 0.7;
    var lo = ctx.createBiquadFilter();
    lo.type = "lowpass";
    lo.frequency.value = 240;
    lo.Q.value = 1.4;
    var drift = ctx.createOscillator();
    drift.frequency.value = 0.017;
    var da = ctx.createGain();
    da.gain.value = 90;
    drift.connect(da);
    da.connect(lo.frequency);
    drift.start();
    var wg = ctx.createGain();
    wg.gain.value = 0.055;
    w.connect(lo);
    lo.connect(wg);
    wg.connect(out);
    wg.connect(send);
    w.start();
    air = h;
  }

  // ---- the voices ---------------------------------------------------------

  // Two sawtooths seven cents apart, opened and closed again over the length
  // of the chord. The filter is doing most of the work; the notes are only
  // there to tell it which chord it is being atmospheric about.
  function pad(t, f, dur, amp) {
    var g = ctx.createGain();
    var lp = ctx.createBiquadFilter();
    lp.type = "lowpass";
    lp.Q.value = 0.9;
    lp.frequency.setValueAtTime(340, t);
    lp.frequency.linearRampToValueAtTime(1500, t + dur * 0.55);
    lp.frequency.linearRampToValueAtTime(480, t + dur + 3);
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(amp, t + 2.4);
    g.gain.setValueAtTime(amp, t + dur);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur + 3.2);
    for (var i = 0; i < 2; i++) {
      var o = ctx.createOscillator();
      o.type = "sawtooth";
      o.frequency.value = f;
      o.detune.value = i ? 7 : -7;
      o.connect(lp);
      o.start(t);
      o.stop(t + dur + 3.4);
    }
    lp.connect(g);
    g.connect(wide);
    g.connect(send);
  }

  // One note, held under the whole chord, with a second an octave up quiet
  // enough that it only tells you which note it was.
  function bass(t, f, dur) {
    var g = ctx.createGain();
    var lp = ctx.createBiquadFilter();
    lp.type = "lowpass";
    lp.frequency.value = 300;
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(0.3, t + 0.9);
    g.gain.setValueAtTime(0.3, t + dur - 0.6);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur + 1.4);
    var a = ctx.createOscillator();
    a.type = "triangle";
    a.frequency.value = f;
    var b = ctx.createOscillator();
    b.type = "sine";
    b.frequency.value = f * 2;
    var bg = ctx.createGain();
    bg.gain.value = 0.22;
    a.connect(lp);
    b.connect(bg);
    bg.connect(lp);
    lp.connect(g);
    g.connect(dry);
    a.start(t); a.stop(t + dur + 1.6);
    b.start(t); b.stop(t + dur + 1.6);
  }

  // The arpeggio, several rooms away: a square through a filter that shuts
  // behind it, most of it arriving as echo rather than as note.
  function pluck(t, f, amp) {
    var g = ctx.createGain();
    var lp = ctx.createBiquadFilter();
    lp.type = "lowpass";
    lp.Q.value = 7;
    lp.frequency.setValueAtTime(Math.min(9000, f * 7), t);
    lp.frequency.exponentialRampToValueAtTime(Math.max(220, f * 1.1), t + 0.5);
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(amp, t + 0.014);
    g.gain.exponentialRampToValueAtTime(0.0001, t + 1.2);
    var o = ctx.createOscillator();
    o.type = "square";
    o.frequency.value = f;
    o.connect(lp);
    lp.connect(g);
    g.connect(dry);
    g.connect(echo);
    g.connect(send);
    o.start(t);
    o.stop(t + 1.3);
  }

  // A sine and its third partial, high up, all tail. This is the one thing in
  // the piece that is allowed to sound like a melody, and it gets four notes a
  // minute to do it in.
  function bell(t, f, amp) {
    var g = ctx.createGain();
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(amp, t + 0.05);
    g.gain.exponentialRampToValueAtTime(0.0001, t + 4.2);
    var a = ctx.createOscillator();
    a.frequency.value = f;
    var b = ctx.createOscillator();
    b.frequency.value = f * 3.01;
    var bg = ctx.createGain();
    bg.gain.value = 0.16;
    a.connect(g);
    b.connect(bg);
    bg.connect(g);
    g.connect(dry);
    g.connect(send);
    g.connect(echo);
    a.start(t); a.stop(t + 4.4);
    b.start(t); b.stop(t + 4.4);
  }

  // The heartbeat. Not a drum — nothing here keeps time for anybody — just a
  // low thump under the bar so the room has a pulse to it.
  function pulse(t, amp) {
    var g = ctx.createGain();
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(amp, t + 0.012);
    g.gain.exponentialRampToValueAtTime(0.0001, t + 0.85);
    var o = ctx.createOscillator();
    o.frequency.setValueAtTime(82, t);
    o.frequency.exponentialRampToValueAtTime(38, t + 0.18);
    o.connect(g);
    g.connect(dry);
    o.start(t);
    o.stop(t + 0.9);
  }

  // Noise climbing a filter into the turn of the progression. The one gesture
  // in here that a synthwave record would recognise.
  function sweep(t, dur) {
    var s = ctx.createBufferSource();
    s.buffer = noise;
    s.loop = true;
    var bp = ctx.createBiquadFilter();
    bp.type = "bandpass";
    bp.Q.value = 1.6;
    bp.frequency.setValueAtTime(300, t);
    bp.frequency.exponentialRampToValueAtTime(4200, t + dur);
    var g = ctx.createGain();
    g.gain.setValueAtTime(0.0001, t);
    g.gain.linearRampToValueAtTime(0.05, t + dur * 0.8);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur + 0.6);
    s.connect(bp);
    bp.connect(g);
    g.connect(dry);
    g.connect(send);
    s.start(t);
    s.stop(t + dur + 0.7);
  }

  // ---- the arrangement ----------------------------------------------------
  // Four chords, and then the same four chords again with something different
  // switched on. A cycle is thirty-four seconds, so a reader who stays for one
  // chapter hears three or four of them and never quite the same one twice.

  function plan(i, t) {
    var n = ((i % CYCLE) + CYCLE) % CYCLE;
    var cyc = Math.floor(i / CYCLE);
    var pos = n % 16;
    var c = chord(Math.floor(n / 16));
    var lift = cyc % 4 === 3 ? 12 : 0;   // every fourth time round, up an octave
    var thin = cyc % 4 === 0;            // and every fourth time round, it steps back

    if (pos === 0) {
      for (var v = 0; v < c.voice.length; v++)
        pad(t, mtof(c.root + 12 + lift + c.voice[v]), CHORD, 0.055);
      bass(t, mtof(low(c.root)), CHORD);
    }
    if (!thin && (pos === 0 || pos === 8)) pulse(t, pos ? 0.1 : 0.16);
    // Stepping back is not stopping: the arpeggio keeps its first note of each
    // chord, so the thin cycles still have somewhere to be rather than sounding
    // like the sound came off.
    for (var a = 0; a < arps.length; a++)
      if (arps[a] === pos && (!thin || a === 0)) {
        var deg = c.voice[(a + cyc) % c.voice.length];
        pluck(t, mtof(c.root + 24 + deg + (rnd() < 0.22 ? 12 : 0)), 0.075);
      }
    if (cyc > 0 && pos === 12 && rnd() < 0.4)
      bell(t, mtof(c.root + 36 + c.voice[Math.floor(rnd() * 4)]), 0.05);
    if (cyc % 2 === 1 && n === 60) sweep(t, 2.1);
  }

  // Wake up four times a second, fill the next second and a half of the audio
  // clock, go back to sleep. Everything above happens on that thread, not this
  // one, which is why a page with the sound on scrolls like a page without it.
  function tick() {
    var now = ctx.currentTime;
    // A tab nobody is looking at gets its timers throttled to one a minute,
    // and comes back owing the audio clock a minute of music. Scheduling that
    // in the past means playing it all at once, so the piece skips the wait
    // instead and comes back in phase, in the middle of wherever it got to.
    if (at < now) {
      var skip = Math.ceil((now - at) / STEP);
      step += skip;
      at += skip * STEP;
    }
    var horizon = now + 1.6;
    while (at < horizon) {
      plan(step, at);
      step++;
      at += STEP;
    }
    // The next page needs to know where this one got to. Storage does not
    // need telling four times a second to answer that; twice every three
    // seconds is closer than a page turn will ever notice.
    if (now - noted > 1.5) { noted = now; keep(); }
  }

  // ---- on and off ---------------------------------------------------------

  var KEY = "hypercolor.room";
  function remember(v) { try { localStorage.setItem(KEY, v); } catch (e) {} }
  function remembered() { try { return localStorage.getItem(KEY); } catch (e) { return null; } }

  // Where the piece got to, and when that was true. It goes in the tab's own
  // storage and not the browser's, because this is one sitting rather than a
  // habit, and a second window is a second room. What comes back is not the
  // step it left off on but the step it would be on now — the room keeps
  // playing while the page loads, the same way it keeps playing while a
  // chapter is read. Past ten minutes of nothing that stops being true and
  // the chapter starts where its own number says.
  var POS = "hypercolor.room.at";
  var CARRY = 600;

  function keep() {
    if (!timer) return;   // nothing is running, so there is no middle to be in
    // step and at are the front of the scheduling horizon, up to a second and
    // a half ahead of anything anybody can hear. What gets written down is
    // where the piece is, not where the scheduler has run on to.
    var here = step - (at - ctx.currentTime) / STEP;
    try { sessionStorage.setItem(POS, Math.round(here) + " " + Date.now()); } catch (e) {}
  }

  function carried() {
    var s;
    try { s = sessionStorage.getItem(POS); } catch (e) { return null; }
    if (!s) return null;
    var p = s.split(" "), n = +p[0], gap = (Date.now() - +p[1]) / 1000;
    if (!isFinite(n) || !isFinite(gap) || gap < 0 || gap > CARRY) return null;
    return Math.round(n + gap / STEP);
  }

  function on() {
    if (!ctx) build();
    playing = true;
    mark();
    remember("on");
    var p = ctx.resume();
    if (p && p.then) p.then(armed, armed); else armed();
  }

  // A page reached by clicking a link has no permission to make a noise yet,
  // however clearly the reader said so on the page before. So if the context
  // will not start, wait for the next thing they do — a click, or the arrow
  // key that turns the page — and start then. Nothing is asked of them twice.
  function armed() {
    if (!playing || !ctx) return;
    if (ctx.state !== "running") { wait(); return; }
    if (timer) return;
    // Asked here rather than at load, because between the two the reader may
    // have taken a while to touch anything, and the room did not wait.
    var pick = carried();
    if (pick !== null) step = pick;
    var t = ctx.currentTime;
    at = t + 0.15;
    out.gain.cancelScheduledValues(t);
    out.gain.setValueAtTime(out.gain.value, t);
    out.gain.linearRampToValueAtTime(LEVEL, t + 2.4);
    // The pad takes two and a half seconds to arrive and a reader who has just
    // pressed a button deserves an answer sooner than that, so the room says
    // one note back. It is in the key it is about to be in, which is the only
    // reason it is a note and not a beep.
    var c = chord(Math.floor((((step % CYCLE) + CYCLE) % CYCLE) / 16));
    bell(at, mtof(c.root + 36 + c.voice[0]), 0.045);
    tick();
    timer = setInterval(tick, 250);
    mark();                 // it is a room now rather than the promise of one
  }

  function wait() {
    var go = function () {
      removeEventListener("pointerdown", go);
      removeEventListener("keydown", go);
      if (playing) on();
    };
    addEventListener("pointerdown", go);
    addEventListener("keydown", go);
  }

  function off() {
    playing = false;
    remember("off");
    mark();
    if (!ctx) return;
    keep();               // where it stopped, while there is still a timer to ask
    var t = ctx.currentTime;
    out.gain.cancelScheduledValues(t);
    out.gain.setValueAtTime(out.gain.value, t);
    out.gain.linearRampToValueAtTime(0, t + 1.2);
    clearInterval(timer);
    timer = null;
    setTimeout(function () { if (!playing && ctx) ctx.suspend(); }, 1500);
  }

  // ---- the switch ---------------------------------------------------------
  // Built by the script rather than printed into the page, because a button
  // that promises sound to a reader with the script switched off is a lie. S
  // does the same thing, since this cabinet is played on a keyboard.

  var btn = document.createElement("button");
  btn.type = "button";
  btn.className = "song";
  btn.innerHTML = '<span class="eq" aria-hidden="true"><i></i><i></i><i></i><i></i></span>' +
                  '<span class="lab">sound</span>';

  // Three states rather than two, because for the first few seconds of most
  // pages the true answer is neither. The room is on and the browser has not
  // let it in yet; bars dancing over silence is the switch telling a small lie
  // about a room that has not arrived.
  function mark() {
    btn.classList.toggle("on", playing);
    btn.classList.toggle("waiting", playing && !awake());
    btn.setAttribute("aria-pressed", playing ? "true" : "false");
    btn.title = !playing ? "the room this is read in (s)"
      : awake() ? "quiet, then (s)"
      : "waiting for a click or a key (s)";
  }

  btn.addEventListener("click", function () { playing ? off() : on(); });
  addEventListener("keydown", function (e) {
    if (e.key !== "s" && e.key !== "S") return;
    if (e.metaKey || e.ctrlKey || e.altKey) return;
    playing ? off() : on();
  });

  // Back through the history to a page the browser kept whole: the graph came
  // back suspended, and the reader already said yes to all of this.
  addEventListener("pageshow", function (e) {
    if (e.persisted && playing) armed();
  });

  // The last word on where the piece was, written on the way out of the page
  // rather than a second and a half before it. pagehide and not unload: it is
  // the one the browser still fires when the page goes into the back-forward
  // cache, which is most of the turning of these pages.
  addEventListener("pagehide", keep);

  // ---- the furniture ------------------------------------------------------
  // The room answers a hand as well as a clock.
  //
  // Same argument the cabinet makes on its splash screen (src/ui/clicks.js): a
  // page you can point at things on should say something when you do, and a
  // book of ten chapters with a rail of plates along the foot of every one of
  // them is a page you point at a lot. Two differences, both of them because
  // this is a book rather than an arcade machine.
  //
  // It is quieter than anything else in here by a wide margin, and it is
  // tuned to whatever chord is currently hanging in the air rather than to a
  // key of its own — the note under your cursor is a degree of the chord the
  // pad is already holding, so pointing at things cannot put a wrong note in
  // the room however fast you do it.
  //
  // And it follows the one switch there is. Somebody who turned the room off
  // did not turn it off in order to be clicked at instead.

  // A degree of the chord in the air at this moment.
  function furniture(deg, lift) {
    var c = chord(Math.floor(((((step % CYCLE) + CYCLE) % CYCLE)) / 16));
    var v = c.voice;
    return mtof(c.root + lift + v[((deg % v.length) + v.length) % v.length]);
  }

  // Under the cursor: a fingertip on the rim of a glass, most of it arriving
  // as room rather than as note.
  function tap(f) {
    var t = ctx.currentTime;
    var g = ctx.createGain();
    var o = ctx.createOscillator();
    o.type = "sine";
    o.frequency.value = f;
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(0.03, t + 0.006);
    g.gain.exponentialRampToValueAtTime(0.0001, t + 0.26);
    o.connect(g);
    g.connect(dry);
    g.connect(send);
    o.start(t);
    o.stop(t + 0.28);
  }

  // Everything a reader can arrive at, by shape rather than by name, so a page
  // that grows a control next year gets this without being told.
  var LIVE = "a[href], button";
  var lastEl = null, lastAt = 0;

  function awake() { return playing && ctx && ctx.state === "running"; }

  // Where a thing sits, as a degree: its place among its own kind. The rail of
  // plates at the foot of a chapter is the whole history in a row, so running
  // a cursor along it arpeggiates the chord — which is the one bit of this
  // anybody is ever going to do on purpose.
  function degreeOf(el) {
    var kin = el.parentElement ? el.parentElement.children : [];
    for (var i = 0; i < kin.length; i++) if (kin[i] === el) return i;
    return 0;
  }

  function reach(e) {
    var el = e.target && e.target.closest ? e.target.closest(LIVE) : null;
    return el && !el.classList.contains("song") ? el : null;
  }

  addEventListener("pointerover", function (e) {
    if (e.pointerType === "touch" || !awake()) return;
    var el = reach(e);
    if (!el || el === lastEl) return;
    var now = ctx.currentTime;
    if (now - lastAt < 0.045) return;      // a fast sweep is a run, not a buzz
    lastEl = el;
    lastAt = now;
    tap(furniture(degreeOf(el), 24));
  }, true);

  // The same tick for a keyboard. This book is turned with the arrow keys and
  // read by people who tab through it.
  addEventListener("focusin", function (e) {
    if (!awake()) return;
    var el = reach(e);
    if (!el) return;
    lastEl = el;
    tap(furniture(degreeOf(el), 24));
  }, true);

  addEventListener("pointerdown", function (e) {
    if (!awake()) return;
    var el = reach(e);
    if (!el) return;
    lastEl = null;                          // coming back over it should answer again
    pluck(ctx.currentTime, furniture(degreeOf(el), 12), 0.05);
    // Turning a page moves air. It is the same sweep the piece uses to get
    // itself round the turn of the progression, which is the joke.
    if (el.classList.contains("turn")) sweep(ctx.currentTime, 0.45);
  }, true);

  mark();
  document.body.appendChild(btn);
  // On unless somebody said otherwise, and a reader who said yes on the last
  // page has said yes. Whether that can be honoured on arrival is the
  // browser's call rather than ours, so the room asks it. Making a context is
  // free and silent and it answers on the spot: one handed back already
  // running is a browser that trusts this book — one it has been read in
  // before, one told to allow it, a file opened off a disk — and then the
  // piece starts on its own, which is what a lit switch is supposed to mean.
  //
  // Where it comes back parked there is nothing to be done but wait, and
  // asking anyway only earns a console full of the browser saying so. So the
  // switch stays lit and gets honest about it: the bars hold still, the
  // tooltip says what it is waiting for, and the next thing the reader does —
  // a click, the arrow key that turns the page — starts the room. Nothing is
  // asked of them twice, and the context they are waiting on is the one they
  // get.
  if (remembered() !== "off") {
    playing = true;
    spare = new Ctx();
    if (spare.state === "running") on(); else wait();
    mark();
  }
})();
JS

# --- the sidecar ------------------------------------------------------------
#
# The book is a book, and the splash screen is a doorway to it. A doorway with
# a picture in it is worth walking through, so this writes what the cabinet
# needs to draw one: the last few painted plates, the newest chapter, and the
# top of the board.
#
# It is a script rather than data because there is no fetch in this project and
# there is not going to be (GR2), which is the same reason docs/faces/faces.js
# is a script. Same contract as that file, too: the game asks for it, does
# without it if it is not there, and never lists it in the manifest. A clone
# that has never run this tool gets the splash it always had.
#
# Everything in it is already committed somewhere else - the history, the
# taglines, the plates, the board. Nothing is invented here and nothing is
# authoritative here; it is the same facts, in the one shape a page can read.

# The board out of docs/RANKINGS.md, folded into the same stream as everything
# else. Row order is the file's, which is score order, which is the whole point
# of that table. The columns are read by position because the header names them
# and the header is the first row we skip.
board() {
  [ -f docs/RANKINGS.md ] || return 0
  awk -F'|' '
    function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
    /^##[ \t]/ { inboard = (index($0, "THE BOARD") > 0); next }
    !inboard || $0 !~ /^\|/ { next }
    { rows++ }
    rows <= 2 { next }                                  # the header, then its rule
    {
      printf "\036RANK\037%s\037%s\037%s\037%s\037%s\037%s\037%s",
             trim($2), trim($3), trim($4), trim($5), trim($6), trim($7), trim($8)
    }
  ' docs/RANKINGS.md
}

{ taglines; plates; board
  git log --format='%x1e%H%x1f%an%x1f%ad' --date=format:'%d %B %Y' \
          --no-merges --full-history HEAD -- $GAME 2>/dev/null
} | awk -v RS='\036' -v FS='\037' -v total="$TOTAL" '
# JS string literals, a character at a time. gsub would do it in two lines and
# get the backslashes wrong on some awk somewhere; this cannot.
function js(s,   i, c, o) {
  o = ""
  for (i = 1; i <= length(s); i++) {
    c = substr(s, i, 1)
    if (c == "\\")      o = o "\\\\"
    else if (c == "\"") o = o "\\\""
    else if (c == "\r" || c == "\n") o = o " "
    else o = o c
  }
  return o
}
function trim(s) { sub(/^[ \t\r\n]+/, "", s); sub(/[ \t\r\n]+$/, "", s); return s }
BEGIN { v = total + 0 }
$1 == "TAG"  { tag[$2] = $3; next }
$1 == "ART"  { art[$2] = $3; alt[$2] = $4; next }
$1 == "RANK" { rc++; for (k = 2; k <= 8; k++) R[rc, k] = $k; next }
NF >= 3 {
  # a version, newest first, so the number counts down from the newest.
  # The last field of a git record carries the newline that ends it.
  if (v < 1) next
  VW[v] = trim($2); VD[v] = trim($3); VT[v] = ($1 in tag) ? tag[$1] : ""
  VP[v] = ($1 in art) ? art[$1] : "";  VA[v] = ($1 in art) ? alt[$1] : ""
  v--
  next
}
END {
  print "// Generated by tools/chronicle.sh from the history, docs/taglines.tsv,"
  print "// docs/art/index.tsv and docs/RANKINGS.md - the splash screen'"'"'s window"
  print "// into the book. src/ui/book.js and src/ui/board.js load this if it is"
  print "// there and do without it if it is not, so it is never in the manifest"
  print "// and never has to exist. Do not edit: every rebuild writes it fresh."
  print "(function (A) {"
  print "  \"use strict\";"
  print "  A.CHRONICLE = {"
  printf "    versions: %d,\n", total
  if (total >= 1) {
    printf "    latest: { v: %d, pilot: \"%s\", date: \"%s\", line: \"%s\"", \
           total, js(VW[total]), js(VD[total]), js(VT[total])
    if (VP[total] != "") printf ", plate: \"%s\", alt: \"%s\"", js(VP[total]), js(VA[total])
    print " },"
  }
  # The plates, newest first, however few of them there are. Four is what the
  # panel has room for; a cabinet with one plate shows one and looks fine.
  print "    plates: ["
  n = 0
  for (v = total; v >= 1 && n < 4; v--) {
    if (VP[v] == "") continue
    n++
    printf "      { v: %d, file: \"%s\", alt: \"%s\", line: \"%s\" },\n", \
           v, js(VP[v]), js(VA[v]), js(VT[v])
  }
  print "    ]"
  print "  };"
  # The board as the file has it - score order, the words included. A tape is
  # the only way onto that table and nothing here is going to be a second way.
  print "  A.BOARD = ["
  for (k = 1; k <= rc; k++) {
    printf "    { rank: \"%s\", pilot: \"%s\", score: \"%s\", wave: \"%s\", time: \"%s\", hits: \"%s\", line: \"%s\" },\n", \
           js(R[k, 2]), js(R[k, 3]), js(R[k, 4]), js(R[k, 5]), js(R[k, 6]), js(R[k, 7]), js(R[k, 8])
  }
  print "  ];"
  print "})(ASTEROIDS);"
}' > docs/chronicle.js

printf 'chronicle: %s version%s, a page each, the cover at docs/index.html,\n' \
  "$TOTAL" "$([ "$TOTAL" = 1 ] || echo s)"
printf '           docs/chronicle.js for the splash screen to read, and\n'
printf '           docs/chronicle-song.js for the room it is read in.\n'
