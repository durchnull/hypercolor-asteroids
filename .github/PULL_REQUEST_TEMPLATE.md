<!--
  The referee reads your commits, not this box. This is for the room.

  Keep it short. The reveal is supposed to happen in the game (GR9), so a pull
  request that explains the surprise in full has spent it before anybody got to
  find it by playing.
-->

## What the next pilot finds out by playing

<!-- One or two lines, written from their seat. Not a changelog. -->

## The tape

<!--
  GR14: a sealed flight buys three landings. Play it, die, copy the tape off
  the game-over screen, and put it on the board - the ranking commit can be in
  this same pull request.

  If this changes nothing under index.html, src/ or styles/, say so and delete
  the rest of this section; work that leaves the cabinet alone leaves the meter
  alone.
-->

- [ ] I flew this build, and the tape is on `docs/RANKINGS.md`
- [ ] or: this does not move the game, so there is nothing to fly

## Anything bent

<!--
  Overrides go in the commit message, not here - that is the whole point of
  them, and this box is not the history. If a commit in this branch carries a
  `Golden-Rule-Override:` line, just say which and why in a sentence, so nobody
  has to go looking.

  Nothing is blocked by an override. It costs one on the tally (GR12), your
  events start coming for you sooner, and it stays in the book under your name.
-->

---

<!--
  Before you open this:

    tools/golden-check.sh --install    once per clone, wires up the hooks
    tools/whoami.sh                    your seat, so your own traps go quiet
    tools/inbound.sh                   what the referee will say about this branch

  That last one is exactly what CI runs. If it is quiet here it will be quiet
  there.

  A rule change lands in its own commit with a `Rule-Change:` line and no game
  code beside it (GR10). Arguing with a rule is allowed and encouraged; doing
  it in the same breath as using it is not.
-->
