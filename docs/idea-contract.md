# Idea Contract — agentic-development v0.1
Status: LOCKED  ·  Date: 2026-09-21

## One line
A git repo that is the single source of truth for how every AI coding agent on every machine the
operator uses is configured.

## The thing itself
The operator moves between machines and between agent products (Claude Code, Codex, Copilot, and
others). Each one needs the same standing instructions — how to respond, what principles to
follow — plus per-project rules, plus the skills, scripts and MCP servers that make the agent
useful. Today that is re-stated per chat and re-created per machine. This repo holds that content
once in a vendor-neutral form, renders it into whatever file each agent reads, and installs it on
a new machine with one command. It also serves as the central place where new general-purpose
skills, scripts and tool definitions accumulate over time.

## Invariants
1. **Vendor-neutral source, generated adapters.** Content is authored once in a neutral form.
   Per-agent files (`CLAUDE.md`, `AGENTS.md`, Codex config, Copilot instructions) are rendered
   from it. The same rule is never hand-maintained in two places.
2. **Two config layers stay distinct.** Global doctrine (applies to every session, every project)
   and project rules (apply to one repo) are separate inputs with separate lifecycles.
3. **One idempotent command per machine.** A new machine becomes a configured workstation with a
   single command, re-runnable any time with no manual steps.
4. **No drift.** Edits made to the installed config while working are repo changes, not a
   divergent copy that a later sync silently discards.
5. **Open-ended hub.** Adding a new skill, script, MCP server or agent definition requires no
   change to the system's structure.

## Non-goals
- **Secrets management** — no tokens, keys or credentials stored or distributed. The repo is
  public; secrets are a different threat model and a different tool.
- **Dotfiles manager** — shell, editor, terminal and OS configuration are out. Agent
  configuration only.
- **Machine provisioning** — installing runtimes, drivers or hardware setup is out, beyond
  recording machine facts in a per-machine profile.
- UNSTATED whether team/multi-operator use is excluded. Written as single-operator.

## Success shape
- Arriving at an unconfigured machine, one command yields agents that already behave to doctrine,
  with no chat-level re-instruction.
- A standing instruction is written in one file and takes effect in every agent product.
- A skill built while working on machine A is present on machine B without a manual copy step.
- Starting a new project applies its rules without re-deriving them.

## Resolved at lock (defaults accepted)
- Which agent products must be supported in v1? — resolved to default: Claude Code + Codex +
  one `AGENTS.md`-reading agent. Copilot deferred.
- Does the rendering step run deterministically, or may it call an LLM?  ·  default:
  deterministic in v1; LLM-assisted setup is a later, optional layer.
- Is the repo to stay public? — resolved to default: yes, with per-machine and personal content
  gitignored, as today.
- Single operator, or shared with others? — resolved to default: single operator.

## Assumed — correct me
- **Evolve the existing repo rather than starting a new one** — it already holds the doctrine,
  skills and install scripts; the change is generalising the render layer. Rejected: greenfield
  repo — discards working content for no gain.
- **Global and project layers are both in scope for v1** — the operator named both as the pain.
  Rejected: global-only v1 — leaves half the repetition in place.
- **Install mechanism, config format and prior-art question are left open** — the operator
  explicitly said he does not know these. Rejected: deciding them here — that is Phase 1–3 work
  and would be drift.
