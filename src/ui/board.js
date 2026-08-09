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
// tool has no such file, which is the ordinary case and not a broken one.
//
// It used to say the same thing about that as it says about a board with
// nothing on it, and the two stopped meaning the same thing the day
// game/bounty.js started reading the top row. An empty board is a cabinet
// nobody has flown yet, and everybody in it is playing the same field. An
// unbuilt one is a cabinet where somebody is wearing a crown they cannot see
// and nobody is being hurried along by it — the same repository, two
// measurably different evenings, and until now no way to tell from the screen
// which one you were having. So it says which.

(function (A) {
  "use strict";

  const TOP = 5;               // a miniature. the rest of the table is a click away

  const esc = (s) => String(s)
    .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");

  // Whether docs/chronicle.js has had its go, hit or miss. Until it has, the
  // absence of A.BOARD says nothing at all, and a panel that announced an
  // unbuilt book for one frame and then filled with rows would be lying twice.
  let asked = false;

  A.renderBoard = function renderBoard() {
    const root = document.getElementById("board");
    if (!root) return;

    const unbuilt = asked && !A.BOARD;
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
      : unbuilt ? `<p class="boardnone">No board in this clone. The records are
         all still there &mdash; nobody has run tools/chronicle.sh to write them
         out for this screen, which takes a second and needs nothing installed.
         Worth doing: the field watches whoever is on the top row, and until
         this is built it is not watching anybody.</p>`
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

  A.sidecar("docs/chronicle.js", () => { asked = true; A.renderBoard(); });
})(ASTEROIDS);
