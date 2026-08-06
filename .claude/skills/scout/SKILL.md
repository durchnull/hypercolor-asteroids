---
name: scout
description: Look around before you build - what the other pilots landed since you last played, who owns which files, which parts of the game nobody has touched in a while, and where a new feature can land without stepping on anyone. Use at the start of any session that will change the game, or when the user asks what is new, what changed, who did what, or what they should work on.
model: sonnet
effort: medium
argument-hint: "[optional: a pilot's name, a file, or the corner of the game you are thinking of building in]"
allowed-tools: Bash, Read, Grep, Glob
---

# Scout

Nobody should start building until they know what landed while they were away.
This is five minutes of reading that prevents most of the ways this project
could stop being fun.

## Look

```sh
tools/chronicle.sh --recent 10                     # the story so far
git log --oneline -15
git log --since="3 weeks ago" --format='%an' | sort | uniq -c | sort -rn
git log --since="3 weeks ago" --name-only --format= | sort | uniq -c | sort -rn | head -20
ls src/entities/ src/game/ src/ui/
cat src/features.js          # the manifest: everything on the board
```

For any file you are thinking of touching, find out whose it is — the author of
the commit that created it owns it under GR4:

```sh
git log --follow --diff-filter=A --format='%an %ad' -- <file> | tail -1
git log --format='%an' -- <file> | sort | uniq -c | sort -rn   # who has been in it since
```

## Notice

- **Fresh work.** Anything landed in the last few days is still warm. Read it
  before you build next to it, and do not rebalance it the same week somebody
  shipped it — let them see their own version get played first.
- **Whose turn it is.** If one pilot has landed the last six versions and
  another has landed nothing, say so. This project is better when the surprise
  comes from different directions.
- **Contested files.** A file with four different authors in a month is a
  design problem, not a merge problem: something belongs in a feature module
  that is currently living in the commons.
- **Quiet corners.** Systems nobody has touched in months — the starfield, the
  song, the CRT pass — are the best places to put a surprise, because nobody is
  expecting one there.
- **Unclaimed ground.** Read the `guide` entries in `src/entities/` and ask what
  the game obviously lacks.

## Report

Four or five lines, not an essay:

- what landed since last time, in the pilots' own words (their chronicle lines)
- who has been busy and who has not
- whose toes the user is about to step on, if any
- two or three suggestions for where a new feature could land cleanly

Then stop and let them choose. Do not start building during a scout.
