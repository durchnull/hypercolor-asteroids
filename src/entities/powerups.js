// Powerups. A crate drifts into the field, floats about for a minute, blinks
// for the last ten seconds of it and is gone. Fly through one and it is yours,
// filed in the rack under its own number; press that number and it is spent.
//
// Every number is one thing and only ever that thing, so a pilot learns them
// once: 1 is the machine gun, 2 is the turret. Seven numbers are still empty,
// and a new powerup is an entry in CATALOGUE — the crate, the rack, the HUD
// and the keys all read off it and nothing else has to be told.
//
// The GR8 argument, in the shape the atom bomb set: every one of these is
// finite. A crate is one use. One drifts in per wave, no more, and the wave
// ends whether or not anybody bothered to catch it. The machine gun runs out;
// the turret runs out; neither one makes a ship harder to kill. And the rack
// is per seat, so seat two catches and spends exactly the way seat one does —
// their numbers are the same numbers, with shift held (src/input/bindings.js).

(function (A) {
  "use strict";

  const drops = A.powerups = [];
  const towers = A.towers = [];

  const FLOAT = 60;          // seconds a crate stays in the field
  const BLINK = 10;          // the last of those, spent blinking
  const CRATE_R = 15;        // the crate's hitbox, and the box it draws
  const DRIFT = 28;          // px/s, slow enough to be a target
  const RACK = 3;            // most of any one number a seat can hold
  const ARRIVE_MIN = 4, ARRIVE_MAX = 14;   // seconds into a wave the crate shows

  const GUN_TIME = 12;       // seconds of machine gun per crate
  const GUN_RATE = 4;        // times the ordinary fire rate (entities/ship.js)

  const TOWER_LIFE = 20;     // seconds a turret stands
  const TOWER_GAP = 0.32;    // seconds between its shots
  const TOWER_RANGE = 330;   // px it will shoot to
  const TOWER_R = 12;        // its footprint on the plane
  const TOWER_H = 26;        // and its height off it
  const SHOT_SPEED = 520;
  const SHOOTABLE_Z = 40;    // entities/kraken.js: deeper than this and a shot passes over it

  // What the numbers mean. `use(p)` is the whole of a powerup's effect; the
  // rest is how it looks on a crate and on the HUD. `glyph` is the icon the
  // crate wears, as polylines in crate space (about ±10), drawn as the same
  // neon line as everything else; `svg` is the same picture for the HUD.
  // The icon is a picture of what the crate makes — a gun, a turret — so a
  // pilot who has caught one before knows the next one on sight.
  const CATALOGUE = {
    1: {
      key: 1, name: "MACHINE GUN", hue: 180,
      glyph: [
        // the gun: barrel forward, grip down
        [[-9, 1], [-9, -3], [1, -3], [1, -5.5], [10, -5.5], [10, -1], [3, -1], [3, 1], [-3, 1], [-3, 6], [-7, 6], [-7, 1], [-9, 1]],
        // and what it is putting out, three tracers ahead of the muzzle
        [[11.5, -3.2], [14, -3.2]], [[12.5, -6], [15, -7]], [[12.5, -0.4], [15, 0.6]],
      ],
      svg: '<svg width="15" height="12" viewBox="-10 -8 26 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round" stroke-linecap="round">' +
        '<path d="M-9 1v-4h10v-2.5h9v4.5h-7v2h-6v5h-4v-5z"/><path d="M11.5-3.2h2.5M12.5-6l2.5-1M12.5-.4l2.5 1"/></svg>',
      use(p) {
        p.rapid = Math.max(p.rapid || 0, 0) + GUN_TIME;
        A.blip(880, 0.12, "square", 0.12);
        A.popup(p.x, p.y - 24, "MACHINE GUN", A.hue + 180);
      },
    },
    2: {
      key: 2, name: "TURRET", hue: 40,
      glyph: [
        // the turret as it stands in the field: a hexagon with a barrel out
        // of the top, and the footprint it will hold
        [[6, 3.5], [0, 7], [-6, 3.5], [-6, -3.5], [0, -7], [6, -3.5], [6, 3.5]],
        [[0, -7], [0, -13]], [[-2, -11.5], [2, -11.5]],
        [[-10, 10], [10, 10]],
      ],
      svg: '<svg width="13" height="13" viewBox="-11 -14 22 26" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round" stroke-linecap="round">' +
        '<path d="M6 3.5L0 7l-6-3.5v-7L0-7l6 3.5z"/><path d="M0-7v-6M-2-11.5h4M-10 10h20"/></svg>',
      use(p) {
        towers.push({
          x: p.x, y: p.y, life: TOWER_LIFE, gap: 0.6, aim: p.angle,
          owner: p, phase: A.rand(0, A.TAU),
          // shots credit the turret and the turret credits the seat, so a
          // turret shot never counts against the pilot's own five in the air
          score: 0,
        });
        A.blip(140, 0.3, "sawtooth", 0.14);
        A.shockwave(p.x, p.y, A.hue + 40, 120, 260);
        A.popup(p.x, p.y - 24, "TURRET", A.hue + 40);
      },
    },
  };
  A.POWERUPS = CATALOGUE;

  const numbers = Object.keys(CATALOGUE).map(Number);

  let dropTimer = -1;        // counts down to this wave's crate; -1 is "spent"
  let lastLevel = 0;

  /** A crate for number `n`, in off an edge, or anywhere if not said. */
  A.dropPowerup = function dropPowerup(n, x, y) {
    const kind = CATALOGUE[n] || CATALOGUE[numbers[Math.floor(Math.random() * numbers.length)]];
    const dir = A.rand(0, A.TAU);
    const d = {
      kind, x: x === undefined ? A.rand(40, A.W - 40) : x, y: y === undefined ? A.rand(40, A.H - 40) : y,
      vx: Math.cos(dir) * DRIFT, vy: Math.sin(dir) * DRIFT,
      life: FLOAT, spin: A.rand(0, A.TAU), radius: CRATE_R,
    };
    drops.push(d);
    A.blip(660, 0.18, "triangle", 0.08);
    return d;
  };

  function collect(d, p) {
    const n = d.kind.key;
    p.rack = p.rack || {};
    p.rack[n] = Math.min(RACK, (p.rack[n] || 0) + 1);
    A.blip(1040, 0.14, "square", 0.1);
    A.kaboom(d.x, d.y, 10, 6, A.hue + d.kind.hue, 0.8);
    A.shockwave(d.x, d.y, A.hue + d.kind.hue, 90, 240);
    A.popup(d.x, d.y, "[" + n + "] " + d.kind.name, A.hue + d.kind.hue);
  }

  function spend(p, n) {
    const kind = CATALOGUE[n];
    if (!kind || !p.rack || !p.rack[n] || p.dead) return;
    p.rack[n]--;
    kind.use(p);
  }

  // ---- the turret ----------------------------------------------------------

  // Whose rocks it minds: the pilot who planted it, or whoever is nearest once
  // that pilot is down. A rock is a threat when it is closing on that ship.
  function ward(t) {
    if (t.owner && !t.owner.dead && !t.owner.out) return t.owner;
    return A.nearestShip(t.x, t.y);
  }

  function target(t) {
    let best = null, bestD = Infinity;
    // a kraken on the plane is the first thing a turret shoots, every time
    for (const s of A.squids) {
      if (s.z >= SHOOTABLE_Z) continue;
      const d = Math.hypot(s.x - t.x, s.y - t.y);
      if (d < TOWER_RANGE && d < bestD) { best = s; bestD = d; }
    }
    if (best) return best;
    const ship = ward(t);
    for (const a of A.asteroids) {
      if (a.arrive > 0) continue;
      const d = Math.hypot(a.x - t.x, a.y - t.y);
      if (d >= TOWER_RANGE) continue;
      if (ship) {
        // closing on the ship: velocity points along the line to it
        const dx = ship.x - a.x, dy = ship.y - a.y;
        if (a.vx * dx + a.vy * dy <= 0) continue;
      }
      if (d < bestD) { best = a; bestD = d; }
    }
    return best;
  }

  function shoot(t, o) {
    // lead the shot by the time it takes to get there, so a rock crossing at
    // speed is hit rather than followed
    const d = Math.hypot(o.x - t.x, o.y - t.y);
    const lead = d / SHOT_SPEED;
    const ax = o.x + o.vx * lead - t.x, ay = o.y + o.vy * lead - t.y;
    t.aim = Math.atan2(ay, ax);
    A.bullets.push({
      x: t.x + Math.cos(t.aim) * (TOWER_R + 4),
      y: t.y + Math.sin(t.aim) * (TOWER_R + 4),
      vx: Math.cos(t.aim) * SHOT_SPEED,
      vy: Math.sin(t.aim) * SHOT_SPEED,
      radius: 1.6, life: TOWER_RANGE / SHOT_SPEED + 0.1,
      hue: A.hue * 3 + 40,
      owner: t,
    });
    A.blip(300 + Math.random() * 60, 0.05, "square", 0.05);
  }

  // ---- the frame -----------------------------------------------------------

  function reset(mode) {
    if (mode === "over") return;
    drops.length = 0;
    towers.length = 0;
    dropTimer = -1;
    lastLevel = 0;
  }

  function update(tick) {
    if (!tick.running) return;
    const dt = tick.dt;

    // one crate per wave, some seconds after the rocks arrive
    if (A.game.level !== lastLevel) {
      lastLevel = A.game.level;
      dropTimer = A.rand(ARRIVE_MIN, ARRIVE_MAX);
    }
    if (dropTimer >= 0 && (dropTimer -= dt) < 0) A.dropPowerup();

    for (let i = drops.length - 1; i >= 0; i--) {
      const d = drops[i];
      d.x += d.vx * dt;
      d.y += d.vy * dt;
      d.spin += dt * 1.4;
      d.life -= dt;
      A.wrap(d);
      if (d.life <= 0) drops.splice(i, 1);
    }

    for (const p of A.livePlayers()) {
      if (p.rapid > 0) p.rapid -= dt;
      const key = A.keys[p.idx];
      for (const n of numbers) {
        if (key["slot" + n]) { key["slot" + n] = false; spend(p, n); }
      }
    }

    for (let i = towers.length - 1; i >= 0; i--) {
      const t = towers[i];
      t.life -= dt;
      t.phase += dt;
      // what the turret earned goes home to the seat that planted it
      if (t.score) { if (t.owner) t.owner.score += t.score; t.score = 0; }
      if (t.life <= 0) {
        A.kaboom(t.x, t.y, 12, 8, A.hue + 40, 0.9);
        A.blip(110, 0.25, "sawtooth", 0.1);
        towers.splice(i, 1);
        continue;
      }
      t.gap -= dt;
      if (t.gap > 0) continue;
      const o = target(t);
      if (o) { shoot(t, o); t.gap = TOWER_GAP; }
      else t.gap = 0.1;
    }
  }

  function resolve() {
    for (const p of A.flyingShips()) {
      for (let i = drops.length - 1; i >= 0; i--) {
        const d = drops[i];
        if (Math.hypot(d.x - p.x, d.y - p.y) < d.radius + p.radius) {
          drops.splice(i, 1);
          collect(d, p);
        }
      }
    }
  }

  // ---- the HUD -------------------------------------------------------------
  // hud.js asks these two rather than knowing what a rack is: one string that
  // changes when the panel should, and the markup for it.

  A.powerupKey = (p) => {
    if (!p) return "";
    const r = p.rack || {};
    return numbers.map((n) => r[n] || 0).join(",") + ":" + Math.ceil(p.rapid > 0 ? p.rapid : 0);
  };

  A.powerupHud = (p) => {
    if (!p || p.out) return "";
    const r = p.rack || {};
    let s = "";
    for (const n of numbers) {
      if (!r[n]) continue;
      const k = CATALOGUE[n];
      s += '<span class="slot"><b>' + n + "</b>" + k.svg + (r[n] > 1 ? "&times;" + r[n] : "") + "</span>";
    }
    if (p.rapid > 0) s += '<span class="slot live">' + CATALOGUE[1].svg + Math.ceil(p.rapid) + "s</span>";
    return s ? '<div class="glyphs rack">' + s + "</div>" : "";
  };

  // ---- drawing -------------------------------------------------------------

  const blinking = (d) => d.life < BLINK && Math.floor(d.life * 6) % 2 === 1;

  function draw(tick, g) {
    if (!tick.running || A.gl.on) return;
    for (const d of drops) {
      if (blinking(d)) continue;
      const c = A.neon(A.hue + d.kind.hue, 66);
      g.save();
      g.translate(d.x, d.y);
      g.rotate(d.spin);
      A.glow(c);
      g.lineWidth = 1.6;
      g.strokeRect(-CRATE_R, -CRATE_R, CRATE_R * 2, CRATE_R * 2);
      g.rotate(-d.spin);
      // the picture stays upright while the box turns under it
      A.glow(A.neon(A.hue + d.kind.hue, 82));
      g.lineWidth = 2;
      g.lineJoin = g.lineCap = "round";
      for (const line of d.kind.glyph) {
        g.beginPath();
        for (let i = 0; i < line.length; i++) {
          if (i) g.lineTo(line[i][0], line[i][1]); else g.moveTo(line[i][0], line[i][1]);
        }
        g.stroke();
      }
      g.restore();
    }
    for (const t of towers) {
      const f = t.life / TOWER_LIFE;
      const c = A.neon(A.hue + 40, 64);
      g.save();
      g.translate(t.x, t.y);
      A.glow(c);
      g.lineWidth = 1.8;
      g.beginPath();
      for (let i = 0; i < 6; i++) {
        const a = (i / 6) * A.TAU + t.phase * 0.5;
        const px = Math.cos(a) * TOWER_R, py = Math.sin(a) * TOWER_R;
        if (i) g.lineTo(px, py); else g.moveTo(px, py);
      }
      g.closePath();
      g.stroke();
      // the barrel, and the life left as an arc round the foot
      g.beginPath();
      g.moveTo(0, 0);
      g.lineTo(Math.cos(t.aim) * (TOWER_R + 8), Math.sin(t.aim) * (TOWER_R + 8));
      g.stroke();
      g.globalAlpha = 0.5;
      g.lineWidth = 1;
      g.beginPath();
      g.arc(0, 0, TOWER_R + 5, -Math.PI / 2, -Math.PI / 2 + f * A.TAU);
      g.stroke();
      g.restore();
    }
  }

  // A cage rather than a box: the picture sits inside it on the plane, and a
  // face that covered would hide the one thing the crate is there to say.
  const crate = () => A.mesh.get("powerup:crate", () => {
    const r = CRATE_R * 0.8, seg = [];
    for (const [a, b] of [[0, 1], [1, 2], [2, 3], [3, 0], [4, 5], [5, 6], [6, 7], [7, 4], [0, 4], [1, 5], [2, 6], [3, 7]]) {
      const c = (i) => [i & 1 ? r : -r, i & 2 ? r : -r, i & 4 ? r : -r];
      seg.push([...c(a), ...c(b)]);
    }
    return A.mesh.wire(seg);
  });
  const post = () => A.mesh.get("powerup:tower", () => {
    const out = [];
    for (let i = 0; i < 6; i++) {
      const a = (i / 6) * A.TAU;
      out.push([Math.cos(a) * TOWER_R, Math.sin(a) * TOWER_R]);
    }
    return A.mesh.prism(out, -4, TOWER_H);
  });
  const at = {};

  function draw3d(tick, s) {
    if (!tick.running) return;
    for (const d of drops) {
      if (blinking(d)) continue;
      at.x = d.x; at.y = d.y; at.z = 0; at.s = 1;
      at.rx = d.spin * 0.7; at.ry = d.spin * 0.4; at.rz = d.spin;
      at.hue = d.kind.hue; at.light = 66;
      at.alpha = 1; at.width = 1.6; at.dim = 0.12; at.glow = false;
      s.model(crate(), at);
      // the picture sits in the middle of the cage, on the plane where there is
      // no parallax to slide it, flat to the eye and never turning
      at.light = 82; at.width = 2; at.glow = true; at.dim = 0;
      for (const line of d.kind.glyph) {
        for (let i = 1; i < line.length; i++) {
          s.line(d.x + line[i - 1][0], d.y + line[i - 1][1], 0,
            d.x + line[i][0], d.y + line[i][1], 0, at);
        }
      }
    }
    for (const t of towers) {
      const f = t.life / TOWER_LIFE;
      at.x = t.x; at.y = t.y; at.z = 0; at.s = 1;
      at.rx = at.ry = 0; at.rz = t.phase * 0.5;
      at.hue = 40; at.light = 64;
      at.alpha = 1; at.width = 1.8; at.dim = 0.14; at.glow = false;
      s.model(post(), at);
      at.width = 2; at.glow = true; at.light = 72;
      s.line(t.x, t.y, TOWER_H, t.x + Math.cos(t.aim) * (TOWER_R + 8), t.y + Math.sin(t.aim) * (TOWER_R + 8), TOWER_H, at);
      at.alpha = 0.5; at.width = 1; at.dim = 0; at.rz = 0;
      s.ring(t.x, t.y, 0, (TOWER_R + 5) * Math.max(0.05, f), at);
    }
  }

  // The key it answers to, as a small tag off the crate's corner — text, so
  // it draws on the chrome pass where it is legible under either renderer.
  function chrome(tick, ctx) {
    if (!tick.running) return;
    ctx.save();
    ctx.font = "600 11px " + A.FONT;
    ctx.textAlign = "left";
    ctx.textBaseline = "middle";
    for (const d of drops) {
      if (blinking(d)) continue;
      ctx.fillStyle = A.neon(A.hue + d.kind.hue, 78);
      ctx.fillText("[" + d.kind.key + "]", d.x + CRATE_R + 6, d.y - CRATE_R - 2);
    }
    ctx.restore();
  }

  A.register({
    id: "powerups",
    order: { update: 44, resolve: 18, draw: 42, guide: 62 },
    reset, update, resolve, draw, draw3d, chrome,
    guide: {
      name: "POWERUPS",
      group: "hands",
      meta: "1 &middot; 2 &middot; one crate a wave",
      tint: "var(--mint)",
      icon: `<svg width="34" height="34" viewBox="0 0 34 34" fill="none" stroke="currentColor" stroke-width="1.3" aria-hidden="true">
        <rect x="8" y="8" width="18" height="18" transform="rotate(12 17 17)"/>
        <path d="M14.5 21.5 V12.5 L12.5 14.5" stroke-linecap="round" stroke-linejoin="round"/>
        <path d="M18 14 q0-2 2-2 t2 2 q0 1.5-4 5.5 h4.5" stroke-linecap="round" stroke-linejoin="round"/>
      </svg>`,
      desc: "A numbered crate drifts in each wave and blinks out after a minute. Fly through it, then press its number: 1 is a machine gun, 2 plants a turret.",
    },
  });
})(ASTEROIDS);
