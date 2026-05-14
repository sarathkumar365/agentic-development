# Docs

Index of everything under `Docs/`. Use this as the entry point when you're looking for something and don't know where it lives.

For code layout and implementation rules, see `../developer-rules.md` (if present).
For agent-facing rules, see `../AGENTS.md`.

## Folders

| Folder | What it's for |
|---|---|
| [features/](features/) | One subfolder per **new feature** — specs, design notes, phase plans. Net-new behavior only. |
| [bugs.md](bugs.md) | Lightweight tracker (issue # + description + PR + status). GitHub Issues is the source of truth; this file is the at-a-glance index. |
| [runbooks/](runbooks/) | How-to-operate docs — deploys, on-call playbooks, manual scripts. |
| [initiatives/](initiatives/) | Cross-cutting work that isn't a feature or a bug — hardening, legacy removal, migrations, tech-debt sweeps. |
| [repo-decisions/](repo-decisions/) | Repo-wide architectural and process decisions (ADRs). Mandatory read before touching modules covered by an `Accepted` decision. |
| [deep-dive/](deep-dive/) | Long-form documentation of how the system works — architecture, per-flow walkthroughs, end-to-end scenarios. |
| [engineering-reference/](engineering-reference/) | Evergreen internal reference — migration plans, testing conventions, known issues, tooling cheat-sheets. |

## "Where does this go?" quick guide

- **Designing a new feature** → new folder under `features/`
- **A defect** → open a GitHub Issue, then add a row to `bugs.md`. Long investigations go in `deep-dive/`.
- **Deploy steps / on-call procedure / how to run a script** → `runbooks/`
- **Hardening pass, legacy removal, migration, tech-debt sweep** → `initiatives/`
- **Decision that affects the whole repo** → `repo-decisions/`
- **Reusable how-to / reference** → `engineering-reference/`

### Quick decision: is this a feature or a bug?

- Adds capability the system didn't have before → feature
- System was supposed to do X, didn't, now we're fixing it → bug
- System does X but we want to stop / clean it up → initiative
- System works fine, but we need a written procedure → runbook
