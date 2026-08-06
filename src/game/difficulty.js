// The ramp, in one place.
//
// Everything that scales with the wave lives here, so the difficulty curve is
// one thing to read and tune rather than a dozen magic numbers scattered
// through the features. A feature asks A.tune() for the numbers it needs.

(function (A) {
  "use strict";

  A.tune = function tune() {
    const L = A.game.level;
    return {
      rocks: Math.min(3 + L, 10),
      rockSpeed: 30 + L * 6,
      maxSquids: L >= 10 ? 3 : L >= 6 ? 2 : 1,
      squidHp: L >= 9 ? 5 : L >= 5 ? 4 : 3,
      squidAccel: 60 + L * 7,
      squidSpeed: 78 + L * 9,
      squidGap: Math.max(5, 15 - L * 1.1),      // seconds between arrivals
      lungeGap: Math.max(1.6, 4.2 - L * 0.28),
      diveGap: Math.max(3, 8 - L * 0.5),
      portalGap: Math.max(12, 26 - L * 1.2),
      planetGap: Math.max(24, 58 - L * 4),
    };
  };

  // Milestone waves get a name, so the ramp is felt and not just endured.
  A.WAVE_NAMES = {
    2: "THEY MULTIPLY", 3: "FULL THROTTLE", 5: "TOUGHER HIDE",
    6: "TWO KRAKENS", 8: "NO QUARTER", 10: "THREE KRAKENS", 14: "ABYSSAL",
  };
})(ASTEROIDS);
