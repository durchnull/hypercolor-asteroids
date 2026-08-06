// The sky: drifting nebula clouds and a twinkling starfield. Drawn straight to
// the visible canvas underneath the glowing entity layer, so it never blooms
// and never leaves trails.

(function (A) {
  "use strict";

  let stars = [];
  let clouds = [];

  A.buildSky = function buildSky() {
    stars = [];
    const n = Math.round((A.W * A.H) / 5200);
    for (let i = 0; i < n; i++) {
      stars.push({
        x: Math.random() * A.W,
        y: Math.random() * A.H,
        d: 0.25 + Math.random() * 0.75,
        tw: Math.random() * A.TAU,
        hue: Math.random() * 360,
      });
    }
    clouds = [];
    for (let i = 0; i < 7; i++) {
      clouds.push({
        x: Math.random() * A.W,
        y: Math.random() * A.H,
        r: Math.min(A.W, A.H) * (0.3 + Math.random() * 0.45),
        hue: i * 51,
        vx: (Math.random() - 0.5) * 11,
        vy: (Math.random() - 0.5) * 11,
      });
    }
  };
  A.onResize(A.buildSky);

  A.drawSky = function drawSky(t) {
    const ctx = A.ctx;
    ctx.fillStyle = "#07030f";
    ctx.fillRect(0, 0, A.W, A.H);

    ctx.save();
    ctx.globalCompositeOperation = "lighter";
    for (const c of clouds) {
      c.x += c.vx * 0.016;
      c.y += c.vy * 0.016;
      if (c.x < -c.r) c.x = A.W + c.r;
      if (c.x > A.W + c.r) c.x = -c.r;
      if (c.y < -c.r) c.y = A.H + c.r;
      if (c.y > A.H + c.r) c.y = -c.r;
      const grad = ctx.createRadialGradient(c.x, c.y, 0, c.x, c.y, c.r);
      grad.addColorStop(0, A.neon(A.hue + c.hue, 55, 0.22));
      grad.addColorStop(0.5, A.neon(A.hue + c.hue + 40, 48, 0.1));
      grad.addColorStop(1, "rgba(0,0,0,0)");
      ctx.fillStyle = grad;
      ctx.beginPath();
      ctx.arc(c.x, c.y, c.r, 0, A.TAU);
      ctx.fill();
    }
    for (const s of stars) {
      const tw = 0.45 + 0.55 * Math.sin(t * 2.5 + s.tw);
      ctx.fillStyle = A.neon(A.hue * 0.6 + s.hue, 80, 0.75 * tw * s.d);
      const r = s.d * 1.5;
      ctx.fillRect(s.x - r / 2, s.y - r / 2, r, r);
    }
    ctx.restore();
  };
})(ASTEROIDS);
