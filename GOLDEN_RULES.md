# THE GOLDEN RULES

Many hands, one cabinet. Somebody lands a version, and the next person to pull
and press ENTER finds out what happened by playing. That is the entire game
behind the game, and these fourteen rules exist to keep it playable for everyone
— not to slow anybody down.

They are enforced three times: while you work (your editor tells you), when you
commit (the hooks), and forever after (the history, which nobody can quietly
edit). Run the referee yourself any time:

```sh
tools/golden-check.sh          # what would the referee say right now?
tools/golden-check.sh --install  # once per clone, wires up the hooks
```

Rules come in four weights, and the weight is the whole fairness argument:

| weight | what it means | which |
|---|---|---|
| **red line** | cannot be overridden by anyone. To change one, change this file — in its own commit, in front of everybody. | GR1, GR2, GR7, GR10, GR11, GR12, GR13 |
| **budget** | you may spend past it, but only in writing. One line in the commit message and you are through. That line stays in the book forever. | GR4, GR5, GR6, GR14 |
| **nudge** | the referee mentions it and gets out of your way. | GR3, GR9 |
| **on your honour** | no check exists and none could. It is the rule that decides whether the game is any good. | GR8 |

The point of a budget is not to stop you. It is that **nobody can do anything
big silently.** You always have a way through; you never have a way through
unnoticed.

---

## GR1 — Leave it playable. `red line`

Every commit opens in a browser and plays. Not "works on my branch", not
"almost" — someone is going to pull this and press ENTER expecting a game.

*Checked:* every changed `.js` file parses; every module path listed in
`src/features.js` points at a file that ships; every `src=` and `href=` in
`index.html` points at something that exists in the commit. None of that is
somebody pressing ENTER, which is why GR14 exists: the referee cannot keep this
promise for you, so it asks for the tape instead.

There is no `import` anywhere in `src/` — modules are classic scripts loaded
from the manifest, because that is what opens from `file://` without a server.
The referee checks relative import specifiers too, for the day somebody tries.

## GR2 — No dependencies, no build step, no network. `red line`

The cabinet is one page you open. No package manager, no bundler, no
TypeScript, nothing fetched from a CDN, nothing phoning home. The game plays on
a plane, from a USB stick, in ten years.

*Checked:* no `package.json`, lockfiles, `node_modules/`, bundler configs or
`.ts`/`.tsx`/`.jsx` files; no `fetch`, `XMLHttpRequest`, `WebSocket`,
`EventSource` or `sendBeacon`; no remote `src=`/`href=`/`@import`.

It applies to the referee as much as to the game: `tools/` is sh, awk and git,
and nothing in it installs anything. One tool is allowed to speak to the world,
on purpose and in the open: `tools/chronicle-art.sh` paints one plate per
version into `docs/art/`, using credentials in an untracked `.env` that only
the book's writer has (see `.env.example`). It runs on their machine, never in
the game or the page, asks once per version ever, and with no credentials it
exits quietly. By the time any reader sees a plate it is an ordinary committed
file. The cabinet itself still plays on a plane.

## GR3 — Your feature, your file. `nudge`

Anything that lives, moves or draws goes in its own module — `src/entities/`
for things in the field, `src/game/` for rules, `src/ui/` for panels,
`src/render/` for the ones that only draw — registered with `register({...})`,
plus one line in the manifest `src/features.js`. That is the whole integration.

The manifest is a list of paths, not imports. Its first block is the commons
and the order there matters; append yours to the second block, alphabetically,
where it does not.

This is why several people can land several features in the same week without
ever touching the same lines, and why the only file two branches are likely to
both touch is a sorted list where the merge is trivial. It is also how
ownership becomes obvious: the file is yours because `git log` says you created
it.

*Checked:* a file calling `register()` from outside those four directories is
flagged; a new feature whose path is not in `src/features.js` is flagged,
because nothing will ever load it.

## GR4 — Add, don't undo. `budget: 25 lines`

You may extend anyone's feature. You may tune anyone's numbers — balance is
everybody's business and a few lines is all it takes. You may not gut, disable
or quietly delete someone else's work to make room for yours.

The owner of a file is whoever's commit created it. Your own files are yours
entirely; do what you like.

*Checked:* removing more than 25 net lines from a file you did not create, or
deleting it outright, needs `Golden-Rule-Override: GR4 - <why>`. Net is a
proxy with a blind spot — replacing somebody's hundred lines with a hundred
different ones — so a rewrite past 100 gross lines gets a nudge: nothing
blocks, the room just looks. The book re-referees this one off the history
too: past the budget with no override line reads as a referee that was never
asked, and costs two (GR12).

## GR5 — The commons stays common. `budget: 60 lines`

`index.html`, `src/main.js`, `src/features.js`, `src/core/`, `src/render/`,
`src/input/`, `src/ui/`, the shared rules in `src/game/` (`players.js`,
`difficulty.js`, `lifecycle.js`, `events.js`, `profile.js`, `tally.js`),
`src/audio/context.js`, `src/audio/buses.js`, `styles/tokens.css` and the
`README` belong to everybody. Add hooks, add fields, add tokens — freely. But
keep it backwards compatible: if you change what a hook is called or what it is
handed, three other people's features break while they are asleep.

The song is deliberately not on that list. `src/audio/voices.js`, `song.js`,
`sfx.js` and `riff.js` load with the commons but they are somebody's work, and
GR4's tighter budget on them is the point rather than an oversight.

The frame object in `loop.js` exists precisely so you can add a field without
changing a signature. Use that shape of solution.

*Checked:* removing more than 60 net lines from a commons file, or deleting
one, needs `Golden-Rule-Override: GR5 - <why>`. As with GR4, a rewrite past
240 gross lines gets a nudge even when the net stays small — and as with GR4,
the book re-referees the budget off the history, so spending it silently
costs two (GR12).

## GR6 — One surprise per commit. `budget: 1200 lines / 25 files`

Land one idea at a time. A commit that changes everything leaves the next
person nothing to discover and nothing to review, and it makes the book
unreadable.

Nothing under `docs/` counts against you — the book is generated, and the map
beside it is not the cabinet. Neither does a commit that is nothing but the
rules and their machinery: GR10 already forces that shape into its own commit
with its reason on the record, and a referee written in sh is verbose rather
than surprising. The budget is for the game.

*Checked:* over budget needs `Golden-Rule-Override: GR6 - <why>`. Over 600
added lines is a nudge, not a block. A commit touching only rule files and
generated files is not measured at all.

## GR7 — Sign your work in git, not in the code. `red line`

`git blame` is the credit system, which is why nothing in the source needs an
`@author` tag and nobody puts their name in the HUD. It is also why the history
is not editable: no force-pushing `main`, no rewriting or reassigning commits
other people already have. Land a new commit instead — the old one stays in the
book either way.

Write the subject line for the next pilot, not for the diff. "Comets, and they
come in threes" beats "add comet feature".

*Checked:* `git config user.name` must be set; no `@author` tags in source; the
pre-push hook refuses any non-fast-forward push to `main`. Thin or generic
subjects get a nudge.

## GR8 — Play fair in the game, too. `on your honour`

The referee cannot check this one, so it is on you, and it is the rule that
actually keeps the game good:

- Nothing makes the player invincible and nothing makes the game unloseable.
  Every new power has a cost, a cooldown, or a finite count — the atom bomb is
  the precedent: two to start, one more each wave.
- Both seats stay equal. Any control you add exists for player one and player
  two.
- Difficulty may rise. It may not become unfair — the player must be able to
  see the thing that is about to kill them.
- It still holds 60fps on a laptop, and it still works on a keyboard with no
  numpad.
- You do not nerf somebody's feature to make yours look better.

No machine checks any of that, and none ever will. What exists is a witness:
when the pilots agree that something landed across this line — an unloseable
power, a firing-squad event, a nerf dressed as a tune — any one of them may
put it on the record, in a commit that carries the freshly generated ledger:

```
Golden-Rule-Breach: GR8 Dave Okoro - the comet shield has no cost and no
                    cooldown, and the table agrees it crossed the line
```

The line names the pilot it is about, not whoever typed it, and it costs them
one on the tally like any other bend (GR12). It is not a veto and it undoes
nothing: the feature stays until somebody fixes it in the open. Agreement
first, always — a breach line written by one annoyed pilot without the table
behind it is itself the kind of thing the table gets to judge, in the open,
where it landed.

The judgment is human and stays human; the paperwork is checked. A breach
naming somebody no commit was ever authored by does not land — a typo would
charge a phantom and let the real pilot walk — and a breach line riding
inside unrelated work gets pointed at, because the ritual is the line and
the ledger, nothing else.

## GR9 — Keep the surprise. `nudge`

The reveal happens in the game, not in the diff. Ship a `guide` entry with your
feature so it appears in the field guide and the next player discovers it by
playing; leave the README describing the cabinet, not your changelog.

Write a `Chronicle:` line in your commit message. That is the sentence that
goes in the book, and the book is read for fun.

*Checked:* a new feature with no `guide` entry is flagged; a README edit
alongside a new feature is flagged; a missing `Chronicle:` line is mentioned.

## GR10 — Changing the rules is its own commit. `red line`

`CLAUDE.md`, `GOLDEN_RULES.md`, `tools/`, `.githooks/`, `.github/`,
`.gitattributes`, `.claude/settings.json` and `.claude/skills/` may not move in
the same commit as game code, and a rule change needs a `Rule-Change: <why>`
line. Widen your own permissions if you can convince people — but never in the
same breath as using them.

`.github/` is on that list for the same reason `.githooks/` is. It is the
second reading of these rules — the one that happens after work arrives from a
clone that never installed the hooks — and a referee you can edit in the same
commit as the thing it is refereeing is not one.

Nobody may disable the referee for a commit. `--no-verify` is not a tool, it is
a confession.

*Checked:* referee files and game files in one commit is refused; a rule change
with no `Rule-Change:` line is refused. Neither is overridable.

## GR11 — An event belongs to the pilot who wrote it. `red line`

An **event** is an unexpected challenge dropped into a live wave — three
krakens surfacing at once from three sides, a ring of rock closing in, portals
opening exactly where you were about to be. Anyone may write them, in one file
under `src/events/` named after themselves, and one rule makes it worth doing:

> **An event never fires for the pilot who wrote it.**

You cannot be ambushed by your own trap. Everybody else can. That is why the
splash screen asks who is flying before it lets you in, and why laying a good
one is the most direct route there is to ruining a friend's evening.

The rule has a mirror, for whoever just walked in: **the field does not
ambush the unarmed.** A named pilot with no event of their own in the game
has none fired at them — the first evening is for learning the field, and
writing your first trap is the induction that arms the room. GUEST is spared
nothing, which is the walk-up experience and is deliberate. The shelter is
for the new, not the indebted: a pilot the ledger still charges (GR12) is
ambushed armed or not, because a shelter you could reach by deleting your
own arsenal would be a hole in the tally.

So this rule is a red line and has no budget, not even an override: the whole
mechanic rests on nobody being able to disarm the thing that is waiting for
them.

- Your own event file is yours forever — rewrite it, retune it, delete it.
- Another pilot's event file is not yours to touch. Not one line.
- Sign every event `by:` your git name, exactly. `by: A.HOUSE` means the event
  belongs to nobody and fires for everyone, author included — the honourable
  option when you want the thing in the game more than the credit for it.
- Balance still applies (GR8). An event is a challenge, not a firing squad:
  make it survivable by a pilot who reads it early and reacts well — and the
  author is the one pilot who can prove that before it lands. Fly your own
  trap (GUEST arms everything, yours included) and put the survived-it tape
  beside the landing. On your honour, like GR1's playtest promise; a trap
  that lands unproven is something the book gets to say.

That `by:` is the one name that belongs in the source, and GR7 is not bent by
it: it is not a credit line, it is a targeting instruction. `git blame` still
says who wrote the file.

**One exception, written here rather than hidden in the rule that uses it.**
The tally (GR12) counts the times a pilot has bent a rule in the open. At three
the runner stops making the exception for them, and their own traps start
firing at them like everybody else's. That is not a way to disarm somebody's
event — nothing is, ever, that is what the red line is for — it is the only way
in the cabinet to arm one *more*, and the only event it can arm is your own,
against you, because you earned it. GR11 still has no override. This is not
one; it is another red line reaching across.

**The machinery counts too.** Two files decide whether any of this is true —
`src/game/events.js`, which skips an event for its own author, and
`src/game/profile.js`, which decides who that is. They are commons (GR5), they
are not anybody's feature, and the guard inside the runner is part of the red
line rather than part of the code. The seat itself is local: `tools/whoami.sh`
writes your git name into `src/game/whoami.local.js`, which is untracked and
stays on your machine, so your own traps go quiet and everybody else's stay
armed. Without that file the splash screen simply asks.

*Checked:* touching or deleting an event file you did not create is refused;
signing an event with a name that is not yours and is not the house is refused;
deleting the runner or the seat is refused; and changing the runner so that it
no longer skips an event for its author is refused. Rewrite it as you like, but
leave the guard recognisable — `e.by !== A.HOUSE && e.by === <the pilot>` — and
leave the only condition on it the one GR12 puts there. No overrides on any of
it.

## GR12 — The tally remembers. `red line`

A budget is spent in the open or it is not spent at all. So the moment a
version lands carrying a `Golden-Rule-Override:` line — or lands with the
referee never having run on it at all — the hooks write it down and commit it
on the spot, under the name of whoever just flew, while they are still reading
their own commit message:

```
THE LEDGER: Dave Okoro bends GR6, and it goes on the record
```

Nothing is blocked and nothing is undone. You keep the override, you keep the
version, and you also keep a number. `src/game/ledger.js` is that number, one
line per pilot, and `tools/tally.sh` reads it off the history exactly the way
`tools/chronicle.sh` reads the book. What the number does to a pilot's field is
`src/game/tally.js`, and that file is commons (GR5) — a punishment the punished
could quietly switch off would not be one.

A bend costs one. Going round the referee costs two — `--no-verify`, hooks
unset, a check edited until it passes — because a rule bent quietly costs more
than a rule bent out loud. The referee cannot stop you doing it. It can notice
afterwards that it was never asked, and that turns out to be enough — and the
noticing no longer depends on the skipper's own machinery: the tally
re-referees the history the same way the book does, so a commit that provably
breaks a red line with nothing written down pays its two whether or not the
hooks were ever wired to say so. A GR8 breach the table put on the record
costs one, under the name of the pilot the line names rather than whoever
held the pen (see GR8).

The number is not a scolding. It is a difficulty setting, and it is yours:

| bends | what the cabinet does about it |
|---|---|
| 0 | nothing at all. The field behaves. |
| 1+ | events come for you sooner — every bend shortens the gap, to a floor of half. |
| 3+ | **your own events stop sparing you.** |
| 4+ | a wave may hold one more ambush than it used to. |

Read the third row twice, because it is the expensive one. GR11 promises that
your own trap never fires at you, and this is the one thing in the cabinet that
takes the promise back — which is why it is written into GR11 as well, where
somebody looking for it will find it.

Nobody else's field changes. It follows the name on the splash screen, so yes,
you could pick somebody else's name and fly their field instead — their traps
quiet for you, yours armed, their tally on your evening. What that buys is a
flight worth nothing: the black box seals the seat into the tape, and a flight
flown under a name that is not the pilot's own ranks nowhere, keeps no best
score, and puts nothing on the board — the blackbox ritual checks, and
refuses. The cheapest way out of the ledger is a run the record ignores. That
is the design.

The record does not decay, because the history does not decay. The field
forgives all the same: every three clean versions landed since your last bend
ease the field's arithmetic by one bend's worth — the heat, the crowding, and
at the far end your own traps go back to sparing you. Every row of the table
reads that eased number; the written one never moves, and the next bend puts
the whole of it straight back. `tools/tally.sh` counts the clean landings off
the same history it counts everything else — a landing is clean when it moved
the game and bent nothing, and the ledger's own receipts do not qualify. Land
good versions; that was always the way out, and now the field can tell.

*Checked:* `src/game/ledger.js` must say what `tools/tally.sh` reads off the
history, with the pending commit message in hand — the clean-version count
beside each name included, derived the same way, and the skips included too,
judged off the history by the book's own audit rather than by anybody's
hooks, against every rule a machine can prove from a commit alone: GR4, GR5,
GR6, GR10, GR11. Editing your own count is refused, deleting the file is
refused, and
there is no override on either — the tally is the one number in this project
nobody writes for themselves.

## GR13 — The owner's ground. `red line`

Almost nothing here belongs to one person. Tune anybody's numbers, extend
anybody's feature, rewrite the book builder if you have a better book in you.
There is one exception, it is small, and it is written down here so that it is
a rule rather than a habit: **a few things change only when the pilot who
opened the cabinet changes them.**

Today there is exactly one of them, and it is the orb.

A chapter opens with a rock hanging in weather, lit by whatever is actually
coming out of the speakers, and every twenty seconds or so it thinks something
unimpressed about the people writing all this. That object and the song it is
listening to are the owner's — how it looks, how it moves, what it says, how it
answers the sound, and the sound itself. Not a hue, not a line of the patter,
not a note of the piece.

The ground is one file: `docs/chronicle-song.js`, the room the book is read in.
It is generated like the rest of the book, so the ground that actually gets
edited is the heredoc in `tools/chronicle.sh` that writes it.

Nobody appoints the owner and nobody writes the name down: it is the author of
the first commit, which `git log --max-parents=0` will tell you, the same way
the history tells you everything else that counts here.

This is not a statement about who works hardest. It is one corner of the
project allowed to stay exactly as somebody meant it, so the room the book is
read in keeps one voice rather than thirteen. Everything else in
`tools/chronicle.sh` — the pages, the plates, the digest, the dock, the rail —
is ordinary work and yours to improve. And if the orb has a bug, or you have a
better thought for it to think, say so: that is a minute of the owner's evening
and they will probably enjoy it.

*Checked:* for anybody but the owner, a commit that changes that heredoc,
hand-edits the generated copy away from what the heredoc says, or deletes
either file, is refused. A rebuild that only brings the copy back into line
with the script is the machine catching up rather than anybody's doing, and it
passes.

No budget, no override: a rule about who may change a thing cannot come with a
line that lets everybody change it. What it can do is be argued with in the
open — move this section, in its own commit (GR10), where the owner reads it
like everybody else. Putting a second thing on the owner's ground is the same
move, and ought to be at least as hard.

## GR14 — Fly what you land. `budget: 3 versions per tape`

GR1 promises somebody who is not in the room that they can pull this, press
ENTER and get a game. The referee cannot keep that promise: it reads the code,
it never presses ENTER. This is the half of GR1 that can be checked.

Every finished flight seals itself into a tape, and a tape on the board in
`docs/RANKINGS.md` is the only evidence this project accepts that anybody
played anything. So:

> **A sealed flight buys three landings.**

Land the third version since you last flew and the referee mentions it. Land a
fourth and it stops you, and the way through is the way through every budget: a
line in the message.

Three, because a flight is four minutes and a version is an evening. It is the
cheapest rule in this file to satisfy and the easiest to forget, which is the
only reason it needed writing down.

- The meter counts **versions** — commits that moved `index.html`, `src/` or
  `styles/`. Rewriting these rules, fixing a line in the README, ranking
  somebody else's tape: real work, and it leaves the cabinet exactly as it was.
  Nobody discovers anything by playing a README.
- It counts **your own** versions. A rule you could fail by having busy friends
  would be a bad rule.
- **Any** finished flight counts. The board keeps the best twenty and the log
  keeps every tape, so a short bad evening clears the meter exactly like a good
  one. This is evidence, not a score: the moment a quota starts rewarding a
  number, people grind the number instead of playing the game.
- Fly under your own name. A tape sealed to somebody else's seat ranks nowhere
  (GR12), a run flown as GUEST is GUEST's flight, and neither clears anybody's
  meter. Couriering a friend's real tape is fine and lands on theirs.
- A tape is a flight, not a keypress. No machine can tell the difference — but
  the log prints how long you lasted, beside your name, for good.

The order is the order the ritual already had: build it, play it, paste the
tape, land the version. Flying, ranking and landing in one sitting is one
sitting — a commit that puts the tape on the board clears the meter before it
spends it.

An override here costs one on the tally like any other bend (GR12), and the way
back off the tally is three clean versions — which is now three versions you
have flown. That loop is deliberate.

*Checked:* a version commit by a pilot with three or more versions since their
last taped flight needs `Golden-Rule-Override: GR14 - <why>`; the one before it
gets a nudge. `tools/flights.sh` reads the meter off the history the way
`tools/tally.sh` reads the ledger — credited to the pilot the board line names,
never to whoever held the pen — and `tools/flights.sh --roll` shows the room.
The meter starts where this rule did: nothing before the commit that added it
is counted, because before it there was no promise to keep.

---

## Spending a budget

Add a line to the commit message:

```
Golden-Rule-Override: GR4 - the kraken's dive state was unreachable after the
                            portal change; rewriting it with Mira's agreement
```

The referee lets it through. `docs/index.html` records it forever, under your
name, in a chapter people read for fun. That is the price, and it is the
right price: cheap to pay, impossible to hide.

One commit later the ledger records it too, and the ledger is read by the game
rather than by people (GR12). The override line is the receipt. The tally is
what the field does about it.

## Versions

A version is a commit that changed the game — `index.html`, `src/` or
`styles/`, the files that ship in the page you open. v1 is the first commit
that touched them and the newest is however many there have been since.

Everything else in the repository is real work and gets a mention rather than a
number: rewriting these rules, ranking a flight, fixing a line in the README.
The cabinet is the same cabinet afterwards, and the next pilot has nothing new
to find out by playing.

One class of commit gets less than a mention. Every landing leaves `docs/` a
commit out of date, and the commit after it carries the pages the hooks wrote —
a book that narrated its own filing would never reach a last chapter. So a
commit that touches nothing but the book's generated files is passed over in
silence, on the cover and in the digest alike. The history keeps it, as it
keeps everything; the book just does not read it out. A commit carrying an
override, a rule change, a ledger receipt or a breach keeps its mention
whatever files it rode in on.

Nobody assigns the numbers. `tools/chronicle.sh` counts them off the history —
so a clone that never installed the hooks arrives at exactly the same numbers
as everybody else — and writes `docs/index.html`, one chapter per version. Your
`Chronicle:` line is what it quotes.

Read the book. Then go and do something to annoy the others.
