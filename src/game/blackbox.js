// The black box. Every flight is taped, and the tape survives the ship.
//
// While the game runs this watches everything worth counting — shots, rock
// breaks, deaths, close shaves, top speed, and every event another pilot's
// file dropped on the flight — and when the last ship dies it seals the lot
// into a tape: a short readable header over a base64 body with a checksum. The debrief panel (ui/debrief.js) puts it on the game-over
// screen with a copy button; tools/blackbox.sh reads it back on the other
// side. The seal is FNV-1a over the exact JSON bytes, so a tape edited by
// hand stops being a tape.
//
// Counting happens by wrapping the commons functions where the deeds actually
// occur (fireBullet, splitAsteroid, killShip...) rather than by asking every
// feature to report in. Additive: same names, same signatures, the original
// always runs. Wrapped once, lazily, on the first reset — by then every
// module in the manifest has loaded, so this file's position in the load
// order does not matter.

(function (A) {
  "use strict";

  const BODY_WIDTH = 48;      // base64 chars per tape line
  const SHAVE_GAP = 34;       // px beyond a killing hit that still counts
  const SHAVE_COOLDOWN = 0.8; // one shave per ship per this many seconds
  const FLURRY_WINDOW = 2.0;  // rock breaks this close together chain up

  let armed = false;
  let taping = false;
  let tape = null;            // the sealed dump, once the flight is over

  const flight = { time: 0, shaves: 0, seats: {}, events: [] };

  // The pilot-vs-pilot half of the flight: every event that fired, whose it
  // was, which wave it came on, and how many ships went down while it was
  // still in the field. The runner keeps one live entry per firing
  // (game/events.js), so entry identity is firing identity - the same trap
  // two waves apart is two rows on the tape.
  const courted = new Map();

  function court() {
    for (const l of (A.liveEvents ? A.liveEvents() : [])) {
      if (courted.has(l)) continue;
      const r = { id: l.e.id, by: l.e.by, wave: A.game.level, deaths: 0 };
      courted.set(l, r);
      flight.events.push(r);
    }
  }

  function seat(p) {
    if (!p) return null;
    let s = flight.seats[p.idx];
    if (!s) {
      s = flight.seats[p.idx] = {
        seat: A.SEATS[p.idx].tag,
        shots: 0, hits: 0,
        rocks: { large: 0, medium: 0, small: 0 }, nuked: 0,
        deaths: 0, bombs: 0, hooks: 0,
        kraken: { hits: 0, kills: 0 },
        dist: 0, top: 0, thrust: 0,
        flurry: 0, chain: 0, chainAt: -9,
        shaveAt: -9,
      };
    }
    return s;
  }

  // ---- the wiretaps -------------------------------------------------------

  function arm() {
    armed = true;

    const fireBullet = A.fireBullet;
    A.fireBullet = function (p) {
      if (taping) { const s = seat(p); if (s) s.shots++; }
      return fireBullet(p);
    };

    const splitAsteroid = A.splitAsteroid;
    A.splitAsteroid = function (a, idx, owner) {
      if (taping && owner) {
        const s = seat(owner);
        s.hits++;
        s.rocks[a.size === 3 ? "large" : a.size === 2 ? "medium" : "small"]++;
        // breaks close together chain up; the longest chain is the flurry
        s.chain = flight.time - s.chainAt <= FLURRY_WINDOW ? s.chain + 1 : 1;
        s.chainAt = flight.time;
        s.flurry = Math.max(s.flurry, s.chain);
      }
      return splitAsteroid(a, idx, owner);
    };

    const vaporiseAsteroid = A.vaporiseAsteroid;
    A.vaporiseAsteroid = function (idx, owner) {
      if (taping && owner) seat(owner).nuked++;
      return vaporiseAsteroid(idx, owner);
    };

    const killShip = A.killShip;
    A.killShip = function (p) {
      if (taping) {
        const s = seat(p);
        if (s) s.deaths++;
        // an event that fires and kills in the same frame is courted here,
        // before update() has had a look at it
        court();
        for (const l of (A.liveEvents ? A.liveEvents() : [])) {
          const r = courted.get(l);
          if (r) r.deaths++;
        }
      }
      return killShip(p);
    };

    const detonate = A.detonate;
    A.detonate = function (p) {
      const before = p ? p.bombs : 0;
      const r = detonate(p);
      // detonate refuses for its own reasons; only a spent bomb is a bomb
      if (taping && p && p.bombs < before) seat(p).bombs++;
      return r;
    };

    const fireHook = A.fireHook;
    A.fireHook = function (p) {
      if (taping) { const s = seat(p); if (s) s.hooks++; }
      return fireHook(p);
    };

    const damageSquid = A.damageSquid;
    A.damageSquid = function (sq, n, owner) {
      const before = A.squids.length;
      const r = damageSquid(sq, n, owner);
      if (taping && owner) {
        const s = seat(owner);
        s.kraken.hits++;
        if (A.squids.length < before) s.kraken.kills++;
      }
      return r;
    };
  }

  // ---- the flight itself --------------------------------------------------

  function update(tick) {
    if (!taping || !tick.running) return;
    // wall time while running: slow-mo stretches the frame, not the flight
    flight.time += tick.raw;
    court();

    for (const p of A.flyingShips()) {
      const s = seat(p);
      const sp = Math.hypot(p.vx, p.vy);
      s.dist += sp * tick.dt;
      s.top = Math.max(s.top, sp);
      if (A.keys[p.idx].thrust) s.thrust += tick.raw;

      // a close shave: a rock passed nearly close enough to have you
      if (p.invuln > 0 || flight.time - s.shaveAt < SHAVE_COOLDOWN) continue;
      for (const a of A.asteroids) {
        const d = Math.hypot(a.x - p.x, a.y - p.y);
        const kill = a.radius + p.radius * 0.7;
        if (d > kill && d < kill + SHAVE_GAP) {
          s.shaveAt = flight.time;
          flight.shaves++;
          break;
        }
      }
    }
  }

  function reset(mode) {
    if (!armed) arm();
    if (mode === "over") { seal(); return; }
    taping = mode === "play";
    tape = null;
    flight.time = 0;
    flight.shaves = 0;
    flight.seats = {};
    flight.events = [];
    courted.clear();
  }

  // ---- sealing the tape ---------------------------------------------------

  function fnv1a(bytes) {
    let h = 0x811c9dc5;
    for (const b of bytes) h = Math.imul(h ^ b, 0x01000193);
    return (h >>> 0).toString(16).padStart(8, "0");
  }

  function b64(bytes) {
    let bin = "";
    for (const b of bytes) bin += String.fromCharCode(b);
    return btoa(bin);
  }

  function clock(t) {
    const m = Math.floor(t / 60), s = Math.floor(t % 60);
    return m > 0 ? m + "m" + String(s).padStart(2, "0") + "s" : s + "s";
  }

  function seal() {
    if (!taping) return;
    taping = false;

    const joined = A.players.filter(Boolean);
    const score = joined.reduce((t, p) => Math.max(t, p.score), 0);
    const seats = joined.map((p) => {
      const s = seat(p);
      const { chain, chainAt, shaveAt, ...kept } = s;
      return { ...kept, score: p.score };
    });

    const record = {
      v: 1,
      ts: new Date().toISOString(),
      pilot: A.activePilot(),
      // The seat the cabinet was locked to, sealed beside the name that flew.
      // A flight flown under a borrowed name carries the mismatch in its own
      // tape, and tools/blackbox.sh says so out loud - GR12 says what such a
      // run is worth. No seat lock, no claim: null, and the reader admits it.
      whoami: A.LOCAL_PILOT || null,
      score,
      best: A.game.best,
      wave: A.game.level,
      time: Math.round(flight.time * 10) / 10,
      shaves: flight.shaves,
      seats,
      // The other pilots' half of the flight, in firing order. Additive: a
      // tape sealed before this existed simply has no events field, and the
      // reader says so rather than guessing.
      events: flight.events,
    };

    const json = JSON.stringify(record);
    const bytes = new TextEncoder().encode(json);
    const crc = fnv1a(bytes);
    const body = b64(bytes);

    const lines = [
      ";; ── HYPERCOLOR ASTEROIDS · BLACK BOX · FLIGHT RECORD ──",
      ";; pilot " + record.pilot + " · score " + score +
        " · wave " + record.wave + " · " + clock(record.time),
      ";; the tape survived the ship. paste all of this into",
      ";; claude code, in this repo, and say: read the black box",
    ];
    for (let i = 0; i < body.length; i += BODY_WIDTH) {
      lines.push("BB1:" + i.toString(16).padStart(4, "0") + " " +
                 body.slice(i, i + BODY_WIDTH));
    }
    lines.push("BB1:CRC " + crc + " :: END OF TAPE");

    tape = { record, text: lines.join("\n") };
  }

  A.blackboxTape = () => tape;

  // No guide tile: the tape announces itself on the game-over screen, which
  // is the only moment it matters. The field guide briefs the flight ahead
  // (see src/ui/fieldguide.js for what earns a row).
  A.register({
    id: "blackbox",
    order: { reset: 60, update: 60 },
    reset, update,
  });
})(ASTEROIDS);
