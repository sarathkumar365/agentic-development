---
name: project-init
description: Scaffold a new project repository from an idea or a source document — convert the source, write README and docs, add CLAUDE.md, .gitignore and tooling config, init git, create the private GitHub repo and push. Use when the user says "initialize this project", "set up the repo", "make this a project", "start a new project", or drops a concept document and asks to begin.
---

# Project Init

Purpose: get from "I have an idea" to "there is a repo with the thinking in it" with no
hand-holding. Idempotent — safe to re-run on a partially set-up project.

## Preconditions

Check first, do not assume:

```bash
git rev-parse --is-inside-work-tree 2>/dev/null; gh auth status 2>&1 | head -3; ls -A
```

If the directory already has a repo, skip creation and fill in only what is missing.

## Step 1 — Preserve the source

Any founder-supplied document is the canonical source and the tiebreaker in every later argument.

- Copy the original to `docs/source/` **unmodified**, whatever its format.
- Convert to Markdown alongside it (`pandoc`, or extract text) as `docs/source/<name>.txt`
  or `.md`.
- Never paraphrase the source into the README and then discard it.

## Step 2 — Directory shape

```
README.md              project goal, north star, architecture sketch, status, open decisions
CLAUDE.md              project-specific agent instructions (inherits ~/.claude/CLAUDE.md)
.gitignore             language-appropriate + .env, .env.local, secrets, data/, models/
docs/
  source/              originals, verbatim
  idea-contract.md     Phase 0 output
  market-landscape.md  Phase 1 output
  product-spec-v1.md   Phase 2 output
  stack-v1.md          Phase 3 output
  build-plan-v1.md     Phase 4 output
  decisions.md         running decision log, newest first
```

Create only the files that have content. Empty placeholders rot.

## Step 3 — README

Sections, in order:

1. Title + one-line definition
2. Status + pointer to the canonical doc
3. Project goal — what it does, for whom, and the explicit non-goals
4. North star — the single sentence that settles arguments
5. Architecture sketch — the pipeline or layer table, not implementation
6. Repo map — what lives where
7. Open decisions — replaced with answers as phases complete
8. How to run — as soon as anything runs

Non-goals go in the README, not buried in a doc. They are what stops scope creep six weeks later.

## Step 4 — Agent instructions

Two files, deliberately. `AGENTS.md` is the cross-agent working agreement (Claude Code, Codex,
Cursor and Copilot all read it). `CLAUDE.md` imports it with `@AGENTS.md` and adds only what is
Claude-specific. Do not duplicate content between them.

`CLAUDE.md` inherits the global doctrine at `~/.claude/CLAUDE.md`, so it carries only:

```markdown
# Claude Code instructions

@AGENTS.md

## Invariants
<copied from docs/idea-contract.md — what must survive every change>

## Non-goals
<never build these; architectural, not config>

## Conventions
<test command, lint command, how to run, layout rules>
```

`~/agentic-development/templates/project-skeleton/init.sh` stamps both, plus the `Docs/` tree and
safety hooks. Run it rather than hand-writing them.

## Step 5 — Git and remote

```bash
git init -b main
git add -A
git commit -m "docs: establish project goal, market landscape, and data strategy"
gh repo create <name> --private --source=. --remote=origin --push
```

Private by default, always. Ask before making anything public — that is an irreversible,
outward-facing action.

Confirm the remote URL back to the founder in one line.

## Step 6 — Report

One block, no narration of the steps:

- Repo URL
- Files created (as clickable relative links)
- What is still `UNSTATED` or blocking
- The single next action

## Discipline

- Never `git push` to an existing remote without saying what is being pushed.
- Never commit secrets. Check `.env*` is ignored before the first `git add -A`.
- Do not scaffold code in this skill. Repo and documents only; code starts at block B0.
