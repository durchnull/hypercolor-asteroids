// Kai Koenig's events. They fire for everybody in the room except Kai, which
// is the whole arrangement — see game/events.js, and GR11.

(function (A) {
  "use strict";

  A.defineEvent({
    id: "kai:horizon",
    by: "Kai Koenig",
    name: "EVENT HORIZON",
    blurb: "IT IS NOT AIMING. IT IS NOT STOPPING",
    minWave: 3,
    weight: 3,
    cooldown: 4,
    // a hole with a disc around it, and the dashed line you should not cross
    icon: `M14.4 12a2.4 2.4 0 1 1-4.8 0 2.4 2.4 0 1 1 4.8 0
           M12 5.6a6.4 6.4 0 0 1 6.4 6.4 M12 18.4a6.4 6.4 0 0 1-6.4-6.4
           M12 2.2a9.8 9.8 0 0 1 4.9 1.3 M20.5 7.1a9.8 9.8 0 0 1 1.3 4.9
           M21.8 12a9.8 9.8 0 0 1-1.3 4.9 M16.9 20.5a9.8 9.8 0 0 1-4.9 1.3
           M12 21.8a9.8 9.8 0 0 1-4.9-1.3 M3.5 16.9A9.8 9.8 0 0 1 2.2 12
           M2.2 12a9.8 9.8 0 0 1 1.3-4.9 M7.1 3.5A9.8 9.8 0 0 1 12 2.2`,
    holds: 8,

    // One black hole, in off an edge, across the middle of the field at
    // walking pace, out the other side. It does not pick a seat and it does
    // not turn — see entities/blackhole.js for why that is the whole event: a
    // thing that aims at you is a thing you cannot answer, and a thing on a
    // straight line at 26 px/s is a question about whether you were watching.
    fire() {
      this.hole = A.spawnBlackhole();
      A.aberrate(0.8);
      A.screenFlash(A.hue + 200, 0.2);
      A.boom(1);
    },

    // The glyph stays down there for as long as this hole is on the glass —
    // this one by identity, so the mark cannot outlive its own crossing.
    while() {
      return !!this.hole && A.blackhole === this.hole;
    },
  });
})(ASTEROIDS);
