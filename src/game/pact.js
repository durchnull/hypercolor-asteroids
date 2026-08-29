// The pact. Two pilots agreeing, in writing, to make each other's evening
// worse.
//
// Everything else in this cabinet that leans on a pilot either leans on the
// whole room at once — an event fires at everybody bar its author (GR11) — or
// is earned, by bending a rule (GR12) or by topping the board (game/bounty.js).
// Aiming an event at a name is the thing the rules do not allow, and the reason
// is not squeamishness: an event written at somebody is one they had no say in
// and cannot answer.
//
// A pact is the shape that survives that objection, because it needs two
// signatures. You declare it on your own events — `pact: "their name"` beside
// your `by:` — and it does precisely nothing until their arsenal says your
// name back. One-sided it is a standing offer: the pilot named is not touched
// by it, will never meet it in the field, and loses nothing by ignoring it
// forever.
//
// Which is why this needed no rule changed. The declaration rides on the one
// identity claim the referee already polices — GR11 refuses a `by:` that is
// not yours — so forging somebody into a pact is exactly as hard as forging
// their signature, which is to say refused, in front of everybody. And nothing
// here touches eligibility: your own events still never come for you, theirs
// still do, and the field still does not ambush the unarmed.
//
// What a live pact moves, for both pilots at once:
//
//   - their arsenal takes the lion's share of the author draw, so most of what
//     the field throws at you is theirs. Everybody else's events are still in
//     the pool. They are just no longer the ones you keep meeting.
//   - the wait between ambushes shortens by a share, floored by the events
//     director along with every other impatience it is multiplied against.
//
// GR8, out loud, because that rule is on our honour and this is exactly the
// kind of thing it is about:
//
//   - a handicap and never a power. It hands nobody anything.
//   - the same handicap on both sides, by construction. There is no version of
//     this that one pilot is winning.
//   - both seats fly it, as they do the tally and the crown.
//   - it is announced early and drawn for the rest of the run. The ambushes it
//     hurries along still announce themselves exactly as they always did.
//   - the way out is one line in your own event file, which nobody else may
//     touch. You signed it; you can unsign it.
//
// No arsenal, no pact: a pilot who has laid no events has nothing to declare it
// on, and would not be ambushed anyway. Writing the event is still the whole
// induction.

(function (A) {
  "use strict";

  const PULL = 3;      // shares in the author draw, against everybody else's one
  const GAP = 0.88;    // and the wait between ambushes, as a share of it
  const SAY = 5.4;     // seconds into a run before it says so

  let said = 0;

  // Events are defined once, at load, and the seat only changes on the splash
  // screen — so the answer is stable for a whole run and is worth not working
  // out again sixty times a second for the sake of one glyph.
  let cache = { who: null, foes: [] };

  function foes() {
    const me = A.activePilot();
    if (cache.who === me) return cache.foes;
    const calls = A.pactCalls ? A.pactCalls() : new Map();
    const mine = calls.get(me);
    const found = !mine ? [] : [...mine].filter((them) => {
      const theirs = calls.get(them);
      return !!theirs && theirs.has(me);
    }).sort();
    cache = { who: me, foes: found };
    return found;
  }

  /** The pilots the one in the seat is actually duelling. Usually nobody. */
  A.pactFoes = () => foes().slice();

  /** Is there a live pact on this seat at all? */
  A.pactOn = () => foes().length > 0;

  /**
   * The share of the author draw an arsenal takes in game/events.js. One is
   * everybody else, and everybody else is nearly everybody.
   */
  A.pactShare = function pactShare(by) {
    return foes().indexOf(by) >= 0 ? PULL : 1;
  };

  /** Gap multiplier for the events director, the way game/bounty.js hands one. */
  A.pactHeat = function pactHeat() {
    return A.pactOn() ? GAP : 1;
  };

  function reset(mode) {
    said = mode === "play" ? 0 : SAY;
  }

  // Said once, and late enough that it is not shouting over anything. The
  // crown says its piece at 2.6 and holds the banner for another 2.2, so this
  // waits until that is off the screen; the earliest an ambush can fire is a
  // settle plus a gap, which is a long way further out than either.
  //
  // On the game clock rather than the wall, so the attract loop — which is
  // nobody's flight and is nobody's pact — is told nothing.
  function resolve(tick) {
    if (said >= SAY) return;
    said += tick.dt;
    if (said < SAY || !A.pactOn()) return;
    said = SAY;
    const who = A.pactFoes().map((n) => String(n).split(/\s+/)[0].toUpperCase());
    A.showBanner("THE PACT HOLDS", who.join(" AND ") + " ASKED FOR THIS, AND SO DID YOU", 2.4);
    A.blip(300, 0.55, "square", 0.08);
  }

  // Two sides facing off across a gap. Eighteen pixels is not much room, and
  // the first draft of this was three strokes that bloomed into an asterisk —
  // so it is two closed shapes with the gap between them wide enough to
  // survive the glow, which is how the crown next door stays a crown.
  //
  // Right-hand side above that crown, because the things the field is holding
  // against a pilot belong in one column rather than in the same pixels, and
  // clear of the bottom edge, which is the sound button and the spent ambushes
  // walking into the corner (ui/mark.js).
  const CLASH = "M3 4.5l7.5 7.5-7.5 7.5z M21 4.5l-7.5 7.5 7.5 7.5z";

  let path = null;

  function draw(tick, g) {
    if (!tick.running || !A.pactOn()) return;
    if (!path) path = new Path2D(CLASH);

    const s = 18 / 24;
    g.save();
    g.globalAlpha = 0.32 + 0.12 * Math.sin(tick.time * 2.2);
    g.lineJoin = "round";
    g.lineCap = "round";
    A.glow(A.neon(A.hue + 300, 64));
    g.translate(A.W - 40, A.H - 98);
    g.scale(s, s);
    g.lineWidth = 1.8 / s;
    g.stroke(path);
    g.restore();
    g.globalAlpha = 1;
  }

  A.register({
    id: "pact",
    order: { draw: 92, guide: 92 },
    reset,
    resolve,
    draw,
    guide: {
      name: "THE PACT",
      meta: "mutual",
      tint: "var(--cyan)",
      icon: `<svg width="34" height="34" viewBox="0 0 34 34" fill="none"
        stroke="currentColor" stroke-width="1.6" stroke-linejoin="round">
        <path d="M4 6l11 11-11 11z"/><path d="M30 6L19 17l11 11z"/></svg>`,
      desc: `Two pilots who have both named the other in their own events spend
        the evening mostly meeting each other's work, and waiting less for it.
        It takes two signatures and it is the same weather on both sides
        &mdash; declared at somebody and never answered, it does nothing at
        all.`,
    },
  });
})(ASTEROIDS);
