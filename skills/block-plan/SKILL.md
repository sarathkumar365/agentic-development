---
name: block-plan
description: Phase 4 of the idea pipeline. Decompose a specced product into independently buildable blocks with a shared schema contract, a dependency table, and ordered build threads each ending in a demoable milestone. Use after stack-decide, or when the user asks "break this into pieces", "what do we build first", "give me the build order", "decompose this".
---

# Phase 4 — Block Plan

Purpose: turn a spec plus a stack into a dependency-ordered set of pieces that can be built one at
a time, each verifiable alone.

**Input:** `docs/product-spec-v1.md` + `docs/stack-v1.md`.

## Step 1 — The enabler block comes first

Block zero is always the shared contract: the typed schemas every other block talks through
(Pydantic models, TypeScript types, protobuf — whatever the stack says). Nothing else can be built
independently until these exist.

List the core entities and their fields. This is what makes the rest of the plan real rather than
a wish list.

## Step 2 — Block table

```markdown
| ID | Block | Depends on | Done when | Notes |
|----|-------|-----------|-----------|-------|
| B0 | Scaffold + schemas | — | `pytest` green on empty suite, types importable | |
| B1 | ... | B0 | <observable, testable condition> | |
```

Rules for a well-formed block:

- One responsibility. If "and" appears in the name, split it.
- Buildable in roughly a day or less. Bigger means split.
- **Done when** is observable and testable by someone who did not build it. Not "implemented X".
- Depends only on blocks above it. No cycles — if you find one, the schema boundary is wrong.
- Every block names its test: unit, replay/fixture, or manual with an explicit script.

## Step 3 — Threads

Group blocks into 2–4 sequential threads. Each thread ends in something demoable.

```markdown
**Thread 1 — thin end-to-end, nothing clever.**
B0 → B1 → B3 → ...
Done when: <one concrete sentence a non-engineer understands>

**Thread 2 — quality.**
Done when: <a ship-criterion number from the spec moves, measurably>

**Thread 3 — the loop.**
Done when: <the product produces its own improvement data>
```

Thread 1 is always the thinnest possible path from input to visible output, with every clever part
stubbed. Nothing earns a place in Thread 1 by being interesting.

## Step 4 — Harness

Name the evaluation harness explicitly as its own block, and say which thread it joins. Without
it, no ship criterion from the spec can ever be checked, and the numbers in Phase 2 become
decoration.

## Step 5 — Blocked and parked

- **Blocked** — work that cannot proceed and the exact fact that unblocks it. Everything else
  continues in parallel; never let one blocker stall the whole plan.
- **Parked** — decisions deferred from Phase 3, each with the block that forces them.

## Output

Write `docs/build-plan-v1.md` with: enabler schemas, block table, threads, harness, blocked,
parked. Commit it.

## Gate

Present the block table and threads. Ask: **"Start B0?"**

On yes, build B0 immediately in the same session — scaffold, schemas, test harness, first commit.
Do not re-plan.

## Discipline

- No block whose **Done when** is "code written". Every one is externally checkable.
- A dependency table with everything depending on everything is a decomposition failure — go back
  to the schemas.
- Do not estimate in hours unless asked. Sequence and size class ("half day / day / split it")
  is enough.
