// Which soundtrack the cabinet rolled tonight.
//
// The field guide asks every feature what it wants to say about itself, and
// this is the one feature that is already playing before you read its entry.
// It sits last in the guide because it is not a thing in the field — it is the
// band, and the band goes at the bottom of the poster.

(function (A) {
  "use strict";

  A.register({
    id: "soundtrack",
    order: { guide: 95 },
    guide: {
      name: "TONIGHT: " + A.theme.name,
      meta: A.theme.bpm + " BPM",
      tint: A.theme.tint,
      icon: `<svg width="34" height="34" viewBox="0 0 34 34" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" aria-hidden="true">
        <path d="M4 17 h3 M11 17 h3 M18 17 h3 M25 17 h3" opacity="0.35"/>
        <path d="M5.5 13.5 v7 M12.5 8 v18 M19.5 11 v12 M26.5 6 v22"/>
      </svg>`,
      desc: `${A.theme.blurb} One of ten &mdash; the splash, the flight, the
        death and the way out, all in the same key. Rolled when the page
        opened, so reload for a different evening.`,
    },
  });
})(ASTEROIDS);
