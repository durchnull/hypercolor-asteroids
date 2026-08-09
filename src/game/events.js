// Events. The field has moods.
//
// An event is an unexpected challenge dropped into a live wave: three krakens
// surfacing at once from three directions, a ring of rock closing in, a pair
// of portals opening exactly where you were about to be. Any pilot may write
// them, in their own file under src/events/, and one rule makes it worth
// doing:
//
//     an event never fires for the pilot who wrote it.
//
// You cannot be ambushed by your own trap. Everybody else can. That is why the
// splash screen asks who is flying before it lets you in — see game/profile.js
// — and why laying a good one is the most direct way there is to ruin a
// friend's run.
//
// The mirror of that rule: a named pilot with no trap in the game is not
// ambushed at all. Nobody's first evening is spent as pure target — writing
// your first event is the induction, and the room arms itself the moment it
// lands. GUEST gets everything, which is the walk-up experience and is
// deliberate. See unarmed() below for the one exception the ledger makes.
//
// Writing one:
//
//   A.defineEvent({
//     id: "pincer",              // unique across the whole game
//     by: "Dave Okoro",          // your git name, exactly. or A.HOUSE.
//     name: "PINCER",            // the banner the victim gets
//     blurb: "From three sides", // the small line under it
//     for: "Mira Vogel",         // optional. a dedication, and nothing else.
//     minWave: 4,                // earliest wave it may fire on
//     weight: 2,                 // relative likelihood within your own arsenal
//     cooldown: 3,               // waves before it may repeat
//     icon: "M12 2.2v5.2 …",     // your glyph, in a 24x24 box, strokes only
//     holds: 5,                  // seconds the glyph stays up, at least
//     while() { ... },           // ... and true keeps it up past that
//     fire(tick) { ... },        // do your worst
//   });
//
// The banner says your name once and gets out of the way; the glyph goes to
// the foot of the screen and stays there for as long as the ambush is really
// happening. Draw one — an event without an icon gets a warning diamond and
// looks like every other event without an icon. See ui/mark.js.
//
// `for:` is a dedication and it is worth being exact about what it is not. It
// changes the banner and it changes nothing else: the trap fires at the same
// pilots it fired at before, at the same odds, in the same waves, and the one
// named gets no more of it than anybody in the room. Everybody reads the name,
// which is the point of dedicating anything — a trap addressed to somebody is
// a thing the rest of the room gets to watch happen.
//
// It is written down here because the line it does not cross is a red one. The
// moment a `for:` decides who an event is eligible for, it is targeting by
// name, and that is GR11 with no override in it. If somebody wants that, it is
// one commit changing the rule in the open, and it is not this.
//
// `by: A.HOUSE` means the event belongs to nobody and fires for everyone,
// author included. Use it when you want a thing in the game more than you want
// the credit for springing it.
//
// One thing revokes that protection, and only for the pilot who bought it: the
// tally. Bend a golden rule three times and game/tally.js stops letting the
// runner make an exception for you — see GR12, and see the ledger, which you
// do not get to edit.
//
// The referee will not let you touch another pilot's event file, and will not
// let you sign an event with a name that is not yours. See GR11.

(function (A) {
  "use strict";

  A.HOUSE = "THE HOUSE";

  const events = [];

  A.defineEvent = function defineEvent(event) {
    for (const e of [].concat(event)) {
      if (!e || !e.id) throw new Error("an event needs an id");
      if (!e.by) throw new Error("event " + e.id + " is not signed: it needs a `by`");
      if (typeof e.fire !== "function") throw new Error("event " + e.id + " needs a fire()");
      if (events.some((o) => o.id === e.id)) {
        throw new Error("duplicate event id: " + e.id);
      }
      events.push(e);
    }
  };

  /**
   * The field does not ambush the unarmed. A named pilot with no trap of
   * their own in the game gets none fired at them: the first evening is for
   * learning the field, and writing your first event is the induction that
   * arms the room (GR11). GUEST keeps the everything-armed walk-up game, on
   * purpose. The shelter is for the new, not the indebted - a pilot the
   * ledger still charges (GR12) is ambushed whether they are armed or not,
   * or deleting your own arsenal would be a way out of the tally.
   */
  function unarmed() {
    const me = A.activePilot();
    if (me === A.GUEST) return false;
    if (A.pilotHeatBends && A.pilotHeatBends(me) > 0) return false;
    return !events.some((e) => e.by !== A.HOUSE && e.by === me);
  }

  /**
   * How many events are pointed at whoever is flying right now. A count and
   * never a list: knowing there are six out there is the fun part, knowing
   * which six is the end of it.
   */
  A.armedCount = function armedCount() {
    if (unarmed()) return 0;
    const me = A.activePilot();
    const mine = mineToo();
    return events.filter((e) => mine || e.by === A.HOUSE || e.by !== me).length;
  };

  // The tally, if it is loaded, decides whether a pilot's own traps are still
  // making an exception for them. Three bends and they are not. GR11 and GR12.
  const mineToo = () => !!(A.ownEventsArmed && A.ownEventsArmed());

  /** The pilots who have laid traps, and how many each. For the picker. */
  A.eventPilots = function eventPilots() {
    const count = new Map();
    for (const e of events) {
      if (e.by === A.HOUSE) continue;
      count.set(e.by, (count.get(e.by) || 0) + 1);
    }
    return [...count]
      .map(([name, events]) => ({ name, events }))
      .sort((a, b) => a.name.localeCompare(b.name));
  };

  // ---- what is happening right now -----------------------------------------
  //
  // An ambush outlives its own announcement. The banner is gone in two seconds
  // and the walls are still closing, so a fired event stays *live* afterwards
  // and ui/mark.js draws its glyph at the foot of the screen for as long as
  // that lasts. `holds` is the floor in seconds, `while()` keeps it up past
  // the floor for as long as the thing is still in the field, and HOLD_MAX is
  // there because nothing gets to sit down there forever.

  const HOLD = 6;        // seconds a fired event holds the foot of the screen
  const HOLD_MAX = 30;   // and the longest a while() may keep it there
  const LOG_MAX = 12;    // how far back the corner remembers

  const live = [];
  const log = [];

  /** What is being done to the pilot right now, oldest first. For the mark. */
  A.liveEvents = () => live;

  /**
   * And what was done to them earlier in this game, oldest first. A mark that
   * has burned down does not vanish — it steps into the corner and stays for
   * the rest of the run, so the answer to "what has this game thrown at me"
   * is on the screen rather than in anybody's memory.
   */
  A.eventLog = () => log;

  /** Whether an event is the flying pilot's own trap, come back around. */
  const own = (e) => e.by !== A.HOUSE && e.by === A.activePilot();

  // A colour per event, taken off its id, so two ambushes on screen at once
  // are two colours as well as two shapes. Nobody picks it, nobody collides.
  function tintOf(id) {
    let n = 0;
    for (let i = 0; i < id.length; i++) n = (n * 31 + id.charCodeAt(i)) % 3600;
    return n / 10;
  }

  function light(e) {
    live.push({
      e,
      name: e.name || "INCOMING",
      icon: e.icon || null,
      hue: tintOf(e.id),
      own: own(e),
      hold: e.holds || HOLD,
      life: e.holds || HOLD,
      age: 0,
      fade: 0,
    });
  }

  // Same contract as fire(): a bad event is a bug in that event, not a reason
  // for the frame to stop. A while() that throws is simply over.
  function stillGoing(l) {
    if (l.age >= HOLD_MAX || typeof l.e.while !== "function") return false;
    try {
      return !!l.e.while();
    } catch (err) {
      console.error("ASTEROIDS: event " + l.e.id + " (" + l.e.by + ") threw in while()", err);
      return false;
    }
  }

  function burn(tick) {
    for (let i = 0; i < live.length; i++) {
      const l = live[i];
      l.age += tick.dt;
      l.life -= tick.dt;
      const held = l.life > 0 || stillGoing(l);
      l.fade = held ? Math.min(1, l.fade + tick.dt * 5) : l.fade - tick.dt * 2.4;
      if (held || l.fade > 0) continue;

      // over: the same object walks into the corner, carrying everything the
      // mark knows about it, and the oldest one there falls off the end
      log.push(l);
      if (log.length > LOG_MAX) log.shift();
      live.splice(i--, 1);
    }
  }

  // ---- the director --------------------------------------------------------

  const SETTLE = 4;          // seconds into a wave before anything may happen
  const MAX_PER_WAVE = 2;    // an ambush is only an ambush if it is rare
  const GAP = [16, 30];      // seconds between attempts, before the ramp

  let timer = 0;
  let firedThisWave = 0;
  let wave = 0;
  const lastFiredOn = new Map();

  // A pilot who has bent a rule waits less between ambushes, and a wave may
  // hold one more of them. Both come off the ledger, both are capped, and
  // neither exists for anybody who has not earned it. GR12.
  //
  // Whoever tops the board waits less as well, for a reason that has nothing
  // to do with the ledger — game/bounty.js, and it is a share of the gap like
  // the other one. Two impatiences multiply, so they get a floor of their own:
  // a pilot who has bent four rules while sitting on the high score is still
  // playing a wave somebody can read and survive. GR8 is why the floor is
  // here rather than in either of the things it caps.
  const HEAT_FLOOR = 0.45;
  const heat = () => Math.max(HEAT_FLOOR,
    (A.eventHeat ? A.eventHeat() : 1) * (A.bountyHeat ? A.bountyHeat() : 1));
  const quota = () => MAX_PER_WAVE + (A.eventQuotaBonus ? A.eventQuotaBonus() : 0);

  const gap = () => Math.max(9, A.rand(GAP[0], GAP[1]) - A.game.level * 0.7) * heat();

  function eligible() {
    const me = A.activePilot();
    const mine = mineToo();
    return events.filter((e) => {
      if (e.by !== A.HOUSE && e.by === me && !mine) return false;   // never your own
      if ((e.minWave || 1) > A.game.level) return false;
      const last = lastFiredOn.get(e.id);
      if (last !== undefined && A.game.level - last < (e.cooldown || 2)) return false;
      return true;
    });
  }

  function pick(pool) {
    // Airtime is dealt per author first, then per event within the arsenal -
    // a pilot who laid ten traps owns no more of anybody's evening than one
    // who laid a single good one. `weight` ranks an author's own traps
    // against each other; it buys nothing against the rest of the room.
    const arsenals = new Map();
    for (const e of pool) {
      if (!arsenals.has(e.by)) arsenals.set(e.by, []);
      arsenals.get(e.by).push(e);
    }
    const authors = [...arsenals.values()];
    const traps = authors[Math.floor(Math.random() * authors.length)];
    let total = 0;
    for (const e of traps) total += e.weight || 1;
    let n = Math.random() * total;
    for (const e of traps) {
      n -= e.weight || 1;
      if (n <= 0) return e;
    }
    return traps[traps.length - 1];
  }

  // A dedication, first name only, because the banner has one line for it and
  // because that is how anybody says it out loud. The pilot it names reads
  // something else, and reads it while the walls are closing: a dedication
  // nobody is told about is a postcard nobody posted.
  const first = (name) => String(name).split(/\s+/)[0].toUpperCase();

  function dedication(e) {
    if (!e.for) return null;
    return e.for === A.activePilot() ? "FOR YOU, " + first(e.for) : "FOR " + first(e.for);
  }

  function announce(e) {
    // Three things can go under the name, and the order is the order they
    // matter in. Your own trap coming back at you outranks everything — the
    // tally is a punishment, and a punishment nobody notices is only a bug.
    // Then whoever it was written for, because that is the whole of what a
    // dedication is. Then the blurb, which is what it always was.
    const sub = own(e) ? "YOURS. YOU EARNED THIS ONE" : dedication(e) || e.blurb || null;
    A.showBanner(e.name || "INCOMING", sub, 1.8);
    A.screenFlash(A.hue + 200, 0.34);
    A.shakeBy(10);
    A.blip(180, 0.4, "sawtooth", 0.16);
  }

  function reset(mode) {
    timer = gap();
    firedThisWave = 0;
    wave = A.game.level;

    // The game just ended: whatever was still running is over, and joins the
    // rest of it in the corner, which is the last thing anybody reads. A new
    // game and the menu both start with an empty corner.
    if (mode === "over") {
      log.push(...live);
      while (log.length > LOG_MAX) log.shift();
    } else {
      log.length = 0;
    }
    live.length = 0;

    if (mode === "play") lastFiredOn.clear();
  }

  function resolve(tick) {
    // the marks burn down on their own clock, whatever the director is doing
    burn(tick);

    // a new wave: the clock and the quota start again
    if (A.game.level !== wave) {
      wave = A.game.level;
      firedThisWave = 0;
      timer = SETTLE + gap();
    }

    if (A.game.levelTimer > 0) return;        // between waves, let it breathe
    if (firedThisWave >= quota()) return;
    if (!A.flyingShips().length) return;      // nobody alive to ambush
    if (unarmed()) return;                    // and the unarmed are not ambushed

    timer -= tick.dt;
    if (timer > 0) return;
    timer = gap();

    const pool = eligible();
    if (!pool.length) return;

    const e = pick(pool);
    lastFiredOn.set(e.id, A.game.level);
    firedThisWave++;
    announce(e);
    light(e);
    try {
      e.fire(tick);
    } catch (err) {
      // one bad event must not take the game down with it
      console.error("ASTEROIDS: event " + e.id + " (" + e.by + ") threw", err);
    }
  }

  A.register({
    id: "events",
    order: { resolve: 850 },     // before waves, which closes the level out
    reset,
    resolve,
    guide: {
      name: "EVENTS",
      meta: "unannounced",
      tint: "var(--amber)",
      icon: `<svg width="34" height="34" viewBox="0 0 34 34" fill="none"
        stroke="currentColor" stroke-width="1.6">
        <path d="M17 3v7M17 24v7M3 17h7M24 17h7M7 7l5 5M22 22l5 5M27 7l-5 5M12 22l-5 5"/>
        <circle cx="17" cy="17" r="4.5"/></svg>`,
      desc: "The field has moods. Somebody wrote one of them for you, and it is not the one they get. A pilot with no trap laid is spared the lot &mdash; the room arms when you do. Some of them arrive with a name under the banner: that is a dedication, and it is addressed to somebody rather than aimed at them.",
    },
  });
})(ASTEROIDS);
