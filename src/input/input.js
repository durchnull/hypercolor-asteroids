// What is being pressed, per seat.
//
//   A.keys[seat][action]   consumed on read for the one-shots (bomb, grapple),
//                          so a tap quicker than a frame still counts
//   A.held[seat][action]   an honest picture of what is still physically down,
//                          which is what the winch needs
//
// Features read these two tables and nothing else. Which physical key feeds
// them is bindings.js's business.

(function (A) {
  "use strict";

  const blank = () => Object.fromEntries(A.ACTIONS.map((a) => [a, false]));

  const keys = A.keys = A.SEATS.map(blank);
  const held = A.held = A.SEATS.map(blank);

  /** Drop latched one-shots — for one seat, or for the whole cabinet. */
  A.clearEdgeKeys = function clearEdgeKeys(seat) {
    const seats = seat === undefined ? keys.map((_, i) => i) : [seat];
    for (const i of seats) for (const a of A.EDGE) keys[i][a] = false;
  };

  function press(seat, action, repeat) {
    if (!(repeat && A.EDGE.has(action))) keys[seat][action] = true;
    held[seat][action] = true;
  }

  function release(seat, action) {
    held[seat][action] = false;
    // a one-shot stays latched until the loop has taken it
    if (!A.EDGE.has(action)) keys[seat][action] = false;
  }

  // A seat's fire button on a menu screen starts a game with that seat in it,
  // so player two can open the game rather than waiting to be let in.
  function startFrom(seat) {
    A.ensureAudio();
    A.startGame(seat > 0 ? [0, seat] : [0]);
  }

  A.installInput = function installInput() {
    window.addEventListener("keydown", (e) => {
      const bind = A.KEYMAP[e.code];
      if (bind) {
        press(bind.seat, bind.action, e.repeat);
        e.preventDefault();
      }
      const menu = A.game.phase !== "playing";
      if (e.code === "Enter" || (menu && bind && bind.action === "fire")) {
        if (A.game.phase === "start" || A.game.phase === "over") {
          startFrom(bind && menu ? bind.seat : 0);
        } else {
          A.ensureAudio();
        }
        e.preventDefault();
      }
      if (e.code === "KeyP" && A.game.phase === "playing") A.game.paused = !A.game.paused;
      if (e.code === "KeyM") A.toggleMute();
    });

    window.addEventListener("keyup", (e) => {
      const bind = A.KEYMAP[e.code];
      if (bind) release(bind.seat, bind.action);
    });

    // Tapping an overlay is the same as pressing start — except on a link,
    // which is a link. The splash has one out to the chronicle, and a door you
    // cannot walk through because the room starts the game instead is not a
    // door. Anything anybody puts on an overlay later gets the same courtesy.
    function tapToStart(phase) {
      return (e) => {
        if (e.target.closest("a")) return;
        A.ensureAudio();
        if (A.game.phase === phase) A.startGame();
      };
    }
    A.overlayEls.start.addEventListener("pointerdown", tapToStart("start"));
    A.overlayEls.over.addEventListener("pointerdown", tapToStart("over"));

    installTouch();
  };

  // ---------- touch ----------
  function installTouch() {
    const root = document.getElementById("touch");
    for (const group of A.TOUCH_PADS) {
      const pad = document.createElement("div");
      pad.className = "pad";
      for (const b of group) {
        const el = document.createElement("button");
        if (b.cls) el.className = b.cls;
        el.innerHTML = b.glyph;
        el.setAttribute("aria-label", b.label);
        bindHold(el, 0, b.action);
        pad.append(el);
      }
      root.append(pad);
    }

    window.addEventListener("touchstart", function once() {
      document.body.classList.add("has-touch");
      A.setTouchPrompts();
      window.removeEventListener("touchstart", once);
    }, { passive: true });
  }

  function bindHold(el, seat, action) {
    const up = () => release(seat, action);
    el.addEventListener("pointerdown", (e) => {
      press(seat, action, false);
      e.preventDefault();
    });
    el.addEventListener("pointerup", up);
    el.addEventListener("pointercancel", up);
    el.addEventListener("pointerleave", up);
  }
})(ASTEROIDS);
