---
name: chronicle
description: The book - docs/index.html is the cover and docs/v<N>.html is a page per version, generated from the git history. Rebuild it, look up what a version did or who flew it, or write a Chronicle line worth reading. Use when the user asks about the chronicle, the book, version history, what version something is, or wants their commit narrated.
model: sonnet
effort: medium
argument-hint: "[optional: a version like v7, a pilot's name, 'rebuild', or the commit to narrate]"
allowed-tools: Bash, Read, Edit, Grep, Glob
---

# Chronicle

A version is a commit that changed the game — `index.html`, `src/` or
`styles/`, the files that ship in the page you open. v1 is the first commit
that touched them and the newest is however many there have been since. Nobody
assigns the numbers; `tools/chronicle.sh` counts them off the history and
writes the book.

**The book is one page per version.** `docs/index.html` is the cover: the
pilots' roster, then every entry in order, newest first. `docs/v<N>.html` is
the chapter — full screen, the tagline in letters you can read from across the
room, the numbers that version made, forward and back buttons, the whole
history as a strip along the foot, and a picture of the commit itself. Arrow
keys turn the pages; Escape goes back to the cover. The game's splash screen
links to it, so nobody has to be told the book exists.

The picture is drawn from the diff and nothing else: a rock per sector the
commit touched, sized by how much of it moved, coloured by which part of the
cabinet it was — magenta for entities and events, violet for game, cyan for
render and input, amber for audio, lime for ui and styles, dim for anything
outside the game. A dashed rock left the repository. The seed is the commit
hash, so a version draws the same field in every clone forever, which is what
makes committing a generated page sane: rebuild it anywhere, get the same bytes.

Everything else that happened is real work and gets a mention rather than a
number: a rule change, a rebuild of this book, a line fixed in the README. The
cabinet is the same cabinet afterwards, so there is nothing for the next pilot
to find out by playing. Those land as **interludes** — *"While v11 was on the
cabinet, Dave changed the rules"* — a line on the cover and a margin note on
the page of whichever version was up at the time. No number, so no page.

```sh
tools/chronicle.sh              # rebuild the book, and backfill any missing taglines
tools/chronicle.sh --version    # what is on the cabinet?
tools/chronicle.sh --next       # what the next commit becomes, or "-" for no version
tools/chronicle.sh --recent 10  # plain text digest, interludes marked --
tools/chronicle.sh --moved HEAD # quietly: did that commit touch the game?
open docs/index.html            # the cover
open docs/v7.html               # straight to a chapter
```

Because the numbers are counted rather than stored, a pilot who never ran
`--install` still lands on the same version as everybody else, and the next
rebuild picks up whatever their hooks did not write.

## The tagline

Every version carries one line saying what happened to the game. It is the
first thing in the chapter, above whatever the pilot had to say about it.

```sh
tools/tagline.sh                # what the change in front of you would be called
tools/tagline.sh HEAD           # the line a version landed under
tools/tagline.sh --list         # the whole record
```

Where it comes from, first one wins:

1. **`docs/taglines.tsv`**, if the version already has one. Written once and
   never rewritten — which is what makes it worth hand-editing. Open the file,
   put a better line in, and it stays. The only place a landed tagline can
   still be fixed, which is how the machine's first fifty-seven were.
2. **A `Tagline:` line in the commit message**, and on a version this is not
   optional — GR17 stops the commit without it. The pilot's own words beat the
   machine's, always.
3. **`tools/tagline.sh`**, from what the commit did: a new file under
   `src/events/` reads as an event, one under `src/entities/` as an arrival,
   `src/audio/` as a noise, `styles/` as a colour, and so on. Deterministic, so
   the line the commit template showed you is the line that lands.

The pools live in the `BEGIN` block of `tools/tagline.sh`. Add to them freely —
same register as everything else here, dry and no exclamation marks — and note
that an already-written line never changes, so improving the pools only affects
versions nobody has flown yet.

The `post-commit` hook rebuilds it automatically, so the file on disk is always
current and lands with the following commit. Never hand-edit `docs/index.html`
or `docs/` — it is generated, and the referee treats it as nobody's property.
To fix a chapter, land a new version worth reading about.

## The book speaks asteroid, not git

The chronicle is read for fun by somebody who is about to press ENTER, not by a
reviewer. So the facts come off the history, and the words do not. Nothing in a
chapter says *commit*, *insertions* or *files changed* when it can say what
happened to the field instead:

| the history says | the book says |
|---|---|
| commit | a version, flown by a pilot |
| by X, on date | flown by **X**, on date |
| 5 files changed | 5 sectors touched |
| 3527 insertions(+) | 3527 lines aboard |
| 12 deletions(-) | 12 jettisoned |
| the subject line | landed as “…” |
| no `Chronicle:` line | nobody wrote this one down |

One exception: **anything somebody has to type stays literal.** The
`git checkout <hash>` under each chapter is meant to be pasted into a terminal,
and a joke you cannot paste is just confusion. Nothing else in the page explains
itself — the book does not carry a note about how it was generated, because a
reader came to read about the versions, not about the script.

If you add something to a chapter, extend the table rather than inventing a
second voice, and keep the register the rest of the project uses — dry, third
person, no exclamation marks. The vocabulary lives in the header comment of
`tools/chronicle.sh`, next to the code that prints it.

## Writing a chapter

A chapter is one line, from the commit message:

```
Chronicle: Dave added comets on a Tuesday, then made them faster than the
           blaster, apparently on purpose.
```

What makes a good one:

- **Third person, past tense.** It is a history book, not a changelog.
- **About the pilot, not the patch.** "Mira gave the kraken a second head" is a
  chapter. "Refactor kraken state machine" is not.
- **Funny is allowed and mild slander is traditional** — about yourself, or
  about what your change does to everybody else's high score. Never actually
  unkind about a person, and never about anyone outside this project.
- **One sentence.** Chapters are read in a row.

If there is no `Chronicle:` line, the chapter says so — *"nobody wrote this one
down"* — and prints the subject as what the flight recorder happened to keep.
That is a visible gap in the record, under your name, which is the cheapest
possible reason to write the line. The subject shows up either way, so write
that one for a reader too.

## What the book records without being asked

- who flew each version, when, and how big it was
- every `Golden-Rule-Override:` — *"On this day Dave invoked an override"* —
  under the pilot's name, permanently, which is the entire deal behind budgets
- every `Rule-Change:`, so changes to the rules are as visible as changes to
  the game
- a roster of pilots, their version count, and how many rules each has bent

That last table is meant to be read out loud. Nobody minds losing at it; people
mind losing at it silently.
