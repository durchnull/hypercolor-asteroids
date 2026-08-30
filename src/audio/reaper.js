// Taking the dead nodes back out of the graph.
//
// Every sound in this cabinet is built the same way, and there are a hundred
// and thirty of them: make a handful of nodes, wire them source → shaping →
// bus, start them, stop them a moment later. Not one of those hundred and
// thirty ever took its nodes out again, and nothing else did it for them, so
// the graph only ever got bigger. Twenty seconds of the vamp with nobody
// flying is nine hundred nodes. One shot is twenty, and the ricochet on it is
// a delay feeding a gain feeding the delay — a loop that goes on being mixed
// long after it has gone quiet, because a loop has no source in it to stop.
//
// Chrome and Firefox cover for that, which is why nobody has noticed. Watch
// the same graph in them and the nodes are collected a second or two after the
// source finishes; run this file's own numbers past them and three thousand
// nodes go in and sixty come out still standing. WebKit does what the
// specification actually promises instead — a node that is still connected is
// still alive, because collecting garbage is not allowed to change what you
// hear — and it holds on to far more, for far longer. Hence the report, and
// hence that it is always the same browser: play for a few minutes in Safari
// and the band starts to come apart. By then the audio thread is mixing
// thousands of voices that stopped making a sound minutes ago.
//
// So the tidying happens once, here, rather than in a hundred and thirty
// places and in every sound anybody writes after this one.
//
// What counts as one sound, for the purpose of knowing what to take out:
// everything built in a single turn of the thread. That is not a rule being
// imposed on the rest of the audio, it is a description of what the rest of
// the audio already does — a voice is a function that runs start to finish,
// and the sixteenths the sequencer lines up in one go belong together as much
// as the six nodes of a blaster shot do. When the last source in a batch has
// ended, the whole batch is unwired.
//
// Three things worth knowing before you write a sound that leans on this:
//
// - A connection *into* one of your nodes from a permanent one — the shared
//   vibrato reaching into a lead oscillator's detune, say — cannot be found
//   from this side. Whoever made that connection takes it out again;
//   src/audio/voices.js is the one place that has to.
// - A chain with no source in it at all is never reaped, because nothing can
//   say when it is finished. Nothing in the game builds one.
// - Hand a node you built this turn to a voice built in a later one and it
//   will be taken out from under that voice. Every `dest` argument in the
//   audio code today is either a permanent bus or something made in the same
//   breath as the notes going through it, which is why this has never come up.
//
// This loads directly after src/audio/buses.js and the order is the whole
// design: the desk is built by then and is never a guest, and nothing has
// played a note yet.

(function (A) {
  "use strict";

  // How long after the last source stops before the chain comes out. Nothing
  // downstream of a stopped source makes a sound except a delay fed by its own
  // output, and the longest of those in the game is the big shot's ricochet:
  // 64% of itself every tenth of a second, which is sixty decibels down inside
  // a second. A second and a half, then, and no tail is ever cut short.
  const TAIL = 1500;

  // What has been taken out, for anybody standing in the console wondering
  // whether the graph is still growing.
  A.audioReaped = 0;

  let building = null;

  function reap(batch) {
    for (const node of batch.nodes) {
      try { node.disconnect(); } catch (e) {}
    }
    A.audioReaped += batch.nodes.length;
    batch.nodes.length = 0;
  }

  function finished(batch) {
    if (batch.open || batch.live > 0 || !batch.sources) return;
    setTimeout(() => reap(batch), TAIL);
  }

  function watch(batch, node) {
    batch.sources++;
    batch.live++;
    node.addEventListener("ended", function ended() {
      node.removeEventListener("ended", ended);
      batch.live--;
      finished(batch);
    });
  }

  function keep(node) {
    if (!building) {
      const batch = building = { nodes: [], sources: 0, live: 0, open: true };
      // The turn of the thread these nodes were made in is the only thing they
      // have in common, and it is over once the microtask queue runs.
      Promise.resolve().then(function close() {
        if (building === batch) building = null;
        batch.open = false;
        finished(batch);
      });
    }
    building.nodes.push(node);
    // Only a source knows when it is done; everything else in the chain is
    // taken out when the last one that feeds it is.
    if (typeof node.start === "function") watch(building, node);
  }

  A.onAudioReady(function armReaper() {
    const audio = A.audio;
    // Every node in the game comes out of one of these, so wrapping them is
    // what saves a hundred and thirty call sites from having to remember. A
    // factory that hands back something with no plug on it — a buffer, a
    // wave — is left alone.
    for (const name in audio) {
      if (name.slice(0, 6) !== "create") continue;
      const make = audio[name];
      if (typeof make !== "function") continue;
      audio[name] = function () {
        const node = make.apply(audio, arguments);
        if (node && typeof node.disconnect === "function") keep(node);
        return node;
      };
    }
  });
})(ASTEROIDS);
