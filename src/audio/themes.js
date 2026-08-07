// The soundtracks. Ten of them, and the cabinet rolls one when the page opens.
//
// A theme is four pieces of music, which is what a cabinet actually needs:
//
//   menu    the vamp under the splash screen, and under pause
//   play    the track that runs while you fly
//   death   the sting when you lose a ship
//   over    the one that plays you out
//
// Everything that makes one theme different from another lives in this file —
// tempo, key, the waveform each instrument uses, how hard the guitar is
// driven, how much drum kit there is. src/audio/song.js sequences `menu` and
// `play`; src/audio/riff.js plays `death` and `over`; src/audio/voices.js asks
// `tone` what it should sound like. None of the three knows which theme it is
// holding, which is the point: an eleventh one is an entry in the list below
// and nothing else in the codebase moves.
//
// The roll is per page load, not per game. Reload for another one. To hear a
// particular one on purpose — index.html#theme=hornet — because ten themes you
// cannot audit are nine themes nobody ever hears.

(function (A) {
  "use strict";

  // ---- the parts ----------------------------------------------------------
  // A pattern is which sixteenths of a bar a part fires on. Everything below
  // is built out of these, so two themes that share a groove really do share
  // it rather than agreeing by accident.

  const P = {
    none:    [],
    whole:   [0],
    half:    [0, 8],
    four:    [0, 4, 8, 12],
    eighths: [0, 2, 4, 6, 8, 10, 12, 14],
    offbeat: [2, 6, 10, 14],
    push:    [0, 3, 6, 8, 11, 14],
    swing:   [0, 3, 4, 7, 8, 11, 12, 15],
    lurch:   [0, 3, 8, 11],
    stab:    [0, 6, 8],
    ring:    [0, 6, 8, 14],
    gallop:  [0, 2, 3, 4, 6, 7, 8, 10, 11, 12, 14, 15],
    all:     [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
  };
  const K = {   // kick drum
    none:   [],
    whole:  [0],
    half:   [0, 8],
    four:   [0, 4, 8, 12],
    rock:   [0, 3, 6, 8, 11, 14],
    double: [0, 2, 3, 6, 8, 10, 11, 14],
    train:  [0, 2, 4, 6, 8, 10, 12, 14],
    broken: [0, 6, 10, 12],
  };
  const S = {   // snare
    none:  [],
    half:  [8],
    back:  [4, 12],
    every: [2, 6, 10, 14],
    drag:  [4, 12, 14],
  };

  // The riff and anything else that wants the house groove by name.
  A.DOUBLE_KICKS = K.double;
  A.SNARES = S.back;

  // ---- the band before anybody retunes it ---------------------------------
  // Every theme's `tone` is filled in from this, so a theme only writes down
  // what it wants to be different about.

  const TONE = {
    guitar: "sawtooth",   // rhythm waveform
    lead: "sawtooth",     // melody waveform
    bass: "square",
    harm: 7,              // semitones the lead is doubled at — 7 is a fifth
    drive: 120,           // distortion into the guitar cab
    gLo: 2600,            // guitar cab lowpass
    lLo: 3400,            // lead lowpass
    lAmp: 0.3,            // lead level
    drums: 0.7,
    bassGain: 0.42,
    level: 1,             // trim, because a wall of sixteenths is louder than a drone
    vib: 5.5, vibAmt: 7,  // lead vibrato: hertz, cents
    hats: P.all, open: [4, 12],
    hotHats: false,       // once it is hot, lay a second hat on every offbeat
    fills: true,          // the snare roll across the last beat of a section
    riffDrive: 120, riffLo: 3000,
    kick: [155, 45, 0.07, 0.14],   // from Hz, to Hz, pitch fall, decay
    snare: [1800, 0.7, 0.16],      // band centre, Q, decay
    hat: [7000],                   // highpass
    crash: [5200, 1.1],            // highpass, decay
  };

  // ---- the ten ------------------------------------------------------------
  // Roots are MIDI: 40 is E2, 45 is A2, 48 is C3. A lead line is one list per
  // bar of [sixteenth, note, length in sixteenths].

  A.THEMES = [
    {
      id: "hypercolor", name: "HYPERCOLOR", tint: "var(--cyan)", bpm: 168,
      blurb: `Downpicked gallop in E minor under a harmonised hero melody. The
        house band, and the one that was here first.`,
      tone: { hotHats: true },
      menu: [
        { roots: [40, 40, 48, 43], guitar: P.whole, sustain: true, ring: 6,
          kicks: K.half, bass: P.eighths, hats: P.eighths,
          lead: [[], [[8, 71, 6]], [], [[8, 67, 7]]] },
      ],
      play: [
        { // the main theme: i VI III VII
          roots: [40, 48, 43, 50], guitar: P.gallop, kicks: K.rock, hot: K.double,
          snares: S.back,
          lead: [
            [[0, 71, 4], [4, 76, 2], [6, 74, 2], [8, 71, 3], [12, 67, 4]],
            [[0, 72, 4], [4, 67, 2], [6, 76, 2], [8, 74, 6], [14, 72, 2]],
            [[0, 71, 4], [4, 74, 4], [8, 79, 4], [12, 76, 4]],
            [[0, 69, 4], [4, 78, 2], [6, 76, 2], [8, 74, 7]],
          ] },
        { // the chase: double kick, melody up an octave
          roots: [40, 50, 48, 50], guitar: P.gallop, kicks: K.double, snares: S.back,
          drone: true,
          lead: [
            [[0, 83, 2], [3, 81, 2], [6, 79, 2], [8, 76, 4], [12, 79, 4]],
            [[0, 81, 2], [3, 78, 2], [6, 81, 2], [8, 83, 6]],
            [[0, 79, 2], [3, 76, 2], [6, 72, 2], [8, 76, 4], [12, 79, 2]],
            [[0, 78, 4], [4, 81, 4], [8, 83, 8]],
          ] },
        { // breakdown: half time, no lead, just menace
          roots: [40, 40, 48, 46], guitar: P.half, kicks: K.half, snares: S.half,
          sustain: true },
        { // the lift: ringing chords under a soaring line
          roots: [48, 50, 40, 40], guitar: P.ring, kicks: K.double, snares: S.back,
          sustain: true, drone: true,
          lead: [
            [[0, 76, 8], [8, 79, 8]], [[0, 78, 8], [8, 81, 8]],
            [[0, 83, 12], [12, 81, 4]], [[0, 79, 8], [8, 76, 7]],
          ] },
      ],
      death: {
        bars: 1, dur: 1.6, kicks: K.double, snares: S.back,
        chugs: [[40, 0, 2], [40, 2, 1], [40, 3, 1], [40, 4, 2], [40, 6, 1],
                [40, 7, 1], [43, 8, 2], [45, 10, 2], [46, 12, 2], [47, 14, 2]],
        wail: [[76, 0, 4], [79, 4, 4], [78, 8, 8]] },
      over: {
        bars: 2, dur: 5.2, kicks: K.double, snares: S.back,
        chugs: [[40, 0, 2], [40, 2, 1], [40, 3, 1], [40, 4, 2], [40, 6, 1],
                [40, 7, 1], [43, 8, 2], [45, 10, 2], [46, 12, 2], [47, 14, 2],
                [48, 16, 3], [48, 20, 1], [47, 21, 1], [45, 22, 2], [43, 24, 4],
                [41, 28, 2], [40, 30, 2]],
        wail: [[76, 0, 4], [79, 4, 4], [78, 8, 4], [76, 12, 4], [83, 16, 8],
               [81, 24, 8]],
        dive: [40, 28, 1.6], squeal: [1480, 2700, 1.0] },
    },

    {
      id: "neon-chapel", name: "NEON CHAPEL", tint: "var(--violet)", bpm: 128,
      blurb: `Cathedral organ in D minor, four to the floor, every chord left
        ringing until the next one arrives.`,
      tone: { guitar: "triangle", lead: "triangle", bass: "triangle", drive: 22,
              gLo: 1700, lLo: 2800, lAmp: 0.36, drums: 0.55, vib: 4.4, vibAmt: 10,
              hats: P.four, open: [12], riffDrive: 40, crash: [3800, 1.9],
              level: 1.05 },
      menu: [
        { roots: [38, 41, 46, 43], guitar: P.whole, sustain: true, ring: 9,
          kicks: K.whole, bass: P.four, hats: P.none,
          lead: [[[0, 74, 12]], [], [[0, 77, 12]], [[8, 69, 8]]] },
      ],
      play: [
        { roots: [38, 46, 41, 48], guitar: P.ring, sustain: true, ring: 5,
          kicks: K.four, hot: K.train, snares: S.back,
          lead: [
            [[0, 74, 6], [8, 70, 4], [12, 69, 4]],
            [[0, 70, 8], [8, 74, 8]],
            [[0, 77, 6], [8, 74, 4], [12, 72, 4]],
            [[0, 69, 12], [12, 67, 4]],
          ] },
        { roots: [46, 48, 38, 41], guitar: P.eighths, kicks: K.four, hot: K.train,
          snares: S.back, bass: P.eighths,
          lead: [
            [[0, 81, 4], [4, 77, 4], [8, 74, 8]],
            [[0, 79, 4], [4, 76, 4], [8, 72, 8]],
            [[0, 74, 4], [4, 77, 4], [8, 81, 8]],
            [[0, 82, 8], [8, 81, 8]],
          ] },
        { roots: [38, 38, 36, 41], guitar: P.half, sustain: true, ring: 7,
          kicks: K.half, snares: S.half, hats: P.none, bass: P.four },
      ],
      death: {
        bars: 1, dur: 2.0, kicks: K.four, snares: S.back,
        chugs: [[38, 0, 4], [36, 4, 4], [34, 8, 4], [33, 12, 4]],
        wail: [[74, 0, 6], [70, 6, 4], [69, 10, 6]] },
      over: {
        bars: 2, dur: 5.6, kicks: K.half, snares: S.half,
        chugs: [[38, 0, 6], [36, 6, 6], [34, 12, 4], [33, 16, 8], [31, 24, 8]],
        wail: [[74, 0, 8], [72, 8, 8], [70, 16, 8], [65, 24, 8]],
        dive: [38, 24, 2.4], squeal: [980, 1240, 1.6] },
    },

    {
      id: "black-ice", name: "BLACK ICE", tint: "var(--dim)", bpm: 92,
      blurb: `Half-time doom in C minor. Two chords a bar, both of them too
        loud, and a very long wait between them.`,
      tone: { drive: 220, gLo: 1500, lLo: 2400, drums: 0.9, bassGain: 0.52,
              vib: 3.8, vibAmt: 14, hats: P.four, open: [8],
              kick: [190, 34, 0.11, 0.26], snare: [1300, 0.5, 0.28],
              crash: [4200, 2.2], riffDrive: 240, riffLo: 2200, level: 0.9 },
      menu: [
        { roots: [36, 36, 39, 34], guitar: P.whole, sustain: true, ring: 13,
          kicks: K.whole, bass: P.whole, hats: P.none, snares: S.none,
          lead: [[[0, 60, 14]], [], [[0, 63, 14]], []] },
      ],
      play: [
        { roots: [36, 36, 44, 39], guitar: P.half, sustain: true, ring: 7,
          kicks: K.half, hot: K.rock, snares: S.half, bass: P.four,
          lead: [
            [[0, 67, 7], [8, 63, 7]], [[0, 63, 14]],
            [[0, 68, 7], [8, 67, 7]], [[0, 63, 12]],
          ] },
        { roots: [36, 41, 44, 43], guitar: P.stab, sustain: true, ring: 5,
          kicks: K.broken, hot: K.rock, snares: S.half, bass: P.four,
          lead: [
            [[0, 70, 6], [8, 67, 6]], [[0, 65, 12]],
            [[0, 68, 6], [8, 70, 6]], [[0, 72, 14]],
          ] },
        { roots: [36, 36, 36, 34], guitar: P.whole, sustain: true, ring: 14,
          kicks: K.whole, snares: S.none, hats: P.none, bass: P.half },
      ],
      death: {
        bars: 1, dur: 2.4, kicks: K.half, snares: S.half,
        chugs: [[36, 0, 6], [35, 8, 8]],
        wail: [[63, 0, 8], [60, 8, 8]] },
      over: {
        bars: 2, dur: 6.4, kicks: K.whole, snares: S.none,
        chugs: [[36, 0, 8], [34, 8, 8], [33, 16, 8], [31, 24, 8]],
        wail: [[63, 0, 12], [60, 12, 12], [56, 24, 8]],
        dive: [36, 22, 3.2], squeal: [740, 620, 2.6] },
    },

    {
      id: "vector-rush", name: "VECTOR RUSH", tint: "var(--magenta)", bpm: 176,
      blurb: `Square-wave synthwave in A minor, four on the floor, an arpeggio
        that never quite catches up with the kick.`,
      tone: { guitar: "square", lead: "square", bass: "sawtooth", drive: 55,
              gLo: 3400, lLo: 4200, lAmp: 0.26, drums: 0.78, vib: 6.2, vibAmt: 5,
              hats: P.eighths, open: [6, 14], snare: [2200, 0.9, 0.13],
              riffDrive: 70, level: 0.95, hotHats: true },
      menu: [
        { roots: [45, 48, 50, 53], guitar: P.offbeat, kicks: K.four, snares: S.none,
          bass: P.eighths, hats: P.four,
          lead: [[[0, 76, 4], [8, 72, 4]], [], [[0, 79, 4], [8, 76, 4]], []] },
      ],
      play: [
        { roots: [45, 53, 48, 55], guitar: P.eighths, kicks: K.four, hot: K.train,
          snares: S.back, bass: P.eighths,
          lead: [
            [[0, 69, 2], [2, 72, 2], [4, 76, 2], [6, 72, 2], [8, 81, 4], [12, 79, 4]],
            [[0, 77, 2], [2, 72, 2], [4, 69, 2], [6, 72, 2], [8, 77, 6]],
            [[0, 76, 2], [2, 72, 2], [4, 67, 2], [6, 72, 2], [8, 79, 4], [12, 76, 4]],
            [[0, 74, 4], [4, 79, 4], [8, 83, 8]],
          ] },
        { roots: [45, 50, 53, 55], guitar: P.all, kicks: K.four, hot: K.train,
          snares: S.back, bass: P.eighths, drone: true,
          lead: [
            [[0, 88, 2], [3, 86, 2], [6, 84, 2], [8, 81, 4], [12, 84, 4]],
            [[0, 86, 2], [3, 83, 2], [6, 86, 2], [8, 88, 6]],
            [[0, 84, 2], [3, 81, 2], [6, 77, 2], [8, 81, 4], [12, 84, 2]],
            [[0, 83, 4], [4, 86, 4], [8, 88, 8]],
          ] },
        { roots: [45, 45, 53, 53], guitar: P.offbeat, kicks: K.half, snares: S.half,
          sustain: true, bass: P.four },
        { roots: [48, 50, 45, 45], guitar: P.ring, sustain: true, ring: 4,
          kicks: K.four, hot: K.train, snares: S.back,
          lead: [
            [[0, 76, 8], [8, 79, 8]], [[0, 81, 8], [8, 84, 8]],
            [[0, 88, 12], [12, 86, 4]], [[0, 84, 8], [8, 81, 7]],
          ] },
      ],
      death: {
        bars: 1, dur: 1.5, kicks: K.train, snares: S.back,
        chugs: [[45, 0, 2], [45, 2, 2], [44, 4, 2], [43, 6, 2], [41, 8, 4],
                [40, 12, 4]],
        wail: [[81, 0, 4], [79, 4, 4], [76, 8, 8]] },
      over: {
        bars: 2, dur: 4.8, kicks: K.four, snares: S.back,
        chugs: [[45, 0, 4], [43, 4, 4], [41, 8, 4], [40, 12, 4], [38, 16, 8],
                [36, 24, 8]],
        wail: [[84, 0, 4], [81, 4, 4], [79, 8, 8], [76, 16, 8], [72, 24, 8]],
        dive: [45, 30, 1.9], squeal: [1620, 2200, 1.2] },
    },

    {
      id: "sunset-drive", name: "SUNSET DRIVE", tint: "var(--amber)", bpm: 108,
      blurb: `Nobody told this one it was an emergency. F sharp minor, warm
        triangles, a lead that leans on every note it lands on.`,
      tone: { guitar: "triangle", lead: "sawtooth", bass: "triangle", drive: 18,
              gLo: 1900, lLo: 2600, lAmp: 0.32, drums: 0.52, vib: 4.0, vibAmt: 13,
              hats: P.eighths, open: [6, 14], harm: 4,
              snare: [1500, 0.6, 0.2], crash: [4600, 1.6], riffDrive: 45 },
      menu: [
        { roots: [42, 45, 47, 42], guitar: P.whole, sustain: true, ring: 11,
          kicks: K.whole, bass: P.four, snares: S.none, hats: P.four,
          lead: [[[0, 78, 10]], [[8, 73, 8]], [[0, 76, 10]], []] },
      ],
      play: [
        { roots: [42, 50, 45, 47], guitar: P.ring, sustain: true, ring: 5,
          kicks: K.rock, hot: K.double, snares: S.back,
          lead: [
            [[0, 78, 6], [8, 76, 3], [12, 73, 4]],
            [[0, 74, 8], [8, 78, 8]],
            [[0, 81, 6], [8, 78, 4], [12, 76, 4]],
            [[0, 73, 12], [12, 71, 4]],
          ] },
        { roots: [42, 47, 49, 50], guitar: P.eighths, kicks: K.four, hot: K.train,
          snares: S.back, bass: P.eighths,
          lead: [
            [[0, 85, 4], [4, 83, 4], [8, 81, 8]],
            [[0, 83, 4], [4, 78, 4], [8, 76, 8]],
            [[0, 81, 4], [4, 85, 4], [8, 88, 8]],
            [[0, 86, 8], [8, 85, 8]],
          ] },
        { roots: [45, 45, 42, 42], guitar: P.whole, sustain: true, ring: 12,
          kicks: K.half, snares: S.half, hats: P.four, bass: P.four },
      ],
      death: {
        bars: 1, dur: 1.9, kicks: K.rock, snares: S.back,
        chugs: [[42, 0, 4], [40, 4, 4], [38, 8, 4], [37, 12, 4]],
        wail: [[76, 0, 5], [73, 5, 5], [71, 10, 6]] },
      over: {
        bars: 2, dur: 5.4, kicks: K.four, snares: S.back,
        chugs: [[42, 0, 6], [40, 6, 4], [38, 10, 6], [35, 16, 8], [33, 24, 8]],
        wail: [[81, 0, 6], [78, 6, 6], [76, 12, 4], [73, 16, 8], [66, 24, 8]],
        dive: [42, 26, 2.2], squeal: [1180, 900, 1.8] },
    },

    {
      id: "hornet", name: "HORNET", tint: "var(--lime)", bpm: 192,
      blurb: `E phrygian, sixteenths all the way down, and a flat second that
        arrives about a bar before you are ready for it.`,
      tone: { drive: 265, gLo: 3100, lLo: 3800, drums: 0.88, vib: 6.8, vibAmt: 9,
              hats: P.all, open: [4, 12], snare: [2000, 0.8, 0.12],
              kick: [165, 48, 0.05, 0.11], riffDrive: 260, level: 0.9,
              hotHats: true },
      menu: [
        { roots: [40, 41, 43, 41], guitar: P.half, sustain: true, ring: 7,
          kicks: K.half, snares: S.none, bass: P.eighths, hats: P.four,
          lead: [[], [[8, 77, 6]], [], [[8, 76, 7]]] },
      ],
      play: [
        { roots: [40, 41, 40, 43], guitar: P.all, kicks: K.double, snares: S.back,
          lead: [
            [[0, 76, 2], [2, 77, 2], [4, 76, 2], [6, 72, 2], [8, 71, 4], [12, 76, 4]],
            [[0, 77, 2], [2, 76, 2], [4, 72, 2], [6, 71, 2], [8, 69, 6], [14, 71, 2]],
            [[0, 76, 2], [2, 79, 2], [4, 77, 2], [6, 76, 2], [8, 72, 8]],
            [[0, 83, 4], [4, 82, 2], [6, 79, 2], [8, 77, 7]],
          ] },
        { roots: [40, 40, 48, 47], guitar: P.gallop, kicks: K.train, snares: S.every,
          drone: true,
          lead: [
            [[0, 88, 2], [3, 87, 2], [6, 83, 2], [8, 79, 4], [12, 83, 4]],
            [[0, 87, 2], [3, 84, 2], [6, 88, 2], [8, 89, 6]],
            [[0, 84, 2], [3, 83, 2], [6, 79, 2], [8, 76, 4], [12, 79, 2]],
            [[0, 77, 4], [4, 83, 4], [8, 88, 8]],
          ] },
        { roots: [41, 41, 40, 40], guitar: P.half, sustain: true, ring: 7,
          kicks: K.half, snares: S.half, hats: P.four },
      ],
      death: {
        bars: 1, dur: 1.4, kicks: K.train, snares: S.every,
        chugs: [[40, 0, 1], [40, 1, 1], [41, 2, 2], [40, 4, 1], [40, 5, 1],
                [43, 6, 2], [40, 8, 2], [41, 10, 2], [43, 12, 2], [45, 14, 2]],
        wail: [[77, 0, 3], [76, 3, 3], [72, 6, 4], [71, 10, 6]] },
      over: {
        bars: 2, dur: 4.6, kicks: K.double, snares: S.back,
        chugs: [[40, 0, 2], [41, 2, 2], [43, 4, 2], [41, 6, 2], [40, 8, 4],
                [48, 12, 4], [47, 16, 4], [45, 20, 4], [43, 24, 4], [41, 28, 4]],
        wail: [[88, 0, 4], [87, 4, 4], [83, 8, 4], [79, 12, 4], [77, 16, 8],
               [71, 24, 8]],
        dive: [40, 25, 1.4], squeal: [1900, 3100, 0.9] },
    },

    {
      id: "glass-orbit", name: "GLASS ORBIT", tint: "var(--cyan)", bpm: 138,
      blurb: `A dorian, sine waves, almost no distortion at all. The kick is
        the only thing in it that admits to being a drum.`,
      tone: { guitar: "sine", lead: "triangle", bass: "triangle", drive: 8,
              gLo: 1300, lLo: 4400, lAmp: 0.34, drums: 0.46, bassGain: 0.36,
              vib: 2.8, vibAmt: 16, harm: 12, hats: P.offbeat, open: [10],
              snare: [2600, 1.4, 0.1], crash: [6400, 1.4], riffDrive: 20,
              level: 1.1 },
      menu: [
        { roots: [45, 48, 50, 47], guitar: P.offbeat, sustain: true, ring: 4,
          kicks: K.whole, snares: S.none, bass: P.four, hats: P.none,
          lead: [[[0, 76, 10]], [], [[0, 79, 10]], [[8, 74, 8]]] },
      ],
      play: [
        { roots: [45, 50, 55, 50], guitar: P.offbeat, kicks: K.four, hot: K.train,
          snares: S.none, bass: P.eighths,
          lead: [
            [[0, 76, 4], [4, 78, 2], [6, 81, 6]],
            [[0, 79, 4], [4, 76, 4], [8, 74, 8]],
            [[0, 83, 4], [4, 81, 2], [6, 78, 6], [12, 76, 4]],
            [[0, 74, 8], [8, 78, 8]],
          ] },
        { roots: [45, 52, 48, 50], guitar: P.eighths, kicks: K.four, hot: K.train,
          snares: S.back, bass: P.eighths,
          lead: [
            [[0, 88, 4], [4, 85, 4], [8, 83, 8]],
            [[0, 85, 4], [4, 81, 4], [8, 78, 8]],
            [[0, 83, 4], [4, 86, 4], [8, 90, 8]],
            [[0, 88, 8], [8, 85, 7]],
          ] },
        { roots: [45, 45, 50, 50], guitar: P.whole, sustain: true, ring: 14,
          kicks: K.whole, snares: S.none, hats: P.none, bass: P.half },
      ],
      death: {
        bars: 1, dur: 1.8, kicks: K.four, snares: S.none,
        chugs: [[45, 0, 6], [43, 6, 4], [41, 10, 6]],
        wail: [[81, 0, 6], [78, 6, 4], [74, 10, 6]] },
      over: {
        bars: 2, dur: 5.8, kicks: K.whole, snares: S.none,
        chugs: [[45, 0, 8], [43, 8, 8], [40, 16, 8], [38, 24, 8]],
        wail: [[81, 0, 8], [78, 8, 8], [74, 16, 8], [69, 24, 8]],
        dive: [45, 24, 3.0], squeal: [2400, 3600, 2.2] },
    },

    {
      id: "carnival-red", name: "CARNIVAL RED", tint: "var(--magenta)", bpm: 152,
      blurb: `D harmonic minor, swung sixteenths, and the augmented second
        nobody in the band will apologise for.`,
      tone: { lead: "square", bass: "square", drive: 95, gLo: 2400, lLo: 3600,
              drums: 0.72, vib: 6.6, vibAmt: 12, harm: 3,
              hats: P.swing, open: [7, 15], snare: [1900, 1.1, 0.14],
              riffDrive: 110 },
      menu: [
        { roots: [38, 38, 46, 45], guitar: P.swing, kicks: K.half, snares: S.none,
          bass: P.four, hats: P.four,
          lead: [[], [[8, 73, 4], [12, 70, 4]], [], [[8, 69, 8]]] },
      ],
      play: [
        { roots: [38, 45, 46, 45], guitar: P.swing, kicks: K.rock, hot: K.double,
          snares: S.back,
          lead: [
            [[0, 74, 3], [3, 73, 1], [4, 70, 4], [8, 69, 4], [12, 65, 4]],
            [[0, 67, 3], [3, 69, 1], [4, 70, 4], [8, 73, 6], [14, 74, 2]],
            [[0, 77, 3], [3, 74, 1], [4, 73, 4], [8, 70, 4], [12, 69, 4]],
            [[0, 65, 4], [4, 69, 4], [8, 73, 4], [12, 74, 4]],
          ] },
        { roots: [38, 43, 46, 45], guitar: P.gallop, kicks: K.double, snares: S.drag,
          lead: [
            [[0, 86, 2], [3, 85, 2], [6, 82, 2], [8, 81, 4], [12, 79, 4]],
            [[0, 79, 2], [3, 81, 2], [6, 82, 2], [8, 85, 6]],
            [[0, 86, 2], [3, 82, 2], [6, 81, 2], [8, 77, 4], [12, 79, 2]],
            [[0, 77, 4], [4, 82, 4], [8, 86, 8]],
          ] },
        { roots: [46, 45, 38, 38], guitar: P.ring, sustain: true, ring: 4,
          kicks: K.broken, snares: S.half, hats: P.four,
          lead: [
            [[0, 70, 8], [8, 69, 8]], [[0, 73, 8], [8, 74, 8]],
            [[0, 77, 12], [12, 73, 4]], [[0, 74, 14]],
          ] },
      ],
      death: {
        bars: 1, dur: 1.7, kicks: K.double, snares: S.drag,
        chugs: [[38, 0, 2], [38, 3, 1], [41, 4, 2], [43, 6, 2], [44, 8, 4],
                [43, 12, 2], [41, 14, 2]],
        wail: [[74, 0, 3], [73, 3, 3], [70, 6, 4], [69, 10, 6]] },
      over: {
        bars: 2, dur: 5.0, kicks: K.rock, snares: S.back,
        chugs: [[38, 0, 4], [44, 4, 4], [43, 8, 4], [41, 12, 4], [40, 16, 8],
                [38, 24, 8]],
        wail: [[85, 0, 4], [82, 4, 4], [81, 8, 4], [77, 12, 4], [74, 16, 8],
               [70, 24, 8]],
        dive: [38, 27, 2.0], squeal: [1520, 2100, 1.4] },
    },

    {
      id: "deep-field", name: "DEEP FIELD", tint: "var(--violet)", bpm: 76,
      blurb: `Open fifths, one chord change a bar, and a very long way to the
        next drum. Mostly it is the room you are hearing.`,
      tone: { guitar: "sine", lead: "sine", bass: "sine", drive: 6, gLo: 900,
              lLo: 2200, lAmp: 0.4, drums: 0.34, bassGain: 0.5, vib: 2.0,
              vibAmt: 20, harm: 12, hats: P.none, open: [], fills: false,
              kick: [130, 30, 0.18, 0.5], snare: [900, 0.4, 0.4],
              crash: [3200, 3.0], riffDrive: 12, riffLo: 1600, level: 1.15 },
      menu: [
        { roots: [33, 36, 31, 33], guitar: P.whole, sustain: true, ring: 15,
          kicks: K.none, snares: S.none, bass: P.whole,
          lead: [[[0, 69, 15]], [], [[0, 72, 15]], []] },
      ],
      play: [
        { roots: [33, 33, 36, 31], guitar: P.whole, sustain: true, ring: 15,
          kicks: K.whole, hot: K.half, snares: S.none, bass: P.whole,
          lead: [
            [[0, 69, 14]], [[0, 72, 7], [8, 69, 7]],
            [[0, 76, 14]], [[0, 72, 12]],
          ] },
        { roots: [33, 38, 36, 31], guitar: P.half, sustain: true, ring: 7,
          kicks: K.half, hot: K.rock, snares: S.half, bass: P.four,
          lead: [
            [[0, 76, 7], [8, 74, 7]], [[0, 72, 14]],
            [[0, 79, 7], [8, 76, 7]], [[0, 74, 12]],
          ] },
        { roots: [33, 33, 33, 33], guitar: P.whole, sustain: true, ring: 15,
          kicks: K.none, snares: S.none, bass: P.whole },
      ],
      death: {
        bars: 1, dur: 3.0, kicks: K.whole, snares: S.none,
        chugs: [[33, 0, 8], [31, 8, 8]],
        wail: [[69, 0, 8], [64, 8, 8]] },
      over: {
        bars: 2, dur: 7.0, kicks: K.none, snares: S.none,
        chugs: [[33, 0, 10], [31, 10, 10], [28, 20, 12]],
        wail: [[69, 0, 10], [67, 10, 10], [60, 20, 12]],
        dive: [33, 20, 4.0], squeal: [620, 400, 3.2] },
    },

    {
      id: "pixel-fury", name: "PIXEL FURY", tint: "var(--lime)", bpm: 200,
      blurb: `Three square waves and a noise channel, run at two hundred beats
        a minute because there is nothing else to spend on.`,
      tone: { guitar: "square", lead: "square", bass: "square", drive: 40,
              gLo: 5200, lLo: 6200, lAmp: 0.24, drums: 0.62, bassGain: 0.38,
              vib: 8.5, vibAmt: 6, harm: 12, hats: P.all, open: [6, 14],
              kick: [200, 60, 0.04, 0.09], snare: [3000, 1.6, 0.08],
              hat: [9000], crash: [7000, 0.7], riffDrive: 50, riffLo: 5000,
              level: 0.85, hotHats: true },
      menu: [
        { roots: [48, 51, 53, 55], guitar: P.offbeat, kicks: K.four, snares: S.none,
          bass: P.eighths, hats: P.four,
          lead: [[[0, 72, 2], [4, 75, 2], [8, 79, 6]], [],
                 [[0, 75, 2], [4, 79, 2], [8, 82, 6]], []] },
      ],
      play: [
        { roots: [48, 56, 51, 58], guitar: P.all, kicks: K.rock, hot: K.double,
          snares: S.back,
          lead: [
            [[0, 84, 1], [2, 87, 1], [4, 91, 1], [6, 87, 1], [8, 84, 4], [12, 79, 4]],
            [[0, 80, 1], [2, 84, 1], [4, 87, 1], [6, 84, 1], [8, 80, 6]],
            [[0, 87, 1], [2, 82, 1], [4, 79, 1], [6, 82, 1], [8, 87, 4], [12, 91, 4]],
            [[0, 82, 2], [4, 86, 2], [8, 89, 8]],
          ] },
        { roots: [48, 53, 55, 58], guitar: P.all, kicks: K.train, snares: S.every,
          drone: true,
          lead: [
            [[0, 91, 2], [3, 89, 2], [6, 87, 2], [8, 84, 4], [12, 87, 4]],
            [[0, 89, 2], [3, 86, 2], [6, 89, 2], [8, 91, 6]],
            [[0, 87, 2], [3, 84, 2], [6, 80, 2], [8, 84, 4], [12, 87, 2]],
            [[0, 86, 4], [4, 89, 4], [8, 91, 8]],
          ] },
        { roots: [48, 48, 51, 51], guitar: P.eighths, kicks: K.half, snares: S.half,
          hats: P.four, sustain: true, ring: 2 },
        { roots: [56, 58, 48, 48], guitar: P.ring, sustain: true, ring: 4,
          kicks: K.double, snares: S.back,
          lead: [
            [[0, 84, 8], [8, 87, 8]], [[0, 89, 8], [8, 91, 8]],
            [[0, 96, 12], [12, 91, 4]], [[0, 87, 8], [8, 84, 7]],
          ] },
      ],
      death: {
        bars: 1, dur: 1.3, kicks: K.train, snares: S.every,
        chugs: [[48, 0, 1], [48, 2, 1], [47, 4, 1], [46, 6, 1], [44, 8, 2],
                [43, 10, 2], [41, 12, 2], [39, 14, 2]],
        wail: [[84, 0, 2], [82, 2, 2], [79, 4, 4], [75, 8, 6]] },
      over: {
        bars: 2, dur: 4.2, kicks: K.rock, snares: S.back,
        chugs: [[48, 0, 2], [46, 2, 2], [44, 4, 2], [43, 6, 2], [41, 8, 4],
                [39, 12, 4], [36, 16, 8], [34, 24, 8]],
        wail: [[91, 0, 2], [87, 2, 2], [84, 4, 4], [79, 8, 8], [75, 16, 8],
               [72, 24, 8]],
        dive: [48, 32, 1.5], squeal: [2600, 4200, 0.8] },
    },
  ];

  // ---- normalising --------------------------------------------------------
  // Done once, at load, so the sequencer never has to fall back to a default
  // in the middle of a sixteenth. Every section comes out of here with every
  // field present, which is why song.js reads so plainly.

  function section(sec, tone) {
    return {
      roots: sec.roots,
      guitar: sec.guitar || P.none,
      bass: sec.bass || P.eighths,
      kicks: sec.kicks || K.none,
      hot: sec.hot || sec.kicks || K.none,   // what it turns into once it is mean
      snares: sec.snares || S.none,
      hats: sec.hats || tone.hats,
      open: sec.open || tone.open,
      lead: sec.lead || null,
      sustain: !!sec.sustain,
      ring: sec.ring || 3.2,   // sixteenths an accented chord is left to hang
      drone: !!sec.drone,      // once it is hot, the bass stops leaving gaps
    };
  }

  function prepare(theme) {
    if (theme.ready) return theme;
    const tone = Object.assign({}, TONE, theme.tone);
    theme.tone = tone;
    theme.menu = theme.menu.map((s) => section(s, tone));
    theme.play = theme.play.map((s) => section(s, tone));
    theme.ready = true;
    return theme;
  }

  // ---- the roll -----------------------------------------------------------

  /**
   * Put a theme on the cabinet by id, by index, or at random. Called once
   * below, before anything has read a tempo off it — src/audio/song.js pins
   * its clock at load, so calling this later swaps the arrangements and the
   * waveforms but not the beats per minute. Reload to change the whole band.
   */
  A.pickTheme = function pickTheme(which) {
    let t = null;
    if (typeof which === "string") t = A.THEMES.find((x) => x.id === which);
    else if (typeof which === "number") t = A.THEMES[which % A.THEMES.length];
    if (!t) t = A.THEMES[Math.floor(Math.random() * A.THEMES.length)];
    A.theme = prepare(t);
    return A.theme;
  };

  // One roll per page load, before anything reads a tempo off it. The hash is
  // for anybody who wants to hear a particular one on purpose — no player will
  // ever type it, and that is the whole idea.
  const asked = /(?:^|[#&])theme=([\w-]+)/.exec(location.hash || "");
  A.pickTheme(asked ? asked[1] : null);

  // The cabs and the vibrato are built by src/audio/buses.js and belong to
  // everyone; what they are set to is this theme's business.
  A.onAudioReady(function tuneRig() {
    const t = A.theme.tone, r = A.rig;
    if (!r) return;
    r.gShape.curve = A.makeDistortion(t.drive);
    r.gLo.frequency.value = t.gLo;
    r.lLo.frequency.value = t.lLo;
    r.lAmp.gain.value = t.lAmp;
    r.vibAmt.gain.value = t.vibAmt;
    A.vibrato.frequency.value = t.vib;
    A.drumBus.gain.value = t.drums;
    A.bassBus.gain.value = t.bassGain;
  });
})(ASTEROIDS);
