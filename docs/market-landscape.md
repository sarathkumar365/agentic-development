# Market Landscape — agentic-development, September 2026

Scope note: this is personal infrastructure for a single operator, not a venture. "Market" here
means prior art and build-vs-adopt. Sections 1 and 7 are answered in that frame.

## 1. Market shape
No market to size. The relevant question is whether the capability is already free and
maintained by someone else. It largely is. Agent-config portability went from a personal
scripting problem to a governed standard inside twelve months: `AGENTS.md` was published by
OpenAI in August 2025, transferred to the Linux Foundation's Agentic AI Foundation in late 2025,
had 60,000+ repositories by December 2025, and is now read by 30+ agents. Claude Code added
`AGENTS.md` fallback in v2.1.278 on 2026-09-19 — two days before this contract was locked.
Direction: consolidation onto one neutral file, fast.

## 2. Vendor segments
| Segment | Examples | Fit |
|---|---|---|
| The standard itself | `AGENTS.md` (AAIF / Linux Foundation) | Removes most of the render problem for *instruction text* |
| Cross-agent render + sync tools | `agentsync` (MIT, Go, v0.15.0, ~10 stars), `agent-dotfiles` (MIT, 6 agents) | Direct overlap with invariants 1–4 |
| Generic dotfile managers | chezmoi, bare-git, GNU stow | Transport only; no per-agent translation |
| Claude-only syncers | `claude-code-dotfiles`, various gists | What this repo is today |

We would sit in segment 2, competing with MIT tools that already ship.

## 3. Already commodity — not differentiation
- Rendering one instruction source into per-agent files. `agentsync`, `agent-dotfiles`, and
  `AGENTS.md` itself all do this.
- Syncing a directory across machines with one idempotent command. chezmoi, bare-git, any
  dotfile manager.
- Drift detection and bidirectional reconcile between source and installed config. `agentsync`
  ships it, with per-agent git history and `revert`.
- Global + project scope split. `agentsync` supports both.
- Cross-agent MCP server, skill, subagent, command and hook translation. `agentsync`: 10 deep
  adapters, 22 breadth-tier, 32 agents total.
- Machine-specific templating and secret references. chezmoi templates; `agentsync`
  `${secret:...}` refs.

Every one of the five locked invariants sits in this list. That is the finding.

## 4. Frontier
- `AGENTS.md` under neutral governance (AAIF) with the last major holdout (Claude Code) adopting
  it in September 2026. The consequence is concrete: for *instruction text*, the neutral source
  and the rendered artefact are now the same file for most agents. The render layer shrinks to
  a compatibility shim for the few that need a different filename.
- What is not converged: skills, subagents, commands, hooks, MCP server definitions and plugin
  manifests remain per-vendor with lossy cross-translation. `agentsync` documents its own lossy
  projections (Codex, Cursor, Gemini), and notes OpenCode hooks are not auto-translated from
  Claude. This is where portability is still genuinely unsolved.

## 5. Regulatory constraints that shape the spec
None material. Single operator, no personal data processed, no distribution to third parties.
The one real constraint is self-imposed and load-bearing: the repo is public, so no secrets,
tokens or machine identifiers may enter it. Consequence: any secret-referencing feature must
resolve from outside the repo, never store inside it — which rules out adopting an
encrypted-in-repo secrets model.

Licence check: `agentsync` MIT, `agent-dotfiles` MIT, chezmoi Apache-2.0, `AGENTS.md` spec open.
No AGPL, no patent traps, no research-only terms. Adoption is legally free.

## 6. Real gaps that survive scrutiny
1. **The content, not the mechanism.** No tool ships the operator's doctrine, the six-phase gated
   idea pipeline, the drift-check agent, or the project skeleton. These are the actual asset and
   nothing external replaces them. Incumbents cannot close this — it is personal and opinionated
   by definition.
2. **Non-instruction portability is still lossy.** Skills, hooks and subagents do not translate
   cleanly between agents. Unsolved by everyone, including `agentsync`, which documents it as a
   known limit.
3. **Maturity risk in the one tool that fits.** `agentsync` is v0.15.0, ~10 stars, effectively
   one maintainer, with open issues about non-hermetic tests and accreting domain logic. It is
   the right shape but not yet a dependency to bet a workstation on.
4. **Symlink-vs-reconcile conflict.** This repo's no-drift mechanism is symlinks; `agentsync`
   rejects symlinked destinations by default (`AGENTSYNC_ALLOW_SYMLINK_DEST=1` to override) and
   solves drift by reconcile instead. The two models do not compose — one must be chosen.

Gap 1 is real and durable. Gaps 2–4 are reasons not to adopt blindly, not reasons to build a
render engine.

## 7. Economics
Cost today is the operator's time re-stating instructions per chat and re-configuring per
machine. Build cost of a general render-and-sync engine: weeks, competing with free MIT tools.
Build cost of the content layer on top of an existing transport: days. The ceiling on what a
bespoke engine can be worth is therefore near zero, because the substitute is free, maintained,
and already broader than anything one operator will write.

## 8. Verdict
**NARROW**

Building a vendor-neutral render-and-sync engine is redundant: `AGENTS.md` under Linux Foundation
governance now covers instruction text for 30+ agents including Claude Code as of 2026-09-19, and
`agentsync` already covers the rest under MIT. The part that survives is the content — doctrine,
the gated idea pipeline, agents, project skeleton — which no external tool ships and never will.
Narrow to: author content in neutral form with `AGENTS.md` as the primary target, keep the
installer thin, and treat cross-agent translation of skills and hooks as a shim to add only where
the standard genuinely does not reach.

Contract amendment required: invariant 1 is retained but its scope shrinks (render is a thin
shim over a standard, not a translation engine), and "build a general multi-agent sync engine"
becomes an explicit non-goal.

## Sources
- [Claude Code adopts AGENTS.md standard (2026-09-19)](https://enterprisedna.co/resources/ai-pulse/ai-pulse-2026-09-19-claude-code-adopts-agents-md-standard/)
- [Claude Code adds AGENTS.md fallback](https://runtimewire.com/article/claude-code-adds-agents-md-support)
- [AGENTS.md Spec 2026 — vs CLAUDE.md vs .cursorrules](https://www.morphllm.com/agents-md-guide)
- [AGENTS.md guide — Copilot, Cursor and more](https://vibecoding.app/blog/agents-md-guide)
- [Agent instruction files and cross-tool portability, Codex CLI](https://codex.danielvaughan.com/2026/05/27/agent-instruction-files-agents-md-claude-md-cross-tool-portability-codex-cli/)
- [agentsync — canonical source, 32 agents, MIT](https://github.com/spxrogers/agentsync)
- [agentsync release v0.15.0 (2026-09-19)](https://github.com/spxrogers/agentsync/releases/tag/v0.15.0)
- [agentsync issue #270 — non-hermetic test suite](https://github.com/spxrogers/agentsync/issues/270)
- [agentsync issue #243 — repo bloat / comment density](https://github.com/spxrogers/agentsync/issues/243)
- [agent-dotfiles — write rules once, 6 agents, MIT](https://github.com/saqibameen/agent-dotfiles)
- [claude-code-dotfiles — git-sync ~/.claude](https://github.com/elizabethfuentes12/claude-code-dotfiles)
- [Managing five AI coding agents from one dotfiles repo (chezmoi)](https://www.jayantak.com/writing/managing-five-ai-agents-with-chezmoi/)
- [chezmoi — machine-to-machine differences](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/)
- [Sync Claude Code config across machines with chezmoi](https://www.frxiaobei.com/en/posts/2026/04/chezmoi-claude-code/)
