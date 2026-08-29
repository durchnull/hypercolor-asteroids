// The tally. What a bent rule costs, in the field rather than on paper.
//
// game/ledger.js holds one number per pilot, read off the git history by
// tools/tally.sh: an override line is worth one, going round the referee is
// worth two. Nobody types those numbers and nobody can edit their own, which
// is the only reason it is worth wiring them to anything. See GR12.
//
// What the number buys you is a less patient field. Events come sooner, and
// past THEIRS they stop making the one exception GR11 grants everybody — your
// own events start recognising you as the target rather than the author.
//
// The field also forgives, without forgetting: every MERCY clean versions a
// pilot lands after their last bend take one bend back out of the arithmetic.
// The record never moves — the marks on the wall stay — but heat, crowding
// and the armed-own-events line all read the eased number. The next bend
// resets the clean count and the whole discount with it.
//
// Deliberately capped at both ends. One bend is a nuisance and ten bends are
// the same nuisance plus your own events; nothing here can make a wave
// unsurvivable, and nothing here touches anybody else's field. GR8 still
// applies to punishments.

(function (A) {
  "use strict";

  const PER_BEND = 0.18;   // how much sooner events come, per bend
  const FLOOR = 0.5;       // and never more than twice as often, whatever you do
  const THEIRS = 3;        // bends before your own events stop sparing you
  const CROWD = 4;         // bends before a wave may hold one more ambush
  const MERCY = 3;         // clean versions since the last bend, per bend eased

  const row = (name) => (A.LEDGER || {})[name === undefined ? A.activePilot() : name];

  const eased = (name) => {
    const r = row(name);
    if (!r) return 0;
    return Math.max(0, Math.max(0, r.bends | 0) - Math.floor(Math.max(0, r.clean | 0) / MERCY));
  };

  A.pilotBends = function pilotBends(name) {
    const r = row(name);
    return r ? Math.max(0, r.bends | 0) : 0;
  };

  /** The number the field actually charges: the record, minus earned mercy. */
  A.pilotHeatBends = function pilotHeatBends(name) {
    return eased(name);
  };

  /** What they bent last, for the splash screen. "GR6", or the referee itself. */
  A.pilotLastBend = function pilotLastBend(name) {
    const r = row(name);
    return r ? r.last || "" : "";
  };

  /** Gap multiplier for the events director. 1 is an honest pilot's field. */
  A.eventHeat = function eventHeat() {
    return Math.max(FLOOR, 1 / (1 + PER_BEND * eased()));
  };

  /** How many extra ambushes a wave may hold. Zero, or one. */
  A.eventQuotaBonus = function eventQuotaBonus() {
    return eased() >= CROWD ? 1 : 0;
  };

  /** GR11 spares you your own events. This is the one thing that takes it back. */
  A.ownEventsArmed = function ownEventsArmed() {
    return eased() >= THEIRS;
  };

  // The marks, bottom left, dim enough to ignore and present enough to notice
  // on the third one. Nothing explains them in the field — the guide does that,
  // and the splash screen says it in words before you press ENTER.
  function draw(tick, g) {
    const n = A.pilotBends();
    if (!n || !tick.running) return;

    const armed = A.ownEventsArmed();
    const shown = Math.min(n, 12);
    const h = 13, w = 5, x0 = 22, y0 = A.H - 26;

    g.save();
    g.lineWidth = 1.6;
    g.globalAlpha = armed ? 0.55 + 0.2 * Math.sin(tick.time * 2.4) : 0.4;
    A.glow(A.neon(A.hue + (armed ? 320 : 200), 62));

    g.beginPath();
    for (let i = 0; i < shown; i++) {
      // four upright and a slash through them, the way a wall gets counted
      const group = Math.floor(i / 5), k = i % 5;
      const x = x0 + group * (w * 5 + 9) + k * w;
      if (k === 4) {
        g.moveTo(x - w * 4 - 2, y0 + h + 2);
        g.lineTo(x + 2, y0 - 2);
      } else {
        g.moveTo(x, y0);
        g.lineTo(x, y0 + h);
      }
    }
    g.stroke();
    g.restore();
    g.globalAlpha = 1;
  }

  A.register({
    id: "tally",
    order: { draw: 92, guide: 92 },
    draw,
    guide: {
      name: "THE TALLY",
      meta: "earned",
      tint: "var(--magenta)",
      icon: `<svg width="34" height="34" viewBox="0 0 34 34" fill="none"
        stroke="currentColor" stroke-width="1.6" stroke-linecap="round">
        <path d="M9 9v16M14 9v16M19 9v16M24 9v16M6 26L27 8"/></svg>`,
      desc: `Every rule a pilot bends is counted, by a machine, off the history.
        The field comes for them quicker &mdash; and at three, their own events
        stop making an exception. Three clean versions landed since the last
        bend ease it all by one; the marks stay on the wall.`,
    },
  });
})(ASTEROIDS);
