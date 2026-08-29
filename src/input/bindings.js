// Seats at the cabinet.
//
// This is the only file that knows which key does what, what a seat is called
// and what colour it flies. The HUD panels, the lobby cards on the splash, the
// key map and the touch pad are all generated from it — add a third seat here
// and a third seat appears everywhere, without touching anything else.

(function (A) {
  "use strict";

  /** Everything a pilot can do. A new verb starts life as an entry here. */
  A.ACTIONS = ["left", "right", "thrust", "fire", "hook", "bomb"];

  /** One action per physical press — auto-repeat must not re-trigger these. */
  A.EDGE = new Set(["bomb", "hook"]);

  A.SEATS = [
    {
      tag: "P1",
      name: "PLAYER 1",
      hue: 180,
      tint: "var(--cyan)",
      side: "left",
      keys: {
        left: "ArrowLeft", right: "ArrowRight", thrust: "ArrowUp",
        fire: "Period", hook: "ArrowDown", bomb: "KeyL",
      },
      binds: [
        ["&larr; &rarr;", "turn"],
        ["&uarr;", "thrust"],
        [".", "fire"],
        ["&darr;", "grapple &middot; hold to winch"],
        ["L", "bomb"],
      ],
      lobby: "READY",              // this seat is always in the game
      joinHint: "",                // …so it never advertises itself on the HUD
      rejoinHint: "PRESS . TO REJOIN",
    },
    {
      tag: "P2",
      name: "PLAYER 2",
      hue: 45,
      tint: "var(--amber)",
      side: "right",
      keys: {
        left: "KeyA", right: "KeyD", thrust: "KeyW",
        fire: "KeyQ", hook: "KeyS", bomb: "KeyE",
      },
      binds: [
        ["A D", "turn"],
        ["W", "thrust"],
        ["Q", "fire"],
        ["S", "grapple &middot; hold to winch"],
        ["E", "bomb"],
      ],
      lobby: "PRESS Q TO DROP IN",
      joinHint: "PRESS Q TO JOIN",
      rejoinHint: "PRESS Q TO REJOIN",
    },
  ];

  /** Touch pad, left group and right group. Buttons drive seat 0. */
  A.TOUCH_PADS = [
    [
      { action: "left", glyph: "&#8634;", label: "Rotate left" },
      { action: "right", glyph: "&#8635;", label: "Rotate right" },
    ],
    [
      { action: "bomb", glyph: "&#9763;", label: "Atom bomb", cls: "bomb" },
      { action: "hook", glyph: "&#8623;", label: "Grappling hook", cls: "hookbtn" },
      { action: "thrust", glyph: "&uarr;", label: "Thrust" },
      { action: "fire", glyph: "&bull;", label: "Fire" },
    ],
  ];

  /** code → { seat, action }, derived so a rebind above is the whole change. */
  A.KEYMAP = {};
  A.SEATS.forEach((seat, i) => {
    for (const action of A.ACTIONS) {
      const code = seat.keys[action];
      if (code) A.KEYMAP[code] = { seat: i, action };
    }
  });
})(ASTEROIDS);
