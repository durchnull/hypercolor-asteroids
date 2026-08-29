// WHAT THIS IS — the cabinet explaining itself, on the way in.
//
// Every other panel on this screen describes the game: what is out there, who
// is flying, what the keys do, what somebody scored, which versions have been
// on the machine. None of them says what the machine *is*, and the answer is
// stranger than an arcade game — the interesting half is the argument going on
// between the people who keep landing versions of it, and until now you found
// that out by reading a repository rather than by reading the cabinet. A game
// whose best joke is only legible to somebody with a git client is a game
// telling its best joke to the wrong room.
//
// So: one sentence about the rocks, and five about everything built around
// them. It sits under the chronicle because it is the same subject from the
// other end — the book is the record, and this is what the record is of.
//
// Static text, deliberately, and the only panel on the deck that is. The rest
// are instruments and they are all reading something; this is the label on the
// machine, and a label that moves is not a label.

(function (A) {
  "use strict";

  const LEAD = "A neon vector arcade game, and an argument between the people"
    + " who keep rebuilding it. Shoot the rocks — that half has not changed"
    + " since 1979. The rest is the game behind the game.";

  // A glyph each, off the same sheet the panels are signposted with — the same
  // argument src/ui/icons.js makes for the headers, one level down. Five
  // paragraphs of small grey type is a wall; five paragraphs with a mark
  // against each is a list, and the eye can pick the one it wants out of it
  // without reading the other four first.
  const NOTES = [
    ["page", "THE CABINET",
      `One page you open, and nothing else. Nothing installed, nothing served,
       nothing fetched — it runs off a stick, on a plane, in ten years. Every
       sound in it is built out of oscillators while you listen; there is not
       an audio file in the building.`],
    ["merge", "MANY HANDS",
      `Several people build this machine, one version at a time, and nobody
       announces what they did. You pull, you press ENTER, and you find out by
       playing. The chronicle above is every version there has ever been, a
       page each, written by whoever landed it.`],
    ["event", "THE EVENTS",
      `Any pilot may write one ambush and drop it into a live wave — three
       krakens from three sides, a ring of rock closing in. It fires for
       everybody except the pilot who wrote it, which is the entire reason to
       write a good one.`],
    ["bend", "THE RULES",
      `Fifteen, and a referee that reads every change. Most cannot be crossed
       at all; four can be bent, in writing, in the open, and one of the four
       asks when you last played the thing you are building. The field reads
       the number afterwards: bend enough and the ambushes come sooner, and at
       the far end your own stop sparing you. The newest one cannot be broken
       by anybody &mdash; it only counts how long it has been since somebody
       else had a turn at this keyboard.`],
    ["cup", "THE RECORD",
      `A score reaches the board one way. You die, the game seals the whole
       flight into a tape, and somebody checks the seal before it lands. There
       is no other door onto that table, and typing a number is not one.`],
  ];

  A.renderAbout = function renderAbout() {
    const root = document.getElementById("about");
    if (!root) return;

    root.innerHTML = `
      <h2>${A.ico("cabinet")}WHAT THIS IS</h2>
      <p class="alead">${LEAD}</p>
      <ul>${NOTES.map(([icon, name, body]) => `
        <li>
          <div class="aname">${A.ico(icon)}${name}</div>
          <div class="abody">${body.replace(/\s+/g, " ").trim()}</div>
        </li>`).join("")}
      </ul>`;
  };

  A.register({
    id: "ui:about",
    reset(mode) {
      if (mode === "attract") A.renderAbout();
    },
  });
})(ASTEROIDS);
