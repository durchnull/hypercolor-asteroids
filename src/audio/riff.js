// The other two pieces of the soundtrack: the sting when you lose a ship, and
// the one that plays you out. Same key and tempo as whatever track is running,
// because both come out of the same theme — see src/audio/themes.js — but the
// band stops everything else to play them.
//
// A riff is its own signal chain rather than the music bus, so it cuts through
// the track it just ducked instead of being ducked along with it.

(function (A) {
  "use strict";

  A.playRiff = function playRiff(full) {
    if (!A.audio || A.muted) return;
    const audio = A.audio;
    const STEP = A.STEP, BAR = A.BAR;
    const tone = A.theme.tone;
    const riff = full ? A.theme.over : A.theme.death;
    const t0 = audio.currentTime + 0.02;
    A.duck(0.02 + riff.dur);

    const shaper = audio.createWaveShaper();
    shaper.curve = A.makeDistortion(tone.riffDrive);
    shaper.oversample = "4x";
    const lo = audio.createBiquadFilter();
    lo.type = "lowpass";
    lo.frequency.value = tone.riffLo;
    const hi = audio.createBiquadFilter();
    hi.type = "highpass";
    hi.frequency.value = 90;
    const amp = audio.createGain();
    amp.gain.value = 0.42;
    shaper.connect(lo).connect(hi).connect(amp).connect(A.master);

    const drums = audio.createGain();
    drums.gain.value = 0.75;
    drums.connect(A.master);

    // the lick, then the kit under it, then the wail across the top
    for (const [n, at, len] of riff.chugs) {
      A.chug(n, t0 + at * STEP, len * STEP * 1.15, shaper, len >= 3);
    }

    A.crash(t0, drums);
    for (let b = 0; b < riff.bars; b++) {
      for (const s of riff.kicks) A.kick(t0 + (b * BAR + s) * STEP, drums);
      for (const s of riff.snares) A.snare(t0 + (b * BAR + s) * STEP, drums);
    }

    for (const [n, at, len] of riff.wail) {
      A.leadNote(n, t0 + at * STEP, len * STEP * 0.9);
    }

    if (!riff.dive) return;

    // whammy dive into the floor, and a pinch harmonic riding over it
    const [from, to, fall] = riff.dive;
    const end = t0 + riff.bars * BAR * STEP;
    A.crash(end, drums);
    [1, 1.4983].forEach((mul) => {
      const o = audio.createOscillator();
      const gn = audio.createGain();
      o.type = tone.guitar;
      o.frequency.setValueAtTime(A.midi(from) * mul * 2, end);
      o.frequency.exponentialRampToValueAtTime(to, end + fall);
      gn.gain.setValueAtTime(0.0001, end);
      gn.gain.exponentialRampToValueAtTime(0.45, end + 0.01);
      gn.gain.exponentialRampToValueAtTime(0.0001, end + fall + 0.2);
      o.connect(gn).connect(shaper);
      o.start(end);
      o.stop(end + fall + 0.25);
    });

    if (!riff.squeal) return;
    const [sFrom, sTo, sDur] = riff.squeal;
    const sq = audio.createOscillator();
    const sg = audio.createGain();
    sq.type = tone.lead;
    sq.frequency.setValueAtTime(sFrom, end);
    sq.frequency.exponentialRampToValueAtTime(sTo, end + sDur * 0.4);
    sg.gain.setValueAtTime(0.0001, end);
    sg.gain.exponentialRampToValueAtTime(0.15, end + 0.02);
    sg.gain.exponentialRampToValueAtTime(0.0001, end + sDur);
    sq.connect(sg).connect(shaper);
    sq.start(end);
    sq.stop(end + sDur + 0.05);
  };
})(ASTEROIDS);
