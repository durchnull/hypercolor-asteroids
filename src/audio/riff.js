// The death riff. Same key and tempo as the track, but the band stops
// everything else: gallop lick, harmonised wail, and a whammy dive when it is
// really over.

(function (A) {
  "use strict";

  A.playRiff = function playRiff(full) {
    if (!A.audio || A.muted) return;
    const audio = A.audio;
    const STEP = A.STEP, BAR = A.BAR;
    const t0 = audio.currentTime + 0.02;
    A.duck(0.02 + (full ? 5.2 : 1.6));

    const shaper = audio.createWaveShaper();
    shaper.curve = A.distCurve;
    shaper.oversample = "4x";
    const lo = audio.createBiquadFilter();
    lo.type = "lowpass";
    lo.frequency.value = 3000;
    const hi = audio.createBiquadFilter();
    hi.type = "highpass";
    hi.frequency.value = 90;
    const amp = audio.createGain();
    amp.gain.value = 0.42;
    shaper.connect(lo).connect(hi).connect(amp).connect(A.master);

    const drums = audio.createGain();
    drums.gain.value = 0.75;
    drums.connect(A.master);

    // bar 1: gallop on E with a walk up — pure Saturday-morning action theme
    const lick = [
      [40, 0, 2], [40, 2, 1], [40, 3, 1], [40, 4, 2], [40, 6, 1], [40, 7, 1],
      [43, 8, 2], [45, 10, 2], [46, 12, 2], [47, 14, 2],
    ];
    const lick2 = [
      [48, 16, 3], [48, 20, 1], [47, 21, 1], [45, 22, 2],
      [43, 24, 4], [41, 28, 2], [40, 30, 2],
    ];
    const notes = full ? lick.concat(lick2) : lick;
    for (const [n, at, len] of notes) {
      A.chug(n, t0 + at * STEP, len * STEP * 1.15, shaper, len >= 3);
    }

    A.crash(t0, drums);
    const bars = full ? 2 : 1;
    for (let b = 0; b < bars; b++) {
      for (const s of A.DOUBLE_KICKS) A.kick(t0 + (b * BAR + s) * STEP, drums);
      for (const s of A.SNARES) A.snare(t0 + (b * BAR + s) * STEP, drums);
    }

    // harmonised lead wail across the top
    const wail = full
      ? [[76, 0, 4], [79, 4, 4], [78, 8, 4], [76, 12, 4], [83, 16, 8], [81, 24, 8]]
      : [[76, 0, 4], [79, 4, 4], [78, 8, 8]];
    for (const [n, at, len] of wail) {
      A.leadNote(n, t0 + at * STEP, len * STEP * 0.9);
    }

    if (!full) return;

    // whammy dive into the floor
    const end = t0 + 32 * STEP;
    A.crash(end, drums);
    [1, 1.4983].forEach((mul) => {
      const o = audio.createOscillator();
      const gn = audio.createGain();
      o.type = "sawtooth";
      o.frequency.setValueAtTime(A.midi(40) * mul * 2, end);
      o.frequency.exponentialRampToValueAtTime(28, end + 1.6);
      gn.gain.setValueAtTime(0.0001, end);
      gn.gain.exponentialRampToValueAtTime(0.45, end + 0.01);
      gn.gain.exponentialRampToValueAtTime(0.0001, end + 1.8);
      o.connect(gn).connect(shaper);
      o.start(end);
      o.stop(end + 1.85);
    });
    // pinch-harmonic squeal riding over the dive
    const sq = audio.createOscillator();
    const sg = audio.createGain();
    sq.type = "sawtooth";
    sq.frequency.setValueAtTime(1480, end);
    sq.frequency.exponentialRampToValueAtTime(2700, end + 0.4);
    sg.gain.setValueAtTime(0.0001, end);
    sg.gain.exponentialRampToValueAtTime(0.15, end + 0.02);
    sg.gain.exponentialRampToValueAtTime(0.0001, end + 1.0);
    sq.connect(sg).connect(shaper);
    sq.start(end);
    sq.stop(end + 1.05);
  };
})(ASTEROIDS);
