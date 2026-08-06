// The sound toggle. Owns the button, its label and the M key's opinion.

(function (A) {
  "use strict";

  const btn = document.getElementById("mute");

  A.toggleMute = function toggleMute() {
    btn.textContent = A.setMuted(!A.muted) ? "SOUND OFF" : "SOUND ON";
  };

  btn.addEventListener("click", A.toggleMute);
})(ASTEROIDS);
