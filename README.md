# Agentic Development

A portable, evolving workbench for AI coding agents. One git repo is the source of truth; any
machine becomes a fully configured workstation with one command; improvements made while working
flow back automatically.

Built for Claude Code first, structured so other agents (Codex, Cursor, Copilot) plug into the
same content.

## Install on a new machine

```bash
curl -fsSL https://raw.githubusercontent.com/sarathkumar365/agentic-development/main/bin/bootstrap.sh | bash
```

Clones the repo, links it into `~/.claude/`, creates a per-machine `profile.md`, and reports
anything still missing. Idempotent — re-run it any time to update.

Lighter alternative, skills and agents only, no doctrine or templates:

```bash
claude plugin marketplace add sarathkumar365/agentic-development
```

## The three properties this is built for

| Property | Mechanism |
|---|---|
| Works on any machine | `bin/bootstrap.sh` — one command, no manual steps. Also installable as a Claude Code plugin marketplace. |
| Migrates and installs itself | Bootstrap detects missing prerequisites, clones, links, and seeds the machine profile from detected hardware. |
| Evolves | `bin/sync.sh` symlinks rather than copies, so edits made while working are already repo changes. `bin/capture.sh` adopts, commits and pushes them. The `evolve` skill decides where a learning belongs. |

The symlink choice is the load-bearing one. A copy-based sync is one-way: work done on machine B
is silently lost on the next sync. Symlinked, `~/.claude/skills/foo` *is*
`~/agentic-development/skills/foo`, so there is no drift to reconcile.

## Layout

```
agentic-development/
├── .claude-plugin/
│   ├── marketplace.json         # makes this repo installable as a plugin marketplace
│   └── plugin.json
├── skills/                      # → ~/.claude/skills/   (also the plugin's skills)
├── agents/                      # → ~/.claude/agents/
├── commands/                    # → ~/.claude/commands/
├── home/
│   ├── CLAUDE.md                # → ~/.claude/CLAUDE.md — global doctrine, public-safe
│   └── profile.md.example       # → ~/.claude/profile.md — machine-specific, gitignored
├── templates/project-skeleton/  # stamped into new repos by init.sh
└── bin/
    ├── bootstrap.sh             # new machine, one command
    ├── sync.sh                  # link repo into ~/.claude (--copy, --dry-run, --status)
    └── capture.sh               # commit and push what changed, adopt loose files
```

## What ships

### Doctrine — `home/CLAUDE.md`

Loaded into every session on every project. Response style, decide-don't-interrogate, anti-drift,
phase discipline, scope guards. Personal and machine facts are split into `profile.md`, which is
gitignored — this repo is public.

### The idea-to-product pipeline

Six gated phases. One phase per turn, an approval gate between each, so validation never slides
into architecture inside the same reply.

| Phase | Skill | Artefact | Gate |
|---|---|---|---|
| 0 Lock | `idea-lock` | `docs/idea-contract.md` | Lock this, or amend it? |
| 1 Proof | `market-proof` | `docs/market-landscape.md` | BUILD / NARROW / KILL |
| 2 Spec | `product-spec` | `docs/product-spec-v1.md` | Veto anything? |
| 3 Stack | `stack-decide` | `docs/stack-v1.md` | Veto any row? |
| 4 Blocks | `block-plan` | `docs/build-plan-v1.md` | Start B0? |
| 5 Init | `project-init` | repo + private GitHub remote | Build B0? |

`new-idea` orchestrates all six. Say "just do it" for the fast path: every phase runs on
defaults, one consolidated report, a single veto at the end.

### Other skills

- `evolve` — turn a session learning into a tracked change, then commit and push it.
- `consult` — senior-engineer thinking partner for feature, bug, audit and replan work.

### Agents

- `drift-check` — audits a plan or diff against the locked idea contract. Reports
  `VIOLATION / SCOPE-CREEP / UNSTATED / DROPPED / RE-LITIGATED`, one line each. Never proposes fixes.
- `market-scout` — parallel research fan-out returning compressed cited evidence, no verdict.

### Project skeleton

```bash
~/agentic-development/templates/project-skeleton/init.sh [target]
```

Stamps `AGENTS.md` (cross-agent working agreement), `CLAUDE.md` (imports it, adds Claude-specific
rules), the `Docs/` tree, and `.claude/settings.json` safety hooks. Refuses to overwrite an
existing `AGENTS.md`.

## Daily commands

```bash
~/agentic-development/bin/sync.sh --status    # what is linked, diverged, or untracked
~/agentic-development/bin/capture.sh          # push what this machine learned
~/agentic-development/bin/bootstrap.sh        # pull what other machines learned
```

Skills and agents load at session start — restart Claude Code after syncing.

## Conventions

- Anything in `skills/`, `agents/`, `commands/` must be **portable across projects**. Refer to
  convention paths (`AGENTS.md`, `docs/`) relatively, and handle their absence gracefully.
- Anything tied to one codebase belongs in that project's `.claude/skills/`, not here.
- `templates/` files stay self-contained and language-agnostic.
- This repo is public: no secrets, no tokens, no transcripts, no personal machine details.
  Those go in `~/.claude/profile.md`, which is gitignored.

## Deliberately not here

`~/.claude/projects/` (transcripts), `~/.claude/statsig/`, `~/.claude/todos/`, `backups/`,
`session-env/`, credentials of any kind, and project-specific skills.
