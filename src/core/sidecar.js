// Generated data, asked for rather than required.
//
// There is no fetch in this project and there is not going to be (GR2), so
// anything a tool writes for the page to read arrives the way the faces
// already do: as a script, injected once, which either turns up and hangs
// something off `A` or does not turn up at all. A clone that has never run the
// tool is the ordinary case rather than the broken one, so a miss is silent
// and whoever asked draws exactly what they drew before there was any data.
//
//   A.sidecar("docs/chronicle.js", () => A.renderBook())
//
// Asked for twice, loaded once: the second caller queues behind the first
// request and both run when it settles, hit or miss.

(function (A) {
  "use strict";

  const asked = new Map();   // src -> { settled, waiting[] }

  A.sidecar = function sidecar(src, then) {
    let s = asked.get(src);
    if (!s) {
      s = { settled: false, waiting: [] };
      asked.set(src, s);
      const el = document.createElement("script");
      el.src = src;
      el.async = false;
      const settle = () => {
        s.settled = true;
        const queue = s.waiting;
        s.waiting = [];
        queue.forEach((fn) => fn());
      };
      el.onload = settle;
      el.onerror = settle;     // nobody generated it. that is a state, not a fault
      document.head.append(el);
    }
    if (!then) return;
    if (s.settled) then();
    else s.waiting.push(then);
  };
})(ASTEROIDS);
