---
name: fairplay
description: Audit whether this is still fair - who has landed what, who owns which parts of the game, who has been spending overrides, whether anyone's feature is being quietly nerfed, and whether the game itself is still winnable and losable. Use when the user asks if things are balanced or fair, who is doing what, for a leaderboard, or before a session where several people have been landing versions.
model: opus
effort: high
argument-hint: "[optional: a pilot's name, or 'pilots' / 'game' to audit only one half]"
allowed-tools: Bash, Read, Grep, Glob
---

# Fair play

Two kinds of fairness live in this project and both drift if nobody looks.
Report on both, in that order, in about fifteen lines total.

## Fair between the pilots

```sh
git shortlog -sn --no-merges
git log --format='%an' --since="2 months ago" | sort | uniq -c | sort -rn
git log --format='%an' --grep='Golden-Rule-Override' -i | sort | uniq -c | sort -rn
tools/tally.sh --roll                    # the same thing, counted, and what it costs
git log --format='%an %s' --grep='Rule-Change' -i
```

Who owns what — the author of the commit that created a file owns it:

```sh
for f in src/entities/*.js src/game/*.js src/audio/*.js styles/*.css; do
  printf '%-34s %s\n' "$f" "$(git log --follow --diff-filter=A --format='%an' -- "$f" | tail -1)"
done
```

Who has been editing whose:

```sh
git log --since="2 months ago" --format='%h %an' --name-only
```

Look for the things that make a shared project stop being fun:

- **One pilot owning everything.** If most of `src/features/` traces back to
  one person, say so and suggest the others take the next surprise.
- **Overrides pooling.** Budgets are meant to be spent occasionally by
  everybody. One name on every override line is a pattern, not a coincidence —
  and it is in the book, so it is already public. Note the tally alongside it:
  the cabinet has already priced that pattern in, so this is an observation to
  make once, not a case to prosecute.
- **A tally nobody mentioned.** Somebody flying at three or more bends has their
  own events armed against them and a field that comes for them faster. That is
  the rule working, but it is worth saying out loud if they have not noticed
  why the game got harder.
- **Somebody's feature being steadily whittled down** by other people's
  commits. Each edit passed GR4 on its own; twenty of them did not.
- **A pilot who has gone quiet.** Not a problem to fix, but worth mentioning to
  whoever is at the keyboard.
- **Rule changes that widened somebody's own room.** Check every
  `Rule-Change:` against who wrote it and what they landed next.

State it as observation, never as accusation. "Dave owns nine of the eleven
features" is useful. "Dave is hogging the project" is not, and is probably
wrong — usually it just means Dave was the only one with a free evening.

## Fair in the game

Read the features and answer honestly, because the referee cannot (GR8):

- Is there any combination that makes the player effectively invincible, or the
  game unloseable? Stack the powers in your head: bomb plus grapple plus
  portal, all at once, in a late wave.
- Does every power still cost something — a cooldown, a finite count, a risk?
- Are both seats equal? Every control player one has, player two has.
- Can the player see the thing that kills them coming, or does it arrive from
  off-screen with no tell?
- Does it still hold frames? Count what draws per entity per frame; the bloom
  pass is not free and neither is anything using `shadowBlur`.
- Is the difficulty curve still a curve? Plot what each wave adds.

If something is out of balance, propose the *smallest* correction and check
whose feature it touches before suggesting it. A rebalance that guts somebody's
work is a GR4 problem wearing a GR8 costume.

## Report

A short leaderboard, then the honest answer to "is the game still good", then
at most three suggestions. Nobody wants a fifty-line audit of a game about
shooting rocks.
