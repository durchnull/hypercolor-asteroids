// The mark. The banner says what just happened; this says what is still
// happening.
//
// An ambush outlives its own announcement — the word VICE is off the screen
// long before the walls have finished closing — so every live event signs the
// foot of the screen with a glyph of its own and stays there until the thing
// it stands for is over. Two at once sit side by side, two shapes and two
// colours, because a pilot who cannot tell them apart has only been told that
// something is wrong.
//
// The glyphs belong to the events; this module draws whatever it is handed.
// An event that never drew one gets a warning diamond rather than nothing,
// because down here silence has to keep meaning "the field is calm".
//
// The clock ring says how much is left. When an event answers `while()` there
// is no clock to draw — it lasts as long as it lasts — so the ring turns
// instead, which is the same sentence in a different tense.
//
// A mark that burns down does not simply go out: it walks into the bottom left
// corner and stands in the row of everything else this game has thrown at you,
// small and dim, above the tally. By wave nine that row is the shape of the
// run, and it is the first thing worth reading on the way to the game over.

(function (A) {
  "use strict";

  // Four rings out from the middle, and nothing shares a radius with anything
  // else: the glyph, the frame, the clock, and the second frame a pilot only
  // gets around one of their own.
  const R = 20;        // the frame the glyph sits in
  const CLOCK = 32;    // how much of it is left
  const MINE = 40;     // and this one is yours
  const STEP = 104;    // between two marks
  const LIFT = 84;     // off the bottom edge, clear of the touch pads

  const SMALL = 15;    // the glyph again, once it is only a memory
  const ROW = 21;      // between two of them in the corner
  const CORNER = { x: 22, y: 54 };   // left, and up off the bottom past the tally
  const WALK = 0.45;   // seconds it takes to cross the screen and sit down

  // a diamond with an exclamation in it: something is happening and nobody
  // said what
  const UNSIGNED = "M12 3.4L20.6 12L12 20.6L3.4 12z M12 8.2v5.4 M11.98 16.6h.04";

  // Path2D is cheap to draw and dear to parse, and there are six of these.
  const paths = new Map();
  function pathFor(d) {
    let p = paths.get(d);
    if (!p) {
      p = new Path2D(d);
      paths.set(d, p);
    }
    return p;
  }

  function hex(g, r) {
    g.beginPath();
    for (let i = 0; i < 6; i++) {
      const a = (i / 6) * A.TAU - Math.PI / 2;
      const x = Math.cos(a) * r;
      const y = Math.sin(a) * r;
      if (i === 0) g.moveTo(x, y);
      else g.lineTo(x, y);
    }
    g.closePath();
    g.stroke();
  }

  function mark(g, l, x, y, time) {
    // it arrives with a bang and leaves quietly
    const pop = Math.min(1, l.age / 0.22);
    const grow = 1 + (1 - pop) * (1 - pop) * 0.8;
    // your own trap knows it is yours, and will not sit still about it
    const pulse = l.own ? 0.72 + 0.28 * Math.sin(time * 6) : 1;
    const hue = A.hue + (l.own ? 320 : l.hue);
    const alpha = Math.min(1, l.fade) * pulse;

    g.save();
    g.translate(x, y);
    g.scale(grow, grow);
    g.lineJoin = "round";
    g.lineCap = "round";
    g.globalAlpha = alpha * 0.85;
    A.glow(A.neon(hue, 64));
    g.lineWidth = 1.5;
    hex(g, R + 6);
    if (l.own) {
      g.globalAlpha = alpha * 0.6;
      hex(g, MINE);
    }

    // the clock, or the turning ring for an event that runs on its own state
    g.globalAlpha = alpha * 0.75;
    g.lineWidth = 2.4;
    g.beginPath();
    if (l.life > 0) {
      const left = Math.max(0, Math.min(1, l.life / l.hold));
      g.arc(0, 0, CLOCK, -Math.PI / 2, -Math.PI / 2 + left * A.TAU);
    } else {
      const from = (time * 1.5) % A.TAU;
      g.arc(0, 0, CLOCK, from, from + 1.2);
    }
    g.stroke();

    // the glyph, out of its 24-box and into the frame
    const s = (R * 2) / 24;
    g.save();
    g.globalAlpha = alpha;
    g.scale(s, s);
    g.translate(-12, -12);
    g.lineWidth = 1.7 / s;
    g.stroke(pathFor(l.icon || UNSIGNED));
    g.restore();

    g.globalAlpha = alpha * 0.8;
    g.fillStyle = A.neon(hue, 72);
    g.font = "600 9px " + A.FONT;
    g.textAlign = "center";
    g.letterSpacing = "3px";
    g.fillText(l.name, 1.5, MINE + 12);
    g.letterSpacing = "0px";
    g.restore();
    g.globalAlpha = 1;
  }

  /** The same glyph, no frame and no name, once it is only a memory. */
  function memory(g, l, i, raw) {
    // It does not blink out of the middle and reappear in the corner — it
    // crosses, from wherever the mark was standing to where it now belongs.
    // On real time and counted here, because the walk is a thing the screen
    // does rather than a thing the game does: it still finishes if the last
    // ship died halfway through it.
    l.walk = Math.min(1, (l.walk || 0) + raw / WALK);
    const ease = l.walk * l.walk * (3 - 2 * l.walk);
    const fromX = l.at === undefined ? A.W / 2 : l.at;
    const x = fromX + (CORNER.x + i * ROW - fromX) * ease;
    const y = A.H - LIFT + (LIFT - CORNER.y) * ease;
    const s = (R * 2 + (SMALL - R * 2) * ease) / 24;

    g.save();
    g.globalAlpha = 0.9 - 0.5 * ease;
    g.lineJoin = "round";
    g.lineCap = "round";
    A.glow(A.neon(A.hue + (l.own ? 320 : l.hue), 62));
    g.translate(x, y);
    g.scale(s, s);
    g.translate(-12, -12);
    g.lineWidth = 1.6 / s;
    g.stroke(pathFor(l.icon || UNSIGNED));
    g.restore();
    g.globalAlpha = 1;
  }

  function draw(tick, g) {
    const done = A.eventLog();
    for (let i = 0; i < done.length; i++) memory(g, done[i], i, tick.raw);

    const live = A.liveEvents();
    const y = A.H - LIFT;
    for (let i = 0; i < live.length; i++) {
      // remembered, so the mark can walk to the corner from where it stood
      live[i].at = A.W / 2 + (i - (live.length - 1) / 2) * STEP;
      mark(g, live[i], live[i].at, y, tick.time);
    }
  }

  A.register({
    id: "mark",
    order: { draw: 93, guide: 93 },
    draw,
    guide: {
      name: "THE MARK",
      meta: "at your feet",
      tint: "var(--cyan)",
      icon: `<svg width="34" height="34" viewBox="0 0 34 34" fill="none"
        stroke="currentColor" stroke-width="1.6" stroke-linejoin="round">
        <path d="M17 5l10.4 6v12L17 29 6.6 23V11z"/>
        <path d="M17 11.6v7.2M16.97 22.6h.06"/></svg>`,
      desc: `Whatever the field is doing to you signs the foot of the screen for
        as long as it lasts. The ring is how much is left; one that turns
        instead ends when it ends. Spent glyphs gather in the bottom left
        corner. A mark that will not hold still is one of your own.`,
    },
  });
})(ASTEROIDS);
