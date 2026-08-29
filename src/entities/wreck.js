// The wreck. The flight above yours on the board, adrift in the field.
//
// Everything this cabinet has built around the tapes — the seal, the rankings,
// the board on the splash — reaches the field through exactly one wire: the
// bounty hurries the ambushes along for whoever is top (game/bounty.js). This
// is the second wire, and it goes the other way: instead of the board changing
// the field, the board turns up *in* it, as an object you can fly to.
//
// Which flight is not a question about waves, it is a question about rank. The
// hull adrift is always the row immediately above your live score, and it
// arrives on the wave that flight died on — or straight away, if you are
// already deeper than they ever got. Break it and the next row up queues.
// Spawning by wave instead would pile ten hulls onto wave four, where most
// evenings end, and leave wave twelve empty; spawning by rank spreads the same
// ten across the whole run, in the order you will meet them, one at a time.
//
// The wager, and GR8 out loud because that rule is on our honour:
//
//   - it is a choice and never an imposition. The hull cannot collide with
//     anything, cannot be shot, and will not hurt you. Ignore it and it drifts.
//   - a cost and a power in the same object. Carrying pays a share of
//     everything you earn; carrying also makes you heavy, and heavy is how the
//     evening ends. Nobody gets the payment without the handling.
//   - and a way to fold. Clearing a wave banks what the share has paid so far,
//     so the bet is re-taken every wave rather than locked in for the evening.
//   - finite, and no ramp. One hull in the field at a time, one row each, and
//     the share is a flat number whether you are chasing a genius or a shrug.
//   - both seats fly the same field. Either can hook it; whoever gets there
//     first carries it; the other one is welcome to have been quicker.
//   - the way out is somebody else having a better evening than you, exactly
//     as it is for the bounty. Get to the top of the board and nothing comes
//     for you at all, which is its own kind of quiet.
//
// No board, no wrecks. A clone that has never run tools/chronicle.sh has no
// A.BOARD, and this does nothing at all until the first sealed tape lands —
// the same graceful absence the splash screen and the bounty already have.

(function (A) {
  "use strict";

  const ARRIVE = 5;      // seconds into a qualifying wave before a hull drifts in
  const RETURN = 20;     // and before the next one does, once this one is settled
  const SHARE = 0.6;     // extra score, as a share of what you earn carrying
  const HEAVY = 0.62;    // per-second drag on a ship with salvage aboard
  const RADIUS = 17;     // the hull itself, for wrapping round the edge
  const GRAB = 26;       // and the ring round it, which is the reach of the claw
  const DRIFT = 30;      // px/s a dead hull tumbles across the field

  // The hull in the field is a public fact, the way A.planet is: anybody's
  // feature can see it is there, and an event could one day do something about
  // it. Null most of the time, which is the ordinary case.
  A.wreck = null;

  let wait = ARRIVE;     // until the next one may arrive
  let since = 0;         // seconds this wave has been running
  let atLevel = 0;       // which wave that was, so a new one restarts the clock

  // Salvage rides on the pilot, not in the field: the claw brings the tape home
  // and the hull is gone. That is the whole reason there is no towing physics
  // in here — a line that hauls is not what entities/hook.js does, and teaching
  // it to would be rebuilding somebody's feature to suit mine.
  const carried = new Map();   // player -> { row, target, from, paid }
  const spent = [];            // rows broken this run, so none comes round twice

  /** "David Friedrich" -> "D. FRIEDRICH", which is what fits beside a hull. */
  function shortName(n) {
    const parts = String(n || "").trim().split(/\s+/);
    if (!parts[0]) return "UNKNOWN";
    const last = parts[parts.length - 1].toUpperCase();
    return parts.length > 1 ? parts[0][0].toUpperCase() + ". " + last : last;
  }

  /** The best score in the room right now — the run's standing, not a seat's. */
  function roomBest() {
    let best = 0;
    for (const p of A.livePlayers()) best = Math.max(best, p.score);
    return best;
  }

  // The row immediately above the room. A.BOARD comes down sorted, but this
  // does not lean on that: it asks for the smallest score still ahead of you,
  // which is the same answer however the board arrives.
  function nextRow() {
    const best = roomBest();
    let pick = null;
    for (const r of (A.BOARD || [])) {
      const s = Number(r.score);
      if (!isFinite(s) || s <= best) continue;
      if (spent.indexOf(r) !== -1) continue;
      if (!pick || s < Number(pick.score)) pick = r;
    }
    return pick;
  }

  function offer() {
    wait = 1;                                  // ask again in a second either way
    const row = nextRow();
    if (!row) return;                          // nobody above you: nothing comes
    if (A.game.level < Number(row.wave)) return;
    if (since < ARRIVE) return;                // clear of the wave banner

    const edge = Math.floor(A.rand(0, 4));
    const a = A.rand(0, A.TAU);
    A.wreck = {
      row,
      radius: RADIUS,
      x: edge === 0 ? -RADIUS : edge === 1 ? A.W + RADIUS : A.rand(0, A.W),
      y: edge === 2 ? -RADIUS : edge === 3 ? A.H + RADIUS : A.rand(0, A.H),
      vx: Math.cos(a) * DRIFT,
      vy: Math.sin(a) * DRIFT,
      angle: A.rand(0, A.TAU),
      spin: A.rand(-0.5, 0.5),
      age: 0,
      // the pieces that came off, each drifting round at its own rate so the
      // whole thing never reads as one rigid object
      shards: [0, 1, 2].map(() => ({
        a: A.rand(0, A.TAU), r: A.rand(24, 40), len: A.rand(4, 9),
        t: A.rand(0, A.TAU), d: A.rand(0.3, 1.6),
      })),
    };
    A.showBanner("SALVAGE ADRIFT", shortName(row.pilot) + "  " + row.score, 2.4);
    A.blip(210, 0.5, "sine", 0.09);
  }

  // A hook still in flight takes it. Deliberately read off the hook rather than
  // wired into entities/hook.js: the claw already knows where it is, and a
  // target that catches itself is one less hand in somebody else's file.
  function catchIt(dt) {
    for (const p of A.flyingShips()) {
      if (carried.has(p)) continue;
      const h = p.hook;
      if (!h || h.state !== "flying") continue;
      if (!swept(h, dt, A.wreck.x, A.wreck.y, GRAB)) continue;
      claim(p);
      return;
    }
  }

  // The claw crosses fifteen pixels in a frame and a hull is a small thing, so
  // asking only where the claw *is* throws away catches the pilot watched
  // happen. This asks where it has *been* since the last frame — the whole
  // swept step against the ring drawn round the hull, which is why that ring
  // is exactly this size. What you can see is what you can catch.
  function swept(h, dt, x, y, r) {
    const px = h.x - h.vx * dt, py = h.y - h.vy * dt;
    const dx = h.x - px, dy = h.y - py;
    const len = dx * dx + dy * dy;
    // a claw that wrapped round the edge this frame did not sweep the middle
    // of the screen on the way, whatever the arithmetic says
    if (len > 40000) return Math.hypot(h.x - x, h.y - y) <= r;
    let t = len ? ((x - px) * dx + (y - py) * dy) / len : 0;
    t = Math.max(0, Math.min(1, t));
    return Math.hypot(px + dx * t - x, py + dy * t - y) <= r;
  }

  function claim(p) {
    const row = A.wreck.row;
    A.kaboom(A.wreck.x, A.wreck.y, 14, 10, A.hue + 200);
    A.shockwave(A.wreck.x, A.wreck.y, A.hue + p.hue, 130, 300);
    A.shakeBy(7);
    A.blip(300, 0.24, "sawtooth", 0.11);
    A.wreck = null;
    p.hook = null;                 // the claw comes home with the tape on it
    p.hookCooldown = 0.3;
    carried.set(p, { row, target: Number(row.score), from: p.score, paid: 0 });
    A.showBanner("SALVAGE ABOARD", shortName(row.pilot) + "  " + row.score, 2.2);
  }

  // Passed them. The tape is worth what it is worth and the hull is finished.
  function crack(p, s) {
    carried.delete(p);
    spent.push(s.row);
    wait = RETURN;
    A.showBanner("PASSED " + shortName(s.row.pilot), String(s.target), 2.6);
    A.popup(p.x, p.y - 30, "SALVAGE +" + s.paid, A.hue + p.hue);
    A.kaboom(p.x, p.y, 22, 16, A.hue + 60, 1.4);
    A.shockwave(p.x, p.y, A.hue + p.hue, 260, 430);
    A.screenFlash(A.hue + 60, 0.22);
    A.shakeBy(12);
    A.blip(720, 0.45, "triangle", 0.12);
  }

  // The wave ended with it still aboard, so the share so far stops being at
  // risk and the meter starts again from here.
  //
  // This is the only way to fold, and the feature needs one: a bet with no way
  // out is not a decision, it is a snare with a number on it. Passing a flight
  // outright is the jackpot and most evenings will not get there — what makes
  // carrying one worth doing every wave is that each wave you survive is
  // banked. It also puts the question somewhere good. One rock left on the
  // field, eight hundred unbanked, and going to fetch it is suddenly worth
  // thinking about.
  function bank(p, s) {
    if (s.paid > 0) A.popup(p.x, p.y - 46, "BANKED +" + s.paid, A.hue + p.hue);
    s.from = p.score;
    s.paid = 0;
  }

  // Died with it aboard. The unbanked share goes back: what you keep is the
  // score you would have had without this wave's wager. The hull itself drifts
  // in again later — a bet you lost is not a door that closes, and deleting
  // the row would punish the worse pilot twice for being the worse pilot.
  function lose(p, s) {
    carried.delete(p);
    wait = RETURN;
    if (s.paid <= 0) return;
    p.score = Math.max(0, p.score - s.paid);
    A.popup(p.x, p.y - 30, "SALVAGE LOST " + s.paid, A.hue + 200);
  }

  function reset(mode) {
    A.wreck = null;
    carried.clear();
    wait = ARRIVE;
    since = 0;
    atLevel = 0;
    if (mode === "play") spent.length = 0;
  }

  function update(tick) {
    if (!tick.running) return;
    const dt = tick.dt;

    if (A.game.level !== atLevel) {
      atLevel = A.game.level;
      since = 0;
      for (const [p, s] of carried) if (!p.dead && !p.out) bank(p, s);
    }
    since += dt;

    if (A.wreck) {
      A.wreck.age += dt;
      A.wreck.x += A.wreck.vx * dt;
      A.wreck.y += A.wreck.vy * dt;
      A.wreck.angle += A.wreck.spin * dt;
      A.wrap(A.wreck);
      catchIt(dt);
    } else if (!carried.size) {   // one hull in the field or in a hand, never two
      wait -= dt;
      if (wait <= 0) offer();
    }

    for (const p of A.players) {
      if (!p) continue;
      const s = carried.get(p);
      if (!s) continue;
      if (p.out || p.dead) { lose(p, s); continue; }

      // Heavy. Not while the line is taut, though — a swing is the grapple's
      // physics and this has no business reaching inside it. So the tactic the
      // weight leaves you is the hook: carrying salvage, the field becomes the
      // only engine you have that still answers properly.
      if (!(p.hook && p.hook.state === "attached")) {
        const k = Math.pow(HEAVY, dt);
        p.vx *= k;
        p.vy *= k;
      }

      // The share, topped up every frame off what has actually been earned
      // since the claim. p.score already carries what has been paid, so the
      // raw earnings are what is left once that is taken back out.
      const raw = p.score - s.from - s.paid;
      const owed = Math.max(0, Math.round(raw * SHARE));
      p.score += owed - s.paid;
      s.paid = owed;

      if (p.score >= s.target) crack(p, s);
    }
  }

  // A dead hull: the same outline the seat cards and the field print, torn
  // open down the nose and turning.
  //
  // Drawn almost colourless, which is the one deliberate act of restraint in
  // this file. Everything else on the glass takes its hue off the drift and
  // burns, so the only way to say *nobody is flying this* in a language the
  // eye reads before the brain does is to be the one thing out here that is
  // not lit up. It must never be mistaken for a live ship, least of all for
  // the other seat.
  function drawHull(g, x, y, angle, scale, alpha) {
    const H = A.SHIP_HULL;
    g.save();
    g.translate(x, y);
    g.rotate(angle);
    g.scale(scale, scale);
    g.globalAlpha = alpha;
    A.glow(A.neon(A.hue + 190, 70, 1, 20));      // bone, not neon
    g.lineWidth = 1.6 / scale;
    g.beginPath();                       // the flanks and the tail notch
    g.moveTo(H[3][0], H[3][1]);
    g.lineTo(H[2][0], H[2][1]);
    g.lineTo(H[1][0], H[1][1]);
    g.stroke();
    g.beginPath();                       // and the two stubs where the nose was
    g.moveTo(H[1][0], H[1][1]);
    g.lineTo(H[0][0] + 3.5, H[0][1] * 0.42);
    g.stroke();
    g.beginPath();
    g.moveTo(H[3][0], H[3][1]);
    g.lineTo(H[0][0] - 2.5, H[0][1] * 0.66);
    g.stroke();
    // the nose itself, off on its own and never coming back
    g.beginPath();
    g.moveTo(H[0][0] - 4, H[0][1] - 5);
    g.lineTo(H[0][0] + 2, H[0][1] - 9);
    g.stroke();
    g.restore();
    g.globalAlpha = 1;
  }

  // The same restraint as the flat hull, by the only means the renderer has:
  // it offers no saturation to drain, so the deadness is bought with a low
  // light over almost no body — a live ship keeps 0.13 of the key light and
  // this keeps 0.05, which is the difference between a hull and the silhouette
  // of one. The shape says it a second time. No canopy peak and no keel, one
  // caved-in ridge over a flat plate, a ragged diagonal where the nose was, and
  // fewer edges than a live ship rather than more.
  const hulk = () => A.mesh.get("wreck:hull", () => {
    const [N, R, T, L] = A.SHIP_HULL;
    const deck = -1.6;                       // the outline sits under the plane
    const verts = [
      [R[0], R[1], deck], [T[0], T[1], deck], [L[0], L[1], deck],
      [N[0] + 3.5, N[1] * 0.42, deck],       // 3, the stub on the right
      [N[0] - 2.5, N[1] * 0.66, deck],       // 4, the longer one on the left
      [0, 1, 3.2],                           // 5, what is left of the deck
    ];
    return A.mesh.build(verts, [
      [3, 0, 5], [0, 1, 5], [1, 2, 5], [2, 4, 5], [4, 2, 1, 0, 3],
    ]);
  });

  // The nose, off on its own and never coming back — line only, and canted out
  // of the plane so it reads as adrift rather than as part of the hull.
  const nose = () => A.mesh.get("wreck:nose", () => {
    const N = A.SHIP_HULL[0];
    return A.mesh.wire([[N[0] - 4, N[1] - 5, 0, N[0] + 2, N[1] - 9, 2.4]]);
  });

  const at = {};

  function hulk3d(s, x, y, z, angle, scale, alpha) {
    at.x = x; at.y = y; at.z = z;
    at.rx = 0; at.ry = 0; at.rz = angle;
    at.s = scale;
    // Bone, at the same twenty percent saturation the flat hull is drawn at.
    // Dimming alone was not enough: a dull magenta beside a bright magenta is
    // still the same colour, and next to a live ship this hull was reading as
    // the louder of the two — which is the one thing it must never do.
    at.hue = 190; at.light = 70; at.sat = 20;
    at.alpha = alpha; at.width = 1.3; at.dim = 0.05; at.glow = false;
    s.model(hulk(), at);
    at.light = 64; at.width = 1.1;
    s.model(nose(), at);
  }

  function draw3d(tick, s) {
    if (!tick.running) return;

    if (A.wreck) {
      const w = A.wreck;
      hulk3d(s, w.x, w.y, 0, w.angle, 1.7, 0.95);

      for (const q of w.shards) {
        const a = w.angle * q.d + q.a;
        // they swing through the plane instead of lying on it, which is what
        // makes the pieces read as adrift rather than as parked
        const z = Math.sin(a * 1.3 + q.t) * 7;
        const sx = w.x + Math.cos(a) * q.r, sy = w.y + Math.sin(a) * q.r;
        at.hue = 190; at.light = 66; at.sat = 20;
        at.alpha = 0.55; at.width = 1.2; at.glow = false;
        s.line(sx, sy, z, sx + Math.cos(a + q.t) * q.len,
          sy + Math.sin(a + q.t) * q.len, z + q.len * 0.5, at);
      }

      // Exactly GRAB and exactly on the floor. Height on this one would be a
      // promise the claw does not keep: the reach is measured in the plane, so
      // the mark has to be drawn there.
      const beat = 0.35 + 0.65 * Math.pow(Math.max(0, Math.sin(tick.time * 2.2)), 6);
      // the locator is the one thing here that is lit: it is a signal rather
      // than a hull, and it is meant to be found across a loud field
      at.hue = 40; at.light = 66; at.sat = 100; at.alpha = 0.3 + beat * 0.5;
      at.rz = 0; at.width = 1.4; at.dim = 0; at.glow = true;
      s.ring(w.x, w.y, 0, GRAB, at);
    }

    for (const p of carried.keys()) {
      if (p.dead || p.out) continue;
      const back = p.angle + Math.PI;
      // slung behind and under, so the weight is something you can see as well
      // as something you feel in the drag
      at.hue = 190; at.light = 50; at.sat = 55; at.alpha = 0.5;
      at.width = 1.1; at.glow = false;
      s.line(p.x + Math.cos(back) * 12, p.y + Math.sin(back) * 12, 0,
        p.x + Math.cos(back) * 26, p.y + Math.sin(back) * 26, -5, at);
      hulk3d(s, p.x + Math.cos(back) * 26, p.y + Math.sin(back) * 26, -5,
        p.angle + tick.time * 0.6, 0.8, 0.7);
    }
  }

  function draw(tick, g) {
    if (!tick.running) return;

    if (A.wreck) {
      const w = A.wreck;
      // The geometry has a solid above; the lettering never will, so the rest
      // of this runs either way.
      if (!A.gl.on) {
        drawHull(g, w.x, w.y, w.angle, 1.7, 0.95);

        // what came off it, still keeping station after all this time
        g.save();
        g.globalAlpha = 0.55;
        A.glow(A.neon(A.hue + 190, 66, 1, 20));
        g.lineWidth = 1.2;
        for (const s of w.shards) {
          const a = w.angle * s.d + s.a;
          const sx = w.x + Math.cos(a) * s.r, sy = w.y + Math.sin(a) * s.r;
          g.beginPath();
          g.moveTo(sx, sy);
          g.lineTo(sx + Math.cos(a + s.t) * s.len, sy + Math.sin(a + s.t) * s.len);
          g.stroke();
        }
        g.restore();
        g.globalAlpha = 1;

        // The locator, still going long after the pilot stopped. It is why a
        // hull is findable at all in a field this loud, and it is drawn at
        // exactly the reach of the claw: put the line through the ring and it
        // is yours. A hitbox nobody can see is how a fair mechanic gets a
        // reputation for cheating.
        const beat = 0.35 + 0.65 * Math.pow(Math.max(0, Math.sin(tick.time * 2.2)), 6);
        g.save();
        g.globalAlpha = 0.3 + beat * 0.5;
        A.glow(A.neon(A.hue + 40, 66));
        g.lineWidth = 1.4;
        g.beginPath();
        g.arc(w.x, w.y, GRAB, 0, A.TAU);
        g.stroke();
        g.restore();
        g.globalAlpha = 1;
      }

      // whose it was, and the number you would be taking on
      g.save();
      g.textAlign = "center";
      g.letterSpacing = "2px";
      g.font = "600 11px " + A.FONT;
      g.fillStyle = A.neon(A.hue + 190, 66, 0.85, 60);
      g.fillText(shortName(w.row.pilot), w.x, w.y + 40);
      g.font = "600 14px " + A.FONT;
      g.fillStyle = A.neon(A.hue + 40, 70, 0.9);
      g.fillText(String(w.row.score), w.x, w.y + 57);
      g.letterSpacing = "0px";
      g.restore();
    }

    for (const [p, s] of carried) {
      if (p.dead || p.out) continue;
      // it rides behind the hull, on a short line, turning as it comes
      const back = p.angle + Math.PI;
      const bx = p.x + Math.cos(back) * 26;
      const by = p.y + Math.sin(back) * 26;
      if (!A.gl.on) {
        g.save();
        A.glow(A.neon(A.hue + 190, 50, 0.5, 55));
        g.lineWidth = 1.2;
        g.beginPath();
        g.moveTo(p.x + Math.cos(back) * 12, p.y + Math.sin(back) * 12);
        g.lineTo(bx, by);
        g.stroke();
        g.restore();
        drawHull(g, bx, by, p.angle + tick.time * 0.6, 0.8, 0.7);
      }

      // The only number that matters while it is aboard, and it is written as
      // a distance rather than a total: a bare figure over your own hull reads
      // as your score, which is the one thing it is not.
      const gap = Math.max(0, s.target - p.score);
      g.save();
      g.textAlign = "center";
      g.letterSpacing = "2px";
      g.font = "600 11px " + A.FONT;
      g.fillStyle = A.neon(A.hue + 40, 70, 0.9);
      g.fillText(gap > 0 ? gap + " TO " + shortName(s.row.pilot) : "PASSING", p.x, p.y - 30);
      g.letterSpacing = "0px";
      g.restore();
    }
  }

  A.register({
    id: "wreck",
    order: { update: 15, draw: 35, guide: 65 },
    reset, update, draw, draw3d,
    guide: {
      name: "THE WRECK",
      meta: "grapple it",
      tint: "var(--violet)",
      icon: `<svg width="34" height="34" viewBox="0 0 34 34" fill="none"
        stroke="currentColor" stroke-width="1.5" stroke-linejoin="round">
        <path d="M8 27 L17 20 L26 27"/>
        <path d="M26 27 L20 9"/>
        <path d="M8 27 L14 12"/>
        <circle cx="17" cy="6" r="2.6" opacity="0.7"/>
      </svg>`,
      desc: `The flight one place above you on the records, adrift on the wave
        it died on. It cannot touch you. <b>Grapple</b> it and you carry their
        tape: everything you earn pays extra and you fly heavy for it. Clearing
        a wave banks what it has paid; dying hands back whatever is not banked.
        Pass their number and it breaks up in your hands.`,
    },
  });
})(ASTEROIDS);
