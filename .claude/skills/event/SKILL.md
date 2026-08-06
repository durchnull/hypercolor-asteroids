---
name: event
description: Write, tune or review an event - an unexpected challenge dropped into a live wave that fires for every pilot except the one who wrote it. Use when the user wants to lay a trap, add an event, ambush the others, make the game meaner, or asks what events exist and who is armed against whom.
model: opus
effort: high
argument-hint: "[optional: what the ambush should do to the field, or which of your own events to retune]"
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, mcp__playwright__browser_navigate, mcp__playwright__browser_press_key, mcp__playwright__browser_click, mcp__playwright__browser_evaluate, mcp__playwright__browser_console_messages, mcp__playwright__browser_take_screenshot, mcp__playwright__browser_resize, mcp__playwright__browser_close
---

# Event

An event is an ambush: three krakens surfacing at once from three sides, a ring
of rock closing in, the Falcon arriving with something behind it. Any pilot may
write them, and the rule that makes it worth doing is that **an event never
fires for the pilot who wrote it.** You lay traps for the others; they lay
traps for you.

## Whose file

One file per pilot, named after them, and they own it outright:

```sh
git config user.name                  # this is the name you sign with
ls src/events/
```

`src/events/<your git name, kebab-cased>.js`. If it does not exist, create it
and add one line to `ASTEROIDS.MODULES` in `src/features.js`.

**Never open another pilot's event file.** Not to read it aloud to the user, not
to "just rebalance it", not with an override — there is none. GR11 is a red
line because the entire mechanic rests on nobody being able to disarm what is
waiting for them. If the user asks, say so in one sentence and offer to write
them a better one of their own.

## Writing one

```js
(function (A) {
  "use strict";

  A.defineEvent({
    id: "dave:vice",              // unique across the game, prefix with yours
    by: "Dave Okoro",             // your git name, exactly. or A.HOUSE.
    name: "THE VICE",             // the banner the victim gets
    blurb: "TWO WALLS, CLOSING",  // the small line under it
    minWave: 3,                   // earliest wave it may fire on
    weight: 2,                    // likelihood against the other events
    cooldown: 3,                  // waves before it may repeat
    fire() { /* your worst */ },
  });
})(ASTEROIDS);
```

`by: A.HOUSE` means it belongs to nobody and fires for everyone, you included —
the honourable option when you want the thing in the game more than the credit.

Read `src/events/house.js` for worked examples. What `fire()` has to hand:
`A.spawnSquid()`, `A.spawnPortals()`, `A.spawnFalcon()`, `A.spawnPlanet()`,
`A.makeAsteroid(x, y, size)` pushed onto `A.asteroids`, `A.flyingShips()`, and
the whole effects bench — `A.shockwave`, `A.screenFlash`, `A.shakeBy`,
`A.aberrate`, `A.slowmo`, `A.kaboom`, `A.boom`, `A.blip`.

## What makes a good one

- **Survivable if read early, lethal if ignored.** The vice leaves a corridor.
  The debris ring has a gap. Give the player the information and let them earn
  it — GR8 says difficulty may rise but must stay fair.
- **Unmistakable.** It gets a banner and a flash for a reason: the player must
  know an event started, or it reads as the game glitching.
- **Bounded.** It fires and it is over. Nothing that permanently changes the
  run, nothing that stacks with itself, nothing that can spawn a second copy.
- **Kind to both seats.** It cannot target one seat and ignore the other.
- **Cheap.** It runs inside a frame. Spawning forty rocks is not an event, it
  is a frame drop with a name.
- Set `minWave` honestly. An ambush on wave 1 is not a surprise, it is a wall.

## Checking it

```sh
tools/golden-check.sh
tools/whoami.sh              # lock your seat, so yours go quiet for you
python3 -m http.server 8000  # then play, as somebody else, and get caught
```

You cannot test your own event by playing as yourself — that is the point. To
see it fire, pick GUEST in the picker, or delete `src/game/whoami.local.js`
temporarily. Do not ship a change to the profile system to make testing easier.

Then land it with `/land`, and write the `Chronicle:` line as the boast it is.
