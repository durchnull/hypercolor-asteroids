// One-shot sound effects. Every one of them is safe to call at any time: if
// the audio context does not exist yet, or the cabinet is muted, they return.
//
// A feature that wants a new noise adds a function here and calls it — this is
// the one file that knows how the game sounds.

(function (A) {
  "use strict";

  A.blip = function blip(freq, dur, type, vol) {
    if (!A.audio || A.muted) return;
    const t = A.audio.currentTime;
    const o = A.audio.createOscillator();
    const gn = A.audio.createGain();
    o.type = type;
    o.frequency.setValueAtTime(freq, t);
    o.frequency.exponentialRampToValueAtTime(freq * 0.4, t + dur);
    gn.gain.setValueAtTime(vol, t);
    gn.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    o.connect(gn).connect(A.master);
    o.start();
    o.stop(t + dur);
  };

  // The blaster: the classic sci-fi bolt is a fast downward pitch sweep through
  // a screaming resonant filter, fed into a short feedback delay so it rings off
  // into the distance like a shot down a metal cable.
  // Consecutive shots walk down a little four-note figure and alternate across
  // the stereo field, so held-down fire reads as a weapon rather than a loop.
  const SHOT_STEPS = [1, 0.94, 1.06, 0.88];
  let shotIndex = 0;

  A.blaster = function blaster(big) {
    if (!A.audio || A.muted) return;
    const audio = A.audio;
    const t = audio.currentTime;
    shotIndex = (shotIndex + 1) % SHOT_STEPS.length;
    const k = big ? 0.42 : SHOT_STEPS[shotIndex];
    const dur = big ? 0.45 : 0.22;

    const out = audio.createGain();
    out.gain.value = big ? 0.7 : 0.42;
    const pan = audio.createStereoPanner ? audio.createStereoPanner() : null;
    if (pan) {
      pan.pan.value = big ? 0 : (shotIndex % 2 ? 0.28 : -0.28);
      out.connect(pan).connect(A.master);
    } else {
      out.connect(A.master);
    }
    const tailIn = pan || A.master;

    // ricochet tail: a damped feedback delay, the bolt screaming off into space
    const dly = audio.createDelay(0.6);
    dly.delayTime.value = big ? 0.1 : 0.058;
    const fb = audio.createGain();
    fb.gain.value = big ? 0.64 : 0.55;
    const damp = audio.createBiquadFilter();
    damp.type = "lowpass";
    damp.frequency.value = 2600;
    const wet = audio.createGain();
    wet.gain.value = 0.6;
    out.connect(dly);
    dly.connect(damp).connect(fb).connect(dly);   // decaying feedback loop
    dly.connect(wet).connect(tailIn);

    // core bolt: an FM'd saw diving four octaves. The modulator is what gives it
    // the hard metallic edge instead of a plain video-game "pew".
    const carrier = audio.createOscillator();
    carrier.type = "sawtooth";
    carrier.frequency.setValueAtTime(2600 * k, t);
    carrier.frequency.exponentialRampToValueAtTime(160 * k, t + dur);
    const mod = audio.createOscillator();
    const modAmt = audio.createGain();
    mod.type = "square";
    mod.frequency.setValueAtTime(720 * k, t);
    mod.frequency.exponentialRampToValueAtTime(90 * k, t + dur);
    modAmt.gain.setValueAtTime(1500, t);
    modAmt.gain.exponentialRampToValueAtTime(30, t + dur);
    mod.connect(modAmt).connect(carrier.frequency);

    const bp = audio.createBiquadFilter();
    bp.type = "bandpass";
    bp.Q.value = 9;
    bp.frequency.setValueAtTime(3400 * k, t);
    bp.frequency.exponentialRampToValueAtTime(300 * k, t + dur);
    const env = audio.createGain();
    env.gain.setValueAtTime(0.0001, t);
    env.gain.exponentialRampToValueAtTime(0.95, t + 0.004);
    env.gain.exponentialRampToValueAtTime(0.0001, t + dur + 0.05);
    carrier.connect(bp).connect(env).connect(out);
    carrier.start(t);
    carrier.stop(t + dur + 0.07);
    mod.start(t);
    mod.stop(t + dur + 0.07);

    // detuned twin, slightly behind, for thickness
    const twin = audio.createOscillator();
    twin.type = "square";
    twin.frequency.setValueAtTime(1720 * k, t);
    twin.frequency.exponentialRampToValueAtTime(180 * k, t + dur * 0.8);
    const te = audio.createGain();
    te.gain.setValueAtTime(0.0001, t);
    te.gain.exponentialRampToValueAtTime(0.3, t + 0.006);
    te.gain.exponentialRampToValueAtTime(0.0001, t + dur * 0.9);
    twin.connect(te).connect(out);
    twin.start(t + 0.006);
    twin.stop(t + dur);

    // muzzle crack
    const n = A.noiseSource();
    const nhp = audio.createBiquadFilter();
    nhp.type = "highpass";
    nhp.frequency.setValueAtTime(2600, t);
    nhp.frequency.exponentialRampToValueAtTime(900, t + 0.07);
    const ng = audio.createGain();
    ng.gain.setValueAtTime(0.55, t);
    ng.gain.exponentialRampToValueAtTime(0.0001, t + 0.07);
    n.connect(nhp).connect(ng).connect(out);
    n.start(t);
    n.stop(t + 0.08);

    // sub thump so the shot has weight in the chest
    const sub = audio.createOscillator();
    const sg = audio.createGain();
    sub.type = "sine";
    sub.frequency.setValueAtTime(big ? 150 : 220, t);
    sub.frequency.exponentialRampToValueAtTime(big ? 38 : 60, t + 0.14);
    sg.gain.setValueAtTime(big ? 0.7 : 0.4, t);
    sg.gain.exponentialRampToValueAtTime(0.0001, t + (big ? 0.3 : 0.16));
    sub.connect(sg).connect(A.master);
    sub.start(t);
    sub.stop(t + (big ? 0.32 : 0.18));
  };

  // --- grappling hook: thwip out, metal bite, snapping release ---
  A.hookThrow = function hookThrow() {
    if (!A.audio || A.muted) return;
    const t = A.audio.currentTime;
    const n = A.noiseSource();
    const bp = A.audio.createBiquadFilter();
    bp.type = "bandpass";
    bp.Q.value = 6;
    bp.frequency.setValueAtTime(600, t);
    bp.frequency.exponentialRampToValueAtTime(3200, t + 0.16);
    const gn = A.audio.createGain();
    gn.gain.setValueAtTime(0.3, t);
    gn.gain.exponentialRampToValueAtTime(0.0001, t + 0.18);
    n.connect(bp).connect(gn).connect(A.master);
    n.start(t);
    n.stop(t + 0.2);
  };

  A.hookBite = function hookBite() {
    if (!A.audio || A.muted) return;
    const t = A.audio.currentTime;
    // metallic clank: two detuned squares clipped short
    [430, 611].forEach((f, i) => {
      const o = A.audio.createOscillator();
      const gn = A.audio.createGain();
      o.type = "square";
      o.frequency.setValueAtTime(f, t);
      o.frequency.exponentialRampToValueAtTime(f * 0.7, t + 0.12);
      gn.gain.setValueAtTime(0.22 - i * 0.08, t);
      gn.gain.exponentialRampToValueAtTime(0.0001, t + 0.16);
      o.connect(gn).connect(A.master);
      o.start(t);
      o.stop(t + 0.18);
    });
    const n = A.noiseSource();
    const hp = A.audio.createBiquadFilter();
    hp.type = "highpass";
    hp.frequency.value = 3000;
    const ng = A.audio.createGain();
    ng.gain.setValueAtTime(0.3, t);
    ng.gain.exponentialRampToValueAtTime(0.0001, t + 0.07);
    n.connect(hp).connect(ng).connect(A.master);
    n.start(t);
    n.stop(t + 0.08);
  };

  A.hookSnap = function hookSnap() {
    if (!A.audio || A.muted) return;
    const t = A.audio.currentTime;
    const o = A.audio.createOscillator();
    const gn = A.audio.createGain();
    o.type = "triangle";
    o.frequency.setValueAtTime(220, t);
    o.frequency.exponentialRampToValueAtTime(900, t + 0.18);
    gn.gain.setValueAtTime(0.0001, t);
    gn.gain.exponentialRampToValueAtTime(0.24, t + 0.02);
    gn.gain.exponentialRampToValueAtTime(0.0001, t + 0.24);
    o.connect(gn).connect(A.master);
    o.start(t);
    o.stop(t + 0.26);
  };

  A.boom = function boom(size) {
    if (!A.audio || A.muted) return;
    const t = A.audio.currentTime;
    const dur = 0.25 + size * 0.12;
    const src = A.noiseSource();
    const filter = A.audio.createBiquadFilter();
    filter.type = "lowpass";
    filter.frequency.setValueAtTime(500 + size * 400, t);
    filter.frequency.exponentialRampToValueAtTime(80, t + dur);
    const gn = A.audio.createGain();
    gn.gain.setValueAtTime(0.3, t);
    gn.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    src.connect(filter).connect(gn).connect(A.master);
    src.start(t);
    src.stop(t + dur);
  };

  // The atom bomb: a bright crack, a long filtered roar, and a sub you feel.
  A.nukeSound = function nukeSound() {
    if (!A.audio || A.muted) return;
    const audio = A.audio;
    const t = audio.currentTime;
    A.duck(2.4);

    const crackle = A.noiseSource();
    const chp = audio.createBiquadFilter();
    chp.type = "highpass";
    chp.frequency.setValueAtTime(4000, t);
    chp.frequency.exponentialRampToValueAtTime(400, t + 0.5);
    const cg = audio.createGain();
    cg.gain.setValueAtTime(0.7, t);
    cg.gain.exponentialRampToValueAtTime(0.0001, t + 0.7);
    crackle.connect(chp).connect(cg).connect(A.master);
    crackle.start(t);
    crackle.stop(t + 0.75);

    const roar = A.noiseSource();
    const rlp = audio.createBiquadFilter();
    rlp.type = "lowpass";
    rlp.frequency.setValueAtTime(1800, t);
    rlp.frequency.exponentialRampToValueAtTime(90, t + 2.2);
    const rg = audio.createGain();
    rg.gain.setValueAtTime(0.0001, t);
    rg.gain.exponentialRampToValueAtTime(0.85, t + 0.06);
    rg.gain.exponentialRampToValueAtTime(0.0001, t + 2.4);
    roar.connect(rlp).connect(rg).connect(A.master);
    roar.start(t);
    roar.stop(t + 2.5);

    const sub = audio.createOscillator();
    const sg = audio.createGain();
    sub.type = "sine";
    sub.frequency.setValueAtTime(110, t);
    sub.frequency.exponentialRampToValueAtTime(22, t + 1.2);
    sg.gain.setValueAtTime(0.0001, t);
    sg.gain.exponentialRampToValueAtTime(0.9, t + 0.02);
    sg.gain.exponentialRampToValueAtTime(0.0001, t + 1.6);
    sub.connect(sg).connect(A.master);
    sub.start(t);
    sub.stop(t + 1.65);
  };

  // --- the kraken's warble: one drone, held while any of them are on screen ---
  let squidSound = null;

  A.warbling = () => !!squidSound;

  A.startWarble = function startWarble() {
    if (!A.audio || squidSound) return;
    const o = A.audio.createOscillator();
    const lfo = A.audio.createOscillator();
    const lfoGain = A.audio.createGain();
    const gn = A.audio.createGain();
    o.type = "triangle";
    o.frequency.value = 90;
    lfo.frequency.value = 5;
    lfoGain.gain.value = 30;
    lfo.connect(lfoGain);
    lfoGain.connect(o.frequency);
    gn.gain.value = 0;
    o.connect(gn).connect(A.master);
    o.start();
    lfo.start();
    squidSound = { o, lfo, g: gn };
  };

  A.stopWarble = function stopWarble() {
    if (!squidSound) return;
    try { squidSound.o.stop(); squidSound.lfo.stop(); } catch (e) {}
    squidSound = null;
  };

  /** The pack sings as one; the kraken decides what it sounds like. */
  A.tuneWarble = function tuneWarble(vol, pitch, wobble) {
    if (!squidSound) return;
    squidSound.g.gain.value = A.muted ? 0 : vol;
    squidSound.o.frequency.value = pitch;
    squidSound.lfo.frequency.value = wobble;
  };
})(ASTEROIDS);
