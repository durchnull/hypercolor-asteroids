---
name: shoot
description: Stage and shoot the cabinet for media/ - drive the game from the browser console into the frame you want, freeze it, and take the picture. Use when the pictures are stale, when the referee mentions media/, or when somebody wants a screenshot of a feature for the readme or the book.
model: opus
effort: high
argument-hint: "[optional: what the picture should show - a wave, a feature, the splash]"
allowed-tools: Bash, Read, Edit, Write, Grep, Glob
---

# Shoot

The pictures in `media/` are the only description of this cabinet anybody reads
without opening it, and they go stale in silence — the referee counts versions
since that directory last moved and mentions it past eight. It stays a nudge at
any number: a poster does not stop a landing.

**A staged frame is a console script, not a game you played well.** Everything
the game owns hangs off `window.ASTEROIDS`, so the scene is written rather than
waited for. Twenty minutes, not an afternoon.

## The shape of a take

```js
A.startGame([0, 1])                 // or [0] for one seat
A.asteroids.length = 0              // clear what the wave brought
A.bullets.length = 0
A.squids.length = 0
A.portals.length = 0
// ... place what the picture is about, by hand
```

Drive input by writing the seat's own state — `A.keys[seat]`, `A.held[seat]` —
rather than sending keystrokes. Stub `A.killShip` and `A.damageSquid` for the
duration: nothing should die in the middle of a shoot.

A kraken is the awkward one, because it is mid-dive whenever it looks good:
`A.spawnSquid()` and then pin its `x`, `y`, `z`, `hp` and `diveTimer` every
frame, or it will have arrived, hit something and left before the shutter.

## The four things that took a while to work out

- **Trails need motion, shapes need stillness.** Run the live loop about half a
  second so the phosphor layer builds, then scale every velocity by `0.02` —
  not to zero, because the kraken reads its rotation off `atan2(vy, vx)` and a
  dead stop points it at nothing — pin `spin`, `phase` and `roll`, and run two
  more frames. Crisp hulls with a ghost still behind them.
- **Freeze by replacing `window.requestAnimationFrame` with a no-op.** The
  loop's own call then never fires and the canvas holds. It kills the loop for
  good: restarting needs `A.startLoop()`, and calling that while the loop is
  still alive gives you two loops and a game at double speed.
- **`A.keys[seat].fire` is not an edge action.** It stays latched until
  something clears it, so a stray `true` left over from the last take fires
  bullets into the next one and splits the rock you were about to grapple.
- **The grapple has to be led.** `A.fireHook` hands the claw the ship's own
  velocity, so aiming at the rock misses it. Solve for the throw direction and
  give the ship a mostly *tangential* velocity — then it swings, which is what
  the picture is of.

## The palette

The HUD and the panels take their colours from CSS `cycle` animations — a nine
second hue-rotate in `hud.css`, `overlay.css` and `logo.css`. Pause **those**
at `currentTime = 0` for the palette the thing was designed in. Do not pause
every animation on the page: the field guide is built out of a `rise` stagger
and pausing it empties the guide.

## Housekeeping

Browser-driven screenshots land in the repository root by default. Pass an
absolute path into the scratchpad instead, and move only the finished frames
into `media/`. Close the browser when the shoot is over.

Reshooting is real work and it leaves the cabinet exactly as it was, so it is a
mention rather than a number — and it is one of the few commits that wants the
`media/` nudge to go quiet in the same breath.
