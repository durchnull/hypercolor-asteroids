// The sound toggle. Owns the button, its label and the M key's opinion.
//
// Three things it can honestly say, because for most of a session's first few
// seconds the honest answer is neither ON nor OFF: the sound is coming and the
// browser has not let it in yet (src/audio/context.js explains the wait). A
// sign in an arcade that says the machine makes a noise, on a machine that is
// not making one, is the one bit of furniture nobody trusts twice.

(function (A) {
  "use strict";

  const btn = document.getElementById("mute");

  function awake() {
    return !!A.audio && A.audio.state === "running";
  }

  function label() {
    btn.textContent = A.muted ? "SOUND OFF" : awake() ? "SOUND ON" : "PRESS FOR SOUND";
    btn.title = A.muted || awake() ? "" : "the browser wants a press before this can make a noise";
  }

  A.toggleMute = function toggleMute() {
    // The press that wakes the cabinet is not a press that silences it. Half
    // the time this button is being pressed to find out whether the thing
    // makes any noise at all, and answering OFF to that question is the wrong
    // answer — same argument src/ui/clicks.js makes about the first press.
    if (awake()) A.setMuted(!A.muted);
    else A.ensureAudio();
    label();
  };

  btn.addEventListener("click", A.toggleMute);

  // The sound can arrive from anywhere — ENTER, a pilot card, the first key of
  // the session — so the sign follows the graph rather than the button.
  A.onAudioReady(() => {
    A.audio.addEventListener("statechange", label);
    label();
  });

  label();
})(ASTEROIDS);
