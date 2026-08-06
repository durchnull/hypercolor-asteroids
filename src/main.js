// Boot.
//
// Size the canvases, build the bits of DOM that are generated from data, wire
// the input up, put some rocks on the attract screen, and start the frame.
// If you are looking for the game, it is in the features — see features.js and
// docs/ARCHITECTURE.md.

(function (A) {
  "use strict";

  A.resize();
  A.buildHud();
  A.renderGuide();
  A.renderLobby();
  A.installInput();
  A.attract();
  A.startLoop();
})(ASTEROIDS);
