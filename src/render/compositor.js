// The render pipeline.
//
//   sky  →  fade the entity layer  →  every feature's draw hook  →  bloom,
//   shake and RGB smear back onto the visible canvas  →  flash, banner, pause
//
// Features draw into `g` (the entity layer) and get bloom and trails for free.
// The last few passes are deliberately *not* bloomed: they are the cabinet
// talking to you, not something in the world.

(function (A) {
  "use strict";

  A.render = function render(tick) {
    const { ctx, g, layer } = A;
    const fx = A.fx;

    A.drawSky(tick.time);

    // fade the entity layer instead of clearing it: trails
    g.save();
    g.setTransform(1, 0, 0, 1, 0, 0);
    g.globalCompositeOperation = "destination-out";
    g.fillStyle = "rgba(0,0,0,0.17)";
    g.fillRect(0, 0, layer.width, layer.height);
    g.restore();
    g.globalCompositeOperation = "source-over";

    // the field itself, as solids under a camera, painted onto the same layer
    // so it inherits the trails and the bloom (src/render/gl.js). On a machine
    // with no WebGL2 this does nothing and the flat draw hooks below are the
    // whole game, exactly as they used to be.
    A.gl.frame(tick, g);
    A.run("draw", tick, g);

    // composite the glowing layer over the sky, with shake and RGB smear
    ctx.save();
    if (fx.shake > 0.2) {
      ctx.translate(A.rand(-fx.shake, fx.shake), A.rand(-fx.shake, fx.shake));
    }
    ctx.globalCompositeOperation = "lighter";
    // bloom: downscale the layer, then let the upscale do the blurring
    A.bA.clearRect(0, 0, A.bloomA.width, A.bloomA.height);
    A.bA.drawImage(layer, 0, 0, A.bloomA.width, A.bloomA.height);
    A.bB.clearRect(0, 0, A.bloomB.width, A.bloomB.height);
    A.bB.drawImage(A.bloomA, 0, 0, A.bloomB.width, A.bloomB.height);
    ctx.globalAlpha = 0.55;
    ctx.drawImage(A.bloomA, 0, 0, A.W, A.H);
    ctx.globalAlpha = 0.45;
    ctx.drawImage(A.bloomB, 0, 0, A.W, A.H);
    ctx.globalAlpha = 1;
    if (fx.aberr > 0.02) {
      const o = fx.aberr * 9;
      ctx.globalAlpha = 0.6;
      ctx.drawImage(layer, -o, 0, A.W, A.H);
      ctx.drawImage(layer, o, o * 0.5, A.W, A.H);
      ctx.globalAlpha = 1;
    }
    ctx.drawImage(layer, 0, 0, A.W, A.H);
    ctx.restore();
    ctx.globalCompositeOperation = "source-over";

    if (fx.flashA > 0.01) {
      ctx.fillStyle = A.neon(A.hue + fx.flashHue, 60, fx.flashA * 0.75);
      ctx.fillRect(0, 0, A.W, A.H);
    }

    if (fx.banner) drawBanner(fx.banner);
    // one voice at a time in the middle of the screen: something holding the
    // screen for an answer has already said the field is stopped
    if (A.game.paused && !A.game.holding) drawPaused();

    // the chrome pass: the cabinet talking to you, over everything and out of
    // the bloom. Draws on `ctx`, not on the entity layer
    A.run("chrome", tick, ctx);
  };

  function drawBanner(banner) {
    const ctx = A.ctx;
    const f = Math.min(1, banner.life / 1.9);
    ctx.save();
    ctx.globalAlpha = Math.min(1, banner.life * 1.6);
    ctx.translate(A.W / 2, A.H / 2);
    ctx.scale(1 + (1 - f) * 0.45, 1 + (1 - f) * 0.45);
    ctx.fillStyle = A.neon(A.hue * 3, 68);
    ctx.shadowColor = ctx.fillStyle;
    ctx.shadowBlur = 24;
    ctx.font = "600 34px " + A.FONT;
    ctx.textAlign = "center";
    ctx.letterSpacing = "10px";
    ctx.fillText(banner.text, 0, 0);
    if (banner.sub) {
      ctx.font = "600 15px " + A.FONT;
      ctx.letterSpacing = "7px";
      ctx.fillStyle = A.neon(A.hue * 3 + 60, 62);
      ctx.shadowColor = ctx.fillStyle;
      ctx.fillText(banner.sub, 0, 30);
    }
    ctx.letterSpacing = "0px";
    ctx.restore();
  }

  function drawPaused() {
    const ctx = A.ctx;
    ctx.save();
    ctx.fillStyle = A.neon(A.hue * 2, 70);
    ctx.shadowColor = ctx.fillStyle;
    ctx.shadowBlur = 18;
    ctx.font = "600 18px " + A.FONT;
    ctx.textAlign = "center";
    ctx.letterSpacing = "8px";
    ctx.fillText("PAUSED", A.W / 2, A.H / 2);
    ctx.letterSpacing = "0px";
    ctx.restore();
  }
})(ASTEROIDS);
