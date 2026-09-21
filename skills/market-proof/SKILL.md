---
name: market-proof
description: Phase 1 of the idea pipeline. Prove or kill an idea against the real market — what already ships, what is commodity, what the regulatory constraints are, where a real gap survives — and end with an explicit BUILD / NARROW / KILL verdict. Use after idea-lock, or when the user asks "does this already exist", "who are the competitors", "is this worth building", "validate this idea". Never run before the Idea Contract is LOCKED.
---

# Phase 1 — Market Proof

Purpose: find out whether the locked idea needs to exist, before any spec or code. Ends in a
verdict, not a report.

**Input:** `docs/idea-contract.md` with `Status: LOCKED`. If it is missing or unlocked, run
`idea-lock` first.

**Hard rule: no architecture, no tech stack, no build plan in this phase.** Naming a technology is
fine only when it is evidence about the market (a competitor ships it, a licence blocks it).

## Research plan

Run searches in parallel, not serially. Cover all six axes — skipping one is where wrong verdicts
come from.

| Axis | What you are looking for |
|---|---|
| Incumbents | Who sells this today. Segment them by business model, not by feature list. |
| Commodity line | Capabilities that are table stakes. Anything here is not differentiation. |
| Frontier | What research/startups shipped in the last 12 months. Cite papers with numbers. |
| Regulation | Laws with enforcement dates that constrain the architecture, not just the marketing. |
| Economics | What the buyer pays today for the job this replaces. That is the price ceiling. |
| Substitutes | The non-product way people solve this now — a human, a spreadsheet, doing nothing. |

Rules:

- Cite every non-obvious claim with a link. No link, no claim.
- Prefer sources dated within 18 months; label anything older as dated.
- Market-size figures from different methodologies disagree. Give the range and label it
  direction, not fact.
- Look for the licence traps early: AGPL libraries, research-only datasets, patent-encumbered
  formats. They constrain v1 and are cheap to find now, expensive later.
- Delegate fan-out research to the `market-scout` agent when there are more than ~6 searches;
  it returns compressed findings instead of flooding the main context.

## Output

```markdown
# Market Landscape — <name>, <Month Year>

## 1. Market shape
<Size range with methodology caveat. Growth direction. Who is buying and why now.>

## 2. Vendor segments
<2–4 segments by business model. Name the companies. State which segment we would be in.>

## 3. Already commodity — not differentiation
<Bulleted list. Brutal. Anything shipping in three or more products goes here.>

## 4. Frontier
<What is newly possible. Papers with numbers and dates. This is where the wedge usually lives.>

## 5. Regulatory constraints that shape the spec
<Laws, dates, and the concrete architectural consequence of each. Not a legal summary —
 a list of things the product may therefore never do.>

## 6. Real gaps that survive scrutiny
<3–6 items. For each: why incumbents have not closed it, and why we could.>

## 7. Economics
<What the buyer spends today on this job. Price ceiling and floor. Who signs.>

## 8. Verdict
**BUILD** | **NARROW** | **KILL**
<Three sentences. If NARROW, name the narrower idea precisely and amend the contract.
 If KILL, name what would have to change for that to flip.>

## Sources
<Every link, labelled.>
```

## Gate

Present the verdict first, then the evidence. Ask: **"Accept the verdict, or challenge it?"**

- **BUILD** → Phase 2 (`product-spec`).
- **NARROW** → amend `docs/idea-contract.md` with the narrower scope, re-lock, then Phase 2.
- **KILL** → stop. Write `docs/market-landscape.md` anyway; a killed idea's research is reusable.

Write the file to `docs/market-landscape.md` regardless of verdict. Commit it.

## Discipline

- A verdict of BUILD with no named gap is not a verdict. If §6 is empty, the honest answer is KILL
  or NARROW.
- Never soften a KILL to be agreeable. A cheap kill in Phase 1 is the highest-value output this
  pipeline produces.
- Do not let an exciting frontier finding override an empty §6. Newly possible ≠ needed.
