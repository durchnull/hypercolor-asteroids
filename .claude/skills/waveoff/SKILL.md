---
name: waveoff
description: A pull request that cannot land - work out what two people moved at once, then tell the contributor on the pull request, in the book's voice, what is in the way and what clears it. Use when github says a pull request is conflicting or dirty, when a merge is refused, when somebody asks why a pull request will not go in, or to sweep every open one for the ones nobody can merge.
model: opus
effort: high
argument-hint: "[optional: a pull request number, or nothing to sweep every open one]"
allowed-tools: Bash, Read, Grep, Glob
---

# Waveoff

A landing gets waved off when the strip is not clear. Nothing is wrong with the
approach and nothing is wrong with the pilot — two things arrived at the same
patch of ground, and one of them has to come round again.

That is the whole of a merge conflict here, and it is worth saying out loud
before you write anything, because the reflex is to write to somebody as though
they broke something. They did not. They cut a branch, main moved underneath
them, and git is refusing to guess which version of a file the room meant. The
message you are about to write is a fact and a command, not a complaint.

## 1. Read the runway

```sh
tools/waveoff.sh          # every open pull request, and which cannot land
tools/waveoff.sh 39       # what is in the way, and what put it there
```

Exit 0 is clear, 1 is fouled, 2 is could-not-tell — and could-not-tell is never
reported as clear. The detail run gives you everything the message needs:

- **which paths**, and which way each came apart — `main deleted it, the branch
  changed it` is a sentence a person can act on; `CONFLICTING` is not.
- **which commit on main did it**, with its subject. This is the good bit. The
  subject line of the commit that moved the ground is usually the entire
  explanation, because subject lines here are written from the next pilot's
  seat.
- **how far behind** the branch has drifted, and whether it came from a fork.
- **whether anybody has waved it off already.** One comment per head sha. If
  the tool says *already waved off and that is still the head*, you are done —
  say so at the keyboard and post nothing. A second comment repeating the first
  is nagging, and nagging is not what the tower is for.

If the tool says it merges clean while github says otherwise, git wins and
github is behind; wait, do not write.

## 2. Find out what actually happened

The tool names the commit. Go read it — `git show --stat <sha>`, and the
`Chronicle:` line especially. A conflict is nearly always a *consequence* of
something the book already has a sentence about: a rename that swept a file
away, a generated artefact both sides regenerated, a manifest two people
appended to. Naming that in one clause is the difference between a message
worth reading and a git error with manners.

Work out what the contributor's side actually should be, and say it plainly if
it is obvious — a generated file gets regenerated rather than merged, a deleted
file stays deleted, a manifest keeps both lines. Do not present a guess as
though you had checked. If you do not know which side is right, say the merge
will ask and leave the answer to them; they wrote it.

## 3. Write it, in the book's voice

This is the part no script does, and the reason it does not: a paragraph canned
in a tool reads as canned the second time somebody receives one.

The voice is the chronicle's, and the chronicle is on `docs/` if you want a
page of it in front of you. Plain, dry, exact. Past tense for what happened,
present for what is true now. No exclamation marks — there are none anywhere in
this project and the prose is funnier for it. Never an apology, never
congratulation, never "unfortunately", never "please resolve the conflicts and
we'll take another look".

What the comment is:

1. **What is in the way**, as the thing that happened rather than as a git
   state. *v38 retired the word trap, and the badge that carried it went with
   it. Your branch repainted that badge on the way past.*
2. **The paths**, one line each, with what each side did. A list, not prose.
3. **What they run**, in a fenced block, on their clone — and if you know which
   side wins, the line that settles it.
4. **What happens after**: they push, the strip re-runs, the referee reads it
   again, and the merge button was always theirs.

What it is not:

- **Not long.** Under about 150 words. A wall of text about one file is its own
  kind of rude.
- **Not a spoiler.** GR9. The comment is public and somebody who has never
  opened this repository may read it first. Say nothing about what their branch
  does in the game, and nothing about what landed while they were flying beyond
  the one clause the conflict needs. The reveal happens in the game.
- **Not signed, and not announced as automatic.** No bot preamble, no "I am an
  agent". The cabinet has talked to itself in this voice since v1 and it does
  not introduce itself.
- **Not a ship.** The ASCII flourish belongs to a turn that ended. This is a
  turn that did not.

End the body with the marker, on its own line, exactly as the tool prints it:

```sh
tools/waveoff.sh --marker 39      # <!-- waveoff ea50101 -->
```

That is how the next run knows this approach was already answered. It carries a
sha rather than a date because a new commit is a new approach and deserves a
fresh answer, while the same commit twice deserves silence.

## 4. Post it

```sh
gh pr comment 39 --body-file <draft>       # a file, so the markdown survives
gh pr comment 39 --edit-last --body-file <draft>   # if it came out wrong
```

Write the draft in the scratchpad, not in the repository — it is a message, not
a file anybody wants in the history. Show it at the keyboard before it goes,
because it is public and it has somebody's name on it, and then send it
yourself. A comment handed over to be pasted is a chore rather than a decision.

## Never

- **Never push a fix to their branch.** Most of what arrives here is a fork and
  you cannot; when you can, that is still their work and their name on it. GR4
  counts lines, and this would be the whole approach.
- **Never merge their branch into main yourself to get round it**, and never
  push the resolution to main. GR7, red line, and a merge button exists.
- **Never resolve it in a branch of your own and open a competing pull
  request.** That is somebody's version taken off them, which is worse than the
  conflict.
- **Never close their pull request** because it is fouled. A waveoff is come
  round again, not go home.
- **Never write a second comment for a head sha that already has one.** The
  tool answers that question so nobody has to guess at it.
