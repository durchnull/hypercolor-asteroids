// The ship: turning, thrust, drag, guns, and what happens after you die.
//
// One pass per joined seat. Everything it reads about the pilot comes from
// A.keys[seat] — nothing in here knows which physical key that was.

(function (A) {
  "use strict";

  const TURN = 4.2;          // radians per second
  const THRUST = 260;        // px/s²
  const TOP_SPEED = 820;
  const FIRE_GAP = 0.22;
  const MAX_SHOTS = 5;       // bullets each pilot may have in the air
  const CUT_WINDOW = 0.16;   // hold the grapple button longer than this to winch

  // The hull, and the flame off the back of it, as points rather than as
  // drawing calls — because the seat cards on the splash print the same two
  // outlines (src/ui/lobby.js), and a ship on the card that is not the ship in
  // the field is worse than no ship on the card at all.
  A.SHIP_HULL = [[0, -13], [9, 11], [0, 6], [-9, 11]];
  A.SHIP_FLAME = [[-5, 9], [0, 18], [5, 9]];

  /** Open a path along a point list. Closing and stroking is the caller's. */
  function trace(g, pts) {
    g.beginPath();
    for (let i = 0; i < pts.length; i++) {
      if (i) g.lineTo(pts[i][0], pts[i][1]);
      else g.moveTo(pts[i][0], pts[i][1]);
    }
  }

  function reset(mode) {
    if (mode !== "over") A.resetPlayers();
    A.clearEdgeKeys();
  }

  function update(tick) {
    if (!tick.running) return;
    const dt = tick.dt;

    for (const p of A.players) {
      if (!p || p.out) continue;
      const key = A.keys[p.idx];

      if (p.dead) {
        p.respawnTimer -= dt;
        if (p.respawnTimer <= 0) {
          if (p.lives <= 0) {
            p.out = true;                 // spectating; can buy back in any time
            if (!A.livePlayers().length) { A.gameOver(); return; }
          } else {
            Object.assign(p, A.makeShip(p));
            A.shockwave(p.x, p.y, p.hue, 160, 300);
          }
        }
        continue;
      }

      if (key.left) p.angle -= TURN * dt;
      if (key.right) p.angle += TURN * dt;
      if (key.thrust) {
        p.vx += Math.cos(p.angle) * THRUST * dt;
        p.vy += Math.sin(p.angle) * THRUST * dt;
        if (Math.random() < 0.6) {
          const back = p.angle + Math.PI;
          const spread = A.rand(-0.4, 0.4);
          A.spark({
            x: p.x + Math.cos(back) * 12,
            y: p.y + Math.sin(back) * 12,
            vx: p.vx + Math.cos(back + spread) * A.rand(60, 150),
            vy: p.vy + Math.sin(back + spread) * A.rand(60, 150),
            angle: back, spin: A.rand(-6, 6),
            len: A.rand(2, 6), life: A.rand(0.2, 0.45),
            hue: A.hue + p.hue + A.rand(-30, 30),
          });
        }
      }

      // A swing has to keep what it is carrying, so the line and its afterglow
      // suspend the usual space-drag — that is what makes the exit worth taking.
      p.boost = Math.max(0, p.boost - dt);
      const swinging = p.hook && p.hook.state === "attached";
      const drag = Math.pow(swinging ? 0.94 : p.boost > 0 ? 0.88 : 0.4, dt);
      p.vx *= drag;
      p.vy *= drag;
      const sp = Math.hypot(p.vx, p.vy);
      if (sp > TOP_SPEED) { p.vx *= TOP_SPEED / sp; p.vy *= TOP_SPEED / sp; }
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      A.wrap(p);
      if (p.invuln > 0) p.invuln -= dt;

      // ---- grapple: one button, two jobs ----
      p.hookCooldown = Math.max(0, p.hookCooldown - dt);
      if (key.hook) {
        key.hook = false;          // tap to throw, tap again to cut it loose
        if (p.hook) p.hook.cutAt = CUT_WINDOW;   // unless you keep holding it
        else A.fireHook(p);
      }
      if (p.hook) {
        const down = A.held[p.idx].hook;
        p.hook.reel = p.hook.state === "attached" && down && p.hook.cutAt === undefined;
        if (p.hook.cutAt !== undefined) {
          if (!down) A.releaseHook(p);
          else if ((p.hook.cutAt -= dt) <= 0) p.hook.cutAt = undefined;
        }
      }
      A.updateHook(p, dt);

      // ---- guns ----
      p.fireCooldown -= dt;
      const mine = A.bullets.filter((b) => b.owner === p).length;
      if (key.fire && p.fireCooldown <= 0 && mine < MAX_SHOTS) {
        A.fireBullet(p);
        p.fireCooldown = FIRE_GAP;
        A.blaster();
        A.shakeBy(1.8);
      }

      // ---- the panic button ----
      p.bombCooldown = Math.max(0, p.bombCooldown - dt);
      if (key.bomb) {
        key.bomb = false;          // one bomb per press, never on auto-repeat
        A.detonate(p);
      }
    }

    // A seat that is empty or spectating buys in with its fire button.
    for (let i = 0; i < A.SEATS.length; i++) {
      if (!A.keys[i].fire) continue;
      const p = A.players[i];
      if (!p || p.out) { A.keys[i].fire = false; A.joinPlayer(i); }
    }
  }

  function draw(tick, g) {
    if (!tick.running) return;
    for (const p of A.livePlayers()) {
      A.drawHook(p, g);
      drawShip(p, g);
    }
  }

  function drawShip(ship, g) {
    if (ship.dead) return;
    if (ship.invuln > 0 && Math.floor(ship.invuln * 8) % 2 === 0) return;
    const c = A.neon(A.hue + ship.hue, 72);
    // shield bubble while respawn protection lasts
    if (ship.invuln > 0) {
      g.save();
      g.globalAlpha = 0.5;
      A.glow(A.neon(A.hue + ship.hue - 60, 70));
      g.lineWidth = 1.3;
      g.setLineDash([5, 5]);
      g.lineDashOffset = -ship.invuln * 30;
      g.beginPath();
      g.arc(ship.x, ship.y, 21 + Math.sin(ship.invuln * 9) * 2, 0, A.TAU);
      g.stroke();
      g.restore();
    }
    g.save();
    g.translate(ship.x, ship.y);
    g.rotate(ship.angle + Math.PI / 2);
    A.glow(c);
    g.lineWidth = 2.2;
    trace(g, A.SHIP_HULL);
    g.closePath();
    g.stroke();
    if (A.keys[ship.idx].thrust && Math.random() > 0.3) {
      A.glow(A.neon(A.hue + ship.hue + 60, 65));
      g.lineWidth = 2;
      // the tip stretches, the roots stay bolted to the hull
      const [root, tip, far] = A.SHIP_FLAME;
      trace(g, [root, [tip[0], tip[1] + Math.random() * 8], far]);
      g.stroke();
    }
    g.restore();
  }

  A.register({ id: "ship", order: { update: 10, draw: 60 }, reset, update, draw });
})(ASTEROIDS);
