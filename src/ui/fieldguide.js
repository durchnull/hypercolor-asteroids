// The field guide on the splash screen writes itself.
//
// Every feature that registers a `guide` gets a row here, in `order.guide`.
// Nobody maintains a list: ship a feature with a guide entry and it is on the
// splash screen, which is also why nothing on that screen can go stale.
//
//   guide: {
//     name: "KRAKEN",
//     meta: "250 · 3–5 hits",   // optional, the amber bit after the name
//     tint: "var(--magenta)",
//     icon: `<svg …>`,          // 34×34, stroke="currentColor"
//     desc: "Hunts you, dives into the deep…",
//   }
//
// It is a briefing, not a brochure. The reader is about to press ENTER, and
// every row answers the same question: what will I meet out there, and what
// can I do about it? Three kinds of thing qualify:
//
//   - a thing in the field — it can turn up in a live wave and act on you
//     (rocks, the kraken, portals, an ambush somebody laid),
//   - a thing in your hands — a control or a power, with its cost or count
//     in `meta` (the bomb, the grapple),
//   - an instrument — something read mid-flight, or something that has
//     already changed the field about to be flown (the mark, the tally).
//
// Bookkeeping stays off. Records, rankings, tapes and paint reveal
// themselves where they happen — the game-over screen, the pilot card, the
// hull, the book — and a tile that briefs nothing crowds out the ones that
// do. One seat is spoken for: the band plays last, at guide order 95, and
// nothing sits below it.

(function (A) {
  "use strict";

  A.renderGuide = function renderGuide() {
    const ul = document.getElementById("guide");
    ul.innerHTML = A.guides().map((entry, i) => `
      <li style="--i:${i}">
        <span class="icon" style="color:${entry.tint}">${entry.icon}</span>
        <div>
          <span class="name">${entry.name}</span>${
            entry.meta ? `<span class="pts">${entry.meta}</span>` : ""}
          <p class="desc">${entry.desc}</p>
        </div>
      </li>`).join("");
  };
})(ASTEROIDS);
