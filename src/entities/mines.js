// Mines. They open where you are, take their time about it, and then pull.
//
// A mine is a fuse, not a wall. Flying into one does nothing at all — there is
// no contact fuse and no hull damage anywhere in this file, so you can sit on
// top of one for the whole four seconds if you think that is clever. What
// happens when the fuse runs out is that everything in reach gets dragged at
// the spot the mine was sitting on: rocks, shots, the kraken, the sparks off
// your own thruster and you, harder the closer you are.
//
// Nothing here kills anybody. The field does that, once the mine has finished
// rearranging it — which is the point, and why the reach is drawn on the
// floor from the moment it opens (GR8: you get to see it coming).

(function (A) {
  "use strict";

  const mines = A.mines = [];

  const ARM = 4.4;      // seconds of fuse, and therefore of warning
  const PULL = 1.9;     // seconds the collapse spends dragging
  const REACH = 3.4;    // pull radius, as a multiple of the mine's own
  const ACCEL = 540;    // px/s² at the throat — the ship thrusts at 260
  const GRIP = 26;      // nothing is pulled from closer than this

  /**
   * Where a mine wants to be: near somebody, never quite on top of them. It
   * opens where you are and goes off where you were, so the fuse is not a
   * countdown to being hit — it is four seconds of being asked whether you
   * still want to be standing here.
   */
  A.mineSpot = function mineSpot() {
    const ships = A.flyingShips();
    if (!ships.length) return { x: A.rand(0, A.W), y: A.rand(0, A.H) };
    const p = ships[Math.floor(Math.random() * ships.length)];
    const dir = A.rand(0, A.TAU);
    const d = A.rand(70, 260);
    return { x: p.x + Math.cos(dir) * d, y: p.y + Math.sin(dir) * d };
  };

  A.layMine = function layMine(x, y, fuse) {
    const max = A.rand(78, 116);
    const m = {
      // the field is a torus, and a mine laid off the edge is really over here
      x: ((x % A.W) + A.W) % A.W,
      y: ((y % A.H) + A.H) % A.H,
      r: 6,
      max,
      reach: max * REACH,
      fuse: fuse || ARM,
      age: 0,
      pulling: 0,
      hueOff: A.rand(-25, 25),
    };
    mines.push(m);
    A.blip(230, 0.2, "sine", 0.06);
    return m;
  };

  function collapse(m) {
    m.pulling = PULL;
    A.blip(74, 0.6, "sawtooth", 0.15);
    A.screenFlash(A.hue + 290 + m.hueOff, 0.26);
    A.shakeBy(15);
    A.aberrate(0.7);
  }

  // Gravity, near enough: the same acceleration for a pebble and a kraken,
  // falling off with the square of the distance so the edge of the reach is a
  // suggestion and the middle of it is not.
  function drag(m, dt) {
    const pull = (o) => {
      const dx = m.x - o.x, dy = m.y - o.y;
      const d = Math.hypot(dx, dy);
      if (d > m.reach || d === 0) return;
      const near = Math.max(d, GRIP);
      const f = 1 - near / m.reach;
      const a = (ACCEL * f * f * dt) / near;
      o.vx += dx * a;
      o.vy += dy * a;
    };
    for (const a of A.asteroids) pull(a);
    for (const p of A.flyingShips()) pull(p);
    for (const b of A.bullets) pull(b);
    for (const s of A.squids) pull(s);
    for (const d of A.debris) pull(d);
  }

  function reset() {
    mines.length = 0;
  }

  function update(tick) {
    if (!tick.running) return;
    for (let i = mines.length - 1; i >= 0; i--) {
      const m = mines[i];
      m.age += tick.dt;

      if (m.pulling > 0) {
        m.pulling -= tick.dt;
        m.r = Math.max(0, m.r - (m.max / (PULL * 0.5)) * tick.dt);
        drag(m, tick.dt);
        if (m.pulling <= 0) mines.splice(i, 1);
        continue;
      }

      // the fuse only ever grows, and only time ends it
      m.r = 6 + (m.max - 6) * Math.min(1, m.age / m.fuse);
      if (m.age >= m.fuse) collapse(m);
    }
  }

  function drawFuse(m, g, c, tick) {
    const t = Math.min(1, m.age / m.fuse);

    // the ground it is going to claim, on the floor from the first frame
    g.save();
    g.globalAlpha = 0.14 + t * 0.22;
    A.glow(c(58));
    g.lineWidth = 1;
    g.setLineDash([4, 13]);
    g.lineDashOffset = -tick.time * 26;
    g.beginPath();
    g.arc(m.x, m.y, m.reach, 0, A.TAU);
    g.stroke();
    g.restore();

    g.save();
    g.translate(m.x, m.y);

    // the shell, breathing harder the less fuse is left
    const wob = 1 + Math.sin(tick.time * (3 + t * 13)) * 0.04 * (0.4 + t);
    A.glow(c(62));
    g.lineWidth = 1.4 + t * 1.4;
    g.globalAlpha = 0.45 + t * 0.55;
    g.beginPath();
    g.arc(0, 0, m.r * wob, 0, A.TAU);
    g.stroke();

    // one hand, going round exactly once. That is the whole clock.
    A.glow(c(78));
    g.lineWidth = 2.4;
    g.globalAlpha = 1;
    g.beginPath();
    g.arc(0, 0, m.r * 0.62, -Math.PI / 2, -Math.PI / 2 + t * A.TAU);
    g.stroke();

    g.fillStyle = c(70, 0.09 + t * 0.15);
    g.beginPath();
    g.arc(0, 0, 5 + t * 5, 0, A.TAU);
    g.fill();
    g.restore();
  }

  function drawCollapse(m, g, c) {
    const f = Math.max(0, m.pulling / PULL);
    g.save();
    g.translate(m.x, m.y);

    // rings running the wrong way — inward is the one thing nothing else on
    // this screen does, so it reads before anybody has time to think
    A.glow(c(72));
    for (let i = 0; i < 3; i++) {
      const p = (f + i / 3) % 1;
      g.globalAlpha = p * 0.75;
      g.lineWidth = 1 + (1 - p) * 3;
      g.beginPath();
      g.arc(0, 0, m.reach * p, 0, A.TAU);
      g.stroke();
    }

    // and the spokes going down the drain with everything else
    g.globalAlpha = f;
    g.lineWidth = 1.6;
    for (let i = 0; i < 12; i++) {
      const a = (i / 12) * A.TAU + (1 - f) * 2.4;
      const from = m.reach * (0.25 + f * 0.5);
      const to = Math.max(0, from - 40 - (1 - f) * 70);
      A.glow(c(58 + i * 2));
      g.beginPath();
      g.moveTo(Math.cos(a) * from, Math.sin(a) * from);
      g.lineTo(Math.cos(a) * to, Math.sin(a) * to);
      g.stroke();
    }

    const throat = Math.max(1, m.r + 14);
    const core = g.createRadialGradient(0, 0, 0, 0, 0, throat);
    core.addColorStop(0, "rgba(255,255,255," + 0.15 * f + ")");
    core.addColorStop(0.5, c(58, 0.11 * f));
    core.addColorStop(1, "rgba(0,0,0,0)");
    g.globalAlpha = 1;
    g.fillStyle = core;
    g.beginPath();
    g.arc(0, 0, throat, 0, A.TAU);
    g.fill();
    g.restore();
  }

  // The same two states with height on them. The shell is a sphere rather than
  // a circle, and the collapse is a hole rather than a pattern of shrinking
  // rings: every ring and every spoke lies on one funnel, so the last second of
  // a mine goes somewhere instead of merely getting smaller.
  //
  // The reach ring is the exception and stays exactly where it was, flat on the
  // floor at z = 0. It is the promise that you can see what is coming (GR8),
  // and a promise you have to read through perspective is a worse promise.

  const THROAT = 120;      // px the drain drops below the plane at its middle
  const shell = () => A.mesh.get("mine:shell", () => A.mesh.ball(0));

  /** How far under the plane the funnel wall has fallen, at radius r. */
  const wall = (m, r) => -(1 - r / m.reach) * THROAT;

  const at = {};

  function drawFuse3d(m, s, tick) {
    const t = Math.min(1, m.age / m.fuse);
    at.hue = 290 + m.hueOff;
    at.rx = at.ry = at.rz = 0;

    // A fuse is light, not matter, and this is the file where that matters
    // most: there is no hull here and no contact fuse, so a shell that covered
    // would be a two-hundred-pixel hole in the field, opened next to a ship,
    // hiding the rocks that can actually kill them. The mark on the floor goes
    // the same way — it is the promise you can see what is coming, and a
    // promise that dims the rock it crosses is a worse promise. Both add and
    // neither writes depth.
    at.dim = 0;
    at.glow = true;

    at.light = 58;
    at.alpha = 0.14 + t * 0.22;
    at.width = 1;
    s.ring(m.x, m.y, 0, m.reach, at);

    // the equator stays on the plane, so the circle the fuse always drew is
    // still the circle you are looking at
    const wob = 1 + Math.sin(tick.time * (3 + t * 13)) * 0.04 * (0.4 + t);
    at.x = m.x; at.y = m.y; at.z = 0;
    at.rx = m.age * 0.31; at.rz = m.age * 0.52;
    at.s = m.r * wob;
    at.dim = 0.06;
    at.light = 62;
    at.alpha = 0.45 + t * 0.55;
    at.width = 1.4 + t * 1.4;
    s.model(shell(), at);

    // The hand rides on top of the dome, because a clock buried in the middle
    // of one is a clock nobody reads. It still leaves at -PI/2 and goes round
    // once, which is the whole clock.
    const lift = m.r * wob * 0.9;
    const hand = -Math.PI / 2 + t * A.TAU;
    at.z = lift;
    at.rx = at.rz = 0;
    at.s = 5 + t * 5;
    at.light = 70;
    at.alpha = 0.35 + t * 0.5;
    at.width = 1;
    at.dim = 0.06;
    at.glow = true;
    s.model(shell(), at);

    at.light = 78;
    at.alpha = 1;
    at.width = 2.4;
    s.line(m.x, m.y, lift,
      m.x + Math.cos(hand) * m.r * 0.62, m.y + Math.sin(hand) * m.r * 0.62, lift, at);
  }

  function drawCollapse3d(m, s) {
    const f = Math.max(0, m.pulling / PULL);
    at.hue = 290 + m.hueOff;
    at.rx = at.ry = at.rz = 0;
    at.dim = 0.06;
    at.glow = true;

    at.light = 72;
    for (let i = 0; i < 3; i++) {
      const p = (f + i / 3) % 1;
      at.alpha = p * 0.75;
      at.width = 1 + (1 - p) * 3;
      s.ring(m.x, m.y, wall(m, m.reach * p), m.reach * p, at);
    }

    at.alpha = f;
    at.width = 1.6;
    for (let i = 0; i < 12; i++) {
      const a = (i / 12) * A.TAU + (1 - f) * 2.4;
      const from = m.reach * (0.25 + f * 0.5);
      const to = Math.max(0, from - 40 - (1 - f) * 70);
      at.light = 58 + i * 2;
      s.line(m.x + Math.cos(a) * from, m.y + Math.sin(a) * from, wall(m, from),
        m.x + Math.cos(a) * to, m.y + Math.sin(a) * to, wall(m, to), at);
    }

    // the light at the bottom of it, where the flat version had a gradient
    at.x = m.x; at.y = m.y; at.z = -THROAT;
    at.s = Math.max(1, m.r + 14);
    at.light = 80;
    at.alpha = 0.5 * f;
    at.width = 1;
    s.model(shell(), at);
  }

  function draw3d(tick, s) {
    for (const m of mines) {
      if (m.pulling > 0) drawCollapse3d(m, s);
      else drawFuse3d(m, s, tick);
    }
  }

  function draw(tick, g) {
    if (A.gl.on) return;
    for (const m of mines) {
      const c = (l, a) => A.neon(A.hue + 290 + m.hueOff, l, a === undefined ? 1 : a);
      if (m.pulling > 0) drawCollapse(m, g, c);
      else drawFuse(m, g, c, tick);
    }
  }

  A.register({
    id: "mines",
    order: { update: 45, draw: 35, guide: 45 },
    reset, update, draw, draw3d,
    guide: {
      name: "MINE",
      group: "field",
      meta: "timed &middot; no contact fuse",
      tint: "var(--violet)",
      icon: `<svg width="34" height="34" viewBox="0 0 34 34" fill="none" stroke="currentColor" stroke-width="1.3" aria-hidden="true">
        <circle cx="17" cy="17" r="3.2"/>
        <circle cx="17" cy="17" r="13.5" stroke-dasharray="2 4" opacity="0.55"/>
        <path d="M17 5.4v4.4 M15.1 8 L17 9.9 L18.9 8" stroke-linecap="round" stroke-linejoin="round"/>
        <path d="M17 28.6v-4.4 M15.1 26 L17 24.1 L18.9 26" stroke-linecap="round" stroke-linejoin="round"/>
        <path d="M5.4 17h4.4 M8 15.1 L9.9 17 L8 18.9" stroke-linecap="round" stroke-linejoin="round"/>
        <path d="M28.6 17h-4.4 M26 15.1 L24.1 17 L26 18.9" stroke-linecap="round" stroke-linejoin="round"/>
      </svg>`,
      desc: "No contact fuse, so flying through one is free. When its timer comes round it drags the ring inward &mdash; and what it drags into you can kill.",
    },
  });
})(ASTEROIDS);
