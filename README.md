# Agentic Development

One repo holding how the operator's AI coding agents behave, installed onto any machine with one
command, improved by a curator rather than by an indiscriminate sync.

The content is the point: doctrine, a phase-gated idea pipeline, review agents, a project
skeleton. The plumbing under it is deliberately thin — around 500 lines of bash — because
[`AGENTS.md`](https://developers.openai.com/codex/guides/agents-md) is now an open standard that
most agents read directly, and cross-agent sync engines already exist under MIT. Rebuilding
either would be duplicating free software. See [docs/market-landscape.md](docs/market-landscape.md)
for the evidence and the resulting NARROW verdict.

## Install on a new machine

```bash
curl -fsSL https://raw.githubusercontent.com/sarathkumar365/agentic-development/main/bin/bootstrap.sh | bash
```

Clones the repo, links it into every agent it finds, creates a per-machine `profile.md`, and
reports anything still missing. Idempotent — re-run it any time.

Lighter alternative, skills and agents only, no doctrine or templates:

```bash
claude plugin marketplace add sarathkumar365/agentic-development
```

## How it works

Three mechanisms, each answering one requirement.

| Requirement | Mechanism |
|---|---|
| A rule is written once, not once per agent | `AGENTS.md` at the repo root is the only authored copy. An agent that reads it natively gets a symlink; an agent that prefers its own filename gets a stub that imports it. Never a second copy of the rules. |
| Any machine, one command | `bin/bootstrap.sh` clones and calls `bin/sync.sh`, which detects which agents are installed and links content into each. Nothing beyond `git` and `bash` is required. |
| Nothing is lost, nothing unwanted is kept | `sync.sh` symlinks, so an edit made while working is immediately a change in this repo's working tree. But nothing reaches git history on its own — the `curator` agent reads what accumulated and proposes only what is durable. |

The symlink choice is the load-bearing one. A copy-based sync is one-way: work done on machine B
is silently lost on the next sync. Symlinked, `~/.claude/skills/foo` *is*
`~/agentic-development/skills/foo`, so there is no drift to reconcile — only a decision about
what deserves to be committed.

## Targets

Adding an agent is one row in [`lib/targets.sh`](lib/targets.sh) and no other edit anywhere.

| Agent | Config root | Doctrine lands as | Takes |
|---|---|---|---|
| Claude Code | `~/.claude` | `CLAUDE.md` importing `AGENTS.md` | skills, agents, commands |
| Codex CLI | `$CODEX_HOME` or `~/.codex` | `AGENTS.md` by direct symlink | skills |

```bash
bin/sync.sh --targets     # which of them exist on this machine
```

## Layout

```
agentic-development/
├── AGENTS.md                    # the doctrine — the single authored copy
├── lib/targets.sh               # the agents installed into, and their paths
├── skills/                      # → each agent's skills directory
├── agents/                      # → ~/.claude/agents/
├── commands/                    # → ~/.claude/commands/
├── home/
│   ├── CLAUDE.md                # a stub importing AGENTS.md and profile.md
│   └── profile.md.example       # → ~/.claude/profile.md — machine-specific, gitignored
├── templates/project-skeleton/  # stamped into new repos by bin/stamp.sh
├── tests/
│   ├── criteria.sh              # the ship criteria as executable checks
│   └── cold-machine.sh          # the same, in a container with nothing installed
└── bin/
    ├── bootstrap.sh             # new machine, one command
    ├── sync.sh                  # link the repo into every detected agent
    ├── capture.sh               # survey, adopt, commit — never all three at once
    └── stamp.sh                 # write a project's AGENTS.md and per-agent stubs
```

## What ships

### Doctrine — `AGENTS.md`

Response style, decide-don't-interrogate, anti-drift, phase discipline, scope guards. Read by
every agent, on every project. Personal and machine facts live in `profile.md`, which is
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

`new-idea` orchestrates all six. This repo's own `docs/` are the output of running it on itself.

### Other skills

- `evolve` — promote one identified learning into a tracked change.
- `consult` — senior-engineer thinking partner for feature, bug, audit and replan work.

### Agents

- `curator` — reads the machine's accumulated edits, classifies each as durable, correction,
  noise, personal or unclear, and proposes what to promote. Never commits on its own.
- `drift-check` — audits a plan or diff against the locked idea contract. Reports
  `VIOLATION / SCOPE-CREEP / UNSTATED / DROPPED / RE-LITIGATED`, one line each.
- `market-scout` — parallel research fan-out returning compressed cited evidence, no verdict.

### Project skeleton

```bash
bin/stamp.sh /path/to/repo
```

Writes the project's `AGENTS.md`, the `Docs/` tree and `.claude/settings.json` safety hooks, plus
a pointer stub for each agent that needs its own filename. Refuses to overwrite an existing
`AGENTS.md`.

## Daily commands

```bash
bin/sync.sh --status    # what is linked, diverged, or untracked
bin/capture.sh          # survey what this machine changed — commits nothing
bin/bootstrap.sh        # pull what other machines learned
```

Promotion is two deliberate steps, never one:

```bash
bin/capture.sh --adopt ~/.claude/skills/new-thing
bin/capture.sh --commit -m "feat(skills): add new-thing"
```

There is no flag that commits everything under a generated message. Ask the `curator` agent to
read the survey when you do not yet know what is worth keeping.

Skills and agents load at session start — restart the agent after syncing.

## Verification

```bash
tests/criteria.sh       # the ship criteria, with measured values
tests/cold-machine.sh   # a container with neither agent installed (skips without docker)
```

The bars come from [docs/product-spec-v1.md](docs/product-spec-v1.md) §6 and are enforced in CI:
time to a configured cold machine, exactly one authored copy of any rule, every target on one
doctrine, zero edits lost, a byte-identical tree on re-run, project rules in effect within 30
seconds, and zero unapproved commit paths.

Still unproven: the two-machine pilot. The container covers the cold-start case, but "works on
any machine" is not claimed until this has been installed from zero on a second physical
machine.

## Conventions

- Anything in `skills/`, `agents/`, `commands/` must be **portable across projects**. Refer to
  convention paths (`AGENTS.md`, `docs/`) relatively, and handle their absence gracefully.
- Anything tied to one codebase belongs in that project's own config, not here.
- `templates/` files stay self-contained and language-agnostic.
- This repo is public: no secrets, no tokens, no transcripts, no personal machine details.
  Those go in `~/.claude/profile.md`, which is gitignored.

## Deliberately not here

A general multi-agent config translation or sync engine — [`agentsync`](https://github.com/spxrogers/agentsync)
and [`agent-dotfiles`](https://github.com/saqibameen/agent-dotfiles) already ship one under MIT,
and `AGENTS.md` removed most of the need. Lossless cross-agent translation of skills and hooks,
which nobody has solved. Secrets management, dotfile management for shell or editor, machine
provisioning. And `~/.claude/projects/`, `statsig/`, `todos/`, `backups/`, `session-env/`, and
credentials of any kind.
