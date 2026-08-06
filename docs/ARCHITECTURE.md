# How this cabinet is wired

No build step, no dependencies, no bundler, no server. You double-click
`index.html` and the game runs. Everything below exists to keep that true while
still letting a dozen people work on it at once.

The rule the whole layout is built around: **a change should touch one file.**
If two people add two features in the same week, the only line they both touch
is a single entry in [`src/features.js`](../src/features.js).

---

## Why classic scripts and not ES modules

Because `import` cannot be fetched from a `file://` page — every browser blocks
it — and opening the game by double-clicking it is the point. So instead of an
import graph there is:

- **one global namespace**, `window.ASTEROIDS`, called `A` inside every module;
- **one manifest**, `src/features.js`, listing every file in load order;
- **one loader**, `src/boot.js`, the only `<script>` tag in `index.html`.

Each file is an IIFE that takes the namespace, keeps its own internals private,
and hangs its public parts on `A`:

```js
(function (A) {
  "use strict";

  const mines = [];          // private: nobody outside can see this
  A.mines = mines;           // public: everyone can

  A.layMine = function layMine(x, y) { ... };
})(ASTEROIDS);
```

The loader injects the manifest's scripts with `async = false`, which the HTML
spec guarantees will execute in insertion order, so the list is the load order
and `main.js` is always last.

---

## The map

```
index.html            the shell — canvas, overlays, empty containers, and one
                      <script src="src/boot.js">. Rarely edited.
styles/               one file per region of the screen
  tokens.css            palette, reset, the two shared keyframes
  crt.css  hud.css  overlay.css  lobby.css  touch.css

src/
  boot.js             the loader. One script tag points here
  features.js         THE MANIFEST — every module, in load order
  main.js             boot: size, build DOM, install input, start the loop

  core/
    registry.js       features register here; the loop asks it who runs
    state.js          A.game — phase, paused, level, best
    loop.js           the frame: update → resolve → draw
    viewport.js       canvases, A.W / A.H / A.DPR, resize
    math.js           A.TAU, A.rand, A.wrap

  render/
    palette.js        the drifting A.hue, A.neon(), A.glow()
    starfield.js      nebula + stars, drawn under everything
    effects.js        debris, shockwaves, popups, shake, flash, slow-mo
    compositor.js     fade-trails, bloom, aberration, banner, pause

  audio/
    context.js        the one AudioContext, mute, noise
    buses.js          the mixing desk (guitar, lead, bass, drums)
    voices.js         the band: chug, leadNote, bassNote, kick, snare…
    song.js           the four-section track and its scheduler
    sfx.js            every one-shot noise the game makes
    riff.js           the death riff

  input/
    bindings.js       A.SEATS: keys, names, colours, touch pad. Edit this to
                      rebind anything or to add a third pilot
    input.js          A.keys[seat][action] / A.held[seat][action]

  game/
    lifecycle.js      startGame / gameOver / attract
    difficulty.js     A.tune() — everything that scales with the wave
    players.js        the roster, joining, dying
    waves.js          clear the field → next wave

  entities/           one file per thing in the game
    ship.js bullets.js asteroids.js hook.js kraken.js
    nuke.js portals.js planet.js falcon.js

  events/             one file per pilot — see game/events.js

  ui/
    hud.js            score panels, generated from A.SEATS
    overlays.js       splash + game over
    fieldguide.js     the splash field guide, generated from the features
    lobby.js          the seat cards, generated from A.SEATS
    mute.js           the sound button
```

---

## The frame

`core/loop.js` runs three phases through the registry, then renders:

| phase | when | for |
|---|---|---|
| `update(tick)` | every frame, running or not | movement, timers, spawning |
| `resolve(tick)` | only while running | collisions and rules |
| `draw(tick, g)` | every frame | strokes onto the glowing entity layer |

`tick` is `{ dt, raw, time, running }` — `dt` is scaled by slow-mo, `raw` is not.
It is one reused object, so new fields can be added without touching a single
feature.

A feature that should only act during play starts with `if (!tick.running) return;`.
Anything before that line still runs on the menu and while paused — which is how
the rocks drift behind the splash screen and the kraken's drone fades out
instead of cutting off.

`reset(mode)` is the fourth hook, called by `game/lifecycle.js`:

| mode | meaning |
|---|---|
| `"play"` | a new game — wipe and re-seed |
| `"attract"` | the menu — wipe, and put up something worth looking at |
| `"over"` | the game just ended; the field stays on screen behind the overlay, so only stop what should stop moving |

---

## Adding a feature

One file. Say `src/entities/mine.js`:

```js
(function (A) {
  "use strict";

  const mines = A.mines = [];

  function reset(mode) {
    if (mode !== "over") mines.length = 0;
  }

  function update(tick) {
    if (!tick.running) return;
    for (const m of mines) { m.x += m.vx * tick.dt; A.wrap(m); }
  }

  function resolve() {
    for (const p of A.flyingShips()) {
      if (p.invuln > 0) continue;
      for (const m of mines) {
        if (Math.hypot(m.x - p.x, m.y - p.y) < m.radius + p.radius) A.killShip(p);
      }
    }
  }

  function draw(tick, g) {
    if (!tick.running) return;
    for (const m of mines) {
      A.glow(A.neon(A.hue + 200, 65));
      g.beginPath();
      g.arc(m.x, m.y, m.radius, 0, A.TAU);
      g.stroke();
    }
  }

  A.register({
    id: "mines",
    order: { update: 45, resolve: 15, draw: 45, guide: 35 },
    reset, update, resolve, draw,
    guide: {                        // optional: your row on the splash screen
      name: "MINE",
      meta: "500",
      tint: "var(--magenta)",
      icon: `<svg width="34" height="34" viewBox="0 0 34 34" fill="none"
               stroke="currentColor" stroke-width="1.3"><circle cx="17" cy="17" r="9"/></svg>`,
      desc: "Sits there. Does not move. Ruins your day.",
    },
  });
})(ASTEROIDS);
```

…then one line in `src/features.js`, at the end of the features list:

```js
  "./entities/mine.js",
```

That is the whole change. The field guide, the frame, the resets and the render
order all pick it up. Deleting the feature is deleting the file and that line.

### Where in the order?

`order` is a number, or an object per hook; the default is 50. Nothing breaks if
you pick a number nobody else uses — leave gaps.

| | 10 | 20 | 30 | 40 | 50 | 60 | 70 | 80 | 88–95 | 850+ |
|---|---|---|---|---|---|---|---|---|---|---|
| **update** | ship | bullets | asteroids | kraken | nuke | portals | falcon | planet | effects, hud | |
| **resolve** | asteroids | kraken | | | | | | | | events, waves |
| **draw** | planet | portals | kraken (deep) | asteroids | kraken (surface) | ship | falcon | nuke | effects, bullets | |

Draw order is back-to-front. A feature may register more than one entry — the
kraken does, so that a diving one passes behind the rocks and a surfacing one in
front of them.

---

## House rules

**Everything shared lives on `A`. Everything else is private.** A `const` inside
your IIFE cannot be reached from another file, which is the point: put on the
namespace only what others genuinely need, and it doubles as the list of what
you are promising to keep working.

**Read mutable values off `A` every time.** `A.W`, `A.H`, `A.hue`, `A.planet`,
`A.portals`, `A.nuke`, `A.falcon`, `A.audio` and the audio buses all change at
runtime. `const { W, H } = A` at the top of a file captures a stale number and
is the one mistake this layout makes easy — don't.

**Arrays are shared in place.** `A.asteroids`, `A.bullets`, `A.squids`,
`A.players` are created once and mutated. Never reassign one; use `.length = 0`.

**Screen feel goes through `render/effects.js`.** `A.shakeBy`, `A.screenFlash`,
`A.kaboom`, `A.shockwave`, `A.popup`, `A.slowmo`, `A.aberrate`. They take the
loudest caller, so a small knock never damps a big one.

**Every noise lives in `audio/sfx.js`.** They are safe to call before the audio
context exists and while muted — they return.

**Balance numbers that scale with the wave go in `game/difficulty.js`.** Numbers
that belong to one feature stay at the top of that feature, named.

**Load order is the manifest.** A feature is loaded after every commons file, so
at *call* time everything is there. Only top-level code in your IIFE has to care
about order, so keep top-level code to declarations and `A.register(...)`.

---

## The merge-conflict contract

| you are… | you touch |
|---|---|
| adding or changing a feature | your one file in `entities/`, plus one line in `features.js` |
| rebinding keys, adding a seat | `input/bindings.js` — alone |
| retuning the difficulty ramp | `game/difficulty.js` — alone |
| changing a sound | `audio/sfx.js`, or one file in `audio/` |
| restyling a region of the screen | one file in `styles/` |
| changing what the splash says about your feature | the `guide` block in your feature |

`index.html` holds no lists and no per-feature copy, which is why it almost never
appears in a diff. The HUD, the seat cards and the field guide are generated —
they cannot drift from the code, and two people adding two features do not both
edit the same markup.

---

## Running it

Open `index.html`. That is the whole procedure, and it is a promise: if you ever
find yourself needing a server to see your change, something has gone in that
should not have.
