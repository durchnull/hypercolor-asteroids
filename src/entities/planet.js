// A planet, far too big for the screen, creeping in from one edge. Rocks and
// krakens bounce off it, shots burn up on it, and it will happily flatten you.

(function (A) {
  "use strict";

  A.planet = null;

  let planetTimer = 0;

  A.spawnPlanet = function spawnPlanet() {
    const R = Math.max(A.W, A.H) * 1.15;
    const edge = Math.floor(A.rand(0, 4));
    const sp = A.rand(13, 19);
    let x, y, vx, vy;
    if (edge === 0) { x = -R - 60; y = A.rand(0, A.H); vx = sp; vy = A.rand(-3, 3); }
    else if (edge === 1) { x = A.W + R + 60; y = A.rand(0, A.H); vx = -sp; vy = A.rand(-3, 3); }
    else if (edge === 2) { x = A.rand(0, A.W); y = -R - 60; vx = A.rand(-3, 3); vy = sp; }
    else { x = A.rand(0, A.W); y = A.H + R + 60; vx = A.rand(-3, 3); vy = -sp; }
    const craters = [];
    for (let i = 0; i < 16; i++) {
      craters.push({ a: A.rand(0, A.TAU), d: A.rand(0.15, 0.96) * R, r: A.rand(10, 44) });
    }
    A.planet = { x, y, r: R, vx, vy, dir: 1, tIn: A.rand(15, 20), craters, hueOff: A.rand(0, 360) };
  };

  function reset(mode) {
    A.planet = null;
    if (mode === "play") planetTimer = A.rand(35, 60);
  }

  function update(tick) {
    if (!tick.running) return;
    const dt = tick.dt;

    // it creeps in, dwells, then retreats
    if (A.planet) {
      const p = A.planet;
      p.x += p.vx * p.dir * dt;
      p.y += p.vy * p.dir * dt;
      if (p.dir === 1) {
        p.tIn -= dt;
        if (p.tIn <= 0) p.dir = -1;
      } else {
        const nx = Math.max(0, Math.min(A.W, p.x));
        const ny = Math.max(0, Math.min(A.H, p.y));
        if (Math.hypot(p.x - nx, p.y - ny) > p.r + 80) {
          A.planet = null;
          const T = A.tune();
          planetTimer = A.rand(T.planetGap, T.planetGap + 25);
        }
      }
    } else {
      planetTimer -= dt;
      if (planetTimer <= 0) A.spawnPlanet();
    }

    if (A.planet) collide(A.planet);
  }

  // bullets burn up, rocks and kraken bounce, the ship dies
  function collide(p) {
    for (let i = A.bullets.length - 1; i >= 0; i--) {
      const b = A.bullets[i];
      if (Math.hypot(b.x - p.x, b.y - p.y) < p.r + b.radius) {
        A.kaboom(b.x, b.y, 4, 4, b.hue);
        A.bullets.splice(i, 1);
      }
    }
    for (const o of A.asteroids.concat(A.squids)) {
      const dx = o.x - p.x, dy = o.y - p.y;
      const d = Math.hypot(dx, dy);
      if (d >= p.r + o.radius) continue;
      const nx = dx / (d || 1), ny = dy / (d || 1);
      const dot = o.vx * nx + o.vy * ny;
      if (dot < 0) {
        o.vx -= 2 * dot * nx;
        o.vy -= 2 * dot * ny;
        if (dot < -20) {
          A.blip(70, 0.08, "triangle", 0.05);
          A.kaboom(o.x, o.y, 5, 6, A.hue + 120);
          A.shakeBy(4);
        }
      }
      o.x = p.x + nx * (p.r + o.radius + 1);
      o.y = p.y + ny * (p.r + o.radius + 1);
    }
    for (const q of A.flyingShips()) {
      if (q.invuln > 0) continue;
      if (Math.hypot(q.x - p.x, q.y - p.y) < p.r + q.radius * 0.8) A.killShip(q);
    }
  }

  // The one body in the field the camera has an opinion about. A true ball of
  // this radius — wider than the screen — would push its near cap straight
  // through the lens, so the solid is squashed in z until it fits under it.
  // What is not squashed is the limb at z = 0, and the limb is the circle every
  // collision above has always used.
  const dome = () => Math.min(300, Math.min(A.W, A.H) * 0.2);

  /** Where that surface stands, at distance d out from the middle. */
  function lift(p, d) {
    const k = Math.min(1, d / p.r);
    return dome() * Math.sqrt(1 - k * k);
  }

  const body = () => A.mesh.get("planet:body", () => A.mesh.ball(2));
  // finer than the shared hoop, because at this radius a fifty-six-sided ring
  // reads as a polygon and this particular ring is the thing that kills you
  const limb = () => A.mesh.get("planet:limb", () => A.mesh.hoop(96));

  const at = {};

  function draw3d(tick, s) {
    if (!tick.running || !A.planet) return;
    const p = A.planet;

    at.x = p.x; at.y = p.y; at.z = 0;
    at.rx = at.ry = 0;
    at.rz = tick.time * 0.06;         // the slow turn the flat meridians had
    at.sx = at.sy = p.r; at.sz = dome();
    at.hue = p.hueOff; at.light = 62;
    at.alpha = 1; at.glow = false;
    // a hull this wide catches too much of the key light to be lit like a rock,
    // and it is here to hide what is behind it rather than to be looked at
    at.dim = 0.1;
    at.width = 0.9;                   // four hundred edges, most of them off screen
    s.model(body(), at);

    at.sz = 1;
    at.width = 2.4;
    s.model(limb(), at);

    // contour bands, climbing the dome as they close on the middle — flat
    // circles in the flat game because a flat game had nowhere else to put them
    at.width = 1.3;
    at.light = 58;
    for (let i = 1; i <= 6; i++) {
      const rr = p.r * (1 - i * 0.055);
      at.hue = p.hueOff + i * 30;
      at.alpha = 0.42 - i * 0.05;
      s.ring(p.x, p.y, lift(p, rr), rr, at);
    }

    at.width = 1.1;
    at.hue = p.hueOff + 60;
    at.light = 55;
    at.alpha = 0.5;
    for (const c of p.craters) {
      const cx = p.x + Math.cos(c.a) * c.d;
      const cy = p.y + Math.sin(c.a) * c.d;
      if (cx < -60 || cx > A.W + 60 || cy < -60 || cy > A.H + 60) continue;
      s.ring(cx, cy, lift(p, c.d), c.r, at);
    }
  }

  function draw(tick, g) {
    if (!tick.running || !A.planet) return;
    if (A.gl.on) return;
    const p = A.planet;
    const t = tick.time;
    g.save();
    // dark body so it occludes the starfield behind it
    g.fillStyle = "rgba(7,3,15,0.93)";
    g.beginPath();
    g.arc(p.x, p.y, p.r, 0, A.TAU);
    g.fill();
    A.glow(A.neon(A.hue + p.hueOff, 62));
    g.lineWidth = 2.4;
    g.stroke();

    // contour bands hugging the limb, cycling through the spectrum
    for (let i = 1; i <= 6; i++) {
      const rr = p.r * (1 - i * 0.055);
      g.strokeStyle = A.neon(A.hue + p.hueOff + i * 30, 58, 0.42 - i * 0.05);
      g.lineWidth = 1.3;
      g.beginPath();
      g.arc(p.x, p.y, rr, 0, A.TAU);
      g.stroke();
    }
    // meridians crossing the limb, slowly rotating
    g.lineWidth = 1.1;
    for (let i = 0; i < 24; i++) {
      const ang = (i / 24) * A.TAU + t * 0.06;
      g.strokeStyle = A.neon(A.hue + p.hueOff + i * 15, 55, 0.3);
      g.beginPath();
      g.moveTo(p.x + Math.cos(ang) * p.r * 0.62, p.y + Math.sin(ang) * p.r * 0.62);
      g.lineTo(p.x + Math.cos(ang) * p.r, p.y + Math.sin(ang) * p.r);
      g.stroke();
    }
    for (const c of p.craters) {
      const cx = p.x + Math.cos(c.a) * c.d;
      const cy = p.y + Math.sin(c.a) * c.d;
      if (cx < -60 || cx > A.W + 60 || cy < -60 || cy > A.H + 60) continue;
      g.strokeStyle = A.neon(A.hue + p.hueOff + 60, 55, 0.5);
      g.beginPath();
      g.arc(cx, cy, c.r, 0, A.TAU);
      g.stroke();
    }
    g.restore();
  }

  A.register({
    id: "planet",
    order: { update: 80, draw: 10, guide: 60 },
    reset, update, draw, draw3d,
    guide: {
      name: "PLANET",
      group: "field",
      tint: "var(--lime)",
      icon: `<svg width="34" height="34" viewBox="0 0 34 34" fill="none" stroke="currentColor" stroke-width="1.3" aria-hidden="true">
        <circle cx="26" cy="27" r="20"/>
        <circle cx="16" cy="22" r="3.5" opacity="0.6"/>
        <circle cx="26" cy="15" r="2.2" opacity="0.6"/>
        <circle cx="12" cy="31" r="2" opacity="0.6"/>
      </svg>`,
      desc: "Too big for the screen. Rocks bounce off it, shots burn up on it, and it will happily flatten you.",
    },
  });
})(ASTEROIDS);
