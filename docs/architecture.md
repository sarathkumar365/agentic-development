# Architecture — the layer model

Status: DRAFT · Date: 2026-10-01

This is the foundation every other part of the system is built against. It answers one question
for every piece of instruction content: **when does the agent see it?** Everything the operator
wants the agents to know lives in exactly one of six layers, and the layer decides when it loads.

It is the single foundation document for this repo: what the system must always be, what it
must never become, and how its content is organised.

## Invariants

These hold for every change. Code comments cite them by number.

1. **Author once, `AGENTS.md` first.** Instruction content is written once, in `AGENTS.md`. Any
   other per-agent file is a thin shim that points at it, never a second copy.
2. **Global and project rules stay distinct.** Global doctrine and project rules are separate
   inputs with separate lifecycles.
3. **One idempotent command per machine.** A new machine becomes configured with one command,
   re-runnable at any time with no manual steps.
4. **No drift, but curated promotion.** Installed config is symlinked, so a local edit shows up
   in the repo working tree at once. Nothing reaches git history automatically: a reviewer
   decides what is durable and commits only that.
5. **No central index.** Adding a skill, agent, hook or script needs no structural edit. Each item
   declares what it is for in its own header.
6. **The system improves itself.** Turning what the operator repeatedly does into a rule or a
   flow is part of the product. Invariant 4 is the path it takes.
7. **Content is the asset, plumbing is borrowed.** Effort goes into doctrine, flows and
   knowledge. Install and translation stay deliberately thin.
8. **The hub is legible.** The operator can see what the system holds without reading the tree.
   Any view is generated from the repo and never a second place the truth lives.
9. **Nothing installs into an unverified format.** Supporting an agent is a deliberate
   declaration of what it reads. Finding a directory is not evidence of a format.

## Non-goals

- Secrets management. The repo is public.
- A dotfiles manager. Agent configuration only.
- Machine provisioning beyond recording machine facts in `profile.md`.
- A general cross-agent sync or translation engine. Existing MIT tools already do that.
- Lossless translation of skills, hooks and subagents between agents.
- Autonomous build-it-for-me flows.
- Auto-applied rule changes.

## Why layers

An agent can follow only so many instructions at once. Frontier models follow roughly 150–200
with reasonable consistency, the agent's own system prompt already spends about 50 of them, and
every added rule dilutes all the others evenly. A single growing `AGENTS.md` therefore gets worse
the more it is improved.

The fix is progressive disclosure: a small core that is always present, and everything else loaded
only when the task in front of the agent needs it. The layers are that mechanism.

## The six layers

| # | Layer | What lives there | When it loads | Works for |
|---|---|---|---|---|
| 1 | **Core** — `AGENTS.md` | How the operator works on every task: response depth and tone, decide vs ask, minimal code, correct with evidence, explain the why. The routing principle. | Every session | All agents |
| 2 | **Flows** — `skills/<flow>/SKILL.md` | How one kind of task runs: its steps, its depth, its gates, when it asks and when it decides. `feature`, `debug`, `refactor`, `review`, `explain`, `new-project`, `validate-idea`. | When the task matches the flow's description | All agents that read skills |
| 3 | **Domain knowledge** — `skills/<flow>/reference/<topic>.md` | Language and framework conventions: TypeScript, Python, React. | Only when that language or framework is involved | All agents that read skills |
| 4 | **Project** — `<project>/AGENTS.md` and `<project>/docs/` | That project's commands, architecture and conventions. | Inside that project; the nearest file wins | All agents |
| 5 | **Enforcement** — hooks, linters, tests | What must hold no matter what the model decides: no secret-file reads, no destructive git, code passes lint and tests. | Always, automatically | Per agent (hooks are agent-specific) |
| 6 | **Learning loop** — `evolve`, `learn`, `evals/`, `curator` | How the other five improve: capture a miss, propose a change to the right layer, prove it with an eval, operator approves, sync. | On demand, or weekly | All agents |

Layers 1–3 are global and synced from this repo. Layer 4 lives in each project's own repo.
Layer 5 is partly here (hooks) and partly in each project (its linter and tests). Layer 6 is the
only layer that writes to the others.

## How the layers connect

```
  this repo (layers 1, 2, 3, 5-hooks, 6)
        │  bin/sync.sh — every machine, every agent
        ▼
  agent config dirs (~/.claude, ~/.codex)
        │  a task arrives
        ▼
  ┌─────────────────── one session ───────────────────┐
  │ core (always) → flow (by task) → knowledge (by    │
  │ language) + project rules (by directory)          │
  │                                                   │
  │ operator approves the plan before code changes    │
  │ enforcement blocks unsafe actions regardless      │
  └──────────────┬────────────────────────┬───────────┘
                 ▼                        ▼
        output: code + why        evidence: corrections,
        (operator learns)         repeats, misses
                                          │ learning loop
                                          ▼
                                  proposal → eval → operator
                                  approves → commit → sync
                                          │
                                          └──► back to this repo
```

Four rules hold the loop together:

1. **One source, many readers.** Content is authored once here. Agents only read it. Cross-machine
   and cross-agent consistency is a consequence of that, not extra work.
2. **The operator is the gate twice.** Once at the plan, before code changes. Once at a rule
   change, before the system changes itself. Everything else is automatic.
3. **Prose suggests, enforcement guarantees.** Anything that must hold every time belongs in
   layer 5, not in a sentence in layers 1–4.
4. **Every session produces two outputs.** The work, with its reasoning, teaches the operator.
   The evidence of where the agent missed teaches the system.

## Routing

The core does not keep a table of flows. Invariant 5 rules out a central index of content: each
item declares what it is for in its own header. So routing works the way
skills already work. Every flow's `description` says what task it handles and what phrases
trigger it. The agent picks the flow whose description matches the task. When none matches, the
task is treated as quick: act, verify, report in one line.

The core states that principle in a few lines. It never lists the flows. Adding a flow therefore
needs no edit to the core.

## Where a new rule goes

Ask in order and stop at the first yes.

1. Must it hold every time, whatever the model decides? → **Layer 5.** Write a hook, a lint rule
   or a test.
2. Is it true of one project only? → **Layer 4.** That project's `AGENTS.md` or `docs/`.
3. Is it about one language or framework? → **Layer 3.** A reference file under the flow that
   needs it.
4. Is it about how one kind of task runs? → **Layer 2.** That flow's `SKILL.md`.
5. Does it apply to every task in every project? → **Layer 1.** The core — and only if it earns
   its place against the budget below.

If it fits none of these, it is not a rule yet. Leave it out.

## Budgets

| Layer | Limit | Why |
|---|---|---|
| Core | under 80 lines | It loads into every session and competes with everything else |
| Flow `SKILL.md` | under 500 lines | Anthropic's skill guidance; split into reference files past that |
| Reference files | one level deep from `SKILL.md` | Agents may read nested references only partially |
| Project `AGENTS.md` | under 200 lines | Claude Code's guidance for a single instruction file |

A layer over budget is a signal that content belongs in a lower layer.

## Portability

| Mechanism | Claude Code | Codex |
|---|---|---|
| `AGENTS.md` core | yes, through `CLAUDE.md` import | yes, natively |
| Skills (flows + references) | yes | yes |
| Nested project `AGENTS.md` | yes | yes |
| Hooks | yes | not used — format unverified |
| Path-scoped rules (`~/.claude/rules/`) | yes | no |

Layers 1–4 use only the mechanisms both agents share. Agent-specific mechanisms — hooks,
path-scoped rules — are optional extras and never the only place a rule lives, except in layer 5,
where enforcement is agent-specific by nature.

## Built and not built

| Piece | State |
|---|---|
| Sync to every agent and machine | built |
| Core `AGENTS.md` | built, but over-scoped: it carries the idea pipeline and scope guards, which belong in a flow |
| Flows | idea pipeline only (`idea-lock` … `project-init`, `new-idea`); no coding flows yet |
| Domain knowledge | none |
| Project layer | built (`bin/stamp.sh`) |
| Enforcement | three hooks for Claude Code |
| Learning loop | `evolve`, `capture.sh` and `curator` built; `learn` and `evals/` not built |

## Sources

- HumanLayer, *Writing a good CLAUDE.md* — instruction-count limits and uniform degradation
- Anthropic, *Skill authoring best practices* — descriptions as routing, 500-line body, one-level references, evaluations first
- Claude Code docs, *How Claude remembers your project* — 200-line target, path-scoped rules, nested loading, hooks as enforcement
- AGENTS.md specification — nested files, nearest wins
- Anthropic research, *How AI assistance impacts the formation of coding skills* — why flows explain the why instead of only delegating
