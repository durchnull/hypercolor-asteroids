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

  A.overlayEls = { start: startEl, over: overEl };

  A.hideOverlays = function hideOverlays() {
    startEl.hidden = true;
    overEl.hidden = true;
  };

  /** Back to the menu — from boot, where it is already up, or from a run that
   *  somebody walked out of. */
  A.showStart = function showStart() {
    overEl.hidden = true;
    startEl.hidden = false;
  };

  A.showGameOver = function showGameOver(scoreHtml, best) {
    finalEl.innerHTML = scoreHtml;
    bestEl.textContent = best;
    overEl.hidden = false;
  };

  /** Once we know there's a finger on the glass, stop talking about keys. */
  A.setTouchPrompts = function setTouchPrompts() {
    startPrompt.textContent = "TAP TO START";
    overPrompt.textContent = "TAP TO RESTART";
  };
})(ASTEROIDS);
