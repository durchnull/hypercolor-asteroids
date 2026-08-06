// Shots. They belong to the pilot who fired them, which is how the score for
// a kill finds its way home.

(function (A) {
  "use strict";

  const bullets = A.bullets = [];

  const SPEED = 480;
  const LIFE = 1.1;

  A.fireBullet = function fireBullet(p) {
    const b = {
      x: p.x + Math.cos(p.angle) * 13,
      y: p.y + Math.sin(p.angle) * 13,
      vx: p.vx + Math.cos(p.angle) * SPEED,
      vy: p.vy + Math.sin(p.angle) * SPEED,
      radius: 1.6,
      life: LIFE,
      hue: A.hue * 3 + p.hue,
      owner: p,
    };
    bullets.push(b);
    return b;
  };

  function reset(mode) {
    if (mode !== "over") bullets.length = 0;
  }

  function update(tick) {
    if (!tick.running) return;
    for (let i = bullets.length - 1; i >= 0; i--) {
      const b = bullets[i];
      b.x += b.vx * tick.dt;
      b.y += b.vy * tick.dt;
      b.life -= tick.dt;
      A.wrap(b);
      if (b.life <= 0) bullets.splice(i, 1);
    }
  }

  function draw(tick, g) {
    for (const b of bullets) {
      g.fillStyle = A.neon(b.hue, 75);
      g.beginPath();
      g.arc(b.x, b.y, 2.6, 0, A.TAU);
      g.fill();
    }
  }

  A.register({ id: "bullets", order: { update: 20, draw: 89 }, reset, update, draw });
})(ASTEROIDS);
