#!/bin/sh
# ---------------------------------------------------------------------------
# evidence-test.sh - the evidence, examined.
#
# GR14 is the one rule here that asks for something no machine can read off the
# source: proof that somebody pressed ENTER. The whole chain is two files.
# tools/blackbox.sh checks the seal on a tape, which is what makes a flight a
# flight rather than a line somebody typed. tools/flights.sh reads the meter off
# the board, which is what makes the promise cost anything. Neither of them had
# a scripted crime committed against it.
#
# That is the silence tools/referee-test.sh and tools/tally-test.sh were written
# to end everywhere else. A seal that quietly accepted a forged tape would rank
# an evening nobody spent; a meter that credited a landing to the courier rather
# than to the pilot would ground the wrong person and clear the wrong one.
# Neither failure has a symptom. The numbers still come out; they are just
# wrong, and the only reader is a rule that trusts them.
#
# Two parts:
#
#   the seal    tools/blackbox.sh, against tapes written the way the game
#               writes them. A good one reads back. A score raised after the
#               ship went down does not, nor a line added to the body, nor a
#               seal edited to suit. A borrowed seat is named rather than
#               refused, and that is the contract: the tape is intact, and what
#               such a run is worth is GR12's answer and the ritual's, not this
#               script's.
#   the meter   tools/flights.sh, against a scratch cabinet whose landings and
#               board are scripted. Whose tape a landing spends, what paperwork
#               costs, where the counting starts, and what a tape buys.
#
# The tapes below are written out whole, with the seal that belongs to each one
# beside it. That is deliberate: a fixture that computed its own checksum would
# be a second implementation agreeing with the first, and two copies of one
# mistake agree perfectly. These are FNV-1a over those exact bytes - what
# src/game/blackbox.js says it writes and what tools/blackbox.sh says it reads -
# so the numbers are the specification and both halves are held against it.
#
# No dependencies, like everything else in tools/ (GR2): sh, git, awk, and the
# base64 that tools/blackbox.sh already needs to read a tape at all.
#
#   tools/evidence-test.sh         run them
#   tools/evidence-test.sh -v      ... and print what the machinery said
#
# Exit 0 = the evidence chain holds. Exit 1 = it does not.
# ---------------------------------------------------------------------------
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  printf 'evidence-test: not a git repo\n' >&2; exit 1; }
cd "$ROOT" || exit 1

# Same reasoning as referee-test.sh and tally-test.sh: a hook exports git's
# environment into everything it starts, and a cabinet that inherits it is a
# window onto this repository rather than a cabinet of its own.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY \
      GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_QUARANTINE_PATH GIT_PREFIX \
      GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_AUTHOR_DATE \
      GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL GIT_COMMITTER_DATE \
      GIT_CONFIG GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM GIT_CONFIG_COUNT \
      GIT_REFLOG_ACTION GIT_EDITOR 2>/dev/null || true

VERBOSE=0
[ "${1:-}" = "-v" ] && VERBOSE=1

WORK=$(mktemp -d) || exit 1
trap 'rm -rf "$WORK"' EXIT INT TERM
CABINET=$WORK/cabinet
LAB=$WORK/lab
OUT=$WORK/out
BOARD=docs/RANKINGS.md

OWNER="Ada Vex"     # opens the cabinet, and lands one version before the rule
PILOT="Bo Renn"     # the seat most cases fly from

if [ -t 1 ]; then
  R=$(printf '\033[31m'); G=$(printf '\033[32m'); D=$(printf '\033[2m'); Z=$(printf '\033[0m')
else
  R=''; G=''; D=''; Z=''
fi

OK=0; BAD=0; SKIP=0
RULE=''; NAME=''; DONE=0

report() {
  printf '  %s%-5s%s %-5s %s\n' "$2" "$1" "$Z" "$RULE" "$NAME"
  [ -n "${3:-}" ] && printf '        %s%s%s\n' "$D" "$3" "$Z"
  { [ "$VERBOSE" = 1 ] && [ -s "$OUT" ]; } && sed 's/^/        | /' "$OUT"
  return 0
}

verdict() {
  [ "$DONE" = 1 ] && return 0
  DONE=1
  if [ "$1" = yes ]; then OK=$((OK + 1)); report "ok" "$G"
  else BAD=$((BAD + 1)); report "FAIL" "$R" "$2"; fi
}

skip() { SKIP=$((SKIP + 1)); DONE=1; report "skip" "$D" "$1"; }

# One verdict per case, the same as tally-test.sh: the whole observation is
# built into one string and compared against the whole expectation, so a case
# cannot half-pass.
expect() {
  if [ "$1" = "$2" ]; then verdict yes
  else verdict no "got \"$1\", wanted \"$2\""; fi
}

# a case that needs nothing but the reader under test
case_() { RULE=$1; NAME=$2; DONE=0; : > "$OUT"; cd "$ROOT" || exit 1; }

# a case that needs a cabinet of its own
lab() { case_ "$1" "$2"; rm -rf "$LAB"; cp -R "$CABINET" "$LAB"; cd "$LAB" || exit 1; }

# ---------------------------------------------------------------------------
# the seal
#
# Three tapes, spelled out. Each one is a flight somebody could really have had,
# written in the shape src/game/blackbox.js seals: a record object with its keys
# in the order that file writes them, because the reader is a shell script and
# that fixed order is the only reason it gets to read JSON at all.
#
# Do not retune a number in one of these without recutting its seal. That is not
# a maintenance burden, it is the point - a tape whose bytes and whose sum can
# be adjusted separately is exactly what this file exists to catch.
# ---------------------------------------------------------------------------

# Bo's own seat, two ambushes on the reel, one of which had him.
flown_json() {
  printf '%s' \
'{"v":1,"ts":"2026-08-09T21:04:11.006Z","pilot":"Bo Renn","whoami":"Bo Renn",' \
'"score":4200,"best":3980,"wave":3,"time":131.4,"shaves":9,' \
'"seats":[{"seat":"P1","shots":312,"hits":58,' \
'"rocks":{"large":6,"medium":17,"small":35},"nuked":0,"deaths":3,"bombs":1,' \
'"hooks":2,"kraken":{"hits":9,"kills":2},"dist":18.2,"top":361,"thrust":74.5,' \
'"flurry":7,"score":4200}],' \
'"events":[{"id":"three-krakens","by":"Ada Vex","wave":2,"deaths":1},' \
'{"id":"closing-ring","by":"Cy Null","wave":3,"deaths":0}]}'
}
FLOWN_CRC=0a0c99bb

# A short evening flown as Ada from Bo's locked cabinet - the borrowed name
# GR12 says is worth nothing, carried in the tape's own bytes.
borrowed_json() {
  printf '%s' \
'{"v":1,"ts":"2026-08-09T21:44:02.881Z","pilot":"Ada Vex","whoami":"Bo Renn",' \
'"score":900,"best":900,"wave":1,"time":41.2,"shaves":0,' \
'"seats":[{"seat":"P1","shots":44,"hits":9,' \
'"rocks":{"large":2,"medium":3,"small":4},"nuked":0,"deaths":3,"bombs":0,' \
'"hooks":0,"kraken":{"hits":0,"kills":0},"dist":3.1,"top":204,"thrust":19.8,' \
'"flurry":2,"score":900}],"events":[]}'
}
BORROWED_CRC=83c0e132

# A tape from before seats and reels were taped. Both fields are additive, so
# an old tape simply has neither, and the reader has to admit that rather than
# guess - which is the difference between an unlocked cabinet and a forgery.
old_json() {
  printf '%s' \
'{"v":1,"ts":"2026-07-02T19:12:55.400Z","pilot":"Cy Null","score":1610,' \
'"best":1610,"wave":2,"time":88.0,"shaves":3,' \
'"seats":[{"seat":"P1","shots":97,"hits":21,' \
'"rocks":{"large":3,"medium":7,"small":11},"nuked":0,"deaths":3,"bombs":0,' \
'"hooks":1,"kraken":{"hits":0,"kills":0},"dist":7.4,"top":288,"thrust":33.9,' \
'"flurry":3,"score":1610}]}'
}
OLD_CRC=cd4483e6

# The same pilot, a fortnight later, from a cabinet that was locked to him. On
# file this is what ages the tape above: one flight proving Cy's cabinet locks
# is what turns "no seat" from a fair question into a poor answer.
locked_json() {
  printf '%s' \
'{"v":1,"ts":"2026-07-14T20:31:09.120Z","pilot":"Cy Null","whoami":"Cy Null",' \
'"score":2040,"best":2040,"wave":2,"time":95.5,"shaves":4,' \
'"seats":[{"seat":"P1","shots":110,"hits":26,' \
'"rocks":{"large":4,"medium":8,"small":13},"nuked":0,"deaths":3,"bombs":0,' \
'"hooks":1,"kraken":{"hits":1,"kills":0},"dist":8.9,"top":301,"thrust":38.2,' \
'"flurry":4,"score":2040}],"events":[]}'
}
LOCKED_CRC=737df8c8

# A pilot the ledger was charging while she flew. The field she met is part of
# what her numbers mean, so the tape carries the row it read - and because the
# game reads that row off the working tree, this is the only place the rest of
# the room ever sees which one it was.
charged_json() {
  printf '%s' \
'{"v":1,"ts":"2026-08-02T18:22:40.010Z","pilot":"Ada Vex","whoami":"Ada Vex",' \
'"ledger":{"bends":4,"clean":3},' \
'"score":3120,"best":3120,"wave":3,"time":120.0,"shaves":5,' \
'"seats":[{"seat":"P1","shots":180,"hits":40,' \
'"rocks":{"large":5,"medium":11,"small":19},"nuked":0,"deaths":3,"bombs":1,' \
'"hooks":0,"kraken":{"hits":3,"kills":1},"dist":11.7,"top":330,"thrust":51.0,' \
'"flurry":6,"score":3120}],"events":[]}'
}
CHARGED_CRC=012cd673

# The tape around a record: the readable header nobody parses, the body base64'd
# into BB1: lines forty-eight characters wide, and the seal on the last line.
tape() {
  printf ';; -- HYPERCOLOR ASTEROIDS - BLACK BOX - FLIGHT RECORD --\n'
  printf ';; the tape survived the ship.\n'
  printf '%s' "$1" | base64 | tr -d '\n' | awk -v w=48 '
    { for (i = 1; i <= length($0); i += w) printf "BB1:%04x %s\n", i - 1, substr($0, i, w) }'
  printf 'BB1:CRC %s :: END OF TAPE\n' "$2"
}

# Read one, keeping the verdict and the exit code together.
read_tape() { sh tools/blackbox.sh "$1" > "$OUT" 2>&1; }

printf '\n  EVIDENCE TESTS  %stools/blackbox.sh, tools/flights.sh%s\n\n' "$D" "$Z"

case_ GR14 "a sealed tape reads back, and the flight comes out with it"
  tape "$(flown_json)" "$FLOWN_CRC" > "$WORK/tape"
  read_tape "$WORK/tape"; X=$?
  expect "exit=$X seal=$(grep -c "^SEAL INTACT (crc $FLOWN_CRC)\$" "$OUT") json=$(grep -c '"score":4200' "$OUT")" \
         "exit=0 seal=1 json=1"

case_ GR14 "a score raised after the ship went down ranks nowhere"
  tape "$(flown_json | sed 's/"score":4200/"score":9999/g')" "$FLOWN_CRC" > "$WORK/tape"
  read_tape "$WORK/tape"; X=$?
  expect "exit=$X broken=$(grep -c '^SEAL BROKEN' "$OUT") said=$(grep -c 'ranks nowhere' "$OUT")" \
         "exit=1 broken=1 said=1"

case_ GR14 "a line added to the body ranks nowhere either"
  # Forty-eight base64 characters is a whole number of bytes, so the doubled
  # line still decodes - it decodes to a different flight, which is the point.
  tape "$(flown_json)" "$FLOWN_CRC" \
    | awk '/^BB1:[0-9a-f]+ / && !d { print; d = 1 } { print }' > "$WORK/tape"
  read_tape "$WORK/tape"; X=$?
  expect "exit=$X broken=$(grep -c '^SEAL BROKEN' "$OUT")" "exit=1 broken=1"

case_ GR14 "editing the seal to suit is not a way round the seal"
  tape "$(flown_json)" 0a0c99bc > "$WORK/tape"
  read_tape "$WORK/tape"; X=$?
  expect "exit=$X broken=$(grep -c "^SEAL BROKEN: the tape says 0a0c99bc, the bytes says\{0,1\} $FLOWN_CRC" "$OUT")" \
         "exit=1 broken=1"

case_ GR14 "prose about a good evening is not a tape"
  printf 'i got to wave nine and it was the best flight of my life\n' \
    | sh tools/blackbox.sh > "$OUT" 2>&1; X=$?
  expect "exit=$X said=$(grep -c '^no tape here' "$OUT")" "exit=2 said=1"

case_ GR12 "a borrowed seat is named on the tape rather than hidden by it"
  # Not refused: the seal is intact and the numbers are real. What such a run
  # is worth is GR12's answer, and the ritual in .claude/skills/blackbox is
  # where the refusing happens. This is the reader saying enough for it to.
  tape "$(borrowed_json)" "$BORROWED_CRC" > "$WORK/tape"
  read_tape "$WORK/tape"; X=$?
  expect "exit=$X seal=$(grep -c '^SEAL INTACT' "$OUT") seat=$(grep -c \
          "^SEAT MISMATCH: flown as Ada Vex from Bo Renn's seat" "$OUT")" \
         "exit=0 seal=1 seat=1"

case_ GR14 "a tape sealed from its own seat says so"
  tape "$(flown_json)" "$FLOWN_CRC" > "$WORK/tape"
  read_tape "$WORK/tape"
  expect "$(grep -c '^SEAT CONFIRMED: Bo Renn flew this from their own seat\.' "$OUT")" "1"

case_ GR14 "an older tape admits what it does not carry"
  tape "$(old_json)" "$OLD_CRC" > "$WORK/tape"
  read_tape "$WORK/tape"; X=$?
  expect "exit=$X seat=$(grep -c '^NO SEAT ON TAPE' "$OUT") reel=$(grep -c '^NO EVENT REEL' "$OUT")" \
         "exit=0 seat=1 reel=1"

case_ GR12 "a missing seat ages: this name has flown from a locked one before"
  # The filed flights are what answers it. "No seat" used to mean an old tape
  # and a lock somebody removed on the way to borrowing a name, with no way to
  # tell the two apart, so the reader asked politely about both. One flight on
  # file under this pilot with a seat in it settles which one this is.
  mkdir -p "$WORK/seat/docs/tapes" "$WORK/seat/tools"
  cp "$ROOT/tools/blackbox.sh" "$WORK/seat/tools/blackbox.sh"
  printf '%s' "$(locked_json)" > "$WORK/seat/docs/tapes/$LOCKED_CRC.json"
  tape "$(old_json)" "$OLD_CRC" > "$WORK/tape"
  ( cd "$WORK/seat" && sh tools/blackbox.sh "$WORK/tape" ) > "$OUT" 2>&1; X=$?
  expect "exit=$X aged=$(grep -c '^SEAT UNPROVEN' "$OUT") old=$(grep -c '^NO SEAT ON TAPE' "$OUT")" \
         "exit=0 aged=1 old=0"

case_ GR12 "a name with no flight on file is still given the benefit of the doubt"
  # The mirror, and the reason the verdict is worth having: a pilot whose
  # cabinet nobody has ever seen locked is exactly who the gentle reading is
  # for, and they keep it.
  mkdir -p "$WORK/noseat/docs/tapes" "$WORK/noseat/tools"
  cp "$ROOT/tools/blackbox.sh" "$WORK/noseat/tools/blackbox.sh"
  printf '%s' "$(flown_json)" > "$WORK/noseat/docs/tapes/$FLOWN_CRC.json"
  tape "$(old_json)" "$OLD_CRC" > "$WORK/tape"
  ( cd "$WORK/noseat" && sh tools/blackbox.sh "$WORK/tape" ) > "$OUT" 2>&1; X=$?
  expect "exit=$X old=$(grep -c '^NO SEAT ON TAPE' "$OUT") aged=$(grep -c '^SEAT UNPROVEN' "$OUT")" \
         "exit=0 old=1 aged=0"

case_ GR12 "the field a flight was flown under is read off the tape, not asked about"
  tape "$(charged_json)" "$CHARGED_CRC" > "$WORK/tape"
  read_tape "$WORK/tape"; X=$?
  expect "exit=$X field=$(grep -c '^THE FIELD IT FLEW: 4 bends, 3 clean' "$OUT")" \
         "exit=0 field=1"

case_ GR12 "a tape from before the ledger was sealed says nothing about it"
  tape "$(flown_json)" "$FLOWN_CRC" > "$WORK/tape"
  read_tape "$WORK/tape"
  expect "$(grep -c '^THE FIELD IT FLEW' "$OUT")" "0"

case_ GR16 "a filed flight is checked against the name it is filed under"
  # The whole point of filing one: the name is the sum, so the bytes answer for
  # themselves for as long as the repository exists.
  printf '%s' "$(flown_json)" > "$WORK/filed.json"
  expect "$(sh tools/blackbox.sh --sum "$WORK/filed.json")" "$FLOWN_CRC"

case_ GR16 "--save writes the flight the seal was taken over, and no more"
  mkdir -p "$WORK/save"; ( cd "$WORK/save" && git init -q . )
  tape "$(flown_json)" "$FLOWN_CRC" > "$WORK/tape"
  ( cd "$WORK/save" && sh "$ROOT/tools/blackbox.sh" --save "$WORK/tape" ) > "$OUT" 2>&1
  expect "filed=$(grep -c '^FILED' "$OUT") sum=$(sh tools/blackbox.sh --sum \
          "$WORK/save/docs/tapes/$FLOWN_CRC.json" 2>/dev/null)" \
         "filed=1 sum=$FLOWN_CRC"

case_ GR11 "the reel names the event, its author, and what it cost"
  tape "$(flown_json)" "$FLOWN_CRC" > "$WORK/tape"
  read_tape "$WORK/tape"
  expect "had=$(grep -c '^  three-krakens (Ada Vex), wave 2 - died inside, 1 down$' "$OUT") clear=$(grep -c '^  closing-ring (Cy Null), wave 3 - flown clear$' "$OUT")" \
         "had=1 clear=1"

case_ GR14 "a flight with nothing thrown at it says that too"
  tape "$(borrowed_json)" "$BORROWED_CRC" > "$WORK/tape"
  read_tape "$WORK/tape"
  expect "$(grep -c '^NO AMBUSHES' "$OUT")" "1"

case_ GR14 "both halves of the pair seal with the same sum"
  # src/game/blackbox.js writes the tape and tools/blackbox.sh reads it, in two
  # languages, from two constants each. Nothing else in the cabinet would ever
  # notice them drifting apart: every tape sealed after the drift would read as
  # forged, and every tape sealed before it would too. Both are checked against
  # FNV-1a's own numbers rather than only against each other, so agreeing on a
  # wrong pair does not pass.
  jsoff=$(sed -n 's/.*h = 0x\([0-9a-fA-F][0-9a-fA-F]*\).*/\1/p' src/game/blackbox.js | head -1)
  jsprime=$(sed -n 's/.*h ^ b, 0x\([0-9a-fA-F][0-9a-fA-F]*\).*/\1/p' src/game/blackbox.js | head -1)
  shoff=$(sed -n 's/^ *h=\([0-9][0-9]*\) *$/\1/p' tools/blackbox.sh | head -1)
  shprime=$(sed -n 's/.*\* \([0-9][0-9]*\)) *&.*/\1/p' tools/blackbox.sh | head -1)
  expect "offset=$((0x${jsoff:-0}))/${shoff:-none} prime=$((0x${jsprime:-0}))/${shprime:-none}" \
         "offset=2166136261/2166136261 prime=16777619/16777619"

# ---------------------------------------------------------------------------
# the meter
#
# A cabinet the size of a postage stamp, built the way tally-test.sh builds
# its own. Two commits deep before any case starts, and the order of those two
# is the whole of the first case: Ada opens the cabinet with the game in it,
# and only then does tools/flights.sh arrive. GR14 counts nothing before the
# commit that added it, because before that there was no promise to keep.
# ---------------------------------------------------------------------------

build_cabinet() {
  mkdir -p "$CABINET/src/core" "$CABINET/src/game" "$CABINET/src/entities" \
           "$CABINET/styles" "$CABINET/docs"
  cp -R "$ROOT/tools" "$CABINET/tools"
  rm -f "$CABINET/tools/flights.sh"       # the rule has not landed yet
  cd "$CABINET" || exit 1

  git init -q .
  git config user.email lab@example.invalid
  git config user.name "$OWNER"
  git config commit.gpgsign false
  # hooks off: this measures one tool at a time, by hand
  git config core.hooksPath "$CABINET/.git/hooks"

  cat > index.html <<'HTML'
<!doctype html>
<html>
  <head><link rel="stylesheet" href="styles/tokens.css"></head>
  <body><canvas id="field"></canvas><script src="src/boot.js"></script></body>
</html>
HTML
  printf ':root { --hue: 0; }\n' > styles/tokens.css
  printf '# THE LAB\n' > README.md
  printf '# THE LAB\n\nA cabinet the size of a postage stamp.\n' > CLAUDE.md
  printf '# THE GOLDEN RULES\n\nFourteen of them, elsewhere.\n' > GOLDEN_RULES.md
  printf 'ASTEROIDS.MODULES = ["./core/registry.js"];\n' > src/features.js
  printf '(function (A) { A.boot = function () {}; })(ASTEROIDS);\n' > src/boot.js
  printf '(function (A) { A.register = function () {}; })(ASTEROIDS);\n' > src/core/registry.js
  printf 'ASTEROIDS.LEDGER = {};\n' > src/game/ledger.js
  printf '(function (A) { A.register({ id: "rock" }); })(ASTEROIDS);\n' > src/entities/rock.js
  printf '<!doctype html><html><body>a book</body></html>\n' > docs/index.html

  # The board, empty, with the marker the log is written under.
  cat > "$BOARD" <<'MD'
# THE FLIGHT RECORDS

## THE BOARD

| # | pilot | score | wave | time | accuracy | the flight in one line |
|---|-------|-------|------|------|----------|------------------------|

## THE FLIGHT LOG

Newest first. One line per tape.

<!-- log -->
MD

  git add -A >/dev/null
  git commit -qm "The lab opens for business" >/dev/null

  # ... and then the rule arrives, which is where the meter starts counting.
  cp "$ROOT/tools/flights.sh" tools/flights.sh
  git add -A >/dev/null
  git commit -qm "Fly what you land" \
             -m "Rule-Change: the lab needs a meter to be a lab about meters" >/dev/null
  cd "$ROOT" || exit 1
}

seat()  { git config user.name "$1"; }
land()  { git add -A >/dev/null 2>&1; git commit -q "$@" >/dev/null 2>&1; }
count() { sh tools/flights.sh --count "$1" 2>/dev/null; }

# One version: something in src/ moves, so the next pilot has something to find
# out by playing. That is the whole test chronicle.sh applies and this asks it.
version() { printf '// %s\n' "$1" >> src/entities/rock.js; land -m "$1"; }

# Real work that leaves the cabinet as it was.
paperwork() { printf '%s\n' "$1" >> README.md; land -m "$1"; }

# A line on the board naming a pilot, written but not landed - so a case can
# choose whether it rides in its own commit or alongside a version.
#
# The tape's checksum goes under it the way the ritual files it. A case that
# wants to know what an unsealed sentence buys passes an empty second argument;
# one that wants to paste somebody's evening twice passes the same one twice.
board() {
  awk -v who="$1" -v crc="${2-deadbeef}" '
    { print }
    /<!-- log -->/ && !done {
      printf "**2026-08-09 · %s · 4200 · wave 3 · 2:11** — a short evening, honestly flown.\n", who
      if (crc != "") printf "<!-- crc %s -->\n", crc
      done = 1
    }' "$BOARD" > "$BOARD.new" && mv "$BOARD.new" "$BOARD"
}

build_cabinet

case_ GR14 "one tape buys three landings, and the number has one home"
  # GR14's heading says it in words and tools/flights.sh says it as PER. Two
  # copies of a constant is one more than there should be, so this is what
  # keeps them the same copy.
  says=$(sed -n 's/^## GR14 .*budget: \([0-9][0-9]*\) versions per tape.*/\1/p' GOLDEN_RULES.md | head -1)
  expect "rule=${says:-none} tool=$(sh tools/flights.sh --per)" "rule=3 tool=3"

lab GR14 "nothing before the rule landed is counted"
  # Ada opened the cabinet with index.html, src/ and styles/ in one commit,
  # which is a version by any reading - and it landed before the meter did.
  expect "versions=$(sh tools/chronicle.sh --versions | awk 'END { print NR + 0 }') ada=$(count "$OWNER")" \
         "versions=1 ada=0"

lab GR14 "a pilot who has never flown is not spared the meter"
  # Pinning what the meter does today rather than deciding it here: never
  # having flown is not a shelter, it is three landings' worth of debt like
  # anybody else's, and --last has nothing to say about it.
  seat "$PILOT"
  version "The rock, elaborated"
  version "The rock, again"
  version "The rock, once more"
  sh tools/flights.sh --last "$PILOT" > "$OUT" 2>&1
  expect "last=$? said=[$(cat "$OUT")] bo=$(count "$PILOT")" "last=1 said=[] bo=3"

lab GR14 "two landings is the last one, three is grounded"
  seat "$PILOT"
  version "The rock, elaborated"
  one=$(sh tools/flights.sh --roll | grep -c "$PILOT.*1 since flying.*clear")
  version "The rock, again"
  two=$(sh tools/flights.sh --roll | grep -c "$PILOT.*2 since flying.*last one")
  version "The rock, once more"
  three=$(sh tools/flights.sh --roll | grep -c "$PILOT.*3 since flying.*GROUNDED")
  expect "one=$one two=$two three=$three" "one=1 two=1 three=1"

lab GR14 "a tape on the board clears the meter"
  seat "$PILOT"
  version "The rock, elaborated"
  version "The rock, again"
  version "The rock, once more"
  before=$(count "$PILOT")
  board "$PILOT"
  land -m "A tape on the board"
  sh tools/flights.sh --last "$PILOT" > "$OUT" 2>&1
  expect "before=$before last=$? after=$(count "$PILOT") said=[$(cat "$OUT")]" \
         "before=3 last=0 after=0 said=[2026-08-09 · 4200 · wave 3 · 2:11]"

lab GR14 "a couriered tape lands on the pilot the line names"
  # The crime this is here for: whoever holds the pen clearing their own meter
  # by ranking somebody else's evening. Both pilots are two landings deep, one
  # tape goes on the board, and only the pilot it names comes off the meter.
  seat "$OWNER"
  version "Ada's rock"
  version "Ada's rock, again"
  seat "$PILOT"
  version "Bo's rock"
  version "Bo's rock, again"
  board "$OWNER"
  land -m "Ada's tape, couriered by somebody who was not flying it"
  expect "ada=$(count "$OWNER") bo=$(count "$PILOT")" "ada=0 bo=2"

lab GR14 "a run of paperwork spends nobody's tape"
  seat "$PILOT"
  version "The rock, elaborated"
  version "The rock, again"
  before=$(count "$PILOT")
  paperwork "The README says a little more"
  paperwork "The README says more still"
  paperwork "The README says too much"
  paperwork "The README is trimmed back"
  expect "before=$before after=$(count "$PILOT")" "before=2 after=2"

lab GR14 "flying, ranking and landing in one sitting is one sitting"
  # GR14's own sentence, and the arithmetic that has to hold for it: the tape
  # clears the meter before the same commit spends it.
  seat "$PILOT"
  version "The rock, elaborated"
  version "The rock, again"
  printf '// the rock, once more\n' >> src/entities/rock.js
  board "$PILOT"
  land -m "Flew it, ranked it, landed it"
  expect "$(count "$PILOT")" "0"

# The crime the meter was built without an answer to: a pilot who cannot be
# bothered to fly writing themselves a receipt. The seal has never been
# checkable from the board - the tape itself is not kept - but the sum it
# printed is, and the ritual has always written it down. These four are what
# reading it turns out to be worth.
lab GR14 "a sentence with no seal under it is not a flight"
  seat "$PILOT"
  version "The rock, elaborated"
  version "The rock, again"
  version "The rock, once more"
  board "$PILOT" ""
  land -m "An evening I would like credit for"
  sh tools/flights.sh --last "$PILOT" > "$OUT" 2>&1
  expect "last=$? after=$(count "$PILOT") said=[$(cat "$OUT")]" "last=1 after=3 said=[]"

lab GR14 "the same tape pasted twice is one evening, not two"
  seat "$PILOT"
  board "$PILOT" c0ffee01
  land -m "Flew it and ranked it"
  version "The rock, elaborated"
  version "The rock, again"
  version "The rock, once more"
  board "$PILOT" c0ffee01
  land -m "The same evening, read out again"
  expect "$(count "$PILOT")" "3"

lab GR14 "a second evening is a second tape"
  seat "$PILOT"
  board "$PILOT" c0ffee01
  land -m "Flew it and ranked it"
  version "The rock, elaborated"
  version "The rock, again"
  version "The rock, once more"
  board "$PILOT" c0ffee02
  land -m "Flew it again, and this one is its own"
  expect "$(count "$PILOT")" "0"

lab GR14 "a receipt already spent buys nothing at the moment of a landing"
  # The one that matters most, because it is the one a pilot would actually
  # try: not a forged evening in the history, but an old crc re-pasted into
  # the commit that is about to be blocked. The referee asks about the index,
  # so the index is where the answer has to hold.
  seat "$PILOT"
  board "$PILOT" c0ffee03
  land -m "Flew it and ranked it"
  version "The rock, elaborated"
  version "The rock, again"
  version "The rock, once more"
  board "$PILOT" c0ffee03
  git add "$BOARD" >/dev/null 2>&1
  expect "staged=$(sh tools/flights.sh --staged --count "$PILOT")" "staged=3"

lab GR14 "a tape staged but not committed already counts"
  # What the referee asks at the moment of a landing, so that the sitting above
  # is a sitting rather than a rule violation caught halfway through itself.
  seat "$PILOT"
  version "The rock, elaborated"
  version "The rock, again"
  version "The rock, once more"
  board "$PILOT"
  git add "$BOARD" >/dev/null 2>&1
  expect "staged=$(sh tools/flights.sh --staged --count "$PILOT") plain=$(count "$PILOT")" \
         "staged=0 plain=3"

# --- the count ---------------------------------------------------------------

cd "$ROOT" || exit 1
printf '\n  %s ok' "$OK"
[ "$SKIP" != 0 ] && printf ', %s skipped' "$SKIP"
[ "$BAD" != 0 ] && printf ', %s%s failed%s' "$R" "$BAD" "$Z"
printf '\n\n'

[ "$BAD" = 0 ] || exit 1
exit 0
