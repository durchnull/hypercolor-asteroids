// The jump.
//
// A cleared field used to be a second and a half of nothing. The rocks were
// gone, the next wave had not arrived, and the ship sat in the dark waiting out
// a timer nobody could see. It spends that time going somewhere now: the sky
// stretches into streaks, the drive winds up behind it, and the next wave
// arrives as an arrival instead of as more rocks quietly appearing.
//
// It owns no rules and it charges nothing. The pause is the length it always
// was (src/game/waves.js), the field stays empty for exactly as long, and
// nothing in here can kill you or save you. It is the second and a half made
// worth watching, and that is the whole of it.

(function (A) {
  "use strict";

  const TAIL = 0.5;      // seconds of falling out of it after the burst
  const REACH = 0.55;    // longest a streak gets, as a fraction of its radius
  const PULL = 6.2;      // how hard the tunnel drags things outward

  let streaks = [];
  let charge = 0;        // seconds left of the wind-up
  let span = 0;          // how long that wind-up was asked to be
  let tail = 0;          // seconds left of the drop-out
  let warp = 0;          // 0..1 — the whole effect in one number

  /** For anything that wants to know whether the sky is moving. */
  A.warping = () => warp;

  // A streak is polar, because the tunnel is: an angle it never changes and a
  // radius that runs away from the middle of the screen faster the further out
  // it gets. That acceleration is the entire perspective trick — near the
  // centre things crawl, at the edges they tear past.
  function seed(s, r) {
    s.a = A.rand(0, A.TAU);
    s.r = r;
    s.sp = A.rand(0.7, 1.55);
    s.hue = A.rand(-80, 80);
    return s;
  }

  function build() {
    const n = Math.round((A.W * A.H) / 4600);
    const far = Math.hypot(A.W, A.H) / 2;
    streaks = [];
    for (let i = 0; i < n; i++) streaks.push(seed({}, A.rand(6, far)));
  }
  A.onResize(() => { if (streaks.length) build(); });

  /**
   * Punch it. `seconds` is how long the wind-up gets before the burst — the
   * caller keeps the clock, because the caller is the one that knows what the
   * ship is waiting for.
   */
  A.lightspeed = function lightspeed(seconds) {
    span = charge = Math.max(0.25, seconds);
    tail = 0;
    if (!streaks.length) build();
    A.lightspeedSound(span);
  };

  // Arrival. The picture side of it — the noise was scheduled the moment the
  // jump began, because Web Audio would rather be told early.
  function burst() {
    A.screenFlash(A.hue + 170, 0.6);
    A.shockwave(A.W / 2, A.H / 2, A.hue + 170, Math.max(A.W, A.H) * 1.1, 2200);
    A.kaboom(A.W / 2, A.H / 2, 22, 10, A.hue + 170, 3);
    A.shakeBy(10);
    A.aberrate(1.2);
  }

  function update(tick) {
    const dt = tick.dt;
    if (charge > 0) {
      charge = Math.max(0, charge - dt);
      const f = 1 - charge / span;
      warp = f * f;              // eased in, so it winds up rather than switches on
      if (charge === 0) { tail = TAIL; burst(); }
    } else if (tail > 0) {
      tail = Math.max(0, tail - dt);
      warp = tail / TAIL;
    } else {
      warp = 0;
      return;
    }

    A.aberrate(warp * 0.85);
    A.shakeBy(warp * warp * 4);

    const far = Math.hypot(A.W, A.H) / 2;
    for (const s of streaks) {
      s.r += (s.r + 24) * s.sp * warp * PULL * dt;
      if (s.r > far * 1.2) seed(s, A.rand(4, 30));
    }
  }

  function draw(tick, g) {
    if (warp <= 0.002) return;
    const cx = A.W / 2, cy = A.H / 2;

    // the mouth of the tunnel, brightening as the drive winds up
    const core = warp * warp * Math.min(A.W, A.H) * 0.22;
    if (core > 2) {
      const grad = g.createRadialGradient(cx, cy, 0, cx, cy, core);
      grad.addColorStop(0, A.neon(A.hue + 150, 88, 0.55 * warp));
      grad.addColorStop(0.45, A.neon(A.hue + 180, 70, 0.2 * warp));
      grad.addColorStop(1, "rgba(0,0,0,0)");
      g.fillStyle = grad;
      g.fillRect(cx - core, cy - core, core * 2, core * 2);
    }

    // One flat loop, no per-streak save/restore — the same bargain effects.js
    // makes with its shards, for the same reason: there are a lot of these.
    g.lineCap = "round";
    const light = 58 + warp * 32;
    for (const s of streaks) {
      const len = Math.min(s.r * REACH * warp * s.sp, s.r - 2);
      if (len < 1.2) continue;
      const dx = Math.cos(s.a), dy = Math.sin(s.a);
      g.globalAlpha = Math.min(1, warp * 1.3) * Math.min(1, s.r / 70);
      g.strokeStyle = A.neon(A.hue + s.hue, light);
      g.lineWidth = 1 + warp * s.sp * 1.7;
      g.beginPath();
      g.moveTo(cx + dx * (s.r - len), cy + dy * (s.r - len));
      g.lineTo(cx + dx * s.r, cy + dy * s.r);
      g.stroke();
    }
    g.globalAlpha = 1;
  }

  function reset(mode) {
    // Died mid-jump: there is no arrival, so fall out of it rather than have
    // the sky stop dead behind the game-over panel.
    if (mode === "over") {
      // Picked up where the wind-up got to, not at the top of it: a flat TAIL
      // here would snap a half-grown sky out to full length on the frame the
      // pilot died, which is a bang the evening did not earn.
      if (charge > 0) { charge = 0; tail = warp * TAIL; }
      return;
    }
    charge = tail = warp = 0;
  }

  // No guide tile: the jump is not a thing a pilot does, it is a thing that
  // happens to them between waves. The guide briefs you on what you can press
  // and what can kill you, and this is neither.
  A.register({ id: "lightspeed", order: { update: 12, draw: 4 }, reset, update, draw });
})(ASTEROIDS);
