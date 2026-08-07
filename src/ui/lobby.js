// The seat cards on the splash screen, straight off the seat list — so the
// keys printed here can never drift from the keys the game listens for, and
// the ship on the card is traced from the same point list entities/ship.js
// flies (A.SHIP_HULL). It wears the seat's own colour, and the rack it is
// bolted to drifts through the spectrum, so the hull on the card is roughly
// the hull you will be holding a minute later.
//
// Seat one is in the game before anybody touches anything. Seat two is an
// invitation, and an invitation that looks exactly as lit as the seat already
// flying is not one — so an open seat steps back to an empty frame with a cold
// ship in it, and the only thing left at full strength is the key that fills
// it. Nothing here is hidden, it is only quiet; the card still answers every
// question it ever answered, to anybody who leans in.

(function (A) {
  "use strict";

  const path = (pts, close) =>
    pts.map(([x, y], i) => (i ? "L" : "M") + x + " " + y).join("") + (close ? "Z" : "");

  // One box for both outlines, so the flame hangs off the back of the hull at
  // the size it really is instead of being scaled to fit beside it. A cabinet
  // that somehow has no ship module gets a card with no ship on it rather than
  // a broken one, which is what every fallback in this project does.
  const ship = () => !A.SHIP_HULL ? "" : `
        <svg class="hull" viewBox="-11 -15 22 35" aria-hidden="true">
          <path class="jet" d="${path(A.SHIP_FLAME)}"/>
          <path class="body" d="${path(A.SHIP_HULL, true)}"/>
        </svg>`;

  A.renderLobby = function renderLobby() {
    const root = document.getElementById("seats");
    root.innerHTML = A.SEATS.map((seat, i) => `
      <div class="seat${i === 0 ? "" : " open"}" style="color:${seat.tint}">${ship()}
        <div class="who">${seat.name}</div>
        <div class="binds">${
          seat.binds.map(([keys, what]) =>
            `<span>${keys.split(" ").map((k) => `<b>${k}</b>`).join("")} ${what}</span>`
          ).join("")
        }</div>
        <div class="ready">${seat.lobby}</div>
      </div>`).join("");
  };
})(ASTEROIDS);
