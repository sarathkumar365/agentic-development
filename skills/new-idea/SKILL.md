---
name: new-idea
description: Orchestrator for taking a raw idea all the way to a scaffolded repo with a build plan — runs idea-lock, market-proof, product-spec, stack-decide, block-plan and project-init in order, with an approval gate between each phase. Use when the user drops a new product idea and wants it turned into a project ("I had an idea", "let's build X", "turn this into a project", "/new-idea"), or wants to resume a partially completed pipeline.
---

# New Idea — pipeline orchestrator

Runs the full idea → repo chain. One phase per turn. Gate between every phase.

## The chain

| # | Phase | Skill | Artefact | Gate question |
|---|---|---|---|---|
| 0 | Lock | `idea-lock` | `docs/idea-contract.md` | "Lock this, or amend it?" |
| 1 | Proof | `market-proof` | `docs/market-landscape.md` | "Accept the verdict, or challenge it?" |
| 2 | Spec | `product-spec` | `docs/product-spec-v1.md` | "Veto anything, or go to stack?" |
| 3 | Stack | `stack-decide` | `docs/stack-v1.md` | "Veto any row, or go to blocks?" |
| 4 | Blocks | `block-plan` | `docs/build-plan-v1.md` | "Start B0?" |
| 5 | Init | `project-init` | repo + remote | "Pushed. Build B0?" |

`project-init` may run early — right after Phase 0 — when a source document exists and the founder
wants the repo now. The remaining phases then commit into it as they complete.

## Rules of the orchestrator

1. **One phase per turn.** Never chain two phases in a single reply, even when the next one seems
   obvious. The gate is the whole point.
2. **Read the previous artefact before starting a phase.** Phase N reads Phase N−1's file, not the
   original conversation. This is what keeps drift from compounding.
3. **Contract check every turn.** If a phase output violates an Idea Contract invariant, print
   `CONTRACT VIOLATION: <invariant>` and stop.
4. **Skip nothing silently.** A skipped phase is announced with the reason
   ("skipping Phase 1 — internal tool, no market").
5. **Resume by inspection.** On "continue", check which `docs/*.md` exist and restart at the first
   missing one. Do not ask where you left off.
6. **Decide, don't interrogate.** At most 5 `[BLOCKING]` questions per phase, each with a default.
   Everything else is decided with a rejected-alternatives line.

## Turn shape

Every phase turn looks like this and nothing else:

```
<the artefact's headline content — decisions, tables, numbers>

---
Phase N complete → docs/<file>.md
[BLOCKING] <≤5 questions, each with a default>   (omit when none)
<gate question>
```

No preamble. No "I'll now run Phase 2". No recap of the previous phase.

## Fast path

When the founder says "just do it", "skip the questions", or "you decide": run every phase using
defaults, take every `[BLOCKING]` default without asking, and present one consolidated report with
a **Decisions taken on your behalf** table at the top. Gates collapse to a single veto at the end.

The contract check still runs. The fast path skips questions, never invariants.

## Scale down when the idea is small

Not every idea deserves six phases. Judge in one line and say which shape you are using:

- **Weekend tool, no market, no users but you** → Phase 0 + Phase 4 + Phase 5. Skip 1–3 out loud.
- **Real product, external users** → full chain.
- **Feature inside an existing project** → no pipeline. Read the existing spec and go straight to
  `block-plan`.
