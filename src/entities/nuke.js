// The atom bomb: your panic button.
//
// The blast front covers somewhere between 30% and 50% of the playfield —
// pi*r² = f*W*H, f drawn fresh per bomb — so you never quite know how much
// screen it will eat, and it never eats all of it. Small and medium rocks
// vaporise; a big rock is too much stone to erase and shatters into small
// ones instead.

(function (A) {
  "use strict";

  A.nuke = null;

  const FRONT_TIME = 0.55;    // seconds for the front to cross its own radius
  const RELOAD = 0.8;

  A.blastRadius = () => Math.sqrt((A.rand(0.3, 0.5) * A.W * A.H) / Math.PI);

  A.detonate = function detonate(p) {
    if (!p || p.bombs <= 0 || p.dead || p.bombCooldown > 0 || A.game.phase !== "playing") return;
    p.bombs--;
    p.bombCooldown = RELOAD;
    A.nuke = { x: p.x, y: p.y, r: 0, max: A.blastRadius(), life: 1.5,
               hit: new Set(), owner: p };
    A.nukeSound();
    A.screenFlash(60, 0.95);
    A.shakeBy(34);
    A.aberrate(1);
    A.slowmo(0.32);
    // everyone in the blast gets a moment of grace — friendly fire is not a thing
    for (const q of A.livePlayers()) q.invuln = Math.max(q.invuln, 1.6);
    A.shockwave(A.nuke.x, A.nuke.y, 60, A.nuke.max * 1.05, A.nuke.max * 2.4);
    A.shockwave(A.nuke.x, A.nuke.y, 20, A.nuke.max * 0.8, A.nuke.max * 1.7);
    A.shockwave(A.nuke.x, A.nuke.y, 0, A.nuke.max * 0.55, A.nuke.max * 1.1);
  };

  function reset() {
    A.nuke = null;
  }

  function update(tick) {
    const n = A.nuke;
    if (!tick.running || !n) return;
    const prev = n.r;
    n.r += (n.max / FRONT_TIME) * tick.dt;
    n.life -= tick.dt;

    // rocks the front has just swept past: small and medium vaporise, big
    // shatters into smalls — marked as the blast's own debris so the front
    // does not eat them on the very next frame
    for (let i = A.asteroids.length - 1; i >= 0; i--) {
      const a = A.asteroids[i];
      if (n.hit.has(a)) continue;
      const d = Math.hypot(a.x - n.x, a.y - n.y);
      if (d <= n.r && d > prev - a.radius) {
        const rock = A.vaporiseAsteroid(i, n.owner);
        if (rock.size === 3) {
          for (let k = 0; k < 2; k++) {
            const shard = A.makeAsteroid(rock.x, rock.y, 1);
            n.hit.add(shard);
            A.asteroids.push(shard);
          }
        }
      }
    }
    // a kraken is all tentacle and no armour — caught in the blast, it dies
    for (const s of A.squids.slice()) {
      if (n.hit.has(s)) continue;
      if (Math.hypot(s.x - n.x, s.y - n.y) <= n.r) {
        n.hit.add(s);
        A.damageSquid(s, s.hp, n.owner);
      }
    }
    if (n.life <= 0) A.nuke = null;
  }

  // The fireball. Flat, it is a radial gradient — which is already a picture of
  // a sphere seen from straight above, so in three dimensions it is just the
  // sphere, middle on the plane so the front you can see is the front that is
  // eating rocks. Two shells rather than one, because the gradient had a white
  // heart in it and no single ball is both white and red.
  const shell = (n) => A.mesh.get("nuke:fireball:" + n, () => A.mesh.ball(n));

  const at = {};

  function draw3d(tick, s) {
    const n = A.nuke;
    if (!n) return;
    const f = Math.min(1, n.r / n.max);
    const fade = Math.max(0, Math.min(1, n.life / 0.9));
    const r = Math.max(1, n.r);

    // Every part of the bomb glows: it is light, not matter, so it adds rather
    // than covers and can never black out the rocks it is busy eating. That is
    // also why the body keeps most of its light here — a fireball dimmed to a
    // sixth like a rock is a soap bubble.
    at.x = n.x; at.y = n.y; at.z = 0;
    at.rx = f * 0.7; at.ry = f * 1.1; at.rz = f * 1.6;
    at.s = r;
    at.hue = 25 - A.hue; at.light = 58;
    at.alpha = 0.2 * fade; at.width = 1; at.dim = 0.9; at.glow = true;
    s.model(shell(1), at);

    at.s = r * 0.42;
    at.hue = 50 - A.hue; at.light = 86;
    at.alpha = 0.4 * fade; at.width = 1.4;
    s.model(shell(0), at);

    // the shock front, at the three radii the flat bomb strokes its arcs
    at.rx = at.ry = at.rz = 0; at.s = 1; at.dim = 0;
    for (let i = 0; i < 3; i++) {
      at.hue = 55 - i * 20 - A.hue;
      at.light = 70;
      at.alpha = (0.9 - i * 0.25) * fade;
      at.width = 7 - i * 2;
      s.ring(n.x, n.y, 0, Math.max(1, n.r - i * 9), at);
    }

    // Forty tongues, because forty is what makes a ring read as fire. The outer
    // end lifts off the plane by turns so the rim boils instead of spreading
    // like a puddle; the inner end stays down, where the front is.
    at.light = 62; at.width = 2.5;
    for (let i = 0; i < 40; i++) {
      const a = (i / 40) * A.TAU + f * 2;
      const wob = 1 + Math.sin(i * 3.1 + f * 12) * 0.09;
      at.hue = 35 + Math.sin(i) * 25 - A.hue;
      at.alpha = 0.55 * fade;
      s.line(n.x + Math.cos(a) * n.r * 0.86, n.y + Math.sin(a) * n.r * 0.86, 0,
             n.x + Math.cos(a) * n.r * wob, n.y + Math.sin(a) * n.r * wob,
             Math.sin(i * 2.7 + f * 9) * n.r * 0.14, at);
    }
  }

  function draw(tick, g) {
    if (A.gl.on) return;
    const n = A.nuke;
    if (!n) return;
    const f = Math.min(1, n.r / n.max);
    const fade = Math.max(0, Math.min(1, n.life / 0.9));

    // the fireball core
    g.save();
    const core = g.createRadialGradient(n.x, n.y, 0, n.x, n.y, Math.max(1, n.r));
    core.addColorStop(0, "rgba(255,255,255," + (0.5 * fade) + ")");
    core.addColorStop(0.35, A.neon(50, 60, 0.34 * fade));
    core.addColorStop(0.75, A.neon(20, 55, 0.16 * fade));
    core.addColorStop(1, "rgba(0,0,0,0)");
    g.fillStyle = core;
    g.beginPath();
    g.arc(n.x, n.y, Math.max(1, n.r), 0, A.TAU);
    g.fill();

    // the shock front itself
    g.lineCap = "round";
    for (let i = 0; i < 3; i++) {
      g.strokeStyle = A.neon(55 - i * 20, 70, (0.9 - i * 0.25) * fade);
      g.lineWidth = 7 - i * 2;
      g.beginPath();
      g.arc(n.x, n.y, Math.max(1, n.r - i * 9), 0, A.TAU);
      g.stroke();
    }
    // rolling flame tongues around the rim
    g.lineWidth = 2.5;
    for (let i = 0; i < 40; i++) {
      const a = (i / 40) * A.TAU + f * 2;
      const wob = 1 + Math.sin(i * 3.1 + f * 12) * 0.09;
      g.strokeStyle = A.neon(35 + Math.sin(i) * 25, 62, 0.55 * fade);
      g.beginPath();
      g.moveTo(n.x + Math.cos(a) * n.r * 0.86, n.y + Math.sin(a) * n.r * 0.86);
      g.lineTo(n.x + Math.cos(a) * n.r * wob, n.y + Math.sin(a) * n.r * wob);
      g.stroke();
    }
    g.restore();
  }

  A.register({
    id: "nuke",
    order: { update: 50, draw: 80, guide: 20 },
    reset, update, draw, draw3d,
    guide: {
      name: "ATOM BOMB",
      meta: "B &middot; 2 to start",
      tint: "var(--amber)",
      icon: `<svg width="34" height="34" viewBox="0 0 34 34" fill="none" stroke="currentColor" stroke-width="1.3" aria-hidden="true">
        <circle cx="16" cy="20" r="9"/>
        <path d="M16 11 V6 M12 7.5 L20 4.5" stroke-linecap="round"/>
        <circle cx="16" cy="20" r="14" stroke-dasharray="2.5 3.5" opacity="0.65"/>
      </svg>`,
      desc: `Your panic button. The blast front eats up to half the screen —
        never all of it — vaporising small and medium rocks, shattering big
        ones into pebbles, and killing any kraken it catches. One more every
        second wave.`,
    },
  });
})(ASTEROIDS);
