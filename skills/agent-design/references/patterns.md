# Pattern catalogue

Paraphrased from *Patterns for Building AI Agents*, Sam Bhagwat and Michelle Gienow (Mastra,
October 2025), 22 patterns in four parts. Summaries are ours. Free copy:
https://mastra.ai/books/patterns-of-building-ai-agents

Each entry: the problem, the move, and the question to put to the design.

---

## Part I — Configure the agent

### 1. Whiteboard agent capabilities
- **Problem:** a wishlist of dozens of automations ("outside-in") with no buildable shape.
- **Move:** treat it as org design. List every capability, group by shared data source,
  shared role, or shared API; split along natural divisions (owner, task type — fetching vs
  synthesis vs acting — or process step). Each group becomes an agent with its tools, ranked
  by priority.
- **Ask:** what is the full list, what are we missing, and which group is first?

### 2. Evolve your agent architecture
- **Problem:** the mega-agent. Wrong-tool choices rise with tool count and task complexity.
- **Move:** discover the architecture iteratively — build the one burning problem well, add
  a separate agent when the next request is separate, split an agent that grows unwieldy,
  add routing once there are several, and a coordinator in front if specialists need shared
  facts (coordinator → router → specialists).
- **Ask:** is this a new agent or a new tool for an existing one? Does each agent have a
  cohesive toolset and a clear success criterion?

### 3. Dynamic agents
- **Problem:** different users and situations need different behaviour; separate agents per
  variant do not scale.
- **Move:** configure prompt, tools, memory depth and model at runtime from signals such as
  user tier, preference or system state. Costs: more logic, harder testing.
- **Ask:** which runtime signals change behaviour, and is that variation tested?

### 4. Human-in-the-loop
- **Problem:** full autonomy is untenable where performance is uneven across task types,
  or where decisions need organisational, legal or ethical context.
- **Move:** human checkpoints, placed by risk. Three modes: human supplies input mid-run
  (agent pauses); human approves or edits a draft before it is final; deferred execution
  (agent carries on, human feedback is folded in asynchronously). Deferred fits real work
  best. Humans become the bottleneck.
- **Ask:** per action, which mode? What happens while the human is asleep?

---

## Part II — Engineer the context

### 5. Parallelize carefully
- **Problem:** parallel subagents working blind to each other produce incompatible parts.
- **Move:** where subtasks interact, run them as one linear multi-turn thread. Teams
  disagree (some coding agents avoid parallelism, others lean on it).
- **Ask:** are these subtasks genuinely independent?

### 6. Share context between subagents
- **Problem:** a subagent receives the conclusion ("I made it red") but not the reasoning.
- **Move:** pass the full trace, or run in sequence and check outputs along the way.
- **Ask:** does each subagent know *why*, not just *what*?

### 7. Avoid context failure modes
- **Problem:** context is not free; everything in it is attended to.
- **Five failures:** poisoning (an error that keeps being referenced), distraction (so
  much context the model ignores its training), confusion (irrelevant material used
  anyway), clash (new information contradicting old), rot (degradation past roughly 100k
  tokens even in large windows).
- **Move:** retrieve top-k instead of everything, prune, keep structured state and compile
  the prompt from it before each call.
- **Ask:** what is in context that does not need to be?

### 8. Compress context
- **Problem:** long runs overflow the window; quality falls before it fails.
- **Move:** compress every step, at a capacity threshold, by pruning the oldest, by
  recursive summarisation, after token-heavy tools, or at agent-to-agent hand-offs. Never
  compress away the specific events or decisions that must survive.
- **Ask:** where does context grow, and what must never be summarised?

### 9. Feed errors into context
- **Problem:** actions and generated code fail.
- **Move:** put the error, the attempt and relevant context back in and retry; log it to
  the thread. When an error recurs, write its fix into the prompt.
- **Ask:** what does the agent see when a step fails, and how many retries?

---

## Part III — Evaluate

### 10. List failure modes
- **Problem:** nondeterministic outputs have no clean pass/fail; a falling number does not
  say why.
- **Move:** classify failures by cause — data quality, reasoning, misapplied domain rules.
- **Ask:** what are the distinct reasons this agent gets it wrong?

### 11. List critical business metrics
- **Problem:** engineering metrics may not show whether the goal is met.
- **Move:** accuracy (false positives, false negatives), domain outcome metrics, and where
  it applies the human team's metric for the same task. Pick a north star — usually the
  costliest wrong action.
- **Ask:** what single number says this agent is hurting us?

### 12. Cross-reference failure modes and success metrics
- **Problem:** metrics alone are not actionable.
- **Move:** map each failure mode to the metric it moves; work the modes that move the
  north star. Loop: expert classifies failures → target set → engineers iterate on
  mode-specific datasets → validate against past production data → ship.
- **Ask:** which failure mode is driving the north star right now?

### 13. Iterate against your evals
- **Problem:** without a benchmark a change is just a change.
- **Move:** a test dataset run in CI; no merge that lowers accuracy without an offsetting
  gain; work from a stated baseline to a stated target.
- **Ask:** what is today's number and what is the target?

### 14. Create an eval test suite
- **Problem:** fixes break things far away; nothing is componentised.
- **Move:** a suite of criteria and expected behaviours built from synthetic data, trusted
  users, or an expert "golden answer" set of input/output pairs; score with a rubric,
  often an LLM judge in a loop. Replace synthetic data with production data over time.
- **Ask:** where do the golden answers come from?

### 15. Have domain experts label data
- **Problem:** engineers are usually not the domain experts; outsourced labelling breaks
  the loop between seeing a failure and understanding it.
- **Move:** experts build the first ground truth and keep reviewing production samples,
  flagged by guardrails, CI or automated evaluators. Grade plus category tags plus optional
  notes; several raters and agreement metrics where it matters. Give them a review UI that
  shows the output as the user sees it, with the full trace.
- **Ask:** who is the expert, and how cheap is it for them to label?

### 16. Create datasets from production data
- **Problem:** production logs are messy but are the realistic test cases.
- **Move:** curate logs into versioned datasets of inputs, expected outputs and metadata;
  store expert thumbs up/down to find new cases.
- **Ask:** how does a real outcome become a test case?

### 17. Evaluate production data
- **Problem:** users change; synthetic benchmarks drift from reality.
- **Move:** sample live outputs and grade with an LLM judge — binary or categorical, not
  numeric scores — plus periodic human review; cross-reference the two to find gaps.
- **Ask:** what fraction is sampled, and what judge criteria?

---

## Part IV — Secure

### 18. Prevent the lethal trifecta
- **Problem:** a model follows any instruction that reaches it. Private data + untrusted
  content + outbound communication = injectable data theft.
- **Move:** remove one leg. Usually the outbound leg: once untrusted input is ingested,
  nothing it says can trigger side effects. Or filter the exposure leg with input
  processors.
- **Ask:** does this agent have all three legs? Which one goes?

### 19. Sandbox code execution
- **Problem:** executed code can exfiltrate secrets, destroy shared environments or hog
  resources.
- **Move:** isolated, resource-limited, fast-starting sandboxes; meter resource use for
  long-running work.
- **Ask:** does the agent run code, and where?

### 20. Granular agent access control
- **Problem:** long-lived broad keys; agents are tirelessly diligent, so obscurity fails;
  overeager agents act without permission.
- **Move:** finer control than for a human — OAuth, per-tool-call permissions granted just
  in time, and a planning mode with programmatically lower permissions.
- **Ask:** what is the least privilege for each tool, and is there a dry-run mode?

### 21. Agent guardrails
- **Problem:** evals are after the fact; live bad inputs and outputs need stopping now.
- **Move:** input guardrails (injection, jailbreak, PII, off-topic) return a fixed response
  without spending tokens; output guardrails (leakage, hallucination, toxicity) retry or
  block, chunk by chunk when streaming. Name each guard by what it blocks.
- **Ask:** what must never go in, and what must never come out?

---

## Part V — Next

### 22. What's next
Expect more simulation to tune agent parameters against strong eval harnesses, agents that
learn from repetition, and automated eval generation.
