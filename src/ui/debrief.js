// The debrief: the black box tape on the game-over screen, with a copy
// button. game/blackbox.js seals the tape when the flight ends; this panel
// only shows it and hands it over.
//
// One trap worth knowing about: tapping anywhere on the game-over overlay
// restarts the game (input.js wires pointerdown on the whole element), so
// this panel stops pointerdown from bubbling — copying the tape must not
// launch the next flight out from under the pilot.

(function (A) {
  "use strict";

  const COPIED_FOR = 2.6;   // seconds the button brags before it resets

  const mount = document.getElementById("debrief");
  let revertAt = 0;

  const pre = document.createElement("pre");
  pre.className = "tape";

  const button = document.createElement("button");
  button.type = "button";
  button.className = "copytape";

  const IDLE = "COPY THE TAPE";
  button.textContent = IDLE;

  mount.append(pre, button);
  mount.addEventListener("pointerdown", (e) => e.stopPropagation());

  function fallbackCopy(text) {
    const t = document.createElement("textarea");
    t.value = text;
    t.style.position = "fixed";
    t.style.opacity = "0";
    document.body.append(t);
    t.select();
    let ok = false;
    try { ok = document.execCommand("copy"); } catch (e) {}
    t.remove();
    return ok;
  }

  function copied() {
    button.textContent = "COPIED — TAKE IT TO CLAUDE";
    revertAt = performance.now() + COPIED_FOR * 1000;
    A.blip(880, 0.09, "square", 0.1);
  }

  button.addEventListener("click", () => {
    const tape = A.blackboxTape();
    if (!tape) return;
    // ENTER restarts the game; a focused button would eat it as a click
    button.blur();
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(tape.text).then(copied, () => {
        if (fallbackCopy(tape.text)) copied();
      });
    } else if (fallbackCopy(tape.text)) {
      copied();
    }
  });

  function reset(mode) {
    if (mode !== "over") { mount.hidden = true; return; }
    const tape = A.blackboxTape();
    if (!tape) return;
    pre.textContent = tape.text;
    pre.scrollTop = 0;          // the panel is reused; last flight's scroll is not this flight's
    button.textContent = IDLE;
    mount.hidden = false;
  }

  function update() {
    if (revertAt && performance.now() >= revertAt) {
      revertAt = 0;
      button.textContent = IDLE;
    }
  }

  // after blackbox's reset (60): the tape is sealed before it is shown
  A.register({ id: "debrief", order: { reset: 70 }, reset, update });
})(ASTEROIDS);
