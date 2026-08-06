// The mixing desk: one bus per section of the band, each with its own amp and
// speaker cab. Voices connect to a bus; the buses meet at the music bus, which
// is what ducks out of the way when something loud happens.
//
// They do not exist until the audio does, so always read them off A.

(function (A) {
  "use strict";

  A.musicBus = A.guitarBus = A.leadBus = A.bassBus = A.drumBus = A.vibrato = null;

  A.onAudioReady(function buildBuses() {
    const audio = A.audio;

    A.musicBus = audio.createGain();
    A.musicBus.gain.value = 0;
    A.musicBus.connect(A.master);

    // rhythm guitar: hot distortion into a speaker-cab-ish band
    const gShape = audio.createWaveShaper();
    gShape.curve = A.distCurve;
    gShape.oversample = "2x";
    const gLo = audio.createBiquadFilter();
    gLo.type = "lowpass";
    gLo.frequency.value = 2600;
    const gHi = audio.createBiquadFilter();
    gHi.type = "highpass";
    gHi.frequency.value = 110;
    const gAmp = audio.createGain();
    gAmp.gain.value = 0.5;
    A.guitarBus = audio.createGain();
    A.guitarBus.gain.value = 1;
    A.guitarBus.connect(gShape);
    gShape.connect(gLo).connect(gHi).connect(gAmp).connect(A.musicBus);

    // lead: softer clip, brighter band, shared vibrato
    const lShape = audio.createWaveShaper();
    lShape.curve = A.makeDistortion(30);
    const lLo = audio.createBiquadFilter();
    lLo.type = "lowpass";
    lLo.frequency.value = 3400;
    const lAmp = audio.createGain();
    lAmp.gain.value = 0.3;
    A.leadBus = audio.createGain();
    A.leadBus.gain.value = 1;
    A.leadBus.connect(lShape);
    lShape.connect(lLo).connect(lAmp).connect(A.musicBus);

    A.vibrato = audio.createOscillator();
    const vibAmt = audio.createGain();
    A.vibrato.frequency.value = 5.5;
    vibAmt.gain.value = 7;          // cents
    A.vibrato.connect(vibAmt);
    A.vibrato.start();
    A.vibrato._amt = vibAmt;

    const bLo = audio.createBiquadFilter();
    bLo.type = "lowpass";
    bLo.frequency.value = 900;
    A.bassBus = audio.createGain();
    A.bassBus.gain.value = 0.42;
    A.bassBus.connect(bLo).connect(A.musicBus);

    A.drumBus = audio.createGain();
    A.drumBus.gain.value = 0.7;
    A.drumBus.connect(A.musicBus);
  });
})(ASTEROIDS);
