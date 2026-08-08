# REQUIREMENTS

Short, on purpose. The game is one page you open; the tooling around it is
shell scripts and git. Nothing installs anything, ever.

## To play

- A browser. That is the whole list.
- Open `index.html`. If your browser is fussy about `file://`, serve it:

```sh
python3 -m http.server 8000     # Windows: py -m http.server 8000
```

- Two pilots share one keyboard. The splash screen lists the keys, and the
  field guide explains what is out there.

## To build

- **git**
- **a POSIX shell** — `sh`, `awk`, `sed`, `grep`. Everything in `tools/` and
  `.githooks/` is made of those and nothing else.
  - macOS and Linux: already there.
  - Windows: **Git Bash**, which comes with Git for Windows. WSL works too.
- **[Claude Code](https://claude.com/claude-code)** — how most turns are taken
  here. Not strictly required; you can write the files yourself.

That is it. There is no package manager, no bundler, no TypeScript, no CDN and
no network call anywhere in the game. That is GR2 in
[GOLDEN_RULES.md](../GOLDEN_RULES.md), and it is a red line — if a change seems
to need any of it, the change is wrong.

### Nice to have, never required

- **node** — the referee parse-checks changed JavaScript if it finds node. If
  it does not, that one check is skipped and nothing fails.
- **python3** — only to serve the page, if your browser refuses `file://`.
- **curl** and a Cloudflare `.env` — only for whoever paints the book's
  pictures. Without them `tools/chronicle-art.sh` exits quietly and the book
  builds as ever.

## If you are on Windows

Three things, and the second one matters.

- **Use Git Bash**, not CMD and not PowerShell. The hooks and every script in
  `tools/` are `#!/bin/sh`.

- **Set your line endings before you clone:**

```sh
git config --global core.autocrlf input
```

  Git for Windows installs with `core.autocrlf=true`, which rewrites every
  checked-out file to CRLF. A hook whose first line reads `#!/bin/sh` followed
  by a carriage return does not run — so the referee quietly stops checking
  your commits, on the one machine nobody else can see. If you already cloned
  with the default, set it and re-clone.

- **Two commands in the docs are mac-shaped.** `open index.html` is
  `start index.html`, and `python3` is usually `py`.

## Check your setup

From the repository, in a shell:

```sh
git config core.hooksPath        # must print: .githooks
tools/golden-check.sh            # must print: golden rules: clear
```

If the first prints nothing, run `tools/golden-check.sh --install` once. If the
second complains, it will tell you which rule and why — that is its job, and it
never bites.
