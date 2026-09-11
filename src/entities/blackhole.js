// The black hole. It comes in off one edge, crosses the field at walking pace,
// and leaves off the other side, and it does not care what was in the way.
//
// Everything carrying a velocity feels it — rocks, both seats, shots, krakens —
// and feels it harder the closer it gets, the way gravity does: inverse square,
// so from across the field it is a nudge and up close it is the only fact in
// the room. Whatever crosses the horizon is gone. Not destroyed, gone: a rock
// it eats scores nobody anything, a shot it eats hits nothing, a ship it eats
// is a ship that flew into a black hole.
//
// The GR8 argument is drawn on the glass. Two rings: the bright one is the
// horizon and it never changes size. The faint one is the point of no return,
// which is the exact distance at which the pull equals what a ship's engine
// can give — THRUST is 260 in entities/ship.js, and NORETURN below is solved
// from that. Outside the faint ring a burn always wins. Inside it a burn loses
// and only your existing speed can carry you past, which is what a slingshot
// is. And the whole thing moves at walking pace along a straight line, so a
// pilot who watches for two seconds knows exactly where it will not be.
//
// The pull is added to velocities rather than taken off them, for the same
// reason the grapple in entities/hook.js does its own damping: an acceleration
// composes with a swing, and a well that a taut line cancelled would be a well
// nobody on a line has to answer.
//
// A public thing in the field, like A.planet. An event sends one today;
// anything else that wants one may ask, and there is never more than one.

(function (A) {
  "use strict";

  const HORIZON = 34;       // px: the ring, and the only part that swallows
  const G = 2.4e6;          // px³/s²: pull at distance d is G / d²
  const NORETURN = Math.sqrt(G / 260);   // where the pull equals a ship's thrust
  const NEAR = HORIZON;     // the pull stops growing inside the horizon
  const SPEED = 26;         // px/s, which is walking pace on this glass
  const ROCKPULL = 1.4;     // rocks are lighter than ships and feel it more
  const SHOTPULL = 0.6;     // shots are fast and brief; the bend is what shows
  const MARGIN = 140;       // px past the edge before it counts as gone

  A.blackhole = null;

  /** Send one in off an edge. There is only ever one; a second ask is ignored. */
  A.spawnBlackhole = function spawnBlackhole() {
    if (A.blackhole) return A.blackhole;
    // In off one side, aimed at a point well inside the far third of the
    // opposite side, so the line always crosses the middle of the field and
    // never skims an edge where nobody would meet it.
    const edge = Math.floor(A.rand(0, 4));
    let x, y, tx, ty;
    if (edge === 0)      { x = -MARGIN; y = A.rand(0.2, 0.8) * A.H; tx = A.W + MARGIN; ty = A.rand(0.25, 0.75) * A.H; }
    else if (edge === 1) { x = A.W + MARGIN; y = A.rand(0.2, 0.8) * A.H; tx = -MARGIN; ty = A.rand(0.25, 0.75) * A.H; }
    else if (edge === 2) { x = A.rand(0.2, 0.8) * A.W; y = -MARGIN; tx = A.rand(0.25, 0.75) * A.W; ty = A.H + MARGIN; }
    else                 { x = A.rand(0.2, 0.8) * A.W; y = A.H + MARGIN; tx = A.rand(0.25, 0.75) * A.W; ty = -MARGIN; }
    const d = Math.hypot(tx - x, ty - y) || 1;
    A.blackhole = {
      x, y,
      vx: ((tx - x) / d) * SPEED,
      vy: ((ty - y) / d) * SPEED,
      spin: A.rand(0, A.TAU),
      age: 0,
      fed: 0,           // what it has eaten, which only the picture cares about
      hum: 0,
    };
    A.blip(44, 1.2, "sine", 0.16);
    return A.blackhole;
  };

  // Acceleration at a distance. Clamped at the horizon so the last few pixels
  // are not a division by nothing, and so what happens there is the swallow
  // rather than a number.
  const pullAt = (d) => G / (Math.max(d, NEAR) * Math.max(d, NEAR));

  function haul(h, list, k, dt) {
    for (const o of list) {
      if (o.arrive > 0) continue;              // a rock still out in the depth
      const dx = h.x - o.x, dy = h.y - o.y;
      const d = Math.hypot(dx, dy) || 1;
      const f = pullAt(d) * k * dt;
      o.vx += (dx / d) * f;
      o.vy += (dy / d) * f;
    }
  }

  function swallowed(h, o, r) {
    return Math.hypot(o.x - h.x, o.y - h.y) < HORIZON + (r || 0) * 0.5;
  }

  function feed(h, x, y, hue) {
    h.fed++;
    h.hum = 1;
    A.kaboom(x, y, 8, 3, hue, 0.6);
    A.blip(90 - Math.min(40, h.fed * 3), 0.18, "sine", 0.1);
  }

  function eat(h) {
    // Rocks: off the list without going through splitAsteroid, because a
    // split is a score and a black hole pays nobody. If this was the last one
    // the wave ends the way it always does — waves.js asks about the list,
    // not about who emptied it.
    for (let i = A.asteroids.length - 1; i >= 0; i--) {
      const a = A.asteroids[i];
      if (a.arrive > 0 || !swallowed(h, a, a.radius)) continue;
      A.asteroids.splice(i, 1);
      feed(h, a.x, a.y, A.hue + a.hueOff);
    }
    for (let i = A.bullets.length - 1; i >= 0; i--) {
      const b = A.bullets[i];
      if (!swallowed(h, b)) continue;
      A.bullets.splice(i, 1);
      h.hum = Math.max(h.hum, 0.4);
    }
    for (let i = A.squids.length - 1; i >= 0; i--) {
      const s = A.squids[i];
      if (!swallowed(h, s, s.radius)) continue;
      A.squids.splice(i, 1);
      if (!A.squids.length && A.stopWarble) A.stopWarble();
      feed(h, s.x, s.y, 320);
    }
    for (const p of A.flyingShips()) {
      if (p.invuln > 0 || !swallowed(h, p)) continue;
      A.killShip(p);
      feed(h, p.x, p.y, 0);
    }
  }

  function reset(mode) {
    if (mode !== "over") A.blackhole = null;
  }

  function update(tick) {
    if (!tick.running || !A.blackhole) return;
    const h = A.blackhole;
    const dt = tick.dt;
    h.age += dt;
    h.x += h.vx * dt;
    h.y += h.vy * dt;
    h.spin += dt * (1.6 + h.hum * 4);
    h.hum = Math.max(0, h.hum - dt * 1.5);

    // Gone once it is out the far side. It does not wrap; a thing that came
    // back around would be a thing that never leaves.
    if (h.x < -MARGIN - 1 || h.x > A.W + MARGIN + 1 || h.y < -MARGIN - 1 || h.y > A.H + MARGIN + 1) {
      if (h.age > 2) { A.blackhole = null; return; }
    }

    haul(h, A.flyingShips(), 1, dt);
    haul(h, A.asteroids, ROCKPULL, dt);
    haul(h, A.squids, 1, dt);
    haul(h, A.bullets, SHOTPULL, dt);
  }

  // After everything has moved and before the wave asks whether the field is
  // empty, so a rock eaten this frame is not also a rock a shot could hit.
  function resolve(tick) {
    if (!tick.running || !A.blackhole) return;
    eat(A.blackhole);
  }

  // Twelve things falling in, forever. Purely a picture: each is a phase on a
  // spiral that tightens as it goes, and the phase is the clock, so nothing is
  // stored per particle and nothing has to be reset.
  const INFALL = 12;
  function infall(h, t, i) {
    const u = ((t * 0.35 + i / INFALL) % 1);       // 0 far out, 1 at the horizon
    const r = HORIZON + (NORETURN * 1.3 - HORIZON) * (1 - u) * (1 - u);
    const a = h.spin + i * 2.4 + u * 7;
    return { x: h.x + Math.cos(a) * r, y: h.y + Math.sin(a) * r, u };
  }

  function draw(tick, g) {
    if (!tick.running || !A.blackhole || A.gl.on) return;
    const h = A.blackhole;
    const t = tick.time;
    const pulse = 0.6 + 0.4 * Math.sin(t * 9);

    g.save();

    // the point of no return, faint and steady: the edge of the argument
    g.globalAlpha = 0.22;
    A.glow(A.neon(A.hue + 200, 62));
    g.lineWidth = 1;
    g.setLineDash([6, 10]);
    g.lineDashOffset = -t * 20;
    g.beginPath();
    g.arc(h.x, h.y, NORETURN, 0, A.TAU);
    g.stroke();
    g.setLineDash([]);

    // the infall
    for (let i = 0; i < INFALL; i++) {
      const q = infall(h, t, i);
      g.globalAlpha = 0.25 + q.u * 0.7;
      g.fillStyle = A.neon(A.hue + 220 + q.u * 60, 70);
      g.beginPath();
      g.arc(q.x, q.y, 1.2 + q.u * 1.4, 0, A.TAU);
      g.fill();
    }

    // the accretion disc: three broken arcs, turning, brightest at the horizon
    for (let k = 0; k < 3; k++) {
      const r = HORIZON + 6 + k * 9;
      const a0 = h.spin * (1 + k * 0.35) + k * 2.1;
      g.globalAlpha = 0.55 - k * 0.14 + h.hum * 0.3;
      A.glow(A.neon(A.hue + 250 + k * 25, 66));
      g.lineWidth = 2.2 - k * 0.5;
      g.beginPath();
      g.arc(h.x, h.y, r, a0, a0 + 2.4);
      g.stroke();
      g.beginPath();
      g.arc(h.x, h.y, r, a0 + Math.PI, a0 + Math.PI + 1.7);
      g.stroke();
    }

    // the body: a hole in the phosphor, which is the one thing on this glass
    // that is allowed to be dark
    g.globalAlpha = 1;
    g.fillStyle = "rgba(7,3,15,0.97)";
    g.beginPath();
    g.arc(h.x, h.y, HORIZON, 0, A.TAU);
    g.fill();

    // the horizon. It never moves relative to the body and never changes
    // size, because a lethal radius that breathes is one nobody can judge.
    g.globalAlpha = 0.5 + pulse * 0.5;
    A.glow(A.neon(A.hue + 190, 72));
    g.lineWidth = 2;
    g.beginPath();
    g.arc(h.x, h.y, HORIZON, 0, A.TAU);
    g.stroke();

    g.restore();
    g.globalAlpha = 1;
  }

  const at = {};

  function draw3d(tick, s) {
    if (!tick.running || !A.blackhole) return;
    const h = A.blackhole;
    const t = tick.time;
    const pulse = 0.6 + 0.4 * Math.sin(t * 9);

    at.rx = at.ry = at.rz = 0; at.dim = 0; at.glow = true; at.sat = 100;

    at.hue = 200; at.light = 62; at.alpha = 0.22; at.width = 1;
    s.ring(h.x, h.y, 0, NORETURN, at);

    // the body, as a stack of rings sinking below the plane — a funnel, which
    // is what a hole looks like from above when you only have lines
    for (let k = 0; k < 6; k++) {
      const f = k / 5;
      at.hue = 230 + k * 8; at.light = 30 + f * 20; at.alpha = 0.25 + f * 0.2; at.width = 1.2;
      s.ring(h.x, h.y, -k * 7, HORIZON * (1 - f * 0.75), at);
    }

    at.hue = 190; at.light = 72; at.alpha = 0.5 + pulse * 0.5; at.width = 2;
    s.ring(h.x, h.y, 0, HORIZON, at);

    // the disc, canted spokes turning above the plane
    for (let k = 0; k < 3; k++) {
      const r = HORIZON + 6 + k * 9;
      const a0 = h.spin * (1 + k * 0.35) + k * 2.1;
      at.hue = 250 + k * 25; at.light = 66; at.alpha = 0.55 - k * 0.14 + h.hum * 0.3; at.width = 2.2 - k * 0.5;
      for (let j = 0; j < 8; j++) {
        const a = a0 + (j / 8) * 2.4, b = a0 + ((j + 1) / 8) * 2.4;
        s.line(h.x + Math.cos(a) * r, h.y + Math.sin(a) * r, 4 + k * 3,
          h.x + Math.cos(b) * r, h.y + Math.sin(b) * r, 4 + k * 3, at);
      }
    }

    // the infall, as short streaks pointing inward
    for (let i = 0; i < INFALL; i++) {
      const q = infall(h, t, i);
      const dx = h.x - q.x, dy = h.y - q.y;
      const d = Math.hypot(dx, dy) || 1;
      at.hue = 220 + q.u * 60; at.light = 70; at.alpha = 0.25 + q.u * 0.7; at.width = 1.2;
      s.line(q.x, q.y, 2, q.x + (dx / d) * 5, q.y + (dy / d) * 5, 2 - q.u * 6, at);
    }
  }

  A.register({
    id: "blackhole",
    order: { update: 75, resolve: 30, draw: 15, guide: 62 },
    reset, update, resolve, draw, draw3d,
    guide: {
      name: "BLACK HOLE",
      group: "field",
      meta: "walking pace",
      tint: "var(--violet)",
      icon: `<svg width="34" height="34" viewBox="0 0 34 34" fill="none"
        stroke="currentColor" stroke-width="1.5">
        <circle cx="17" cy="17" r="5"/>
        <path d="M17 6.5a10.5 10.5 0 0 1 10.5 10.5" opacity="0.8"/>
        <path d="M17 27.5a10.5 10.5 0 0 1-10.5-10.5" opacity="0.8"/>
        <circle cx="17" cy="17" r="15" stroke-dasharray="2.5 4" opacity="0.4"/>
      </svg>`,
      desc: "Crosses the field once, slowly, and pulls on everything — harder the closer you are. The bright ring swallows whatever touches it, for nobody's points. Outside the dashed ring your engine wins. Inside it, only your speed does.",
    },
  });
})(ASTEROIDS);
