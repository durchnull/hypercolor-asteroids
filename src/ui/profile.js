// The pilot picker on the splash screen.
//
// Built from the event registry, so it cannot go stale: a pilot appears here
// the moment they land their first event, and the count next to their name is
// how many events of theirs are armed against everybody else.
//
// It re-renders on every return to the splash, which is how the locked seat
// arrives — whoami.local.js loads a moment after the page and asks for a
// redraw when it does. The faces arrive the same way and for the same reason:
// docs/faces/faces.js is written by tools/chronicle-art.sh out of the list of
// pilots who have been painted, it is a script rather than data because there
// is no fetch in this project (GR2), and a clone that has none of it simply
// gets the cards it always had.

(function (A) {
  "use strict";

  const esc = (s) => String(s)
    .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");

  const plural = (n, one, many) => n + " " + (n === 1 ? one : many);

  // The picture belonging to a name, if one was ever painted. GUEST is not a
  // person and never gets one.
  const faceOf = (name) => (A.FACES && A.FACES[name]) || "";

  A.renderPilot = function renderPilot() {
    const root = document.getElementById("pilot");
    if (!root) return;

    const active = A.activePilot();
    const locked = A.pilotLocked();
    const pilots = A.eventPilots ? A.eventPilots() : [];

    // Everyone with an event in the game, then everyone on the guest list who has
    // not laid one yet, then whoever is locked into this seat even if they are
    // on neither — a pilot whose git name nobody spelled right still gets to see
    // their own card. Names collapse: the count only ever comes from the
    // registry, and the roster decides nothing except who else gets a card.
    const named = new Map(pilots.map((p) => [p.name, p]));
    for (const name of (A.ROSTER || []).concat(locked ? [active] : [])) {
      if (name && name !== A.GUEST && !named.has(name)) named.set(name, { name, events: 0 });
    }

    const seats = [{ name: A.GUEST, events: -1 }].concat(
      [...named.values()].sort((a, b) => a.name.localeCompare(b.name)));

    // A locked seat shows itself and nothing else; there is nothing to choose.
    const shown = locked ? seats.filter((p) => p.name === active) : seats;
    const known = shown.length > 0;

    const bends = (name) => (A.pilotBends ? A.pilotBends(name) : 0);

    root.innerHTML = `
      <h2>${A.ico("helmet")}WHO IS FLYING</h2>
      <div class="pilots">${(known ? shown : seats).map((p) => `
        <button type="button" class="pilotcard${p.name === active ? " on" : ""}"
                data-pilot="${esc(p.name)}"${locked ? " disabled" : ""}>${
          faceOf(p.name) ? `
          <img class="pface" src="docs/faces/${esc(faceOf(p.name))}" alt="">`
          : ""}
          <span class="pname">${esc(p.name)}</span>
          <span class="pmeta">${
            p.events < 0 ? A.ico("aim") + "every event armed"
            : p.events === 0 ? A.ico("event", "cold") + "no events written"
            : A.ico("event") + plural(p.events, "event", "events") + " written"
          }</span>${(() => {
            const r = A.serviceRecord && A.serviceRecord(p.name);
            if (!r || (!r.versions && !r.flights)) return "";
            const bits = [];
            if (r.versions) bits.push(plural(r.versions, "version", "versions") + " landed");
            if (r.flights) bits.push(plural(r.flights, "flight", "flights") + " on the board");
            return `
          <span class="pserv">${A.ico("chevron")}${bits.join(" &middot; ")}</span>`;
          })()}${bends(p.name) ? `
          <span class="pbends${(A.pilotHeatBends ? A.pilotHeatBends(p.name) : bends(p.name)) >= 3 ? " hot" : ""}">${A.ico("bend")}${
            plural(bends(p.name), "bend", "bends")} on the ledger</span>`
          : ""}
        </button>`).join("")}
      </div>
      <p class="pilotarmed${A.armedCount && A.armedCount() ? " live" : ""}">${
        A.ico("aim")}${plural(A.armedCount ? A.armedCount() : 0,
        "event is pointed at you", "events are pointed at you")}</p>
      <p class="pilotnote">${
        A.ownEventsArmed && A.ownEventsArmed()
        ? "&#9670; the ledger has you at " + plural(bends(active), "bend", "bends")
          + ", which is past the point where your own events go on sparing you. "
          + "They are in the pile with everybody else's now. The field will also "
          + "come for you sooner than it does for the others."
        : active !== A.GUEST && pilots.length > 0 && A.armedCount && A.armedCount() === 0
        ? "&#9670; the field does not ambush the unarmed. None of the events in "
          + "this room fire at a pilot who has laid none &mdash; write your "
          + "first event and the room arms itself. That is the induction."
        : locked
        ? "&#9670; your git identity, so this seat is yours. Your own events "
          + "stay quiet &mdash; you get to be surprised by everyone else's."
        : "Events are written by the pilots, and never fire for the one who "
          + "wrote them. Pick your own name and theirs are armed against you; "
          + "pick somebody else's and you only spoil your own."}</p>`;

    // A face is never repainted, so a manifest can outlive the picture it
    // names. Rather than leave a broken image sitting on somebody's seat, the
    // card gives the space back and reads as it did before there were faces.
    root.querySelectorAll(".pface").forEach((img) => {
      img.addEventListener("error", () => img.remove(), { once: true });
    });
  };

  function onClick(ev) {
    const card = ev.target.closest("[data-pilot]");
    if (!card || A.pilotLocked()) return;
    A.setPilot(card.dataset.pilot);
    A.renderPilot();
  }

  // The faces, asked for the same way the seat is and just as optionally: it
  // is a generated file that only exists once somebody has been painted, so a
  // miss is silent and a hit asks for a redraw of whatever is already on screen.
  A.sidecar("docs/faces/faces.js", () => A.renderPilot());

  A.register({
    id: "ui:profile",
    // the splash is being rebuilt, so the picker rebuilds with it
    reset(mode) {
      if (mode === "attract") A.renderPilot();
    },
  });

  document.addEventListener("click", onClick);
})(ASTEROIDS);
