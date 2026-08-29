// The ship: turning, thrust, drag, guns, and what happens after you die.
//
// One pass per joined seat. Everything it reads about the pilot comes from
// A.keys[seat] — nothing in here knows which physical key that was.

(function (A) {
  "use strict";

  const TURN = 4.2;          // radians per second
  const MOUSE_TURN = 7;      // radians per second — mouse-aim still has to swing round, not snap
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

  // p.angle accumulates rather than wrapping (turning left for a minute keeps
  // subtracting), so a target angle from atan2 needs its own shortest way
  // round rather than a plain subtraction.
  function shortestDiff(target, angle) {
    let d = (target - angle) % A.TAU;
    if (d > Math.PI) d -= A.TAU;
    else if (d < -Math.PI) d += A.TAU;
    return d;
  }

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
    // The crosshair is a promise about what the mouse currently does, so it
    // has to track solo/multi even across a phase change (game over, a pause,
    // player two dropping in) rather than only while a round is live.
    document.body.classList.toggle("mouse-aim", tick.running && A.solo() && A.mouseEngaged);
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

      // Keys and touch buttons always turn, seat 0 included, and taking the
      // wheel that way hands the mouse back — it only takes it again once it
      // actually moves (src/input/mouse.js). Solo only (GR8): two seats
      // share one mouse, so the cursor never aims anybody but seat 0, and
      // only while seat 1 is not in the game.
      if (key.left) p.angle -= TURN * dt;
      if (key.right) p.angle += TURN * dt;
      if (p.idx === 0 && (key.left || key.right)) A.mouseEngaged = false;
      if (p.idx === 0 && A.solo() && A.mouseEngaged) {
        const step = MOUSE_TURN * dt;
        const diff = shortestDiff(A.mouseAim(p), p.angle);
        p.angle += Math.max(-step, Math.min(step, diff));
      }
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

  // The hull as a solid, built over the same four points the flat game draws,
  // so looking straight down at it gives back exactly the silhouette the seat
  // cards print. The dart was always a good shape; it only ever needed a
  // spine — a canopy ridge nose to tail, wings left flat either side of it,
  // and one keel underneath that you never see from up here.
  //
  // A single peak over the middle was the first thing tried and it was wrong:
  // four edges radiating to one apex read as a diamond, and the ship stopped
  // looking like a ship. The ridge is what puts the nose back.
  const hull = () => A.mesh.get("ship:hull", () => {
    const [N, R, T, L] = A.SHIP_HULL;
    const verts = [
      [N[0], N[1], 0], [R[0], R[1], 0], [T[0], T[1], 0], [L[0], L[1], 0],
      [0, -4, 5.0],      // 4, the canopy
      [0, -2, -2.8],     // 5, the keel
    ];
    // Four panels on top and four underneath, and no more than that. An
    // earlier deck had a second ridge vertex and five struts, which at the
    // size a ship actually is on screen is eleven glowing lines inside
    // twenty pixels — it bloomed into a white smear. Fewer edges is what
    // makes it legible, not a dimmer colour.
    return A.mesh.build(verts, [
      [0, 1, 4], [4, 1, 2], [0, 4, 3], [4, 2, 3],
      [1, 0, 5], [2, 1, 5], [3, 2, 5], [0, 3, 5],
    ]);
  });

  // The flame is built in the hull's own space rather than lathed and turned,
  // because a cone that has to be rotated into place is a cone somebody will
  // get backwards later.
  const flame = () => A.mesh.get("ship:flame", () => {
    const verts = [[0, 18, 0]];
    const ring = [];
    for (let i = 0; i < 6; i++) {
      const a = (i / 6) * A.TAU;
      ring.push(verts.length);
      verts.push([Math.cos(a) * 4.4, 9, Math.sin(a) * 4.4]);
    }
    const faces = [ring.slice().reverse()];
    for (let i = 0; i < 6; i++) faces.push([ring[i], ring[(i + 1) % 6], 0]);
    return A.mesh.build(verts, faces);
  });

  const shell = () => A.mesh.get("ship:shield", () => A.mesh.ball(1));

  const at = {};

  function draw3d(tick, s) {
    if (!tick.running) return;
    for (const p of A.livePlayers()) {
      A.hook3d(p, s);
      if (p.dead) continue;
      if (p.invuln > 0 && Math.floor(p.invuln * 8) % 2 === 0) continue;

      if (p.invuln > 0) {
        at.x = p.x; at.y = p.y; at.z = 0;
        at.rx = at.ry = 0; at.rz = p.invuln * 1.4;
        at.s = 21 + Math.sin(p.invuln * 9) * 2;
        at.hue = p.hue - 60; at.light = 70;
        at.alpha = 0.34; at.width = 1; at.dim = 0.04; at.glow = true;
        s.model(shell(), at);
      }

      at.x = p.x; at.y = p.y; at.z = 0;
      at.rx = 0; at.ry = 0; at.rz = p.angle + Math.PI / 2;
      at.s = 1;
      at.hue = p.hue; at.light = 66;
      // the same dimming the rocks get: this is a hull that catches light, and
      // a hull bright enough to read as paint drowns in its own bloom
      at.alpha = 1; at.width = 1.8; at.dim = 0.13; at.glow = false;
      s.model(hull(), at);

      if (A.keys[p.idx].thrust && Math.random() > 0.3) {
        at.hue = p.hue + 60; at.light = 62;
        at.sx = at.sz = 0.8 + Math.random() * 0.5;
        at.sy = 0.7 + Math.random() * 0.9;
        at.s = undefined;
        at.alpha = 0.55; at.width = 1.4; at.dim = 0.1; at.glow = true;
        s.model(flame(), at);
        at.sx = at.sy = at.sz = undefined;
      }
    }
  }

  function draw(tick, g) {
    if (!tick.running) return;
    for (const p of A.livePlayers()) {
      if (!A.gl.on) A.drawHook(p, g);
      if (!A.gl.on) drawShip(p, g);
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

  A.register({ id: "ship", order: { update: 10, draw: 60 }, reset, update, draw, draw3d });
})(ASTEROIDS);
