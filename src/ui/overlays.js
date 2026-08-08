// The splash and game-over screens. This module owns those two elements and
// nothing else owns them — it takes strings and shows them.

(function (A) {
  "use strict";

  const startEl = document.getElementById("start");
  const overEl = document.getElementById("over");
  const finalEl = document.getElementById("finalScore");
  const bestEl = document.getElementById("bestScore");
  const startPrompt = document.getElementById("startPrompt");
  const overPrompt = document.getElementById("overPrompt");

  // The prompt is on this list because it is the only thing on the splash a
  // press starts a game with, and src/input/input.js is where that is wired.
  A.overlayEls = { start: startEl, over: overEl, startPrompt };

  // Whether a menu is up, said out loud on the body so the stylesheet can hear
  // it. The touch pads are the one thing that has to: they are fixed to the
  // foot of the screen and so is the dock, so on a phone the bomb button sits
  // exactly on top of the words TAP TO START. That was untidy while a tap
  // anywhere started the game and it is not any more — a pad parked over the
  // only button that opens the gate is a pad that eats the press. There is
  // nothing to fly on a menu, so there are no pads on one.
  const menu = (on) => document.body.classList.toggle("menu", on);

  A.hideOverlays = function hideOverlays() {
    startEl.hidden = true;
    overEl.hidden = true;
    menu(false);
  };

  /** Back to the menu — from boot, where it is already up, or from a run that
   *  somebody walked out of. */
  A.showStart = function showStart() {
    overEl.hidden = true;
    startEl.hidden = false;
    menu(true);
  };

  A.showGameOver = function showGameOver(scoreHtml, best) {
    finalEl.innerHTML = scoreHtml;
    bestEl.textContent = best;
    overEl.hidden = false;
    menu(true);
  };

  /** Once we know there's a finger on the glass, stop talking about keys. */
  A.setTouchPrompts = function setTouchPrompts() {
    startPrompt.textContent = "TAP TO START";
    overPrompt.textContent = "TAP TO RESTART";
  };
})(ASTEROIDS);
