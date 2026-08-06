// The seat cards on the splash screen, straight off the seat list — so the
// keys printed here can never drift from the keys the game listens for.

(function (A) {
  "use strict";

  A.renderLobby = function renderLobby() {
    const root = document.getElementById("seats");
    root.innerHTML = A.SEATS.map((seat, i) => `
      <div class="seat" style="color:${seat.tint}">
        <div class="who">${seat.name}</div>
        <div class="binds">${
          seat.binds.map(([keys, what]) =>
            `<span>${keys.split(" ").map((k) => `<b>${k}</b>`).join("")} ${what}</span>`
          ).join("")
        }</div>
        <div class="ready${i === 0 ? "" : " open"}">${seat.lobby}</div>
      </div>`).join("");
  };
})(ASTEROIDS);
