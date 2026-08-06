// The frame. Three phases, in order:
//
//   update   every feature, every frame — a feature that only runs during play
//            checks tick.running itself, so the attract screen can drift
//   resolve  collisions and rules, only while the game is running
//   draw     the render pipeline, which runs the features' draw hooks
//
// Nothing game-specific belongs in here. If you are tempted to add a case for
// your feature, add a hook to your feature instead.

(function (A) {
  "use strict";

  let last = 0;
  let clock = 0;

  // One object, reused, so adding a field here never breaks a feature.
  const tick = { dt: 0, raw: 0, time: 0, running: false };

  function frame(now) {
    const raw = Math.min((now - last) / 1000, 0.05);
    last = now;
    clock += raw;

    // Screen effects decay on real time so slow-mo doesn't stall them.
    A.decayEffects(raw);

    const running = A.isRunning();
    tick.raw = raw;
    tick.time = clock;
    tick.running = running;
    tick.dt = running ? raw * A.fx.timeScale : raw;

    // the global spectrum drift — slower when nobody is playing
    A.advanceHue(running ? tick.dt * 34 : raw * 24);

    A.run("update", tick);
    // a feature may have ended the game mid-update, so ask again
    if (A.isRunning()) A.run("resolve", tick);
    A.render(tick);

    requestAnimationFrame(frame);
  }

  A.startLoop = function startLoop() {
    last = performance.now();
    requestAnimationFrame(frame);
  };
})(ASTEROIDS);
