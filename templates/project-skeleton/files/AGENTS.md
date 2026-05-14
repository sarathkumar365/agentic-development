# Agent Working Agreement

Agents working in this repo (Claude Code, Copilot, Codex, Cursor, etc.) should read this file first.

## Project context

- **Project name:** <fill in>
- **Domain:** <what this project does>
- **Primary goal:** <main objective>

## Rules reference

- **Documentation layout:** `Docs/README.md` — index + "where does this go?" routing guide. Consult before creating any new folder/file under `Docs/`.
- **Implementation/structure rules:** `developer-rules.md` (if present)

## Branch strategy

- `main` is production-only. Do not push to `main` directly.
- Create feature branches from `main` (or `dev` if your team uses one): `feature/<slug>`.
- Open a PR to merge.

## Spec adherence and scope discipline

- When a written spec exists (a doc under `Docs/features/<slug>/` or a `Docs/repo-decisions/RD-*.md`), the spec is the source of truth.
- Re-read the relevant spec before editing behavior governed by it.
- Surface deviations from a spec **explicitly, in-conversation**, before shipping them.
- "Fix X" means fix X. Don't widen scope to "also improve Y" without raising it as a separate item.

## Mandatory testing

- Add or update tests with behavior changes.
- Run the existing test suite before declaring work complete.
- If test execution is blocked (env, credentials, infra), report the blocker — do not claim validation as complete.

## How to use Claude / Copilot / etc. in this repo

- For per-task workflows (bug investigation, feature scaffolding, planning), use slash commands or skills, not bullets in this file.
- For safety rules (no push to main, no `.env` access), see `.claude/settings.json` hooks.
- Keep this file under ~150 lines. If you're tempted to add a generic best-practice the model already follows from training, delete instead.
