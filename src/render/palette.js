// Colour. The whole game is one drifting spectrum: almost nothing picks an
// absolute hue, it picks an offset from A.hue and rides along.

(function (A) {
  "use strict";

  A.FONT = 'ui-monospace, "SF Mono", Menlo, Consolas, monospace';

  // changes every frame — always read it off the namespace
  A.hue = 0;
  A.advanceHue = (d) => { A.hue += d; };

  A.neon = (h, l = 62, a = 1, s = 100) =>
    "hsla(" + (((h % 360) + 360) % 360) + "," + s + "%," + l + "%," + a + ")";

  // The halo comes from the bloom pass, not from per-shape shadows — canvas
  // shadowBlur on hundreds of little strokes tanks the frame rate.
  A.glow = (c) => { A.g.strokeStyle = c; };
})(ASTEROIDS);
