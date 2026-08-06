// The field guide on the splash screen writes itself.
//
// Every feature that registers a `guide` gets a row here, in `order.guide`.
// Nobody maintains a list: ship a feature with a guide entry and it is on the
// splash screen, which is also why nothing on that screen can go stale.
//
//   guide: {
//     name: "KRAKEN",
//     meta: "250 · 3–5 hits",   // optional, the amber bit after the name
//     tint: "var(--magenta)",
//     icon: `<svg …>`,          // 34×34, stroke="currentColor"
//     desc: "Hunts you, dives into the deep…",
//   }

(function (A) {
  "use strict";

  A.renderGuide = function renderGuide() {
    const ul = document.getElementById("guide");
    ul.innerHTML = A.guides().map((entry, i) => `
      <li style="--i:${i}">
        <span class="icon" style="color:${entry.tint}">${entry.icon}</span>
        <div>
          <span class="name">${entry.name}</span>${
            entry.meta ? `<span class="pts">${entry.meta}</span>` : ""}
          <p class="desc">${entry.desc}</p>
        </div>
      </li>`).join("");
  };
})(ASTEROIDS);
