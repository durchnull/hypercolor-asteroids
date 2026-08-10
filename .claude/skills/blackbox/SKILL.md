---
name: blackbox
description: Read a black box tape pasted from the game-over screen - verify the seal with tools/blackbox.sh, pull the flight out, rank it in docs/RANKINGS.md and commit it. Use when the user pastes a block containing BB1: lines or "BLACK BOX", says read the black box, or wants a finished flight on the record.
model: sonnet
effort: high
argument-hint: "[the tape pasted in full, or a path to the file holding it]"
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

# Black box

The game seals every finished flight into a tape: readable header, base64
body, FNV-1a checksum (`src/game/blackbox.js` writes it). The pilot copies it
off the game-over screen and pastes it here. Your job is the other half:
verify, decode, rank, commit. The tape is the only way onto the board — that
is what makes the board worth reading.

**You never write one.** Not a `BB1:` block, not a checksum for numbers
somebody read out, not a reconstruction of a flight from what the pilot
remembers of it. This skill starts with a paste and cannot start any other way
(GR16, red line, no override). Asked for a tape, the answer is the game: four
minutes, and the screen prints one. Asked because there is no time to fly, the
answer is `Golden-Rule-Override: GR14` in the landing — a bend that is true
beats a receipt that is not.

## The ritual

1. **Save the paste verbatim** to a scratchpad file — never into the repo —
   and run the reader:

   ```sh
   sh tools/blackbox.sh --save <file>    # or: pbpaste | sh tools/blackbox.sh --save
   ```

   `--save` files the decoded flight at `docs/tapes/<crc>.json` — the exact
   bytes the seal was taken over, which is why the file is named after its own
   sum. Use it on every tape you are going to rank, and commit it beside the
   board row. Without it the row is a sentence and eight hex digits that
   nobody, ever, can read back — which is what the board used to be, and the
   one thing about it that was not true of every other number in this project.
   Leave `--save` off only when you are reading a tape without ranking it: a
   proof flight, or somebody asking what their numbers were.

2. **Seal broken or no tape?** Say so and stop. Do not decode by hand, do not
   "fix" the base64, do not rank it. A tape that fails the reader ranks
   nowhere, whoever asks, however close the numbers look. The seal is honesty
   rather than security, and this step is where the honesty lives.

3. **Already on the record?** Grep `docs/RANKINGS.md` for the tape's crc.
   A hit means this exact flight already landed — point at its row and stop,
   because one flight is one entry no matter how many times it is pasted.
   `tools/flights.sh` reads the same marker and would refuse the second one
   anyway (GR14), so a duplicate ranked here buys its pilot nothing and puts a
   confusing row on a page people read.

4. **Whose name is in the seat?** The reader prints a seat verdict under the
   seal. `SEAT CONFIRMED` — carry on. `SEAT MISMATCH` — the run was flown
   under a borrowed name: it ranks nowhere, keeps no best score, and puts
   nothing on the board, however good the numbers (GR12); say so and stop.
   `NO SEAT ON TAPE` (an older tape, or an unlocked cabinet) — the tape's
   pilot line is unverified: if it is not the pilot at this keyboard
   (`git config user.name`), ask one question before ranking — was this
   genuinely the named pilot's flight? Couriering a friend's real tape is
   fine and lands under the friend's name. The seal proves the tape; this
   step is what proves the pilot.

   `SEAT UNPROVEN` is the same missing seat with the benefit of the doubt
   spent: `docs/tapes/` already holds a flight where this pilot flew from a
   locked cabinet, so "no seat" cannot mean "this name never locks its own"
   any more. Removing the lock is one deleted file and it is what borrowing a
   name looks like from here. Do not rank it on your own judgement — put the
   verdict to the pilot in one sentence, name the filed flight that contradicts
   it, and let them answer. A real explanation exists (a second machine, a
   fresh clone, a tape from before they locked it) and it is theirs to give.

5. **Work out the fun numbers.** The JSON has the raw counts per seat; derive
   the ones people actually enjoy reading:

   - accuracy — `hits / shots`, as a percent. Bullets only; the bomb is not aim.
   - pace — score per minute of flight.
   - the tally of rocks by size, deaths, bombs spent, grapple throws,
     kraken hits and kills, close shaves, the longest flurry.
   - distance flown in klicks (`dist / 1000`), and top speed.
   - the ambush reel — the reader lists every event that fired: id, author,
     wave, flown clear or died inside. "Died to PINCER, Mira's, wave 3" is
     exactly the sentence the board wants; a cleared trap is the pilot's
     boast, a kill is its author's. An older tape has no reel, and that is
     not a gap to fill in by asking.

6. **Land it in `docs/RANKINGS.md`.** THE BOARD is ranked by score and keeps
   twenty rows; THE FLIGHT LOG below keeps every tape, newest first. A board
   row ends with the flight in one line — dry, specific, written from the
   numbers ("died with the bomb still in the rack" beats "great game"). Tag
   the log entry with an HTML comment holding the crc — `<!-- crc a6bfaee1 -->`
   on its own line directly under the entry, exactly the sum the reader
   printed. That marker is not decoration and it is not optional: step 3 greps
   for it, and GR14's meter counts an entry without one as a sentence somebody
   typed. A two-seat tape lands once, under the tape's pilot, and the
   line mentions the wingmate. When the tape carries an ambush reel, the
   flight log entry names each event with its author and outcome — cleared
   or fatal — so an author's public kills and clears read straight off the
   record, and the board line names the trap that ended the run when one
   did.

7. **Commit it, without asking.** Handing over the tape is the ask; a verified
   flight that sits unstaged in somebody's working tree is not on the record,
   and the pilot has already walked away. So finish the job: stage
   `docs/RANKINGS.md` and the `docs/tapes/<crc>.json` step 1 filed, nothing
   else that happens to be dirty, and commit in the same breath as ranking.
   The two land together or the row cannot be read back — the referee will say
   so, and it is right. No confirmation round, no "shall I land
   this?" — the only stops in this ritual are steps 2, 3 and 4, and a tape
   that got past those is going on the board. A ranking does not change the
   game, so it is not a version at all; it gets a subject worth reading and a
   `Chronicle:` line like everything else. Example:

   ```
   GUEST flies 4 minutes and the board notices

   Chronicle: A tape came back from the field: wave 6, 71 percent accuracy,
              and eleven close shaves that were apparently all on purpose.
   ```

## What this skill never does

- Produce a tape. The game writes them and nothing else does (GR16).
- Rank a tape the reader rejected, or numbers typed in without a tape.
- Rank a flight flown under a borrowed name. The seat on the tape is the
  pilot the run belongs to; a run flown as somebody else ranks nowhere,
  whoever asks (GR12).
- Edit an existing score, reorder the board by anything but score, or delete
  somebody's flight to make room. The log keeps everything; the board keeps
  the best twenty and drops the rest by falling off, not by being erased.
- Touch `src/` or `styles/` — reading a tape is repo work, not a version.
- Stop at the edge of the commit to ask permission. Refusing a tape is a
  decision; landing one that passed every check is just the rest of the job.
