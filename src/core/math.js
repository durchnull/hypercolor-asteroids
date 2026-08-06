(function (A) {
  "use strict";

  A.TAU = Math.PI * 2;

  A.rand = (a, b) => a + Math.random() * (b - a);

  /** The playfield is a torus: leave one edge, arrive at the other. */
  A.wrap = function wrap(obj) {
    const m = obj.radius;
    if (obj.x < -m) obj.x += A.W + m * 2;
    if (obj.x > A.W + m) obj.x -= A.W + m * 2;
    if (obj.y < -m) obj.y += A.H + m * 2;
    if (obj.y > A.H + m) obj.y -= A.H + m * 2;
  };
})(ASTEROIDS);
