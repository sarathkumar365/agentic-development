---
category: product
name: stack-decide
description: Phase 3 of the idea pipeline. Choose the technology stack for a specced product — language, runtime, data layer, models, hosting, hardware — each as a decision with rejected alternatives, licence check, and a cost check, and a local-resource check when the stack runs heavy compute locally. Use after product-spec, or when the user asks "what stack", "what should we build this with", "which model/database/framework".
---

# Phase 3 — Stack Decide

Purpose: pick the tools, once, with reasons that survive being questioned in a month.

**Input:** `Docs/product-spec-v1.md`. Every choice must trace to a spec constraint or a ship
criterion. A choice justified only by taste is a choice not yet made.

**Hard rule: no build order, no task breakdown in this phase.** That is Phase 4.

## Standing defaults

Start here and deviate only with a named reason. Language, storage and tooling have no default:
each is chosen from the spec, with options and a recommendation.

| Layer | Default | Deviate when |
|---|---|---|
| Repo | One repo, private, on the operator's account | Separate release cadences genuinely exist |
| Runtime target | Local machine first | Spec requires a form factor that cannot run locally |
| Cloud | None in v1 | Pilot cannot function without it |
| Models | Hosted API behind a swappable interface | Privacy, cost at volume, or offline requirement |
| Cost posture | Free tier until proven impossible | — |

## Checks that must run on every choice

1. **Licence check.** No AGPL in anything shippable. Flag copyleft, research-only, and
   "non-commercial" terms explicitly. State the permissive alternative by name.
2. **Local feasibility.** Only when the stack runs heavy compute locally (models, large builds,
   large data). Check this machine's real resources with the OS's own command and quote the
   numbers — never remembered specs. If it does not fit, say so and give the fallback.
3. **Cost at v1 volume.** Estimate monthly spend at pilot scale. If it exceeds free tier, say the
   number and the cheaper path.
4. **Swap cost.** For each choice, one line: how hard to replace later. Anything rated "hard" needs
   a stronger justification than convenience.
5. **Interface isolation.** Any vendor-specific dependency sits behind a local interface so the
   swap cost stays low. Name the interface.

## Output

Write `Docs/stack-v1.md`:

```markdown
# Stack v1 — <name>
Traces to: product-spec-v1.md

## Decision table
| Layer | Choice | Why (traces to spec §) | Rejected + reason | Licence | Swap cost |

## Local feasibility
<Only if check 2 applied: the real resource numbers, what fits, and the fallback for what does not.>

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

Present the decision table only. Each row shows options, a recommendation and why. Ask:
**"Pick each open row, or take the recommendations?"**

Then Phase 4 (`block-plan`).

## Discipline

- Never decide something that can be deferred cheaply. Put it in **Deferred** with a trigger
  condition ("decide at block B9").
- Two choices that do the same job is a smell — pick one.
- Novelty is not a reason. "Newest" never appears in a Why column.
