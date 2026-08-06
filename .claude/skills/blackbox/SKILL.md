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

## The ritual

1. **Save the paste verbatim** to a scratchpad file — never into the repo —
   and run the reader:

   ```sh
   sh tools/blackbox.sh <file>     # or: pbpaste | sh tools/blackbox.sh
   ```

2. **Seal broken or no tape?** Say so and stop. Do not decode by hand, do not
   "fix" the base64, do not rank it. A tape that fails the reader ranks
   nowhere, whoever asks, however close the numbers look. The seal is honesty
   rather than security, and this step is where the honesty lives.

3. **Already on the record?** Grep `docs/RANKINGS.md` for the tape's crc.
   A hit means this exact flight already landed — point at its row and stop,
   because one flight is one entry no matter how many times it is pasted.

4. **Work out the fun numbers.** The JSON has the raw counts per seat; derive
   the ones people actually enjoy reading:

   - accuracy — `hits / shots`, as a percent. Bullets only; the bomb is not aim.
   - pace — score per minute of flight.
   - the tally of rocks by size, deaths, bombs spent, grapple throws,
     kraken hits and kills, close shaves, the longest flurry.
   - distance flown in klicks (`dist / 1000`), and top speed.

5. **Land it in `docs/RANKINGS.md`.** THE BOARD is ranked by score and keeps
   twenty rows; THE FLIGHT LOG below keeps every tape, newest first. A board
   row ends with the flight in one line — dry, specific, written from the
   numbers ("died with the bomb still in the rack" beats "great game"). Tag
   the log entry with an HTML comment holding the crc, which is what step 3
   greps for. A two-seat tape lands once, under the tape's pilot, and the
   line mentions the wingmate.

6. **Commit it** — `docs/RANKINGS.md` alone, nothing else that happens to be
   dirty. A ranking does not change the game, so it gets no `Version:` line;
   it gets a subject worth reading and a `Chronicle:` line like everything
   else. Example:

   ```
   GUEST flies 4 minutes and the board notices

   Chronicle: A tape came back from the field: wave 6, 71 percent accuracy,
              and eleven close shaves that were apparently all on purpose.
   ```

## What this skill never does

- Rank a tape the reader rejected, or numbers typed in without a tape.
- Edit an existing score, reorder the board by anything but score, or delete
  somebody's flight to make room. The log keeps everything; the board keeps
  the best twenty and drops the rest by falling off, not by being erased.
- Touch `src/` or `styles/` — reading a tape is repo work, not a version.
