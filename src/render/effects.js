// Screen feel: debris, shockwaves, score popups, camera shake, colour flash,
// chromatic aberration, slow-mo and the wave banner.
//
// Every feature is allowed to reach for these — they are the vocabulary of
// "something just happened". Nothing here knows what a rock or a kraken is.

(function (A) {
  "use strict";

  /** Whole-screen state. Read it anywhere; set it through the helpers below. */
  A.fx = {
    shake: 0,
    flashA: 0,
    flashHue: 0,
    aberr: 0,
    deathFx: 0,
    deathAt: null,
    timeScale: 1,
    banner: null,
  };
  const fx = A.fx;

  const shocks = A.shocks = [];
  const debris = A.debris = [];
  const popups = A.popups = [];

  A.shockwave = (x, y, h, max, speed) => {
    shocks.push({ x, y, r: 4, max: max || 140, sp: speed || 320, hue: h });
  };

  A.popup = (x, y, text, h) => {
    popups.push({ x, y, text, hue: h, life: 1 });
  };

  A.kaboom = function kaboom(x, y, n, spread, h, power) {
    for (let i = 0; i < n; i++) {
      const dir = A.rand(0, A.TAU);
      const speed = A.rand(40, 150) * (power || 1);
      debris.push({
        x: x + Math.cos(dir) * A.rand(0, spread),
        y: y + Math.sin(dir) * A.rand(0, spread),
        vx: Math.cos(dir) * speed,
        vy: Math.sin(dir) * speed,
        angle: A.rand(0, A.TAU),
        spin: A.rand(-8, 8),
        len: A.rand(3, 11),
        life: A.rand(0.4, 1.1),
        hue: (h === undefined ? A.rand(0, 360) : h + A.rand(-40, 40)),
      });
    }
  };

  /** One shard, for the trails and sparks that want to place their own. */
  A.spark = (shard) => debris.push(shard);

  A.screenFlash = (h, a) => {
    fx.flashHue = h;
    fx.flashA = Math.max(fx.flashA, a);
  };

  // The loudest caller wins: a small knock never damps a big one.
  A.shakeBy = (n) => { fx.shake = Math.max(fx.shake, n); };
  A.aberrate = (n) => { fx.aberr = Math.max(fx.aberr, n); };
  A.slowmo = (scale) => { fx.timeScale = Math.min(fx.timeScale, scale); };

  A.deathBloom = (x, y, life) => {
    fx.deathFx = life;
    fx.deathAt = { x, y };
  };

  A.showBanner = (text, sub, life) => {
    fx.banner = { text, sub: sub || null, life };
  };

  /** Real-time decay, run by the loop before anything else touches the frame. */
  A.decayEffects = function decayEffects(raw) {
    fx.shake *= Math.pow(0.02, raw);
    fx.flashA *= Math.pow(0.03, raw);
    fx.aberr *= Math.pow(0.05, raw);
    if (fx.deathFx > 0) fx.deathFx = Math.max(0, fx.deathFx - raw);
    fx.timeScale += (1 - fx.timeScale) * Math.min(1, raw * 1.6);
  };

  function reset(mode) {
    fx.timeScale = 1;
    if (mode === "over") return;
    shocks.length = debris.length = popups.length = 0;
    fx.banner = null;
    fx.deathFx = 0;
    fx.shake = 0;
  }

  function update(tick) {
    // debris and shockwaves keep moving on the menu too, so an explosion that
    // outlives the game still finishes
    const dt = tick.dt;
    for (let i = debris.length - 1; i >= 0; i--) {
      const d = debris[i];
      d.x += d.vx * dt;
      d.y += d.vy * dt;
      if (tick.running) {
        d.vx *= Math.pow(0.6, dt);
        d.vy *= Math.pow(0.6, dt);
        d.angle += d.spin * dt;
      }
      d.life -= dt;
      if (d.life <= 0) debris.splice(i, 1);
    }
    for (let i = shocks.length - 1; i >= 0; i--) {
      const s = shocks[i];
      s.r += s.sp * dt;
      if (s.r > s.max) shocks.splice(i, 1);
    }
    if (!tick.running) return;
    for (let i = popups.length - 1; i >= 0; i--) {
      const p = popups[i];
      p.y -= 34 * dt;
      p.life -= dt * 1.1;
      if (p.life <= 0) popups.splice(i, 1);
    }
    if (fx.banner) {
      fx.banner.life -= dt;
      if (fx.banner.life <= 0) fx.banner = null;
    }
  }

  function drawField(tick, g) {
    for (const s of shocks) {
      const f = 1 - s.r / s.max;
      g.save();
      g.globalAlpha = Math.max(0, f) * 0.85;
      A.glow(A.neon(A.hue + s.hue, 65));
      g.lineWidth = 1 + f * 3.5;
      g.beginPath();
      g.arc(s.x, s.y, s.r, 0, A.TAU);
      g.stroke();
      g.restore();
    }
    // debris shards — flat loop, no per-particle save/restore
    g.lineCap = "round";
    g.lineWidth = 1.8;
    for (const d of debris) {
      g.globalAlpha = Math.min(1, d.life * 2.2);
      g.strokeStyle = A.neon(d.hue, 62);
      const cx = Math.cos(d.angle) * d.len * 0.5;
      const cy = Math.sin(d.angle) * d.len * 0.5;
      g.beginPath();
      g.moveTo(d.x - cx, d.y - cy);
      g.lineTo(d.x + cx, d.y + cy);
      g.stroke();
    }
    g.globalAlpha = 1;
  }

  function drawOver(tick, g) {
    // death kaleidoscope, anchored where the ship actually died
    if (fx.deathFx > 0 && fx.deathAt) {
      g.save();
      g.translate(fx.deathAt.x, fx.deathAt.y);
      g.rotate(tick.time * 3);
      g.globalAlpha = fx.deathFx * 0.6;
      for (let i = 0; i < 16; i++) {
        A.glow(A.neon(A.hue * 5 + i * 22, 62));
        g.lineWidth = 2.5;
        g.beginPath();
        g.moveTo(0, 0);
        const len = (1.4 - fx.deathFx) * Math.max(A.W, A.H) * 0.9;
        g.lineTo(Math.cos((i / 16) * A.TAU) * len, Math.sin((i / 16) * A.TAU) * len);
        g.stroke();
      }
      g.restore();
    }
    if (popups.length) {
      g.font = "600 15px " + A.FONT;
      g.textAlign = "center";
      for (const p of popups) {
        g.globalAlpha = Math.min(1, p.life);
        g.fillStyle = A.neon(p.hue, 70);
        g.fillText(p.text, p.x, p.y);
      }
      g.globalAlpha = 1;
    }
  }

  // Two entries, because the effects straddle everything else: shards and rings
  // sit under the bullets, the death bloom and the score popups sit over them.
  A.register([
    { id: "effects", order: { update: 90, draw: 88 }, reset, update, draw: drawField },
    { id: "effects:overlay", order: { draw: 92 }, draw: drawOver },
  ]);
})(ASTEROIDS);
