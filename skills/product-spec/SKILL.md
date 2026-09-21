---
name: product-spec
description: Phase 2 of the idea pipeline. Turn a validated idea into one buildable v1 wedge — vertical, deployment form, scope freeze, non-goals, not-in-v1 list, and falsifiable numeric ship criteria. Decides on the founder's behalf and lists rejected alternatives instead of interrogating. Use after market-proof returns BUILD or NARROW, or when the user asks "what exactly do we build first", "define the MVP", "what's in v1".
---

# Phase 2 — Product Spec

Purpose: collapse a validated idea into exactly one thing to build, with numbers that decide
whether it worked.

**Input:** locked `docs/idea-contract.md` + `docs/market-landscape.md` with verdict BUILD or NARROW.

**Hard rule: no libraries, no frameworks, no repo layout in this phase.** That is Phase 3.
Hardware class is in scope only where it is a product constraint (bandwidth, on-prem, offline).

## The decision method

Decide. Do not interrogate. For every decision below, produce:

> **Decision** — one line. **Why** — one line. **Rejected** — each alternative plus the reason it lost.

Founders veto faster than they answer questionnaires. A wrong decision that is written down and
reversed in one line costs less than five questions that stall the project for a day.

Ask only what the founder alone knows, tagged `[BLOCKING]`, capped at 5, each with a default.

## Decisions to make

1. **Vertical / first user.** One. Name who they are, what they lose today, what they already pay.
   Reject the others by name.
2. **Wedge.** The single job v1 does better than the incumbent. One sentence, testable.
3. **Deployment form.** How it reaches the user, driven by a hard constraint you can name
   (bandwidth, privacy, latency, offline, procurement).
4. **Jurisdiction / market.** Where the first customer is, and what that implies for compliance.
5. **P0 surface.** The minimum feature set. Every item must be needed for the wedge to function.
6. **Ship criteria.** Numeric bars — see below.
7. **Price shape.** Per unit, per seat, per site, flat. Anchored on what §7 of the market doc found.
8. **Pilot definition.** What counts as one real deployment, and what artefact it produces.

## Ship criteria — the core of this phase

Three to six metrics. Each needs: a number, a measurement method, and a window. A bar that cannot
fail is not a bar.

| Metric | Bar | How measured | Window |
|---|---|---|---|
| <name> | <number + unit> | <method> | <e.g. 30-day rolling> |

Add a **stratification clause**: the bars must hold in the hard conditions, not the average ones
(night, rain, low bandwidth, cold start, empty account, worst device). Failing a stratum means not
shipped.

One of these metrics is the company. Name which, and say why.

## The three lists

Carry all three forward into every later document.

- **Frozen** — decided. Reopened only when the founder says "reopen".
- **Non-goals** — never built. Inherited from the Idea Contract, extended here. Architectural, not
  a config flag.
- **Not in v1** — real and deferred. Naming them is what stops them leaking into v1.

## Output

Write `docs/product-spec-v1.md`:

```markdown
# Product Spec v1 — <name>
Derived from: idea-contract.md (LOCKED), market-landscape.md (verdict: <BUILD|NARROW>)

## 0. Value proposition in one line
## 1. First user and vertical            (decision / why / rejected)
## 2. Wedge
## 3. Deployment form                    (decision / why / rejected)
## 4. Jurisdiction and compliance posture
## 5. P0 surface
## 6. Ship criteria                      (table + stratification clause + "this one is the company")
## 7. Price shape
## 8. Pilot definition and first proof
## 9. Frozen
## 10. Non-goals
## 11. Not in v1
## 12. Open — blocking                   (≤5, each with a default)
```

Then replace any open-decisions section in `README.md` with the answers, and commit.

## Gate

Present §0, §2, §6 and §11 first — value, wedge, bars, and what is excluded. Ask:
**"Veto anything, or go to stack?"**

Silence on a decision means accepted. Proceed to Phase 3 (`stack-decide`) only after this gate.

## Discipline

- A P0 surface with more than about 10 items is not a v1. Cut until every item is load-bearing.
- If you cannot write a falsifiable bar for the wedge, the wedge is not yet real — go back to §2.
- Never present a feature list as a spec. A spec is decisions plus exclusions plus numbers.
