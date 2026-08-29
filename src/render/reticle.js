// The aim reticle — solo mouse-aim's crosshair, styled like the fleet rather
// than the OS pointer.
//
// Drawn every frame at the raw cursor position (not the ship's damped
// facing — see src/entities/ship.js), onto the same layer that fades rather
// than clears, so it drags the same short comet trail everything else out
// here does. Nothing here owns any state; it only reads A.mouseX/A.mouseY
// (src/input/mouse.js) and P1's hue.
//
// No guide tile: it only ever appears under your own cursor, in solo play —
// nothing to discover, nothing to brief.

(function (A) {
  "use strict";

  const R1 = 8, R2 = 15;    // ring radius, tick outer radius
  const RING_SEGS = 16;

  function active() {
    return A.game.phase === "playing" && A.solo() && A.mouseEngaged && A.mouseX !== null;
  }

  function draw(tick, g) {
    if (!active()) return;
    const p = A.players[0];
    g.save();
    A.glow(A.neon(A.hue + p.hue, 70));
    g.lineWidth = 1.6;
    g.beginPath();
    g.arc(A.mouseX, A.mouseY, R1, 0, A.TAU);
    g.stroke();
    g.beginPath();
    for (let i = 0; i < 4; i++) {
      const a = (i / 4) * A.TAU;
      const c = Math.cos(a), s = Math.sin(a);
      g.moveTo(A.mouseX + c * R1, A.mouseY + s * R1);
      g.lineTo(A.mouseX + c * R2, A.mouseY + s * R2);
    }
    g.stroke();
    g.restore();
  }

  function draw3d(tick, s3) {
    if (!active()) return;
    const p = A.players[0];
    const hue = p.hue, light = 70, z = 4;
    for (let i = 0; i < 4; i++) {
      const a = (i / 4) * A.TAU;
      const c = Math.cos(a), n = Math.sin(a);
      s3.line(
        A.mouseX + c * R1, A.mouseY + n * R1, z,
        A.mouseX + c * R2, A.mouseY + n * R2, z,
        { hue, light, alpha: 1, width: 1.8 });
    }
    // the ring, as a short-segment polygon — s3.line has no arc primitive
    let px = A.mouseX + R1, py = A.mouseY;
    for (let i = 1; i <= RING_SEGS; i++) {
      const a = (i / RING_SEGS) * A.TAU;
      const qx = A.mouseX + Math.cos(a) * R1, qy = A.mouseY + Math.sin(a) * R1;
      s3.line(px, py, z, qx, qy, z, { hue, light, alpha: 1, width: 1.4 });
      px = qx; py = qy;
    }
  }

  A.register({ id: "reticle", order: { draw: 95 }, draw, draw3d });
})(ASTEROIDS);
