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

  function draw(tick, g) {
    for (const m of mines) {
      const c = (l, a) => A.neon(A.hue + 290 + m.hueOff, l, a === undefined ? 1 : a);
      if (m.pulling > 0) drawCollapse(m, g, c);
      else drawFuse(m, g, c, tick);
    }
  }

  A.register({
    id: "mines",
    order: { update: 45, draw: 35, guide: 45 },
    reset, update, draw,
    guide: {
      name: "MINE",
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
      desc: `Opens quietly, grows, and only time sets it off &mdash; there is no
        contact fuse, so flying through one costs nothing. When the hand comes
        round it drags everything inside the dotted ring toward the middle,
        harder the closer you are. It cannot hurt you. What it drags into you
        can.`,
    },
  });
})(ASTEROIDS);
