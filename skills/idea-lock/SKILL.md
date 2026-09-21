---
name: idea-lock
description: Phase 0 of the idea pipeline. Turn a raw, half-formed idea into a locked one-page Idea Contract — definition, invariants, non-goals, success shape — before any research, expansion, spec or code. Use whenever the user drops a new idea ("I had an idea", "what if we built", "here's a product idea", a pasted concept doc), or when an existing project has drifted and needs its contract restated. Always run this before market-proof, product-spec, stack-decide or block-plan.
---

# Phase 0 — Idea Lock

Purpose: stop direction drift at the only point where it is cheap to stop. An unlocked idea gets
expanded in the model's direction, not the founder's, and every later phase inherits the error.

**Hard rule: produce the contract and stop. No market research, no architecture, no stack, no code
in this phase.** Those are Phases 1–4 and they run against the locked contract.

## Step 1 — Extract, do not invent

Read whatever the user gave you — a sentence, a voice-note transcript, a `.docx`, a README.
Extract only what is actually there. Where something essential is missing, write `UNSTATED` rather
than filling it with a plausible guess. `UNSTATED` fields are what you are allowed to ask about.

If a source document exists, convert and keep it verbatim at `docs/source/` before summarising it.
The founder's own words are the tiebreaker in every later argument.

## Step 2 — Write the Idea Contract

Exactly this shape. One page. No expansion beyond it.

```markdown
# Idea Contract — <name> v0.1
Status: DRAFT (unlocked)  ·  Date: <YYYY-MM-DD>

## One line
<What it is, in one sentence a stranger understands. No adjectives.>

## The thing itself
<One paragraph. What it does, for whom, replacing what they do today.>

## Invariants
Three to five. These survive every later decision. Violating one means it is a different product.
1. <invariant>
2. <invariant>
3. <invariant>

## Non-goals
Never built. Architectural exclusions, not config toggles.
- <non-goal> — <why excluded>

## Success shape
What "this worked" looks like, before we know how to measure it precisely.
- <observable outcome>

## Open — blocking
Facts only the founder holds. Max 5. Each with a proposed default.
- [BLOCKING] <question>  ·  default: <your default>

## Assumed — correct me
Judgement calls already decided so work can proceed.
- <decision> — <one line why> — rejected: <alternative + reason>
```

## Step 3 — Read back the drift risks

Before asking for the lock, name in 2–4 bullets the places where you were tempted to expand and
did not. This is the founder's chance to say "actually, go there". Example shape:

> Tempted to widen from X to Y — parked, that is a different product.
> Tempted to assume the buyer is Z — left UNSTATED, it changes the whole spec.

## Step 4 — Gate

Ask one question: **"Lock this, or amend it?"**

- Amendments are applied to the contract, not argued with.
- On lock: flip `Status: LOCKED`, write to `docs/idea-contract.md`, commit it if the repo exists.
- Only after LOCKED may Phase 1 (`market-proof`) start.

## Enforcement for the rest of the project

Once locked, the contract is the drift test. In any later phase:

- A proposal that violates an invariant → say `CONTRACT VIOLATION: <invariant>` and stop. Do not
  silently re-scope.
- The founder correcting direction → append it to Invariants or Non-goals immediately, same turn.
  A correction that is not written down will be re-litigated, which is the failure this exists to
  prevent.
- Scope creep that does not violate an invariant → add to `Not in v1` in the spec, do not build.

## Failure modes this exists to prevent

| Failure | Symptom | Guard |
|---|---|---|
| Model expands in its own direction | Founder says "that's not what I meant" on the first long output | Contract is extraction-only, invented content marked `UNSTATED` |
| Research answers the wrong question | Deep market report about an adjacent product | Phase 1 reads the contract, not the original prompt |
| Silent re-scope mid-build | v1 grew a feature nobody chose | Invariant check on every proposal |
| Same argument twice | Founder repeats a correction from last week | Corrections are written into the contract |
