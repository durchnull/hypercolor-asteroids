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
    ENT[++en] = "I" SUBSEP said
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

  # The strip that sits at the foot of every page: the whole history at a
  # glance, oldest on the left, with both kinds of trouble already marked. A
  # reader can see where the book gets loud before they get there.
  for (v = 1; v <= total; v++) {
    nth[VW[v]]++
    NT[v] = nth[VW[v]]
    TICK[v] = "<a class=\"tick" (VU[v] != "" ? " off" : (VO[v] != "" ? " bent" : "")) \
              "\" href=\"v" v ".html\" data-t=\"v" v " &middot; " att(shout(v)) "\">" v "</a>"
  }

  # ---- the cover -----------------------------------------------------------
  cover = "docs/index.html"
  head(cover, "ASTEROIDS // HYPERCOLOR &mdash; the chronicle", "")
  print "<main>" > cover
  print "<h1>THE CHRONICLE</h1>" > cover
  print "<p class=\"sub\">Being a true and complete account of ASTEROIDS // HYPERCOLOR," > cover
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
    } else
      printf "<li class=\"ci\">%s</li>\n", e[2] > cover
  }
  print "</ol>" > cover
  print "</main>" > cover
  print "</body></html>" > cover
  close(cover)

  # ---- one page per version ------------------------------------------------
  # It fills the screen because a version is one thing that happened and it
  # deserves to be looked at on its own, and because the next one is always one
  # key away.
  for (v = 1; v <= total; v++) {
    f = "docs/v" v ".html"
    head(f, "v" v " &mdash; ASTEROIDS // HYPERCOLOR", "page")
    print "<main>" > f
    printf "<header class=\"plate\"><span class=\"num\">CHAPTER %s</span><span class=\"ver\">v%s</span>", \
           roman(v), v > f
    printf "<span class=\"who\">%s%s</span><span class=\"when\">%s &middot; %s</span></header>\n", \
           face(VW[v]), esc(VW[v]), esc(VN[v]), VC[v] > f
    printf "<h1 class=\"shout\">%s</h1>\n", esc(shout(v)) > f
    # The plate, if this version has one, above the drawn field: the scene
    # first and the diff underneath it, which is the order a reader wants them
    # in. Nothing below changes when it is missing.
    if (VP[v] != "")
      printf "<figure class=\"plate-art\"><a href=\"art/%s\"><img src=\"art/%s\" alt=\"%s\" loading=\"lazy\" decoding=\"async\"></a><figcaption>Painted for this chapter, once, from its own tagline.</figcaption></figure>\n", \
             VP[v], VP[v], att(VQ[v] != "" ? VQ[v] : shout(v)) > f
    printf "<figure class=\"frame\">%s<figcaption>%s</figcaption></figure>\n", picture(v), esc(caption(v)) > f
    print "<div class=\"told\">" > f
    if (VL[v] == "")
      printf "<p class=\"deed untold\">Nobody wrote this one down. The flight recorder kept the subject line: &ldquo;%s&rdquo;</p>\n", \
             esc(VS[v]) > f
    else {
      printf "<p class=\"deed\">%s</p>\n", esc(VL[v]) > f
      if (VL[v] != VS[v]) printf "<p class=\"subj\">landed as &ldquo;%s&rdquo;</p>\n", esc(VS[v]) > f
    }
    # First of the three, because it decides how much of the rest a reader
    # should believe. Assembled, not copied, so it is escaped already.
    if (VU[v] != "") printf "<p class=\"unrecorded\">The referee never saw this one. %s</p>\n", VU[v] > f
    if (VO[v] != "") printf "<p class=\"override\">On this day %s invoked an override: %s</p>\n", esc(VW[v]), esc(VO[v]) > f
    if (VR[v] != "") printf "<p class=\"lawchange\">The rules themselves were altered: %s</p>\n", esc(VR[v]) > f
    if (v in IB)     printf "<div class=\"meanwhile\">%s</div>\n", IB[v] > f
    print "</div>" > f
    print "<ul class=\"stats\">" > f
    printf "<li><b>%d</b><span>sector%s touched</span></li>", VF[v], plural(VF[v]) > f
    printf "<li><b>%d</b><span>line%s aboard</span></li>", VI[v], plural(VI[v]) > f
    printf "<li><b>%d</b><span>jettisoned</span></li>", VJ[v] > f
    printf "<li><b>%s</b><span>on the clock</span></li>", VC[v] > f
    if (v > 1) {
      gap = int((VA[v] - VA[v-1]) / 86400)
      printf "<li><b>%d</b><span>day%s after v%d</span></li>", gap, plural(gap), v - 1 > f
    } else
      printf "<li><b>first</b><span>coin in the slot</span></li>" > f
    printf "<li><b>%s</b><span>version by %s</span></li>", ord(NT[v]), esc(VW[v]) > f
    print "</ul>" > f
    # The one line that stays literal: it is meant to be pasted into a terminal.
    printf "<p class=\"play\">Drop a coin in this one: <code>git checkout %s</code></p>\n", substr(VH[v], 1, 8) > f
    print "<nav class=\"flip\">" > f
    if (v > 1) printf "<a class=\"prev\" rel=\"prev\" href=\"v%d.html\">&#9664; v%d</a>\n", v - 1, v - 1 > f
    else       print "<span class=\"prev none\">&#9664; the first</span>" > f
    print "<a class=\"up\" href=\"index.html\">CONTENTS</a>" > f
    if (v < total) printf "<a class=\"next\" rel=\"next\" href=\"v%d.html\">v%d &#9654;</a>\n", v + 1, v + 1 > f
    else           print "<span class=\"next none\">on the cabinet &#9654;</span>" > f
    print "</nav>" > f
    print "<nav class=\"strip\" aria-label=\"every version\">" > f
    for (k = 1; k <= total; k++) {
      t = TICK[k]
      if (k == v) sub(/class="tick/, "class=\"tick here", t)
      print t > f
    }
    print "</nav>" > f
    print "</main>" > f
    # The arrow keys, because a book of pages that only turn by mouse is a
    # worse book, and because this cabinet is played on a keyboard.
    print "<script>" > f
    print "addEventListener(\"keydown\", function (e) {" > f
    print "  var to = { ArrowLeft: \".prev\", ArrowRight: \".next\", Escape: \".up\" }[e.key]" > f
    print "  var a = to ? document.querySelector(\"nav.flip \" + to) : null" > f
    print "  if (a && a.href) location.href = a.href" > f
    print "})" > f
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

/* --- one version, one page ------------------------------------------------
   A chapter fills the screen, is read in one look, and the next one is one
   arrow key away. It scrolls only when what is written on it will not fit,
   which is rare and still better than clipping somebody mid-sentence. */
body.page { padding: 0; overflow: hidden; }
.page main {
  max-width: 78rem;
  height: 100dvh;
  padding: clamp(0.7rem, 2vh, 1.4rem) clamp(0.9rem, 3vw, 2.4rem) clamp(0.5rem, 1.4vh, 1rem);
  /* a column rather than fixed rows: a chapter that grows a part later does
     not have to come back here and count them again */
  display: flex;
  flex-direction: column;
  gap: clamp(0.35rem, 1.1vh, 0.85rem);
  overflow-y: auto;
}
.plate {
  display: flex;
  flex-wrap: wrap;
  gap: 0.3rem 1.1rem;
  align-items: baseline;
  padding-bottom: 0.45rem;
  border-bottom: 1px dashed rgba(160, 75, 255, 0.3);
}
.num {
  font-size: 0.58rem;
  letter-spacing: 0.34em;
  color: var(--violet);
  text-shadow: 0 0 8px currentColor;
}
.ver { font-size: 0.58rem; letter-spacing: 0.2em; color: var(--cyan); }
.plate .who {
  margin-left: auto;
  font-size: 0.62rem;
  letter-spacing: 0.22em;
  text-transform: uppercase;
  color: var(--cyan);
  display: flex;
  align-items: center;
  gap: 0.55rem;
}
/* Whoever flew it, at the top of their own chapter, where there is room for
   them to be slightly more than a line of text. */
.plate .who .face {
  width: 4rem;
  height: 4rem;
  border-color: rgba(33, 243, 255, 0.55);
  box-shadow: 0 0 12px rgba(33, 243, 255, 0.35);
}
.plate .when {
  font-size: 0.58rem;
  letter-spacing: 0.14em;
  color: var(--dim);
  font-variant-numeric: tabular-nums;
}

/* What happened to the game, in letters you can read from the other side of
   the room. Every version has one, and on a page it is the whole headline. */
.shout {
  font-size: clamp(1.1rem, 3.3vw, 2.5rem);
  font-weight: 600;
  line-height: 1.14;
  /* the cover title is spaced out like a marquee; a sentence is not */
  letter-spacing: 0.01em;
  margin-right: 0;
  text-wrap: balance;
  background: linear-gradient(100deg,
    #ff3ec8, #ffb020, #b6ff3d, #21f3ff, #a04bff, #ff3ec8);
  background-size: 300% 100%;
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
  filter: drop-shadow(0 0 14px rgba(255, 62, 200, 0.35));
  animation: slide 9s linear infinite;
}

/* The plate: a painted scene of whatever the tagline says happened, asked for
   once by tools/chronicle-art.sh and kept in docs/art/ from then on. It is a
   band rather than a picture that fills the page, because the drawn field
   below it is the one that is actually about the commit, and because a chapter
   with no plate has to look deliberate rather than short of one. */
.plate-art {
  /* two shares against the drawn field's three, both flexible: on a laptop the
     band gives way first, because the field below is the one that is about the
     commit and it must never be the thing that gets squeezed out */
  flex: 2 1 0;
  min-height: 0;
  display: flex;
  flex-direction: column;
  border: 1px solid rgba(160, 75, 255, 0.28);
  background: #000;
}
.plate-art a { display: block; position: relative; flex: 1 1 auto; min-height: 0; line-height: 0; }
.plate-art img {
  display: block;
  width: 100%;
  height: 100%;
  max-height: min(34vh, 18rem);
  object-fit: cover;
  /* the book is a CRT and the plate did not come off one, so it is sent
     through the same glass as everything else on the page */
  filter: saturate(1.15) contrast(1.06);
  opacity: 0.92;
}
/* the scanline layer sits behind main, so the plate gets its own */
.plate-art a::after {
  content: "";
  position: absolute;
  inset: 0;
  pointer-events: none;
  background: repeating-linear-gradient(
    to bottom, rgba(0, 0, 0, 0.28) 0 1px, transparent 1px 3px);
}
.plate-art figcaption {
  padding-top: 0.25rem;
  font-size: 0.57rem;
  letter-spacing: 0.1em;
  color: var(--dim);
  text-align: center;
}

/* The commit, drawn: one rock per sector it touched, sized by how much of that
   sector moved, coloured by which part of the cabinet it was, dashed if it left
   the repository altogether. The ship is the pilot, taking a shot at the
   biggest thing they moved. None of it is random — tools/chronicle.sh seeds it
   with the commit hash, so a version looks the same in every clone forever. */
/* basis 0 rather than auto: the drawn field asks for whatever is left over
   instead of for its own natural height, so a chapter carrying a plate as well
   still fits on one screen and neither picture has to be told about the other */
.frame { flex: 3 1 0; display: flex; flex-direction: column; min-height: 6rem; }
.frame .art { flex: 1; min-height: 0; width: 100%; }
.frame figcaption {
  padding-top: 0.25rem;
  font-size: 0.57rem;
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

/* The numbers the commit made, in the vocabulary the rest of the book uses. */
.stats { list-style: none; display: flex; flex-wrap: wrap; gap: 0.4rem; }
.stats li {
  flex: 1 1 7rem;
  padding: 0.36rem 0.6rem;
  background: rgba(160, 75, 255, 0.08);
  border-left: 2px solid rgba(160, 75, 255, 0.5);
}
.stats b {
  display: block;
  font-size: 0.92rem;
  font-weight: 500;
  color: var(--cyan);
  font-variant-numeric: tabular-nums;
}
.stats span {
  font-size: 0.53rem;
  letter-spacing: 0.13em;
  text-transform: uppercase;
  color: var(--dim);
}

/* Forward, back, and out. The arrow keys do the same thing — see the script
   at the foot of every page. */
.flip {
  display: flex;
  gap: 1rem;
  align-items: baseline;
  justify-content: space-between;
  padding-top: 0.45rem;
  border-top: 1px dashed rgba(160, 75, 255, 0.3);
  font-size: 0.66rem;
  letter-spacing: 0.18em;
}
.flip a { color: var(--lime); text-decoration: none; text-shadow: 0 0 10px currentColor; }
.flip a:hover { color: var(--ink); }
.flip .up { color: var(--dim); text-shadow: none; letter-spacing: 0.3em; }
.flip .none { color: rgba(154, 134, 189, 0.4); }

/* Every version there has ever been, oldest first, always in reach. The two
   kinds of trouble are marked, so a reader can see where the book gets loud
   before they get there. */
.strip { position: relative; display: flex; flex-wrap: wrap; gap: 3px; }
.tick {
  min-width: 1.5rem;
  padding: 0.16rem 0.28rem;
  border: 1px solid rgba(160, 75, 255, 0.28);
  font-size: 0.54rem;
  text-align: center;
  color: var(--dim);
  text-decoration: none;
  font-variant-numeric: tabular-nums;
}
.tick:hover { color: var(--ink); border-color: var(--cyan); }
.tick.bent { border-color: rgba(255, 176, 32, 0.6); color: var(--amber); }
.tick.off {
  border-color: var(--magenta);
  color: var(--magenta);
  background: rgba(255, 62, 200, 0.12);
}
.tick.here { background: var(--cyan); border-color: var(--cyan); color: var(--void); }
/* The preview, parked at the left of the strip rather than over the tick, so
   that the first version and the last one both get a whole one. */
.tick::after {
  content: attr(data-t);
  position: absolute;
  left: 0;
  right: 0;
  bottom: calc(100% + 5px);
  padding: 0.42rem 0.7rem;
  background: rgba(12, 5, 24, 0.96);
  border: 1px solid var(--cyan);
  box-shadow: 0 0 20px rgba(33, 243, 255, 0.2);
  color: var(--ink);
  font-size: 0.6rem;
  line-height: 1.5;
  letter-spacing: 0.04em;
  text-align: left;
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.12s;
}
.tick:hover::after, .tick:focus::after { opacity: 1; }

.deed {
  font-size: 0.95rem;
  line-height: 1.7;
  color: var(--ink);
  text-wrap: pretty;
}
/* A version whose pilot wrote no Chronicle line reads as a gap in the record,
   and looks like one, so the next person can see what a missing chapter costs. */
.deed.untold {
  color: var(--dim);
  font-size: 0.82rem;
  font-style: italic;
}
.subj {
  margin-top: 0.4rem;
  font-size: 0.68rem;
  letter-spacing: 0.14em;
  color: var(--dim);
}
/* Something happened that was not a version: the rules moved, the book was
   rebuilt, somebody tidied. It goes in the record because everything goes in
   the record, but it never took a number, so it does not take a page either —
   it sits in the margin of whichever version was on the cabinet at the time. */
.meanwhile {
  margin-top: 0.55rem;
  padding-top: 0.45rem;
  border-top: 1px dotted rgba(160, 75, 255, 0.25);
}
.interlude {
  margin: 0 0 0.5rem;
  padding-left: 0.9rem;
  border-left: 1px dashed rgba(160, 75, 255, 0.22);
}
.between {
  font-size: 0.74rem;
  line-height: 1.7;
  letter-spacing: 0.06em;
  color: var(--dim);
}
.between b { color: var(--violet); font-weight: 500; }
.interlude .subj { margin-top: 0.25rem; font-size: 0.62rem; }

/* The four things the book records whether you like it or not. */
.override, .lawchange, .unrecorded, .ledger {
  margin-top: 0.6rem;
  padding: 0.42rem 0.7rem;
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

.play { margin-top: 0.6rem; font-size: 0.62rem; letter-spacing: 0.1em; color: var(--dim); }
.play code {
  color: var(--lime);
  background: rgba(182, 255, 61, 0.08);
  padding: 0.1rem 0.4rem;
  user-select: all;
}

@media (max-width: 34rem) {
  .roster table { font-size: 0.62rem; }
  .cv a { grid-template-columns: 2.9rem 1fr; }
  .cv i { display: none; }
  .ci { padding-left: 0.3rem; }
  .plate .who { margin-left: 0; }
}
/* A screen too short to hold a panel stops pretending, and becomes a page. */
@media (max-height: 34rem) {
  body.page { overflow: auto; }
  .page main { height: auto; min-height: 100dvh; }
}
@media (prefers-reduced-motion: reduce) {
  h1, .shout, .roster, .art * { animation: none; }
}
CSS

printf 'chronicle: %s version%s, a page each, and the cover at docs/index.html\n' \
  "$TOTAL" "$([ "$TOTAL" = 1 ] || echo s)"
