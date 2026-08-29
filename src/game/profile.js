// Who is flying.
//
// The splash screen asks before it lets you in, because the answer decides
// which events are armed against you. An event never fires for the pilot who
// wrote it — see game/events.js — so the profile is not a cosmetic label, it
// is which half of the ambushes you are on the wrong end of.
//
// There is no incentive to lie about it, which is the nice part. Pick somebody
// else's name and their events go quiet while your own start firing: you spoil
// your own surprises and nobody else's. The honest answer is the fun one.
//
// Two places remember who you are, and the order matters:
//
//   localStorage          what you last picked. A player answers once and the
//                         cabinet stops asking, the same way it remembers the
//                         best score. May throw on a file:// page in some
//                         browsers, which is why every touch of it is wrapped
//                         — without it the picker simply asks again next time.
//   whoami.local.js       your git identity, and it wins. Written by
//                         tools/whoami.sh, untracked, never leaves this
//                         machine. With it there the seat is locked and the
//                         stored pick is ignored, not overwritten: delete the
//                         file and you are back to whatever you last chose.
//
// This is identity, not security, and it does not pretend otherwise.

(function (A) {
  "use strict";

  const KEY = "asteroids-pilot";

  A.GUEST = "GUEST";

  let current = A.GUEST;
  let locked = false;

  try {
    current = localStorage.getItem(KEY) || A.GUEST;
  } catch (e) {}

  A.activePilot = () => current;
  A.pilotLocked = () => locked;

  A.setPilot = function setPilot(name) {
    if (locked) return current;
    current = name || A.GUEST;
    try { localStorage.setItem(KEY, current); } catch (e) {}
    return current;
  };

  // The local identity, asked for rather than listed in the manifest: it is
  // untracked, so on most machines it is simply not there. A miss is silent
  // and the picker stays open; a hit arrives a moment later and locks it, and
  // the splash screen is still sitting there waiting for ENTER either way.
  const s = document.createElement("script");
  s.src = "src/game/whoami.local.js";
  s.async = false;
  s.onerror = () => {};                      // not there: you are a player, then
  s.onload = () => {
    if (!A.LOCAL_PILOT) return;
    current = A.LOCAL_PILOT;
    locked = true;
    if (A.renderPilot) A.renderPilot();
  };
  document.head.append(s);
})(ASTEROIDS);
