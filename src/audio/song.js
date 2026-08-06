// The track: a four-section song in E minor rather than one loop on repeat —
// main theme, a faster drive, a half-time breakdown, then the triumphant lift.
// It is sequenced sixteenth by sixteenth, a fraction of a second ahead of the
// playhead, so it stays locked to the audio clock and not to the frame rate.
//
// Want a different soundtrack? Everything you need is in this file: the
// patterns, the sections, and the one function that decides what plays on a
// given sixteenth.

(function (A) {
  "use strict";

  const BPM = 168;
  const STEP = A.STEP = 60 / BPM / 4;      // one sixteenth note
  const BAR = A.BAR = 16;                  // sixteenths per bar
  const LOOP = BAR * 4;                    // four-bar loop

  let musicTimer = null, musicStep = 0, nextStepTime = 0;
  let duckUntil = 0;

  /** Get the band out of the way for `seconds` — used by the loud one-shots. */
  A.duck = function duck(seconds) {
    if (!A.audio) return;
    duckUntil = Math.max(duckUntil, A.audio.currentTime + seconds);
  };

  // classic downpicked gallop: eighth + two sixteenths, four times a bar
  const GALLOP = [0, 2, 3, 4, 6, 7, 8, 10, 11, 12, 14, 15];
  const RING = [0, 6, 8, 14];
  const HALF = [0, 8];
  const KICKS = [0, 3, 6, 8, 11, 14];
  const DOUBLE_KICKS = A.DOUBLE_KICKS = [0, 2, 3, 6, 8, 10, 11, 14];
  const HALF_KICKS = [0, 8];
  const SNARES = A.SNARES = [4, 12];
  const HALF_SNARES = [8];

  // [step, midi note, length in sixteenths], one list per bar
  const SECTIONS = [
    { // A — the main theme: i VI III VII
      roots: [40, 48, 43, 50], guitar: GALLOP, kicks: KICKS, snares: SNARES,
      lead: [
        [[0, 71, 4], [4, 76, 2], [6, 74, 2], [8, 71, 3], [12, 67, 4]],
        [[0, 72, 4], [4, 67, 2], [6, 76, 2], [8, 74, 6], [14, 72, 2]],
        [[0, 71, 4], [4, 74, 4], [8, 79, 4], [12, 76, 4]],
        [[0, 69, 4], [4, 78, 2], [6, 76, 2], [8, 74, 7]],
      ],
    },
    { // B — the chase: double kick, melody up an octave
      roots: [40, 50, 48, 50], guitar: GALLOP, kicks: DOUBLE_KICKS, snares: SNARES,
      lead: [
        [[0, 83, 2], [3, 81, 2], [6, 79, 2], [8, 76, 4], [12, 79, 4]],
        [[0, 81, 2], [3, 78, 2], [6, 81, 2], [8, 83, 6]],
        [[0, 79, 2], [3, 76, 2], [6, 72, 2], [8, 76, 4], [12, 79, 2]],
        [[0, 78, 4], [4, 81, 4], [8, 83, 8]],
      ],
    },
    { // C — breakdown: half time, no lead, just menace
      roots: [40, 40, 48, 46], guitar: HALF, kicks: HALF_KICKS, snares: HALF_SNARES,
      lead: null, sustain: true,
    },
    { // D — the lift: ringing chords under a soaring line
      roots: [48, 50, 40, 40], guitar: RING, kicks: DOUBLE_KICKS, snares: SNARES,
      sustain: true,
      lead: [
        [[0, 76, 8], [8, 79, 8]],
        [[0, 78, 8], [8, 81, 8]],
        [[0, 83, 12], [12, 81, 4]],
        [[0, 79, 8], [8, 76, 7]],
      ],
    },
  ];
  const SONG = SECTIONS.length * LOOP;

  function scheduleStep(step, t) {
    const sec = SECTIONS[Math.floor(step / LOOP) % SECTIONS.length];
    const within = step % LOOP;
    const bar = Math.floor(within / BAR);
    const s = within % BAR;
    const root = sec.roots[bar];
    const playing = A.isRunning();
    const hot = playing && A.game.level >= 3;  // meaner as you survive

    // bass drives the whole time, menu included
    if (s % 2 === 0) A.bassNote(root - 12, t, STEP * 1.8);
    else if (hot && sec.kicks === DOUBLE_KICKS) A.bassNote(root - 12, t, STEP * 0.9);

    // hats keep time
    A.hat(t, s % 8 === 4);
    if (hot && s % 2 === 1) A.hat(t, false);

    if (!playing) {
      // menu vamp: a heartbeat and one ringing chord under the bass
      if (s === 0 || s === 8) A.kick(t);
      if (s === 0 && bar % 2 === 0) A.chug(40, t, STEP * 6, null, true);
      return;
    }

    // rhythm guitar
    if (sec.guitar.includes(s)) {
      const accent = s === 0 || s === 8 || sec.sustain;
      A.chug(root, t, accent ? STEP * 3.2 : STEP * 1.1, null, accent);
    }
    // drums
    const kicks = hot && sec.kicks === KICKS ? DOUBLE_KICKS : sec.kicks;
    if (kicks.includes(s)) A.kick(t);
    if (sec.snares.includes(s)) A.snare(t);
    // fill across the last beat of every section, then crash into the next
    if (bar === 3 && s >= 12) A.snare(t);
    if (within === 0) A.crash(t);

    // hero melody over the top
    if (sec.lead) {
      for (const [ms, note, len] of sec.lead[bar]) {
        if (ms === s) A.leadNote(note, t, len * STEP * 0.9);
      }
    }
  }

  function musicScheduler() {
    if (!A.audio) return;
    // volume follows game state; riffs duck the track out of the way
    let target = A.muted ? 0
      : A.game.phase === "playing" ? (A.game.paused ? 0.1 : 0.44)
      : 0.24;
    if (A.audio.currentTime < duckUntil) target *= 0.22;
    A.musicBus.gain.setTargetAtTime(target, A.audio.currentTime, 0.09);

    // a backgrounded tab throttles the timer; resync rather than dumping
    // every missed sixteenth into the present all at once
    if (nextStepTime < A.audio.currentTime - 0.1) {
      const missed = Math.ceil((A.audio.currentTime - nextStepTime) / STEP);
      musicStep += missed;
      nextStepTime += missed * STEP;
    }
    while (nextStepTime < A.audio.currentTime + 0.14) {
      if (!A.muted) scheduleStep(musicStep % SONG, nextStepTime);
      nextStepTime += STEP;
      musicStep++;
    }
  }

  A.onAudioReady(function startMusic() {
    if (!A.audio || musicTimer) return;
    musicStep = 0;
    nextStepTime = A.audio.currentTime + 0.12;
    musicScheduler();
    musicTimer = setInterval(musicScheduler, 25);
  });
})(ASTEROIDS);
