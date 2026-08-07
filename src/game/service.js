// The service record. What a pilot has earned, derived — never assigned.
//
// The punishment side of the meta-game is thorough: bends, skips, breaches,
// all counted by machines off the history. This is the other ledger, built
// the same way from records that already exist for other reasons: versions
// landed (docs/chronicle.js, counted by the book), traps laid (the event
// registry), flights on the board (docs/RANKINGS.md by way of A.BOARD).
// Nothing is stored, nothing can be edited, and the only way to move a
// number is to land, lay or fly something.
//
// Milestones buy trim, and trim is paint (GR8): chevrons on the hull for
// versions landed, a tail bar for the first trap laid, wingtip marks for
// flights on the board. No speed, no armour, no cost, both seats wear it
// alike, and it follows the name at the keyboard — GUEST flies a bare hull.

(function (A) {
  "use strict";

  const CHEVRONS = [5, 15, 30];   // versions landed per chevron, up to three

  /** The earned facts for a name, or null for GUEST and strangers. */
  A.serviceRecord = function serviceRecord(name) {
    if (!name || name === A.GUEST) return null;
    const versions = ((A.CHRONICLE && A.CHRONICLE.roster) || {})[name] || 0;
    const traps = (A.eventPilots ? A.eventPilots() : [])
      .filter((p) => p.name === name)
      .reduce((t, p) => t + p.events, 0);
    const flights = (A.BOARD || []).filter((r) => r.pilot === name).length;
    if (!versions && !traps && !flights) return null;
    return { versions, traps, flights };
  };

  function draw(tick, g) {
    if (!tick.running) return;
    const r = A.serviceRecord(A.activePilot());
    if (!r) return;

    let chevrons = 0;
    for (const at of CHEVRONS) if (r.versions >= at) chevrons++;

    for (const p of A.livePlayers()) {
      if (p.dead) continue;
      // the ship blinks through respawn protection; paint on an invisible
      // hull would give its position away, so the trim blinks with it
      if (p.invuln > 0 && Math.floor(p.invuln * 8) % 2 === 0) continue;

      g.save();
      g.translate(p.x, p.y);
      g.rotate(p.angle + Math.PI / 2);
      A.glow(A.neon(A.hue + p.hue + 40, 78));
      g.lineWidth = 1.3;
      g.globalAlpha = 0.85;
      g.beginPath();
      // chevrons down the spine, nose-first, one per milestone
      for (let i = 0; i < chevrons; i++) {
        const y = -3.5 + i * 4;
        g.moveTo(-3.6, y + 2.4);
        g.lineTo(0, y);
        g.lineTo(3.6, y + 2.4);
      }
      // the tail bar: the first trap laid, and the room armed itself
      if (r.traps > 0) { g.moveTo(-3.4, 8.4); g.lineTo(3.4, 8.4); }
      // wingtip marks: flights that made the board
      if (r.flights > 0) {
        g.moveTo(-8.2, 9.6); g.lineTo(-6.4, 6.4);
        g.moveTo(8.2, 9.6); g.lineTo(6.4, 6.4);
      }
      g.stroke();
      g.restore();
      g.globalAlpha = 1;
    }
  }

  // The roster arrives with the book, a moment after the page. The picker may
  // already be on screen by then, so ask it to say the numbers again.
  A.sidecar("docs/chronicle.js", () => { if (A.renderPilot) A.renderPilot(); });

  A.register({
    id: "service",
    order: { draw: 61, guide: 93 },   // paint goes on right after the hull
    draw,
    guide: {
      name: "SERVICE RECORD",
      meta: "earned",
      tint: "var(--cyan)",
      icon: `<svg width="34" height="34" viewBox="0 0 34 34" fill="none"
        stroke="currentColor" stroke-width="1.6" stroke-linecap="round"
        stroke-linejoin="round">
        <path d="M8 10l9-5 9 5M8 17l9-5 9 5M8 24l9-5 9 5"/></svg>`,
      desc: `Versions landed, traps laid, flights on the board &mdash; counted
        off the record by machines, worn on the hull as paint. Nobody assigns
        any of it, and the paint buys nothing but the look.`,
    },
  });
})(ASTEROIDS);
