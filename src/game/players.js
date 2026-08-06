// The roster.
//
// Drop-in co-op: a seat can join at any moment, and a pilot who runs out of
// lives can buy back in whenever they like. Joining is never refused.
//
// This module owns who is playing and how many lives they have. How a ship
// flies is entities/ship.js's business.

(function (A) {
  "use strict";

  const players = A.players = [];

  A.livePlayers = () => players.filter((p) => p && !p.out);
  A.flyingShips = () => players.filter((p) => p && !p.out && !p.dead);

  A.nearestShip = function nearestShip(x, y) {
    let closest = null, bestD = Infinity;
    for (const p of A.flyingShips()) {
      const d = Math.hypot(p.x - x, p.y - y);
      if (d < bestD) { bestD = d; closest = p; }
    }
    return closest;
  };

  /** A fresh hull for a seat, spaced out from the others. */
  A.makeShip = function makeShip(p) {
    const spread = (p.idx - (A.SEATS.length - 1) / 2) * 120;
    return {
      x: A.W / 2 + spread, y: A.H / 2, vx: 0, vy: 0,
      angle: -Math.PI / 2,
      radius: 11,
      invuln: 2.5,
      dead: false,
      hook: null,
      hookCooldown: 0,
      boost: 0,
    };
  };

  function makePlayer(idx) {
    const p = {
      idx,
      hue: A.SEATS[idx].hue,
      lives: 3,
      score: 0,
      bombs: 2,
      bombCooldown: 0,
      fireCooldown: 0,
      respawnTimer: 0,
      hook: null,
      hookCooldown: 0,
      boost: 0,
      out: false,
    };
    Object.assign(p, A.makeShip(p));
    return p;
  }

  A.joinPlayer = function joinPlayer(idx) {
    let p = players[idx];
    if (!p) {
      p = makePlayer(idx);
      players[idx] = p;
    } else {
      // buying back in after running out
      p.lives = 3;
      p.bombs = Math.max(p.bombs, 2);
    }
    p.out = false;
    p.respawnTimer = 0;
    Object.assign(p, A.makeShip(p));
    p.invuln = 3;
    A.shockwave(p.x, p.y, p.hue, 190, 340);
    A.screenFlash(p.hue, 0.2);
    A.blip(560, 0.2, "square", 0.14);
    return p;
  };

  A.resetPlayers = function resetPlayers() {
    players.length = 0;
  };

  A.killShip = function killShip(p) {
    A.boom(3);
    A.kaboom(p.x, p.y, 46, 10, undefined, 2.2);
    A.shockwave(p.x, p.y, 0, 340, 520);
    A.shockwave(p.x, p.y, 60, 240, 380);
    A.shockwave(p.x, p.y, 300, 180, 260);
    A.screenFlash(0, 0.55);
    A.shakeBy(26);
    A.aberrate(1);
    A.deathBloom(p.x, p.y, 1.4);
    A.slowmo(0.25);
    p.dead = true;
    p.hook = null;
    p.boost = 0;
    // drop any one-shot still latched, so a press made mid-death does not spend
    // itself the instant you come back
    A.clearEdgeKeys(p.idx);
    p.lives--;
    // the riff only goes full-length when the whole crew is down
    const lastStanding = A.livePlayers().every((q) => q === p || q.lives <= 0);
    A.playRiff(p.lives <= 0 && lastStanding);
    p.respawnTimer = p.lives <= 0 ? 2.2 : 1.7;
  };
})(ASTEROIDS);
