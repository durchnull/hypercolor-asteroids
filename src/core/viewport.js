// The canvases and the size of the world.
//
// A.W and A.H change on every resize, so always read them off the namespace —
// never copy them into a local at load time.

(function (A) {
  "use strict";

  A.canvas = document.getElementById("game");
  A.ctx = A.canvas.getContext("2d");

  // Entities are drawn to their own layer so it can be faded, not cleared,
  // leaving phosphor trails behind everything that moves.
  A.layer = document.createElement("canvas");
  A.g = A.layer.getContext("2d");

  // Two half-baked downscales of the layer, upscaled back for a cheap bloom.
  A.bloomA = document.createElement("canvas");
  A.bloomB = document.createElement("canvas");
  A.bA = A.bloomA.getContext("2d");
  A.bB = A.bloomB.getContext("2d");

  A.W = 0;
  A.H = 0;
  A.DPR = 1;

  const listeners = [];
  /** Run `fn` after every resize (and after the first one). */
  A.onResize = (fn) => listeners.push(fn);

  A.resize = function resize() {
    A.DPR = Math.min(window.devicePixelRatio || 1, 1.5);
    A.W = window.innerWidth;
    A.H = window.innerHeight;
    for (const c of [A.canvas, A.layer]) {
      c.width = Math.round(A.W * A.DPR);
      c.height = Math.round(A.H * A.DPR);
    }
    A.canvas.style.width = A.W + "px";
    A.canvas.style.height = A.H + "px";
    A.bloomA.width = Math.max(1, Math.round(A.W * 0.25));
    A.bloomA.height = Math.max(1, Math.round(A.H * 0.25));
    A.bloomB.width = Math.max(1, Math.round(A.W * 0.08));
    A.bloomB.height = Math.max(1, Math.round(A.H * 0.08));
    A.ctx.setTransform(A.DPR, 0, 0, A.DPR, 0, 0);
    A.g.setTransform(A.DPR, 0, 0, A.DPR, 0, 0);
    for (const fn of listeners) fn();
  };

  window.addEventListener("resize", A.resize);
})(ASTEROIDS);
