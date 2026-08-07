// The sequencer. It reads whichever soundtrack the cabinet rolled tonight —
// see src/audio/themes.js — and plays two of that theme's four pieces: the
// vamp while you are on the splash screen or paused, and the track while you
// are flying. src/audio/riff.js plays the other two.
//
// Everything is sequenced sixteenth by sixteenth, a fraction of a second ahead
// of the playhead, so it stays locked to the audio clock rather than to the
// frame rate. Nothing about a particular song lives in this file any more:
// want a different soundtrack, write one into the list in themes.js.

(function (A) {
  "use strict";

  const theme = A.theme;
  const tone = theme.tone;
  const STEP = A.STEP = 60 / theme.bpm / 4;   // one sixteenth note
  const BAR = A.BAR = 16;                     // sixteenths per bar
  const LOOP = BAR * 4;                       // four-bar section

  let musicTimer = null, musicStep = 0, nextStepTime = 0;
  let duckUntil = 0;
  // which of the two arrangements is up, and the step it started on — so the
  // band comes in on a downbeat when you press ENTER instead of halfway
  // through somebody's bar
  let onStage = false, startStep = 0;

  /** Get the band out of the way for `seconds` — used by the loud one-shots. */
  A.duck = function duck(seconds) {
    if (!A.audio) return;
    duckUntil = Math.max(duckUntil, A.audio.currentTime + seconds);
  };

  function scheduleStep(t) {
    const playing = A.isRunning();
    if (playing !== onStage) {
      onStage = playing;
      startStep = musicStep;
    }
    const set = onStage ? theme.play : theme.menu;
    const pos = (musicStep - startStep) % (set.length * LOOP);
    const sec = set[Math.floor(pos / LOOP)];
    const within = pos % LOOP;
    const bar = Math.floor(within / BAR);
    const s = within % BAR;
    const root = sec.roots[bar];
    // meaner as you survive: the section says what its kick turns into
    const hot = onStage && A.game.level >= 3;
    const kicks = hot ? sec.hot : sec.kicks;

    // bass. A droning section stops leaving gaps at all once it is hot; every
    // other section keeps its pattern however bad things get.
    if (sec.bass.includes(s)) A.bassNote(root - 12, t, STEP * 1.8);
    else if (hot && sec.drone) A.bassNote(root - 12, t, STEP * 0.9);

    // hats keep time, and a theme that wants to can lay a second one over the
    // offbeats once it is hot
    if (sec.hats.includes(s)) A.hat(t, sec.open.includes(s));
    if (hot && tone.hotHats && s % 2 === 1) A.hat(t, false);

    // rhythm guitar
    if (sec.guitar.includes(s)) {
      const accent = s === 0 || s === 8 || sec.sustain;
      A.chug(root, t, (accent ? sec.ring : 1.1) * STEP, null, accent);
    }

    // drums
    if (kicks.includes(s)) A.kick(t);
    if (sec.snares.includes(s)) A.snare(t);
    // fill across the last beat of every section, then crash into the next
    if (tone.fills && bar === 3 && s >= 12) A.snare(t);
    if (within === 0) A.crash(t);

    // the melody over the top
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
    target *= tone.level;
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
      if (!A.muted) scheduleStep(nextStepTime);
      nextStepTime += STEP;
      musicStep++;
    }
  }

  A.onAudioReady(function startMusic() {
    if (!A.audio || musicTimer) return;
    musicStep = 0;
    startStep = 0;
    onStage = A.isRunning();
    nextStepTime = A.audio.currentTime + 0.12;
    musicScheduler();
    musicTimer = setInterval(musicScheduler, 25);
  });
})(ASTEROIDS);
