# ASTEROIDS // HYPERCOLOR

A neon vector rewrite of the 1979 arcade game, in one HTML file. No build step,
no dependencies, no network — the graphics are canvas, the music is synthesised
in the Web Audio API at runtime, and the whole thing is about 110 KB of hand
written HTML, CSS and JavaScript.

![The field of play](media/swing.png)

## Play

Open `index.html` in a browser. That's it.

Some browsers refuse `file://` for local pages, so if it misbehaves, serve it:

```sh
python3 -m http.server 8000
# then open http://localhost:8000
```

## Controls

Two pilots, one screen. Player two can drop in mid-wave, and anyone out of
lives can buy back in — joining is never refused.

| | Player 1 | Player 2 |
|---|---|---|
| Turn | `←` `→` | `A` `D` |
| Thrust | `↑` | `W` |
| Fire | `space` | `Q` |
| Grapple (hold to winch) | `↓` | `S` |
| Atom bomb | `B` | `E` |

`P` pauses, `M` toggles sound.

## What's out there

- **Asteroid** — 20 / 50 / 100 points. Shoot one and it splits into smaller,
  quicker pieces.
- **Atom bomb** — the panic button. The blast front eats half the screen,
  vaporising every rock it touches and gutting any kraken. Two to start, one
  more each wave.
- **Grapple** — the line locks where it bites and never hauls you in, it
  *swings* you. Arc round a rock and cut loose to fly off on the tangent,
  faster than you came. Hold to winch tighter — a smaller circle is a quicker
  one. The rock swings too, and wrecks whatever it meets.
- **Kraken** — 250 points, 3–5 hits. Hunts you, dives into the deep, then
  surfaces right beneath you. Angrier with every hit, and later waves send a
  whole pack.
- **Portals** — a pair blinks open. Fly in one and out the other. So can your
  shots, and so can the kraken.
- **Planet** — too big for the screen. Rocks bounce off it, shots burn up on
  it, and it will happily flatten you.
- **The Falcon** — passing smuggler. Fires one enormous laser at the kraken,
  then keeps flying.

![Splash screen](media/splash-1280.png)

## How it's put together

Everything lives in `index.html`.

- **Rendering** — entities draw to an offscreen layer that is faded rather than
  cleared, so everything that moves leaves a phosphor trail. That layer is
  downscaled twice and scaled back up for a cheap bloom, then composited under
  a CRT vignette, scanlines and a rolling refresh bar.
- **Audio** — one shared Web Audio graph. A four section song in E minor
  (main theme, chase, half time breakdown, lift) is sequenced sixteenth by
  sixteenth at 168 BPM over synthesised guitar, harmonised lead, bass and
  drums. Sound effects are one shots on the same graph — the blaster is an
  FM'd saw diving four octaves through a resonant bandpass into a feedback
  delay, so it screams off into the distance.
- **Input** — keyboard for both seats, plus on screen buttons that appear only
  when a touch device is detected.
