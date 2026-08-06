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

  function draw(tick, g) {
    if (!tick.running || !A.falcon) return;
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
    reset, update, draw,
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
