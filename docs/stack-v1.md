# Stack v1 — agentic-development
Traces to: product-spec-v1.md

Deviation note: the standing defaults (Python, SQLite, hosted models, `uv`/`ruff`/`pytest`,
docker-compose) assume an application. This is config plumbing that must run on a machine before
any runtime is installed — spec §3 hard constraint. Every default below is deviated from for that
one reason, stated once here rather than repeated per row.

## Decision table

| Layer | Choice | Why (traces to spec §) | Rejected + reason | Licence | Swap cost |
|---|---|---|---|---|---|
| Language | Bash 4.0+, no `set -u` reliance on associative arrays | §3 zero-dependency bootstrap; present on every target machine before anything else. Frozen in §9 | Python — not guaranteed present on a cold machine, and version skew is the classic bootstrap failure. Go — needs a toolchain or a per-platform release pipeline, over the §7 complexity cap. `sh`/POSIX — `/bin/sh` is dash here, and POSIX-only costs readability for no portability gain on Linux+macOS | GPL (bash itself; we ship no bash code under it) | Hard — but the code is ~500 lines, so a rewrite is days |
| Shell target | `#!/usr/bin/env bash`, never `#!/bin/sh` | `/bin/sh` → dash on this machine; bashisms would fail silently | Invoking via `sh script.sh` — same failure | — | Trivial |
| Instruction format | Markdown, `AGENTS.md` shape | Contract invariant 1. Open standard, read by 30+ agents natively | YAML/TOML source rendered to Markdown — a build step and a second format for content that is already Markdown at both ends | Spec open (AAIF) | Trivial |
| Composition mechanism | File import directive in the agent file (`@path`), not text concatenation | Ship criterion "rule duplication = 1" — an import is a pointer, a concat is a copy | Concatenation at install time — produces a second authored-looking copy and fails the metric. Templating engine — a dependency for string substitution | — | Easy |
| Install mechanism | Symlinks from agent config dirs into the repo | §9 frozen: no-drift is a property. A symlinked file *is* the repo file, so there is nothing to reconcile | Copy + reconcile (`agentsync` model) — rejected in spec §3; also needs conflict resolution code we would own. `git` worktree per target — heavier and still copies | — | Medium — the no-drift property is frozen, the mechanism is not |
| Transport | Plain `git` + GitHub, public repo | §3, §4. Already the case; nothing else needed to move content between machines | chezmoi — a dependency and a template language for a job four scripts do. `agentsync` — deferred, see spec §11 | — | Trivial |
| Repo | Existing monorepo `sarathkumar365/agentic-development`, public | Contract v0.2: evolve, do not replace. Public is frozen in §9 | Split content/tooling repos — two clones on every machine for one operator | — | Hard |
| Machine-specific data | Gitignored `~/.claude/profile.md`, seeded from `profile.md.example` | §4: public repo, no machine facts in git. Already working | chezmoi templates — dependency. Env vars — not durable across sessions | — | Trivial |
| Structured data (settings, manifests) | `jq` where JSON must be edited, with a guard that degrades gracefully when absent | Agent settings files are JSON; hand-rolled sed on JSON is the classic corruption bug | Python `json` — reintroduces the runtime dependency. `sed`/`awk` on JSON — unsafe | MIT | Easy |
| Tests | Plain bash script under `tests/`, run against a scratch `HOME` | Ship criteria §6 need a repeatable harness; a temp `HOME` is the only honest way to test a cold machine | `bats` — not installed, adds a dev dependency for assertions a function provides. Manual testing — cannot satisfy "byte-identical on re-run" | — | Easy |
| Lint | `shellcheck` if present, skipped with a notice if not | Catches the quoting and word-splitting bugs that break installers on paths with spaces | Mandatory shellcheck — would make the repo unusable on a machine that lacks it, contradicting §3 | GPL-3.0 (dev tool only, never shipped or linked) | Trivial |
| CI | GitHub Actions running the test script and shellcheck | Free for public repos; the only place shellcheck can be made mandatory without burdening a cold machine | No CI — the idempotence and duplication bars would then be unverified claims | — | Trivial |
| Models / GPU | None | No inference anywhere in v1. LLM-assisted setup is spec §11, not in v1 | — | — | — |

## Local feasibility

```
GNU bash, version 5.2.21(1)-release (x86_64-pc-linux-gnu)
git version 2.43.0
Linux 7.0.11-76070011-generic
/bin/sh -> dash
jq: present at /usr/bin/jq
shellcheck: absent
bats: absent
Mem: 15 GiB total, 8 GiB available
```

GPU and VRAM are not applicable — v1 runs no models, so the 8 GB VRAM constraint that governs
other projects does not bind here. Memory and disk are non-constraints for shell scripts.

Two real findings: `/bin/sh` is dash, so every script must declare bash explicitly; and
`shellcheck` is absent locally, which is why it is optional in the scripts and mandatory only in
CI.

## Cost model at pilot scale
Zero. Public GitHub repo, GitHub Actions free for public repositories, no hosted services, no
inference, no storage beyond the clone. The only budget is spec §7's complexity cap: `bin/` under
500 lines total, currently 267 across three scripts.

## Licence register
| Component | Licence | Mitigation |
|---|---|---|
| bash | GPL-3.0 | Interpreter only. We distribute no bash source under it; our scripts are our own. |
| shellcheck | GPL-3.0 | Development and CI only. Never invoked by the installer, never shipped. |
| jq | MIT | Permissive, no action. |
| `AGENTS.md` spec | Open (Linux Foundation / AAIF) | No action. |
| `agentsync`, `agent-dotfiles`, chezmoi | MIT / MIT / Apache-2.0 | Not dependencies in v1. All permissive if adopted later. |

No AGPL anywhere. No research-only or non-commercial terms.

## Interfaces that isolate vendors
The vendors here are agent products, and each has its own config layout. Three seams keep that
knowledge in one place:

- **Target adapter** — one small file or function per agent, holding only that agent's paths and
  its import syntax (`~/.claude/CLAUDE.md` + `@import` vs `~/.codex/AGENTS.md`). Adding Cursor
  later is a new adapter, not a change to the installer.
- **Link layer** — the single function that creates a link, backs up a pre-existing real file,
  and is idempotent. Swapping symlinks for copy+reconcile touches this function only, which is
  what keeps the §9 mechanism swappable while the property stays frozen.
- **Content root** — `skills/`, `agents/`, `commands/` are addressed by role, not by Claude's
  directory names, so an agent that organises them differently maps in its adapter.

## Deferred
| Decision | Becomes due |
|---|---|
| Whether to adopt `agentsync` as transport | When it reaches v1.0 or ~500 stars. Re-run the spec §3 comparison then |
| Windows / WSL support | First time the operator works on a Windows machine. Bash assumption holds under WSL; native PowerShell would be a rewrite |
| macOS-specific paths | First macOS machine. Expect only path and `readlink`/`sed` flag differences |
| MCP server definition format | Spec §11 — not in v1 |
| Per-agent hook and settings translation | Spec §11 — not in v1 |
| Whether `commands/` needs a Codex equivalent | At the block that implements the Codex adapter; depends on what Codex actually reads |
