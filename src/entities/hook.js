// The grappling hook.
//
// It is a tether, not a winch. The line locks at the length it bit at and from
// then on it only ever *stops* you leaving — it never hauls you in. So a hook
// turns speed you already had into a curve: you swing round the thing you
// caught and leave on the tangent, carrying the lot. The line also refuses to
// let you closer than a ship's width from the anchor, so the one thing it can
// never do is feed you to the rock. Hold the button and the winch shortens the
// line: a tighter arc is a faster one, which is how you build real speed.
//
// The ship drives all of this — see entities/ship.js for the button handling.

(function (A) {
  "use strict";

  const HOOK_SPEED = 900;
  const HOOK_RANGE = 380;
  const HOOK_SNAP = 560;         // haul past this and the line parts
  const HOOK_CLEAR = 26;         // hull-to-rock daylight the line will not give up
  const REEL_RATE = 300;         // px/s the winch takes in while you hold it
  const TETHER_BITE = 0.94;      // how much outward speed the line eats
  const WHIP = 0.8;              // arrested speed spent sideways instead of lost
  const HOOK_KICK = 110;         // shove off as you cut loose
  const WRECK_SPEED = 170;       // how fast a held rock must swing to break things
  const HARPOON_TICK = 1.5;      // seconds per point of bleed on a hooked kraken

  // Everything you can catch answers the same three questions: where is the
  // bite point now, how big is the body, and is it still there to hold on to.
  function anchorPos(h) {
    const a = h.target;
    if (!a) return { x: h.x, y: h.y };
    if (h.kind === "rock") {         // the bite rides along as the rock spins
      const c = Math.cos(a.angle), s = Math.sin(a.angle);
      return { x: a.x + h.offX * c - h.offY * s, y: a.y + h.offX * s + h.offY * c };
    }
    return { x: a.x + h.offX, y: a.y + h.offY };
  }

  function anchorRadius(h) {
    const a = h.target;
    if (!a) return 0;
    return h.kind === "planet" ? a.r : h.kind === "kraken" ? a.radius + 10 : a.radius;
  }

  function anchorAlive(h) {
    if (h.kind === "rock") return A.asteroids.indexOf(h.target) !== -1;
    if (h.kind === "kraken") return A.squids.indexOf(h.target) !== -1 && h.target.hp > 0;
    if (h.kind === "planet") return A.planet === h.target;
    return false;
  }

  // Newton gets his say: whatever the line takes off you, it puts on the
  // anchor, divided by how much rock there is. A pebble comes along for the
  // ride; a boulder shrugs; the planet does not even notice.
  function tugAnchor(h, ix, iy) {
    const a = h.target;
    if (!a || h.kind === "planet") return;
    const m = h.kind === "kraken" ? 7 : (a.radius * a.radius) / 169;
    a.vx += ix / m;
    a.vy += iy / m;
  }

  // A line cannot destroy the speed you brought it — it can only bend it. So
  // whatever the tether arrests head-on it spends sideways instead: even a shot
  // straight down the middle throws you into an arc rather than parking you.
  // Which way round is not arbitrary — the rock's own spin decides it.
  function whipRound(p, h, nx, ny, arrested) {
    const s = Math.abs(arrested);
    if (s < 110) return;      // below this it is just the arc drawn in steps
    const tx = -ny, ty = nx;
    let side = p.vx * tx + p.vy * ty;        // keep going whichever way you leaned
    if (Math.abs(side) < 30) side = h.kind === "rock" ? h.target.spin || 1 : 1;
    const sg = side >= 0 ? 1 : -1;
    p.vx += tx * sg * s * WHIP;
    p.vy += ty * sg * s * WHIP;
  }

  A.fireHook = function fireHook(p) {
    if (p.hook || p.hookCooldown > 0 || p.dead) return;
    p.hook = {
      x: p.x + Math.cos(p.angle) * 14,
      y: p.y + Math.sin(p.angle) * 14,
      vx: p.vx + Math.cos(p.angle) * HOOK_SPEED,
      vy: p.vy + Math.sin(p.angle) * HOOK_SPEED,
      radius: 3,
      state: "flying",
      travel: 0,
      spin: p.angle,
      target: null, kind: null, offX: 0, offY: 0,
      len: 0, taut: 0, reel: 0, swept: 0, lastA: 0,
      wreckCd: 0, bleed: HARPOON_TICK,
    };
    A.hookThrow();
  };

  function bite(p, h, obj, kind) {
    h.state = "attached";
    h.target = obj;
    h.kind = kind;
    const dx = h.x - obj.x, dy = h.y - obj.y;
    if (kind === "rock") {        // store the bite in the rock's own turning frame
      const c = Math.cos(-obj.angle), s = Math.sin(-obj.angle);
      h.offX = dx * c - dy * s;
      h.offY = dx * s + dy * c;
    } else {
      h.offX = dx;
      h.offY = dy;
    }
    const anc = anchorPos(h);
    h.len = Math.max(Math.hypot(p.x - anc.x, p.y - anc.y),
                     anchorRadius(h) + p.radius + HOOK_CLEAR);
    h.lastA = Math.atan2(p.y - anc.y, p.x - anc.x);
    h.taut = 1;
    A.kaboom(h.x, h.y, 6, 5, A.hue + 40);
    A.shockwave(h.x, h.y, A.hue + p.hue, 46, 190);
    A.hookBite();
    if (kind === "kraken") A.damageSquid(obj, 1, p);   // the barb goes in deep
  }

  A.releaseHook = function releaseHook(p) {
    const h = p.hook;
    if (!h) return;
    if (h.state === "attached") {
      const sp = Math.hypot(p.vx, p.vy);
      if (sp > 1) {                 // kick off the line on the way past
        p.vx += (p.vx / sp) * HOOK_KICK;
        p.vy += (p.vy / sp) * HOOK_KICK;
      }
      // the afterglow lasts as long as the exit was worth having
      p.boost = Math.min(2.4, 0.5 + sp / 380);
      if (sp > 560) {
        A.popup(p.x, p.y - 24, "SLINGSHOT", A.hue + p.hue);
        A.screenFlash(A.hue + p.hue, 0.12);
      }
      A.kaboom(h.x, h.y, 5, 5, A.hue + p.hue);
      A.hookSnap();
    }
    p.hook = null;
    p.hookCooldown = 0.3;
  };

  // A rock on the end of a line is a mace. Swing one hard enough and it opens
  // up whatever it lands on — free of ammunition, expensive in nerve.
  function wreckPass(p, h, dt) {
    if (h.kind !== "rock") return;
    const a = h.target;
    h.wreckCd -= dt;
    if (h.wreckCd > 0) return;
    const sp = Math.hypot(a.vx, a.vy);
    if (sp < WRECK_SPEED) return;

    for (let i = A.asteroids.length - 1; i >= 0; i--) {
      const o = A.asteroids[i];
      if (o === a) continue;
      if (Math.hypot(o.x - a.x, o.y - a.y) >= o.radius + a.radius) continue;
      const nx = (o.x - a.x) / (o.radius + a.radius);
      const ny = (o.y - a.y) / (o.radius + a.radius);
      A.splitAsteroid(o, i, p);
      p.score += 50;
      A.popup(a.x, a.y - 18, "WRECK +50", A.hue + p.hue);
      A.shakeBy(9);
      a.vx -= nx * sp * 0.5;
      a.vy -= ny * sp * 0.5;
      h.wreckCd = 0.18;
      // swing a pebble at a boulder and the pebble is what breaks
      if (o.size >= a.size) {
        const j = A.asteroids.indexOf(a);
        if (j !== -1) { A.splitAsteroid(a, j, p); A.releaseHook(p); }
      }
      return;
    }
    for (const s of A.squids) {
      if (s.z >= 25 || s.hp <= 0) continue;
      if (Math.hypot(s.x - a.x, s.y - a.y) >= s.radius + a.radius) continue;
      A.damageSquid(s, a.size, p);
      A.popup(a.x, a.y - 18, "WRECK", A.hue + p.hue);
      a.vx = -a.vx * 0.6;
      a.vy = -a.vy * 0.6;
      h.wreckCd = 0.3;
      return;
    }
  }

  A.updateHook = function updateHook(p, dt) {
    const h = p.hook;
    if (!h) return;

    if (h.state === "flying") {
      h.x += h.vx * dt;
      h.y += h.vy * dt;
      h.travel += Math.hypot(h.vx, h.vy) * dt;
      h.spin += 16 * dt;
      A.wrap(h);
      for (const a of A.asteroids) {
        if (Math.hypot(a.x - h.x, a.y - h.y) < a.radius) { bite(p, h, a, "rock"); break; }
      }
      if (h.state === "flying") {
        for (const s of A.squids) {      // a submerged kraken is not there to catch
          if (s.z >= 25 || s.hp <= 0) continue;
          if (Math.hypot(s.x - h.x, s.y - h.y) < s.radius + 6) { bite(p, h, s, "kraken"); break; }
        }
      }
      if (h.state === "flying" && A.planet &&
          Math.hypot(A.planet.x - h.x, A.planet.y - h.y) < A.planet.r) {
        bite(p, h, A.planet, "planet");    // the thing that was going to flatten you
      }
      if (h.state === "flying" && h.travel > HOOK_RANGE) {
        p.hook = null;
        p.hookCooldown = 0.25;
      }
      return;
    }

    if (!anchorAlive(h)) { A.releaseHook(p); return; }  // anchor gone, line comes free

    const anc = anchorPos(h);
    h.x = anc.x;
    h.y = anc.y;
    const core = anchorRadius(h);
    const clear = core + p.radius + HOOK_CLEAR;   // hull-to-body, kept absolutely
    // The winch stops at the length that still lets you go all the way round at
    // that clearance. Shorter than this and the line and the rock would be
    // asking for two different things at once, and the argument costs you all
    // your speed.
    const bo = Math.hypot(h.x - h.target.x, h.y - h.target.y);
    const minLen = Math.min(clear + bo, HOOK_RANGE);

    const dx = p.x - h.x, dy = p.y - h.y;
    const d = Math.hypot(dx, dy) || 1;
    const nx = dx / d, ny = dy / d;                     // anchor → ship

    // too much line out and it parts — which is also what happens the moment
    // one of you wraps round the edge of the world
    if (d > HOOK_SNAP) { A.releaseHook(p); return; }

    // Hold the button and the winch takes line in. How much you leave out is
    // the whole tactical choice: a long line is a wide, fast, committed arc; a
    // short one whips you tight around the rock. Shortening a swing also spins
    // you up, because the angular momentum has to go somewhere — that is how
    // you build real speed out of a hook, and it is the only part of the rig
    // that may.
    const onSkin = Math.hypot(p.x - h.target.x, p.y - h.target.y) <= clear + 1;
    if (h.reel && h.len > minLen) {
      const nl = Math.max(minLen, h.len - REEL_RATE * dt);
      if (!onSkin && d <= h.len + 1) {          // only a line under load pays out speed
        const gain = Math.min(1.6, 1 + (h.len / nl - 1) * 0.5);  // half the physics
        const vr = p.vx * nx + p.vy * ny;
        const tx = p.vx - nx * vr, ty = p.vy - ny * vr;          // tangential part
        p.vx = nx * vr + tx * gain;
        p.vy = ny * vr + ty * gain;
      }
      h.len = nl;
      if (Math.random() < 0.5) {
        const dir = A.rand(0, A.TAU);
        A.spark({
          x: h.x, y: h.y,
          vx: Math.cos(dir) * A.rand(30, 90), vy: Math.sin(dir) * A.rand(30, 90),
          angle: dir, spin: A.rand(-8, 8),
          len: A.rand(2, 5), life: A.rand(0.15, 0.35),
          hue: A.hue + 40 + A.rand(-25, 25),
        });
      }
    }
    h.len = Math.max(h.len, minLen);

    // From here on the line may bend what you are carrying but never add to it.
    // The winch above is the only thing in the rig allowed to make you faster,
    // which is what keeps a long swing honest instead of a free engine.
    const sp0 = Math.hypot(p.vx, p.vy);

    h.taut = Math.max(0, h.taut - dt * 3);
    if (d > h.len) {
      // the line comes up hard: you stay on the circle and keep everything that
      // was carrying you sideways
      const over = d - h.len;
      p.x -= nx * over;
      p.y -= ny * over;
      const vr = p.vx * nx + p.vy * ny;
      if (vr > 0) {
        p.vx -= nx * vr * TETHER_BITE;
        p.vy -= ny * vr * TETHER_BITE;
        tugAnchor(h, nx * vr * TETHER_BITE, ny * vr * TETHER_BITE);
        whipRound(p, h, nx, ny, vr * TETHER_BITE);
        h.taut = Math.min(1, vr / 260);
      }
    }

    // And the hard promise: the line keeps your hull off the body it is tied
    // to, always, whatever the rope is doing. You came in down the middle, or
    // the rock drifted onto you — either way it fends you off and throws the
    // stopped speed round the side. That is a suicide run turned into a swing.
    const a = h.target;
    const bx = p.x - a.x, by = p.y - a.y;
    const bd = Math.hypot(bx, by) || 1;
    if (bd < clear) {
      const ux = bx / bd, uy = by / bd;
      p.x += ux * (clear - bd);
      p.y += uy * (clear - bd);
      const vr = p.vx * ux + p.vy * uy;
      if (vr < 0) {
        p.vx -= ux * vr;
        p.vy -= uy * vr;
        tugAnchor(h, ux * vr, uy * vr);
        whipRound(p, h, ux, uy, vr);
        if (vr < -120) {
          A.kaboom(p.x, p.y, 4, 5, A.hue + 40);
          A.shockwave(p.x, p.y, A.hue + p.hue, 40, 200);
          A.shakeBy(5);
        }
      }
      h.taut = 1;
      // the body shouldered the line aside, so the winch pays out rather than
      // fight it — otherwise the two constraints would argue every frame
      h.len = Math.max(h.len, Math.hypot(p.x - h.x, p.y - h.y));
    }

    const sp1 = Math.hypot(p.vx, p.vy);
    if (sp1 > sp0 && sp1 > 1) { p.vx *= sp0 / sp1; p.vy *= sp0 / sp1; }

    // how far round you have come, for the arc readout
    const ang = Math.atan2(p.y - h.y, p.x - h.x);
    let da = ang - h.lastA;
    while (da > Math.PI) da -= A.TAU;
    while (da < -Math.PI) da += A.TAU;
    h.swept += Math.abs(da);
    h.lastA = ang;

    wreckPass(p, h, dt);

    if (h.kind === "kraken") {        // the barb keeps working while you ride it
      h.bleed -= dt;
      if (h.bleed <= 0) { h.bleed = HARPOON_TICK; A.damageSquid(h.target, 1, p); }
    }
  };

  A.drawHook = function drawHook(p, g) {
    const h = p.hook;
    if (!h || p.dead) return;
    const taut = h.state === "attached";
    const dx = h.x - p.x, dy = h.y - p.y;
    const d = Math.hypot(dx, dy) || 1;
    const nx = -dy / d, ny = dx / d;
    const c = A.neon(A.hue + p.hue + (taut ? 40 : 0), taut ? 70 + h.taut * 20 : 60);

    // the arc the line will hold you to, drawn only as you come out to meet it
    // — it fades up exactly when it starts to matter and stays out of the way
    // while the line is slack
    const reach = taut ? Math.min(1, Math.max(0, (d / h.len - 0.72) * 3.6)) : 0;
    if (reach > 0.02) {
      g.save();
      A.glow(A.neon(A.hue + p.hue, 60, 0.26 * reach));
      g.lineWidth = 1;
      g.setLineDash([5, 9]);
      g.lineDashOffset = -h.swept * 26;
      g.beginPath();
      g.arc(h.x, h.y, h.len, 0, A.TAU);
      g.stroke();
      g.restore();
    }

    // the line: loose while it flies out, singing while it holds you
    A.glow(c);
    g.lineWidth = taut ? 1.8 + h.taut * 1.6 : 1.4;
    g.beginPath();
    g.moveTo(p.x, p.y);
    const segs = 10;
    for (let i = 1; i <= segs; i++) {
      const f = i / segs;
      const wob = taut
        ? Math.sin(f * Math.PI) * Math.sin(h.swept * 9) * (1 + h.taut * 5)
        : Math.sin(f * Math.PI) * Math.sin(h.travel * 0.05) * 7;
      g.lineTo(p.x + dx * f + nx * wob, p.y + dy * f + ny * wob);
    }
    g.stroke();

    // the head: a little barbed claw
    g.save();
    g.translate(h.x, h.y);
    g.rotate(taut ? Math.atan2(-dy, -dx) : h.spin);
    g.lineWidth = 2;
    g.beginPath();
    g.moveTo(-5, 0);
    g.lineTo(4, 0);
    g.moveTo(4, 0);
    g.lineTo(-2, -5);
    g.moveTo(4, 0);
    g.lineTo(-2, 5);
    g.stroke();
    g.restore();
  };

  // No hooks of its own — the ship drives it. It is here for the field guide.
  A.register({
    id: "grapple",
    order: { guide: 30 },
    guide: {
      name: "GRAPPLE",
      meta: "&darr; &middot; free",
      tint: "var(--lime)",
      icon: `<svg width="34" height="34" viewBox="0 0 34 34" fill="none" stroke="currentColor" stroke-width="1.3" aria-hidden="true">
        <path d="M3 28 Q11 22 18 14" stroke-linecap="round"/>
        <path d="M18 14 L24 8 M24 8 L17 7 M24 8 L25 15" stroke-linecap="round" stroke-linejoin="round"/>
        <circle cx="27" cy="6" r="5" stroke-dasharray="2.5 3" opacity="0.6"/>
      </svg>`,
      desc: `The line locks where it bites and swings you rather than hauling
        you in. Cut loose to fly off on the tangent, faster than you came;
        <b>hold</b> to winch tighter, since a smaller circle is a quicker one.
        The rock swings too, wrecks what it meets, and cannot touch you.`,
    },
  });
})(ASTEROIDS);
