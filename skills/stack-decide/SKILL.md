---
name: stack-decide
description: Phase 3 of the idea pipeline. Choose the technology stack for a specced product — language, runtime, data layer, models, hosting, hardware — each as a decision with rejected alternatives, licence check, and a cost and local-feasibility check against the founder's actual machine. Use after product-spec, or when the user asks "what stack", "what should we build this with", "which model/database/framework".
---

# Phase 3 — Stack Decide

Purpose: pick the tools, once, with reasons that survive being questioned in a month.

**Input:** `docs/product-spec-v1.md`. Every choice must trace to a spec constraint or a ship
criterion. A choice justified only by taste is a choice not yet made.

**Hard rule: no build order, no task breakdown in this phase.** That is Phase 4.

## Standing defaults

Start here and deviate only with a named reason:

| Layer | Default | Deviate when |
|---|---|---|
| Language | Python | Latency or fps measurably fails; then name the measurement |
| Repo | Monorepo, private, GitHub `sarathkumar365` | Separate release cadences genuinely exist |
| Runtime target | Local dev box first | Spec requires a form factor that cannot run locally |
| Cloud | None in v1; AWS when production demands it | Pilot cannot function without it |
| Models | Hosted API behind a swappable interface | Privacy, cost at volume, or offline requirement |
| Storage | SQLite + local disk | Concurrency or scale is a v1 requirement, not a v2 hope |
| Packaging | `uv`, `ruff`, `pytest`, docker-compose | — |
| Cost posture | Free tier until proven impossible | — |

## Checks that must run on every choice

1. **Licence check.** No AGPL in anything shippable. Flag copyleft, research-only, and
   "non-commercial" terms explicitly. State the permissive alternative by name.
   *(Concrete example: Ultralytics YOLO is AGPL-3.0 — use RT-DETR / D-FINE / RF-DETR instead.)*
2. **Local feasibility.** Machine is RTX 2070 Super **8 GB VRAM**, i5 12th gen, 16 GB RAM.
   Run `nvidia-smi` and `free -g` and quote the real numbers — do not trust remembered specs.
   If a model does not fit in 8 GB, say so and give the hosted-API or smaller-model fallback.
3. **Cost at v1 volume.** Estimate monthly spend at pilot scale. If it exceeds free tier, say the
   number and the cheaper path.
4. **Swap cost.** For each choice, one line: how hard to replace later. Anything rated "hard" needs
   a stronger justification than convenience.
5. **Interface isolation.** Any vendor-specific dependency sits behind a local interface so the
   swap cost stays low. Name the interface.

## Output

Write `docs/stack-v1.md`:

```markdown
# Stack v1 — <name>
Traces to: product-spec-v1.md

## Decision table
| Layer | Choice | Why (traces to spec §) | Rejected + reason | Licence | Swap cost |

## Local feasibility
<Real `nvidia-smi` / `free -g` output. What fits, what does not, the fallback for what does not.>

## Cost model at pilot scale
<Line items, monthly total, free-tier boundary.>

## Licence register
<Every dependency with a non-permissive licence, and the mitigation.>

## Interfaces that isolate vendors
<Name each interface and what it hides.>

## Deferred
<Choices deliberately not made yet, and the moment each becomes due.>
```

## Gate

Present the decision table only. Ask: **"Veto any row, or go to blocks?"**

Then Phase 4 (`block-plan`).

## Discipline

- Never decide something that can be deferred cheaply. Put it in **Deferred** with a trigger
  condition ("decide at block B9").
- Two choices that do the same job is a smell — pick one.
- Novelty is not a reason. "Newest" never appears in a Why column.
