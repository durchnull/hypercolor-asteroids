# Joining the cabinet

Somebody lands a version. The next person pulls, presses ENTER, and finds out
what happened by playing. That is the game behind the game, and everything
below exists to keep it playable for whoever is not in the room.

The short version: build one thing, put it in its own file, play it, and write
the commit for the next pilot rather than for the diff.

## Set up, once

```sh
git clone https://github.com/durchnull/hypercolor-asteroids
cd hypercolor-asteroids
tools/golden-check.sh --install   # wire in the referee
git config pull.rebase false      # the house setting, and it is not a taste
tools/whoami.sh                   # your seat, so your own traps go quiet
open index.html                   # find out what the others did to you
```

There is nothing to install and nothing to build. If `open index.html` shows
you a game, you are set up. Some browsers are strict about `file://`, in which
case `python3 -m http.server 8000` and go to `localhost:8000`.

`tools/golden-check.sh --install` is the one step worth not skipping. It points
git at the hooks in `.githooks/`, and those are what tell you a rule is about
to be bent while you can still cheaply do something about it. Skip it and
nothing stops you — you just find out on the pull request instead, in public,
which is a worse place to find out.

`pull.rebase false` is the one line here that is about this repository rather
than about good practice, and it is worth the sentence. A rebase checks the
worktree out to each commit it replays, `.githooks/` along with everything
else, so an old commit runs the `post-commit` hook *it* shipped with — which
rebuilds the book, which dirties the tree, which stops the replay dead on the
very next commit. Today's hook refuses to rebuild mid-replay; a copy that
landed before that guard existed never will, and those copies are not going
anywhere. So this house merges. `tools/groundcrew.sh` merges for the same
reason, the referee says so if it catches you halfway through one, and if you
are already stuck the way out is `git rebase --abort`.

## Taking a turn

Most people here work by talking to [claude](https://claude.com/claude-code) in
the project folder, because [CLAUDE.md](CLAUDE.md) makes it a second referee
that knows the rulebook. A session looks like:

- *"what did the others land since I last played?"* — or `/scout`
- *"add comets, and make them come in threes"*
- *"a trap that flips everyone's controls for ten seconds"* — or `/event`
- *"read the black box"* — paste the tape off the game-over screen
- *"land it"* — or `/land`

You do not have to. Everything the skills do, you can do by hand, and the
referee does not care which you chose.

## What a good change looks like

**One idea, in its own file.** A feature is a plain object registered with the
game loop, plus one line in the manifest `src/features.js`. That is the whole
integration — `src/entities/` for things in the field, `src/game/` for rules,
`src/ui/` for panels. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) is the map.
If you find yourself editing four shared files to land one idea, that is the
signal to stop and find the registry-shaped solution instead.

**With a `guide` entry,** so the next player discovers it by playing rather
than by reading your diff.

**That you have actually played.** Every flight seals itself into a tape; copy
it off the game-over screen and put it on `docs/RANKINGS.md`. One tape buys
three landings (GR14). The referee cannot press ENTER for you, and this is the
half of that promise which can be checked.

**Fair.** Every new power gets a cost, a cooldown or a finite count. Both seats
stay equal. Nothing makes the game unloseable. No machine checks this and none
ever will — it is the rule that decides whether the game is any good.

## Before you open a pull request

Branches live in a directory, and the directory is the mark: the same nine
words the book puts on a chapter and the strip puts on a pull request.
`game/comets-come-in-threes`, `music/the-bass-was-too-polite`,
`chronicle/the-plates-paint-themselves`. Not `feat/` and `fix/`, because every
change is one of those and the word is spent before it has said anything.

```sh
tools/branch.sh <name>       # the mark is read off what you have changed
tools/branch.sh --rename     # for the branch you cut before you knew
tools/branch.sh --marks      # the nine directories, in order
```

You do not type the mark. `tools/chronicle.sh --marks` answers that question
for the book, the labels and the branch alike, so all three say the same word.
A branch that is already pushed is left alone — renaming it there strands the
old name on the remote with a pull request pointing at it.

```sh
tools/inbound.sh
```

That runs exactly what CI runs: every commit on your branch, read one at a
time, judged as its own author against its own message. If it is quiet locally
it will be quiet there.

Write the subject line from the next pilot's seat — *"Comets, and they come in
threes"* beats *"add comet feature"* — and add a `Chronicle:` line, which is
the sentence the book quotes.

## What happens to your pull request

Three things read it, in this order.

**The flight strip**, which is furniture and arrives first: you are assigned to
your own pull request, the owner is asked for a review, and it wears the same
nine marks the book puts on the chapter it becomes — `game`, `music`, `rules`,
and the rest. `tools/labels.sh main..HEAD` previews them. Nobody fills any of
that in by hand, and a path the book gives no mark to arrives bare.

**A workflow**, which prints what it found into the pull request summary: every
commit and its verdict, every budget the branch spent, and where the flight
meter stands. Red lines fail it. Budgets and nudges never do — they just get
printed, because the point was never that a machine stops you.

**People**, which is the part that matters. The summary exists so nobody has to
read the diff to find out what happened, and reading the diff is discouraged
anyway (GR9 — it is like shaking the presents).

Merges keep the individual commits rather than squashing them. Half the
rulebook only means anything one commit at a time, so a squashed branch is one
that cannot be refereed.

## The rules

[GOLDEN_RULES.md](GOLDEN_RULES.md) is the whole rulebook and it is one page.
Sixteen rules in four weights:

| weight | what it means |
|---|---|
| **red line** | cannot be overridden by anyone. To change one, change the file, in its own commit, in front of everybody. |
| **budget** | you may spend past it, in writing. One line in the commit message and you are through, and that line stays in the book forever. |
| **nudge** | the referee mentions it and gets out of your way. |
| **on your honour** | no check exists and none could. |

Spending a budget is not a failing. It costs one on the tally, your events
start coming for you sooner, and it is on the record under your name — that is
the entire price, and it is meant to be cheap to pay and impossible to hide.

Four things get refused whoever asks, and they are worth knowing in advance:

- **Another pilot's event file** (GR11). An event is a trap that never fires
  for whoever wrote it, and the whole mechanic rests on nobody being able to
  disarm the one waiting for them. No budget, no override, not one line.
- **Your own tally** (GR12). It is generated from the history by
  `tools/tally.sh`, which is the only reason it means anything.
- **The orb and the song in the book** (GR13). One corner of the project stays
  as one person meant it. If you have a better thought for it to think, say so
  — that is a minute of their evening and they will probably enjoy it.
- **A tape you did not fly** (GR16). Black boxes come off the game-over screen
  and nowhere else — not typed out, not a checksum worked backwards from
  numbers somebody read to you. The meter, the board and the rankings all rest
  on that, and GR14's override is the honest way past an evening you cannot
  fly.

Everything else is arguable, including the rules. Argue with them in their own
commit with a `Rule-Change:` line, never in the same breath as using them
(GR10).

## The licence, in one paragraph

This project is MIT ([LICENSE](LICENSE)), and **anything you contribute is
contributed under the same licence.** Opening a pull request is how you say so;
there is no form to sign and no bot to argue with.

It is written down because of what happens if it is not. You keep the copyright
on the lines you wrote — that is how copyright works and nobody is asking you
to give it up. But if the terms were never stated, every merged contribution
adds one more person whose agreement would be needed to change the licence
later, and after a while that is a question nobody can answer. One paragraph,
read before the first pull request, and it never becomes a question at all.

`docs/art/` and `docs/faces/` are machine-painted rather than written; see
[NOTICE](NOTICE) if you were wondering who drew them.

## One thing that is not arguable

The game is hostile on purpose and the people are not.
[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) is short and it comes down to aiming
it at the ship rather than at the pilot. Build the meanest trap you can and
address it to somebody by name — that is the game working. The rest of what
that file rules out was never part of it.

## If you are new here

Two things are on your side.

**The field does not ambush the unarmed.** A pilot with no event of their own
has none fired at them. The first evening is for learning the field; writing
your first trap is the induction that arms the room, and it is the most direct
route there is to ruining a stranger's evening.

**Your meter starts at zero.** You get three landings before GR14 asks to see a
tape. Use one of them on something small, so you find out what the ritual feels
like before it matters.

Now go and do something to annoy the others.
