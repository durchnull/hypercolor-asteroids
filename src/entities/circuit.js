// A live circuit: connect-all across three asteroids, whatever size they
// happen to be. Touch a wire and you are gone. Shoot down any one corner and
// the whole loop drops dead with it; leave it alone and it burns out on its
// own after twenty seconds. Any event may call A.layCordon() to lay one —
// this file only owns the wire itself, not who throws the switch.

(function (A) {
  "use strict";

  const LIFETIME = 20;   // seconds before it burns out unfired-at

  A.cordon = null;

  // A ship's own frame-to-frame travel is the segment that has to miss all
  // three wires — checking only where it landed would let a fast ship jump
  // a wire between two frames without ever having touched it.
  const prevPos = new Map();

  /** Wire three live asteroids together at random. False if the field is too thin. */
  A.layCordon = function layCordon() {
    if (A.asteroids.length < 3) return false;
    const pool = A.asteroids.slice();
    const nodes = [];
    for (let i = 0; i < 3; i++) {
      const idx = Math.floor(Math.random() * pool.length);
      nodes.push(pool.splice(idx, 1)[0]);
    }
    A.cordon = { nodes, timer: LIFETIME };
    return true;
  };

  function reset() {
    A.cordon = null;
    prevPos.clear();
  }

  // does segment (ax,ay)-(bx,by) cross segment (cx,cy)-(dx,dy)?
  function side(ax, ay, bx, by, px, py) {
    return (bx - ax) * (py - ay) - (by - ay) * (px - ax);
  }
  function segmentsCross(ax, ay, bx, by, cx, cy, dx, dy) {
    const d1 = side(cx, cy, dx, dy, ax, ay);
    const d2 = side(cx, cy, dx, dy, bx, by);
    const d3 = side(ax, ay, bx, by, cx, cy);
    const d4 = side(ax, ay, bx, by, dx, dy);
    return ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
           ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0));
  }

  function update(tick) {
    const c = A.cordon;
    if (!tick.running || !c) { prevPos.clear(); return; }

    // one corner gone and the whole net was one circuit — it dies with it
    if (!c.nodes.every((n) => A.asteroids.includes(n))) { A.cordon = null; return; }

    c.timer -= tick.dt;
    if (c.timer <= 0) A.cordon = null;
  }

  function resolve() {
    const c = A.cordon;
    for (const p of A.flyingShips()) {
      const prev = prevPos.get(p) || { x: p.x, y: p.y };
      if (c && p.invuln <= 0) {
        for (let i = 0; i < 3; i++) {
          const n1 = c.nodes[i], n2 = c.nodes[(i + 1) % 3];
          if (segmentsCross(prev.x, prev.y, p.x, p.y, n1.x, n1.y, n2.x, n2.y)) {
            A.killShip(p);
            break;
          }
        }
      }
      prevPos.set(p, { x: p.x, y: p.y });
    }
  }

  // A stable hot amber, cancelling the drift the way the nuke's fireball
  // does — a live wire reads as danger precisely because it does not join
  // the fleet's mood swings.
  function flicker() {
    return 58 + Math.sin(performance.now() * 0.03) * 16 + Math.random() * 8;
  }

  function draw(tick, g) {
    const c = A.cordon;
    if (!c || A.gl.on) return;
    g.save();
    A.glow(A.neon(28 - A.hue, flicker(), 0.95));
    g.lineWidth = 2;
    g.beginPath();
    for (let i = 0; i < 3; i++) {
      const n1 = c.nodes[i], n2 = c.nodes[(i + 1) % 3];
      g.moveTo(n1.x, n1.y);
      g.lineTo(n2.x, n2.y);
    }
    g.stroke();
    g.restore();
  }

  function draw3d(tick, s) {
    const c = A.cordon;
    if (!c) return;
    const light = flicker();
    for (let i = 0; i < 3; i++) {
      const n1 = c.nodes[i], n2 = c.nodes[(i + 1) % 3];
      s.line(n1.x, n1.y, 6, n2.x, n2.y, 6, { hue: 28 - A.hue, light, alpha: 1, width: 2.2 });
    }
  }

  A.register({
    id: "circuit",
    order: { update: 46, resolve: 25, draw: 46, guide: 46 },
    reset, update, resolve, draw, draw3d,
    guide: {
      name: "CIRCUIT",
      group: "field",
      meta: "connect three &middot; stay off the wire",
      tint: "var(--amber)",
      icon: `<svg width="34" height="34" viewBox="0 0 34 34" fill="none" stroke="currentColor" stroke-width="1.3" aria-hidden="true">
        <path d="M17 6.5L27 25.5H7Z"/>
        <circle cx="17" cy="6.5" r="2.1"/>
        <circle cx="27" cy="25.5" r="2.1"/>
        <circle cx="7" cy="25.5" r="2.1"/>
      </svg>`,
      desc: "Three rocks wire themselves together. Touch a wire and you are gone. Shoot any one corner to kill the loop, or wait twenty seconds.",
    },
  });
})(ASTEROIDS);
