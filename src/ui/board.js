// The board on the splash screen — the top of docs/RANKINGS.md, in miniature.
//
// Nobody types a score into this panel and nobody can. A flight gets onto that
// table exactly one way: you die, you copy the black box off the game-over
// screen, somebody verifies the seal, and it lands in the file. This reads the
// file back, five rows of it, so the number you are about to try and beat is
// on the screen while you are deciding whether to press ENTER.
//
// The numbers arrive in docs/chronicle.js, written by tools/chronicle.sh out of
// the same markdown the rankings page renders. A clone that has never run that
// tool has no such file, which is the ordinary case and not a broken one — the
// panel says the board is empty, which is also what it says when the board is
// empty, and both are an invitation.

(function (A) {
  "use strict";

  const TOP = 5;               // a miniature. the rest of the table is a click away

  const esc = (s) => String(s)
    .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");

  A.renderBoard = function renderBoard() {
    const root = document.getElementById("board");
    if (!root) return;

    const rows = (A.BOARD || []).slice(0, TOP);
    const flying = A.activePilot ? A.activePilot() : "";

    root.innerHTML = `
      <h2>${A.ico("cup")}THE BOARD</h2>
      ${rows.length ? `
      <ol class="ranks">${rows.map((r, i) => `
        <li class="rank r${i + 1}${r.pilot === flying ? " you" : ""}">
          <span class="rn">${esc(r.rank || i + 1)}</span>
          <span class="rwho">${esc(r.pilot)}</span>
          <span class="rsc">${esc(r.score)}</span>
          <span class="rwv">w${esc(r.wave)}</span>
        </li>`).join("")}
      </ol>`
      : `<p class="boardnone">Nothing on the record yet. The first flight anybody
         seals is the one everybody else has to beat, which is the cheapest
         high score this cabinet will ever hand out.</p>`}
      <p class="boardnote">${A.ico("door")}<a href="docs/rankings.html">THE FLIGHT RECORDS</a>
        <span>a sealed tape is the only way onto this table</span></p>`;
  };

  A.register({
    id: "ui:board",
    // the splash is being rebuilt, so the board comes back with it — and the
    // pilot may have changed seats since the last one, which moves the highlight
    reset(mode) {
      if (mode === "attract") A.renderBoard();
    },
  });

  A.sidecar("docs/chronicle.js", () => A.renderBoard());
})(ASTEROIDS);
