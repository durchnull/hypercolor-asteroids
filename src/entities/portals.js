// A pair of portals blinks open somewhere on the field. Fly in one and out the
// other — and so can your shots, the rocks, and the kraken.

(function (A) {
  "use strict";

  A.portals = null;

  const PORTAL_R = A.PORTAL_R = 26;
  const COOLDOWN = 0.6;     // no instant round trips
  const WARMUP = 0.4;       // a portal that just opened does not grab you

  let portalTimer = 0;

  A.spawnPortals = function spawnPortals() {
    const m = 90;
    function spot() {
      for (let i = 0; i < 20; i++) {
        const x = A.rand(m, A.W - m), y = A.rand(m, A.H - m);
        if (A.planet && Math.hypot(x - A.planet.x, y - A.planet.y) < A.planet.r + 70) continue;
        return { x, y };
      }
      return { x: A.rand(m, A.W - m), y: A.rand(m, A.H - m) };
    }
    const a = spot();
    let b = spot();
    for (let i = 0; i < 20 && Math.hypot(a.x - b.x, a.y - b.y) < Math.min(A.W, A.H) * 0.4; i++) {
      b = spot();
    }
    A.portals = { a, b, life: A.rand(9, 13), age: 0 };
    A.blip(520, 0.25, "sine", 0.12);
    A.shockwave(a.x, a.y, 190, 90, 200);
    A.shockwave(b.x, b.y, 260, 90, 200);
  };

  /** Anything with x/y/vx/vy can take the trip. */
  A.tryPortal = function tryPortal(obj, dt) {
    obj.portalCd = Math.max(0, (obj.portalCd || 0) - dt);
    if (!A.portals || obj.portalCd > 0 || A.portals.age < WARMUP) return;
    const pairs = [[A.portals.a, A.portals.b], [A.portals.b, A.portals.a]];
    for (const [from, to] of pairs) {
      if (Math.hypot(obj.x - from.x, obj.y - from.y) < PORTAL_R - 2) {
        const sp = Math.hypot(obj.vx, obj.vy);
        let nx, ny;
        if (sp > 10) { nx = obj.vx / sp; ny = obj.vy / sp; }
        else { const a = A.rand(0, A.TAU); nx = Math.cos(a); ny = Math.sin(a); }
        A.kaboom(from.x, from.y, 8, 12, 200);
        obj.x = to.x + nx * (PORTAL_R + (obj.radius || 2) + 6);
        obj.y = to.y + ny * (PORTAL_R + (obj.radius || 2) + 6);
        obj.portalCd = COOLDOWN;
        A.kaboom(obj.x, obj.y, 8, 12, 280);
        A.shockwave(to.x, to.y, 260, 70, 240);
        A.blip(660, 0.12, "sine", 0.08);
        return;
      }
    }
  };

  function reset(mode) {
    A.portals = null;
    if (mode === "play") portalTimer = A.rand(15, 25);
  }

  function update(tick) {
    if (!tick.running) return;
    const dt = tick.dt;

    if (A.portals) {
      A.portals.age += dt;
      A.portals.life -= dt;
      if (A.portals.life <= 0) {
        A.portals = null;
        const T = A.tune();
        portalTimer = A.rand(T.portalGap, T.portalGap + 10);
      }
    } else {
      portalTimer -= dt;
      if (portalTimer <= 0) A.spawnPortals();
    }

    for (const p of A.flyingShips()) A.tryPortal(p, dt);
    for (const b of A.bullets) A.tryPortal(b, dt);
    for (const a of A.asteroids) A.tryPortal(a, dt);
    for (const s of A.squids) A.tryPortal(s, dt);
  }

  function draw(tick, g) {
    if (!tick.running || !A.portals) return;
    const t = tick.time;
    const closing = A.portals.life < 2;
    for (const [i, e] of [A.portals.a, A.portals.b].entries()) {
      g.save();
      g.translate(e.x, e.y);
      const grow = Math.min(1, A.portals.age / 0.4);
      g.scale(grow, grow);
      g.globalAlpha = closing ? 0.35 + 0.65 * Math.abs(Math.sin(A.portals.life * 6)) : 1;
      // swirling rainbow arms
      for (let k = 0; k < 7; k++) {
        A.glow(A.neon(A.hue * 2 + k * 51 + i * 180, 62));
        g.lineWidth = 2;
        g.beginPath();
        const spin = t * (1.6 + k * 0.12) + k * 0.9;
        for (let j = 0; j <= 22; j++) {
          const f = j / 22;
          const ang = spin + f * 3.4;
          const rr = f * (PORTAL_R - 1);
          const x = Math.cos(ang) * rr, y = Math.sin(ang) * rr;
          if (j === 0) g.moveTo(x, y);
          else g.lineTo(x, y);
        }
        g.stroke();
      }
      A.glow(A.neon(A.hue * 3 + i * 180, 75));
      g.lineWidth = 2.2;
      g.setLineDash([8, 6]);
      g.lineDashOffset = -t * 60;
      g.beginPath();
      g.arc(0, 0, PORTAL_R - 1, 0, A.TAU);
      g.stroke();
      g.setLineDash([]);
      g.restore();
    }
    g.globalAlpha = 1;
  }

  A.register({
    id: "portals",
    order: { update: 60, draw: 20, guide: 50 },
    reset, update, draw,
    guide: {
      name: "PORTALS",
      tint: "var(--violet)",
      icon: `<svg width="34" height="34" viewBox="0 0 34 34" fill="none" stroke="currentColor" stroke-width="1.3" aria-hidden="true">
        <circle cx="9" cy="17" r="6.5" stroke-dasharray="3.5 3"/>
        <circle cx="25" cy="17" r="6.5" stroke-dasharray="3.5 3"/>
        <path d="M15.5 17 h3 M20 17 h1" opacity="0.7" stroke-linecap="round"/>
      </svg>`,
      desc: `A pair blinks open: in one, out the other. So can your shots, and
        so can the kraken.`,
    },
  });
})(ASTEROIDS);
