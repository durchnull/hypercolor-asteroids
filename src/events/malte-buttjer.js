// Malte Buttjer's events.
//
// Signed with a name rather than A.HOUSE, which means they fire for every
// pilot except the one who wrote them. Nobody else may touch this file, and
// this file may not touch anybody else's — GR11.

(function (A) {
  "use strict";

  A.defineEvent({
    id: "mb:undertow",
    by: "Malte Buttjer",
    name: "THE UNDERTOW",
    blurb: "IT OPENS WHERE YOU ARE AND WAITS",
    minWave: 3,
    weight: 2,
    cooldown: 3,
    // a throat, and everything falling into it from four sides
    icon: `M12 8.6a3.4 3.4 0 1 0 0 6.8a3.4 3.4 0 1 0 0-6.8
           M12 1.8v3.6 M10.4 3.9L12 5.5L13.6 3.9
           M12 22.2v-3.6 M10.4 20.1L12 18.5L13.6 20.1
           M1.8 12h3.6 M3.9 10.4L5.5 12L3.9 13.6
           M22.2 12h-3.6 M20.1 10.4L18.5 12L20.1 13.6`,
    holds: 7,
    // Three to five of them, laid where the pilots actually are and fused a
    // second and a half apart, so the field is not rearranged all at once but
    // keeps being rearranged while you are still deciding about the last one.
    // Nothing here is a killing blow: the mines cannot touch a hull. They only
    // move the rocks, and the rocks were always the problem.
    fire() {
      const n = Math.min(5, 2 + Math.floor(A.game.level / 3));
      for (let i = 0; i < n; i++) {
        const spot = A.mineSpot();
        A.layMine(spot.x, spot.y, 3.8 + i * 1.5);
      }
      A.aberrate(0.5);
    },
    // The mark stays down there while anything is still ticking or pulling —
    // the ambush is not over until the last throat has closed.
    while() {
      return A.mines.length > 0;
    },
  });
})(ASTEROIDS);
