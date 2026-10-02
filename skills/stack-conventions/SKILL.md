---
category: engineering
name: stack-conventions
description: The operator's default conventions and known pitfalls for Java, Python, TypeScript, React and PostgreSQL. Use whenever writing, reviewing, refactoring or debugging code in any of these — including SQL, migrations, Spring, JPA, pytest, hooks and components — and read only the file for the language in front of you.
---

# Stack conventions

Defaults for when a project has not already decided. The project's own `AGENTS.md`, linter
config and existing code always win over anything here. When they disagree, follow the project
and mention the difference once.

Read only what the task touches:

- **Java** (Spring, JPA, Maven, Gradle) → [reference/java.md](reference/java.md)
- **Python** (pytest, typing, async) → [reference/python.md](reference/python.md)
- **TypeScript** (Node, types, async) → [reference/typescript.md](reference/typescript.md)
- **React** (components, hooks, state) → [reference/react.md](reference/react.md)
- **PostgreSQL** (schema, migrations, queries) → [reference/postgres.md](reference/postgres.md)

These files hold only what differs from a sensible default or is easy to get wrong. They grow
from real corrections through the learning loop, not from general knowledge.
