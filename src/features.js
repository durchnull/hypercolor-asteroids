// THE MANIFEST — every module in the game, in load order.
//
// Adding a feature: write src/entities/your-thing.js, add one line to the
// second list, done. Removing one: delete the line and the file. Nothing else
// in the codebase mentions it.
//
// This is the only file two feature branches are ever likely to both touch, and
// a one-line append is about the cheapest merge conflict there is.

ASTEROIDS.MODULES = [
  // ---- the commons: the cabinet everything else is built on ----------------
  // Order matters here — each of these is used by the ones below it.
  "./core/registry.js",
  "./core/state.js",
  "./core/viewport.js",
  "./core/math.js",
  "./render/palette.js",
  "./render/starfield.js",
  "./render/compositor.js",
  "./audio/context.js",
  "./audio/buses.js",
  "./audio/voices.js",
  "./audio/song.js",
  "./audio/sfx.js",
  "./audio/riff.js",
  "./input/bindings.js",
  "./input/input.js",
  "./game/difficulty.js",
  "./game/players.js",
  "./game/profile.js",
  "./game/ledger.js",
  "./game/tally.js",
  "./game/events.js",
  "./game/lifecycle.js",
  "./ui/overlays.js",
  "./ui/mute.js",
  "./ui/fieldguide.js",
  "./ui/lobby.js",
  "./core/loop.js",

  // ---- the features: everything that lives, moves or draws ----------------
  // Order does not matter here. Add yours at the end and keep it alphabetical.
  "./render/effects.js",
  "./entities/asteroids.js",
  "./entities/bullets.js",
  "./entities/falcon.js",
  "./entities/hook.js",
  "./entities/kraken.js",
  "./entities/nuke.js",
  "./entities/planet.js",
  "./entities/portals.js",
  "./entities/ship.js",
  "./game/blackbox.js",
  "./game/waves.js",
  "./ui/debrief.js",
  "./ui/hud.js",
  "./ui/profile.js",

  // ---- the events: one file per pilot, and the pilot owns it ---------------
  // Yours never fire for you. Add your own line, never touch anybody else's.
  // See GOLDEN_RULES.md, GR11.
  "./events/house.js",
  "./events/david-friedrich.js",
];
