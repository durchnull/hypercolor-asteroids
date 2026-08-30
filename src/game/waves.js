// Waves. Clear the field and the next one arrives a beat and a half later,
// harder, with a fresh bomb in every second rack — an atom bomb is earned,
// not an allowance.
//
// The beat and a half is spent at light speed (src/render/lightspeed.js). That
// is a picture and a noise and nothing else: the pause is the same length it
// has always been, and the rocks arrive on the same frame they always did.

(function (A) {
  "use strict";

  const CLEAR_PAUSE = 1.5;   // seconds between waves, spent in the jump
  const BOMB_RACK = 4;       // how many bombs a pilot may stockpile

  function reset(mode) {
    if (mode !== "over") A.game.levelTimer = 0;
  }

  // Runs last, after everything that could have destroyed the final rock —
  // including the atom bomb, which does not go through splitAsteroid.
  function resolve(tick) {
    if (A.game.levelTimer <= 0) {
      if (!A.asteroids.length) {
        A.game.levelTimer = CLEAR_PAUSE;
        A.lightspeed(CLEAR_PAUSE);   // punch it — the burst lands as the wave does
        // Clearing the rocks does not clear the kraken, and the jump whites the
        // screen out at the end of it. Nothing gets to kill a pilot inside a
        // transition the game itself made unreadable, so the invulnerability
        // arrival already hands out starts when the drive does.
        for (const p of A.flyingShips()) p.invuln = Math.max(p.invuln, CLEAR_PAUSE);
      }
      return;
    }
    A.game.levelTimer -= tick.dt;
    if (A.game.levelTimer > 0) return;

    A.game.level++;
    A.spawnField();
    for (const p of A.flyingShips()) p.invuln = Math.max(p.invuln, 1.5);
    // a bomb after every second cleared wave: levels run 1, 2, 3... so the
    // odd ones (3, 5, 7) are the paydays
    if (A.game.level % 2 === 1) {
      for (const p of A.livePlayers()) if (p.bombs < BOMB_RACK) p.bombs++;
    }
    A.showBanner("LEVEL " + A.game.level, A.WAVE_NAMES[A.game.level], 1.9);
    A.screenFlash(A.hue + 120, 0.28);
    A.shockwave(A.W / 2, A.H / 2, A.hue + 120, Math.max(A.W, A.H), 900);
  }

  A.register({ id: "waves", order: { resolve: 900 }, reset, resolve });
})(ASTEROIDS);
