# Agentic Development

Personal config repo for AI coding agents (Claude Code, Codex, Copilot, Cursor, future ones). Single source of truth; sync to each agent's expected location with a script.

## Why this exists

- Different agents read config from different places (`~/.claude/`, `~/.codex/`, etc.) but my workflow doesn't change between them. I want one place to author skills, commands, agents, and project templates, and one command to push them out to wherever they need to live.
- Backed by git so the work survives machine changes, accidents, and "I deleted that, didn't I."
- Project templates so every new repo gets a consistent starting layout (`AGENTS.md`, `Docs/` tree, safety hooks).

## Layout

```
agentic-development/
├── claude/                      # mirror of ~/.claude/
│   ├── skills/
│   │   └── consult/             # senior-engineer thinking-partner skill
│   ├── commands/
│   │   └── consult.md           # /consult slash command
│   └── agents/                  # custom subagents (empty for now)
├── codex/                       # mirror of ~/.codex/  (when used)
├── shared/                      # agent-agnostic content
├── templates/
│   └── project-skeleton/        # standard layout for any new project
│       ├── files/               # what gets stamped into the project
│       │   ├── AGENTS.md
│       │   ├── Docs/
│       │   └── .claude/settings.json   # safety hooks
│       └── init.sh              # the stamp script
└── bin/
    └── sync.sh                  # push claude/ → ~/.claude/, codex/ → ~/.codex/, etc.
```

## Two commands you'll actually run

### Sync personal config out to the agents

After editing anything under `claude/` (or `codex/`, etc.):

```bash
~/agentic-development/bin/sync.sh
```

Additive by default — won't delete anything in `~/.claude/` that isn't tracked here. Pass `--clean` to mirror exactly (deletes destination files not in source).

### Stamp the standard layout into a new project

In a fresh repo:

```bash
~/agentic-development/templates/project-skeleton/init.sh
```

Or target a specific directory:

```bash
~/agentic-development/templates/project-skeleton/init.sh ~/Projects/new-thing
```

Refuses to overwrite an existing `AGENTS.md` so you can't accidentally clobber real work.

## Adding a new agent

When you start using a new agent (say Codex):

1. `mkdir codex/` and put its config there in the layout it expects under `~/.codex/`
2. Uncomment `sync_agent codex` in `bin/sync.sh`
3. Run `bin/sync.sh`

## Adding a new skill / command / template

1. Author it under the appropriate subdir (e.g. `claude/skills/<name>/SKILL.md`)
2. `bin/sync.sh`
3. Restart your agent (skills/commands are picked up at session start)
4. Commit and push so it survives

## Conventions

- Anything under `claude/` and `codex/` should be **portable across projects** — refer to standard convention paths (`AGENTS.md`, `Docs/bugs.md`) by relative path; gracefully handle their absence.
- Anything that depends on a specific codebase belongs in **that project's** `.claude/skills/`, not here.
- `templates/` files should be self-contained — usable in any project regardless of language or stack.

## What's NOT in this repo (and shouldn't be)

- `~/.claude/projects/` — session transcripts, large and personal
- `~/.claude/statsig/`, `~/.claude/todos/` — runtime state
- API tokens, OAuth credentials, anything sensitive
- Project-specific skills (those live in each project's `.claude/`)

See `.gitignore`.
