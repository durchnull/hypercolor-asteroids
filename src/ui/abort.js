// The way out, and the one question it asks first.
//
// P stops the field and M stops the band, but until now there was no way off
// this cabinet except dying, which is a strange thing to make somebody do when
// they only wanted their evening back. ESC is that way out.
//
// It does not take it on the first press. A flight that ends because a rock
// found you is a flight; a flight that ends because a hand went to the wrong
// corner of the keyboard is an accident, and this is the one control on the
// cabinet whose accident cannot be undone. So the first ESC freezes the field,
// puts the run's own numbers up where the pilot has to look at them, and waits.
//
// The two answers are deliberately lopsided. Leaving costs a second, exact
// press of the same key. Staying costs anything at all — every other key on the
// board says fly on, because a pilot with the kraken surfacing under them who
// reaches for the wrong thing should end up back in the game rather than out of
// it. Nothing here is a trick question.
//
// What you give up by walking is the record: no tape, no best score, nothing
// for the board. That is not a punishment, it is what a run that nobody
// finished is worth, and saying so on the panel is the whole reason the panel
// has room for a third line.

(function (A) {
  "use strict";

  const W = 520;          // the panel, or the screen if the screen is narrower
  const H = 214;
  const MARGIN = 36;
  const POP = 0.18;       // seconds it takes to arrive

  // a modifier is a hand on its way somewhere, not an answer
  const REACHING = new Set([
    "ShiftLeft", "ShiftRight", "ControlLeft", "ControlRight",
    "AltLeft", "AltRight", "MetaLeft", "MetaRight", "CapsLock",
  ]);

  let wasPaused = false;
  let age = 0;

  function arm() {
    wasPaused = A.game.paused;
    A.game.holding = true;
    A.game.paused = true;
    age = 0;
    // whatever was under the thumb when the question came up is not an answer
    // to it, and must not still be latched when the game starts again
    A.clearEdgeKeys();
    A.uiDeny();
  }

  function stay() {
    A.game.holding = false;
    A.game.paused = wasPaused;
    A.clearEdgeKeys();
    A.uiClick(2);
  }

  function leave() {
    A.game.holding = false;
    A.game.paused = false;
    A.clearEdgeKeys();
    A.uiDoor(4);
    A.attract();
  }

  // Capture, and ahead of input.js on purpose: while the question is up, the
  // keyboard belongs to the question. P especially — a pilot who answers this
  // with the pause key must not also unpause the field they are standing in.
  window.addEventListener("keydown", (e) => {
    // a key held down asks once; without this, leaning on ESC arms the panel
    // and then answers it on the first repeat
    if (e.repeat || e.ctrlKey || e.metaKey || e.altKey) return;

    if (!A.game.holding) {
      if (e.code !== "Escape" || A.game.phase !== "playing") return;
      arm();
      e.preventDefault();
      return;
    }

    if (REACHING.has(e.code)) return;
    if (e.code === "Escape") leave();
    else stay();
    e.preventDefault();
    e.stopImmediatePropagation();
  }, true);

  function reset() {
    A.game.holding = false;
    age = 0;
  }

  // ---- the panel ----------------------------------------------------------

  /** What the run is worth, which is the number the question is really about. */
  function standing() {
    const joined = A.players.filter(Boolean);
    const scores = joined.length > 1
      ? joined.map((p) => A.SEATS[p.idx].tag + " " + p.score).join("     ")
      : "SCORE " + (joined[0] ? joined[0].score : 0);
    return scores + "     WAVE " + A.game.level;
  }

  function say(ctx, text, y, size, spacing, hue, light, alpha) {
    ctx.globalAlpha = alpha;
    ctx.fillStyle = A.neon(A.hue + hue, light);
    ctx.font = "600 " + size + "px " + A.FONT;
    ctx.letterSpacing = spacing + "px";
    ctx.fillText(text, 0, y);
  }

  /** Corner brackets rather than a closed box: it is a sight, not a dialog. */
  function brackets(ctx, w, h, len) {
    ctx.beginPath();
    for (const sx of [-1, 1]) {
      for (const sy of [-1, 1]) {
        const x = (sx * w) / 2;
        const y = (sy * h) / 2;
        ctx.moveTo(x - sx * len, y);
        ctx.lineTo(x, y);
        ctx.lineTo(x, y - sy * len);
      }
    }
    ctx.stroke();
  }

  function chrome(tick, ctx) {
    if (!A.game.holding) return;
    age = Math.min(age + tick.raw, 99);

    const pop = Math.min(1, age / POP);
    const ease = pop * pop * (3 - 2 * pop);
    const w = W;
    const h = H;

    // A narrow window shrinks the whole panel rather than reflowing it: the
    // lines are written to sit beside each other and half of what they say is
    // that there are two answers.
    const fit = Math.min(1, (A.W - MARGIN * 2) / W, (A.H - MARGIN * 2) / H);
    const scale = fit * (0.94 + ease * 0.06);

    // the field goes quiet behind the question, rather than away
    ctx.save();
    ctx.fillStyle = "rgba(2,0,8,0.88)";
    ctx.globalAlpha = ease;
    ctx.fillRect(0, 0, A.W, A.H);

    ctx.translate(A.W / 2, A.H / 2);
    ctx.scale(scale, scale);
    ctx.textAlign = "center";
    ctx.lineCap = "round";

    // the frame breathes, so a panel over a stopped field is still alive
    const breath = 0.72 + 0.28 * Math.sin(age * 3.4);
    ctx.globalAlpha = ease * breath;
    ctx.strokeStyle = A.neon(A.hue * 2, 64);
    ctx.lineWidth = 1.6;
    brackets(ctx, w, h, 26);
    ctx.globalAlpha = ease * 0.28;
    ctx.lineWidth = 1;
    ctx.strokeRect(-w / 2, -h / 2, w, h);

    const top = -h / 2;
    say(ctx, "ABORT FLIGHT?", top + 54, 23, 9, 0, 70, ease);
    say(ctx, standing(), top + 92, 13, 5, 120, 62, ease * 0.85);
    say(ctx, "NOTHING ABOUT THIS RUN GOES ON THE RECORD",
        top + 116, 10, 3, 60, 56, ease * 0.68);

    // the two answers, and the gap between them is the point: one of them is a
    // second deliberate press, the other is anything you like
    ctx.globalAlpha = ease * 0.3;
    ctx.strokeStyle = A.neon(A.hue * 2, 60);
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(0, top + 140);
    ctx.lineTo(0, top + 188);
    ctx.stroke();

    const half = w / 4;
    ctx.save();
    ctx.translate(-half, 0);
    say(ctx, "ESC AGAIN", top + 162, 13, 4, 300, 66, ease);
    say(ctx, "AND YOU ARE OUT", top + 180, 9, 2, 300, 58, ease * 0.85);
    ctx.restore();
    ctx.translate(half, 0);
    say(ctx, "ANY OTHER KEY", top + 162, 13, 4, 150, 66, ease);
    say(ctx, "AND YOU FLY ON", top + 180, 9, 2, 150, 58, ease * 0.85);

    ctx.letterSpacing = "0px";
    ctx.restore();
  }

  A.register({
    id: "abort",
    // under the mark, over the band: it is the cabinet rather than the field
    order: { guide: 94 },
    reset, chrome,
    guide: {
      name: "THE WAY OUT",
      meta: "ESC",
      tint: "var(--amber)",
      icon: `<svg width="34" height="34" viewBox="0 0 34 34" fill="none"
        stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"
        stroke-linecap="round" aria-hidden="true">
        <path d="M18 5H7v24h11"/>
        <path d="M14 17h13M22 12l5 5-5 5"/></svg>`,
      desc: `ESC asks whether you meant it, and holds the field still while it
        waits. ESC again and you are out; any other key and you never left. A
        run walked out of goes on no record at all.`,
    },
  });
})(ASTEROIDS);
