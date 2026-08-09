// The bounty. The field is less patient with whoever is winning.
//
// Every other pressure in this cabinet is authored at somebody. An event is a
// trap with a pilot's name on the file and a pilot's name in the `by:`
// (GR11); the tally is a bill for something you did (GR12). This one has
// nobody behind it. It reads the top line of the board — the same rows the
// splash screen shows, out of docs/chronicle.js — and shortens the wait
// between ambushes for whoever is standing on it.
//
// Which makes it the one shape of targeting the rules already allow: by
// standing, not by grudge. Nobody wrote it at anybody, the pilot it comes for
// picked the fight by beating everybody else, and it is self-correcting in a
// way a personal trap can never be — the moment somebody else takes the top
// row, the field changes its mind about who it is impatient with. An event
// aimed at a name would need GR11 amended in the open; this needed nothing,
// which is most of the argument for it.
//
// GR8, out loud, because that rule is on our honour and this is the kind of
// thing it is about:
//
//   - a handicap and never a power. It gives nobody anything.
//   - one flat number, not a ramp. Being first by ten thousand is the same
//     crown as being first by ten.
//   - both seats fly the same field, as they do for the tally.
//   - it is announced before the second wave and drawn for the whole run.
//     Nothing arrives unseen; the ambushes it hurries along still announce
//     themselves exactly as they always did.
//   - the way out is the way in, and it costs nothing but somebody else
//     having a better evening than you.
//
// No board, no bounty. A clone that has never run tools/chronicle.sh has no
// docs/chronicle.js and no A.BOARD, which the splash screen already treats as
// the ordinary case rather than a broken one — so this quietly does nothing,
// and the first sealed tape anybody lands switches it on for them.

(function (A) {
  "use strict";

  const GAP = 0.86;      // the crown-holder's wait between ambushes, as a share
  const SAY = 2.6;       // seconds into a run before it says so

  let said = 0;

  /** Whoever is on the top row of the board, or "" when there is no board. */
  A.bountyPilot = function bountyPilot() {
    const top = (A.BOARD || [])[0];
    return top && top.pilot ? String(top.pilot) : "";
  };

  /** Is the pilot in the seat the one the field is impatient with? */
  A.bountyOn = function bountyOn() {
    const who = A.bountyPilot();
    return !!who && who === A.activePilot();
  };

  /**
   * Gap multiplier for the events director, the way game/tally.js hands it
   * one. 1 is everybody else's field, and everybody else is most people.
   */
  A.bountyHeat = function bountyHeat() {
    return A.bountyOn() ? GAP : 1;
  };

  function reset(mode) {
    said = mode === "play" ? 0 : SAY;
  }

  // Said once, a couple of seconds in. Not at nought, because the opening of a
  // run is already busy and a banner nobody has settled enough to read is a
  // banner that did not happen; and well before four, which is the earliest
  // game/events.js will let anything fire, so the crown is never explaining
  // itself over the top of the first ambush it hurried along.
  //
  // Counted on the game clock rather than the wall, so it only runs while the
  // game does: the attract loop is nobody's flight and gets told nothing.
  function resolve(tick) {
    if (said >= SAY) return;
    said += tick.dt;
    if (said < SAY || !A.bountyOn()) return;
    said = SAY;
    A.showBanner("WEARING THE CROWN", "TOP OF THE BOARD. THE FIELD NOTICED", 2.2);
    A.blip(520, 0.5, "triangle", 0.09);
  }

  // Right-hand side, opposite the tally's marks, so the two things the field
  // holds against a pilot are not in the same corner arguing over pixels - and
  // lifted well off the bottom edge, which belongs to the sound button and to
  // the row of spent ambushes walking into the corner (ui/mark.js).
  const CROWN = "M2 16.5V6.6l4.6 4L12 2.6l5.4 8 4.6-4v9.9z M2 19.6h20";

  let path = null;

  function draw(tick, g) {
    if (!tick.running || !A.bountyOn()) return;
    if (!path) path = new Path2D(CROWN);

    const s = 18 / 24;
    g.save();
    g.globalAlpha = 0.34 + 0.1 * Math.sin(tick.time * 1.7);
    g.lineJoin = "round";
    g.lineCap = "round";
    A.glow(A.neon(A.hue + 42, 66));
    g.translate(A.W - 40, A.H - 74);
    g.scale(s, s);
    g.lineWidth = 1.8 / s;
    g.stroke(path);
    g.restore();
    g.globalAlpha = 1;
  }

  A.register({
    id: "bounty",
    order: { draw: 92, guide: 92 },
    reset,
    resolve,
    draw,
    guide: {
      name: "THE BOUNTY",
      meta: "earned",
      tint: "var(--amber)",
      icon: `<svg width="34" height="34" viewBox="0 0 34 34" fill="none"
        stroke="currentColor" stroke-width="1.6" stroke-linejoin="round">
        <path d="M4 23V9.5l6.5 5.6L17 4l6.5 11.1L30 9.5V23z"/>
        <path d="M4 27.4h26"/></svg>`,
      desc: `Top of the board and the field stops waiting so long between
        ambushes. Nobody wrote it at you and nobody can call it off &mdash; it
        follows the first row of the flight records, so the only way out of it
        is somebody else having a better evening.`,
    },
  });
})(ASTEROIDS);
