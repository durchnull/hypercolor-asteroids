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

  // Exposed so another input source — the mouse, so far — can drive the same
  // tables through the same press/release rules instead of poking keys/held
  // directly.
  A.pressAction = press;
  A.releaseAction = release;

  // A seat's fire button on the game-over screen restarts with that seat in
  // it, so player two can call for another round rather than waiting to be let
  // in. On the splash it does not — see below, and src/ui/lobby.js.
  function startFrom(seat) {
    A.ensureAudio();
    A.startGame(seat > 0 ? [0, seat] : [0]);
  }

  /** The gate, and the two things allowed to open it: ENTER, and the button
   *  in the dock that says so. Everybody the lobby has sat down goes in. */
  function openTheGate() {
    A.ensureAudio();
    A.startGame(A.seatedPilots());
  }

  A.installInput = function installInput() {
    window.addEventListener("keydown", (e) => {
      const bind = A.KEYMAP[e.code];
      if (bind) {
        press(bind.seat, bind.action, e.repeat);
        e.preventDefault();
      }
      const phase = A.game.phase;
      // On the splash a fire key takes its seat and stops there; the lobby
      // holds the roster until ENTER asks for it. Seat one is already down, so
      // its key has nothing left to do on this screen, which is the point:
      // there is exactly one way into a flight from here.
      if (phase === "start" && bind && bind.action === "fire") {
        A.ensureAudio();
        A.takeSeat(bind.seat);
        e.preventDefault();
      } else if (e.code === "Enter" || (phase === "over" && bind && bind.action === "fire")) {
        if (phase === "start") openTheGate();
        else if (phase === "over") startFrom(bind ? bind.seat : 0);
        else A.ensureAudio();
        e.preventDefault();
      }
      if (e.code === "KeyP" && A.game.phase === "playing") A.game.paused = !A.game.paused;
      if (e.code === "KeyM") A.toggleMute();
    });

    window.addEventListener("keyup", (e) => {
      const bind = A.KEYMAP[e.code];
      if (bind) release(bind.seat, bind.action);
    });

    // Tapping the game-over screen anywhere is the same as pressing start —
    // except on a link, which is a link, and anything anybody puts on that
    // overlay later gets the same courtesy.
    function tapToStart(phase) {
      return (e) => {
        if (e.target.closest("a")) return;
        A.ensureAudio();
        if (A.game.phase === phase) A.startGame();
      };
    }
    A.overlayEls.over.addEventListener("pointerdown", tapToStart("over"));

    // The splash is not that screen. It is six panels of reading with a door
    // out to the book in it, a pilot to choose and a deck to scroll, and every
    // one of those is a press somebody makes without meaning to launch
    // anything. So the whole overlay does not answer a hand any more — one
    // button in the dock does, and it is the button that says what it does.
    A.overlayEls.startPrompt.addEventListener("pointerdown", (e) => {
      if (A.game.phase !== "start") return;
      openTheGate();
      e.preventDefault();
    });

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
