// Rocks. The oldest thing in the game and still the centre of it: shoot one
// and it splits into smaller, quicker pieces.

(function (A) {
  "use strict";

  const asteroids = A.asteroids = [];

  /** size 3 = large, 2 = medium, 1 = small */
  const RADIUS = { 3: 42, 2: 24, 1: 13 };
  const POINTS = { 3: 20, 2: 50, 1: 100 };
  const ATTRACT_ROCKS = 5;
  const REST = 0.92;             // rock-on-rock bounce: brakes only a little

  A.makeAsteroid = function makeAsteroid(x, y, size) {
    const radius = RADIUS[size];
    const speed = A.rand(0.75, 1.5) * A.tune().rockSpeed + (3 - size) * 25;
    const dir = A.rand(0, A.TAU);
    const points = [];
    const n = 9 + Math.floor(A.rand(0, 4));
    for (let i = 0; i < n; i++) points.push(A.rand(0.72, 1.18));
    return {
      x, y,
      vx: Math.cos(dir) * speed,
      vy: Math.sin(dir) * speed,
      angle: A.rand(0, A.TAU),
      spin: A.rand(-0.8, 0.8),
      radius, size, points,
      hueOff: A.rand(0, 360),
      pulse: A.rand(0, A.TAU),
    };
  };

  /** A fresh wave, kept clear of the middle where the ships come in. */
  A.spawnField = function spawnField() {
    asteroids.length = 0;
    const count = A.tune().rocks;
    for (let i = 0; i < count; i++) {
      let x, y;
      do {
        x = A.rand(0, A.W);
        y = A.rand(0, A.H);
      } while (Math.hypot(x - A.W / 2, y - A.H / 2) < 180);
      asteroids.push(A.makeAsteroid(x, y, 3));
    }
  };

  A.splitAsteroid = function splitAsteroid(a, idx, owner) {
    asteroids.splice(idx, 1);
    const pts = POINTS[a.size];
    if (owner) owner.score += pts;
    A.boom(a.size);
    const h = A.hue + a.hueOff;
    A.kaboom(a.x, a.y, 8 + a.size * 4, a.radius * 0.5, h);
    A.shockwave(a.x, a.y, h, 60 + a.radius * 2, 300);
    A.popup(a.x, a.y, "+" + pts, h);
    A.shakeBy(3 + a.size * 1.5);
    if (a.size > 1) {
      asteroids.push(A.makeAsteroid(a.x, a.y, a.size - 1));
      asteroids.push(A.makeAsteroid(a.x, a.y, a.size - 1));
    }
  };

  /** Vaporised rather than broken up — the atom bomb leaves no pieces. */
  A.vaporiseAsteroid = function vaporiseAsteroid(idx, owner) {
    const a = asteroids[idx];
    if (owner) owner.score += POINTS[a.size];
    asteroids.splice(idx, 1);
    A.kaboom(a.x, a.y, 10 + a.size * 4, a.radius * 0.6, 40, 1.5);
    A.boom(a.size);
    return a;
  };

  function reset(mode) {
    if (mode === "over") return;
    if (mode === "attract") {
      // drifting rocks behind the start screen
      asteroids.length = 0;
      for (let i = 0; i < ATTRACT_ROCKS; i++) {
        asteroids.push(A.makeAsteroid(A.rand(0, A.W), A.rand(0, A.H), 3));
      }
      return;
    }
    A.spawnField();
  }

  function update(tick) {
    // on the menu they drift, slowly, and nothing bumps into anything
    const dt = tick.running ? tick.dt : tick.raw * 0.3;
    for (const a of asteroids) {
      a.x += a.vx * dt;
      a.y += a.vy * dt;
      a.angle += a.spin * dt;
      a.pulse += (tick.running ? tick.dt * 3 : tick.raw * 2);
      a.clack = Math.max(0, (a.clack || 0) - dt);
      A.wrap(a);
    }
    if (tick.running) collideRocks();
  }

  // Rock against rock: elastic bounce with mass by area, so a pebble glances
  // off a boulder and the boulder barely notices. They keep nearly all their
  // speed — the collision redirects them rather than stopping them.
  function collideRocks() {
    let clacks = 0;
    for (let i = 0; i < asteroids.length; i++) {
      const a = asteroids[i];
      for (let j = i + 1; j < asteroids.length; j++) {
        const b = asteroids[j];
        const dx = b.x - a.x, dy = b.y - a.y;
        const min = a.radius + b.radius;
        if (Math.abs(dx) > min || Math.abs(dy) > min) continue;   // cheap reject
        const d = Math.hypot(dx, dy);
        if (d === 0 || d >= min) continue;
        const nx = dx / d, ny = dy / d;
        const ma = a.radius * a.radius, mb = b.radius * b.radius;
        const total = ma + mb;

        // push them apart so they don't sink into each other
        const overlap = min - d;
        a.x -= nx * overlap * (mb / total);
        a.y -= ny * overlap * (mb / total);
        b.x += nx * overlap * (ma / total);
        b.y += ny * overlap * (ma / total);

        const vn = (b.vx - a.vx) * nx + (b.vy - a.vy) * ny;
        if (vn >= 0) continue;                 // already separating
        const imp = (-(1 + REST) * vn) / (1 / ma + 1 / mb);
        a.vx -= (imp / ma) * nx;
        a.vy -= (imp / ma) * ny;
        b.vx += (imp / mb) * nx;
        b.vy += (imp / mb) * ny;
        // glancing hits set them tumbling
        a.spin += A.rand(-0.6, 0.6);
        b.spin += A.rand(-0.6, 0.6);

        if (-vn > 45 && a.clack <= 0 && b.clack <= 0 && clacks < 3) {
          clacks++;
          a.clack = b.clack = 0.12;
          const mx = a.x + nx * a.radius, my = a.y + ny * a.radius;
          A.kaboom(mx, my, 3, 3, A.hue + 40);
          A.blip(90 + Math.random() * 50, 0.07, "triangle", 0.05);
        }
      }
    }
  }

  function resolve() {
    // bullet vs rock
    outer:
    for (let i = asteroids.length - 1; i >= 0; i--) {
      const a = asteroids[i];
      for (let j = A.bullets.length - 1; j >= 0; j--) {
        const b = A.bullets[j];
        if (Math.hypot(a.x - b.x, a.y - b.y) < a.radius) {
          A.bullets.splice(j, 1);
          A.splitAsteroid(a, i, b.owner);
          continue outer;
        }
      }
    }

    // ship vs rock — the rock on your own line is the one rock that cannot have
    // you: the tether holds it at arm's length and shoves it off instead
    for (const p of A.flyingShips()) {
      if (p.invuln > 0) continue;
      const onLine = p.hook && p.hook.state === "attached" ? p.hook.target : null;
      for (const a of asteroids) {
        if (a === onLine) continue;
        if (Math.hypot(a.x - p.x, a.y - p.y) < a.radius + p.radius * 0.7) {
          A.killShip(p);
          break;
        }
      }
    }
  }

  // Five boulders, built once. A rock's variant and its tumble both come off
  // hueOff and angle, which it already had — a shape this old should not need
  // new state to stand up in.
  const SHAPES = 5;
  const shapeOf = (a) => A.mesh.get("rock:" + (Math.floor(a.hueOff) % SHAPES),
    () => A.mesh.rock(Math.floor(a.hueOff) % SHAPES + 1));

  const at = {};

  function draw3d(tick, s) {
    for (const a of asteroids) {
      at.x = a.x; at.y = a.y; at.z = 0;
      // the equator stays on the plane, because the equator is the hitbox
      at.rz = a.angle;
      at.rx = a.angle * 0.71 + a.hueOff;
      at.ry = a.angle * 0.43;
      at.s = a.radius;
      at.hue = a.hueOff;
      at.light = 60 + Math.sin(a.pulse) * 8;
      at.width = 1.6;
      s.model(shapeOf(a), at);
    }
  }

  function draw(tick, g) {
    if (A.gl.on) return;
    for (const a of asteroids) {
      const c = A.neon(A.hue + a.hueOff, 60 + Math.sin(a.pulse) * 8);
      g.save();
      g.translate(a.x, a.y);
      g.rotate(a.angle);
      A.glow(c);
      g.lineWidth = 1.6;
      g.beginPath();
      const n = a.points.length;
      for (let i = 0; i <= n; i++) {
        const r = a.radius * a.points[i % n];
        const th = (i / n) * A.TAU;
        const x = Math.cos(th) * r;
        const y = Math.sin(th) * r;
        if (i === 0) g.moveTo(x, y);
        else g.lineTo(x, y);
      }
      g.stroke();
      g.restore();
    }
  }

  A.register({
    id: "asteroids",
    order: { update: 30, resolve: 10, draw: 40, guide: 10 },
    reset, update, resolve, draw, draw3d,
    guide: {
      name: "ASTEROID",
      group: "field",
      meta: "20 / 50 / 100",
      tint: "var(--cyan)",
      icon: `<svg width="34" height="34" viewBox="0 0 34 34" fill="none" stroke="currentColor" stroke-width="1.3" aria-hidden="true">
        <path d="M17 4 L26 8 L30 17 L26 27 L16 30 L7 25 L4 15 L9 7 Z" stroke-linejoin="round"/>
      </svg>`,
      desc: "Shoot one and it breaks into smaller, quicker pieces &mdash; and the smallest are worth the most.",
    },
  });
})(ASTEROIDS);
