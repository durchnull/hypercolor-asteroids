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

  const at = {};

  function draw3d(tick, s) {
    const m = A.mesh.get("bullet", () => A.mesh.ball(0));
    for (const b of bullets) {
      at.x = b.x; at.y = b.y; at.z = 0;
      // stretched along its own flight, which is the only direction a shot
      // has ever cared about
      at.rz = Math.atan2(b.vy, b.vx);
      at.rx = 0; at.ry = 0;
      at.sx = 4.4; at.sy = 2.4; at.sz = 2.4;
      at.hue = b.hue - A.hue;   // bullets bake the drift in at birth
      at.light = 75; at.width = 1.4; at.dim = 0.55; at.glow = true;
      s.model(m, at);
    }
  }

  function draw(tick, g) {
    if (A.gl.on) return;
    for (const b of bullets) {
      g.fillStyle = A.neon(b.hue, 75);
      g.beginPath();
      g.arc(b.x, b.y, 2.6, 0, A.TAU);
      g.fill();
    }
  }

  A.register({ id: "bullets", order: { update: 20, draw: 89 }, reset, update, draw, draw3d });
})(ASTEROIDS);
