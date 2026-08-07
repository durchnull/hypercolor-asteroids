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

  // --- the panels -----------------------------------------------------------
  //
  // Everything above this line is the field. This is the furniture: the small
  // answer a panel gives when you point at it, and the firmer one it gives
  // when you choose it. A screen you sweep a mouse across should sound like an
  // instrument being brushed rather than like a game being played, so these
  // are the quietest things in this file by a factor of ten and the shortest
  // by a factor of three.
  //
  // They are also in tonight's key. There is a band on this cabinet already
  // (src/audio/themes.js) and a menu beeping in C over a song in E is the
  // sound of two rooms, so every note below is a step of the vamp's own scale.
  // src/ui/clicks.js decides which panel gets which step; this file only knows
  // what a step sounds like.

  // Minor pentatonic, an octave and a half of it. A list of any length walks
  // somewhere musical rather than running out of notes and going shrill.
  const STEPS = [0, 3, 5, 7, 10, 12, 15, 17, 19, 22];

  /** The note a step lands on: `lift` semitones above the tonight's tonic. */
  A.uiNote = function uiNote(step, lift) {
    const vamp = A.theme && A.theme.menu && A.theme.menu[0];
    const root = (vamp && vamp.roots && vamp.roots[0]) || 40;
    const i = (((step | 0) % STEPS.length) + STEPS.length) % STEPS.length;
    return root + lift + STEPS[i];
  };

  // Panel sounds are mono by default and this is where the width comes from:
  // consecutive steps lean alternately left and right, so a hand moving down a
  // list moves across the desk too.
  function panned(x) {
    if (!A.audio.createStereoPanner) return A.master;
    const p = A.audio.createStereoPanner();
    p.pan.value = x;
    p.connect(A.master);
    return p;
  }

  // Three hundredths of a second of filtered noise. Every panel sound starts
  // with one, because contact is what the ear actually reads — the note after
  // it is only there to say which panel was touched.
  function contact(t, level, from, to, dur, dest) {
    const n = A.noiseSource();
    const hp = A.audio.createBiquadFilter();
    hp.type = "highpass";
    hp.frequency.setValueAtTime(from, t);
    hp.frequency.exponentialRampToValueAtTime(to, t + dur);
    const g = A.audio.createGain();
    g.gain.setValueAtTime(level, t);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    n.connect(hp).connect(g).connect(dest);
    n.start(t);
    n.stop(t + dur + 0.01);
  }

  /** Under the cursor: a fingertip on glass, and barely that. */
  A.uiHover = function uiHover(step, lift) {
    if (!A.audio || A.muted) return;
    const audio = A.audio;
    const t = audio.currentTime;
    const dest = panned(step % 2 ? 0.22 : -0.22);
    const f = A.midi(A.uiNote(step, lift === undefined ? 24 : lift));

    contact(t, 0.05, 5200, 2600, 0.02, dest);

    const o = audio.createOscillator();
    const bp = audio.createBiquadFilter();
    const g = audio.createGain();
    o.type = "triangle";
    o.frequency.setValueAtTime(f, t);
    bp.type = "bandpass";
    bp.Q.value = 2.4;
    bp.frequency.setValueAtTime(f * 1.6, t);
    bp.frequency.exponentialRampToValueAtTime(f * 0.9, t + 0.09);
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(0.06, t + 0.006);
    g.gain.exponentialRampToValueAtTime(0.0001, t + 0.1);
    o.connect(bp).connect(g).connect(dest);
    o.start(t);
    o.stop(t + 0.11);
  };

  /** Chosen: the same note with a body under it and a fifth on top. */
  A.uiClick = function uiClick(step, lift) {
    if (!A.audio || A.muted) return;
    const audio = A.audio;
    const t = audio.currentTime;
    const f = A.midi(A.uiNote(step, lift === undefined ? 12 : lift));

    contact(t, 0.14, 4200, 900, 0.035, A.master);

    // the body: a square shutting behind itself, which is what a switch is
    const o = audio.createOscillator();
    const lp = audio.createBiquadFilter();
    const g = audio.createGain();
    o.type = "square";
    o.frequency.setValueAtTime(f * 1.02, t);
    o.frequency.exponentialRampToValueAtTime(f, t + 0.05);
    lp.type = "lowpass";
    lp.Q.value = 1.6;
    lp.frequency.setValueAtTime(f * 7, t);
    lp.frequency.exponentialRampToValueAtTime(f * 1.4, t + 0.14);
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(0.09, t + 0.005);
    g.gain.exponentialRampToValueAtTime(0.0001, t + 0.16);
    o.connect(lp).connect(g).connect(A.master);
    o.start(t);
    o.stop(t + 0.17);

    // the ring: a fifth above, arriving a frame late, all tail
    const r = audio.createOscillator();
    const rg = audio.createGain();
    r.type = "sine";
    r.frequency.setValueAtTime(f * 3, t);
    rg.gain.setValueAtTime(0.0001, t);
    rg.gain.exponentialRampToValueAtTime(0.035, t + 0.02);
    rg.gain.exponentialRampToValueAtTime(0.0001, t + 0.34);
    r.connect(rg).connect(A.master);
    r.start(t + 0.012);
    r.stop(t + 0.36);

    // and a thump, so pressing something has a floor under it
    const sub = audio.createOscillator();
    const sg = audio.createGain();
    sub.type = "sine";
    sub.frequency.setValueAtTime(190, t);
    sub.frequency.exponentialRampToValueAtTime(64, t + 0.1);
    sg.gain.setValueAtTime(0.12, t);
    sg.gain.exponentialRampToValueAtTime(0.0001, t + 0.13);
    sub.connect(sg).connect(A.master);
    sub.start(t);
    sub.stop(t + 0.14);
  };

  /** Taking a seat: three notes up the same scale, and the cabinet has you. */
  A.uiPick = function uiPick(step) {
    if (!A.audio || A.muted) return;
    const audio = A.audio;
    const t0 = audio.currentTime;
    contact(t0, 0.12, 4200, 1100, 0.03, A.master);
    [0, 2, 4].forEach((up, i) => {
      const t = t0 + i * 0.055;
      const f = A.midi(A.uiNote(step + up, 24));
      const o = audio.createOscillator();
      const g = audio.createGain();
      o.type = "triangle";
      o.frequency.setValueAtTime(f, t);
      g.gain.setValueAtTime(0.0001, t);
      g.gain.exponentialRampToValueAtTime(0.075 - i * 0.01, t + 0.008);
      g.gain.exponentialRampToValueAtTime(0.0001, t + (i === 2 ? 0.5 : 0.14));
      o.connect(g).connect(A.master);
      o.start(t);
      o.stop(t + (i === 2 ? 0.52 : 0.16));
    });
  };

  /** Pressing something that is not going to move: a flat, honest no. */
  A.uiDeny = function uiDeny() {
    if (!A.audio || A.muted) return;
    const audio = A.audio;
    const t = audio.currentTime;
    contact(t, 0.07, 1800, 400, 0.04, A.master);
    [96, 101].forEach((f, i) => {
      const o = audio.createOscillator();
      const lp = audio.createBiquadFilter();
      const g = audio.createGain();
      o.type = "square";
      o.frequency.setValueAtTime(f, t);
      lp.type = "lowpass";
      lp.frequency.value = 420;
      g.gain.setValueAtTime(0.0001, t);
      g.gain.exponentialRampToValueAtTime(0.085 - i * 0.035, t + 0.008);
      g.gain.exponentialRampToValueAtTime(0.0001, t + 0.13);
      o.connect(lp).connect(g).connect(A.master);
      o.start(t);
      o.stop(t + 0.15);
    });
  };

  /** Leaving the cabinet for the book: air moving, and one note going with it. */
  A.uiDoor = function uiDoor(step) {
    if (!A.audio || A.muted) return;
    const audio = A.audio;
    const t = audio.currentTime;

    const n = A.noiseSource();
    const bp = audio.createBiquadFilter();
    const g = audio.createGain();
    bp.type = "bandpass";
    bp.Q.value = 1.3;
    bp.frequency.setValueAtTime(340, t);
    bp.frequency.exponentialRampToValueAtTime(3600, t + 0.26);
    g.gain.setValueAtTime(0.0001, t);
    g.gain.linearRampToValueAtTime(0.16, t + 0.16);
    g.gain.exponentialRampToValueAtTime(0.0001, t + 0.34);
    n.connect(bp).connect(g).connect(A.master);
    n.start(t);
    n.stop(t + 0.36);

    [[0, 0], [4, 0.07]].forEach(([up, at]) => {
      const o = audio.createOscillator();
      const og = audio.createGain();
      o.type = "triangle";
      o.frequency.setValueAtTime(A.midi(A.uiNote(step + up, 24)), t + at);
      og.gain.setValueAtTime(0.0001, t + at);
      og.gain.exponentialRampToValueAtTime(0.08, t + at + 0.01);
      og.gain.exponentialRampToValueAtTime(0.0001, t + at + 0.42);
      o.connect(og).connect(A.master);
      o.start(t + at);
      o.stop(t + at + 0.44);
    });
  };
})(ASTEROIDS);
