# Features

One subfolder per feature, holding its spec, design notes, and any phase plans.

## Conventions

- Folder name: kebab-case feature slug.
- Inside each folder: a primary spec/RFC (`plan.md`), supporting notes (`research.md`), phase docs as needed.
- Repo-wide decisions surfaced by a feature get promoted to `../repo-decisions/`.

## What goes here

- Feature specs and RFCs
- Phase plans, rollout notes, vertical-slice breakdowns
- Feature-scoped diagrams or design discussion

## What does not go here

- Bug fixes / defect tracking → `../bugs.md`
- Deploy steps, on-call playbooks, manual scripts → `../runbooks/`
- Hardening, legacy removal, migrations → `../initiatives/`
- Repo-wide decisions → `../repo-decisions/`

## The "feature?" test

Ask: *"Does this add a capability the system didn't have before?"* If no, it probably belongs in `bugs.md`, `runbooks/`, or `initiatives/` instead.
