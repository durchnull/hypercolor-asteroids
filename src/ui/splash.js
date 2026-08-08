// The two things that float over the splash screen, and how far down the deck
// has got.
//
// The mark and the dock used to be rows: the title on top, the deck in the
// middle taking what was left, the instruction underneath. That kept PRESS
// ENTER findable, which was the whole point of it and still is — but it also
// meant the deck stopped dead at a hard edge under the title, with a strip of
// shade above doing no work at all. A panel cut in half by an edge reads as a
// panel that is broken. A panel running on under something you can see through
// reads as a panel with more of it, which is the truth.
//
// So both of them float now, and the deck owns the whole screen. Two lengths
// are all that costs, and neither can be written down in the stylesheet: the
// mark is a clamp against the viewport and the dock is however many lines the
// instruction wrapped onto. They are measured here and handed to the CSS,
// which holds the deck off them with padding — so nothing on the deck ever
// starts life underneath either, and everything is free to scroll under both.
//
// The mark also folds as you read. It is the biggest thing on the screen and
// the least useful once you are three panels down, so the scroll position
// drives its scale between a maximum and a minimum and nothing else touches
// it. And the rack answers the same movement: a panel sliding out under the
// mark or down behind the dock gives up a little size and a lot of light on
// the way, so the edges of the deck read as somewhere the reading goes rather
// than as two lines it is cut off at. The middle of the screen is where the
// panel you are actually reading is, and now the screen says so.
//
// Deliberately none of it is a threshold with a class on it: a mark that
// snapped to half size at some magic scrollTop, or a panel that blinked to
// half light as it crossed a line, would be a thing that happened *to* you.
// All of it is a continuous function of where the deck has got to, so it is
// the same movement your hand is making.
//
// Two measurements, and both of them are careful about the same trap. The mark
// is read with offsetHeight and offsetTop, which are layout and ignore
// transforms: a rectangle with the fold already applied to it would feed the
// scale back into the deck's padding, the padding back into the scroll, and
// the whole screen would breathe at you. The panels have to be read where they
// actually are, which means getBoundingClientRect, which does see transforms —
// so the scale this file put on is divided back out before anything is decided
// from the number. A scale about the middle leaves the middle where it was,
// which is the whole of the arithmetic and the reason the origin is left
// alone.

(function (A) {
  "use strict";

  const MAX = 1;             // at the top of the deck: the mark, full size
  const MIN = 0.5;           // folded away, and no further
  const RUN = 260;           // pixels of scroll that take it from one to other

  // How far under a panel has to be before it has given up everything it is
  // going to give up. Four fifths rather than all of it: the last sliver of a
  // panel disappearing is not worth watching, and a panel that only reaches
  // its dimmest at the exact moment it leaves never looks dim at all.
  const GONE = 0.8;
  const DIM = 0.76;          // light given up by then
  const SHRINK = 0.11;       // and size

  const splash = document.getElementById("start");
  const mark = splash && splash.querySelector(".logo");
  const deck = splash && splash.querySelector(".deck");
  const dock = splash && splash.querySelector(".dock");
  if (!splash || !mark || !deck || !dock) return;

  const quiet = matchMedia("(prefers-reduced-motion: reduce)");
  const worn = new Map();    // what each panel is currently scaled by
  let head = 0, foot = 0, pending = 0;

  // A hidden splash measures zero, and zero is not news — it is the game
  // running. The last true reading stands until there is another one.
  function fit() {
    const h = mark.offsetTop + mark.offsetHeight;
    const f = dock.offsetHeight;
    if (h > 0) splash.style.setProperty("--head", (head = h) + "px");
    if (f > 0) splash.style.setProperty("--foot", (foot = f) + "px");
    paint();
  }

  function fold() {
    const down = Math.max(0, deck.scrollTop);
    const s = MAX - Math.min(1, down / RUN) * (MAX - MIN);
    splash.style.setProperty("--mark", s.toFixed(3));
  }

  // How far a panel has gone under, measured against the clear strip of the
  // deck — the part with neither the mark nor the dock over it. What counts is
  // how much of the panel has crossed an edge, and how much of it there was to
  // cross: a short panel is gone after very little and a long one is not.
  //
  // The exception in the middle is the one that matters, and the field guide
  // is why. It is three panels tall on its own and on a laptop it is taller
  // than the strip, so it is always over one edge or the other by some amount
  // — measured like the rest it would spend its whole life half dimmed, and it
  // is the panel most likely to be the one somebody is actually reading. A
  // panel hanging out of both ends is not leaving. It is what you are looking
  // at, and it is left alone.
  function depth() {
    const box = deck.getBoundingClientRect();
    const top = box.top + head;
    const bottom = box.bottom - foot;
    const band = Math.max(1, bottom - top);

    for (const panel of deck.children) {
      const r = panel.getBoundingClientRect();
      // where the panel would be standing if this file had left it alone
      const mid = (r.top + r.bottom) / 2;
      const half = r.height / (worn.get(panel) || 1) / 2;
      const above = top - (mid - half);
      const below = (mid + half) - bottom;
      const over = above > 0 && below > 0 ? 0 : Math.max(0, above, below);
      const run = Math.min(half * 2, band) * GONE;
      const t = run > 0 ? Math.min(1, over / run) : 0;
      const s = 1 - t * SHRINK;
      worn.set(panel, s);
      panel.style.opacity = (1 - t * DIM).toFixed(3);
      panel.style.transform = t ? "scale(" + s.toFixed(4) + ")" : "";
    }
  }

  // One pass per frame however many scroll events arrive in it, and the whole
  // pass reads the layout before it writes any of it.
  function paint() {
    if (pending) return;
    pending = requestAnimationFrame(() => {
      pending = 0;
      if (quiet.matches) return;
      fold();
      depth();
    });
  }

  deck.addEventListener("scroll", paint, { passive: true });
  addEventListener("resize", fit);

  // The panels fill themselves in after this file has run, and the dock grows a
  // line when the screen is narrow enough to wrap it. Both are box changes, so
  // both arrive here without anybody having to remember to say so — and so is
  // the splash coming back up after a flight, which is the one that matters:
  // the deck is still scrolled to wherever it was left.
  if (window.ResizeObserver) {
    const ro = new ResizeObserver(fit);
    ro.observe(mark);
    ro.observe(dock);
  }

  fit();
})(ASTEROIDS);
