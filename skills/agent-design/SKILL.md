---
category: engineering
name: agent-design
description: >-
  Design an AI agent (or an agentic feature) with the user, pattern by pattern, using the
  production patterns from "Patterns for Building AI Agents" (Bhagwat & Gienow, Mastra, 2025):
  capability whiteboarding, architecture evolution, human-in-the-loop, context engineering,
  failure modes and metrics, evals, and security (lethal trifecta, access control,
  guardrails). Use whenever the user wants to design, plan, architect, scope, review or
  harden an agent, an autonomous pipeline, a bot, or any system that acts on its own —
  e.g. "design the agent", "what's the agent architecture", "next piece of the agent",
  "should this be autonomous", "how do we evaluate the agent", "is this agent safe",
  "decision rule for the agent", "human approval step". Produces a design document, one
  decision at a time, with the user deciding. Do NOT use for implementing an already-decided
  design, for non-agent features, or for general LLM API questions (use claude-api).
---

# Agent design

You are designing an agent **with** the user. They decide; you bring the patterns, the
questions each pattern forces, and a recommendation. One decision at a time, recorded as it
is made.

The pattern catalogue — problem, solution and "ask this" for each of the 22 patterns — is in
`references/patterns.md`. Read it at the start of a design session. It is a paraphrase in
our own words, not the book's text; do not quote the book at length.

## First principles, before any pattern

- **Most of an "agent" should be deterministic code.** Use a model only where judgement on
  unstructured input is genuinely needed. Every model call in the loop is latency, cost,
  nondeterminism and an injection surface. Say which steps need a model and which do not.
- **Ground in the project.** Read the project's own contract (`AGENTS.md`, `CLAUDE.md`,
  `README`, existing design docs) before proposing structure. Designs follow the repo's
  layering and conventions.
- **Prove the riskiest external dependency with a spike before designing around it.** A
  design built on an assumed API or site behaviour is fiction until it has run once.

## The session

Work through these phases in order. Skip a phase only by saying why. Each phase ends with a
decision written into the design doc.

1. **Whiteboard** — list every capability wanted; keep asking "what is missing?". Group by
   data source, by task type (fetch / judge / act), and by step in the process. Rank. Pick
   the one burning problem. *(Patterns 1, 2)*
2. **Loop and architecture** — draw the loop: trigger → inputs → decision → action →
   outcome → feedback. Mark each step deterministic or model-driven. One agent unless there
   is a real reason to split; a router only once there are several. Prefer a single linear
   thread over parallel subagents unless subtasks are truly independent. *(2, 3, 5, 6)*
3. **Autonomy and the human** — for each action: what does a wrong action cost, what does a
   missed one cost? Pick the HITL mode per action: human gives input mid-run, human approves
   a draft, or deferred (agent proceeds, human reviews later). Humans are the bottleneck;
   design for them not babysitting. Start more supervised than you think; earn autonomy with
   measured performance. *(4)*
4. **Decision rule** — when the agent acts on a prediction or judgement, define the rule and
   threshold explicitly, including the "I am not sure" path, rate limits and budgets (disk,
   money, API quota, actions per day).
5. **Context** (only where a model is in the loop) — what goes into context, what is
   filtered, where it is compressed, how errors are fed back, which decisions must never be
   compressed away. Watch for poisoning, distraction, confusion, clash and rot. *(7, 8, 9)*
6. **Failure modes and metrics** — list *why* it can fail, not just that it can. Pick one
   north-star metric (usually the costliest wrong action) plus accuracy and outcome
   metrics. Cross-reference: which failure mode moves the north star? *(10, 11, 12)*
7. **Evals** — a golden dataset, where its labels come from (the domain expert is usually
   the user, not the engineer), an eval run that gates changes, and how production outcomes
   become new test cases. LLM judges grade pass/fail or categories, not numbers.
   *(13–17)*
8. **Security** — check the lethal trifecta: private data, untrusted content, outbound
   action. If all three are present, remove a leg (usually: untrusted content never reaches
   a model that can act). Then: sandboxing for any executed code, per-tool just-in-time
   permissions, a lower-permission dry-run/planning mode, input and output guardrails named
   by what they block. Where credentials or accounts live, and what happens if they leak.
   *(18–21)*
9. **Operations** — where it runs, how it is scheduled, logging of every action with its
   reason, how to stop it, how to undo what it did.

## Output

- One design document per agent (or per piece of a larger agent), in the project's docs
  location — for example `Docs/agent/<PIECE>.md` — with an index that records state.
- Each section: the decision, the alternatives rejected and why, and open questions.
- End every phase by asking the user for the decision the phase needs, with your
  recommendation first. Do not implement until the user says the design is settled.

## Style of the conversation

- Short. One phase, one recommendation, one question per turn where possible.
- Name the pattern you are applying so the user can look it up.
- Say plainly when a pattern does not apply to this agent and skip it.
- Where the book's teams disagree (parallel subagents, context sharing), say so and pick
  for this case.
