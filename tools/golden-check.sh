#!/bin/sh
# ---------------------------------------------------------------------------
# golden-check.sh - the referee for HYPERCOLOR ASTEROIDS.
#
# Checks the current change against GOLDEN_RULES.md. In the spirit of the game
# itself there are no dependencies: sh, git, grep, sed, awk, and node if you
# happen to have one.
#
#   tools/golden-check.sh              what does the referee say about my work?
#   tools/golden-check.sh --staged     ... about what is staged
#   tools/golden-check.sh --rev SHA    ... about a commit that already exists
#   tools/golden-check.sh --range A..B ... about every commit in a range
#   tools/golden-check.sh --install    install the hooks in this clone
#   tools/golden-check.sh --json       machine readable, for the editor hook
#
# Exit 0 = clear (warnings never block). Exit 1 = blocked.
#
# Seven rules are red lines and cannot be overridden. Four are budgets: you may
# spend past them, but only by saying so in the commit message, where everybody
# can read it later. Three are nudges. One is on your honour.
#
# The first two modes referee a pilot who is present: their tree, their index,
# their git config. --rev referees one who is not - a commit that already
# exists, judged as its own author, against its own message, with the files as
# that commit left them. Nothing else changes, and that is the point: a clone
# that never installed the hooks gets the same reading as one that did, only
# later, and in front of everybody. GR12 said so first.
# ---------------------------------------------------------------------------
set -u

MODE=worktree          # worktree | staged | rev | install
STAGE=all              # all | pre-commit | commit-msg
MSGFILE=""
FORMAT=text            # text | json
REV=""                 # the commit under review, in rev mode
RANGE=""
BLOCK=0
WARNED=0
HARD=0

while [ $# -gt 0 ]; do
  case "$1" in
    --staged)        MODE=staged ;;
    --stage)         STAGE="${2:-all}"; shift ;;
    --message-file)  MSGFILE="${2:-}"; MODE=staged; shift ;;
    --rev)           MODE=rev; REV="${2:-}"; shift ;;
    --range)         RANGE="${2:-}"; shift ;;
    --json)          FORMAT=json ;;
    --install)       MODE=install ;;
    -h|--help)       sed -n '2,27p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)               printf 'golden-check: unknown option %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$ROOT" || exit 0

if [ "$MODE" = install ]; then
  git config core.hooksPath .githooks
  chmod +x .githooks/* tools/*.sh 2>/dev/null
  # carry the mode bit into git as well, so nobody else has to do this at all
  for f in .githooks/* tools/*.sh; do
    git ls-files --error-unmatch "$f" >/dev/null 2>&1 && \
      git update-index --chmod=+x "$f" 2>/dev/null
  done
  printf 'referee installed: core.hooksPath = .githooks\n'
  exit 0
fi

# A range is not a bigger commit, it is several commits, and half the rulebook
# only means anything one commit at a time: GR6 counts one surprise, GR10 keeps
# the rules out of the same breath as the game, GR4 and GR11 ask who wrote the
# file and the answer changes per author. Squash the range into one diff and
# all four stop being checkable. So the range is a loop, and each pass is an
# ordinary --rev with its own verdict.
#
# Merges are skipped for the reason the post-commit hook skips them: a merge is
# nobody's work, and refereeing somebody for the shape of a branch point would
# be a rule about git rather than about the game.
if [ -n "$RANGE" ]; then
  revs=$(git rev-list --reverse --no-merges "$RANGE" 2>/dev/null) || {
    printf 'golden-check: %s is not a range git knows\n' "$RANGE" >&2; exit 2; }
  if [ -z "$revs" ]; then
    [ "$FORMAT" = text ] && printf 'no commits in %s. nothing to check.\n' "$RANGE"
    exit 0
  fi
  status=0
  for r in $revs; do
    if [ "$FORMAT" = text ]; then
      printf '\n%s  %s\n            %s\n' \
        "$(git log -1 --format='%h' "$r")" \
        "$(git log -1 --format='%s' "$r")" \
        "$(git log -1 --format='%an' "$r")"
      sh "$0" --rev "$r" || status=1
    else
      sh "$0" --rev "$r" --json || status=1
    fi
  done
  exit $status
fi

TMP=$(mktemp -d 2>/dev/null) || exit 0
trap 'rm -rf "$TMP"' EXIT INT TERM
: > "$TMP/out"

if [ "$FORMAT" = text ] && [ -t 1 ]; then
  R=$(printf '\033[31m'); Y=$(printf '\033[33m'); D=$(printf '\033[2m'); Z=$(printf '\033[0m')
else
  R=''; Y=''; D=''; Z=''
fi

fail() { printf ' %s!%s %-4s %s\n' "$R" "$Z" "$1" "$2" >> "$TMP/out"; BLOCK=1; }
# Same, for a red line that happens to be checked at message time. It blocks the
# same way; it must not be answered with "spend a budget", because it cannot be.
hard() { fail "$@"; HARD=1; }
warn() { printf ' %s?%s %-4s %s\n' "$Y" "$Z" "$1" "$2" >> "$TMP/out"; WARNED=1; }
note() { printf '   %s%s%s\n' "$D" "$1" "$Z" >> "$TMP/out"; }

# A working tree fills up with things that were never going to be committed: a
# screenshot somebody pasted, a render, an export. The referee cannot read a
# byte of any of it, and asking wc -l how many lines a PNG has is how a
# docs-and-tools afternoon got told it was ten thousand lines of game (GR6) and
# that the rules and the game were moving together (GR10). A referee that cries
# wolf gets skimmed past, and then the true ones go unread with it.
#
# Only ever applied to what nobody has offered yet. Staged is different: git add
# is the pilot saying this belongs, and then it counts, whatever it is.
is_litter() {
  case "$1" in
    *.png|*.jpg|*.jpeg|*.gif|*.webp|*.avif|*.ico) return 0 ;;
    *.mp4|*.mov|*.webm|*.wav|*.mp3|*.ogg) return 0 ;;
    *.zip|*.gz|*.tar|*.pdf|*.ttf|*.woff|*.woff2) return 0 ;;
  esac
  return 1
}

# --- the change under review ------------------------------------------------

EMPTYTREE=$(git hash-object -t tree /dev/null)

if git rev-parse --verify -q HEAD >/dev/null 2>&1; then
  BASE=HEAD
else
  BASE=$EMPTYTREE
fi

# Where to ask who owns a file. From HEAD when the pilot is here, and from the
# commit under review when they are not - so a later commit on the same branch
# cannot retroactively decide who owned what while an earlier one was landing.
LOGREF=HEAD

ME=$(git config user.name 2>/dev/null || true)

if [ "$MODE" = rev ]; then
  REV=$(git rev-parse --verify -q "$REV^{commit}") || {
    printf 'golden-check: no such commit\n' >&2; exit 2; }
  LOGREF=$REV
  # Judged as its own author, not as whoever is running this. Everything GR4,
  # GR11 and GR14 say about ownership hangs off this one line.
  ME=$(git log -1 --format='%an' "$REV")
  # ... and against its own message, which is where the budgets are spent.
  MSGFILE="$TMP/msg"
  git log -1 --format='%B' "$REV" > "$MSGFILE"
  BASE=$(git rev-parse --verify -q "$REV^" 2>/dev/null) || BASE=$EMPTYTREE
fi

# A rename reaches the lists above as an add and nothing else - git is being
# tactful about where the file came from. Everywhere else that tact is welcome.
# For GR11 it is the one move the red line cannot survive, so the pairs are
# kept: old path, tab, new path.
renames() { awk -F'\t' '$1 ~ /^R/ { print $2 "\t" $3 }'; }

# The same tact in the other list, and here it costs a budget rather than a red
# line. numstat folds a renamed file's two paths into one field -
# "src/entities/{planet.js => planetoid.js}" - so asking it how many lines that
# file lost answers 0 however much the diff took out. The counts are already the
# right ones; only the label is folded. Unfold it onto the path the file now has,
# which is the path every check downstream is holding.
unfold() {
  awk -F'\t' -v OFS='\t' '
    {
      p = $3
      if (match(p, /\{[^{}]* => [^{}]*\}/)) {          # src/{a.js => b.js}
        head = substr(p, 1, RSTART - 1)
        mid  = substr(p, RSTART + 1, RLENGTH - 2)
        tail = substr(p, RSTART + RLENGTH)
        sub(/^.* => /, "", mid)
        p = head mid tail
      } else if (index(p, " => ")) {                   # a.js => b.js
        sub(/^.* => /, "", p)
      }
      print $1, $2, p
    }'
}

# --find-renames is the default, and it is written down anyway: the pairs and
# the counts have to be reading the same diff now that one is asked about the
# other.
if [ "$MODE" = rev ]; then
  git diff --name-only --diff-filter=ACMR "$BASE" "$REV" > "$TMP/files"
  git diff --name-only --diff-filter=D    "$BASE" "$REV" > "$TMP/gone"
  git diff --numstat --find-renames "$BASE" "$REV" | unfold > "$TMP/stat"
  git diff --name-status --find-renames "$BASE" "$REV" | renames > "$TMP/moved"
elif [ "$MODE" = staged ]; then
  git diff --cached --name-only --diff-filter=ACMR "$BASE" > "$TMP/files"
  git diff --cached --name-only --diff-filter=D    "$BASE" > "$TMP/gone"
  git diff --cached --numstat --find-renames "$BASE" | unfold > "$TMP/stat"
  git diff --cached --name-status --find-renames "$BASE" | renames > "$TMP/moved"
else
  git diff --name-only --diff-filter=ACMR "$BASE" > "$TMP/files"
  git diff --name-only --diff-filter=D    "$BASE" > "$TMP/gone"
  git diff --numstat --find-renames "$BASE" | unfold > "$TMP/stat"
  git diff --name-status --find-renames "$BASE" | renames > "$TMP/moved"
  git ls-files --others --exclude-standard        > "$TMP/new"
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    is_litter "$f" && continue
    printf '%s\t0\t%s\n' "$(wc -l < "$f" | tr -d ' ')" "$f" >> "$TMP/stat"
    printf '%s\n' "$f" >> "$TMP/files"
  done < "$TMP/new"
fi

# Nothing changed is usually nothing to check - unless a message is on the
# table. An --allow-empty commit still carries its message, a message can
# carry a breach line, and a breach naming a phantom must not land however
# little else the commit does (GR8, GR12).
if [ ! -s "$TMP/files" ] && [ ! -s "$TMP/gone" ] && [ -z "$MSGFILE" ]; then
  [ "$FORMAT" = text ] && printf 'nothing to check.\n'
  exit 0
fi

# content of a path as it will be committed - or, in rev mode, as it was
content() {
  case "$MODE" in
    staged) git show ":$1" 2>/dev/null ;;
    rev)    git show "$REV:$1" 2>/dev/null ;;
    *)      cat "$1" 2>/dev/null ;;
  esac
}

# will this path exist for the next person who clones?
path_exists() {
  case "$MODE" in
    staged) git cat-file -e ":$1" 2>/dev/null ;;
    rev)    git cat-file -e "$REV:$1" 2>/dev/null ;;
    *)      [ -f "$1" ] ;;
  esac
}

# the author of the commit that first added a file. empty means it is new,
# which means it is yours.
#
# Asked without --follow, and that is the whole point rather than an oversight.
# --follow turns on git's find-copies-harder, which will happily report a new
# file as having been added by whoever wrote the file it happens to resemble -
# no rename involved, the original still sitting there untouched. A pilot
# writing their first event from somebody else's as a template is exactly that
# shape, so the referee used to tell them, the second time they opened their
# own trap, that it belonged to the pilot they had copied. GR11 has no
# override, so there was no way out of it either.
owner_of() {
  o=$(git log "$LOGREF" --diff-filter=A --format='%an' -- "$1" 2>/dev/null | tail -1)
  [ -n "$o" ] || o="$ME"
  printf '%s' "$o"
}

# where a path came from, when it came from somewhere. empty means it is new,
# and new is the answer owner_of already knows what to do with.
#
# A rename is how a file gets a history it did not have: the new path has none,
# a path with none is yours, and everything that asks who owns a file gets the
# flattering answer. GR11 shut that door on event files by judging the pair
# rather than the path. GR4 and GR5 had the same door, and a budget you can
# step around by typing git mv is not one.
came_from() {
  awk -F'\t' -v n="$1" '$2 == n { print $1; exit }' "$TMP/moved"
}

# shared ground: everybody's, nobody's. the machinery every feature imports.
#
# src/game/events.js and src/game/profile.js are here because GR11 stands on
# them: one decides whether an event fires for its own author, the other decides
# who the author is. src/game/tally.js is here because GR12 does - it is what
# the ledger costs a pilot in the field, and it would be a strange punishment
# that the punished could quietly turn off. None of the three is a feature
# anybody owns. The song is not here on purpose - src/audio/voices.js and the
# rest are somebody's work, and GR4's tighter budget on them is the point, not
# an oversight.
is_commons() {
  case "$1" in
    index.html|src/main.js|src/features.js) return 0 ;;
    src/core/*|src/render/*|src/input/*|src/ui/*) return 0 ;;
    src/game/players.js|src/game/difficulty.js|src/game/lifecycle.js) return 0 ;;
    src/game/events.js|src/game/profile.js|src/game/tally.js) return 0 ;;
    src/audio/context.js|src/audio/buses.js) return 0 ;;
    styles/tokens.css|README.md) return 0 ;;
  esac
  return 1
}

# The two files GR11 is made of, and the shape the guard has to keep. Named
# here rather than inline so the rule and the check read the same.
RUNNER=src/game/events.js
SEAT=src/game/profile.js
GUARD='\.by[[:space:]]*!==[[:space:]]*A\.HOUSE[[:space:]]*&&[^&|]*\.by[[:space:]]*==='

# GR13's ground: the room the book is read in, and the script that writes it.
# The song is generated like the rest of the book, so the file anybody would
# actually edit is the heredoc, not the copy.
SONG=docs/chronicle-song.js
BOOK=tools/chronicle.sh

# That heredoc and nothing else in that script. Read from stdin so the same
# reader works on a blob out of the history and on the working copy.
song_of() {
  awk -v f="$SONG" '
    index($0, "cat > " f " <<") == 1 { on = 1; next }
    on && $0 == "JS" { on = 0; next }
    on { print }'
}

# where a feature is allowed to call register()
is_feature_home() {
  case "$1" in
    src/entities/*.js|src/game/*.js|src/ui/*.js|src/render/*.js) return 0 ;;
  esac
  return 1
}

# the referee itself, and the rules it enforces
is_referee() {
  case "$1" in
    CLAUDE.md|GOLDEN_RULES.md|tools/*|.githooks/*|.claude/settings.json|.claude/skills/*) return 0 ;;
    .gitattributes|.env.example) return 0 ;;   # tool config travels with the tools
    # The second reading, for work that arrives from a clone the hooks never
    # reached. Same argument as .githooks/: a referee you can edit in the same
    # commit as the thing it referees is not one.
    .github/*) return 0 ;;
  esac
  return 1
}

# The notes - docs/ pages rendered from the markdown by tools/docs.sh. Which
# notes exist is derived from the README rather than written down anywhere, so
# the tool is asked once, here, rather than copied into a case arm below that
# would go stale the first time somebody adds one.
sh tools/docs.sh --list > "$TMP/notes" 2>/dev/null || : > "$TMP/notes"

# written by a machine from the history - nobody owns it, nobody is judged for it
is_generated() {
  case "$1" in
    docs/index.html|docs/chronicle.css|docs/taglines.tsv) return 0 ;;
    docs/chronicle.js) return 0 ;;      # the same book, in the shape the splash reads
    docs/chronicle-song.js) return 0 ;; # the room the book is read in, same machine
    docs/rail.js) return 0 ;;           # the dock every chapter shares, same machine
    docs/favicon.svg) return 0 ;;       # the signet on the tab, read off the logo
    docs/v[0-9]*.html) return 0 ;;      # one page per version, same machine
    docs/art/*) return 0 ;;             # the plates, painted once and kept
    docs/faces/*) return 0 ;;           # the pilots, painted once and never again
    src/game/ledger.js) return 0 ;;
  esac
  grep -qxF "$1" "$TMP/notes" 2>/dev/null && return 0
  return 1
}

added_of()   { awk -F'\t' -v f="$1" '$3==f && $1!="-" {a+=$1} END{print a+0}' "$TMP/stat"; }
removed_of() { awk -F'\t' -v f="$1" '$3==f && $2!="-" {d+=$2} END{print d+0}' "$TMP/stat"; }

# a budget is spent by naming the rule in the commit message
overridden() {
  [ -n "$MSGFILE" ] && [ -f "$MSGFILE" ] || return 1
  grep -Eiq "^[[:space:]]*golden-rule-override:.*\b$1\b.{8,}" "$MSGFILE"
}

Q="[\"']"

# ---------------------------------------------------------------------------
# GR1  Leave it playable.
# ---------------------------------------------------------------------------
check_gr1() {
  while IFS= read -r f; do
    case "$f" in *.js) ;; *) continue ;; esac
    if command -v node >/dev/null 2>&1; then
      content "$f" > "$TMP/syn.mjs"
      if ! node --check "$TMP/syn.mjs" 2>"$TMP/syn.err"; then
        fail GR1 "$f does not parse"
        note "$(sed -n '3,4p' "$TMP/syn.err" | tr '\n' ' ')"
        continue
      fi
    fi
    dir=$(dirname "$f")
    content "$f" \
      | grep -Eo "(from|import)[[:space:]]*${Q}[^\"']+${Q}" \
      | sed -E "s/^(from|import)[[:space:]]*${Q}//; s/${Q}\$//" \
      | grep -E '^\.' > "$TMP/imports" 2>/dev/null || true
    while IFS= read -r spec; do
      [ -n "$spec" ] || continue
      target=$(printf '%s/%s' "$dir" "$spec" | awk -F/ '{n=0
        for(i=1;i<=NF;i++){ if($i=="."||$i=="")continue
          if($i==".."){ if(n>0)n--; continue } p[++n]=$i }
        s=""; for(i=1;i<=n;i++) s=s (i>1?"/":"") p[i]; print s}')
      path_exists "$target" || fail GR1 "$f imports $spec, which is not there"
    done < "$TMP/imports"
  done < "$TMP/files"

  # The manifest is the load order now, so a path that is not there is a game
  # that does not boot - the same mistake a bad import used to be.
  if path_exists src/features.js; then
    content src/features.js \
      | grep -Eo '"\./[^"]+\.js"' | sed -e 's/^"\.\///' -e 's/"$//' > "$TMP/mods"
    while IFS= read -r m; do
      [ -n "$m" ] || continue
      path_exists "src/$m" || fail GR1 "src/features.js lists $m, which is not there"
    done < "$TMP/mods"
  fi

  # the front door has to open, whether or not this commit touched it
  if path_exists index.html; then
    content index.html \
      | grep -Eo '(src|href)="[^"]+"' | sed -E 's/^(src|href)="//; s/"$//' \
      > "$TMP/refs"
    while IFS= read -r ref; do
      case "$ref" in ''|'#'*|data:*|http:*|https:*|//*|mailto:*) continue ;; esac
      path_exists "${ref#./}" || fail GR1 "index.html loads $ref, which is not there"
    done < "$TMP/refs"
  fi
}

# ---------------------------------------------------------------------------
# GR2  No dependencies, no build step, no network.
# ---------------------------------------------------------------------------
check_gr2() {
  while IFS= read -r f; do
    case "$f" in
      package.json|package-lock.json|yarn.lock|pnpm-lock.yaml|bun.lockb|node_modules/*)
        fail GR2 "$f - the cabinet has no package manager" ; continue ;;
      vite.config.*|webpack.config.*|rollup.config.*|esbuild.*|tsconfig.json|*.ts|*.tsx|*.jsx)
        fail GR2 "$f - the cabinet has no build step" ; continue ;;
    esac
    case "$f" in *.js|*.css|*.html) ;; *) continue ;; esac
    # A page that quotes this rule is not a page that breaks it. The rendered
    # golden rules say "XMLHttpRequest" and "sendBeacon" precisely because GR2
    # forbids them, and a machine put the words there. Nothing that ships in
    # the cabinet is generated, so everything that ships is still read.
    is_generated "$f" && continue
    if content "$f" | grep -Eq '\bfetch[[:space:]]*\(|XMLHttpRequest|new[[:space:]]+WebSocket|sendBeacon|new[[:space:]]+EventSource'; then
      fail GR2 "$f reaches for the network - the game plays on a plane"
    fi
    if content "$f" | grep -Eq "(src|href)=${Q}https?:|@import[[:space:]]+url\([\"']?https?:"; then
      fail GR2 "$f loads something remote - everything ships in the repo"
    fi
  done < "$TMP/files"
}

# ---------------------------------------------------------------------------
# GR7  Sign your work in git, not in the code.
# ---------------------------------------------------------------------------
check_gr7() {
  case "$ME" in
    ''|'Your Name'|unknown)
      fail GR7 "git config user.name is not set - the history has to know who you are" ;;
  esac
  while IFS= read -r f; do
    case "$f" in *.js|*.css|*.html) ;; *) continue ;; esac
    # As GR2 above: the rendered rules carry GR7's own "@author" because GR7 is
    # the rule that bans it. A generated page is not somebody signing their
    # work, and nothing a person wrote is exempt from this.
    is_generated "$f" && continue
    if content "$f" | grep -Eiq '@author|^[[:space:]]*(//|\*)[[:space:]]*(author|written by)[[:space:]]*:'; then
      fail GR7 "$f signs itself in a comment - git blame already knows"
    fi
  done < "$TMP/files"
}

# ---------------------------------------------------------------------------
# GR10  Changing the rules is its own commit.
# ---------------------------------------------------------------------------
check_gr10() {
  ref=0; game=0; reffiles=''; gamefiles=''
  # The book and the taglines are written by a machine from the history, and
  # they land with whatever commit comes next - including a rule change. They
  # are nobody's work, so they are neither side of this argument.
  while IFS= read -r f; do
    is_generated "$f" && continue
    if is_referee "$f"; then ref=1; reffiles="$reffiles $f"
    else game=1; gamefiles="$gamefiles $f"; fi
  done < "$TMP/files"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    is_generated "$f" && continue
    if is_referee "$f"; then ref=1; reffiles="$reffiles $f"
    else game=1; gamefiles="$gamefiles $f"; fi
  done < "$TMP/gone"
  [ "$ref" = 1 ] || return 0
  if [ "$game" = 1 ]; then
    # Both sides, because half the argument is unreadable on its own: a pilot
    # who can see the rules half still has to guess which of their files the
    # referee thinks is the game.
    hard GR10 "the rules and the game are moving together"
    note "the rules:$reffiles"
    note "the game:$gamefiles"
    note "split it: rule changes land alone, where everyone can see them"
  fi
  if [ -n "$MSGFILE" ] && [ -f "$MSGFILE" ]; then
    grep -Eiq '^[[:space:]]*rule-change:.{10,}' "$MSGFILE" || {
      hard GR10 "a rule change needs a 'Rule-Change: <why>' line in the message"
    }
  fi
}

# ---------------------------------------------------------------------------
# GR11  An event belongs to the pilot who wrote it.
#
# Ownership per file, because that is the one boundary git can prove. Your
# events are yours to rewrite forever; another pilot's are not yours to touch
# at all - not one line, not with an override. The whole mechanic rests on
# nobody being able to disarm the trap that is waiting for them.
# ---------------------------------------------------------------------------
check_gr11() {
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    case "$f" in
      "$RUNNER"|"$SEAT")
        fail GR11 "$f is what arms everybody's events - it does not get deleted"
        continue ;;
      src/events/*.js) ;;
      *) continue ;;
    esac
    o=$(owner_of "$f")
    [ "$o" = "$ME" ] || fail GR11 "$f is $o's - you cannot delete another pilot's events"
  done < "$TMP/gone"

  # Deleting somebody's trap is refused above, so the way round it was to move
  # it: rename another pilot's event file, sign the copy your own name, and it
  # fires at them and never at you - which is the exact thing this rule exists
  # to make impossible. git reports that as an ordinary new file, so the pair
  # has to be asked for by name and judged on where it came from.
  while IFS="$(printf '\t')" read -r was now; do
    [ -n "${was:-}" ] || continue
    case "$was" in
      "$RUNNER"|"$SEAT")
        fail GR11 "$was is what arms everybody's events - moving it is deleting it"
        continue ;;
      src/events/*.js) ;;
      *) continue ;;
    esac
    o=$(owner_of "$was")
    [ "$o" = "$ME" ] || \
      fail GR11 "$now is $o's $was under a new name - a trap is not yours to move"
  done < "$TMP/moved"

  # The one line that makes the whole mechanic true. Rewrite the runner all you
  # like; if this guard stops being recognisable, every pilot's own traps are
  # suddenly armed against them and only the author would know.
  if grep -qx "$RUNNER" "$TMP/files" 2>/dev/null; then
    content "$RUNNER" | grep -Eq "$GUARD" || {
      fail GR11 "$RUNNER no longer skips an event for the pilot who wrote it"
      note "keep the guard readable: e.by !== A.HOUSE && e.by === <the pilot>"
    }
  fi

  while IFS= read -r f; do
    case "$f" in src/events/*.js) ;; *) continue ;; esac
    o=$(owner_of "$f")
    if [ "$o" != "$ME" ]; then
      fail GR11 "$f is $o's event file - write your own, do not touch theirs"
      note "your events go in src/events/ under your own name, one file, yours forever"
      continue
    fi
    # Signed with a name that is not yours is the same trick by another route:
    # it would arm the event against its supposed author and spare you.
    content "$f" | grep -Eo 'by:[[:space:]]*("[^"]*"|A\.HOUSE|HOUSE)' \
      | sed -e 's/^by:[[:space:]]*//' -e 's/^"//' -e 's/"$//' > "$TMP/signed"
    while IFS= read -r by; do
      [ -n "$by" ] || continue
      case "$by" in
        "$ME"|A.HOUSE|HOUSE|"THE HOUSE") ;;
        *) fail GR11 "$f signs an event \"$by\", which is not you and not the house" ;;
      esac
    done < "$TMP/signed"
  done < "$TMP/files"
}

# ---------------------------------------------------------------------------
# GR4  Add, don't undo.   GR5  The commons stays common.
# ---------------------------------------------------------------------------
check_gr45() {
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    is_referee "$f" && continue
    is_generated "$f" && continue
    case "$f" in "$RUNNER"|"$SEAT") continue ;; esac   # GR11 already refused it
    o=$(owner_of "$f")
    if is_commons "$f"; then
      overridden GR5 || fail GR5 "$f is commons and this commit deletes it"
    elif [ "$o" != "$ME" ]; then
      overridden GR4 || fail GR4 "$f is $o's and this commit deletes it"
    fi
  done < "$TMP/gone"

  while IFS= read -r f; do
    is_referee "$f" && continue
    is_generated "$f" && continue
    # Weighed as whatever it was before somebody moved it. A file arriving under
    # a new name is a file with no history, and a file with no history is yours
    # and outside the commons - so a rename was a way to gut somebody's feature
    # while the referee watched a stranger's new file being quiet. Ask where it
    # came from and both questions below get the answer they had yesterday.
    from=$(came_from "$f"); from=${from:-$f}
    if [ "$from" = "$f" ]; then name="$f"; else name="$f (was $from)"; fi
    case "$from" in src/events/*) continue ;; esac   # GR11's ground, and it has no budget
    a=$(added_of "$f"); d=$(removed_of "$f"); net=$((d - a))
    # Net is a proxy, and a rewrite is its blind spot: replace 200 lines with
    # 210 different ones and net says almost nothing moved. The nudge below
    # does not block - the diff is public, this just makes the room look.
    if is_commons "$from"; then
      if [ "$net" -gt 60 ]; then
        overridden GR5 || {
          fail GR5 "$name loses $net lines net - the commons is shared ground"
          note "keep it additive, or say why: Golden-Rule-Override: GR5 - <reason>"
        }
      elif [ "$d" -gt 240 ] && ! overridden GR5; then
        warn GR5 "$name has $d lines rewritten in place - net says little moved, the diff says otherwise"
      fi
    else
      o=$(owner_of "$from")
      if [ "$o" != "$ME" ] && [ "$net" -gt 25 ]; then
        overridden GR4 || {
          fail GR4 "$name is $o's and loses $net lines net"
          note "tune it freely, gut it never - or: Golden-Rule-Override: GR4 - <reason>"
        }
      elif [ "$o" != "$ME" ] && [ "$d" -gt 100 ] && ! overridden GR4; then
        warn GR4 "$name is $o's and has $d lines rewritten in place - net hides a rewrite"
      fi
    fi
  done < "$TMP/files"
}

# ---------------------------------------------------------------------------
# GR6  One surprise per commit.
# ---------------------------------------------------------------------------
check_gr6() {
  # The rules and their machinery cannot land in pieces - GR10 already forces
  # them into their own commit with the reason on the record, and a referee
  # written in sh is verbose rather than surprising. The budget is for the
  # game, so a commit that is nothing but rule files does not spend it.
  if [ -s "$TMP/files" ]; then
    rulesonly=1
    while IFS= read -r f; do
      case "$f" in docs/*) continue ;; esac
      is_generated "$f" && continue
      is_referee "$f" || { rulesonly=0; break; }
    done < "$TMP/files"
    [ "$rulesonly" = 1 ] && return 0
  fi

  # awk rather than grep -c, which prints 0 and exits 1 on a docs-only commit -
  # and a docs-only commit is the normal shape after the book is rebuilt.
  files=$(awk '!/^docs\//' "$TMP/files" | wc -l | tr -d ' ')
  added=$(awk -F'\t' '$1!="-" && $3 !~ /^docs\// {a+=$1} END{print a+0}' "$TMP/stat")
  if [ "$added" -gt 1200 ] || [ "$files" -gt 25 ]; then
    overridden GR6 || {
      fail GR6 "$added lines across $files files - that is more than one surprise"
      note "split it, or: Golden-Rule-Override: GR6 - <reason>"
    }
  elif [ "$added" -gt 600 ]; then
    warn GR6 "$added lines added - large, but landing"
  fi
}

# ---------------------------------------------------------------------------
# GR14  Fly what you land.
#
# GR1 promises the next pilot that this opens and plays, and the referee cannot
# keep that promise - it reads the code, it does not press ENTER. This is the
# evidence half: a sealed tape on the board buys three landings, and the meter
# is read off the history by tools/flights.sh, not written down by anybody.
#
# Only a version spends a tape. A commit that leaves the cabinet alone leaves
# the meter alone with it - there is nothing new to find out by playing a README.
# ---------------------------------------------------------------------------
check_gr14() {
  [ -f tools/flights.sh ] || return 0

  # Whether this is a version at all is not decided here. It was, off a copied
  # path list, and the referee saying "version" where the book says otherwise is
  # a pilot grounded for a landing that never gets a chapter. $BOOK answers it
  # for the index, the worktree and a commit alike, which is exactly the three
  # modes below.
  case "$MODE" in
    rev) sh "$BOOK" --moved "$REV" 2>/dev/null || return 0 ;;
    *)   sh "$BOOK" --moved 2>/dev/null || return 0 ;;
  esac

  per=$(sh tools/flights.sh --per 2>/dev/null) || per=3
  case "$MODE" in
    staged) set -- --staged ;;
    rev)    set -- --at "$REV" ;;
    *)      set -- --dirty ;;
  esac
  n=$(sh tools/flights.sh --count "$ME" "$@" 2>/dev/null) || return 0
  case "$n" in ''|*[!0-9]*) return 0 ;; esac    # no meter, no verdict

  if [ "$n" -ge "$per" ]; then
    overridden GR14 || {
      fail GR14 "$n versions landed since you last flew - this would be number $((n + 1))"
      note "play it, copy the tape off the game-over screen, and /blackbox puts it on the board"
      note "or say why not: Golden-Rule-Override: GR14 - <reason>"
    }
  elif [ "$n" -eq "$((per - 1))" ]; then
    warn GR14 "this is the last landing your tape covers - fly it before the next one"
  fi
}

# ---------------------------------------------------------------------------
# GR12  The tally remembers.
#
# The ledger is derived, never authored: tools/tally.sh reads it off the
# history, and so can anybody else, which is what makes this checkable at all.
# The hooks write it after a bend and commit it on the spot; a pilot editing
# their own count by hand is the one thing here worth being strict about.
#
# Checked with the message in hand, because the commit that records a bend
# carries the trailer that counts it - the ledger has to match the history this
# commit is about to become, not the one behind it.
# ---------------------------------------------------------------------------
check_gr12() {
  LEDGER=src/game/ledger.js

  if grep -qx "$LEDGER" "$TMP/gone" 2>/dev/null; then
    hard GR12 "$LEDGER is the tally - nobody deletes their own record"
    note "it is generated: tools/tally.sh rewrites it from the history"
    return 0
  fi

  # The rest needs the message in hand, and at pre-commit there is not one yet.
  [ "$STAGE" = pre-commit ] && return 0

  grep -qx "$LEDGER" "$TMP/files" 2>/dev/null || return 0
  [ -f tools/tally.sh ] || return 0

  content "$LEDGER" > "$TMP/ledger.mine"
  if [ "$MODE" = rev ]; then
    # The ledger is a snapshot of the history behind it, and tools/tally.sh
    # reads the history in front of it too. Compare an old commit's ledger
    # against everything that has happened since and it is wrong every time -
    # not because the pilot edited it, but because they landed before the rest
    # of the evening did. So this half only runs where the two ends meet: the
    # tip, which is the commit that would actually merge. Deleting the file is
    # still refused above, on every commit, because that one does not depend on
    # where in the history you are standing.
    [ "$REV" = "$(git rev-parse HEAD)" ] || return 0
    # ... and at the tip the message is already history, so nothing is pending.
    sh tools/tally.sh --print > "$TMP/ledger.true" 2>/dev/null
  elif [ -n "$MSGFILE" ] && [ -f "$MSGFILE" ]; then
    sh tools/tally.sh --print --plus "$MSGFILE" > "$TMP/ledger.true" 2>/dev/null
  else
    sh tools/tally.sh --print > "$TMP/ledger.true" 2>/dev/null
  fi

  cmp -s "$TMP/ledger.mine" "$TMP/ledger.true" && return 0
  hard GR12 "$LEDGER does not say what the history says"
  note "the tally is not edited by hand - run tools/tally.sh, or --roll to read it"
  note "or leave $LEDGER out of this commit - the hooks keep it fresh"
}

# ---------------------------------------------------------------------------
# GR13  The owner's ground.
#
# One corner of this repository is one pilot's, and it is the orb in the book
# together with the song it listens to. The owner is the author of the first
# commit - derived like everything else here, so there is no name in a file for
# anybody to edit themselves into. No budget and no override: a rule about who
# may change a thing cannot come with a line that lets everybody change it.
# ---------------------------------------------------------------------------
check_gr13() {
  owner=$(git log --max-parents=0 --format='%an' 2>/dev/null | tail -1)
  [ -n "$owner" ] || return 0            # no history yet, nobody's ground yet
  [ "$owner" = "$ME" ] && return 0

  if grep -qx "$SONG" "$TMP/gone" 2>/dev/null || grep -qx "$BOOK" "$TMP/gone" 2>/dev/null; then
    hard GR13 "the room the book is read in is $owner's - it does not get deleted"
    return 0
  fi

  if grep -qx "$BOOK" "$TMP/files" 2>/dev/null; then
    git show "$BASE:$BOOK" 2>/dev/null | song_of > "$TMP/song.was"
    content "$BOOK" | song_of > "$TMP/song.now"
    cmp -s "$TMP/song.was" "$TMP/song.now" || {
      hard GR13 "the orb and its song are $owner's - that heredoc is not yours to change"
      note "the rest of $BOOK is ordinary work; the part that writes $SONG is not"
    }
  fi

  # The copy is the heredoc, byte for byte, so it only moves when the heredoc
  # does. A pilot with a stale docs/ rebuilding the book is the machine catching
  # up and is nobody's doing. A copy that no longer says what the script says is
  # somebody's doing, and it is the same edit by the other door.
  if grep -qx "$SONG" "$TMP/files" 2>/dev/null; then
    content "$BOOK" | song_of > "$TMP/song.src"
    content "$SONG" > "$TMP/song.mine"
    cmp -s "$TMP/song.src" "$TMP/song.mine" || {
      hard GR13 "$SONG has been edited away from what $BOOK writes, and it is $owner's"
      note "it is generated - the next rebuild would overwrite this anyway"
    }
  fi
}

# ---------------------------------------------------------------------------
# GR8, the one checkable corner of it: a breach line the table writes.
#
# The fairness rule itself stays on honour - no machine judges whether a
# feature is fair. What is checkable is the paperwork: a breach must name a
# pilot the history has actually seen (a typo would charge a phantom and let
# the real pilot walk), it must give a reason, and it should land as the
# ritual shape GR8 describes - the line and the regenerated ledger, nothing
# else riding along.
# ---------------------------------------------------------------------------
check_breach() {
  [ -n "$MSGFILE" ] && [ -f "$MSGFILE" ] || return 0
  grep -Eiq '^[[:space:]]*golden-rule-breach:' "$MSGFILE" || return 0

  grep -Ei '^[[:space:]]*golden-rule-breach:' "$MSGFILE" > "$TMP/blines"
  git log --format='%an' 2>/dev/null | sort -u > "$TMP/pilots"

  while IFS= read -r bl; do
    if ! printf '%s' "$bl" | grep -Eiq '^[[:space:]]*golden-rule-breach:[[:space:]]*GR[0-9]+[[:space:]]+.+[[:space:]]-[[:space:]].+'; then
      warn GR8 "a breach line is malformed and will count for nothing"
      note "the shape is: Golden-Rule-Breach: GR8 <git name> - <why the table agrees>"
      continue
    fi
    nm=$(printf '%s' "$bl" | sed -E 's/^[[:space:]]*[Gg][^:]*:[[:space:]]*//; s/^[A-Za-z0-9]+[[:space:]]+//; s/[[:space:]]+-[[:space:]].*$//')
    [ -n "$nm" ] || continue
    grep -qxF "$nm" "$TMP/pilots" || \
      hard GR12 "a breach names \"$nm\", and no commit here was ever authored by them"
  done < "$TMP/blines"

  # the ritual shape: the message and the ledger, not a vehicle for other work
  if grep -Ev '^docs/|^src/game/ledger\.js$' "$TMP/files" 2>/dev/null | grep -q .; then
    warn GR8 "a breach commit should carry the ledger and nothing else - this one carries more"
  fi
}

# ---------------------------------------------------------------------------
# GR3  Your feature, your file.   GR9  Keep the surprise.
# ---------------------------------------------------------------------------
check_gr39() {
  newfeat=0; readme=0
  git ls-tree -r "$BASE" --name-only 2>/dev/null > "$TMP/known"
  manifest=$(content src/features.js 2>/dev/null)

  while IFS= read -r f; do
    [ "$f" = "README.md" ] && readme=1
    case "$f" in
      src/core/registry.js|src/features.js) continue ;;   # one defines it, one lists it
      *.js) ;;
      *) continue ;;
    esac
    # an actual registration, not the word in a comment
    content "$f" | grep -Eq 'register\([{[]' || continue

    if ! is_feature_home "$f"; then
      warn GR3 "$f calls register() from outside src/entities|game|ui|render"
      continue
    fi

    grep -qx "$f" "$TMP/known" && continue    # not new, leave it alone
    newfeat=1

    printf '%s' "$manifest" | grep -q "\"\\./${f#src/}\"" || \
      warn GR3 "$f is not imported in src/features.js - nothing will ever load it"
    # Only the entities, because the guide turns things away and says so in
    # src/ui/fieldguide.js: a tile briefs the flight, and bookkeeping reveals
    # itself where it happens instead. A thing in the field is the one kind
    # nothing turns away - and even there the answer can be the other one, a
    # line saying why this one stays off the splash. Both spellings are looked
    # for at once, and they do not overlap: "No guide tile:" has a word between
    # the key and the colon, which is what keeps it out of the first pattern.
    case "$f" in src/entities/*.js)
      content "$f" | grep -Eqi 'guide[[:space:]]*:|no guide tile:' || \
        warn GR9 "$f has neither a guide entry nor a \"No guide tile:\" line saying why not" ;;
    esac
  done < "$TMP/files"

  [ "$newfeat" = 1 ] && [ "$readme" = 1 ] && \
    warn GR9 "new feature and a README edit together - let the game do the talking"
  return 0
}

# ---------------------------------------------------------------------------
# GR9  The pictures on the front door.
#
# media/ is the only description of this cabinet anybody reads without opening
# it, and until now nothing in here had an opinion about it. The last set ran
# eleven versions behind - a splash screen with no logo, no pilot card, no
# board and no seats on it, advertising a machine nobody could play any more -
# and every check in this file said clear the whole way.
#
# So: the same shape of meter GR14 keeps for flights, counting versions since
# media/ last moved. A nudge and never anything else. A picture is not a red
# line, and nobody should be stopped from landing a wave because the poster
# outside is out of date.
#
# What a version is, is not answered here. $BOOK answers it, the way GR14 asks
# rather than counting for itself - a second copy of that arithmetic is the
# thing tools/lockstep.sh exists to catch.
# ---------------------------------------------------------------------------
check_media() {
  [ -f "$BOOK" ] || return 0

  # No pictures, nothing to go stale. Cheap, and first: every other line in
  # here forks the book, and most clones asking this have nothing to answer.
  shot=$(git log -1 --format='%H' "$BASE" -- media/ 2>/dev/null) || return 0
  [ -n "$shot" ] || return 0

  # This commit is the reshoot. The pictures are of the game as it is about to
  # be, which is the most current they have ever been.
  grep -q '^media/' "$TMP/files" 2>/dev/null && return 0

  # Only a landing moves the meter, the way only a landing spends a tape:
  # rewriting the rules leaves the cabinet exactly as the last photograph
  # found it.
  case "$MODE" in
    rev) sh "$BOOK" --moved "$REV" 2>/dev/null || return 0 ;;
    *)   sh "$BOOK" --moved 2>/dev/null || return 0 ;;
  esac

  # Both counted as of $BASE, which is HEAD for a pilot at work and the parent
  # for a commit being read back - so the number means the same thing in all
  # three modes: versions that landed after the shutter closed, not counting
  # the one being landed now.
  now=$(sh "$BOOK" --versions "$BASE" 2>/dev/null | wc -l | tr -d ' ')
  was=$(sh "$BOOK" --versions "$shot" 2>/dev/null | wc -l | tr -d ' ')
  case "$now$was" in ''|*[!0-9]*) return 0 ;; esac

  # Eight, because eleven was plainly too many and a poster nobody has looked
  # at for eight evenings is describing a different machine. Reshooting is
  # twenty minutes: the game hangs everything off ASTEROIDS, so a staged frame
  # is a console script rather than an afternoon.
  [ "$((now - was))" -ge 8 ] || return 0
  warn GR9 "$((now - was)) versions since the pictures in media/ were taken - the front door is showing another cabinet"
  note "a nudge, and it stays one: nothing here is waiting on a photograph"
}

# ---------------------------------------------------------------------------
# GR15  Somebody else's turn.
#
# Every other rule in this file is about restraint. This one is about the
# opposite, and it is the only one nobody can break: a pilot working alone has
# done nothing wrong and the referee is not about to tell them they have.
#
# What it notices is the shape the book already draws. The cover shelves the
# history into books - a run of chapters one pilot flew with nobody else
# landing in between - and a cabinet that has never been handed over reads as
# one very long spine. GR14 counts your flights and GR12 counts your bends;
# neither has ever had an opinion about a run, so a pilot who flies everything
# they land and bends nothing can hold the keyboard forever with every check in
# here saying clear.
#
# Every fifth landing rather than every landing past the fifth. A nudge that
# fires on every commit is wallpaper by the third one, and then the true ones
# get skimmed past along with it - the same worry is_litter() came out of.
#
# The run itself is not counted here. $BOOK counts it, the way GR14 asks rather
# than keeping a copy of the meter, because a referee whose spine is a
# different length from the cover's is two answers to one question.
# ---------------------------------------------------------------------------
check_turns() {
  [ -f "$BOOK" ] || return 0

  # Only a landing is a turn at the keyboard. Rewriting these rules, ranking a
  # tape, filing the book: real work, and it hands nobody anything.
  case "$MODE" in
    rev) sh "$BOOK" --moved "$REV" 2>/dev/null || return 0 ;;
    *)   sh "$BOOK" --moved 2>/dev/null || return 0 ;;
  esac

  # As of $BASE - HEAD for a pilot at work, the parent for a commit being read
  # back - so what comes out is the run this landing is about to extend.
  run=$(sh "$BOOK" --run "$BASE" 2>/dev/null) || return 0
  n=$(printf '%s' "$run" | cut -f1)
  who=$(printf '%s' "$run" | cut -f2)
  case "$n" in ''|*[!0-9]*) return 0 ;; esac

  # Somebody else landed the last one. That is a handover, and a handover is
  # the thing this rule wants rather than the thing it mentions.
  [ "$who" = "$ME" ] || return 0

  n=$((n + 1))
  [ "$n" -ge 5 ] && [ "$((n % 5))" -eq 0 ] || return 0

  warn GR15 "$n versions in a row with one name on them - has anybody else had a turn?"
  note "a nudge at any number, and nothing goes on the tally: an evening alone is not an offence"
}

# ---------------------------------------------------------------------------
# the commit message is the changelog
# ---------------------------------------------------------------------------
check_message() {
  [ -n "$MSGFILE" ] && [ -f "$MSGFILE" ] || return 0
  subject=$(grep -v '^#' "$MSGFILE" | sed -n '1p')
  len=$(printf '%s' "$subject" | wc -c | tr -d ' ')
  if [ "$len" -lt 18 ]; then
    warn GR7 "subject is thin - write it from the player's seat, not the diff's"
  fi
  case "$(printf '%s' "$subject" | tr 'A-Z' 'a-z')" in
    wip*|fix*|update*|changes*|stuff*|misc*)
      warn GR7 "\"$subject\" - the next player reads this to find out what changed" ;;
  esac
  grep -Eiq '^[[:space:]]*chronicle:.{10,}' "$MSGFILE" || \
    warn GR9 "no Chronicle: line - the book will have to make do with your subject"
}

# ---------------------------------------------------------------------------
# The replay hazard.
#
# Not a rule either, and nobody's fault - a landmine, in a repository that
# happens to be full of them, and the referee is the one thing a pilot who has
# just stepped on it is likely to run.
#
# A rebase checks the worktree out to each commit it replays, .githooks/
# included, so an old commit runs the post-commit hook *it* shipped with. That
# hook rebuilds the book, the rebuild dirties the tree, and the replay refuses
# to lay the next commit down over it. Today's post-commit refuses to rebuild
# mid-replay, which fixes it going forward and can never fix a copy that landed
# before the guard existed - so replaying anything from before that will keep
# doing this, forever.
#
# tools/groundcrew.sh stopped rebasing for exactly this reason. A pilot who
# typed `git pull --rebase` by hand has no tool to catch them: what git says on
# the way past is that there are unstaged changes and a hint about --edit-todo,
# and neither of those is the thing that happened.
# ---------------------------------------------------------------------------
check_replay() {
  case "$MODE" in rev) return 0 ;; esac
  gd=$(git rev-parse --git-dir 2>/dev/null) || return 0
  [ -e "$gd/rebase-merge" ] || [ -e "$gd/rebase-apply" ] || return 0
  warn GIT "a rebase is in progress, and this repository fights one"
  note "an old post-commit rebuilds the book as it is replayed, which dirties"
  note "the tree, and the next commit will not apply over it. not your change."
  note "out: git rebase --abort, then git config pull.rebase false && git pull"
  note "tools/groundcrew.sh does that and rebuilds the book once, at the end"
}

# ---------------------------------------------------------------------------
# The referee's own arithmetic.
#
# Not a golden rule - a rule needs somebody to have broken it, and nobody breaks
# this one on purpose. "Does this commit count as a version" decides the number
# on the cabinet, the chapter in the book, the plate, the clean landing on the
# ledger and the meter under GR14, and it used to be answered in seven places
# that were asked by comment to keep up. tools/lockstep.sh is what asks them
# instead. When it says they disagree, several of the checks above are quietly
# measuring different commits from the ones the book will file.
#
# Only for a pilot who is here. In --rev the tools under review are whatever
# that commit shipped rather than what is in this tree, and in --json this runs
# after every keystroke somebody's editor decides to save.
# ---------------------------------------------------------------------------
check_lockstep() {
  [ -f tools/lockstep.sh ] || return 0
  case "$MODE" in rev) return 0 ;; esac
  [ "$FORMAT" = text ] || return 0
  out=$(sh tools/lockstep.sh 2>&1) && return 0
  fail LOCK "the readers of what counts as a version no longer agree"
  printf '%s\n' "$out" | sed -n 's/^  *no  */   /p' | while IFS= read -r l; do
    note "$l"
  done
  note "tools/lockstep.sh says it in full"
}

# --- run --------------------------------------------------------------------

case "$STAGE" in
  pre-commit) check_gr1; check_gr2; check_gr7; check_gr10; check_gr11; check_gr12
              check_gr13; check_gr39; check_media; check_turns; check_replay
              check_lockstep ;;
  commit-msg) check_gr45; check_gr6; check_gr10; check_gr12; check_gr14
              check_breach; check_message ;;
  *)          check_gr1; check_gr2; check_gr7; check_gr10; check_gr11
              check_gr45; check_gr6; check_gr12; check_gr13; check_gr14
              check_breach; check_gr39; check_media; check_turns; check_replay
              check_lockstep ;;
esac

if [ ! -s "$TMP/out" ]; then
  # a hook that passes says nothing; only a person asking gets an answer
  [ "$FORMAT" = text ] && [ "$STAGE" = all ] && printf '%sgolden rules: clear%s\n' "$D" "$Z"
  exit 0
fi

if [ "$FORMAT" = json ]; then
  {
    printf 'golden-check (working tree, advisory - the hooks decide at commit time):\n'
    cat "$TMP/out"
    [ "$BLOCK" = 1 ] && printf 'Fix these, or spend a budget with a Golden-Rule-Override line. See GOLDEN_RULES.md.\n'
  } | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' \
    | awk 'BEGIN{ORS="";print "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":\""}
           {print (NR>1?"\\n":"") $0}
           END{print "\"}}\n"}'
  # Same parting of the ways as below: advisory for a tree, binding for a
  # commit that already exists.
  [ "$MODE" = rev ] && [ "$BLOCK" = 1 ] && exit 1
  exit 0
fi

case "$STAGE" in
  pre-commit) LABEL='red lines' ;;
  commit-msg) LABEL='budgets, and the ledger' ;;
  *)          if [ "$MODE" = rev ]; then LABEL="all rules, as $ME landed them"
              else LABEL='all rules, advisory'; fi ;;
esac
printf '\n  GOLDEN RULES  %s%s%s\n' "$D" "$LABEL" "$Z"
cat "$TMP/out"

if [ "$BLOCK" = 1 ]; then
  case "$STAGE" in
    pre-commit) printf '\n  %sblocked.%s red lines are not overridable - fix it, or change the rule in its own commit.\n\n' "$R" "$Z" ;;
    commit-msg)
      if [ "$HARD" = 1 ]; then
        printf '\n  %sblocked.%s at least one of those is a red line - no message gets you\n           past it. Fix the cause, or change the rule in its own commit.\n\n' "$R" "$Z"
      else
        printf '\n  %sblocked.%s spend the budget if you mean it: add a line to the message\n           %sGolden-Rule-Override: GR4 - <why this is fair>%s\n\n' "$R" "$Z" "$D" "$Z"
      fi ;;
    *)
      # The friendly reading and the late one part company here. A pilot
      # asking the referee about their own tree is asking a question, and the
      # referee answers it without biting - the hooks decide at commit time.
      # A commit that already exists has had its commit time, and either the
      # hooks were never there or they were told not to look. Somebody has to
      # say so out loud, so this reading bites.
      if [ "$MODE" = rev ]; then
        printf '\n  %sthis one landed anyway.%s the hooks either were not installed or were\n' "$R" "$Z"
        printf '                          told not to look. GR12 costs two for that,\n'
        printf '                          and it is the room reading this, not a machine.\n\n'
        exit 1
      fi
      printf '\n  %swould block at commit time.%s see GOLDEN_RULES.md\n\n' "$R" "$Z" ;;
  esac
  [ "$STAGE" = all ] && exit 0
  exit 1
fi

[ "$WARNED" = 1 ] && printf '\n  %snudges only - nothing is stopping you.%s\n\n' "$D" "$Z"
exit 0
