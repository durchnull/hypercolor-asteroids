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
      // two walls and the direction they are going
      icon: `M3.6 3.4v17.2 M20.4 3.4v17.2
             M6.6 12h4 M8.7 10.2L10.5 12L8.7 13.8
             M17.4 12h-4 M15.3 10.2L13.5 12L15.3 13.8`,
      holds: 9,
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
      // one ship, and a bigger one on the same heading behind it
      icon: `M15.6 3.4l2.9 6.3-2.9-1.6-2.9 1.6z
             M9 11.4l4.3 9.6-4.3-2.4-4.3 2.4z`,
      holds: 4,
      // The smuggler run, except this time it is being chased, and whatever is
      // chasing it arrives on the same heading a second and a half later.
      fire() {
        A.spawnFalcon();
        this.smuggler = A.falcon;
        setTimeout(() => {
          if (!A.isRunning()) return;
          A.spawnSquid();
          this.tail = A.squids[A.squids.length - 1];
          A.boom(2);
        }, 1500);
      },
      // The mark stays up while either of them is still out there — the run is
      // not over until the thing that followed it in is dealt with.
      while() {
        return (!!this.smuggler && A.falcon === this.smuggler) ||
          (!!this.tail && A.squids.includes(this.tail));
      },
    },
  ]);
})(ASTEROIDS);
