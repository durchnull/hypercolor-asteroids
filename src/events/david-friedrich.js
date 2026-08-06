// David Friedrich's events.
//
// Signed with a name, not with A.HOUSE, which means they fire for every pilot
// except the one who wrote them. If you are reading this because you want your
// own: copy the file, call it your git name, sign the events with your git
// name, add one line to src/features.js, and that is the whole ceremony.
//
// Nobody else may touch this file — GR11 — and this file may not touch anybody
// else's. That is the deal that makes it worth laying a good one.

(function (A) {
  "use strict";

  A.defineEvent([
    {
      id: "df:vice",
      by: "David Friedrich",
      name: "THE VICE",
      blurb: "TWO WALLS, AND THEY ARE NOT STOPPING",
      minWave: 3,
      weight: 2,
      cooldown: 3,
      // Rock down both sides at once, leaving a corridor up the middle. It is
      // survivable the whole time. It just stops looking that way.
      fire() {
        const rows = 5;
        for (let i = 0; i < rows; i++) {
          const y = ((i + 0.5) / rows) * A.H + A.rand(-30, 30);
          for (const side of [-1, 1]) {
            const rock = A.makeAsteroid(side < 0 ? -60 : A.W + 60, y, 2);
            const speed = Math.hypot(rock.vx, rock.vy) * 0.8;
            rock.vx = -side * speed;
            rock.vy = A.rand(-18, 18);
            A.asteroids.push(rock);
          }
        }
        A.aberrate(0.9);
        A.shakeBy(12);
      },
    },

    {
      id: "df:bad-company",
      by: "David Friedrich",
      name: "BAD COMPANY",
      blurb: "THE FALCON BROUGHT SOMETHING WITH IT",
      minWave: 5,
      weight: 1,
      cooldown: 4,
      // The smuggler run, except this time it is being chased, and whatever is
      // chasing it arrives on the same heading a second and a half later.
      fire() {
        A.spawnFalcon();
        setTimeout(() => {
          if (!A.isRunning()) return;
          A.spawnSquid();
          A.boom(2);
        }, 1500);
      },
    },
  ]);
})(ASTEROIDS);
