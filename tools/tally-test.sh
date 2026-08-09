#!/bin/sh
# ---------------------------------------------------------------------------
# tally-test.sh - the sentence, sentenced.
#
# tools/referee-test.sh checks that the referee says yes and no at the right
# moments. This file checks everything that happens after the referee has
# spoken: what a bend actually costs, who gets charged for it, whether going
# round the referee really is noticed and really is worth two, and whether the
# number on the ledger reaches the field as the punishment GR12 promises. A
# verdict nobody prices is a warning; a price nobody collects is a bluff. Both
# fail silently, which is why this file exists.
#
# It is also the closest thing the cabinet has to an audit of the whole
# pipeline against a pilot who is actively trying to cheat it. Every scripted
# history below is a move somebody could really make - landing hookless from a
# clone that never ran --install, doctoring the ledger, writing a breach
# against a name that does not exist, force-pushing the scoreboard - and the
# assertion is that the machinery answers the way the rules say it does.
#
# Four parts:
#
#   the price       tools/tally.sh, against scripted histories. Bends cost
#                   one, skips cost two, receipts do not stack with the audit,
#                   a breach charges the pilot it names, mercy is arithmetic.
#   the receipts    .githooks/post-commit, driven directly. The ledger commit
#                   lands on its own, says the right number, and does not
#                   tally itself.
#   the scoreboard  .githooks/pre-push. main moves forward or not at all.
#   the field       node, loading src/game/tally.js and src/game/events.js -
#                   the real files, not copies - and asking them the GR12
#                   table line by line.
#
# No dependencies, like everything else in tools/ (GR2): sh, git, awk, and
# node only for the part that judges javascript.
#
#   tools/tally-test.sh            run them
#   tools/tally-test.sh -v         ... and print what the machinery said
#
# Exit 0 = the sentence lands. Exit 1 = it does not.
# ---------------------------------------------------------------------------
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  printf 'tally-test: not a git repo\n' >&2; exit 1; }
cd "$ROOT" || exit 1

# Same reasoning as referee-test.sh: a hook exports git's environment into
# everything it starts, and a cabinet that inherits it stops being a cabinet.
# ASTEROIDS_TALLY joins the list because the post-commit hook under test uses
# it to keep the ledger commit from tallying itself - inherited from outside,
# it would switch that hook off for every case at once.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY \
      GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_QUARANTINE_PATH GIT_PREFIX \
      GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_AUTHOR_DATE \
      GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL GIT_COMMITTER_DATE \
      GIT_CONFIG GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM GIT_CONFIG_COUNT \
      GIT_REFLOG_ACTION GIT_EDITOR ASTEROIDS_TALLY 2>/dev/null || true

VERBOSE=0
[ "${1:-}" = "-v" ] && VERBOSE=1

WORK=$(mktemp -d) || exit 1
trap 'rm -rf "$WORK"' EXIT INT TERM
CABINET=$WORK/cabinet
LAB=$WORK/lab
OUT=$WORK/out

OWNER="Ada Vex"     # roots the cabinet, owns one trap and the long rock
PILOT="Bo Renn"     # the seat every case flies from, and charges land on

if [ -t 1 ]; then
  R=$(printf '\033[31m'); G=$(printf '\033[32m'); D=$(printf '\033[2m'); Z=$(printf '\033[0m')
else
  R=''; G=''; D=''; Z=''
fi

OK=0; BAD=0; SKIP=0
RULE=''; NAME=''; DONE=0

# --- the miniature cabinet ---------------------------------------------------

pad() {
  i=1
  while [ "$i" -le "$2" ]; do printf '// %s %s\n' "$3" "$i" >> "$1"; i=$((i + 1)); done
}

build_cabinet() {
  mkdir -p "$CABINET/src/core" "$CABINET/src/game" "$CABINET/src/entities" \
           "$CABINET/src/events" "$CABINET/docs"
  mkdir -p "$CABINET/styles"
  cp -R "$ROOT/tools" "$CABINET/tools"
  cp -R "$ROOT/.githooks" "$CABINET/.githooks"
  cd "$CABINET" || exit 1

  git init -q .
  git config user.email lab@example.invalid
  git config user.name "$OWNER"
  git config commit.gpgsign false
  # hooks off: every case drives the machinery by hand, so that the thing
  # being measured is one moving part rather than all of them at once
  git config core.hooksPath "$CABINET/.git/hooks"

  cat > index.html <<'HTML'
<!doctype html>
<html>
  <head><link rel="stylesheet" href="styles/tokens.css"></head>
  <body><canvas id="field"></canvas><script src="src/boot.js"></script></body>
</html>
HTML

  echo ':root { --hue: 0; }' > styles/tokens.css
  printf '# THE LAB\n' > README.md
  printf '# THE LAB\n\nA cabinet the size of a postage stamp.\n' > CLAUDE.md
  printf '# THE GOLDEN RULES\n\nFourteen of them, elsewhere.\n' > GOLDEN_RULES.md
  printf '<!doctype html><html><body>a book</body></html>\n' > docs/index.html

  cat > src/boot.js <<'JS'
(function (A) {
  A.boot = function () { return A.MODULES.length; };
})(ASTEROIDS);
JS

  cat > src/features.js <<'JS'
ASTEROIDS.MODULES = [
  "./core/registry.js",
  "./game/ledger.js",
  "./entities/rock.js",
  "./events/ada-vex.js",
];
JS

  cat > src/core/registry.js <<'JS'
(function (A) {
  const features = [];
  A.register = function (f) { features.push(f); return f; };
})(ASTEROIDS);
JS

  cat > src/game/ledger.js <<'JS'
ASTEROIDS.LEDGER = {};
JS

  cat > src/entities/rock.js <<'JS'
(function (A) {
  A.register({ order: 40, guide: { name: "ROCK" }, draw: function () {} });
})(ASTEROIDS);
JS
  pad src/entities/rock.js 60 "rock, elaborated,"

  cat > src/events/ada-vex.js <<'JS'
(function (A) {
  A.EVENTS = (A.EVENTS || []).concat([{
    id: "closing-ring",
    by: "Ada Vex",
    fire: function () {},
  }]);
})(ASTEROIDS);
JS

  git add -A >/dev/null
  git commit -qm "The lab opens for business" >/dev/null

  # the ledger the generator writes, so no case starts from a fixture lie
  sh tools/tally.sh >/dev/null 2>&1 || :
  if ! git diff --quiet -- src/game/ledger.js 2>/dev/null; then
    git add -A >/dev/null
    git commit -qm "The lab counts nobody, in writing" >/dev/null
  fi

  # Bo arrives with one trap, and every case after this is Bo at the keyboard
  git config user.name "$PILOT"
  cat > src/events/bo-renn.js <<'JS'
(function (A) {
  A.EVENTS = (A.EVENTS || []).concat([{
    id: "three-krakens",
    by: "Bo Renn",
    fire: function () {},
  }]);
})(ASTEROIDS);
JS
  awk '/^\];$/ && !d { print "  \"./events/bo-renn.js\","; d = 1 } { print }' \
    src/features.js > src/features.new && mv src/features.new src/features.js
  git add -A >/dev/null
  git commit -qm "Bo Renn lays the first trap of the evening" >/dev/null
  cd "$ROOT" || exit 1
}

# --- helpers -------------------------------------------------------------------

fresh() { rm -rf "$LAB"; cp -R "$CABINET" "$LAB"; cd "$LAB" || exit 1; }

land() { git add -A >/dev/null 2>&1; git commit -q "$@" >/dev/null 2>&1; }

count() { sh tools/tally.sh --count "$1" 2>/dev/null; }

# one pilot's line in the generated ledger, whitespace trimmed - or nothing
rowof() {
  sh tools/tally.sh --print 2>/dev/null \
    | grep -F "\"$1\":" | sed 's/^ *//; s/,$//'
}

# what the audit charges with nothing written down: a commit under src/events
# that is not the author's own file, judged off the history alone
sneak_red_line() {
  printf '// a small improvement, surely\n' >> src/events/ada-vex.js
  land -m "a small tidy-up of the traps"
}

case_() { RULE=$1; NAME=$2; DONE=0; fresh; }

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

# one verdict per case: build the whole observation into one string and
# compare it against the whole expectation, so a case cannot half-pass
expect() {
  if [ "$1" = "$2" ]; then verdict yes
  else verdict no "got \"$1\", wanted \"$2\""; fi
}

# --- the price: tools/tally.sh against scripted histories ---------------------

build_cabinet
printf '\n  TALLY TESTS  %stools/tally.sh, .githooks, src/game%s\n\n' "$D" "$Z"

case_ GR12 "a clean history charges nobody"
  expect "count=$(count "$PILOT") row=$(rowof "$PILOT")" "count=0 row="

case_ GR12 "a bend costs one, and the ledger says which rule"
  printf '// retuned\n' >> src/events/bo-renn.js
  land -m "The trap comes a wave later" \
       -m "Golden-Rule-Override: GR4 - Ada agreed, in the lab's imagination"
  expect "count=$(count "$PILOT") row=$(rowof "$PILOT")" \
         "count=1 row=\"Bo Renn\": { bends: 1, clean: 0, last: \"GR4\" }"

case_ GR12 "a second bend costs a second one"
  printf '// retuned\n' >> src/events/bo-renn.js
  land -m "The trap comes a wave later" -m "Golden-Rule-Override: GR4 - once"
  printf '// retuned again\n' >> src/events/bo-renn.js
  land -m "The trap comes later still" -m "Golden-Rule-Override: GR6 - twice"
  expect "$(count "$PILOT")" "2"

case_ GR12 "a receipt prices going round the referee at two"
  land --allow-empty -m "THE LEDGER: Bo Renn went round the referee" \
       -m "Referee-Skipped: 0123abc landed with the golden check never run"
  expect "$(count "$PILOT")" "2"

case_ GR12 "the audit charges a hookless red line two, in silence broken later"
  # the referee never ran, nothing was written down, and the next pilot to
  # ask the tally still gets the true answer - off the history alone
  sneak_red_line
  SHA=$(git rev-parse HEAD)
  FLAGGED=$(sh tools/chronicle.sh --skips 2>/dev/null | grep -c "^$SHA")
  expect "flagged=$FLAGGED count=$(count "$PILOT")" "flagged=1 count=2"

case_ GR12 "a hookless budget bust pays the same two"
  awk 'NR <= 5' src/entities/rock.js > r && mv r src/entities/rock.js
  land -m "the rock loses its long tail, and nobody is told"
  expect "$(count "$PILOT")" "2"

case_ GR12 "rules and game in one quiet commit is a skip like any other"
  printf '\nA new paragraph of rules.\n' >> GOLDEN_RULES.md
  printf '// and a tweak while nobody is looking\n' >> src/boot.js
  land -m "tidying"
  expect "$(count "$PILOT")" "2"

case_ GR12 "a witnessed skip costs two rather than four"
  sneak_red_line
  SHORT=$(git rev-parse --short HEAD)
  BEFORE=$(count "$PILOT")
  land --allow-empty -m "THE LEDGER: Bo Renn went round the referee" \
       -m "Tally: Bo Renn - 2" \
       -m "Referee-Skipped: $SHORT landed with the golden check never run"
  expect "before=$BEFORE after=$(count "$PILOT")" "before=2 after=2"

case_ GR8 "a breach charges the pilot it names, not the scribe"
  land --allow-empty -m "The table has a word about the shield" \
       -m "Golden-Rule-Breach: GR8 Ada Vex - no cost, no cooldown, and the table agrees"
  expect "ada=$(count "$OWNER") bo=$(count "$PILOT")" "ada=1 bo=0"

case_ GR8 "a breach naming a phantom charges nobody"
  land --allow-empty -m "The table has a word about the shield" \
       -m "Golden-Rule-Breach: GR8 Nobody Here - a typo is not a verdict"
  expect "phantom=$(count "Nobody Here") anybody=$(sh tools/tally.sh --print 2>/dev/null | grep -c 'bends:')" \
         "phantom=0 anybody=0"

case_ GR12 "three clean versions ease one bend"
  printf '// retuned\n' >> src/events/bo-renn.js
  land -m "The trap comes a wave later" -m "Golden-Rule-Override: GR4 - spent"
  for w in 7 8 9; do
    printf '// wave %s, retuned\n' "$w" >> src/events/bo-renn.js
    land -m "The trap moves to wave $w"
  done
  CHARGE=$(sh tools/tally.sh --roll 2>/dev/null | grep -F "$PILOT" | sed 's/.*charges as \([0-9]*\).*/\1/')
  expect "row=$(rowof "$PILOT") charges=$CHARGE" \
         "row=\"Bo Renn\": { bends: 1, clean: 3, last: \"GR4\" } charges=0"

case_ GR12 "the next bend takes the whole discount back"
  printf '// retuned\n' >> src/events/bo-renn.js
  land -m "The trap comes a wave later" -m "Golden-Rule-Override: GR4 - spent"
  for w in 7 8 9; do
    printf '// wave %s, retuned\n' "$w" >> src/events/bo-renn.js
    land -m "The trap moves to wave $w"
  done
  printf '// meaner\n' >> src/events/bo-renn.js
  land -m "The trap grows teeth" -m "Golden-Rule-Override: GR6 - spent again"
  expect "$(rowof "$PILOT")" "\"Bo Renn\": { bends: 2, clean: 0, last: \"GR6\" }"

case_ GR12 "the ledger's own receipt is not a clean landing"
  printf '// retuned\n' >> src/events/bo-renn.js
  land -m "The trap comes a wave later" -m "Golden-Rule-Override: GR4 - spent"
  sh tools/tally.sh >/dev/null 2>&1
  git add src/game/ledger.js >/dev/null 2>&1
  git commit -qm "THE LEDGER: Bo Renn bends GR4, and it goes on the record" >/dev/null 2>&1
  AFTER_RECEIPT=$(rowof "$PILOT")
  printf '// a real landing\n' >> src/events/bo-renn.js
  land -m "The trap moves once more"
  expect "receipt=[$AFTER_RECEIPT] version=[$(rowof "$PILOT")]" \
         "receipt=[\"Bo Renn\": { bends: 1, clean: 0, last: \"GR4\" }] version=[\"Bo Renn\": { bends: 1, clean: 1, last: \"GR4\" }]"

case_ GR12 "a message still being written is already priced"
  printf 'The trap moves once more\n\nGolden-Rule-Override: GR14 - not landed yet\n' > "$WORK/msg"
  expect "$(sh tools/tally.sh --plus "$WORK/msg" --count "$PILOT" 2>/dev/null)" "1"

case_ GR12 "a doctored ledger does not survive --check"
  printf '// retuned\n' >> src/events/bo-renn.js
  land -m "The trap comes a wave later" -m "Golden-Rule-Override: GR4 - spent"
  sh tools/tally.sh >/dev/null 2>&1
  HONEST=$?
  sh tools/tally.sh --check >/dev/null 2>&1; HONEST=$?
  awk '{ sub(/bends: 1/, "bends: 0"); print }' src/game/ledger.js > l && mv l src/game/ledger.js
  sh tools/tally.sh --check >/dev/null 2>&1; DOCTORED=$?
  expect "honest=$HONEST doctored=$DOCTORED" "honest=0 doctored=1"

# --- the receipts: .githooks/post-commit, driven directly ----------------------
#
# The hook decides whether the referee saw the tree that landed by reading the
# note commit-msg leaves behind ($GIT_DIR/asteroids-referee). Each case sets
# that stage by hand: the note matching the tree is a commit the referee
# cleared, the note missing is a commit that went round it.

refereed() { git rev-parse 'HEAD^{tree}' > .git/asteroids-referee; }
unrefereed() { rm -f .git/asteroids-referee; }
receipts() { sh .githooks/post-commit > "$OUT" 2>&1; }

case_ GR12 "a clean landing gets no ledger commit"
  printf '// retuned\n' >> src/events/bo-renn.js
  land -m "The trap comes a wave later"
  WAS=$(git rev-parse HEAD)
  refereed; receipts
  expect "moved=$(git rev-parse HEAD | grep -c "$WAS") count=$(count "$PILOT")" \
         "moved=1 count=0"

case_ GR12 "a refereed bend is written down while the pilot is still reading"
  printf '// retuned\n' >> src/events/bo-renn.js
  land -m "The trap comes a wave later" -m "Golden-Rule-Override: GR4 - spent"
  refereed; receipts
  expect "subject=[$(git log -1 --format=%s)] author=[$(git log -1 --format=%an)] count=$(count "$PILOT") ledger=$(grep -c '"Bo Renn": { bends: 1' src/game/ledger.js)" \
         "subject=[THE LEDGER: Bo Renn bends GR4, and it goes on the record] author=[Bo Renn] count=1 ledger=1"

case_ GR12 "a commit the referee never saw gets its two, in writing"
  printf '// retuned\n' >> src/events/bo-renn.js
  land -m "The trap comes a wave later"
  unrefereed; receipts
  expect "subject=[$(git log -1 --format=%s)] receipt=$(git log -1 --format=%B | grep -c '^Referee-Skipped:') count=$(count "$PILOT")" \
         "subject=[THE LEDGER: Bo Renn went round the referee] receipt=1 count=2"

case_ GR12 "the ledger commit does not tally itself"
  printf '// retuned\n' >> src/events/bo-renn.js
  land -m "The trap comes a wave later" -m "Golden-Rule-Override: GR4 - spent"
  WAS=$(git rev-parse HEAD)
  unrefereed
  ASTEROIDS_TALLY=1 sh .githooks/post-commit > "$OUT" 2>&1
  expect "$(git rev-parse HEAD | grep -c "$WAS")" "1"

case_ GR12 "a merge is nobody's bend"
  git checkout -qb side 2>/dev/null
  printf '// side work\n' >> src/events/bo-renn.js
  land -m "The trap, on a branch"
  git checkout -q - 2>/dev/null
  printf '\nA paragraph.\n' >> README.md
  land -m "The README says a little more"
  git merge -q --no-ff side -m "the evening merges" >/dev/null 2>&1
  WAS=$(git rev-parse HEAD)
  unrefereed; receipts
  expect "moved=$(git rev-parse HEAD | grep -c "$WAS") count=$(count "$PILOT")" \
         "moved=1 count=0"

# --- the scoreboard: .githooks/pre-push ----------------------------------------
#
# GR7's last line of defence, fed the same stdin git would feed it. The shas
# are real commits from the lab so merge-base can actually answer.

ZERO=0000000000000000000000000000000000000000

push() { printf '%s %s %s %s\n' "$1" "$2" "$3" "$4" | sh .githooks/pre-push > "$OUT" 2>&1; }

case_ GR7 "history may move forward on main"
  OLD=$(git rev-parse HEAD~1); NEW=$(git rev-parse HEAD)
  push refs/heads/main "$NEW" refs/heads/main "$OLD"
  expect "$?" "0"

case_ GR7 "rewriting main is refused, whoever asks"
  OLD=$(git rev-parse HEAD~1); NEW=$(git rev-parse HEAD)
  push refs/heads/main "$OLD" refs/heads/main "$NEW"
  expect "exit=$? said=$(grep -c GR7 "$OUT")" "exit=1 said=1"

case_ GR7 "deleting main is refused"
  OLD=$(git rev-parse HEAD)
  push '(delete)' "$ZERO" refs/heads/main "$OLD"
  expect "$?" "1"

case_ GR7 "your own branch is your own business"
  OLD=$(git rev-parse HEAD~1); NEW=$(git rev-parse HEAD)
  push refs/heads/lab "$OLD" refs/heads/lab "$NEW"
  expect "$?" "0"

# --- the field: what the number does, in the code that ships -------------------
#
# Everything above prices the paper. This loads the real src/game/tally.js and
# src/game/events.js - from this working tree, not from the lab - hands them a
# ledger, and reads the GR12 table back out of them: events sooner from one
# bend, your own traps armed at three, a crowded wave at four, a floor of
# half, mercy every three clean landings. The thresholds are quoted from
# GOLDEN_RULES.md on purpose: retuning them is a rule change, and this is
# where a quiet one gets loud.

cd "$ROOT" || exit 1

if command -v node >/dev/null 2>&1; then
  cat > "$WORK/field.js" <<'NODE'
  const fs = require("fs");
  const path = require("path");
  const ROOT = process.argv[2];
  const out = [];
  const t = (rule, name, cond, detail) =>
    out.push((cond ? "ok" : "no") + "\t" + rule + "\t" + name + "\t" + (cond ? "" : detail));

  // a fresh cabinet per question: stub seat, real punishment code
  function cabinet(ledger, pilot, traps) {
    const A = { register() {}, activePilot: () => pilot, GUEST: "GUEST", LEDGER: ledger };
    global.ASTEROIDS = A;
    for (const f of ["src/game/tally.js", "src/game/events.js"]) {
      new Function(fs.readFileSync(path.join(ROOT, f), "utf8"))();
    }
    for (const e of traps || []) A.defineEvent(e);
    return A;
  }
  const bo = (bends, clean) => ({ "Bo Renn": { bends, clean, last: "GR4" } });
  const armoury = () => [
    { id: "three-krakens", by: "Bo Renn", fire() {} },
    { id: "closing-ring", by: "Ada Vex", fire() {} },
  ];

  try {
    let A = cabinet(bo(0, 0), "Bo Renn", armoury());
    t("GR12", "an honest pilot's field behaves",
      A.eventHeat() === 1 && A.eventQuotaBonus() === 0 && !A.ownEventsArmed(),
      "heat=" + A.eventHeat() + " bonus=" + A.eventQuotaBonus() + " own=" + A.ownEventsArmed());
    t("GR11", "an event never fires for the pilot who wrote it",
      A.armedCount() === 1, "armedCount=" + A.armedCount() + ", wanted Ada's trap only");

    A = cabinet(bo(1, 0), "Bo Renn", armoury());
    const h1 = A.eventHeat();
    t("GR12", "one bend and events come sooner",
      h1 < 1 && h1 >= 0.5 && !A.ownEventsArmed(), "heat=" + h1 + " own=" + A.ownEventsArmed());

    A = cabinet(bo(2, 0), "Bo Renn", armoury());
    t("GR12", "two bends press harder and still spare your own traps",
      A.eventHeat() < h1 && !A.ownEventsArmed(),
      "heat=" + A.eventHeat() + " (one bend gave " + h1 + ") own=" + A.ownEventsArmed());

    A = cabinet(bo(3, 0), "Bo Renn", armoury());
    t("GR11", "three bends and your own events stop sparing you",
      A.ownEventsArmed() && A.armedCount() === 2 && A.eventQuotaBonus() === 0,
      "own=" + A.ownEventsArmed() + " armedCount=" + A.armedCount() + " bonus=" + A.eventQuotaBonus());

    A = cabinet(bo(4, 0), "Bo Renn", armoury());
    t("GR12", "four bends and a wave may hold one more ambush",
      A.eventQuotaBonus() === 1, "bonus=" + A.eventQuotaBonus());

    A = cabinet(bo(50, 0), "Bo Renn", armoury());
    t("GR12", "the punishment is capped, however long the record",
      A.eventHeat() === 0.5 && A.eventQuotaBonus() === 1,
      "heat=" + A.eventHeat() + " bonus=" + A.eventQuotaBonus() + ", the floor is half and one");

    A = cabinet(bo(1, 3), "Bo Renn", armoury());
    t("GR12", "three clean versions ease the field back to nothing",
      A.eventHeat() === 1 && !A.ownEventsArmed(),
      "heat=" + A.eventHeat() + " own=" + A.ownEventsArmed());

    A = cabinet(bo(4, 3), "Bo Renn", armoury());
    t("GR12", "the field reads the eased number, the wall keeps the record",
      A.pilotBends("Bo Renn") === 4 && A.pilotHeatBends("Bo Renn") === 3 &&
        A.ownEventsArmed() && A.eventQuotaBonus() === 0,
      "bends=" + A.pilotBends("Bo Renn") + " charged=" + A.pilotHeatBends("Bo Renn") +
        " own=" + A.ownEventsArmed() + " bonus=" + A.eventQuotaBonus());

    A = cabinet(bo(3, 3), "Bo Renn", armoury());
    t("GR11", "mercy hands your own traps back to sparing you",
      !A.ownEventsArmed(), "3 bends 3 clean charges as 2, own=" + A.ownEventsArmed());

    A = cabinet({}, "GUEST", armoury());
    t("GR11", "GUEST is spared nothing",
      A.armedCount() === 2, "armedCount=" + A.armedCount());

    A = cabinet({}, "Cy Null", armoury());
    t("GR11", "the field does not ambush the unarmed",
      A.armedCount() === 0, "armedCount=" + A.armedCount());

    A = cabinet({ "Cy Null": { bends: 1, clean: 0, last: "GR6" } }, "Cy Null", armoury());
    t("GR11", "the shelter is for the new, not the indebted",
      A.armedCount() === 2, "armedCount=" + A.armedCount());

    A = cabinet({}, "Ada Vex",
      [{ id: "closing-ring", by: "Ada Vex", fire() {} },
       { id: "meteor-rain", by: "THE HOUSE", fire() {} }]);
    t("GR11", "the house ambushes everybody, author included",
      A.armedCount() === 1, "armedCount=" + A.armedCount() + ", wanted the house trap only");

    A = cabinet(bo(-5, 0), "Bo Renn", armoury());
    t("GR12", "a garbage ledger row charges nothing rather than less than nothing",
      A.eventHeat() === 1 && !A.ownEventsArmed() && A.pilotHeatBends("Bo Renn") === 0,
      "heat=" + A.eventHeat() + " charged=" + A.pilotHeatBends("Bo Renn"));
  } catch (err) {
    out.push("no\tGR12\tthe field code loads at all\t" + err.message);
  }
  process.stdout.write(out.join("\n") + "\n");
NODE
  node "$WORK/field.js" "$ROOT" > "$WORK/field.out" 2>&1 || {
    printf 'no\tGR12\tthe field harness ran\t%s\n' "$(head -1 "$WORK/field.out")" > "$WORK/field.out"
  }
  TAB=$(printf '\t')
  while IFS="$TAB" read -r ST RULE NAME DETAIL; do
    DONE=0; : > "$OUT"
    if [ "$ST" = ok ]; then verdict yes; else verdict no "$DETAIL"; fi
  done < "$WORK/field.out"
else
  RULE=GR12; NAME="the field's own arithmetic"; DONE=0
  skip "no node here, and the field runs on one"
fi

# --- the count ---------------------------------------------------------------

cd "$ROOT" || exit 1
printf '\n  %s ok' "$OK"
[ "$SKIP" != 0 ] && printf ', %s skipped' "$SKIP"
[ "$BAD" != 0 ] && printf ', %s%s failed%s' "$R" "$BAD" "$Z"
printf '\n\n'

[ "$BAD" = 0 ] || exit 1
exit 0
