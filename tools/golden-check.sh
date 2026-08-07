#!/bin/sh
# ---------------------------------------------------------------------------
# golden-check.sh - the referee for ASTEROIDS // HYPERCOLOR.
#
# Checks the current change against GOLDEN_RULES.md. In the spirit of the game
# itself there are no dependencies: sh, git, grep, sed, awk, and node if you
# happen to have one.
#
#   tools/golden-check.sh              what does the referee say about my work?
#   tools/golden-check.sh --staged     ... about what is staged
#   tools/golden-check.sh --install    install the hooks in this clone
#   tools/golden-check.sh --json       machine readable, for the editor hook
#
# Exit 0 = clear (warnings never block). Exit 1 = blocked.
#
# Six rules are red lines and cannot be overridden. Three are budgets: you may
# spend past them, but only by saying so in the commit message, where everybody
# can read it later. Two are nudges. One is on your honour.
# ---------------------------------------------------------------------------
set -u

MODE=worktree          # worktree | staged
STAGE=all              # all | pre-commit | commit-msg
MSGFILE=""
FORMAT=text            # text | json
BLOCK=0
WARNED=0
HARD=0

while [ $# -gt 0 ]; do
  case "$1" in
    --staged)        MODE=staged ;;
    --stage)         STAGE="${2:-all}"; shift ;;
    --message-file)  MSGFILE="${2:-}"; MODE=staged; shift ;;
    --json)          FORMAT=json ;;
    --install)       MODE=install ;;
    -h|--help)       sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
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

# --- the change under review ------------------------------------------------

if git rev-parse --verify -q HEAD >/dev/null 2>&1; then
  BASE=HEAD
else
  BASE=$(git hash-object -t tree /dev/null)
fi

ME=$(git config user.name 2>/dev/null || true)

if [ "$MODE" = staged ]; then
  git diff --cached --name-only --diff-filter=ACMR "$BASE" > "$TMP/files"
  git diff --cached --name-only --diff-filter=D    "$BASE" > "$TMP/gone"
  git diff --cached --numstat "$BASE"                      > "$TMP/stat"
else
  git diff --name-only --diff-filter=ACMR "$BASE" > "$TMP/files"
  git diff --name-only --diff-filter=D    "$BASE" > "$TMP/gone"
  git diff --numstat "$BASE"                      > "$TMP/stat"
  git ls-files --others --exclude-standard        > "$TMP/new"
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    printf '%s\t0\t%s\n' "$(wc -l < "$f" | tr -d ' ')" "$f" >> "$TMP/stat"
    printf '%s\n' "$f" >> "$TMP/files"
  done < "$TMP/new"
fi

if [ ! -s "$TMP/files" ] && [ ! -s "$TMP/gone" ]; then
  [ "$FORMAT" = text ] && printf 'nothing to check.\n'
  exit 0
fi

# content of a path as it will be committed
content() {
  if [ "$MODE" = staged ]; then git show ":$1" 2>/dev/null; else cat "$1" 2>/dev/null; fi
}

# will this path exist for the next person who clones?
path_exists() {
  if [ "$MODE" = staged ]; then git cat-file -e ":$1" 2>/dev/null
  else [ -f "$1" ]; fi
}

# the author of the commit that first added a file. empty means it is new,
# which means it is yours.
owner_of() {
  o=$(git log --follow --diff-filter=A --format='%an' -- "$1" 2>/dev/null | tail -1)
  [ -n "$o" ] || o="$ME"
  printf '%s' "$o"
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
  ref=0; game=0; reffiles=''
  # The book and the taglines are written by a machine from the history, and
  # they land with whatever commit comes next - including a rule change. They
  # are nobody's work, so they are neither side of this argument.
  while IFS= read -r f; do
    is_generated "$f" && continue
    if is_referee "$f"; then ref=1; reffiles="$reffiles $f"; else game=1; fi
  done < "$TMP/files"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    is_generated "$f" && continue
    if is_referee "$f"; then ref=1; reffiles="$reffiles $f"; else game=1; fi
  done < "$TMP/gone"
  [ "$ref" = 1 ] || return 0
  if [ "$game" = 1 ]; then
    hard GR10 "the rules and the game are moving together -$reffiles"
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
    case "$f" in src/events/*) continue ;; esac   # GR11's ground, and it has no budget
    a=$(added_of "$f"); d=$(removed_of "$f"); net=$((d - a))
    if is_commons "$f"; then
      if [ "$net" -gt 60 ]; then
        overridden GR5 || {
          fail GR5 "$f loses $net lines net - the commons is shared ground"
          note "keep it additive, or say why: Golden-Rule-Override: GR5 - <reason>"
        }
      fi
    else
      o=$(owner_of "$f")
      if [ "$o" != "$ME" ] && [ "$net" -gt 25 ]; then
        overridden GR4 || {
          fail GR4 "$f is $o's and loses $net lines net"
          note "tune it freely, gut it never - or: Golden-Rule-Override: GR4 - <reason>"
        }
      fi
    fi
  done < "$TMP/files"
}

# ---------------------------------------------------------------------------
# GR6  One surprise per commit.
# ---------------------------------------------------------------------------
check_gr6() {
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
  if [ -n "$MSGFILE" ] && [ -f "$MSGFILE" ]; then
    sh tools/tally.sh --print --plus "$MSGFILE" > "$TMP/ledger.true" 2>/dev/null
  else
    sh tools/tally.sh --print > "$TMP/ledger.true" 2>/dev/null
  fi

  cmp -s "$TMP/ledger.mine" "$TMP/ledger.true" && return 0
  hard GR12 "$LEDGER does not say what the history says"
  note "the tally is not edited by hand - run tools/tally.sh, or --roll to read it"
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
    case "$f" in src/entities/*.js)
      content "$f" | grep -q 'guide' || \
        warn GR9 "$f has no guide entry - nobody will discover it by playing" ;;
    esac
  done < "$TMP/files"

  [ "$newfeat" = 1 ] && [ "$readme" = 1 ] && \
    warn GR9 "new feature and a README edit together - let the game do the talking"
  return 0
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

# --- run --------------------------------------------------------------------

case "$STAGE" in
  pre-commit) check_gr1; check_gr2; check_gr7; check_gr10; check_gr11; check_gr12; check_gr39 ;;
  commit-msg) check_gr45; check_gr6; check_gr10; check_gr12; check_message ;;
  *)          check_gr1; check_gr2; check_gr7; check_gr10; check_gr11
              check_gr45; check_gr6; check_gr12; check_gr39 ;;
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
  exit 0
fi

case "$STAGE" in
  pre-commit) LABEL='red lines' ;;
  commit-msg) LABEL='budgets, and the ledger' ;;
  *)          LABEL='all rules, advisory' ;;
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
    *)          printf '\n  %swould block at commit time.%s see GOLDEN_RULES.md\n\n' "$R" "$Z" ;;
  esac
  [ "$STAGE" = all ] && exit 0
  exit 1
fi

[ "$WARNED" = 1 ] && printf '\n  %snudges only - nothing is stopping you.%s\n\n' "$D" "$Z"
exit 0
