// The loader. index.html has exactly one script tag and this is it.
//
// Classic scripts, deliberately: ES modules cannot be fetched from a file://
// page, and this game opens by double-clicking index.html. So instead of an
// import graph there is one namespace — window.ASTEROIDS, called `A` inside
// every module — and this file pulls the manifest, then everything in it.
//
// Dynamically inserted scripts with async = false execute in insertion order,
// so the manifest is a plain ordered list and main.js is always last.

window.ASTEROIDS = {};

(function () {
  "use strict";

  const BASE = "src/";

  function inject(path, onload) {
    const s = document.createElement("script");
    s.src = BASE + path.replace(/^\.\//, "");
    s.async = false;
    if (onload) s.onload = onload;
    s.onerror = () => console.error("ASTEROIDS: could not load " + s.src);
    document.head.append(s);
  }

  inject("./features.js", () => {
    for (const path of window.ASTEROIDS.MODULES) inject(path);
    inject("./main.js");
  });
})();
