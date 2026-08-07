// The logo — the name of the cabinet, drawn. (Not to be confused with THE
// MARK, which is ui/mark.js and belongs to the events.)
//
// A Bild-Text-Marke: one signet, one wordmark, and neither of them travels
// alone. The signet is a rock printed three times slightly out of register —
// magenta, cyan, lime — which is the whole name in one glyph. The asteroid is
// the shape; the misconvergence is the hypercolor. It is the trick a tube
// plays on you when it has lost its purity, and this cabinet is a tube.
//
// One path, defined once, here. Everything that needs the mark reads it off
// this file: the splash screen, and the tab icon, which is the same drawing
// flattened to fixed hues because a favicon cannot see a stylesheet.
//
// The wordmark is two lines that come out exactly the same width without
// anybody measuring them: HYPERCOLOR sets the measure and ASTEROIDS is nine
// letters told to space themselves across it. That is worth more than it
// sounds. The monospace stack in tokens.css resolves to a different face on
// every platform, so a tracking value hand-tuned until it lined up on this
// laptop would be wrong on the next four — and if the mono is wide enough that
// ASTEROIDS ends up the longer line, it sets the measure instead and the
// lockup is still square. The layout does the arithmetic either way.

(function (A) {
  "use strict";

  // Twelve vertices and no two radii alike: a rock, not a gem. Drawn in a
  // 24-box like everything in icons.js, in a viewBox with room around it so
  // the ghosts and their bloom have somewhere to go.
  const ROCK = "M12 2.5L16.6 5.2L20.6 8.2L17.8 12.6L19.5 17L15.6 20.8" +
               "L10.7 18.3L6 19.1L3.7 14.7L2.9 9.7L7.8 7.7L9.6 3.5z";
  const BOX = "-2.5 -2.5 29 29";

  // Where the three copies sit: one up, two down, 120 degrees apart and 1.4
  // units out. Three in a row was the first try and it was wrong — the eye
  // reads collinear copies as three rings of a rope rather than one shape
  // three times, and only two colours ever end up on the outside. Round a
  // triangle every hue gets an edge of its own.
  const LOBES = [[0, -1.4], [1.22, 0.7], [-1.22, 0.7]];

  // On the page the signet drifts with the rest of the rack, so it names its
  // colours and lets the stylesheet rotate them. In the tab it cannot, so it
  // carries the same four as numbers.
  const LIVE = ["var(--magenta)", "var(--cyan)", "var(--lime)", "var(--ink)"];
  const FLAT = ["#ff3ec8", "#21f3ff", "#b6ff3d", "#f2e9ff"];

  /** The three ghosts at one stroke weight. */
  function pass(hues, w, o) {
    return hues.slice(0, 3).map((h, i) =>
      `<path d="${ROCK}" stroke="${h}" stroke-width="${w}"` +
      (o < 1 ? ` opacity="${o}"` : "") +
      ` transform="translate(${LOBES[i][0]} ${LOBES[i][1]})"/>`).join("");
  }

  // Wide and faint under narrow and bright, which is how everything else in
  // this game glows (see src/render/effects.js). Painted into the drawing
  // rather than hung off the element with a CSS drop-shadow, because the
  // stylesheet wants `filter` for the hue drift and cannot have both.
  //
  // The rock itself goes on last, in ink, down the middle of the three: a
  // white line with a coloured edge on every side, which is what a tube does
  // when it is telling you three times where something is and landing in three
  // slightly different places. Mixing the three additively gets to the same
  // picture and was the first way this was drawn — but an SVG loaded as an
  // image is not promised its blend modes, and the tab icon is exactly that.
  // Painted, it is the same mark everywhere it is ever drawn.
  function signet(hues) {
    return `<svg class="signet" viewBox="${BOX}" fill="none"
      stroke-linejoin="round" aria-hidden="true"
      >${pass(hues, 6, 0.35)}${pass(hues, 2.4, 1)}` +
      `<path d="${ROCK}" stroke="${hues[3]}" stroke-width="1.9"/></svg>`;
  }

  /** The lockup: signet, then the two words, as one object. */
  A.logo = function logo() {
    const letters = "ASTEROIDS".split("").map((c) => `<i>${c}</i>`).join("");
    return `<span class="lockup" aria-hidden="true">${signet(LIVE)}<span class="wordmark">
      <span class="hyper">HYPERCOLOR</span>
      <span class="roids">${letters}</span>
    </span></span>`;
  };

  // Anything with `data-logo` on it gets the mark, the same way a panel header
  // with `data-ico` gets its glyph. The element keeps whatever accessible name
  // it was given: the lockup itself is a drawing of a word, not the word.
  A.dressLogo = function dressLogo(root) {
    (root || document).querySelectorAll("[data-logo]").forEach((el) => {
      if (el.firstElementChild) return;   // already wearing one
      el.innerHTML = A.logo();
    });
  };

  // The tab icon, from the same path, built here rather than written into
  // index.html as four hundred characters of percent-encoding. It is a data
  // URI, so the cabinet still opens on a plane.
  function pin() {
    const svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="' + BOX + '" ' +
      'fill="none" stroke-linejoin="round">' +
      // the void, spelled out: a tab icon is drawn against whatever the browser
      // chrome happens to be, and this one is only legible against black
      '<rect x="-2.5" y="-2.5" width="29" height="29" fill="#07030f"/>' +
      pass(FLAT, 6, 0.35) + pass(FLAT, 2.4, 1) +
      `<path d="${ROCK}" stroke="${FLAT[3]}" stroke-width="1.9"/></svg>`;
    const link = document.createElement("link");
    link.rel = "icon";
    link.type = "image/svg+xml";
    link.href = "data:image/svg+xml," + encodeURIComponent(svg);
    document.head.append(link);
  }

  function dress() {
    A.dressLogo();
    pin();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", dress);
  } else {
    dress();
  }
})(ASTEROIDS);
