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
// Continuous is not the same as *written out* continuously, and on a phone the
// difference was the whole problem. Three things were wrong with the pass and
// all three showed up as the same stutter under a thumb.
//
// The first was a real bug and the paragraph below claimed the opposite of it:
// the loop read a panel's rectangle, wrote that panel's style, then read the
// next one's — and a read after a write is the browser flushing layout, six
// times a frame, on a screen with six frosted panels on it. Every rectangle is
// read before any style is written now, which is what this file always said it
// did.
//
// The second is that the panels had no step in them. A scroll of one pixel
// changed every panel's opacity in the fourth decimal place, and each of those
// is a composite of a `backdrop-filter` that has to sample what is behind it
// again. So a panel's number snaps to `STEP` now and a panel whose step has not
// moved is not touched at all. The motion is the same function it always was;
// it is sampled coarsely enough that a phone can afford to draw it.
//
// The mark is deliberately not in that deal. It was worth trying and it was
// wrong: its number is not spent through DIM and SHRINK on the way to the
// screen, it *is* the size of the name, so a step coarse enough to be worth
// having is five pixels of HYPERCOLOR jumping on a phone and three on a desk —
// on the one thing you are looking at while you scroll. And it was never what
// cost anything: one custom property, on one element, that the compositor
// handles. It writes every frame the deck moves in, exactly as it always did.
//
// The third is `SLACK`, and it is the one you can see. A panel began giving up
// light the instant its edge touched the mark, so on a short screen everything
// on the deck was always a little faded and the fade read as the panel being
// broken rather than as it leaving. The first eighth of the crossing is free
// now, and what happens after it is gentler than it was: this is the edge of
// the reading going quiet, not the panel being taken away.
//
// Two measurements, and both of them are careful about the same pitfall. The mark
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
  const SLACK = 0.12;        // and the first eighth of that costs nothing
  const DIM = 0.45;          // light given up by the end of it
  const SHRINK = 0.05;       // and size

  // What a panel's crossing is written in. Worth a hundredth of a pixel by the
  // time DIM and SHRINK have had it, so it can afford to be this coarse — and
  // coarse is the whole point, because most frames of a scroll then write no
  // panel at all. The mark is measured in nothing: see above.
  const STEP = 0.02;
  const snap = (v) => Math.round(v / STEP) * STEP;

  const splash = document.getElementById("start");
  const mark = splash && splash.querySelector(".logo");
  const deck = splash && splash.querySelector(".deck");
  const dock = splash && splash.querySelector(".dock");
  if (!splash || !mark || !deck || !dock) return;

  const quiet = matchMedia("(prefers-reduced-motion: reduce)");
  const worn = new Map();    // per panel: the scale in effect, and the step it is on
  let head = 0, foot = 0, pending = 0;
  let at = -1, dirty = true; // where the deck was last painted from

  // A hidden splash measures zero, and zero is not news — it is the game
  // running. The last true reading stands until there is another one.
  function fit() {
    const h = mark.offsetTop + mark.offsetHeight;
    const f = dock.offsetHeight;
    if (h > 0) splash.style.setProperty("--head", (head = h) + "px");
    if (f > 0) splash.style.setProperty("--foot", (foot = f) + "px");
    // The band moved, so every panel is worth asking again — and worth
    // *writing* again. `worn` is a memory of what was last put on each panel so
    // that an unchanged one can be skipped, which makes it the one thing here
    // that can disagree with the panel it describes. Every step is thrown away
    // rather than the whole entry: the scale has to survive, because the next
    // measurement is a rectangle with that scale still in it and divides the
    // number back out.
    for (const w of worn.values()) w.step = -1;
    dirty = true;
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

    // Every rectangle first, then every style. The other order asks the browser
    // to lay the deck out again between one panel and the next.
    const panels = [];
    for (const panel of deck.children) panels.push([panel, panel.getBoundingClientRect()]);

    for (const [panel, r] of panels) {
      const was = worn.get(panel);
      // where the panel would be standing if this file had left it alone
      const mid = (r.top + r.bottom) / 2;
      const half = r.height / ((was && was.scale) || 1) / 2;
      const above = top - (mid - half);
      const below = (mid + half) - bottom;
      const over = above > 0 && below > 0 ? 0 : Math.max(0, above, below);
      const run = Math.min(half * 2, band) * GONE;
      // How much of the strip this panel is still standing in. A panel taller
      // than the strip hangs out of one end for most of its journey, and `run`
      // is capped at the strip, so it would be marked entirely gone with more
      // than half of it still on the screen — the field guide reading as
      // broken while it is the only thing you can see. It cannot be further
      // gone than it is absent from the strip. For a panel small enough to fit
      // this never binds, which is why the arithmetic above is left alone.
      const seen = Math.max(0, Math.min(mid + half, bottom) - Math.max(mid - half, top));
      const gone = run > 0 ? Math.min(1, over / run, 1 - seen / band) : 0;
      // the slack at the near edge, then the rest of the crossing spread over
      // what is left of it, so the far end still arrives at exactly one
      const t = snap(gone <= SLACK ? 0 : (gone - SLACK) / (1 - SLACK));
      if (was && was.step === t) continue;
      const scale = 1 - t * SHRINK;
      worn.set(panel, { scale, step: t });
      panel.style.opacity = t ? (1 - t * DIM).toFixed(2) : "";
      panel.style.transform = t ? "scale(" + scale.toFixed(3) + ")" : "";
    }
  }

  // One pass per frame however many scroll events arrive in it, and no pass at
  // all for a frame the deck has not moved in — the last few events of a
  // momentum scroll on a phone all report the same position, and each of them
  // used to cost a full read of the deck.
  function paint() {
    if (pending) return;
    pending = requestAnimationFrame(() => {
      pending = 0;
      if (quiet.matches) return;
      const down = deck.scrollTop;
      if (down === at && !dirty) return;
      at = down;
      dirty = false;
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
