# Pilot log

Spec §8 defines one pilot as a second real machine, provisioned from zero, on which a doctrine
rule authored on machine A visibly changes agent behaviour without local editing. This file
records every run against that definition, including the runs that only partly meet it.

## 2026-09-25 — container stratum, machine A only

| Field | Value |
|---|---|
| Ran | `tests/criteria.sh`, `tests/cold-machine.sh` |
| Host | machine A (Linux 7.0.11, bash 5.2.21, jq present, shellcheck absent) |
| Container | `debian:stable-slim`, `git` installed, no agent CLI, no `jq` |
| Result | 11 of 11 bars pass; container pass — configured in 1s, zero prompts, re-run wrote nothing |

Bars measured: cold machine 0s (bar 300s) · rule duplication 1 authored copy · cross-agent reach
3 of 3 · drift loss 0 · idempotence identical · project stamp 0s (bar 30s) · curated promotion 0
unapproved paths · hooks reach 3 linked, declared, denying · content classified 0 uncategorised ·
stratum hand-written both backed up · stratum settings merge existing keys kept.

Manual steps needed: none on a machine with `jq`. On the container, which has no `jq`, the hook
scripts link but their declaration degrades to a printed instruction — one manual step, and the
only one anywhere in the suite. That is the honest cost of hooks living in a JSON settings file.

**What this run does not prove.** The container shares this machine's kernel, filesystem
semantics and clock, and it runs the repo from a bind mount rather than a `git clone` over the
network. So it proves cold-start correctness and idempotence; it does not prove the bootstrap
one-liner, network clone, credential-free `git` access, or that a doctrine rule authored here
changes behaviour in a session started elsewhere.

**Status: pilot PENDING.** Blocked on a second physical machine or a clean VM. Until it runs, the
claim this repo makes is "configures this machine and a cold container", not "works on any
machine".

## 2026-09-27 — portability pass before the macOS pilot

Three GNU-only flags were load-bearing and would have failed on macOS: `readlink -f` (BSD
added `-f` only in 12.3), `sort -z`, and `find -printf`. `grep --exclude-dir` was a fourth,
which BSD does have. All four are gone: `lib/targets.sh` carries `rlf` and `sort0`, and the
suite now runs green under both GNU and BusyBox userlands — BusyBox lacking the same flags
that BSD lacks. 14/14 bars in each.

This lowers the odds of the macOS run failing on something trivial. It does not prove macOS:
`/Users` paths, a case-insensitive filesystem, and `/bin/bash` 3.2 are untested.

## Pending — the real pilot

When a second machine is available, run and record:

1. `curl -fsSL .../bin/bootstrap.sh | bash` on the bare machine. Stopwatch it. Count prompts.
2. `bin/inventory.sh --roles` — every detected target shows, every role has its items.
3. `tests/criteria.sh` on that machine, all bars with measured values.
4. Author a one-line doctrine rule on machine A, push, `bin/bootstrap.sh` on machine B, then a
   fresh session in each installed agent whose correct answer depends on that rule.
5. Anything that needed a hand — especially whether `jq` was present.

### On macOS specifically, note these

- `bash --version`. macOS ships 3.2 at `/bin/bash`; a newer one usually sits in Homebrew.
  Every script declares `#!/usr/bin/env bash`, so whichever is first on `PATH` runs them.
- Whether `~/Library/...` rather than `~/.claude` is where the agent keeps config.
- Case-insensitivity: `AGENTS.md` and `agents/` differ only by case in the same tree.
- `jq` present or absent — it gates the hook declaration, nothing else.
