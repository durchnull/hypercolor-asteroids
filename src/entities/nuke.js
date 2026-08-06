// The atom bomb: your panic button.
//
// The blast front covers half the playfield — pi*r² = W*H/2 — and everything
// it sweeps over is vaporised as it passes, so you watch it eat the screen.

(function (A) {
  "use strict";

  A.nuke = null;

  const FRONT_TIME = 0.55;    // seconds for the front to cross its own radius
  const KRAKEN_HURT = 3;      // hit points a caught kraken loses
  const RELOAD = 0.8;

  A.blastRadius = () => Math.sqrt((A.W * A.H) / (2 * Math.PI));

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

    // vaporise rocks the front has just swept past
    for (let i = A.asteroids.length - 1; i >= 0; i--) {
      const a = A.asteroids[i];
      const d = Math.hypot(a.x - n.x, a.y - n.y);
      if (d <= n.r && d > prev - a.radius) A.vaporiseAsteroid(i, n.owner);
    }
    // krakens caught in the blast take heavy damage, once each
    for (const s of A.squids.slice()) {
      if (n.hit.has(s)) continue;
      if (Math.hypot(s.x - n.x, s.y - n.y) <= n.r) {
        n.hit.add(s);
        A.damageSquid(s, KRAKEN_HURT, n.owner);
      }
    }
    if (n.life <= 0) A.nuke = null;
  }

  function draw(tick, g) {
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
    reset, update, draw,
    guide: {
      name: "ATOM BOMB",
      meta: "B &middot; 2 to start",
      tint: "var(--amber)",
      icon: `<svg width="34" height="34" viewBox="0 0 34 34" fill="none" stroke="currentColor" stroke-width="1.3" aria-hidden="true">
        <circle cx="16" cy="20" r="9"/>
        <path d="M16 11 V6 M12 7.5 L20 4.5" stroke-linecap="round"/>
        <circle cx="16" cy="20" r="14" stroke-dasharray="2.5 3.5" opacity="0.65"/>
      </svg>`,
      desc: `Your panic button. The blast front eats half the screen, vaporising
        every rock it touches and gutting any kraken. One more each wave.`,
    },
  });
})(ASTEROIDS);
