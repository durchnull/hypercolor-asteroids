// The HUD: one panel per seat, the wave in the middle.
//
// It polls once a frame and rebuilds only when something it shows has actually
// changed, so no other module has to remember to tell it anything.

(function (A) {
  "use strict";

  const SHIP_GLYPH =
    '<svg width="12" height="15" viewBox="0 0 14 18" fill="none">' +
    '<path d="M7 1 L13 17 L7 13 L1 17 Z" stroke="currentColor" stroke-width="1.6"/></svg>';
  const BOMB_GLYPH =
    '<svg width="13" height="13" viewBox="0 0 15 15" fill="none">' +
    '<circle cx="7.5" cy="9" r="5" stroke="currentColor" stroke-width="1.4"/>' +
    '<ellipse cx="7.5" cy="9" rx="5" ry="2" stroke="currentColor" stroke-width="1" opacity="0.6"/>' +
    '<path d="M7.5 4 V1.5 M5.5 2.5 L9.5 0.8" stroke="currentColor" stroke-width="1.3"/></svg>';

  const panels = [];
  let levelEl = null;
  let hudKey = "";

  A.buildHud = function buildHud() {
    const root = document.getElementById("hud");
    root.replaceChildren();
    levelEl = document.createElement("div");
    levelEl.className = "level";

    A.SEATS.forEach((seat, i) => {
      const el = document.createElement("div");
      el.className = "player";
      el.style.color = seat.tint;
      panels[i] = el;
      root.append(el);
      // the wave sits between the first two seats
      if (i === 0) root.append(levelEl);
    });
  };

  function updateHud() {
    const key = A.players.map((p) => p && [p.score, p.lives, p.bombs, p.out].join()).join("|")
      + "/" + A.game.level + "/" + A.game.phase;
    if (key === hudKey) return;
    hudKey = key;

    // nothing to say on the attract screen; after a game it holds the last wave
    levelEl.textContent = A.game.phase === "start" ? "" : "LEVEL " + A.game.level;

    A.SEATS.forEach((seat, i) => {
      const el = panels[i];
      const p = A.players[i];
      el.className = "player" + (seat.side === "right" ? " right" : "");
      if (!p) {
        el.innerHTML = A.game.phase === "playing"
          ? '<div class="tag">' + seat.tag + '</div>' +
            '<div class="hint">' + seat.joinHint + "</div>"
          : "";
        return;
      }
      if (p.out) el.className += " out";
      el.innerHTML =
        '<div class="tag">' + seat.tag + "</div>" +
        '<div class="pscore">' + p.score + "</div>" +
        (p.out
          ? '<div class="hint">' + seat.rejoinHint + "</div>"
          : '<div class="glyphs">' + SHIP_GLYPH.repeat(Math.max(p.lives, 0)) + "</div>" +
            '<div class="glyphs bombs">' +
              (p.bombs > 0 ? BOMB_GLYPH.repeat(p.bombs) : '<span class="empty">NO BOMBS</span>') +
            "</div>");
    });
  }

  A.register({ id: "hud", order: { update: 95 }, update: updateHud });
})(ASTEROIDS);
