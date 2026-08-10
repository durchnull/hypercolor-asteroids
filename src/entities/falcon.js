// A passing smuggler. Shows up a few seconds after a kraken arrives, fires one
// enormous laser at whichever one is closest to full health, and keeps flying.

(function (A) {
  "use strict";

  A.falcon = null;

  const IDLE = 999;         // "not coming" — anything above 900 counts as unarmed
  const LASER_HURT = 2;

  let falconTimer = IDLE;
  let krakensSeen = 0;

  A.spawnFalcon = function spawnFalcon() {
    const fromLeft = Math.random() < 0.5;
    A.falcon = {
      x: fromLeft ? -60 : A.W + 60,
      y: 0,
      baseY: A.rand(A.H * 0.2, A.H * 0.8),
      vx: (fromLeft ? 1 : -1) * A.rand(170, 210),
      vy: 0,
      t: 0,
      fired: false,
      laserT: 0,
      beamX: 0, beamY: 0,
    };
    A.falcon.y = A.falcon.baseY;
  };

  function reset() {
    A.falcon = null;
    falconTimer = IDLE;
    krakensSeen = 0;
  }

  function update(tick) {
    if (!tick.running) return;
    const dt = tick.dt;

    // a fresh kraken on the field is what calls the smuggler in
    if (A.squids.length > krakensSeen && falconTimer > 900) falconTimer = A.rand(6, 14);
    krakensSeen = A.squids.length;

    if (!A.falcon) {
      if (!A.squids.length) return;
      falconTimer -= dt;
      if (falconTimer <= 0) { A.spawnFalcon(); falconTimer = IDLE; }
      return;
    }

    const f = A.falcon;
    f.t += dt;
    f.x += f.vx * dt;
    f.y = f.baseY + Math.sin(f.t * 1.6) * 14;
    f.vy = Math.cos(f.t * 1.6) * 22;
    f.laserT = Math.max(0, f.laserT - dt);
    const progress = f.vx > 0 ? f.x : A.W - f.x;
    // it picks off whichever kraken is closest to full health
    const mark = A.squids.slice().sort((a, b) => b.hp - a.hp)[0];
    if (!f.fired && mark && progress > A.W * 0.3) {
      f.fired = true;
      f.beamX = mark.x;
      f.beamY = mark.y;
      f.laserT = 0.35;
      A.blaster(true);
      A.screenFlash(A.hue + 60, 0.3);
      A.damageSquid(mark, LASER_HURT);
    }
    if ((f.vx > 0 && f.x > A.W + 80) || (f.vx < 0 && f.x < -80)) A.falcon = null;
  }

  // The hull, built once. The flat version is this same ship seen from straight
  // overhead — a disc, two forks, a pod on the rim — so the solid keeps every
  // radius and every reach it already had and only gains a thickness.
  const disc = () => A.mesh.get("falcon:disc", () => A.mesh.lathe(
    [[0, -2.5], [9, -1.7], [13, 0], [9, 1.7], [0, 2.5]], 14));
  const mandible = () => A.mesh.get("falcon:mandible", () => A.mesh.box(9, 2.5, 1.9));
  const pod = () => A.mesh.get("falcon:pod", () => A.mesh.ball(0));

  const at = {};

  function draw3d(tick, s) {
    if (!tick.running || !A.falcon) return;
    const f = A.falcon;
    const t = tick.time;
    const rot = Math.atan2(f.vy, f.vx);
    const cr = Math.cos(rot), sr = Math.sin(rot);
    // every part is bolted to a hull that flies nose first, so each one is
    // placed by the same turn ctx.rotate was doing for the flat draw
    const px = (lx, ly) => f.x + lx * cr - ly * sr;
    const py = (lx, ly) => f.y + lx * sr + ly * cr;

    if (f.laserT > 0) {
      // the beam rides a little above the plane, which is what makes it read as
      // something passing over the field rather than lying on it
      const a = Math.min(1, f.laserT / 0.2);
      at.glow = true;
      for (let i = 0; i < 4; i++) {
        at.hue = A.hue * 5 + i * 90;      // the flat code names an absolute hue
        at.light = 62; at.alpha = a; at.width = 11 - i * 2.6;
        s.line(f.x, f.y, 5,
          f.beamX + Math.sin(t * 40 + i) * 3, f.beamY + Math.cos(t * 40 + i) * 3, 1, at);
      }
      at.hue = 0; at.light = 100; at.width = 1.8;
      s.line(f.x, f.y, 5, f.beamX, f.beamY, 1, at);
    }

    at.x = f.x; at.y = f.y; at.z = 0;
    at.rx = 0; at.ry = 0; at.rz = rot;
    at.s = 1;
    at.hue = 200; at.light = 78;
    at.alpha = 1; at.width = 1.5; at.dim = 0.14; at.glow = false;
    s.model(disc(), at);

    for (let side = -1; side <= 1; side += 2) {
      at.x = px(17, side * 6.5); at.y = py(17, side * 6.5);
      s.model(mandible(), at);
    }

    at.x = px(5, -12); at.y = py(5, -12); at.z = 2.2;
    at.s = 3.2;
    s.model(pod(), at);

    // the dish reads as a hoop on the roof; a second ball up there would only
    // be another blob at the size this ship actually is on screen
    at.s = 1;
    s.ring(px(-2, 0), py(-2, 0), 2.8, 4.5, at);

    at.hue = 20; at.light = 62; at.width = 3.2; at.glow = true;
    s.line(px(-13.5, -6), py(-13.5, -6), 0, px(-13.5, 6), py(-13.5, 6), 0, at);
  }

  function draw(tick, g) {
    if (!tick.running || !A.falcon) return;
    if (A.gl.on) return;
    const f = A.falcon;
    const t = tick.time;
    if (f.laserT > 0) {
      g.save();
      g.globalAlpha = Math.min(1, f.laserT / 0.2);
      for (let i = 0; i < 4; i++) {
        A.glow(A.neon(A.hue * 6 + i * 90, 62));
        g.lineWidth = 11 - i * 2.6;
        g.beginPath();
        g.moveTo(f.x, f.y);
        g.lineTo(f.beamX + Math.sin(t * 40 + i) * 3, f.beamY + Math.cos(t * 40 + i) * 3);
        g.stroke();
      }
      g.strokeStyle = "#ffffff";
      g.lineWidth = 1.8;
      g.beginPath();
      g.moveTo(f.x, f.y);
      g.lineTo(f.beamX, f.beamY);
      g.stroke();
      g.restore();
    }
    g.save();
    g.translate(f.x, f.y);
    g.rotate(Math.atan2(f.vy, f.vx));
    A.glow(A.neon(A.hue + 200, 78));
    g.lineWidth = 1.4;
    g.beginPath();
    g.arc(0, 0, 13, 0, A.TAU);
    g.stroke();
    g.beginPath();
    g.moveTo(8, -9); g.lineTo(26, -9); g.lineTo(26, -4); g.lineTo(11, -4);
    g.moveTo(8, 9); g.lineTo(26, 9); g.lineTo(26, 4); g.lineTo(11, 4);
    g.stroke();
    g.beginPath();
    g.arc(5, -12, 3.2, 0, A.TAU);
    g.stroke();
    g.beginPath();
    g.arc(-2, 0, 4.5, 0, A.TAU);
    g.stroke();
    A.glow(A.neon(A.hue + 20, 62));
    g.lineWidth = 2.6;
    g.beginPath();
    g.moveTo(-13.5, -6);
    g.lineTo(-13.5, 6);
    g.stroke();
    g.restore();
  }

  A.register({
    id: "falcon",
    order: { update: 70, draw: 70, guide: 70 },
    reset, update, draw, draw3d,
    guide: {
      name: "THE FALCON",
      tint: "var(--ink)",
      icon: `<svg width="34" height="34" viewBox="0 0 34 34" fill="none" stroke="currentColor" stroke-width="1.3" aria-hidden="true">
        <circle cx="14" cy="19" r="8"/>
        <circle cx="14" cy="19" r="3" opacity="0.55"/>
        <path d="M20 14 h10 v3 h-8 M20 24 h10 v-3 h-8" stroke-linejoin="round"/>
        <circle cx="18" cy="11" r="2.2"/>
        <path d="M6 16 v6" stroke="#21f3ff" stroke-width="2" stroke-linecap="round"/>
      </svg>`,
      desc: "Passing smuggler. Fires one enormous laser at the kraken, then keeps flying.",
    },
  });
})(ASTEROIDS);
