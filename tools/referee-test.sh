#!/bin/sh
# ---------------------------------------------------------------------------
# referee-test.sh - the referee, refereed.
#
# tools/golden-check.sh says yes or no to every commit that lands here, and
# until this file existed nothing said yes or no to it. Both of its failure
# modes are silent ones. A check that quietly stops firing turns a red line
# into a suggestion and the first anybody hears of it is a rule nobody kept.
# A check that fires when it should not is worse, because a referee that
# cries wolf gets skimmed past, and then the true ones go unread too.
#
# So: a miniature cabinet in a temporary directory, a scripted change made
# inside it, and an assertion about what the referee says. Two pilots live
# there - Ada Vex landed the first commit and owns the ground, Bo Renn turned
# up afterwards and owns one event file. The tests fly as Bo, which is the
# interesting seat: everything Bo touches is somebody else's.
#
# No dependencies, like everything else in tools/ (GR2). sh and git, and node
# only where the referee itself wants one.
#
#   tools/referee-test.sh            run them
#   tools/referee-test.sh -v         ... and print what the referee actually said
#
# Exit 0 = the referee behaves. Exit 1 = it does not.
#
# A case written with todo_ instead of case_ is a known-open bug in the
# referee: it runs, it reports, and it does not fail the suite. When somebody
# fixes the cause it starts saying "todo now passes", and whoever is passing
# promotes it to case_ and deletes the note.
# ---------------------------------------------------------------------------
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  printf 'referee-test: not a git repo\n' >&2; exit 1; }
cd "$ROOT" || exit 1

# Read the real repository once, above, and then stop being able to see it. A
# hook runs with git's environment exported into it - the directory, the index,
# and the name and address of whoever is halfway through committing - and every
# one of those is inherited by a shell this script starts. The cabinet below
# then does its git init, sets its own two pilots in its own config, and gets
# overruled from the outside: Ada Vex and Bo Renn commit under the name of the
# pilot at the keyboard, so a test that asks whose file this is gets the same
# answer for all of them and five red lines quietly stop being testable.
#
# The suite passes on a command line for exactly that reason, and fails from
# the hook that runs it - which is the wrong way round for the one thing here
# whose whole job is to be believed. So the environment goes, and the cabinet
# is a cabinet rather than a window onto this one.
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
MSG=$WORK/msg

OWNER="Ada Vex"     # the root commit is hers, so GR13's ground is hers
PILOT="Bo Renn"     # the seat every test flies from

if [ -t 1 ]; then
  R=$(printf '\033[31m'); G=$(printf '\033[32m'); D=$(printf '\033[2m'); Z=$(printf '\033[0m')
else
  R=''; G=''; D=''; Z=''
fi

OK=0; BAD=0; TODO=0; RIPE=0; SKIP=0
RULE=''; NAME=''; TODOING=0; DONE=0

# --- the miniature cabinet ---------------------------------------------------

# N lines of comment, so the budgets have something to bite on. Padding rather
# than plausible code: the referee counts lines, it does not read them.
pad() {
  i=1
  while [ "$i" -le "$2" ]; do printf '// %s %s\n' "$3" "$i" >> "$1"; i=$((i + 1)); done
}

# keep the first N lines of a file and drop the rest - how a test removes bulk
# from somebody else's work without pretending to have rewritten it
truncate_to() {
  awk -v n="$2" 'NR <= n' "$1" > "$1.cut" && mv "$1.cut" "$1"
}

build_cabinet() {
  mkdir -p "$CABINET/src/core" "$CABINET/src/game" "$CABINET/src/entities" \
           "$CABINET/src/events" "$CABINET/styles" "$CABINET/docs"
  cp -R "$ROOT/tools" "$CABINET/tools"
  cd "$CABINET" || exit 1

  git init -q .
  git config user.email lab@example.invalid
  git config user.name "$OWNER"
  git config commit.gpgsign false
  # the referee under test, never the one this clone has installed
  git config core.hooksPath "$CABINET/.git/hooks"

  cat > index.html <<'HTML'
<!doctype html>
<html>
  <head><link rel="stylesheet" href="styles/tokens.css"></head>
  <body><canvas id="field"></canvas><script src="src/boot.js"></script></body>
</html>
HTML

  echo ':root { --hue: 0; }' > styles/tokens.css
  echo '# THE LAB' > README.md
  printf '# THE LAB\n\nA cabinet the size of a postage stamp.\n' > CLAUDE.md
  printf '# THE GOLDEN RULES\n\nThirteen of them, elsewhere.\n' > GOLDEN_RULES.md
  printf '<!doctype html><html><body>the book</body></html>\n' > docs/index.html

  cat > src/boot.js <<'JS'
(function (A) {
  A.boot = function () { return A.MODULES.length; };
})(ASTEROIDS);
JS

  cat > src/features.js <<'JS'
ASTEROIDS.MODULES = [
  "./core/registry.js",
  "./core/loop.js",
  "./game/events.js",
  "./game/profile.js",
  "./game/tally.js",
  "./game/ledger.js",
  "./entities/rock.js",
  "./events/ada-vex.js",
];
JS

  cat > src/core/registry.js <<'JS'
(function (A) {
  const features = [];
  A.register = function (f) { features.push(f); return f; };
  A.features = features;
})(ASTEROIDS);
JS

  cat > src/core/loop.js <<'JS'
(function (A) {
  A.frame = function (tick) { return tick + 1; };
})(ASTEROIDS);
JS
  pad src/core/loop.js 100 "the loop, at length,"

  cat > src/game/events.js <<'JS'
(function (A) {
  A.HOUSE = "THE HOUSE";
  // GR11 lives on this line: an event never fires for the pilot who wrote it.
  A.armed = function (events, me) {
    return events.filter((e) => !(e.by !== A.HOUSE && e.by === me));
  };
})(ASTEROIDS);
JS

  cat > src/game/profile.js <<'JS'
(function (A) {
  A.activePilot = function () { return A.pilot || "GUEST"; };
})(ASTEROIDS);
JS

  cat > src/game/tally.js <<'JS'
(function (A) {
  A.bendsOf = function (who) { return (A.LEDGER || {})[who] || 0; };
})(ASTEROIDS);
JS

  cat > src/game/ledger.js <<'JS'
ASTEROIDS.LEDGER = {};
JS

  cat > src/entities/rock.js <<'JS'
(function (A) {
  A.register({
    order: 40,
    guide: { name: "ROCK", text: "it drifts, and then it splits" },
    update: function () {},
    draw: function () {},
  });
})(ASTEROIDS);
JS
  pad src/entities/rock.js 60 "rock, elaborated,"

  cat > "src/events/ada-vex.js" <<'JS'
(function (A) {
  A.EVENTS = (A.EVENTS || []).concat([{
    id: "closing-ring",
    by: "Ada Vex",
    at: 4,
    fire: function () {},
  }]);
})(ASTEROIDS);
JS

  git add -A >/dev/null
  git commit -qm "The lab opens for business" >/dev/null

  # The ledger is generated, so let the generator write it - a fixture that
  # disagreed with tools/tally.sh would fail GR12 in every test at once.
  sh tools/tally.sh >/dev/null 2>&1 || :
  if ! git diff --quiet -- src/game/ledger.js 2>/dev/null; then
    git add -A >/dev/null
    git commit -qm "The lab counts nobody, in writing" >/dev/null
  fi

  # Bo arrives, and brings one event. From here on this is Bo's seat.
  #
  # Written to look nothing like Ada's on purpose. git's rename detection will
  # call a similar new file a copy of the old one, and the referee asks git who
  # owns a file - see the todo case about templates, which is that bug with its
  # own name on it rather than a thing every other case trips over.
  git config user.name "$PILOT"
  cat > "src/events/bo-renn.js" <<'JS'
(function (A) {
  const KRAKENS = 3;
  const SIDES = ["north", "east", "west"];

  function surface(side, wave) {
    return { side: side, wave: wave, teeth: 8, warned: true };
  }

  A.EVENTS = (A.EVENTS || []).concat([{
    id: "three-krakens",
    by: "Bo Renn",
    at: 6,
    banner: "SOMETHING IS COMING UP FROM UNDERNEATH",
    fire: function (wave) {
      const out = [];
      for (let i = 0; i < KRAKENS; i++) out.push(surface(SIDES[i], wave));
      return out;
    },
  }]);
})(ASTEROIDS);
JS
  awk '/^\];$/ && !d { print "  \"./events/bo-renn.js\","; d = 1 } { print }' \
    src/features.js > src/features.new && mv src/features.new src/features.js
  git add -A >/dev/null
  git commit -qm "Bo Renn lays the first event of the evening" >/dev/null
  cd "$ROOT" || exit 1
}

# --- running the referee -----------------------------------------------------

fresh() { rm -rf "$LAB"; cp -R "$CABINET" "$LAB"; cd "$LAB" || exit 1; }

stage() { git add -A >/dev/null 2>&1; }

# land it and come back tomorrow - a file has no owner until it has a commit
land() { git add -A >/dev/null 2>&1; git commit -qm "$1" >/dev/null 2>&1; }

# what the hooks see: the staged change, at one of the two hook stages
check() {
  st=$1; shift
  sh tools/golden-check.sh --staged --stage "$st" "$@" > "$OUT" 2>&1
  CODE=$?
}

# what a pilot at work sees: the working tree, untracked files and all
check_tree() {
  sh tools/golden-check.sh "$@" > "$OUT" 2>&1
  CODE=$?
}

message() { printf '%s\n' "$@" > "$MSG"; }

# the referee pads the rule to four columns, so GR1 arrives as "GR1 ". The
# marker goes in brackets because "?" is a quantifier everywhere else.
said() { grep -Eq "^ [$1] $2 " "$OUT"; }

# --- cases and their verdicts ------------------------------------------------

case_() { RULE=$1; NAME=$2; TODOING=0; DONE=0; fresh; }
todo_() { RULE=$1; NAME=$2; TODOING=1; DONE=0; fresh; }

report() {
  printf '  %s%-5s%s %-5s %s\n' "$2" "$1" "$Z" "$RULE" "$NAME"
  [ -n "${3:-}" ] && printf '        %s%s%s\n' "$D" "$3" "$Z"
  { [ "$VERBOSE" = 1 ] || [ "$1" = FAIL ]; } && sed 's/^/        | /' "$OUT"
  return 0
}

# One verdict per case. Called twice by mistake, the second is the one nobody
# asked for, so the first wins and the rest is noise.
verdict() {
  [ "$DONE" = 1 ] && return 0
  DONE=1
  if [ "$TODOING" = 1 ]; then
    if [ "$1" = yes ]; then RIPE=$((RIPE + 1)); report "todo" "$D" "now passes - promote it to case_"
    else TODO=$((TODO + 1)); report "todo" "$D" "$2"; fi
    return 0
  fi
  if [ "$1" = yes ]; then OK=$((OK + 1)); report "ok" "$G"
  else BAD=$((BAD + 1)); report "FAIL" "$R" "$2"; fi
}

skip() { SKIP=$((SKIP + 1)); DONE=1; report "skip" "$D" "$1"; }

blocks() {
  if ! said '!' "$1"; then verdict no "expected a block on $1, got none"
  elif [ "$CODE" != 1 ]; then verdict no "$1 was named but the referee exited $CODE"
  else verdict yes; fi
}

lands() {
  if said '!' '[A-Z0-9]*'; then verdict no "blocked, and it should not have"
  elif [ "$CODE" != 0 ]; then verdict no "nothing was blocked but the referee exited $CODE"
  else verdict yes; fi
}

nudges() {
  if said '!' '[A-Z0-9]*'; then verdict no "blocked, where a nudge was the whole point"
  elif ! said '?' "$1"; then verdict no "expected a nudge about $1, got none"
  else verdict yes; fi
}

silent() {
  if said '!' "$1" || said '?' "$1"; then verdict no "$1 spoke up about work that does not concern it"
  else verdict yes; fi
}

# --- the tests ---------------------------------------------------------------

build_cabinet
printf '\n  REFEREE TESTS  %stools/golden-check.sh%s\n\n' "$D" "$Z"

case_ GR1 "ordinary work in your own file goes through in silence"
  printf '// one more line\n' >> src/events/bo-renn.js
  stage; check pre-commit
  lands

case_ GR1 "a module that does not parse"
if command -v node >/dev/null 2>&1; then
  printf '(function (A) {\n  A.oops = ;\n' > src/entities/comet.js
  stage; check pre-commit
  blocks GR1
else
  skip "no node here, and the parse check needs one"
fi

case_ GR1 "the manifest lists a module that does not ship"
  awk '/^\];$/ && !d { print "  \"./entities/ghost.js\","; d = 1 } { print }' \
    src/features.js > f && mv f src/features.js
  stage; check pre-commit
  blocks GR1

case_ GR1 "the front door loads something that is not there"
  awk '{ sub(/<script src="src\/boot.js">/, "<script src=\"src/nope.js\">"); print }' \
    index.html > f && mv f index.html
  stage; check pre-commit
  blocks GR1

case_ GR2 "a package manager arrives"
  printf '{ "name": "asteroids" }\n' > package.json
  stage; check pre-commit
  blocks GR2

case_ GR2 "a module that reaches for the network"
  printf '(function (A) {\n  A.phone = function () { return fetch("/scores"); };\n})(ASTEROIDS);\n' \
    > src/entities/comet.js
  stage; check pre-commit
  blocks GR2

case_ GR2 "a generated page may quote the ban it exists to state"
  printf '<!doctype html><html><body>no fetch( and no XMLHttpRequest</body></html>\n' > docs/index.html
  stage; check pre-commit
  silent GR2

case_ GR7 "a file that signs itself in a comment"
  printf '// @author Bo Renn\n(function (A) { A.x = 1; })(ASTEROIDS);\n' > src/entities/comet.js
  stage; check pre-commit
  blocks GR7

case_ GR10 "the rules and the game moving together"
  printf '\nA new paragraph of rules.\n' >> CLAUDE.md
  printf '// and a tune\n' >> src/events/bo-renn.js
  stage; check pre-commit
  blocks GR10

case_ GR10 "a rule change with no reason on the record"
  printf '\nA new paragraph of rules.\n' >> CLAUDE.md
  stage; message "Quietly widen my own permissions"
  check commit-msg --message-file "$MSG"
  blocks GR10

case_ GR10 "a rule change that says why, landing alone"
  printf '\nA new paragraph of rules.\n' >> CLAUDE.md
  stage; message "The rules learn a new paragraph" "" \
                 "Rule-Change: the lab needed somewhere to put this"
  check commit-msg --message-file "$MSG"
  lands

case_ GR11 "another pilot's event file is not yours to touch"
  printf '// a small improvement, surely\n' >> "src/events/ada-vex.js"
  stage; check pre-commit
  blocks GR11

case_ GR11 "another pilot's event file is not yours to delete"
  rm "src/events/ada-vex.js"
  awk '!/ada-vex/' src/features.js > f && mv f src/features.js
  stage; check pre-commit
  blocks GR11

case_ GR11 "another pilot's event file is not yours to rename"
  git mv "src/events/ada-vex.js" "src/events/bo-renn-spoils.js" >/dev/null 2>&1
  awk '{ sub(/ada-vex/, "bo-renn-spoils"); print }' \
    src/features.js > f && mv f src/features.js
  stage; check pre-commit
  blocks GR11

case_ GR11 "nor yours to rename and sign your own name to"
  git mv "src/events/ada-vex.js" "src/events/bo-renn-spoils.js" >/dev/null 2>&1
  awk '{ sub(/by: "Ada Vex"/, "by: \"Bo Renn\""); print }' \
    "src/events/bo-renn-spoils.js" > f && mv f "src/events/bo-renn-spoils.js"
  awk '{ sub(/ada-vex/, "bo-renn-spoils"); print }' \
    src/features.js > f && mv f src/features.js
  stage; check pre-commit
  blocks GR11

case_ GR11 "your own event is yours to move wherever you like"
  git mv "src/events/bo-renn.js" "src/events/bo-renn-the-first.js" >/dev/null 2>&1
  awk '{ sub(/bo-renn\.js/, "bo-renn-the-first.js"); print }' \
    src/features.js > f && mv f src/features.js
  stage; check pre-commit
  lands

case_ GR11 "the runner does not get moved out of the way either"
  git mv src/game/events.js src/game/event-runner.js >/dev/null 2>&1
  awk '{ sub(/game\/events\.js/, "game/event-runner.js"); print }' \
    src/features.js > f && mv f src/features.js
  stage; check pre-commit
  blocks GR11

case_ GR11 "an event signed with a name that is not yours"
  awk '{ sub(/by: "Bo Renn"/, "by: \"Ada Vex\""); print }' \
    "src/events/bo-renn.js" > f && mv f "src/events/bo-renn.js"
  stage; check pre-commit
  blocks GR11

case_ GR11 "the runner losing the guard the whole mechanic rests on"
  # Every token of the real guard is still in here, in an order that does not
  # guard anything - which is what a refactor that means no harm actually looks
  # like. A check that has been loosened to grep for the words rather than the
  # shape lets this through, and this case is the only thing that would notice.
  cat > src/game/events.js <<'JS'
(function (A) {
  A.HOUSE = "THE HOUSE";
  A.armed = function (events, me) {
    return events.filter((e) => e.by === me || e.by !== A.HOUSE);
  };
})(ASTEROIDS);
JS
  stage; check pre-commit
  blocks GR11

case_ GR11 "your own event is yours to rewrite from scratch"
  cat > "src/events/bo-renn.js" <<'JS'
(function (A) {
  A.EVENTS = (A.EVENTS || []).concat([{
    id: "the-ring-closes",
    by: "Bo Renn",
    at: 9,
    fire: function () {},
  }]);
})(ASTEROIDS);
JS
  stage; check pre-commit
  lands

case_ GR13 "the orb's song is not a stranger's to retune"
  awk '{ print } index($0, "cat > docs/chronicle-song.js <<") == 1 { print "// lab" }' \
    tools/chronicle.sh > f && mv f tools/chronicle.sh
  stage; check pre-commit
  blocks GR13

case_ GR13 "the rest of that script is ordinary work"
  printf '\n# a passing thought about the book\n' >> tools/chronicle.sh
  stage; check pre-commit
  lands

case_ GR4 "gutting another pilot's feature"
  truncate_to src/entities/rock.js 20
  stage; message "Trim the rock a little"
  check commit-msg --message-file "$MSG"
  blocks GR4

case_ GR4 "the same cut, with the budget spent out loud"
  truncate_to src/entities/rock.js 20
  stage; message "The rock loses its long tail" "" \
                 "Golden-Rule-Override: GR4 - Ada agreed the padding was dead weight"
  check commit-msg --message-file "$MSG"
  lands

case_ GR4 "tuning another pilot's numbers is everybody's business"
  awk '{ sub(/order: 40/, "order: 55"); print }' \
    src/entities/rock.js > f && mv f src/entities/rock.js
  stage; message "The rock sits a little later in the frame"
  check commit-msg --message-file "$MSG"
  lands

# The cuts below are shallower than the ones above, and that is the whole test.
# Take enough out and git stops calling it a rename at all - it reports a delete
# and an add, the delete lands in the list GR4 has always read, and the case
# passes without the rename ever being asked about. Every move here leaves more
# than half the file behind, so git reports the pair and nothing else does.
case_ GR4 "the same cut, with the file carried out under a new name"
  git mv src/entities/rock.js src/entities/boulder.js >/dev/null 2>&1
  truncate_to src/entities/boulder.js 40
  awk '{ sub(/rock\.js/, "boulder.js"); print }' \
    src/features.js > f && mv f src/features.js
  stage; message "The rock is a boulder now, and shorter"
  check commit-msg --message-file "$MSG"
  blocks GR4

case_ GR4 "the same move, with the budget spent out loud"
  git mv src/entities/rock.js src/entities/boulder.js >/dev/null 2>&1
  truncate_to src/entities/boulder.js 40
  awk '{ sub(/rock\.js/, "boulder.js"); print }' \
    src/features.js > f && mv f src/features.js
  stage; message "The rock is a boulder now, and shorter" "" \
                 "Golden-Rule-Override: GR4 - Ada wanted the name and agreed to the cut"
  check commit-msg --message-file "$MSG"
  lands

case_ GR4 "your own feature is yours to rename and yours to cut"
  printf '(function (A) {\n  A.comet = { tail: 9 };\n})(ASTEROIDS);\n' > src/entities/comet.js
  pad src/entities/comet.js 60 "comet, elaborated,"
  awk '/^\];$/ && !d { print "  \"./entities/comet.js\","; d = 1 } { print }' \
    src/features.js > f && mv f src/features.js
  land "Bo Renn brings a comet, and it comes in threes"
  git mv src/entities/comet.js src/entities/comets.js >/dev/null 2>&1
  truncate_to src/entities/comets.js 35
  awk '{ sub(/comet\.js/, "comets.js"); print }' \
    src/features.js > f && mv f src/features.js
  stage; message "The comet was always plural"
  check commit-msg --message-file "$MSG"
  lands

case_ GR5 "carving a hole in the commons"
  truncate_to src/core/loop.js 20
  stage; message "The loop loses most of itself"
  check commit-msg --message-file "$MSG"
  blocks GR5

case_ GR5 "the commons does not stop being commons on the way out of it"
  pad src/core/loop.js 100 "the loop, at greater length,"
  land "The loop has more to say for itself"
  git mv src/core/loop.js src/game/loop.js >/dev/null 2>&1
  truncate_to src/game/loop.js 130
  awk '{ sub(/core\/loop\.js/, "game/loop.js"); print }' \
    src/features.js > f && mv f src/features.js
  stage; message "The loop moves house, and leaves a good deal behind"
  check commit-msg --message-file "$MSG"
  blocks GR5

case_ GR6 "more than one surprise in a commit"
  pad src/entities/comet.js 1300 "comet,"
  stage; message "Everything, all at once"
  check commit-msg --message-file "$MSG"
  blocks GR6

case_ GR6 "the book is generated and does not count against you"
  pad docs/v9.html 1300 "the ninth chapter,"
  stage; message "The book gains a long chapter"
  check commit-msg --message-file "$MSG"
  lands

case_ GR12 "nobody deletes their own record"
  rm src/game/ledger.js
  awk '!/ledger/' src/features.js > f && mv f src/features.js
  stage; check pre-commit
  blocks GR12

case_ GR12 "a ledger that does not say what the history says"
  printf 'ASTEROIDS.LEDGER = { "Bo Renn": { bends: 0, clean: 99 } };\n' > src/game/ledger.js
  stage; message "The ledger is feeling generous"
  check commit-msg --message-file "$MSG"
  blocks GR12

# GR14 counts off the history like everything else here, and in this lab the
# commit that added tools/flights.sh is the root commit - so the meter starts at
# the beginning and Bo's one event is already one landing against it.
fly() { printf '// wave %s, retuned\n' "$1" >> "src/events/bo-renn.js"; }

case_ GR14 "a fourth version on the strength of one tape"
  fly 7; land "The event comes a wave later"
  fly 8; land "The event comes later still"
  fly 9
  stage; message "The event moves once more"
  check commit-msg --message-file "$MSG"
  blocks GR14

case_ GR14 "the same landing, with the budget spent out loud"
  fly 7; land "The event comes a wave later"
  fly 8; land "The event comes later still"
  fly 9
  stage; message "The event moves once more" "" \
                 "Golden-Rule-Override: GR14 - a one-line retune I have flown twice today"
  check commit-msg --message-file "$MSG"
  lands

case_ GR14 "the last landing the tape covers gets a word, not a wall"
  fly 7; land "The event comes a wave later"
  fly 8
  stage; message "The event comes later still"
  check commit-msg --message-file "$MSG"
  nudges GR14

case_ GR14 "work that leaves the cabinet alone leaves the meter alone"
  fly 7; land "The event comes a wave later"
  fly 8; land "The event comes later still"
  printf '\nA paragraph about the cabinet.\n' >> README.md
  stage; message "The README says what the cabinet is"
  check commit-msg --message-file "$MSG"
  silent GR14

case_ GR14 "flying it, ranking it and landing it is one sitting"
  fly 7; land "The event comes a wave later"
  fly 8; land "The event comes later still"
  fly 9
  printf '# THE FLIGHT RECORDS\n\n<!-- log -->\n' > docs/RANKINGS.md
  printf '**2026-08-08 · Bo Renn · 8400 · wave 5 · 5:03** — flew its own event.\n' \
    >> docs/RANKINGS.md
  # The receipt off the tape. Without it the line is a sentence somebody typed
  # and the meter does not read it - tools/evidence-test.sh is where that is
  # examined; here it just has to be a flight.
  printf '<!-- crc 5eaf00d1 -->\n' >> docs/RANKINGS.md
  stage; message "The event moves once more, and its author survived it"
  check commit-msg --message-file "$MSG"
  lands

case_ GR8 "a breach naming a pilot the history never saw"
  message "The table has a word about the shield" "" \
          "Golden-Rule-Breach: GR8 Nobody Here - the shield has no cost and no cooldown"
  check commit-msg --message-file "$MSG"
  blocks GR12

case_ GR8 "a breach naming a pilot who actually flew"
  message "The table has a word about the shield" "" \
          "Golden-Rule-Breach: GR8 Ada Vex - the shield has no cost and no cooldown"
  check commit-msg --message-file "$MSG"
  lands

case_ GR3 "a feature registering from outside the four homes"
  mkdir -p src/audio
  printf '(function (A) {\n  A.register({ draw: function () {} });\n})(ASTEROIDS);\n' \
    > src/audio/drone.js
  stage; check pre-commit
  nudges GR3

case_ GR9 "a new rock nobody can discover by playing"
  printf '(function (A) {\n  A.register({ order: 40, draw: function () {} });\n})(ASTEROIDS);\n' \
    > src/entities/comet.js
  awk '/^\];$/ && !d { print "  \"./entities/comet.js\","; d = 1 } { print }' \
    src/features.js > f && mv f src/features.js
  stage; check pre-commit
  nudges GR9

# The other answer GR9 takes: the guide turns away anything that briefs
# nobody, so a feature that says why it stays off the splash has answered the
# question rather than ducked it.
case_ GR9 "a feature that says why it stays off the splash"
  printf '(function (A) {\n  // No guide tile: it is scenery, and the guide briefs the flight.\n  A.register({ order: 40, draw: function () {} });\n})(ASTEROIDS);\n' \
    > src/entities/dust.js
  awk '/^\];$/ && !d { print "  \"./entities/dust.js\","; d = 1 } { print }' \
    src/features.js > f && mv f src/features.js
  stage; check pre-commit
  silent GR9

# The pictures on the front door, which are not in the diff and go stale
# without anybody touching them. The lab has none until a case hangs some, so
# every other test in here answers this one in a single git log.
poster() { mkdir -p media; printf 'a photograph of the cabinet, %s\n' "$1" > media/cabinet.png; }
landings() {
  i=1
  while [ "$i" -le "$1" ]; do fly "$i"; land "The event comes a wave later"; i=$((i + 1)); done
}

case_ GR9 "the pictures on the wall are of a cabinet nobody can play"
  poster one; land "The pictures on the wall are of the game in the cabinet"
  landings 12
  fly 13
  stage; check pre-commit
  nudges GR9

case_ GR9 "the same landing, with the pictures reshot in it"
  poster one; land "The pictures on the wall are of the game in the cabinet"
  landings 12
  poster later; fly 13
  stage; check pre-commit
  silent GR9

case_ GR9 "a poster that is still of this week's cabinet"
  poster one; land "The pictures on the wall are of the game in the cabinet"
  landings 2
  fly 3
  stage; check pre-commit
  silent GR9

# The meter counts versions, so the thing that leaves the cabinet alone leaves
# the pictures as true as it found them - however long the poster has hung.
case_ GR9 "work that leaves the cabinet alone leaves the poster alone"
  poster one; land "The pictures on the wall are of the game in the cabinet"
  landings 12
  printf '\nA paragraph about the cabinet.\n' >> README.md
  stage; check pre-commit
  silent GR9

# The spine. Bo already has one landing in the fixture - the event they arrived
# with - so `landings N` leaves them on N + 1, and the case stages the one
# after that. Ada takes her turn in src/entities/rock.js rather than in Bo's
# event file, because a handover that trips GR11 on the way past would be
# testing the wrong rule.
elsewhere() { git config user.name "$OWNER"; }
backagain()  { git config user.name "$PILOT"; }

case_ GR15 "four in a row is nobody's business"
  landings 2
  fly 9
  stage; check pre-commit
  silent GR15

case_ GR15 "the fifth version in a row gets a sentence"
  landings 3
  fly 9
  stage; check pre-commit
  nudges GR15

case_ GR15 "the sixth does not get it again"
  landings 4
  fly 9
  stage; check pre-commit
  silent GR15

case_ GR15 "the tenth does"
  landings 8
  fly 9
  stage; check pre-commit
  nudges GR15

# The thing the rule is actually for. Somebody else landing one breaks the run,
# and the pilot who picks the keyboard back up starts a spine of their own.
case_ GR15 "a handover starts the count again"
  landings 3
  elsewhere
  printf '// Ada takes a turn\n' >> src/entities/rock.js
  land "Ada has a go at the rock"
  backagain
  fly 9
  stage; check pre-commit
  silent GR15

case_ GR15 "work that leaves the cabinet alone is not a turn at the keyboard"
  landings 8
  printf '\nA paragraph about the cabinet.\n' >> README.md
  stage; check pre-commit
  silent GR15

# GR16 is nearly all honour, and this is the one edge of it a machine can see:
# a tape is a thing the game prints on a screen, so a tape sitting in the
# repository as a file was made rather than flown.
case_ GR16 "a tape written into the cabinet is not a flight"
  printf ';; -- FLIGHT RECORD --\nBB1:0000 eyJ2IjoxLCJwaWxvdCI6IkJvIFJlbm4ifQ==\n' > flight.txt
  printf 'BB1:CRC deadbeef :: END OF TAPE\n' >> flight.txt
  stage; check pre-commit
  blocks GR16

# The writer, the reader and the fixtures all say BB1: constantly. None of them
# is carrying one, which is the whole reason the check is anchored.
case_ GR16 "the machinery may talk about tapes without holding one"
  printf '(function (A) {\n  A.seal = function (i, s) { return "BB1:" + i + " " + s; };\n})(ASTEROIDS);\n' \
    > src/entities/comet.js
  stage; check pre-commit
  silent GR16

case_ GR16 "a flight on the board is a checksum, and a checksum is not a tape"
  # The row and the flight it came off, which is the shape the ritual files
  # now: the sum on the board, the bytes it was taken over in docs/tapes, and
  # the referee able to tell you a year from now that the two still agree.
  printf -- '- Bo Renn - 4200 - wave 6 - died with the bomb still in the rack\n' > docs/RANKINGS.md
  printf -- '<!-- crc 79e0d8c7 -->\n' >> docs/RANKINGS.md
  mkdir -p docs/tapes
  # Named after its own sum, like every filed flight. Change a byte of it and
  # the name stops being true, which is the next case down.
  printf '%s' '{"v":1,"pilot":"Bo Renn","whoami":"Bo Renn","score":4200}' \
    > docs/tapes/79e0d8c7.json
  stage; check pre-commit
  silent GR16

case_ GR16 "a row with no flight under it can never be read back, and is told so"
  # Warned rather than refused: every row that landed before anything was kept
  # is one of these, and a rule that opens by calling the record it inherited a
  # forgery is not one anybody would install.
  printf -- '- Bo Renn - 9900 - wave 9 - a very good evening indeed\n' > docs/RANKINGS.md
  printf -- '<!-- crc 5ea15ea1 -->\n' >> docs/RANKINGS.md
  stage; check pre-commit
  nudges GR16

case_ GR16 "a filed flight that does not answer to its own name"
  # The one thing filing them buys, and the reason the name is the sum.
  printf -- '<!-- crc c0ffee11 -->\n' > docs/RANKINGS.md
  mkdir -p docs/tapes
  printf '%s' '{"v":1,"pilot":"Bo Renn","score":999999}' > docs/tapes/c0ffee11.json
  stage; check pre-commit
  blocks GR16

case_ GR11 "an event started from somebody else's template is still yours"
  sed 's/closing-ring/quiet-ring/; s/Ada Vex/Bo Renn/; s/at: 4/at: 7/' \
    "src/events/ada-vex.js" > "src/events/bo-renn-two.js"
  awk '/^\];$/ && !d { print "  \"./events/bo-renn-two.js\","; d = 1 } { print }' \
    src/features.js > f && mv f src/features.js
  land "Bo Renn lays a second event, from the house template"
  printf '// tomorrow: make it meaner\n' >> "src/events/bo-renn-two.js"
  stage; check pre-commit
  lands

case_ GR10 "the second reading is refereed by the first"
  mkdir -p .github/workflows
  printf 'name: the referee\non: [pull_request]\n' > .github/workflows/referee.yml
  printf '// and a tweak while I am here\n' >> src/entities/rock.js
  stage; check pre-commit
  blocks GR10

case_ GR10 "a stray screenshot in the root is not the game moving"
  printf '\nA new paragraph of rules.\n' >> CLAUDE.md
  printf 'not a real screenshot\n' > shot.png
  check_tree
  silent GR10

case_ GR6 "a stray screenshot is not ten thousand lines of anything"
  printf 'not a real screenshot\n' > shot.png
  pad shot.png 2000 "binary, allegedly,"
  check_tree
  silent GR6

# The other half of that: staging it is the pilot saying it belongs, and then
# the referee has every right to an opinion about it again.
case_ GR10 "a screenshot the pilot actually staged still counts"
  printf '\nA new paragraph of rules.\n' >> CLAUDE.md
  printf 'a plate for the book\n' > plate.png
  stage; check pre-commit
  blocks GR10

case_ GR12 "the audit and the referee mean the same thing by 'the rules'"
  # Two readers decide what counts as referee machinery: is_referee in
  # golden-check.sh, and its twin in chronicle.sh that re-referees the history
  # for GR12. Divergence does not look like a bug. It looks like a pilot who
  # went round the referee - the audit decides a rule-only commit moved the
  # game as well, calls it a GR10 breach with nothing written down, and puts
  # two on somebody's tally for a commit the referee cleared. So both are asked
  # about every kind of path either of them knows.
  for p in CLAUDE.md GOLDEN_RULES.md .gitattributes .env.example \
           tools/nothing.sh .githooks/post-merge .github/workflows/referee.yml \
           .claude/settings.json .claude/skills/scout/SKILL.md; do
    mkdir -p "$(dirname "$p")" 2>/dev/null
    printf '# the rules move\n' >> "$p"
  done
  git add -A >/dev/null 2>&1
  git commit -q -m "Every kind of rule file at once

Rule-Change: to see whether both readers agree that is all this commit is" \
    >/dev/null 2>&1
  sh tools/chronicle.sh --skips > "$OUT" 2>&1
  if [ -s "$OUT" ]; then
    verdict no "the audit called a rule-only commit a red line breach - the lists have drifted"
  else
    verdict yes
  fi

case_ GR7 "the message the hooks prepare carries no number that can move"
  # Not tools/golden-check.sh, like the case above it: this is
  # .githooks/prepare-commit-msg, which writes what a pilot commits against. It
  # used to stamp Version: vN there, and a version number is counted off the
  # history rather than assigned - so the stamp was a second copy of a derived
  # number, written into the one place nobody may go back and correct (GR7).
  # The count has already moved once and left thirty-eight of them stale.
  #
  # The hook under test is the one in this working tree; it finds the lab for
  # itself, because it asks git where the root is and the lab is where this
  # runs. What is checked is both halves: no number, and the template it was
  # sharing a block with still arriving.
  printf '// one more line\n' >> src/entities/rock.js
  stage
  message "The rock grows a line"
  sh "$ROOT/.githooks/prepare-commit-msg" "$MSG" >/dev/null 2>&1
  cp "$MSG" "$OUT"
  if grep -qi '^Version:' "$MSG"; then
    verdict no "the hook wrote a number into a message nobody may rewrite"
  elif ! grep -q 'Tagline:' "$MSG"; then
    verdict no "the template lost the tagline offer along with the number"
  else
    verdict yes
  fi

# --- refereeing a pilot who is not in the room --------------------------------
#
# Everything above is the referee reading a tree somebody is standing in front
# of. --rev is the referee reading a commit that already exists, which is the
# only reading available when the work arrives from a clone that never ran
# --install. The interesting half is identity: the verdict has to follow the
# commit's author and the commit's message, not whoever happens to be running
# the check. These cases fly from Bo's seat and referee Ada's commits, so a
# reading that quietly used the local git config would come out wrong rather
# than come out empty.

# what the room sees afterwards: a commit that already exists
check_rev() {
  sh tools/golden-check.sh --rev "$1" > "$OUT" 2>&1
  CODE=$?
}

# a commit that went round the hooks entirely - which is every commit that
# arrives from a fork, and the whole reason --rev exists
sneak() {
  git add -A >/dev/null 2>&1
  git commit -q --no-verify -m "$1" >/dev/null 2>&1
}

case_ GR11 "another pilot's event, caught after the fact"
  printf '// Bo was here\n' >> "src/events/ada-vex.js"
  sneak "A small tidy-up of the events"
  check_rev HEAD
  blocks GR11

case_ GR11 "the same file, by the pilot it belongs to, reads clean"
  git config user.name "$OWNER"
  printf '  // Ada retunes her own ring\n' >> "src/events/ada-vex.js"
  sneak "The ring closes a little sooner"
  git config user.name "$PILOT"          # back to Bo, who is running the check
  check_rev HEAD
  lands

case_ GR10 "the rules and the game, one commit, read back later"
  printf '\nA new paragraph of rules.\n' >> CLAUDE.md
  printf '// and a tweak while I am here\n' >> src/entities/rock.js
  sneak "Tidying"
  check_rev HEAD
  blocks GR10

# Cut to 20 rather than to the bone, like the commit-msg cases above: rev mode
# runs GR1 as well, and a file cut mid-object stops parsing, which would be a
# different rule answering the question.
case_ GR4 "a budget spent out loud is still spent out loud in rev mode"
  truncate_to src/entities/rock.js 20
  sneak "The rock loses its long tail

Golden-Rule-Override: GR4 - Ada agreed the padding was dead weight"
  check_rev HEAD
  lands

case_ GR4 "the same cut with nothing written down, found later"
  truncate_to src/entities/rock.js 20
  sneak "The rock loses its long tail"
  check_rev HEAD
  blocks GR4

case_ GR1 "ordinary work in your own file is as quiet in rev mode as in the tree"
  printf '// one more line\n' >> src/events/bo-renn.js
  sneak "Bo keeps fiddling"
  check_rev HEAD
  lands

case_ GR10 "a range is every commit in it, judged one at a time"
  printf '// one more line\n' >> src/events/bo-renn.js
  sneak "A quiet one"
  printf '\nA new paragraph of rules.\n' >> CLAUDE.md
  printf '// and the game too\n' >> src/entities/rock.js
  sneak "A loud one"
  sh tools/golden-check.sh --range HEAD~2..HEAD > "$OUT" 2>&1
  CODE=$?
  blocks GR10

# --- the count ---------------------------------------------------------------

cd "$ROOT" || exit 1
printf '\n  %s ok' "$OK"
[ "$TODO" != 0 ] && printf ', %s todo' "$TODO"
[ "$RIPE" != 0 ] && printf ', %s todo now passing' "$RIPE"
[ "$SKIP" != 0 ] && printf ', %s skipped' "$SKIP"
[ "$BAD" != 0 ] && printf ', %s%s failed%s' "$R" "$BAD" "$Z"
printf '\n\n'

[ "$BAD" = 0 ] || exit 1
exit 0
