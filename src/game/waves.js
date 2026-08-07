// Waves. Clear the field and the next one arrives a beat and a half later,
// harder, with a fresh bomb in every second rack — an atom bomb is earned,
// not an allowance.

(function (A) {
  "use strict";

  const CLEAR_PAUSE = 1.5;   // seconds of quiet between waves
  const BOMB_RACK = 4;       // how many bombs a pilot may stockpile

  function reset(mode) {
    if (mode !== "over") A.game.levelTimer = 0;
  }

  // Runs last, after everything that could have destroyed the final rock —
  // including the atom bomb, which does not go through splitAsteroid.
  function resolve(tick) {
    if (A.game.levelTimer <= 0) {
      if (!A.asteroids.length) A.game.levelTimer = CLEAR_PAUSE;
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
