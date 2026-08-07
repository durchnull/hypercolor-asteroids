// One shared Web Audio graph for the whole cabinet. No samples, no network —
// every sound in the game is synthesised at runtime.
//
// The graph cannot make a noise until the player has touched something, so
// anything that needs to build nodes at startup registers with A.onAudioReady()
// and is called once, in manifest order, the first time the audio comes up.
// When that is depends on the browser rather than on us — see "coming up" at
// the foot of this file, which is where the sound starts itself if it can and
// waits for the first thing the pilot does if it cannot.

(function (A) {
  "use strict";

  A.audio = null;
  A.master = null;
  A.distCurve = null;
  A.NOISE = null;
  A.muted = false;

  const ready = [];
  /** Run `fn` once, when the audio context first comes to life. */
  A.onAudioReady = (fn) => ready.push(fn);

  const Ctx = window.AudioContext || window.webkitAudioContext;

  // A context the browser would not start, made at load and kept rather than
  // thrown away. The graph is not built on it; it is what the first touch
  // reaches for. See "coming up" at the foot of the file.
  let waiting = null;

  // Hang the graph off a context and tell everybody who was waiting for one.
  // Called once a context exists that is running or about to be — never on one
  // that has no prospect of it, because everything downstream of here checks
  // `A.audio` to decide whether a sound is worth making, and a graph that
  // exists before the clock does quietly collects every noise nobody could
  // hear and plays the lot at once the moment it starts.
  function rig(audio) {
    A.audio = audio;
    const master = audio.createGain();
    master.gain.value = 0.9;
    // a limiter so the riff and a screenful of explosions can't clip
    const comp = audio.createDynamicsCompressor();
    comp.threshold.value = -14;
    comp.knee.value = 14;
    comp.ratio.value = 7;
    comp.attack.value = 0.004;
    comp.release.value = 0.16;
    master.connect(comp).connect(audio.destination);
    A.master = master;
    A.distCurve = A.makeDistortion(120);
    A.NOISE = audio.createBuffer(1, Math.ceil(audio.sampleRate * 1.2), audio.sampleRate);
    const d = A.NOISE.getChannelData(0);
    for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1;
    for (const fn of ready) fn();
  }

  A.ensureAudio = function ensureAudio() {
    if (!A.audio && Ctx) rig(waiting || new Ctx());
    waiting = null;
    if (A.audio && A.audio.state === "suspended") A.audio.resume();
  };

  A.makeDistortion = function makeDistortion(amount) {
    const n = 2048;
    const curve = new Float32Array(n);
    const deg = Math.PI / 180;
    for (let i = 0; i < n; i++) {
      const x = (i * 2) / n - 1;
      curve[i] = ((3 + amount) * x * 20 * deg) / (Math.PI + amount * Math.abs(x));
    }
    return curve;
  };

  A.noiseSource = function noiseSource() {
    const s = A.audio.createBufferSource();
    s.buffer = A.NOISE;
    s.loop = true;
    return s;
  };

  A.setMuted = function setMuted(m) {
    A.muted = m;
    A.ensureAudio();
    return A.muted;
  };

  // ---- coming up ----------------------------------------------------------
  //
  // The switch in the corner has said SOUND ON since the page drew itself, and
  // for a while that was a promise the cabinet could not keep. No browser lets
  // a page make a noise before somebody has touched it, so a machine that
  // plays ten different bands sat there in silence under a sign saying
  // otherwise, and the first thing anyone heard was whatever happened after
  // ENTER. The menu vamp — one of the two arrangements every theme in
  // src/audio/themes.js is written with — was reachable by clicking a panel
  // and by almost nothing else anybody actually does.
  //
  // Two halves to keeping the promise, and neither of them argues with the
  // browser about whose page it is.
  //
  // Making a context is free and silent, so one is made as soon as the page
  // has finished loading, and asked. A browser that already trusts this page
  // hands back one that is running — it has been played on before, or it was
  // told to allow this, or somebody opened the file off a disk — and the band
  // starts with nobody having touched anything, which is what the sign said.
  //
  // Everywhere else it comes back suspended, and then the first thing the
  // pilot does is the cue, whatever that thing is: any key, any press,
  // anywhere on the screen. Not only ENTER, and not only the panels that
  // already answer a hand. Somebody who walks up to this and pushes something
  // has said yes to sound, and should not have to say it twice.

  const WAKERS = ["pointerdown", "keydown", "touchstart"];

  function firstTouch() {
    A.ensureAudio();
    if (!A.audio) return disarm();
    // resume() settles a tick later, so this is the only place the state is
    // worth reading. A browser still saying no leaves the listeners armed.
    const p = A.audio.resume();
    if (p && p.then) p.then(disarm, () => {});
    else disarm();
  }

  function disarm() {
    for (const ev of WAKERS) window.removeEventListener(ev, firstTouch, true);
  }

  function comeUp() {
    if (A.audio || waiting || !Ctx) return;
    const audio = new Ctx();
    if (audio.state === "running") return rig(audio);
    waiting = audio;
    for (const ev of WAKERS) window.addEventListener(ev, firstTouch, true);
    // Some browsers make their mind up a moment after being asked, and one
    // that changes it in our favour should not need a hand as well.
    audio.addEventListener("statechange", function second() {
      if (waiting !== audio || audio.state !== "running") return;
      audio.removeEventListener("statechange", second);
      waiting = null;
      rig(audio);
      disarm();
    });
  }

  // Every module that registers with onAudioReady is loaded by then, which is
  // the whole reason this waits for the page rather than running here.
  if (document.readyState === "complete") comeUp();
  else window.addEventListener("load", comeUp);
})(ASTEROIDS);
