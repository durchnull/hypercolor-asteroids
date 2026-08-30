// The third dimension.
//
// The field is still a plane and the controls still live on it — every feature
// keeps thinking in the same x and y it always has, wrapping at the same edges,
// colliding at the same radii. What changed is what sits on that plane: solids
// with height, lit and occluding each other, under a camera looking straight
// down at them.
//
// Straight down is the whole reason this was safe to do at all. A plane square
// to the view axis maps to the screen affinely, so the camera is set up such
// that world (x, y, 0) lands on screen pixel (x, y) exactly — the same pixel it
// landed on when this was a flat game. The HUD still lines up, the touch
// buttons still line up, the hitboxes are still the shapes you see, and nobody
// had to move a number in a rule file. Height is the only thing that is new,
// and height is what does the leaning, the parallax and the occlusion.
//
// Objects therefore straddle the plane rather than standing on it: a rock's
// equator is at z = 0, which is exactly the circle its hitbox has always been.
// GR8 asks that you can see the thing that is about to kill you, and the
// honest way to keep that promise under perspective is to put the silhouette
// the collision uses where the eye is already looking.
//
// The output is a texture, not a screen. It is drawn onto the same entity
// layer the flat game drew onto, so the phosphor trails, the bloom, the shake,
// the RGB smear, the CRT glass and the whole chrome pass keep working without
// knowing anything happened. Dark faces are the point rather than a
// compromise: the layer composites additively over the sky, so a dim facet is
// invisible against the nebula and still hides the neon behind it.
//
// If WebGL2 is not there, `A.gl.on` stays false, no scene is ever built, and
// every feature's flat draw hook runs exactly as before. GR1 is a promise to
// somebody whose machine you have never seen.

(function (A) {
  "use strict";

  // How far the eye sits above the plane, as a share of the longer screen
  // edge. Lower is a wider lens and a harder lean at the corners; higher
  // flattens back toward the old game. This is the one number that decides how
  // three-dimensional the cabinet feels, so it is up here on its own.
  const DEPTH = 0.55;

  const STRIDE = 22;                   // floats per instance: mat4, rgba, width, dim
  const LIGHT = [0.36, -0.48, 0.80];   // key light, over your shoulder and to the left

  const gl3 = {
    on: false,
    canvas: null,
    eye: 0,        // camera height over the plane, in screen pixels
  };
  A.gl = gl3;

  let gl = null;
  let solidProg = null;
  let edgeProg = null;
  let unitLine = null;
  const gpu = new Map();                    // mesh -> its uploaded buffers
  const queues = [new Map(), new Map()];    // 0 covers, 1 adds
  const vp = new Float32Array(16);

  // ---------------------------------------------------------------------------
  // the shaders
  // ---------------------------------------------------------------------------

  const INSTANCE = `#version 300 es
    precision highp float;
    layout(location=0) in vec4 iM0;
    layout(location=1) in vec4 iM1;
    layout(location=2) in vec4 iM2;
    layout(location=3) in vec4 iM3;
    layout(location=4) in vec4 iCol;
    layout(location=5) in vec2 iParam;
    uniform mat4 uVP;
  `;

  const SOLID_VS = INSTANCE + `
    layout(location=6) in vec3 aPos;
    layout(location=7) in vec3 aNrm;
    out vec4 vCol;
    out vec3 vNrm;
    out float vDim;
    void main() {
      mat4 m = mat4(iM0, iM1, iM2, iM3);
      gl_Position = uVP * m * vec4(aPos, 1.0);
      // the scales here are mild and near-uniform, so the model matrix is a
      // good enough normal matrix; an inverse-transpose would cost more than
      // these facets are worth
      vNrm = normalize((m * vec4(aNrm, 0.0)).xyz);
      vCol = iCol;
      vDim = iParam.y;
    }`;

  const SOLID_FS = `#version 300 es
    precision highp float;
    in vec4 vCol;
    in vec3 vNrm;
    in float vDim;
    uniform vec3 uLight;
    out vec4 outColor;
    void main() {
      float d = max(dot(normalize(vNrm), uLight), 0.0);
      // deliberately dark: a body here is an occluder that catches a little
      // light, not paint. The cage over it is what you actually see.
      float k = vDim * (0.28 + 0.72 * d * d);
      outColor = vec4(vCol.rgb * k * vCol.a, vCol.a);
    }`;

  // Edges become screen-space quads because WebGL's own line width is one
  // pixel nearly everywhere, and one pixel is not this game's look. Each edge
  // arrives as four corners carrying both of its endpoints; the width goes on
  // after the divide, so a line is the same thickness however far off it is.
  const EDGE_VS = INSTANCE + `
    layout(location=6) in vec3 aA;
    layout(location=7) in vec3 aB;
    layout(location=8) in vec2 aSide;
    uniform vec2 uHalf;
    uniform float uBias;
    out vec4 vCol;
    void main() {
      mat4 m = mat4(iM0, iM1, iM2, iM3);
      vec4 ca = uVP * m * vec4(aA, 1.0);
      vec4 cb = uVP * m * vec4(aB, 1.0);
      vec2 sa = ca.xy / max(abs(ca.w), 0.0001) * uHalf;
      vec2 sb = cb.xy / max(abs(cb.w), 0.0001) * uHalf;
      vec2 dir = sb - sa;
      float len = length(dir);
      dir = len > 0.0001 ? dir / len : vec2(1.0, 0.0);
      vec2 side = vec2(-dir.y, dir.x);
      vec4 c = mix(ca, cb, aSide.y);
      c.xy += side * aSide.x * iParam.x * 0.5 / uHalf * abs(c.w);
      // pull the cage a hair toward the eye so it never fights its own faces
      c.z -= uBias * c.w;
      gl_Position = c;
      vCol = iCol;
    }`;

  const EDGE_FS = `#version 300 es
    precision highp float;
    in vec4 vCol;
    out vec4 outColor;
    void main() { outColor = vec4(vCol.rgb * vCol.a, vCol.a); }`;

  // ---------------------------------------------------------------------------
  // bringing it up
  // ---------------------------------------------------------------------------

  function compile(vsrc, fsrc) {
    const p = gl.createProgram();
    for (const [type, src] of [[gl.VERTEX_SHADER, vsrc], [gl.FRAGMENT_SHADER, fsrc]]) {
      const s = gl.createShader(type);
      gl.shaderSource(s, src.trim());
      gl.compileShader(s);
      if (!gl.getShaderParameter(s, gl.COMPILE_STATUS)) {
        throw new Error(gl.getShaderInfoLog(s) || "shader");
      }
      gl.attachShader(p, s);
    }
    gl.linkProgram(p);
    if (!gl.getProgramParameter(p, gl.LINK_STATUS)) {
      throw new Error(gl.getProgramInfoLog(p) || "link");
    }
    return {
      p,
      vp: gl.getUniformLocation(p, "uVP"),
      light: gl.getUniformLocation(p, "uLight"),
      half: gl.getUniformLocation(p, "uHalf"),
      bias: gl.getUniformLocation(p, "uBias"),
    };
  }

  try {
    const c = document.createElement("canvas");
    gl = c.getContext("webgl2", {
      alpha: true,
      antialias: true,
      depth: true,
      premultipliedAlpha: true,
      powerPreference: "high-performance",
    });
    if (gl) {
      solidProg = compile(SOLID_VS, SOLID_FS);
      edgeProg = compile(EDGE_VS, EDGE_FS);
      gl3.canvas = c;
      gl3.on = true;
    }
  } catch (e) {
    // A machine without WebGL2 gets the flat cabinet, which is still the whole
    // game. Nothing below here runs, and no feature has to know.
    gl = null;
    gl3.on = false;
  }

  // Where the eye sits is the cabinet's geometry rather than this renderer's,
  // so it is kept up to date whether or not a scene is ever built. A machine
  // with no WebGL2 still has things that leave the plane — a wave arriving out
  // of depth (src/entities/asteroids.js) — and the flat path fakes this exact
  // camera to draw them. One answer, asked by both.
  function eyeUp() { gl3.eye = Math.max(A.W, A.H) * DEPTH; }
  A.onResize(eyeUp);

  if (gl3.on) {
    unitLine = A.mesh.get("gl:segment", () => A.mesh.wire([[0, 0, 0, 1, 0, 0]]));
    A.onResize(sizeUp);
  }

  function sizeUp() {
    const c = gl3.canvas;
    c.width = Math.max(1, Math.round(A.W * A.DPR));
    c.height = Math.max(1, Math.round(A.H * A.DPR));
  }

  /**
   * View and projection in one matrix, rebuilt every frame because the eye
   * height follows the screen.
   *
   * The view part shifts the eye to the middle of the screen, flips y for a
   * canvas that counts downward, and pushes the plane out in front of the lens:
   * xv = x - W/2, yv = -(y - H/2), zv = z - D. The projection is then the
   * ordinary right-handed one with the field of view solved rather than
   * chosen — f = 2D/H — which is what makes the plane at z = 0 land on the
   * viewport exactly: ndc.x = 2(x - W/2)/W, ndc.y = 1 - 2y/H.
   */
  function camera() {
    const D = gl3.eye;
    const f = (2 * D) / A.H;
    const aspect = A.W / A.H;
    // Generous at both ends. The blast front is most of the screen across and
    // the kraken dives a long way under it, and a body clipped by the lens on
    // the frame it matters is worse than a little lost depth precision.
    const near = Math.max(1, D * 0.15);
    const far = D + 1400;
    const zc = (far + near) / (near - far);
    const zd = (2 * far * near) / (near - far);

    vp.fill(0);
    vp[0] = f / aspect;
    vp[5] = -f;                       // the y flip
    vp[10] = zc;
    vp[11] = -1;
    vp[12] = -(f / aspect) * (A.W / 2);
    vp[13] = f * (A.H / 2);
    vp[14] = zd - zc * D;             // fold the eye's own height into the row
    vp[15] = D;
  }

  // ---------------------------------------------------------------------------
  // queueing
  // ---------------------------------------------------------------------------

  function batchFor(mesh, additive) {
    const q = queues[additive ? 1 : 0];
    let b = q.get(mesh);
    if (!b) {
      b = { mesh, data: new Float32Array(STRIDE * 64), n: 0 };
      q.set(mesh, b);
    }
    if ((b.n + 1) * STRIDE > b.data.length) {
      const bigger = new Float32Array(b.data.length * 2);
      bigger.set(b.data);
      b.data = bigger;
    }
    return b;
  }

  // The same colour A.neon names in CSS, saturation and all. Saturation is not
  // decoration here: the salvage hull is drawn at twenty percent of it because
  // being the one thing out here that is not lit up is how the field says
  // nobody is flying this, and a renderer that could only dim would have had
  // to say it some other way.
  function rgb(out, at, h, l, sat) {
    h = (((h % 360) + 360) % 360) / 60;
    l = l / 100;
    const c = (1 - Math.abs(2 * l - 1)) * (sat === undefined ? 1 : sat / 100);
    const x = c * (1 - Math.abs((h % 2) - 1));
    const m = l - c / 2;
    let r = 0, g = 0, b = 0;
    if (h < 1) { r = c; g = x; }
    else if (h < 2) { r = x; g = c; }
    else if (h < 3) { g = c; b = x; }
    else if (h < 4) { g = x; b = c; }
    else if (h < 5) { r = x; b = c; }
    else { r = c; b = x; }
    out[at] = r + m;
    out[at + 1] = g + m;
    out[at + 2] = b + m;
  }

  /**
   * Put one solid in the field this frame.
   *
   * `o` is read and never kept, so hoist one object per feature and rewrite it
   * — several hundred of these go by in a busy frame and none of them should
   * cost the collector anything.
   *
   *   x, y      where it already lives, in the same pixels as ever
   *   z         height over the plane; 0 is the plane, positive is toward you
   *   rz        the spin you would have handed to ctx.rotate
   *   rx, ry    tumble, which a flat shape never had
   *   s         size, or sx / sy / sz for something that is not a ball
   *   hue       an offset from A.hue, exactly as A.neon takes it
   *   light     lightness 0-100, as A.neon's second argument
   *   sat       saturation 0-100, as A.neon's fourth. 100 unless you say otherwise
   *   alpha     1 by default
   *   width     edge thickness in pixels, 1.6 by default
   *   dim       how much light the body keeps, 0.16 by default
   *   glow      true to add rather than cover: fire, portals, shockwaves
   *
   * A mesh with no faces in it draws no body — that is what src/render/meshes.js
   * builds `wire` and `hoop` for — so there is no flag for turning them off.
   */
  gl3.model = function model(mesh, o) {
    if (!gl3.on || !mesh) return;
    const b = batchFor(mesh, !!o.glow);
    const d = b.data;
    const i = b.n * STRIDE;

    const rx = o.rx || 0, ry = o.ry || 0, rz = o.rz || 0;
    const cx = Math.cos(rx), sx = Math.sin(rx);
    const cy = Math.cos(ry), sy = Math.sin(ry);
    const cz = Math.cos(rz), sz = Math.sin(rz);
    const u = o.s === undefined ? 1 : o.s;
    const kx = o.sx === undefined ? u : o.sx;
    const ky = o.sy === undefined ? u : o.sy;
    const kz = o.sz === undefined ? u : o.sz;

    // R = Rz Ry Rx, scaled, laid out in the columns the shader reads
    d[i] = cz * cy * kx;
    d[i + 1] = sz * cy * kx;
    d[i + 2] = -sy * kx;
    d[i + 3] = 0;
    d[i + 4] = (cz * sy * sx - sz * cx) * ky;
    d[i + 5] = (sz * sy * sx + cz * cx) * ky;
    d[i + 6] = cy * sx * ky;
    d[i + 7] = 0;
    d[i + 8] = (cz * sy * cx + sz * sx) * kz;
    d[i + 9] = (sz * sy * cx - cz * sx) * kz;
    d[i + 10] = cy * cx * kz;
    d[i + 11] = 0;
    d[i + 12] = o.x;
    d[i + 13] = o.y;
    d[i + 14] = o.z || 0;
    d[i + 15] = 1;

    rgb(d, i + 16, A.hue + (o.hue || 0), o.light === undefined ? 62 : o.light, o.sat);
    d[i + 19] = o.alpha === undefined ? 1 : o.alpha;
    d[i + 20] = o.width === undefined ? 1.6 : o.width;
    d[i + 21] = o.dim === undefined ? 0.16 : o.dim;
    b.n++;
  };

  /**
   * One neon segment between two points in the world. The grapple line, a
   * tentacle, a shard of debris, the smuggler's laser: everything the flat game
   * drew with moveTo and lineTo has this instead, and it costs no more than any
   * other instance, because a segment is a mesh with one edge in it.
   */
  gl3.line = function line(x0, y0, z0, x1, y1, z1, o) {
    if (!gl3.on) return;
    const b = batchFor(unitLine, !!o.glow);
    const d = b.data;
    const i = b.n * STRIDE;
    // only the first and last columns can matter to a shape with no width
    d[i] = x1 - x0; d[i + 1] = y1 - y0; d[i + 2] = z1 - z0; d[i + 3] = 0;
    d[i + 4] = 0; d[i + 5] = 1; d[i + 6] = 0; d[i + 7] = 0;
    d[i + 8] = 0; d[i + 9] = 0; d[i + 10] = 1; d[i + 11] = 0;
    d[i + 12] = x0; d[i + 13] = y0; d[i + 14] = z0; d[i + 15] = 1;
    rgb(d, i + 16, A.hue + (o.hue || 0), o.light === undefined ? 62 : o.light, o.sat);
    d[i + 19] = o.alpha === undefined ? 1 : o.alpha;
    d[i + 20] = o.width === undefined ? 1.6 : o.width;
    d[i + 21] = 0;
    b.n++;
  };

  // Every field is written on every call, deliberately. A carried-over object
  // that only copies the keys the caller happened to set is how a ring that
  // glowed once goes on glowing for the rest of the run.
  const hoopOpts = {};

  /** A hoop lying flat on the plane — reach marks, blast fronts, shockwaves. */
  gl3.ring = function ring(x, y, z, radius, o) {
    if (!gl3.on) return;
    const m = A.mesh.get("gl:hoop", () => A.mesh.hoop(56));
    hoopOpts.x = x;
    hoopOpts.y = y;
    hoopOpts.z = z;
    hoopOpts.sx = radius;
    hoopOpts.sy = radius;
    hoopOpts.sz = 1;
    hoopOpts.rx = 0;
    hoopOpts.ry = 0;
    hoopOpts.rz = o.rz || 0;
    hoopOpts.s = undefined;
    hoopOpts.hue = o.hue;
    hoopOpts.light = o.light;
    hoopOpts.alpha = o.alpha;
    hoopOpts.width = o.width;
    hoopOpts.sat = o.sat;
    hoopOpts.dim = o.dim;
    hoopOpts.glow = o.glow;
    gl3.model(m, hoopOpts);
  };

  // ---------------------------------------------------------------------------
  // uploading and drawing
  // ---------------------------------------------------------------------------

  /** The six instance attributes, identical in both programs and both passes. */
  function bindInstance(buffer) {
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    const bytes = STRIDE * 4;
    for (let k = 0; k < 4; k++) {
      gl.enableVertexAttribArray(k);
      gl.vertexAttribPointer(k, 4, gl.FLOAT, false, bytes, k * 16);
      gl.vertexAttribDivisor(k, 1);
    }
    gl.enableVertexAttribArray(4);
    gl.vertexAttribPointer(4, 4, gl.FLOAT, false, bytes, 64);
    gl.vertexAttribDivisor(4, 1);
    gl.enableVertexAttribArray(5);
    gl.vertexAttribPointer(5, 2, gl.FLOAT, false, bytes, 80);
    gl.vertexAttribDivisor(5, 1);
  }

  function upload(mesh) {
    let m = gpu.get(mesh);
    if (m) return m;

    m = { tris: mesh.tris, edges: mesh.edges, inst: gl.createBuffer() };

    if (mesh.tris) {
      m.solid = gl.createVertexArray();
      gl.bindVertexArray(m.solid);
      bindInstance(m.inst);
      const pos = gl.createBuffer();
      gl.bindBuffer(gl.ARRAY_BUFFER, pos);
      gl.bufferData(gl.ARRAY_BUFFER, mesh.tri, gl.STATIC_DRAW);
      gl.enableVertexAttribArray(6);
      gl.vertexAttribPointer(6, 3, gl.FLOAT, false, 0, 0);
      const nrm = gl.createBuffer();
      gl.bindBuffer(gl.ARRAY_BUFFER, nrm);
      gl.bufferData(gl.ARRAY_BUFFER, mesh.nrm, gl.STATIC_DRAW);
      gl.enableVertexAttribArray(7);
      gl.vertexAttribPointer(7, 3, gl.FLOAT, false, 0, 0);
    }

    if (mesh.edges) {
      // four corners per edge, each carrying both endpoints and which side of
      // the line it stands on, so the vertex shader can fatten it after the
      // divide
      const n = mesh.edges;
      const v = new Float32Array(n * 4 * 8);
      const idx = new Uint16Array(n * 6);
      const corners = [-1, 0, 1, 0, 1, 1, -1, 1];
      for (let e = 0; e < n; e++) {
        const s = e * 6;
        for (let k = 0; k < 4; k++) {
          const o = (e * 4 + k) * 8;
          v[o] = mesh.edge[s]; v[o + 1] = mesh.edge[s + 1]; v[o + 2] = mesh.edge[s + 2];
          v[o + 3] = mesh.edge[s + 3]; v[o + 4] = mesh.edge[s + 4]; v[o + 5] = mesh.edge[s + 5];
          v[o + 6] = corners[k * 2];
          v[o + 7] = corners[k * 2 + 1];
        }
        const b = e * 4;
        idx.set([b, b + 1, b + 2, b, b + 2, b + 3], e * 6);
      }
      m.edge = gl.createVertexArray();
      gl.bindVertexArray(m.edge);
      bindInstance(m.inst);
      const vb = gl.createBuffer();
      gl.bindBuffer(gl.ARRAY_BUFFER, vb);
      gl.bufferData(gl.ARRAY_BUFFER, v, gl.STATIC_DRAW);
      gl.enableVertexAttribArray(6);
      gl.vertexAttribPointer(6, 3, gl.FLOAT, false, 32, 0);
      gl.enableVertexAttribArray(7);
      gl.vertexAttribPointer(7, 3, gl.FLOAT, false, 32, 12);
      gl.enableVertexAttribArray(8);
      gl.vertexAttribPointer(8, 2, gl.FLOAT, false, 32, 24);
      const ib = gl.createBuffer();
      gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, ib);
      gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, idx, gl.STATIC_DRAW);
    }

    gl.bindVertexArray(null);
    gpu.set(mesh, m);
    return m;
  }

  function drawPass(q, additive) {
    let any = false;
    gl.bindVertexArray(null);
    for (const b of q.values()) {
      if (!b.n) continue;
      any = true;
      const m = upload(b.mesh);
      gl.bindBuffer(gl.ARRAY_BUFFER, m.inst);
      gl.bufferData(gl.ARRAY_BUFFER, b.data.subarray(0, b.n * STRIDE), gl.DYNAMIC_DRAW);
    }
    if (!any) return;

    if (additive) {
      gl.blendFunc(gl.ONE, gl.ONE);
      gl.depthMask(false);
    } else {
      gl.blendFunc(gl.ONE, gl.ONE_MINUS_SRC_ALPHA);
      gl.depthMask(true);
    }

    // bodies first, so the cages have something to stand in front of
    gl.useProgram(solidProg.p);
    gl.uniformMatrix4fv(solidProg.vp, false, vp);
    gl.uniform3f(solidProg.light, LIGHT[0], LIGHT[1], LIGHT[2]);
    for (const b of q.values()) {
      if (!b.n || !b.mesh.tris) continue;
      const m = gpu.get(b.mesh);
      gl.bindVertexArray(m.solid);
      gl.drawArraysInstanced(gl.TRIANGLES, 0, m.tris * 3, b.n);
    }

    gl.useProgram(edgeProg.p);
    gl.uniformMatrix4fv(edgeProg.vp, false, vp);
    gl.uniform2f(edgeProg.half, gl3.canvas.width / 2, gl3.canvas.height / 2);
    gl.uniform1f(edgeProg.bias, 0.0018);
    for (const b of q.values()) {
      if (!b.n || !b.mesh.edges) continue;
      const m = gpu.get(b.mesh);
      gl.bindVertexArray(m.edge);
      gl.drawElementsInstanced(gl.TRIANGLES, m.edges * 6, gl.UNSIGNED_SHORT, 0, b.n);
    }
  }

  /**
   * The whole of the 3D frame, called by the compositor between the fade and
   * the flat draw hooks. Everything with a `draw3d` fills the queues; this
   * empties them onto a texture and hands the texture to the entity layer,
   * where the trails and the bloom take it from there.
   */
  gl3.frame = function frame(tick, g) {
    if (!gl3.on) return;
    for (const q of queues) for (const b of q.values()) b.n = 0;

    A.run("draw3d", tick, gl3);
    camera();

    gl.viewport(0, 0, gl3.canvas.width, gl3.canvas.height);
    gl.clearColor(0, 0, 0, 0);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.enable(gl.DEPTH_TEST);
    gl.depthFunc(gl.LEQUAL);
    gl.enable(gl.BLEND);
    gl.disable(gl.CULL_FACE);        // a hollow shell is read from both sides

    drawPass(queues[0], false);
    drawPass(queues[1], true);

    gl.bindVertexArray(null);
    gl.depthMask(true);

    g.drawImage(gl3.canvas, 0, 0, A.W, A.H);
  };

  // No guide tile: a renderer briefs nobody. What it draws introduces itself by
  // being three-dimensional the moment somebody presses ENTER, which was always
  // going to be the only introduction it got.
  A.register({ id: "gl" });
})(ASTEROIDS);
