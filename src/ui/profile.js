// The pilot picker on the splash screen.
//
// Built from records that already exist, so it cannot go stale: a pilot
// appears here the moment they land their first version, write their first
// event or put their first flight on the board, and every number on the card
// is counted rather than assigned.
//
// It re-renders on every return to the splash, which is how the locked seat
// arrives — whoami.local.js loads a moment after the page and asks for a
// redraw when it does. The faces arrive the same way and for the same reason:
// docs/faces/faces.js is written by tools/chronicle-art.sh out of the list of
// pilots who have been painted, it is a script rather than data because there
// is no fetch in this project (GR2), and a clone that has none of it simply
// gets the cards it always had.
//
// **The panel is a fixed height and the room is dealt into pages of four.** It
// used to be a grid that got taller with every pilot, which was free while
// there were four of them and would quietly push the board and the book off a
// laptop at twelve. Then it was a scroll box, which held the height but hid
// the room: a splash screen is read at a glance and nobody drags a list on it,
// so the fifth pilot was as good as absent and the fade at the bottom edge was
// the only thing arguing otherwise.
//
// So it deals. Four cards to a page, the pages side by side on a track that
// slides, and a footer that says which page this is out of how many. Every
// pilot is one press away instead of one gesture nobody makes, the panel is
// the same height at three pilots or thirty, and the page you were on survives
// a redraw — picking a card re-renders the whole picker, and a deck that
// snapped back to the first page every time you chose somebody from the third
// would be unusable.
//
// **A locked seat used to show itself and nothing else**, on the reasoning
// that there is nothing to choose. True, and it also meant the one pilot who
// had set their seat up properly was the only one who never saw the room: no
// idea who else flies here, what they have landed, or what the ledger has on
// them. The cards are still not a choice when the seat is locked — they are
// disabled, and yours is the lit one at the top — but the room is worth
// looking at whether or not you can sit anywhere else in it.

(function (A) {
  "use strict";

  const esc = (s) => String(s)
    .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");

  const plural = (n, one, many) => n + " " + (n === 1 ? one : many);

  // Four to a page. It is the number the panel has room for at the height it
  // has always been, and the same four whether the deck is one column or two —
  // a page that held six on a wide screen and three on a narrow one would put
  // a different pilot behind the arrow depending on the window.
  const PER = 4;

  // Which page is showing. Module state rather than a data- attribute on the
  // panel, because the panel is thrown away and rebuilt on every redraw and
  // this has to outlive that: a redraw happens every time somebody picks a
  // card, and every time whoami.local.js or faces.js turns up late.
  let page = 0;

  // The picture belonging to a name, if one was ever painted. GUEST is not a
  // person and never gets one.
  const faceOf = (name) => (A.FACES && A.FACES[name]) || "";

  // What a pilot has actually put into this cabinet, and the only thing the
  // order of the cards is decided by. A version is an evening — GR14 prices it
  // at three flights and says so — an event is the induction that arms the
  // room against everybody but its author, and a flight is four minutes. So
  // they are weighted in that order. Bends are not in it: the ledger is a
  // difficulty setting rather than a ranking, and sorting the room by who has
  // been naughtiest would turn it into one.
  const standing = (name) => {
    const r = A.serviceRecord && A.serviceRecord(name);
    return r ? r.versions * 3 + r.events * 2 + r.flights : 0;
  };

  // Everybody this cabinet has heard of, from the three records that already
  // know: the event registry, the book's roster of who has landed a version,
  // and the flight board. Then the guest list, for the people who hold a key
  // and have not done any of the three yet, and finally whoever is locked into
  // this seat even if they are on none of them — a pilot whose git name nobody
  // spelled right still gets to see their own card. Names collapse; the event
  // count only ever comes from the registry.
  function seatList() {
    const locked = A.pilotLocked();
    const named = new Map((A.eventPilots ? A.eventPilots() : []).map((p) => [p.name, p]));
    const rest = Object.keys((A.CHRONICLE && A.CHRONICLE.roster) || {})
      .concat((A.BOARD || []).map((r) => r.pilot))
      .concat(A.ROSTER || [])
      .concat(locked ? [A.activePilot()] : []);
    for (const name of rest) {
      if (name && name !== A.GUEST && !named.has(name)) named.set(name, { name, events: 0 });
    }

    // The seat you are in leads, and it stays there when you pick somebody
    // else's name: it is your git identity if you have one and GUEST if you do
    // not, never whatever card was clicked last. A list that reordered itself
    // under the cursor would be a list nobody could click twice.
    const home = locked ? A.activePilot() : A.GUEST;
    return [{ name: A.GUEST, events: -1 }].concat([...named.values()]).sort((a, b) =>
      (a.name === home ? -1 : b.name === home ? 1 : 0) ||
      standing(b.name) - standing(a.name) ||
      a.name.localeCompare(b.name));
  }

  function card(p, active, locked) {
    const bends = A.pilotBends ? A.pilotBends(p.name) : 0;
    const heat = A.pilotHeatBends ? A.pilotHeatBends(p.name) : bends;
    const r = A.serviceRecord && A.serviceRecord(p.name);
    const serv = [];
    if (r && r.versions) serv.push(plural(r.versions, "version", "versions") + " landed");
    if (r && r.flights) serv.push(plural(r.flights, "flight", "flights") + " on the board");

    return `
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
          }</span>${serv.length ? `
          <span class="pserv">${A.ico("chevron")}${serv.join(" &middot; ")}</span>` : ""}${
          bends ? `
          <span class="pbends${heat >= 3 ? " hot" : ""}">${A.ico("bend")}${
            plural(bends, "bend", "bends")} on the ledger</span>` : ""}
        </button>`;
  }

  A.renderPilot = function renderPilot() {
    const root = document.getElementById("pilot");
    if (!root) return;

    const active = A.activePilot();
    const locked = A.pilotLocked();
    const seats = seatList();
    const bends = (name) => (A.pilotBends ? A.pilotBends(name) : 0);
    // "nobody is pointed at you" only means the shelter is holding if there is
    // anything in the room to be pointed at in the first place.
    const armable = (A.eventPilots ? A.eventPilots() : []).length > 0;

    // The room, dealt. Whole pages are kept in the DOM side by side so the
    // track is as tall as its tallest page and the panel never jumps a pixel
    // between presses.
    const pages = [];
    for (let i = 0; i < seats.length; i += PER) pages.push(seats.slice(i, i + PER));
    if (!pages.length) pages.push([]);
    page = Math.max(0, Math.min(page, pages.length - 1));

    root.innerHTML = `
      <h2>${A.ico("helmet")}WHO IS FLYING<span class="pcount">${seats.length}</span></h2>
      <div class="pilotdeck">
        <div class="pilotroll">
          <div class="pilottrack" style="transform: translateX(${-page * 100}%)">${
            pages.map((pg, i) => `
            <div class="pilots"${i === page ? "" : " inert aria-hidden=\"true\""}>${
              pg.map((p) => card(p, active, locked)).join("")}</div>`).join("")}
          </div>
        </div>
      </div>${pages.length > 1 ? `
      <div class="pilotpager">
        <button type="button" class="pstep" data-step="-1"
                aria-label="Previous pilots"${page === 0 ? " disabled" : ""}>${A.ico("next")}</button>
        <span class="pdots">${pages.map((pg, i) => `
          <button type="button" class="pdot${i === page ? " on" : ""}" data-page="${i}"
                  aria-label="Pilots ${i * PER + 1} to ${i * PER + pg.length}"${
                  i === page ? ' aria-current="true"' : ""}></button>`).join("")}
        </span>
        <span class="pof">${page + 1}<i>/</i>${pages.length}</span>
        <button type="button" class="pstep next" data-step="1"
                aria-label="More pilots"${page === pages.length - 1 ? " disabled" : ""}>${A.ico("next")}</button>
      </div>` : ""}
      <p class="pilotarmed${A.armedCount && A.armedCount() ? " live" : ""}">${
        A.ico("aim")}${plural(A.armedCount ? A.armedCount() : 0,
        "event is pointed at you", "events are pointed at you")}</p>
      <p class="pilotnote">${
        A.ownEventsArmed && A.ownEventsArmed()
        ? "&#9670; the ledger has you at " + plural(bends(active), "bend", "bends")
          + ", which is past the point where your own events go on sparing you. "
          + "They are in the pile with everybody else's now. The field will also "
          + "come for you sooner than it does for the others."
        : active !== A.GUEST && armable && A.armedCount && A.armedCount() === 0
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

  // Turning a page. The track is already built and already the right height,
  // so this only moves it — no rebuild, which is what lets the slide be a
  // slide rather than a flash of new markup. The arrows and the dots are
  // rewritten by hand for the same reason.
  function turn(to) {
    const root = document.getElementById("pilot");
    const track = root && root.querySelector(".pilottrack");
    if (!track) return;
    const last = track.children.length - 1;
    page = Math.max(0, Math.min(to, last));
    track.style.transform = `translateX(${-page * 100}%)`;
    // Off-page cards stop being tab stops and stop being read out. A deck that
    // kept thirty buttons in the tab order and showed four of them is a
    // keyboard trap with a picture of a room in it.
    [...track.children].forEach((pg, i) => {
      pg.toggleAttribute("inert", i !== page);
      pg.setAttribute("aria-hidden", String(i !== page));
    });
    root.querySelectorAll(".pdot").forEach((d, i) => {
      d.classList.toggle("on", i === page);
      if (i === page) d.setAttribute("aria-current", "true");
      else d.removeAttribute("aria-current");
    });
    const of = root.querySelector(".pof");
    if (of) of.innerHTML = `${page + 1}<i>/</i>${last + 1}`;
    root.querySelectorAll(".pstep").forEach((b) => {
      b.disabled = Number(b.dataset.step) < 0 ? page === 0 : page === last;
    });
  }

  function onClick(ev) {
    const step = ev.target.closest("[data-step]");
    if (step) { turn(page + Number(step.dataset.step)); return; }
    const dot = ev.target.closest("[data-page]");
    if (dot) { turn(Number(dot.dataset.page)); return; }

    const card = ev.target.closest("[data-pilot]");
    if (!card || A.pilotLocked()) return;
    A.setPilot(card.dataset.pilot);
    A.renderPilot();
  }

  // The arrow keys, while the deck has focus. A pager somebody can only click
  // is half a pager, and these are the two keys anybody already tries.
  function onKey(ev) {
    if (ev.key !== "ArrowLeft" && ev.key !== "ArrowRight") return;
    const root = document.getElementById("pilot");
    if (!root || !root.contains(document.activeElement)) return;
    turn(page + (ev.key === "ArrowRight" ? 1 : -1));
    ev.preventDefault();
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
  document.addEventListener("keydown", onKey);
})(ASTEROIDS);
