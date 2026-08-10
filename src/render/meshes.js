// Geometry. Every solid in the field is built here, out of arithmetic, at load
// time — there are no model files to fetch and nothing to install (GR2), and a
// shape somebody wants to argue with is a function they can read.
//
// A mesh is low-poly on purpose and in two halves, because that is what the
// cabinet has always looked like: dark faceted faces that occlude what is
// behind them, and a bright edge cage over the top that the bloom turns into
// neon. Take the faces away and you have the old vector game; take the edges
// away and you have a black hole. Both together is the whole trick.
//
//   { tri, nrm, edge, tris, edges }
//
// `tri` and `nrm` are flat-shaded triangle soup — one normal per face, repeated
// per corner, which is what gives a twenty-sided rock twenty readable facets
// instead of a smooth ball. `edge` is the unique edge list as pairs of points;
// src/render/gl.js turns each pair into a screen-space quad, because WebGL's
// own line width is one pixel almost everywhere and one pixel is not a look.

(function (A) {
  "use strict";

  const M = A.mesh = {};

  const cache = new Map();

  /** Build once, keyed by name. Meshes are immutable and shared by every instance. */
  M.get = function get(key, build) {
    let m = cache.get(key);
    if (!m) { m = build(); cache.set(key, m); }
    return m;
  };

  /**
   * The one constructor everything else goes through: a vertex list and a face
   * list in, flat-shaded triangles and a deduplicated edge cage out. Faces may
   * have any number of corners — they are fanned — so a lathe can hand over
   * quads and a cone can hand over triangles without either one caring.
   */
  M.build = function build(verts, faces) {
    const tri = [];
    const nrm = [];
    const seen = new Set();
    const edge = [];

    for (const f of faces) {
      const a = verts[f[0]];
      // Newell's normal, so a slightly non-planar quad still points somewhere
      // sensible rather than folding along whichever diagonal we happened to
      // fan from.
      let nx = 0, ny = 0, nz = 0;
      for (let i = 0; i < f.length; i++) {
        const p = verts[f[i]], q = verts[f[(i + 1) % f.length]];
        nx += (p[1] - q[1]) * (p[2] + q[2]);
        ny += (p[2] - q[2]) * (p[0] + q[0]);
        nz += (p[0] - q[0]) * (p[1] + q[1]);
      }
      const len = Math.hypot(nx, ny, nz) || 1;
      nx /= len; ny /= len; nz /= len;

      for (let i = 1; i < f.length - 1; i++) {
        const b = verts[f[i]], c = verts[f[i + 1]];
        tri.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]);
        for (let k = 0; k < 3; k++) nrm.push(nx, ny, nz);
      }

      for (let i = 0; i < f.length; i++) {
        const u = f[i], v = f[(i + 1) % f.length];
        const key = u < v ? u + ":" + v : v + ":" + u;
        if (seen.has(key)) continue;      // every interior edge is shared twice
        seen.add(key);
        const p = verts[u], q = verts[v];
        edge.push(p[0], p[1], p[2], q[0], q[1], q[2]);
      }
    }

    return {
      tri: new Float32Array(tri),
      nrm: new Float32Array(nrm),
      edge: new Float32Array(edge),
      tris: tri.length / 9,
      edges: edge.length / 6,
    };
  };

  /** A cage with no faces at all — rings, spokes, anything that is only line. */
  M.wire = function wire(segments) {
    const edge = [];
    for (const s of segments) edge.push(s[0], s[1], s[2], s[3], s[4], s[5]);
    return {
      tri: new Float32Array(0),
      nrm: new Float32Array(0),
      edge: new Float32Array(edge),
      tris: 0,
      edges: edge.length / 6,
    };
  };

  // ---------------------------------------------------------------------------
  // the shapes
  // ---------------------------------------------------------------------------

  const PHI = (1 + Math.sqrt(5)) / 2;

  /**
   * An icosahedron, optionally subdivided, at radius 1. `n` of 0 is twenty
   * faces and reads as a rock; 1 is eighty and reads as a moon. Nothing here
   * ever wants more than that.
   */
  M.ico = function ico(n) {
    let verts = [
      [-1, PHI, 0], [1, PHI, 0], [-1, -PHI, 0], [1, -PHI, 0],
      [0, -1, PHI], [0, 1, PHI], [0, -1, -PHI], [0, 1, -PHI],
      [PHI, 0, -1], [PHI, 0, 1], [-PHI, 0, -1], [-PHI, 0, 1],
    ].map(norm);
    let faces = [
      [0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
      [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
      [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
      [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1],
    ];

    for (let pass = 0; pass < (n || 0); pass++) {
      const mid = new Map();
      const next = [];
      const cut = (u, v) => {
        const key = u < v ? u + ":" + v : v + ":" + u;
        let i = mid.get(key);
        if (i === undefined) {
          i = verts.length;
          verts.push(norm([
            (verts[u][0] + verts[v][0]) / 2,
            (verts[u][1] + verts[v][1]) / 2,
            (verts[u][2] + verts[v][2]) / 2,
          ]));
          mid.set(key, i);
        }
        return i;
      };
      for (const [a, b, c] of faces) {
        const ab = cut(a, b), bc = cut(b, c), ca = cut(c, a);
        next.push([a, ab, ca], [b, bc, ab], [c, ca, bc], [ab, bc, ca]);
      }
      faces = next;
    }
    return { verts, faces };
  };

  function norm(p) {
    const d = Math.hypot(p[0], p[1], p[2]) || 1;
    return [p[0] / d, p[1] / d, p[2] / d];
  }

  /**
   * A rock. Radius-1 icosahedron with every vertex shoved in or out by a seeded
   * amount, which is the 3D reading of the same nine-to-twelve wobbly radii the
   * flat rocks have always been drawn from.
   */
  M.rock = function rock(seed, n) {
    const { verts, faces } = M.ico(n === undefined ? 0 : n);
    let s = seed * 9301 + 49297;
    const rnd = () => {
      s = (s * 9301 + 49297) % 233280;
      return s / 233280;
    };
    const out = verts.map((v) => {
      const k = 0.74 + rnd() * 0.46;
      return [v[0] * k, v[1] * k, v[2] * k];
    });
    return M.build(out, faces);
  };

  /** A sphere by way of the icosahedron — planets and kraken domes. */
  M.ball = function ball(n) {
    const { verts, faces } = M.ico(n);
    return M.build(verts, faces);
  };

  /** A prism: one outline, two heights, walls between them. */
  M.prism = function prism(outline, z0, z1) {
    const verts = [];
    const n = outline.length;
    for (const p of outline) verts.push([p[0], p[1], z0]);
    for (const p of outline) verts.push([p[0], p[1], z1]);
    const faces = [];
    const bottom = [], top = [];
    for (let i = 0; i < n; i++) { bottom.push(n - 1 - i); top.push(n + i); }
    faces.push(bottom, top);
    for (let i = 0; i < n; i++) {
      const j = (i + 1) % n;
      faces.push([i, j, n + j, n + i]);
    }
    return M.build(verts, faces);
  };

  /** A box, centred, given half-extents. */
  M.box = function box(hx, hy, hz) {
    return M.prism([[-hx, -hy], [hx, -hy], [hx, hy], [-hx, hy]], -hz, hz);
  };

  /**
   * Revolve a profile — pairs of [radius, z], bottom to top — around the z
   * axis. Radius 0 at either end closes into a point, which is what turns the
   * same function into a cone, a barrel, a dome and a tentacle segment.
   */
  M.lathe = function lathe(profile, seg) {
    const verts = [];
    const faces = [];
    const rings = [];
    for (const [r, z] of profile) {
      if (r <= 0.0001) {
        rings.push([verts.length]);
        verts.push([0, 0, z]);
        continue;
      }
      const ring = [];
      for (let i = 0; i < seg; i++) {
        const a = (i / seg) * A.TAU;
        ring.push(verts.length);
        verts.push([Math.cos(a) * r, Math.sin(a) * r, z]);
      }
      rings.push(ring);
    }
    for (let k = 0; k < rings.length - 1; k++) {
      const lo = rings[k], hi = rings[k + 1];
      if (lo.length === 1) {
        for (let i = 0; i < hi.length; i++) faces.push([lo[0], hi[(i + 1) % hi.length], hi[i]]);
      } else if (hi.length === 1) {
        for (let i = 0; i < lo.length; i++) faces.push([lo[i], lo[(i + 1) % lo.length], hi[0]]);
      } else {
        for (let i = 0; i < lo.length; i++) {
          const j = (i + 1) % lo.length;
          faces.push([lo[i], lo[j], hi[j], hi[i]]);
        }
      }
    }
    // cap an open bottom and top so nothing is ever see-through from behind
    if (rings[0].length > 1) faces.push(rings[0].slice().reverse());
    if (rings[rings.length - 1].length > 1) faces.push(rings[rings.length - 1].slice());
    return M.build(verts, faces);
  };

  /** A flat annulus lying in the plane — floor rings, blast fronts, reach marks. */
  M.annulus = function annulus(inner, seg) {
    const verts = [];
    const faces = [];
    for (let i = 0; i < seg; i++) {
      const a = (i / seg) * A.TAU;
      verts.push([Math.cos(a) * inner, Math.sin(a) * inner, 0]);
      verts.push([Math.cos(a), Math.sin(a), 0]);
    }
    for (let i = 0; i < seg; i++) {
      const j = (i + 1) % seg;
      faces.push([i * 2, j * 2, j * 2 + 1, i * 2 + 1]);
    }
    return M.build(verts, faces);
  };

  /** A ring of line and nothing else, radius 1 in the plane. */
  M.hoop = function hoop(seg) {
    const segs = [];
    for (let i = 0; i < seg; i++) {
      const a = (i / seg) * A.TAU, b = ((i + 1) / seg) * A.TAU;
      segs.push([Math.cos(a), Math.sin(a), 0, Math.cos(b), Math.sin(b), 0]);
    }
    return M.wire(segs);
  };

  /** A doughnut, major radius 1. Portals and mine collars. */
  M.torus = function torus(minor, major, sides) {
    const verts = [];
    const faces = [];
    for (let i = 0; i < major; i++) {
      const a = (i / major) * A.TAU;
      for (let j = 0; j < sides; j++) {
        const b = (j / sides) * A.TAU;
        const r = 1 + Math.cos(b) * minor;
        verts.push([Math.cos(a) * r, Math.sin(a) * r, Math.sin(b) * minor]);
      }
    }
    for (let i = 0; i < major; i++) {
      const i2 = (i + 1) % major;
      for (let j = 0; j < sides; j++) {
        const j2 = (j + 1) % sides;
        faces.push([i * sides + j, i2 * sides + j, i2 * sides + j2, i * sides + j2]);
      }
    }
    return M.build(verts, faces);
  };

  // No guide tile: geometry briefs nobody. What it builds shows up in the
  // field wearing its own name, and those tiles were already written.
  A.register({ id: "meshes" });
})(ASTEROIDS);
