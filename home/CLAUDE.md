# Claude Code entry point

This file carries no rules of its own. It exists because Claude Code reads `CLAUDE.md` in
preference to `AGENTS.md`, so it points at the two files that hold the content.

The operating contract — response style, decide-don't-interrogate, anti-drift, phase discipline,
scope guards. One authored copy, shared with every other agent:

@AGENTS.md

Machine and operator specifics — hardware, accounts, per-machine defaults. Gitignored, never
committed, created by `bin/sync.sh` from `home/profile.md.example`:

@profile.md
