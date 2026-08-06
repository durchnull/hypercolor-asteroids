// Start, finish, attract. The three moments where the whole board changes.
//
// None of these know what is on the board: they set the phase and ask every
// feature to reset itself. `mode` says what kind of reset it is —
//
//   "play"     a new game is starting; wipe and re-seed
//   "attract"  the menu; wipe, and put up something pretty to look at
//   "over"     the game just ended; the field stays on screen behind the
//              overlay, so only stop what should stop moving
//
// A feature that ignores a mode simply keeps what it had.

(function (A) {
  "use strict";

  A.startGame = function startGame(seats = [0]) {
    A.game.level = 1;
    A.game.paused = false;
    A.game.phase = "playing";
    A.run("reset", "play");
    for (const i of seats) A.joinPlayer(i);
    A.hideOverlays();
  };

  A.attract = function attract() {
    A.game.phase = "start";
    A.run("reset", "attract");
  };

  A.gameOver = function gameOver() {
    A.game.phase = "over";
    A.run("reset", "over");

    const joined = A.players.filter(Boolean);
    const best = A.recordBest(Math.max(...joined.map((p) => p.score), 0));
    const scores = joined.length > 1
      ? joined.map((p) => A.SEATS[p.idx].tag + " " + p.score).join(" &nbsp;&middot;&nbsp; ")
      : String(joined[0] ? joined[0].score : 0);
    A.showGameOver(scores, best);
  };
})(ASTEROIDS);
