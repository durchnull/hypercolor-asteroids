// The doorway to the chronicle, with a picture in it.
//
// docs/index.html is the cover and docs/v<N>.html is a page per version, and
// for a long time the splash screen mentioned all of that in one grey line of
// six words. It is a book somebody paints plates for; it can afford a window.
//
// So: the last few plates at a size you can actually see, a sentence saying
// what the thing behind them is, and the newest chapter in miniature — the
// version number, who flew it and the line they wrote about it. Somebody who
// pulls this repository at three in the afternoon finds out what happened to
// the cabinet before they have pressed anything.
//
// The plates and the chapter come from docs/chronicle.js, written by
// tools/chronicle.sh. Without it this is the grey line of six words again,
// which is what a clone that has never run the tool gets and what the panel is
// designed around: no data is a layout, not a hole.

(function (A) {
  "use strict";

  const esc = (s) => String(s)
    .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");

  const TEASER = "Every version that has ever been on this cabinet, a page each"
    + " — what changed, who flew it, and the line they wrote about it"
    + " afterwards. Somebody painted a plate for most of them.";

  A.renderBook = function renderBook() {
    const root = document.getElementById("book");
    if (!root) return;

    const c = A.CHRONICLE;
    const plates = (c && c.plates) || [];
    const latest = c && c.latest;

    root.innerHTML = `
      <h2>${A.ico("book")}THE CHRONICLE${
        c ? `<span class="bcount">${c.versions} version${c.versions === 1 ? "" : "s"}</span>` : ""}</h2>
      <div class="bwrap${plates.length ? "" : " bare"}">${plates.length ? `
        <div class="plates">${plates.map((p, i) => `
          <a class="plate${i === 0 ? " lead" : ""}" href="docs/v${p.v}.html"
             title="v${p.v} &middot; ${esc(p.line || p.alt)}">
            <img src="docs/art/${esc(p.file)}" alt="" loading="lazy" decoding="async">
            <span class="pv">v${p.v}</span>
          </a>`).join("")}
        </div>` : ""}
        <div class="btext">
          <p class="bteaser">${TEASER}</p>${latest ? `
          <a class="latest" href="docs/v${latest.v}.html">
            <span class="lv">v${latest.v}</span>
            <span class="lbody">
              <span class="lline">${esc(latest.line || "nobody wrote this one down")}</span>
              <span class="lwho">${esc(latest.pilot)} &middot; ${esc(latest.date)}</span>
            </span>
            <span class="lgo">${A.ico("door")}</span>
          </a>` : ""}
          <p class="bdoor">${A.ico("door")}<a href="docs/index.html">OPEN THE BOOK</a></p>
        </div>
      </div>`;

    // A plate can be repainted but a manifest can outlive a file, and a panel
    // with a broken picture in it is worse than a panel with one fewer. Same
    // bargain the faces strike on the seat cards.
    root.querySelectorAll(".plate img").forEach((img) => {
      img.addEventListener("error", () => img.closest(".plate").remove(), { once: true });
    });
  };

  A.register({
    id: "ui:book",
    reset(mode) {
      if (mode === "attract") A.renderBook();
    },
  });

  A.sidecar("docs/chronicle.js", () => A.renderBook());
})(ASTEROIDS);
