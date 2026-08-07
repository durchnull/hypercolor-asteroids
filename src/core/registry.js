// The feature registry.
//
// Every part of the game that lives, moves or draws is a *feature*: a module
// that registers an object with lifecycle hooks. Nothing else in the codebase
// needs to know that feature exists — the loop asks the registry who wants to
// run, the compositor asks who wants to draw, and the splash screen asks who
// has a field-guide entry to contribute.
//
// That indirection is the whole point of this file: adding a feature is a new
// module plus one line in src/features.js, so two people can land two features
// in the same week without ever editing the same lines.
//
// A feature is a plain object:
//
//   A.register({
//     id: "kraken",                  // unique, used in errors
//     order: { update: 40, draw: 30 },
//     reset(mode) {},                // "play" | "attract" | "over"
//     update(tick) {},               // every frame, running or not
//     resolve(tick) {},              // after every update, only while running
//     draw(tick, g) {},              // onto the glowing entity layer
//     chrome(tick, ctx) {},          // over the finished frame, out of the bloom
//     guide: { name, icon, ... },    // optional field-guide row
//   })
//
// Every hook is optional. `order` is a number (applied to every hook) or an
// object keyed by hook name; the default is 50, so a feature that does not care
// where it sits in the frame does not have to say anything.

(function (A) {
  "use strict";

  const DEFAULT_ORDER = 50;

  const registered = [];
  const cache = new Map();

  function register(feature) {
    for (const f of [].concat(feature)) {
      if (!f || !f.id) throw new Error("a feature needs an id");
      if (registered.some((o) => o.id === f.id)) {
        throw new Error("duplicate feature id: " + f.id);
      }
      registered.push(f);
    }
    cache.clear();
  }

  function orderOf(f, hook) {
    const o = f.order;
    if (typeof o === "number") return o;
    if (o && typeof o[hook] === "number") return o[hook];
    return DEFAULT_ORDER;
  }

  // features that implement `hook`, in the order they want to run
  function listeners(hook) {
    let list = cache.get(hook);
    if (!list) {
      list = registered
        .filter((f) => typeof f[hook] === "function")
        .sort((a, b) => orderOf(a, hook) - orderOf(b, hook));
      cache.set(hook, list);
    }
    return list;
  }

  function run(hook, a1, a2) {
    for (const f of listeners(hook)) f[hook](a1, a2);
  }

  // field-guide rows, in guide order
  function guides() {
    return registered
      .filter((f) => f.guide)
      .sort((a, b) => orderOf(a, "guide") - orderOf(b, "guide"))
      .map((f) => f.guide);
  }

  A.register = register;
  A.run = run;
  A.guides = guides;
})(ASTEROIDS);
