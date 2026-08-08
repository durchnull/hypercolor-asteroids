// The glyphs the splash screen is signposted with.
//
// The field guide already draws icons, but those belong to the features that
// register them — a kraken ships its own kraken. These are the other kind: the
// marks the panels themselves wear, where a number on its own would not say
// what kind of number it is. Seven traps laid and three bends on the ledger
// are both small amber digits until one of them has teeth next to it.
//
// One box, one stroke weight, no fills, `currentColor` throughout — so a glyph
// picks up the colour of whatever it was dropped into and drifts with the
// spectrum like everything else on that screen.
//
//   A.ico("trap")            -> <svg class="ic">…</svg>
//   A.ico("bend", "lit")     -> the same, plus a class of your own
//
// An unknown name draws nothing rather than a broken box: a panel that asks
// for a glyph nobody has drawn yet should read as a panel with one fewer
// glyph, which is what every fallback in this project does.

(function (A) {
  "use strict";

  const PATH = {
    // a bear trap, seen from the side: teeth on the ground, plate in the middle
    trap: '<path d="M3 16h18"/><path d="M5 16l2.2-4.6L9.4 16l2.6-5.6L14.6 16l2.2-4.6L19 16"/><circle cx="12" cy="19.3" r="1.5"/>',
    // a rule that should be straight, and is not
    bend: '<path d="M2.6 17.4h6.2l5.4-10.8h7.2"/><path d="M2.6 15.2v4.4M21.4 4.4v4.4"/>',
    // something has you in it
    aim: '<circle cx="12" cy="12" r="7.2"/><circle cx="12" cy="12" r="2.1"/><path d="M12 1.8v4M12 18.2v4M1.8 12h4M18.2 12h4"/>',
    // the field, swept
    radar: '<circle cx="12" cy="12" r="8.6"/><circle cx="12" cy="12" r="3.6"/><path d="M12 12l6.1-6.1"/>',
    // a pilot, from the front
    helmet: '<path d="M4.7 12.5a7.3 7.3 0 1 1 14.6 0v3a3 3 0 0 1-3 3H7.7a3 3 0 0 1-3-3z"/><path d="M7.6 11.9a4.4 4.4 0 0 1 8.8 0v1.5H7.6z"/>',
    // a stick and a base: the seats
    stick: '<rect x="3" y="12.4" width="18" height="7.6" rx="2.2"/><path d="M12 12.4V7.6"/><circle cx="12" cy="5.4" r="2.4"/><path d="M6.6 16.2h2.6M7.9 14.9v2.6"/><circle cx="16.6" cy="15.6" r=".9"/><circle cx="18.4" cy="17.4" r=".9"/>',
    // what the board is for
    cup: '<path d="M8 3.6h8v5.1a4 4 0 0 1-8 0z"/><path d="M8 5.1H5.4a2.6 2.6 0 0 0 2.6 5.1M16 5.1h2.6a2.6 2.6 0 0 1-2.6 5.1"/><path d="M12 12.8v4.1M9.4 20.4h5.2M10.4 17v3.4h3.2V17"/>',
    // the book, open
    book: '<path d="M3.6 4.6h5.5a2.9 2.9 0 0 1 2.9 2.9v11.9a2.4 2.4 0 0 0-2.4-2.4H3.6z"/><path d="M20.4 4.6h-5.5a2.9 2.9 0 0 0-2.9 2.9v11.9a2.4 2.4 0 0 1 2.4-2.4h6z"/>',
    // a painted plate, hung
    frame: '<rect x="3.2" y="4.6" width="17.6" height="14.8" rx="1.4"/><path d="M3.2 15.4l4.6-4.5 3.5 3.4 3-2.9 6.5 6.5"/><circle cx="8.6" cy="9" r="1.3"/>',
    // the way out of the cabinet
    door: '<path d="M13.6 3.4H5.4v17.2h8.2"/><path d="M10 12h9.4M16.2 8.4L19.6 12l-3.4 3.6"/>',
    // service chevrons, the way a sleeve wears them
    chevron: '<path d="M5 9.5l7-4.3 7 4.3M5 15l7-4.3 7 4.3M5 20.5l7-4.3 7 4.3"/>',
    // the machine itself, from the front: marquee, screen, control panel
    cabinet: '<path d="M6.2 3.2h11.6v17.6H6.2z"/><path d="M6.2 7.4h11.6M6.2 16.6h11.6"/>' +
             '<rect x="8.3" y="9.3" width="7.4" height="5.2" rx="0.8"/>' +
             '<path d="M9.2 18.6h2.2M14 18.6h.9"/>',
    // one sheet with a corner turned, which is the whole of what ships
    page: '<path d="M6.2 3.2h7.4L17.8 7.4v13.4H6.2z"/><path d="M13.3 3.2v4.4h4.5"/>' +
          '<path d="M9 12.6h6M9 15.8h4.2"/>',
    // several hands, one cabinet: two lines arriving at the same place
    merge: '<circle cx="5.4" cy="5.6" r="2.1"/><circle cx="5.4" cy="18.4" r="2.1"/>' +
           '<circle cx="18.6" cy="12" r="2.1"/>' +
           '<path d="M7.5 5.6h3.1a3.4 3.4 0 0 1 3.4 3.4 3 3 0 0 0 2.5 3"/>' +
           '<path d="M7.5 18.4h3.1a3.4 3.4 0 0 0 3.4-3.4 3 3 0 0 1 2.5-3"/>',
  };

  A.ico = function ico(name, cls) {
    const p = PATH[name];
    if (!p) return "";
    return `<svg class="ic${cls ? " " + cls : ""}" viewBox="0 0 24 24" aria-hidden="true">${p}</svg>`;
  };

  // The panels that draw themselves put a glyph in their own markup. The two
  // that are plain html in index.html ask for one by name instead, so a static
  // header does not have to carry forty characters of path data around.
  A.dressIcons = function dressIcons(root) {
    (root || document).querySelectorAll("[data-ico]").forEach((el) => {
      const first = el.firstElementChild;
      if (first && first.classList.contains("ic")) return;   // already wearing one
      el.insertAdjacentHTML("afterbegin", A.ico(el.dataset.ico));
    });
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", () => A.dressIcons());
  } else {
    A.dressIcons();
  }
})(ASTEROIDS);
