---
name: evolve
description: Turn something learned in this session into a durable change to the agent system — a new skill, an amended doctrine rule, a corrected default, or a project invariant — then commit and push it so every machine gets it. Use when the user says "remember this", "don't do that again", "add this to the system", "make this permanent", "/evolve", or after correcting the same behaviour twice.
---

# Evolve

The system only gets better if corrections outlive the session. This skill converts a
correction, a discovery, or a repeated friction into a tracked change in
`~/agentic-development`, then pushes it.

## Step 1 — Classify what was learned

Pick exactly one target. Wrong target is the common failure: a one-off preference written as a
new skill is clutter, and a repeated workflow written as a memory is forgotten.

| Learning | Target | Where |
|---|---|---|
| A rule about how I should behave, always | Doctrine | `AGENTS.md` |
| A fact about this operator or machine | Profile | `~/.claude/profile.md` (never committed) |
| A repeatable multi-step workflow | New or edited skill | `skills/<name>/SKILL.md` |
| A read-only audit or research routine | Agent | `agents/<name>.md` |
| A constraint true only for one project | Project instructions | that repo's `CLAUDE.md` |
| A fact about one project's history | Memory | that project's memory dir |
| A default that turned out wrong | Edit in place | wherever it was stated |

If it fits nowhere, it is not a learning yet. Say so instead of inventing a home for it.

## Step 2 — Write it as a rule, not a story

Bad: "The user got annoyed when I asked lots of questions."
Good: "Cap blocking questions at 5 per turn, each with a proposed default."

Every durable entry carries:

- **The rule** — imperative, one or two lines.
- **Why** — the concrete incident, dated. Without it the rule gets deleted by a future reader
  who does not know what it prevents.
- **How to apply** — the trigger that should fire it.

## Step 3 — Prefer editing over adding

Check for an existing home first:

```bash
grep -rn "<keyword>" ~/agentic-development/AGENTS.md ~/agentic-development/skills/
```

Amending an existing rule beats a new file almost every time. A system with forty overlapping
skills is worse than one with eight sharp ones. If a new skill is genuinely warranted, say in one
line why no existing skill covers it.

## Step 4 — Commit and propagate

```bash
~/agentic-development/bin/capture.sh --commit -m "<conventional commit message>"
```

One learning, one commit, one message naming it. `capture.sh` with no flags surveys instead —
use that when you do not yet know what is worth keeping, or hand the survey to the `curator`
agent, which classifies everything in the working tree and proposes what to promote. Loose
content created directly in an agent directory is adopted first with `--adopt <path>`.

There is no path that commits everything with a generated message. That is deliberate.

Commit messages are normal English, Conventional Commits style — they are read by humans later.

## Step 5 — Report

Three lines, no more:

```
Learned: <the rule>
Written to: <file>
Pushed: <commit sha> — live on every machine after bootstrap.sh
```

## Discipline

- One learning per invocation. Batching produces vague rules that fire on nothing.
- Never write a rule that only restates a default the model already follows.
- A rule that has never fired after a month is noise — say so when you notice one.
- Personal or machine facts go to `profile.md`, which is gitignored. This repo is public.
- Curating a whole machine's accumulated edits is the `curator` agent's job, not this skill's.
  This skill promotes one learning you already identified.
