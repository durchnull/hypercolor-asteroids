// Mouse aim, and the mouse buttons standing in for fire/bomb/grapple —
// seat 0 only, and only while seat 0 is flying alone.
//
// The cabinet has one mouse and two seats, so this can never be fair between
// them (GR8): the moment seat 1 sits down, the mouse goes quiet and seat 0 is
// back on the keyboard alone, same as before this file existed. That is what
// A.solo() is for, and src/entities/ship.js asks it the same question before
// letting the cursor set an angle.

(function (A) {
  "use strict";

  // Live cursor position, in world space — read fresh, like A.W/A.H, never
  // copied to a local at load time. src/render/reticle.js draws the aim
  // marker at exactly this point.
  A.mouseX = null;
  A.mouseY = null;

  // Two ways to steer seat 0's facing, and only one gets to hold the wheel
  // at a time: moving the mouse claims it, and src/entities/ship.js hands it
  // straight back the moment left/right (keyboard or the touch pad) is used.
  A.mouseEngaged = true;

  const BUTTON_ACTION = { 0: "fire", 1: "bomb", 2: "hook" };

  A.solo = () => !A.players[1] || A.players[1].out;

  function active() {
    return A.game.phase === "playing" && A.solo();
  }

  // World space and viewport pixels are the same thing here — #game sits at
  // inset:0 with no offset, and the camera in render/gl.js is solved so world
  // (x, y, 0) lands on screen pixel (x, y) exactly — so the pointer position
  // needs no unprojection.
  A.mouseAim = function mouseAim(p) {
    if (A.mouseX === null) return p.angle;
    return Math.atan2(A.mouseY - p.y, A.mouseX - p.x);
  };

  // Pointer events, gated to pointerType "mouse" throughout — a touch tap
  // synthesizes these same events, and without the gate a tap anywhere on
  // the field would read as seat 0's fire/bomb/hook and steal the gesture
  // the touch pad was supposed to get.
  A.installMouseAim = function installMouseAim() {
    window.addEventListener("pointermove", (e) => {
      if (e.pointerType !== "mouse") return;
      A.mouseX = e.clientX; A.mouseY = e.clientY;
      A.mouseEngaged = true;
    });

    window.addEventListener("pointerdown", (e) => {
      if (e.pointerType !== "mouse") return;
      const action = BUTTON_ACTION[e.button];
      if (!action || !active()) return;
      A.pressAction(0, action, false);
      e.preventDefault();
    });

    window.addEventListener("pointerup", (e) => {
      if (e.pointerType !== "mouse") return;
      const action = BUTTON_ACTION[e.button];
      if (action) A.releaseAction(0, action);
    });

    // the right button flies the grapple, not a context menu — but a
    // touch long-press still gets its own menu, same as always
    window.addEventListener("contextmenu", (e) => {
      if (active() && e.pointerType !== "touch") e.preventDefault();
    });
  };
})(ASTEROIDS);
