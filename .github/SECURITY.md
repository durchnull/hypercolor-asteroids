# Security

The honest version: there is not much attack surface here, on purpose.

The game is one HTML page and a directory of classic scripts. It has no build
step, no package manager, no lockfile and no dependencies, and GR2 in
[GOLDEN_RULES.md](../GOLDEN_RULES.md) makes that a red line rather than a
preference. It never calls `fetch`, `XMLHttpRequest`, `WebSocket`,
`EventSource` or `sendBeacon`, it loads nothing from a CDN, and it has no
server, no accounts and no database. It opens from `file://`, keeps its high
scores in `localStorage`, and would work the same on a laptop that has been in
a drawer since the day it was cloned.

So a supply chain attack has nothing to poison, and there is no deployment to
compromise.

## What is worth reporting

- Anything in `tools/` or `.githooks/` that could be made to run code a
  contributor did not intend — these are shell scripts that read git history,
  and history is attacker-supplied when pull requests are open.
- Anything in `.github/workflows/` that leaks the repository token, or that
  would run a fork's code with write access.
- A way to make the referee pass something it should refuse. That is closer to
  cheating at the game than to a vulnerability, and it is still worth knowing:
  see `tools/referee-test.sh`, which exists precisely because a check that
  quietly stops firing is the worst failure this project has.
- Anything that turns the game into a way to attack the person playing it.

## How

Open a [security advisory](https://github.com/durchnull/hypercolor-asteroids/security/advisories/new),
or a normal issue if it is not sensitive. Most things here are not sensitive
and a public issue is fine.

There is no bounty. There is a cabinet, and you are welcome at it.

## Not security

- A pilot can type a line into `docs/RANKINGS.md` and clear their own flight
  meter. A pilot can fly under somebody else's name. Both are known, both are
  written down in the rules, and the posture is honesty rather than security —
  they would be writing themselves a receipt for an evening they did not spend,
  in a public file, in a repository that remembers who wrote every line of it.
- The black box seal is a checksum, not a signature. It catches a tape somebody
  edited by hand. It is not trying to stop somebody determined to forge one.
