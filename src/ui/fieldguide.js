// The field guide on the splash screen writes itself.
//
// Every feature that registers a `guide` gets a row here, in `order.guide`.
// Nobody maintains a list: ship a feature with a guide entry and it is on the
// splash screen, which is also why nothing on that screen can go stale.
//
//   guide: {
//     name: "KRAKEN",
//     group: "field",           // "field" | "hands" | "instrument"
//     meta: "250 · 3–5 hits",   // optional, the amber bit after the name
//     tint: "var(--magenta)",
//     icon: `<svg …>`,          // 34×34, stroke="currentColor"
//     desc: "Hunts you, dives into the deep…",
//   }
//
// It is a briefing, not a brochure. The reader is about to press ENTER, and
// every row answers the same question: what will I meet out there, and what
// can I do about it? Three kinds of thing qualify, and they are the three
// bands below:
//
//   - a thing in the field — it can turn up in a live wave and act on you
//     (rocks, the kraken, portals, an ambush somebody laid),
//   - a thing in your hands — a control or a power, with its cost or count
//     in `meta` (the bomb, the grapple),
//   - an instrument — something read mid-flight, or something that has
//     already changed the field about to be flown (the mark, the tally).
//
// That taxonomy was written here from the first day and read by nobody,
// because the panel was one undifferentiated run of sixteen rows: a bomb you
// can drop sat between two rocks that can kill you, and the reader had to work
// out which was which from the prose. `group` says it instead, and the panel
// puts the three in the order a pilot needs them — what is coming, what you
// can do about it, what the screen is telling you. An entry that names no
// group is a thing in the field, because that is the one kind of feature GR9
// insists on a tile for, and a guess that lands the newcomer among the hazards
// is the safe way round.
//
// **A row is at most `LIMIT` characters.** Not a house style — a load-bearing
// number. Sixteen entries share one panel above the fold, and prose is the
// only thing on this screen that grows without anybody deciding it should: the
// grapple once ran nine lines and pushed the last four rows off a laptop, so
// the panel briefed a pilot on everything except the half they never scrolled
// to. Whatever will not fit belongs in the game, where it is discovered, or in
// `meta`, where it is a number. The console says so at load rather than the
// referee saying so at commit, because this is a thing you fix while you are
// looking at it and not a thing anybody should be stopped for.
//
// Bookkeeping stays off. Records, rankings, tapes and paint reveal
// themselves where they happen — the game-over screen, the pilot card, the
// hull, the book — and a tile that briefs nothing crowds out the ones that
// do. One seat is spoken for: the band plays last, at guide order 95, and
// nothing sits below it.

(function (A) {
  "use strict";

  const LIMIT = 150;

  // In reading order, which is also the order the flight happens in: what is
  // out there, what you can do about it, what tells you how it went.
  const BANDS = [
    { id: "field", label: "OUT THERE", note: "what the wave puts in front of you" },
    { id: "hands", label: "IN YOUR HANDS", note: "what you can do about it" },
    { id: "instrument", label: "INSTRUMENTS", note: "what you read, and what was decided before you flew" },
  ];

  // What the reader actually has to get through: entities and tags are the
  // author's business, characters on the screen are the pilot's.
  const plain = (html) => String(html)
    .replace(/<[^>]*>/g, "")
    .replace(/&mdash;|&ndash;/g, "-")
    .replace(/&[a-z]+;|&#\d+;/g, "*");

  const row = (entry, i) => `
      <li style="--i:${i}">
        <span class="icon" style="color:${entry.tint}">${entry.icon}</span>
        <div>
          <span class="name">${entry.name}</span>${
            entry.meta ? `<span class="pts">${entry.meta}</span>` : ""}
          <p class="desc">${entry.desc}</p>
        </div>
      </li>`;

  A.renderGuide = function renderGuide() {
    const root = document.getElementById("guide");
    const entries = A.guides();

    // One cascade down the whole panel rather than three that restart, so the
    // bands read as sections of one guide and not as three little guides.
    let i = 0;
    root.innerHTML = BANDS.map((band) => {
      const mine = entries.filter((e) => (e.group || "field") === band.id);
      if (!mine.length) return "";
      return `
    <div class="band">
      <h3>${band.label}<span>${band.note}</span></h3>
      <ul>${mine.map((e) => row(e, i++)).join("")}</ul>
    </div>`;
    }).join("");

    for (const e of entries) {
      const n = plain(e.desc).length;
      if (n > LIMIT) {
        console.warn("ASTEROIDS: field guide row " + e.name + " runs " + n +
          " characters, and the panel holds " + LIMIT +
          " (see src/ui/fieldguide.js)");
      }
    }
  };
})(ASTEROIDS);
