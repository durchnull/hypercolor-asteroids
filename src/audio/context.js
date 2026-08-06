// One shared Web Audio graph for the whole cabinet. No samples, no network —
// every sound in the game is synthesised at runtime.
//
// The context cannot exist until the player has touched something, so anything
// that needs to build nodes at startup registers with A.onAudioReady() and is
// called once, in manifest order, the first time the audio comes up.

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

  A.ensureAudio = function ensureAudio() {
    if (!A.audio && (window.AudioContext || window.webkitAudioContext)) {
      const audio = new (window.AudioContext || window.webkitAudioContext)();
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
})(ASTEROIDS);
