---
name: land
description: The commit ritual for this cabinet - run the referee, hand the build to the pilot to play, write a subject line from the next pilot's seat and a Chronicle line for the book, then commit. Use whenever work is finished and ready to become a version, or when the user says land it, ship it, or commit.
model: opus
effort: high
argument-hint: "[optional: the subject line you want, or the Chronicle line to put on the record]"
allowed-tools: Bash, Read, Edit, Write, Grep, Glob
---

# Land

A commit here is a version, and somebody is going to pull it and press ENTER
expecting a game. Do the whole ritual; it takes two minutes.

## 0. Collect the ground crew's paperwork

```sh
tools/groundcrew.sh
```

`.github/workflows/book.yml` rebuilds the book after every push to main and
files it as **Ground Crew**. That lands while the pilot is working, so a
landing built on a stale main is a push that gets rejected an hour later for
reasons that have nothing to do with the pilot. Run this first and the landing
is built on top of the remote instead.

It is quiet when there is nothing waiting, quiet when there is no network, and
it takes the paperwork itself when there is any: fetch, merge it, rebuild the
book over whatever the union drivers made of the generated files, file that.

It merges rather than rebases on purpose. A rebase checks the worktree out to
each commit it replays, `.githooks/` included, so an old commit runs the
`post-commit` it shipped with — which rebuilds the book, dirties the tree and
stops the replay on the next commit. No fix to that hook can reach a copy that
landed before the fix existed. Nothing of the pilot's moves, either, which is
GR7 kept rather than argued with.

It stops and hands back, exit 1, in two cases, and neither is a thing to work
around:

- **a person's commit is waiting.** Somebody flew that. Read it before you
  build on top of it — that is CLAUDE.md's rule, not this tool's — and pull it
  yourself once you have.
- **the working tree is dirty.** A replay would drag the pilot's half-finished
  edit through it. Commit or stash, then run it again.

Never reach for `git pull --rebase` to get around a stop. The stop is the
point.

Then get off `main`, because that is not where a version lands any more:

```sh
tools/branch.sh <name>        # -> <mark>/<name>, e.g. game/comets-come-in-threes
tools/branch.sh --rename      # if you cut the branch before you knew
```

A branch lives in a directory and the directory is its mark — the same word
the pull request and the chapter will wear, read off what you changed rather
than typed. Not `feat/` or `fix/`: every change is one of those, so the word is
spent before it has said anything. If nothing has changed yet the tool says so
and asks you to name one, which is the honest answer to branching first.

`main` takes pull requests and nothing else (GR7). The pre-push hook refuses
every push to it and the remote's ruleset refuses the same ones from the other
side, so a branch is not a formality here — it is the only route. Paperwork
first, branch second, in that order: `tools/groundcrew.sh` only ever looks at
`main`, and on a branch it exits without a word.

## 1. The referee

```sh
tools/golden-check.sh
```

Fix everything red. If what it flags is a **budget** (GR4, GR5, GR6, GR14), do
not quietly work around it and do not argue: tell the user plainly what the
change costs somebody else, offer the override line, and let them decide. If
they confirm, write the override and land it — that is what budgets are for.

Never suggest `--no-verify`. If you find yourself wanting to, the answer is
either a smaller commit or an override line.

## 2. Hand it to the pilot

GR1 is a promise to someone who is not in the room, and the referee cannot keep
it for you — it reads the code, it does not run the game. Somebody has to press
ENTER, and that somebody is the pilot, not you.

Say what you changed and what to look for, then wait:

```sh
python3 -m http.server 8000    # then open http://localhost:8000
```

- the thing you built actually happens
- the console is clean
- the field guide shows your entry
- both seats still work

Do not drive a browser, and never report a build as played. "The code looks
right" is not a playtest and saying so is the whole failure GR1 exists to
prevent. If the pilot waves it through unplayed that is their call — land it,
and do not pretend in the commit message that it was checked.

**Then ask for the tape.** They played until they died; the game-over screen is
holding a sealed flight record with a copy button on it. One paste and
`/blackbox` puts it on the board, which is what GR14 counts — a tape covers this
landing and the next two, and the meter is public either way:

```sh
tools/flights.sh --count "$(git config user.name)"
```

Ask once, after the playtest and before the commit message, and take no for an
answer. A pilot who does not feel like ranking a four-minute death is not doing
anything wrong; they are just spending their next three landings' worth of
credit, and the referee will say so when it runs out.

## 3. Write it for the next pilot

The subject line is what somebody reads before they press ENTER. Write what
they will *notice*, not what you changed.

- `Comets, and they come in threes` — yes
- `add comet feature` — no
- `wip`, `fixes`, `update` — the referee will nudge you, and it is right

The `Chronicle:` line goes into `docs/index.html` for good. Third person, one
sentence, and it is allowed to be funny about you:

```
Comets, and they come in threes

Chronicle: Dave added comets on a Tuesday, then made them faster than the
           blaster, apparently on purpose.
```

Ask the user for the chronicle line, or draft one and let them redraw it. It is
their chapter, not yours.

## 4. Commit

```sh
git add -A && git commit
```

The hooks check the red lines, check the budgets against your overrides, and
rebuild the book afterwards. The version number is not written into the message
— it is counted off the history, so it can move, and the template shows you
what this one becomes without recording it. Report the version number and what
the next pilot will see; `tools/chronicle.sh --version` is the answer after the
commit lands.

If the commit leaves `index.html`, `src/` and `styles/` alone — a rule change,
a rebuilt book, a line in the README — it is not a version at all, and the
template says so instead of offering you a tagline. That is correct, not a
failure. Say which version is still on the cabinet rather than announcing a new
one.

The template also shows you the **tagline** the version will land under, and
you can replace it in the message:

```
Tagline: Dave built a door that only opens for other people.
```

Leave it out and `tools/tagline.sh` writes one from what the commit did. Either
way it is kept in `docs/taglines.tsv` and never rewritten, so it is worth ten
seconds of thought — offer the pilot the generated line and let them redraw it,
the same as the `Chronicle:` line.

If a hook blocks the commit, read what it said and fix the cause. Do not
retry the same commit with the check disabled.

## 5. File the paperwork, and do not stop one round early

The book describes commits, so it can only be built once they exist: the
`post-commit` hook rebuilds `docs/` into the working tree, paints the plate and
writes the tagline *after* the landing. Every commit therefore leaves the tree
dirty, by design. Landing is not finished until that is filed, so file it —
staging the generated paths and nothing else that happens to be lying about:

```sh
git status --porcelain -- docs src/game/ledger.js     # what the hook just wrote
git add -A -- docs src/game/ledger.js
git commit -m "The paperwork from <what landed>, filed"
```

**Then look again, because once is usually not enough.** Round one often
carries `src/game/ledger.js` — the refreshed clean-landing count — and the book
counts any commit touching `src/` as a version, generated file or not. So that
filing commit becomes a version itself and earns a chapter, a plate and a
tagline: more paperwork. Round two touches nothing but `docs/`, which is not a
version, so the book has nothing to say about it and the tree comes out clean.

Repeat until `git status --porcelain` is empty. It settles in two rounds at the
outside; if a third is somehow needed, stop and say so rather than looping,
because something else is dirty and it is not the book's doing.

One thing this hook deliberately does *not* do is run during a replay. A
rebase, a merge or a cherry-pick reaches `post-commit` once per commit it lays
down, against a history that is half rewritten — so it writes nothing, and
whoever finishes the replay rebuilds once at the end. `tools/groundcrew.sh`
does that; a pilot doing it by hand runs `tools/chronicle.sh` and
`tools/tally.sh` and files the result.

A filing commit is not a story. Subject line only — no `Chronicle:` line, no
`Tagline:`, nothing to explain. The referee will nudge about the missing
chronicle line and the nudge is wrong here, which is the one place in this
ritual to ignore it: the book passes over its own filing in silence everywhere
it speaks, and a book that narrated its own bookkeeping would never reach a
last chapter.

Report the version that landed, not the filing commits. The pilot asked for a
version; the paperwork is the tail of it.

## 6. Open the pull request

```sh
git push -u origin <name>
gh pr create
```

`.github/PULL_REQUEST_TEMPLATE.md` is already in the box. It ends the way a
turn at the keyboard ends — a ship drawn fresh, then what the next pilot finds
out by playing, then who else it happens to — and the same rule applies: write
a block only when this branch gave it something to say, and delete the rest.
Draft it for the pilot the way you draft the `Chronicle:` line, and let them
redraw it. This repository is public and somebody who has never pressed ENTER
here may read it first.

Do not spoil the surprise in it (GR9). Tease the thing; the reveal belongs in
the game.

Do not fill in assignees, reviewers or labels. `.github/workflows/strip.yml`
does all three the moment the pull request opens — the author is assigned to
their own, the owner is asked for a review unless they wrote it, and the labels
come out of `tools/labels.sh`, which reads the same buckets the book draws
with. `tools/labels.sh main..HEAD` shows you what they will be if you want to
know first.

The merge is the pilot's, on github, and it is a **merge commit** — squashing
collapses several versions into one and rebasing hands every commit a new sha,
and the book counts versions off commits. Say so once if they ask which button.

Then it is out of your hands: the referee reads every commit on the branch on
the way in, and Ground Crew files the book on the way out. Nothing to push
afterwards, and nothing of yours to collect until next session, when step 0
takes it.
