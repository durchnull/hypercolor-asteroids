// The band. Each voice is one function that schedules a note at a given time
// on a given bus — the song and the death riff both play the same instruments.

(function (A) {
  "use strict";

  A.midi = (m) => 440 * Math.pow(2, (m - 69) / 12);

  /** palm-muted power chord: root + fifth, clipped short so it chugs */
  A.chug = function chug(root, t, dur, dest, sustain) {
    const f = A.midi(root);
    const voices = sustain ? [1, 1.4983, 2] : [1, 1.4983];
    voices.forEach((mul, i) => {
      const o = A.audio.createOscillator();
      const gn = A.audio.createGain();
      o.type = "sawtooth";
      o.frequency.setValueAtTime(f * mul, t);
      const peak = (i === 0 ? 0.5 : 0.3) * (sustain ? 1 : 0.85);
      gn.gain.setValueAtTime(0.0001, t);
      gn.gain.exponentialRampToValueAtTime(peak, t + 0.006);
      if (!sustain) gn.gain.exponentialRampToValueAtTime(peak * 0.25, t + dur * 0.4);
      gn.gain.exponentialRampToValueAtTime(0.0001, t + dur);
      o.connect(gn).connect(dest || A.guitarBus);
      o.start(t);
      o.stop(t + dur + 0.02);
    });
  };

  /** harmonised lead line — the hero melody, doubled a fifth up */
  A.leadNote = function leadNote(note, t, dur) {
    [[0, 0.34], [7, 0.16]].forEach(([iv, vol]) => {
      const o = A.audio.createOscillator();
      const gn = A.audio.createGain();
      o.type = "sawtooth";
      o.frequency.setValueAtTime(A.midi(note + iv), t);
      if (A.vibrato) A.vibrato._amt.connect(o.detune);
      gn.gain.setValueAtTime(0.0001, t);
      gn.gain.exponentialRampToValueAtTime(vol, t + 0.02);
      gn.gain.setValueAtTime(vol, t + dur * 0.7);
      gn.gain.exponentialRampToValueAtTime(0.0001, t + dur);
      o.connect(gn).connect(A.leadBus);
      o.start(t);
      o.stop(t + dur + 0.02);
    });
  };

  A.bassNote = function bassNote(note, t, dur) {
    const o = A.audio.createOscillator();
    const gn = A.audio.createGain();
    o.type = "square";
    o.frequency.setValueAtTime(A.midi(note), t);
    gn.gain.setValueAtTime(0.0001, t);
    gn.gain.exponentialRampToValueAtTime(0.5, t + 0.01);
    gn.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    o.connect(gn).connect(A.bassBus);
    o.start(t);
    o.stop(t + dur + 0.02);
  };

  A.kick = function kick(t, dest) {
    const o = A.audio.createOscillator();
    const gn = A.audio.createGain();
    o.frequency.setValueAtTime(155, t);
    o.frequency.exponentialRampToValueAtTime(45, t + 0.07);
    gn.gain.setValueAtTime(0.9, t);
    gn.gain.exponentialRampToValueAtTime(0.001, t + 0.14);
    o.connect(gn).connect(dest || A.drumBus);
    o.start(t);
    o.stop(t + 0.16);
  };

  A.snare = function snare(t, dest) {
    const src = A.noiseSource();
    const bp = A.audio.createBiquadFilter();
    bp.type = "bandpass";
    bp.frequency.value = 1800;
    bp.Q.value = 0.7;
    const gn = A.audio.createGain();
    gn.gain.setValueAtTime(0.6, t);
    gn.gain.exponentialRampToValueAtTime(0.001, t + 0.16);
    src.connect(bp).connect(gn).connect(dest || A.drumBus);
    src.start(t);
    src.stop(t + 0.18);
    // a little body under the crack
    const o = A.audio.createOscillator();
    const og = A.audio.createGain();
    o.frequency.setValueAtTime(190, t);
    o.frequency.exponentialRampToValueAtTime(120, t + 0.09);
    og.gain.setValueAtTime(0.25, t);
    og.gain.exponentialRampToValueAtTime(0.001, t + 0.1);
    o.connect(og).connect(dest || A.drumBus);
    o.start(t);
    o.stop(t + 0.12);
  };

  A.hat = function hat(t, open) {
    const src = A.noiseSource();
    const hp = A.audio.createBiquadFilter();
    hp.type = "highpass";
    hp.frequency.value = 7000;
    const gn = A.audio.createGain();
    const dur = open ? 0.18 : 0.045;
    gn.gain.setValueAtTime(open ? 0.16 : 0.1, t);
    gn.gain.exponentialRampToValueAtTime(0.001, t + dur);
    src.connect(hp).connect(gn).connect(A.drumBus);
    src.start(t);
    src.stop(t + dur + 0.01);
  };

  A.crash = function crash(t, dest) {
    const src = A.noiseSource();
    const hp = A.audio.createBiquadFilter();
    hp.type = "highpass";
    hp.frequency.value = 5200;
    const gn = A.audio.createGain();
    gn.gain.setValueAtTime(0.42, t);
    gn.gain.exponentialRampToValueAtTime(0.001, t + 1.1);
    src.connect(hp).connect(gn).connect(dest || A.drumBus);
    src.start(t);
    src.stop(t + 1.15);
  };
})(ASTEROIDS);
