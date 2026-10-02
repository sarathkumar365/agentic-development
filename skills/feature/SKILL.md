---
category: engineering
name: feature
description: Build a feature or behaviour change in an existing codebase the way a senior engineer would — explore how the code already works, ask the questions that change the design, write a plan and wait for approval, implement the smallest change that meets it, verify by running it, then explain why it works. Use when the user asks to add, implement, build, change or extend behaviour in a repo ("add X", "implement Y", "make it do Z", "build the endpoint for", "wire up", "support W"). Do NOT use for a pure discussion of options with no code wanted (use consult), for a bug (use debug when it exists), or for a typo-sized edit.
---

# Feature

The operator stays the engineer. You do the legwork; they make the design calls and understand
every line that lands.

## 0. Size it

Say the depth in one line. A change that touches one obvious place with no design choice is
**quick**: make it, verify it, report in one line (what changed and the concept it relies on),
and skip the rest of this skill.

Everything else runs the steps below. Copy this checklist into your reply and keep it current:

```
- [ ] 1 Explore
- [ ] 2 Clarify
- [ ] 3 Plan — operator approved
- [ ] 4 Implement
- [ ] 5 Verify
- [ ] 6 Explain
```

## 1. Explore

Read before proposing anything.

- The project's `AGENTS.md` and anything under `Docs/` that covers this area.
- The closest existing example of what is being asked: a similar endpoint, component, table,
  test. The new code follows that pattern unless there is a stated reason not to.
- How to build, test and typecheck this project. Find the commands; do not guess them.
- For each language involved, the matching file in the `stack-conventions` skill. Where the
  project already decides something differently, the project wins.

Output: a short map — files involved, the pattern you will follow, the test command.

## 2. Clarify

Restate the feature in three lines:

- **What** — the behaviour, from the user's side.
- **Done when** — checks a test or a command can prove.
- **Not doing** — what is deliberately out of scope.

Then ask only the questions whose answers change the design. At most 5, each tagged
`[BLOCKING]` with a proposed default. Ask none when the defaults are clearly right.

If the feature has a real design choice (where state lives, sync or async, a new table or a
column), present it before planning: two or three options with their trade-offs, your
recommendation and why. The operator picks; the plan builds on that pick.

## 3. Plan

```
Goal:        <one line>
Done when:   <testable checks>
Changes:     <file — what changes and why, one line each>
Tests:       <what is added or updated, and what each proves>
Risks:       <what could break, and how you will know>
Rejected:    <the options the operator did not pick, and why>
```

For work that will span sessions, save the plan as `Docs/<slug>.md` in the project. Otherwise
keep it in the conversation.

End with: **"Approve, or change?"** Stop. Write no code before the operator approves.

## 4. Implement

- Follow the plan in order. If the plan turns out wrong, stop and say what changed before going
  on. Never widen scope silently.
- The smallest diff that meets "done when". Reuse what exists. No new abstraction, dependency or
  config the plan did not name.
- Match the surrounding code: naming, structure, error handling, comment density.
- Write the tests with the code, not after.
- If the operator says "teach me" or "let me write it", leave the core piece as a stub with the
  signature, the contract and a hint, and review their version instead of writing it.

## 5. Verify

Run the project's tests, typecheck and linter. Show the result lines that matter. If something
cannot be run here, say exactly what was not verified. Never report done on an assertion.

## 6. Explain

```
Changed:   <file:line — what, one line each>
How it works: <the flow through the code now — what calls what, where data goes, what
              state changes — using the codebase's own names>
Concepts:  <each concept or pattern the change relies on, by its correct technical term,
           with one precise line on what it is and why it applies here>
Not done:  <anything skipped, deferred or unverified>
```

Precise, not simplified: the operator must be able to explain this change to a reviewer
afterwards. Scale it to the change: a small change gets a line or two per field, and no field
repeats another. Switch to plain language only if they say they are lost.

Do not commit or push unless asked.
