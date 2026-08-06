// The house events.
//
// These belong to nobody — `by: A.HOUSE` — so unlike a pilot's own, they fire
// for everybody, author included. The house has no favourites and does not
// care whose profile is selected.
//
// They are also the worked examples. Copy the shape, put it in a file with
// your own name on it under src/events/, sign it with your git name instead of
// A.HOUSE, and it will fire for everyone but you. See game/events.js.

(function (A) {
  "use strict";

  /** Somewhere on the edge of the screen, roughly `d` away from a point. */
  function ringPoint(cx, cy, angle, d) {
    return { x: cx + Math.cos(angle) * d, y: cy + Math.sin(angle) * d };
  }

  A.defineEvent([
    {
      id: "house:pincer",
      by: A.HOUSE,
      name: "PINCER",
      blurb: "THREE AT ONCE, THREE DIRECTIONS",
      minWave: 4,
      weight: 2,
      cooldown: 3,
      fire() {
        for (let i = 0; i < 3; i++) A.spawnSquid();
        A.aberrate(0.8);
        A.boom(2);
      },
    },

    {
      id: "house:debris",
      by: A.HOUSE,
      name: "DEBRIS FIELD",
      blurb: "IT IS CLOSING",
      minWave: 2,
      weight: 3,
      cooldown: 2,
      // A ring of rock around whoever is furthest from help, all of it aimed
      // inward. There is a gap; there is always a gap. Finding it is the game.
      fire() {
        const ships = A.flyingShips();
        const target = ships[Math.floor(A.rand(0, ships.length))];
        if (!target) return;

        const count = 7;
        const gapAt = Math.floor(A.rand(0, count));
        const dist = Math.min(A.W, A.H) * 0.45 + 120;

        for (let i = 0; i < count; i++) {
          if (i === gapAt) continue;
          const angle = (i / count) * A.TAU + A.rand(-0.12, 0.12);
          const at = ringPoint(target.x, target.y, angle, dist);
          const rock = A.makeAsteroid(at.x, at.y, 2);
          const speed = Math.hypot(rock.vx, rock.vy) * 0.85;
          rock.vx = -Math.cos(angle) * speed;
          rock.vy = -Math.sin(angle) * speed;
          A.asteroids.push(rock);
          A.shockwave(at.x, at.y, A.hue + 30, 70, 240);
        }
        A.shakeBy(14);
      },
    },

    {
      id: "house:switch",
      by: A.HOUSE,
      name: "THE SWITCH",
      blurb: "SOMETHING CAME THROUGH WITH YOU",
      minWave: 3,
      weight: 2,
      cooldown: 3,
      fire() {
        A.spawnPortals();
        A.spawnSquid();
        A.aberrate(1.1);
      },
    },

    {
      id: "house:shower",
      by: A.HOUSE,
      name: "METEOR SHOWER",
      blurb: "SMALL, FAST, AND ALL THE SAME WAY",
      minWave: 2,
      weight: 3,
      cooldown: 2,
      // Everything on one heading, so it is survivable if you read it early
      // and lethal if you keep flying the way you were.
      fire() {
        const from = Math.floor(A.rand(0, 4));      // which edge it comes off
        const heading = (from * Math.PI) / 2 + Math.PI / 2 + A.rand(-0.25, 0.25);

        for (let i = 0; i < 12; i++) {
          const along = A.rand(-0.2, 1.2);
          const back = A.rand(40, 420);
          const x = from % 2 === 0 ? along * A.W : (from === 1 ? A.W + back : -back);
          const y = from % 2 === 0 ? (from === 0 ? -back : A.H + back) : along * A.H;

          const rock = A.makeAsteroid(x, y, 1);
          const speed = Math.hypot(rock.vx, rock.vy) * 1.7;
          rock.vx = Math.cos(heading) * speed;
          rock.vy = Math.sin(heading) * speed;
          A.asteroids.push(rock);
        }
        A.slowmo(0.55);
        A.blip(90, 0.7, "triangle", 0.12);
      },
    },
  ]);
})(ASTEROIDS);
