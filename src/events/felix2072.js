// felix2072's events.
//
// Signed with a name, not with A.HOUSE, which means they fire for every pilot
// except the one who wrote them (GR11). Nobody else may touch this file, and
// this file may not touch anybody else's.

(function (A) {
  "use strict";

  A.defineEvent({
    id: "felix:circuit",
    by: "felix2072",
    name: "LIVE CIRCUIT",
    blurb: "THREE ROCKS, WIRED TOGETHER, AND THE WIRE MEANS IT",
    minWave: 2,
    weight: 2,
    cooldown: 3,
    // a triangle of nodes, wired
    icon: `M12 3.6L20.8 19.6H3.2Z M12 3.6v3 M17.8 17L15.5 15.6 M6.2 17L8.5 15.6`,
    holds: 6,
    // src/entities/circuit.js owns the wire itself; this just throws the switch.
    fire() {
      A.layCordon();
    },
    while() {
      return !!A.cordon;
    },
  });
})(ASTEROIDS);
