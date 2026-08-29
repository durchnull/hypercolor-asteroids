<!--
  main takes pull requests and nothing else (GR7), so this box is how a version
  arrives. The referee reads your commits, not this - it has already started on
  them. This is for the room.

  Write it the way a turn ends at the keyboard: a ship, then what the next
  pilot finds out by playing, then who else it happens to. Five headings below,
  and the same rule as at the keyboard applies - **write a block only when this
  branch gave it something to say, and delete the ones that did not.** Never
  "None", never a placeholder. Three empty blocks teach the room to skim past
  the one that mattered. Three of the five is a normal pull request.

  Keep it short, and keep the surprise. The reveal is supposed to happen in the
  game (GR9); a pull request that explains the whole trick has spent it before
  anybody got to find it by playing. Tease it.

  This repository is public. Somebody who has never pressed ENTER on this
  cabinet may read this before anyone in the room does. Write for them too.
-->

```
                     .                *                    .
          *                    .            .
                   .      __                        *
    .                  .-'  `-.         .                        .
              *       (  o  o  )                   .
                       `--==--'      *                     .
        .                 /||\                 .
                *        ` || `        .                *      .
```

<!--
  Draw a new ship every time. A different hull, a different angle, a different
  piece of sky, 100 columns to play with. Never paste the last one back and do
  not keep a stash of them - a flourish that repeats is a logo. Do not caption
  it either. Under about twelve lines, because the ship is the flourish and
  YOUR MOVE is the point.
-->

## WHAT CHANGED

<!--
  The version verdict in the first three words, because it is the first thing
  anybody asks: **v32.** or **Not a version - v31 is still on the cabinet.**
  `tools/chronicle.sh --next` has already worked it out; quote it rather than
  deciding it again.

  Then one or two lines on what the next pilot notices by *playing*, written
  from their seat. Not a changelog - the diff is right there and nobody reads a
  list of files twice. If it made the game worse - a nerf, a wave that stopped
  being fair, somebody's feature quietly gutted - that goes here in the same
  plain voice. It is the honest half of GR8 and it is never dressed up.
-->

## WHAT IT DOES TO THE OTHERS

<!--
  Only when the answer is not nothing - and in a shared cabinet it usually is
  not. A new event arms the room and names the one pilot it will never fire at.
  A tuned number lands in somebody's feature, and names them. A difficulty
  change says which seat feels it first.

  Name people, not files. This is the one place GR8 becomes visible at the
  moment it becomes true, and the people it happens to are reading.
-->

## THE TAPE

<!--
  GR14: a sealed flight buys three landings. Play it, die, copy the tape off
  the game-over screen, and put it on the board - the ranking commit is welcome
  in this same pull request.

  Nobody writes a tape by hand, ever, for any reason (GR16). They come off the
  glass or they are not tapes.
-->

- [ ] I flew this build, and the tape is on `docs/RANKINGS.md`
- [ ] or: this does not move the game, so there is nothing to fly

## WHAT IT COST ME

<!--
  Only when something was spent. Overrides live in the commit message, not
  here - that is the whole point of them and this box is not the history. If a
  commit on this branch carries a `Golden-Rule-Override:` line, say which and
  why in a sentence so nobody has to go looking.

  Nothing is blocked by an override. It costs one on the tally (GR12), your own
  events start coming for you sooner, and it stays in the book under your name.
  Write it flat - it is a difficulty setting, not a confession.

  `tools/tally.sh --roll` and `tools/flights.sh --count "<name>"` have the real
  numbers. A line whose tool did not run does not get written.
-->

## YOUR MOVE

<!--
  Three lines at most, one verb each, for whoever is reading. What do they do
  to see this - which wave, which key, which corner of the screen. Copy-
  pasteable.

  Merge it with a **merge commit**. Squashing collapses several versions into
  one and rebasing hands every commit a new sha; the book counts versions off
  commits, and either button breaks GR7 on the author's behalf.
-->

1. `git switch <this branch> && python3 -m http.server 8000`
2. <!-- the thing to watch for, in one clause -->

---

<!--
  Before you open this:

    tools/golden-check.sh --install    once per clone, wires up the hooks
    tools/whoami.sh                    your seat, so your own events go quiet
    tools/groundcrew.sh                on main, before you branched
    tools/inbound.sh                   what the referee will say about this branch
    tools/labels.sh main..HEAD         what this will be tagged as

  The middle one is exactly what CI runs. If it is quiet here it will be quiet
  there. The last one is a preview, not a chore - the flight strip puts those
  labels on for you, assigns you to your own pull request, and asks the owner
  for a review. Do not fill any of that in by hand.

  A rule change lands in its own commit with a `Rule-Change:` line and no game
  code beside it (GR10). Arguing with a rule is allowed and encouraged; doing
  it in the same breath as using it is not.
-->
