// The handful of facts the whole cabinet agrees on. Anything narrower than
// this — where the rocks are, how angry the kraken is — belongs to the feature
// that owns it, not here.

(function (A) {
  "use strict";

  const BEST_KEY = "asteroids-best";

  A.game = {
    phase: "start",   // start | playing | over
    paused: false,
    level: 1,
    levelTimer: 0,    // counts down to the next wave once the field is clear
    best: 0,
  };

  try {
    A.game.best = Number(localStorage.getItem(BEST_KEY)) || 0;
  } catch (e) {}

  // "running" is the state every gameplay feature actually cares about: the
  // game is on and nobody has hit pause.
  A.isRunning = () => A.game.phase === "playing" && !A.game.paused;

  A.recordBest = (score) => {
    if (score > A.game.best) {
      A.game.best = score;
      try { localStorage.setItem(BEST_KEY, String(A.game.best)); } catch (e) {}
    }
    return A.game.best;
  };
})(ASTEROIDS);
