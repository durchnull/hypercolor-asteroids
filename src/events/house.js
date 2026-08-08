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
      // three arrows converging on something in the middle
      icon: `M12 2.2v5.2 M10.1 5.4L12 7.3L13.9 5.4
             M4.4 19.4L8.3 15.5 M8.3 15.5H5.6 M8.3 15.5v2.7
             M19.6 19.4L15.7 15.5 M15.7 15.5h2.7 M15.7 15.5v2.7
             M14.2 12a2.2 2.2 0 1 1-4.4 0 2.2 2.2 0 1 1 4.4 0`,
      holds: 4,
      fire() {
        this.pack = [];
        for (let i = 0; i < 3; i++) {
          A.spawnSquid();
          this.pack.push(A.squids[A.squids.length - 1]);
        }
        A.aberrate(0.8);
        A.boom(2);
      },
      // The mark stays up while its own three are still in the water — these
      // three by identity, not "are there krakens", which the wave answers.
      while() {
        return !!this.pack && this.pack.some((s) => A.squids.includes(s));
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
      // a ring of rock with one hole in it, closing on something
      icon: `M12 3l1.5 1.5-1.5 1.5-1.5-1.5z M18.5 6.7l1.5 1.5-1.5 1.5-1.5-1.5z
             M18.5 14.3l1.5 1.5-1.5 1.5-1.5-1.5z M12 18l1.5 1.5-1.5 1.5-1.5-1.5z
             M5.5 14.3l1.5 1.5-1.5 1.5-1.5-1.5z
             M13.7 12a1.7 1.7 0 1 1-3.4 0 1.7 1.7 0 1 1 3.4 0`,
      holds: 8,
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
      // two gates, and a way through them you did not ask for
      icon: `M7 4.6a7 8.5 0 0 0 0 14.8 M17 4.6a7 8.5 0 0 1 0 14.8
             M7.6 12h8.8 M14.4 9.9L16.5 12L14.4 14.1`,
      holds: 4,
      fire() {
        A.spawnPortals();
        this.gate = A.portals;
        A.spawnSquid();
        A.aberrate(1.1);
      },
      // as long as the pair it opened is the pair still standing there
      while() { return !!this.gate && A.portals === this.gate; },
    },

    {
      id: "house:shower",
      by: A.HOUSE,
      name: "METEOR SHOWER",
      blurb: "SMALL, FAST, AND ALL THE SAME WAY",
      minWave: 2,
      weight: 3,
      cooldown: 2,
      // three streaks, all the same way, each with something at the front
      icon: `M3.2 4.4L8.6 9.8 M11.1 11a1.3 1.3 0 1 1-2.6 0 1.3 1.3 0 1 1 2.6 0
             M9.4 3.2L14.8 8.6 M17.3 9.8a1.3 1.3 0 1 1-2.6 0 1.3 1.3 0 1 1 2.6 0
             M5.6 12.4L11 17.8 M13.5 19a1.3 1.3 0 1 1-2.6 0 1.3 1.3 0 1 1 2.6 0`,
      holds: 7,
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
// a deliberate trespass
