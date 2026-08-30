// The band. Each voice is one function that schedules a note at a given time
// on a given bus — the song and the death riff both play the same instruments.
//
// What the instruments are made of is not decided here. Every voice asks the
// soundtrack on the cabinet (src/audio/themes.js) for its waveform and its
// tuning, which is how ten themes get ten drum kits out of one drum kit.

(function (A) {
  "use strict";

  A.midi = (m) => 440 * Math.pow(2, (m - 69) / 12);

  const T = () => A.theme.tone;

  /** palm-muted power chord: root + fifth, clipped short so it chugs */
  A.chug = function chug(root, t, dur, dest, sustain) {
    const f = A.midi(root);
    const voices = sustain ? [1, 1.4983, 2] : [1, 1.4983];
    voices.forEach((mul, i) => {
      const o = A.audio.createOscillator();
      const gn = A.audio.createGain();
      o.type = T().guitar;
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
    [[0, 0.34], [T().harm, 0.16]].forEach(([iv, vol]) => {
      const o = A.audio.createOscillator();
      const gn = A.audio.createGain();
      o.type = T().lead;
      o.frequency.setValueAtTime(A.midi(note + iv), t);
      // The desk lets go of the note when the note ends. A permanent node
      // holding an output into a finished oscillator is a finished oscillator
      // that never leaves the graph, and src/audio/reaper.js cannot see this
      // one from its side: it unwires what a voice reached out to, not what
      // reached into the voice.
      if (A.vibrato) {
        const vib = A.vibrato._amt;
        vib.connect(o.detune);
        o.addEventListener("ended", function loosen() {
          o.removeEventListener("ended", loosen);
          try { vib.disconnect(o.detune); } catch (e) {}
        });
      }
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
    o.type = T().bass;
    o.frequency.setValueAtTime(A.midi(note), t);
    gn.gain.setValueAtTime(0.0001, t);
    gn.gain.exponentialRampToValueAtTime(0.5, t + 0.01);
    gn.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    o.connect(gn).connect(A.bassBus);
    o.start(t);
    o.stop(t + dur + 0.02);
  };

  A.kick = function kick(t, dest) {
    const [from, to, fall, decay] = T().kick;
    const o = A.audio.createOscillator();
    const gn = A.audio.createGain();
    o.frequency.setValueAtTime(from, t);
    o.frequency.exponentialRampToValueAtTime(to, t + fall);
    gn.gain.setValueAtTime(0.9, t);
    gn.gain.exponentialRampToValueAtTime(0.001, t + decay);
    o.connect(gn).connect(dest || A.drumBus);
    o.start(t);
    o.stop(t + decay + 0.02);
  };

  A.snare = function snare(t, dest) {
    const [band, q, decay] = T().snare;
    const src = A.noiseSource();
    const bp = A.audio.createBiquadFilter();
    bp.type = "bandpass";
    bp.frequency.value = band;
    bp.Q.value = q;
    const gn = A.audio.createGain();
    gn.gain.setValueAtTime(0.6, t);
    gn.gain.exponentialRampToValueAtTime(0.001, t + decay);
    src.connect(bp).connect(gn).connect(dest || A.drumBus);
    src.start(t);
    src.stop(t + decay + 0.02);
    // a little body under the crack, pitched off the same band
    const o = A.audio.createOscillator();
    const og = A.audio.createGain();
    o.frequency.setValueAtTime(band * 0.105, t);
    o.frequency.exponentialRampToValueAtTime(band * 0.067, t + decay * 0.56);
    og.gain.setValueAtTime(0.25, t);
    og.gain.exponentialRampToValueAtTime(0.001, t + decay * 0.62);
    o.connect(og).connect(dest || A.drumBus);
    o.start(t);
    o.stop(t + decay * 0.75 + 0.02);
  };

  A.hat = function hat(t, open) {
    const src = A.noiseSource();
    const hp = A.audio.createBiquadFilter();
    hp.type = "highpass";
    hp.frequency.value = T().hat[0];
    const gn = A.audio.createGain();
    const dur = open ? 0.18 : 0.045;
    gn.gain.setValueAtTime(open ? 0.16 : 0.1, t);
    gn.gain.exponentialRampToValueAtTime(0.001, t + dur);
    src.connect(hp).connect(gn).connect(A.drumBus);
    src.start(t);
    src.stop(t + dur + 0.01);
  };

  A.crash = function crash(t, dest) {
    const [band, decay] = T().crash;
    const src = A.noiseSource();
    const hp = A.audio.createBiquadFilter();
    hp.type = "highpass";
    hp.frequency.value = band;
    const gn = A.audio.createGain();
    gn.gain.setValueAtTime(0.42, t);
    gn.gain.exponentialRampToValueAtTime(0.001, t + decay);
    src.connect(hp).connect(gn).connect(dest || A.drumBus);
    src.start(t);
    src.stop(t + decay + 0.05);
  };
})(ASTEROIDS);
