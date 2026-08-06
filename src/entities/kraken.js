// The kraken.
//
// It hunts whichever pilot is closest, dives into the deep, and surfaces right
// underneath you. Every hit makes it angrier: faster, redder, and quicker to
// lunge. Later waves send a whole pack, and the pack sings as one.

(function (A) {
  "use strict";

  const squids = A.squids = [];

  const KILL_SCORE = 250;
  const SURFACE_Z = 25;      // below this it can touch you, and you it
  const SHOOTABLE_Z = 40;
  const DEEP_Z = 240;
  const FOCAL = A.FOCAL = 150;  // how hard the perspective bites as it dives

  let squidTimer = 0;

  A.spawnSquid = function spawnSquid() {
    const edge = Math.floor(A.rand(0, 4));
    let x, y;
    if (edge === 0) { x = -30; y = A.rand(0, A.H); }
    else if (edge === 1) { x = A.W + 30; y = A.rand(0, A.H); }
    else if (edge === 2) { x = A.rand(0, A.W); y = -30; }
    else { x = A.rand(0, A.W); y = A.H + 30; }
    const T = A.tune();
    squids.push({
      x, y, vx: 0, vy: 0, hp: T.squidHp, maxHp: T.squidHp, radius: 21,
      phase: A.rand(0, A.TAU), roll: A.rand(0, A.TAU), flash: 0,
      windup: 0, lungeTimer: T.lungeGap, lungeBoost: 0,
      z: 0, zState: "surface", diveTimer: A.rand(T.diveGap, T.diveGap + 4), deepTimer: 0,
    });
    if (!A.warbling()) A.startWarble();
    A.shockwave(x, y, 300, 200, 400);
  };

  A.damageSquid = function damageSquid(s, n, owner) {
    if (!s || s.hp <= 0) return;
    if (owner) s.lastHitBy = owner;
    s.hp -= n;
    s.flash = 0.15;
    A.shakeBy(7);
    A.aberrate(0.5);
    if (s.hp > 0) {
      A.blip(220, 0.12, "sawtooth", 0.15);
      A.kaboom(s.x, s.y, 8, 10, 320);
      return;
    }
    A.boom(3);
    A.kaboom(s.x, s.y, 34, 16, 320, 1.6);
    A.shockwave(s.x, s.y, 320, 260, 460);
    A.shockwave(s.x, s.y, 180, 200, 300);
    A.screenFlash(320, 0.35);
    A.shakeBy(16);
    const credit = owner || s.lastHitBy || A.livePlayers()[0];
    if (credit) credit.score += KILL_SCORE;
    A.popup(s.x, s.y, "+" + KILL_SCORE, 320);
    const i = squids.indexOf(s);
    if (i >= 0) squids.splice(i, 1);
    if (!squids.length) A.stopWarble();
    squidTimer = A.rand(A.tune().squidGap, A.tune().squidGap + 8);
  };

  function reset(mode) {
    squids.length = 0;
    A.stopWarble();
    if (mode === "play") squidTimer = A.rand(10, 16);
  }

  function update(tick) {
    // the drone follows the pack even while the game is stopped, so it fades
    // rather than cutting out
    if (A.warbling()) {
      let depth = 0, rage = 0;
      for (const s of squids) {
        depth = Math.max(depth, FOCAL / (FOCAL + s.z));
        rage = Math.max(rage, s.maxHp - s.hp);
      }
      const vol = 0.05 * depth * Math.min(1.6, 0.75 + squids.length * 0.35);
      A.tuneWarble(tick.running ? vol : 0, 90 + rage * 45, 5 + rage * 3);
    }
    if (!tick.running) return;

    const dt = tick.dt;
    const T = A.tune();
    for (const s of squids) {
      const rage = s.maxHp - s.hp;
      const prey = A.nearestShip(s.x, s.y);   // each one stalks its own pilot
      s.phase += dt * (1 + rage * 0.3);
      s.roll += dt * (0.9 + rage * 0.4);
      s.flash = Math.max(0, s.flash - dt);
      s.lungeBoost = Math.max(0, s.lungeBoost - dt);

      if (s.zState === "down") {
        s.z += 350 * dt;
        if (s.z >= DEEP_Z) { s.z = DEEP_Z; s.zState = "deep"; s.deepTimer = A.rand(2, 3.5); }
      } else if (s.zState === "deep") {
        s.deepTimer -= dt;
        if (prey) {
          const dx = prey.x - s.x, dy = prey.y - s.y;
          const d = Math.hypot(dx, dy) || 1;
          s.vx += (dx / d) * 240 * dt;
          s.vy += (dy / d) * 240 * dt;
        }
        if (s.deepTimer <= 0) s.zState = "up";
      } else if (s.zState === "up") {
        s.z -= 300 * dt;
        if (s.z <= 0) {
          s.z = 0;
          s.zState = "surface";
          s.diveTimer = A.rand(T.diveGap, T.diveGap + 4);
          s.lungeTimer = Math.min(s.lungeTimer, 1);
          A.shockwave(s.x, s.y, 320, 220, 380);
          A.shakeBy(8);
        }
      } else if (s.windup > 0) {
        s.windup -= dt;
        const brake = Math.pow(0.05, dt);
        s.vx *= brake;
        s.vy *= brake;
        if (s.windup <= 0 && prey) {
          const dx = prey.x - s.x, dy = prey.y - s.y;
          const d = Math.hypot(dx, dy) || 1;
          const burst = 300 + rage * 90;
          s.vx += (dx / d) * burst;
          s.vy += (dy / d) * burst;
          s.lungeBoost = 0.7;
          A.blip(150 + rage * 40, 0.25, "sawtooth", 0.18);
          A.shakeBy(6);
        }
      } else {
        s.diveTimer -= dt;
        if (s.diveTimer <= 0) {
          s.zState = "down";
        } else if (prey) {
          const dx = prey.x - s.x, dy = prey.y - s.y;
          const d = Math.hypot(dx, dy) || 1;
          const accel = T.squidAccel * (1 + rage * 0.3);
          s.vx += (dx / d) * accel * dt;
          s.vy += (dy / d) * accel * dt;
          s.lungeTimer -= dt;
          if (s.lungeTimer <= 0) {
            s.windup = 0.45;
            s.lungeTimer = T.lungeGap + A.rand(0, 1.4) - rage * 0.4;
          }
        }
        const dir = Math.atan2(s.vy, s.vx);
        const sway = Math.sin(s.phase * 2.2) * 30;
        s.vx += Math.cos(dir + Math.PI / 2) * sway * dt;
        s.vy += Math.sin(dir + Math.PI / 2) * sway * dt;
      }

      const maxV = s.zState === "deep" ? 300
        : T.squidSpeed * (1 + rage * 0.35) * (s.lungeBoost > 0 ? 2.2 : 1);
      const v = Math.hypot(s.vx, s.vy);
      if (v > maxV) { s.vx *= maxV / v; s.vy *= maxV / v; }
      s.x += s.vx * dt;
      s.y += s.vy * dt;
      A.wrap(s);
    }

    if (squids.length < T.maxSquids) {
      squidTimer -= dt;
      if (squidTimer <= 0) {
        A.spawnSquid();
        squidTimer = A.rand(T.squidGap, T.squidGap + 8);
      }
    }
  }

  function resolve() {
    // bullet vs kraken — only when it's near the play plane
    for (const s of squids.slice()) {
      if (s.z >= SHOOTABLE_Z) continue;
      for (let j = A.bullets.length - 1; j >= 0; j--) {
        const b = A.bullets[j];
        if (Math.hypot(s.x - b.x, s.y - b.y) < s.radius + 6) {
          A.bullets.splice(j, 1);
          A.damageSquid(s, 1, b.owner);
          break;
        }
      }
    }
    // ship vs kraken — a submerged one passes harmlessly beneath you
    for (const p of A.flyingShips()) {
      if (p.invuln > 0) continue;
      for (const s of squids) {
        if (s.z >= SURFACE_Z) continue;
        if (Math.hypot(s.x - p.x, s.y - p.y) < s.radius + 10 + p.radius * 0.7) {
          A.killShip(p);
          break;
        }
      }
    }
  }

  // ---------- drawing ----------
  // 3D helpers: roll around the travel axis, tilt toward the viewer, then
  // perspective-project onto the playfield.
  function rot3(p, roll, tilt) {
    const x = p[0] * Math.cos(roll) + p[2] * Math.sin(roll);
    const z = -p[0] * Math.sin(roll) + p[2] * Math.cos(roll);
    const y = p[1] * Math.cos(tilt) - z * Math.sin(tilt);
    const z2 = p[1] * Math.sin(tilt) + z * Math.cos(tilt);
    return [x, y, z2];
  }

  function proj(p) {
    const k = FOCAL / (FOCAL + p[2]);
    return [p[0] * k, p[1] * k, p[2]];
  }

  function drawSquid(s, g) {
    const rage = s.maxHp - s.hp;
    const enraged = rage >= s.maxHp - 1;
    const tilt = -0.4 + Math.sin(s.phase * 1.3) * 0.12;
    const thrash = 3 + rage * 1.5;
    const flare = s.windup > 0 ? 1.9 : 1;
    const R = 17;
    const lines = [];

    for (const lat of [0.1, 0.75, 1.25]) {
      const ring = [];
      const r = R * Math.cos(lat), y = -R * Math.sin(lat);
      for (let i = 0; i <= 12; i++) {
        const a = (i / 12) * A.TAU;
        ring.push([Math.cos(a) * r, y, Math.sin(a) * r]);
      }
      lines.push(ring);
    }
    for (let k = 0; k < 6; k++) {
      const az = (k / 6) * A.TAU;
      const arc = [];
      for (let i = 0; i <= 5; i++) {
        const lat = (i / 5) * (Math.PI / 2);
        const r = R * Math.cos(lat), y = -R * Math.sin(lat);
        arc.push([Math.cos(az) * r, y, Math.sin(az) * r]);
      }
      lines.push(arc);
    }
    for (let k = 0; k < 6; k++) {
      const az = (k / 6) * A.TAU + 0.5;
      const tent = [[Math.cos(az) * 11, 4, Math.sin(az) * 11]];
      for (let i = 1; i <= 6; i++) {
        const radial = 11 + Math.sin(s.phase * thrash + k * 1.1 + i * 0.9) * i * 1.6 * flare;
        const tang = Math.cos(s.phase * thrash * 0.8 + k * 2.1 + i * 0.7) * i * 1.4 * flare;
        tent.push([
          Math.cos(az) * radial - Math.sin(az) * tang,
          4 + i * 6.6,
          Math.sin(az) * radial + Math.cos(az) * tang,
        ]);
      }
      lines.push(tent);
    }

    // rage drags its color from violet toward a screaming red
    const baseHue = 300 - rage * 45 + Math.sin(s.phase * 2) * 20;
    const body = s.flash > 0 || s.windup > 0
      ? A.neon(A.hue * 4, 80)
      : enraged && Math.sin(s.phase * 9) > 0
        ? A.neon(baseHue - 20, 70)
        : A.neon(baseHue, 60);

    const kz = FOCAL / (FOCAL + s.z);
    const depthA = 0.3 + 0.7 * kz;

    g.save();
    g.translate(s.x, s.y);
    g.rotate(Math.atan2(s.vy, s.vx) + Math.PI / 2);
    g.scale(kz, kz);
    A.glow(body);
    g.lineCap = "round";

    // one stroke per polyline, depth-cued by its average z
    for (const line of lines) {
      const pts = line.map((p) => proj(rot3(p, s.roll, tilt)));
      let zSum = 0;
      for (const p of pts) zSum += p[2];
      const near = Math.max(0, Math.min(1, (28 - zSum / pts.length) / 56));
      g.globalAlpha = (0.3 + 0.7 * near) * depthA;
      g.lineWidth = 1 + 1.1 * near;
      g.beginPath();
      g.moveTo(pts[0][0], pts[0][1]);
      for (let i = 1; i < pts.length; i++) g.lineTo(pts[i][0], pts[i][1]);
      g.stroke();
    }
    g.globalAlpha = depthA;

    // the glare stays locked on you while the body rolls
    const eye = enraged ? A.neon(10, 60) : A.neon(35, 60);
    A.glow(eye);
    g.fillStyle = eye;
    g.lineWidth = 2.2;
    const ey = -6;
    const er = (enraged ? 2.8 : 2.1) + Math.sin(s.phase * 6) * 0.25;
    g.beginPath();
    g.moveTo(-6 + er, ey);
    g.arc(-6, ey, er, 0, A.TAU);
    g.moveTo(6 + er, ey);
    g.arc(6, ey, er, 0, A.TAU);
    g.fill();
    g.beginPath();
    g.moveTo(-11, ey - 8);
    g.lineTo(-2, ey - 3.5);
    g.moveTo(11, ey - 8);
    g.lineTo(2, ey - 3.5);
    g.stroke();
    g.globalAlpha = 1;
    g.restore();
  }

  // A diving kraken passes *behind* the rocks and a surfacing one in front of
  // them, so it draws in two passes with the field in between.
  const DEPTH_SPLIT = 30;

  function drawDeep(tick, g) {
    if (!tick.running) return;
    for (const s of squids) if (s.z > DEPTH_SPLIT) drawSquid(s, g);
  }

  function drawSurface(tick, g) {
    if (!tick.running) return;
    for (const s of squids) if (s.z <= DEPTH_SPLIT) drawSquid(s, g);
  }

  A.register([
    {
      id: "kraken",
      order: { update: 40, resolve: 20, draw: 30, guide: 40 },
      reset, update, resolve, draw: drawDeep,
      guide: {
        name: "KRAKEN",
        meta: "250 &middot; 3&ndash;5 hits",
        tint: "var(--magenta)",
        icon: `<svg width="34" height="34" viewBox="0 0 34 34" fill="none" stroke="currentColor" stroke-width="1.3" aria-hidden="true">
          <path d="M6 17 A11 11 0 0 1 28 17" stroke-linecap="round"/>
          <path d="M6 17 h22" opacity="0.45"/>
          <path d="M8 17 q-2 5 1 8 M13.5 17 q-2 6 1 9 M20.5 17 q2 6 -1 9 M26 17 q2 5 -1 8" stroke-linecap="round"/>
          <circle cx="13" cy="12" r="1.6" fill="#ffb020" stroke="none"/>
          <circle cx="21" cy="12" r="1.6" fill="#ffb020" stroke="none"/>
          <path d="M10 8.5 L15.5 10.5 M24 8.5 L18.5 10.5" stroke="#ffb020" stroke-linecap="round"/>
        </svg>`,
        desc: `Hunts you, dives into the deep, then surfaces right beneath you.
          Angrier with every hit &mdash; and later waves send a whole pack.`,
      },
    },
    { id: "kraken:surface", order: { draw: 50 }, draw: drawSurface },
  ]);
})(ASTEROIDS);
