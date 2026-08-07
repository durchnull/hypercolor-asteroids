// The cabinet answers your hand.
//
// Everything on the splash screen has been pointable at for a while — seat
// cards, plates, the door out into the book — and pointing at it was silent,
// which on a machine this loud reads as a web page rather than as furniture. So
// there is a note under the cursor now, and a firmer one under the press.
//
// Two decisions are what keep that on the right side of annoying.
//
// The notes are in tonight's key. src/audio/sfx.js counts them off the tonic of
// the vamp that is already playing under this screen, so the panels are in the
// band rather than over it, and a cabinet that rolled NEON CHAPEL clicks in D
// while the one next to it clicks in E.
//
// And the screen is laid out like an instrument. A thing's note comes from
// where it sits — which panel, and how far down it — so it is the same note in
// the same place every time, and sweeping a list runs up a scale rather than
// repeating one beep. The field guide is fifteen rows long and it is the best
// thing on the screen to drag a cursor down.
//
// Nothing here is heard before the first press of a session, and that is the
// browser's rule rather than ours: an audio context will not start for a mouse
// that is merely moving over things. The first press on anything brings the
// sound up and takes its own noise with it, and the hovers work from then on.

(function (A) {
  "use strict";

  // Anything a hand can arrive at. Deliberately by shape rather than by name —
  // a panel somebody adds next month gets this for free, the same way it gets
  // the CRT and the spectrum.
  const LIVE = "button, a[href], #guide li";

  // The pads are the game being played, not the cabinet being chosen, and they
  // have the whole of src/audio/sfx.js to make noise with already. The tape is
  // text somebody is selecting.
  const QUIET = "#touch, #debrief pre";

  const GAP = 45;             // ms between hovers: a fast sweep is a run, not a buzz

  let lastEl = null;
  let lastAt = 0;

  // Where a thing sits, as a step of the scale. The panel it is in sets the
  // starting degree and its place in that panel walks up from there, so each
  // panel of the deck answers in its own corner of the key. Two steps apart is
  // not an accident: the scale in sfx.js is ten notes long and the deck is five
  // panels wide, so every panel gets a degree nobody else starts on.
  const OUTSIDE = 6;    // the sound button, the copy button: furniture, not rack

  function stepOf(el) {
    const panel = el.closest(".deck > section");
    if (!panel) return OUTSIDE;
    const home = [...panel.parentElement.children].indexOf(panel);
    const kin = el.parentElement ? [...el.parentElement.children] : [];
    return Math.max(0, home) * 2 + Math.max(0, kin.indexOf(el));
  }

  function touchable(target) {
    const el = target && target.closest ? target.closest(LIVE) : null;
    if (!el || el.closest(QUIET)) return null;
    return el;
  }

  function hover(el) {
    const now = performance.now();
    if (el === lastEl || now - lastAt < GAP) return;
    lastEl = el;
    lastAt = now;
    A.uiHover(stepOf(el));
  }

  // Capture, both of them: the debrief panel stops pointerdown from bubbling so
  // that copying the tape does not launch the next flight, and a button that
  // answers everywhere except the one place somebody thought about it hardest
  // is worse than one that never answered at all.
  document.addEventListener("pointerover", (e) => {
    if (e.pointerType === "touch") return;   // a finger is a press, not a hover
    const el = touchable(e.target);
    if (el) hover(el);
  }, true);

  // The same tick for a keyboard, which is how half this cabinet is driven.
  document.addEventListener("focusin", (e) => {
    const el = touchable(e.target);
    if (el) hover(el);
  }, true);

  document.addEventListener("pointerdown", (e) => {
    const el = touchable(e.target);
    if (!el || el.id === "mute") return;
    // The first press of the session is what is allowed to start the audio, so
    // it has to be the thing that starts it — otherwise the button somebody
    // pressed to find out whether this cabinet makes noise is the one button
    // that did not.
    A.ensureAudio();
    lastEl = null;                       // hovering back over it should answer again
    const step = stepOf(el);
    if (el.matches("[data-pilot]")) el.disabled ? A.uiDeny() : A.uiPick(step);
    else if (el.matches("a[href]")) A.uiDoor(step);
    else A.uiClick(step);
  }, true);

  // The sound button is the one control whose own sound has to happen after it
  // has been pressed rather than as it is: half the time it is being pressed to
  // turn the sound back on, and a cabinet that says nothing about that has not
  // answered the question it was asked. src/ui/mute.js is commons and loads
  // first, so by the time this runs the switch has already flipped.
  const mute = document.getElementById("mute");
  if (mute) mute.addEventListener("click", () => A.uiClick(OUTSIDE));

  A.register({
    id: "ui:clicks",
    // last in the guide, under the band — it is not a thing in the field either
    order: { guide: 96 },
    guide: {
      name: "THE PANELS",
      meta: "in tonight's key",
      tint: "var(--cyan)",
      icon: `<svg width="34" height="34" viewBox="0 0 34 34" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round" stroke-linecap="round" aria-hidden="true">
        <path d="M9 5.5 L9 23 L13.2 18.9 L16 25.5 L18.6 24.4 L15.9 18 L21.5 17.4 Z"/>
        <path d="M23.5 11.5a7 7 0 0 1 0 11" opacity="0.75"/>
        <path d="M27 8a11.5 11.5 0 0 1 0 18" opacity="0.4"/>
      </svg>`,
      desc: `This screen answers back. Every card, row and door has a note of
        its own &mdash; picked by where it sits, tuned to whatever the band is
        playing tonight &mdash; so pointing at things is an instrument and
        running a cursor down this list is a scale. M still turns the lot off.`,
    },
  });
})(ASTEROIDS);
