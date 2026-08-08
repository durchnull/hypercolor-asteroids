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

The hooks stamp `Version: vN`, check the red lines, check the budgets against
your overrides, and rebuild the book afterwards. Report the version number and
what the next pilot will see.

If the commit leaves `index.html`, `src/` and `styles/` alone — a rule change,
a rebuilt book, a line in the README — it is not a version and gets no
`Version:` stamp. That is correct, not a failure. Say which version is still on
the cabinet rather than announcing a new one.

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

A filing commit is not a story. Subject line only — no `Chronicle:` line, no
`Tagline:`, nothing to explain. The referee will nudge about the missing
chronicle line and the nudge is wrong here, which is the one place in this
ritual to ignore it: the book passes over its own filing in silence everywhere
it speaks, and a book that narrated its own bookkeeping would never reach a
last chapter.

Report the version that landed, not the filing commits. The pilot asked for a
version; the paperwork is the tail of it.
