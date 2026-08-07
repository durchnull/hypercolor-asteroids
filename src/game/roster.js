// The guest list.
//
// The picker is built from the event registry, which is exact and never goes
// stale — but it only knows a pilot once they have laid a trap, and everybody
// arrives before that. Somebody is handed a key, pulls, presses ENTER, and
// finds a splash screen that has never heard of them: fly as GUEST with every
// trap armed, or fly under somebody else's name and spoil their surprises
// instead of your own. Neither is much of a welcome.
//
// So this is the one list in the cabinet written by hand rather than read off
// the history: the people holding a key to the repository, spelled the way
// their git config spells them. It grants nothing. A seat is only worth
// anything because your own events go quiet behind it, and a pilot who has not
// written one has nothing to go quiet — a fresh name here is exactly as
// dangerous as GUEST, and stops being so the moment they lay their first trap,
// at which point the registry would have listed them anyway. What it buys is a
// name to point at on the way in, and a card that reads "no traps laid", which
// is the most pointed invitation this screen knows how to make.
//
// Names in the source, so: GR7 says sign your work in git, and this is no more
// a signature than an event's `by:` is. Nobody is credited by appearing here,
// and git blame still says who added the line.
//
// Spell one wrong and nothing breaks. tools/whoami.sh writes the real git name
// into whoami.local.js, that seat wins, and the picker shows it whether it is
// on this list or not — the misspelling just sits there being nobody until
// somebody deletes the line.

(function (A) {
  "use strict";

  A.ROSTER = [
    "David Friedrich",
    "Malte Buttjer",
    "Michele Rüdiger",
  ];
})(ASTEROIDS);
