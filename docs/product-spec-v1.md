# Product Spec v1 — agentic-development
Derived from: idea-contract.md v0.2 (LOCKED), market-landscape.md (verdict: NARROW)

Framing note: single operator, no customers, no revenue. Sections that assume a market (price,
pilot) are answered in the equivalent personal terms — cost of ownership and first real use.

## 0. Value proposition in one line
Every agent on every machine the operator touches starts already knowing his doctrine, his
pipeline and his project rules, from one repo and one command.

## 1. First user and vertical
**Decision** — the operator himself, on Claude Code and Codex CLI, on the machines he already
uses. **Why** — both agents are installed on this machine today (`codex` on PATH, `~/.codex/`
present with its own `skills/`), so both targets are testable immediately and neither is
hypothetical. **Rejected** — Cursor, Copilot, Windsurf: not installed, so support would be
written blind and unverifiable; adding them later costs one shim each. Other people: contract
says single operator.

## 2. Wedge
One authored doctrine file reaches both Claude Code and Codex CLI on any machine, with no
per-agent copy of the rules and no manual step after a single install command.

## 3. Deployment form
**Decision** — public git repo plus an idempotent shell installer, linking content into each
agent's config directory. **Why** — hard constraint is zero-dependency bootstrap: a fresh
machine may have nothing but `git` and `bash`, and the installer must work before any package
manager or runtime is configured. **Rejected** — adopting `agentsync` as the transport: v0.15.0,
~10 stars, one maintainer, and it rejects symlink destinations by default, which conflicts with
the no-drift mechanism; re-evaluate at v1.0 or 500 stars. chezmoi: adds a dependency and a
templating language for a problem four shell scripts already solve. A packaged CLI in Go or
Node: needs a runtime present before the runtime is configured.

## 4. Jurisdiction and compliance posture
Not applicable — no data processed, no distribution, no third parties. The operative constraint
is self-imposed: the repo is public, so no secrets, tokens, hostnames or transcripts may enter
it. Machine-specific content lives in gitignored `profile.md`. Any feature that would require a
secret in-repo is out of scope by construction.

## 5. P0 surface
Seven items. Each is load-bearing for the wedge in §2.

1. **Neutral doctrine source** — one authored file, `AGENTS.md`-shaped, the single place standing
   instructions are written.
2. **Claude Code target** — `~/.claude/CLAUDE.md` as a pointer to the doctrine, not a copy.
3. **Codex CLI target** — `~/.codex/AGENTS.md` fed from the same source.
4. **Portable content install** — `skills/`, `agents/`, `commands/` reach both agents' config
   directories, degrading gracefully where an agent has no equivalent.
5. **One idempotent install command** — fresh machine to configured, re-runnable, no manual step.
6. **No-drift mechanism** — edits made to installed config while working are already repo
   changes. Symlinks today; the mechanism is frozen, the implementation is not.
7. **Project rule stamping** — a command that writes a project's `AGENTS.md` and per-agent shims
   into a target repo.
8. **Curator** — added v0.3. An agent that reads the repo's uncommitted local changes, proposes
   what should become a durable skill, agent or doctrine amendment, and commits only what the
   operator approves. Replaces `capture.sh`, which adopts indiscriminately.

## 6. Ship criteria

| Metric | Bar | How measured | Window |
|---|---|---|---|
| Cold-machine time to configured | ≤ 5 min, 0 manual steps | Clean container, run the documented one-liner, stopwatch; any prompt other than a sudo or auth prompt counts as a manual step | Per release |
| Rule duplication | Exactly 1 authored copy of any standing instruction | `grep` a canary sentence across the repo and both installed config trees; more than one non-generated, non-symlinked hit fails | Per release |
| Cross-agent reach | 2 of 2 target agents honour the doctrine | Open a fresh session in Claude Code and in Codex, issue a prompt whose correct response depends on a doctrine rule, check both comply | Per release |
| Drift loss | 0 edits lost | Edit an installed file in each agent's config dir, run install again, run `capture.sh`, confirm the edit is in git history | Per release |
| Idempotence | Byte-identical tree on re-run | Run installer twice, `diff -r` the two resulting config trees | Per release |
| Project stamp time | ≤ 30 s to rules-in-effect | Stamp an empty repo, open an agent session in it, confirm project rules apply | Per release |
| Curated promotion | 0 unapproved commits; ≥ 1 real improvement promoted | Make three local edits, two of them throwaway; run the curator; exactly the durable one is proposed, and nothing is committed without approval | Per release |

**Stratification clause** — bars must hold in the hard conditions, not the average one:
machine with no prior `~/.claude` or `~/.codex` (cold start); machine that already has a
hand-written `CLAUDE.md` (installer must not destroy it); and a re-run after local edits
(no silent overwrite). Failing any stratum means not shipped.

**The one that is the company**: *rule duplication = 1*. It is the whole thesis. If a standing
instruction ends up hand-maintained in two files, this is a dotfiles repo with extra steps, and
every other metric can pass while the project has failed.

## 7. Price shape
No price. Cost of ownership is the budget, and it is capped: total shell code across `bin/`
stays under 500 lines, and the system adds no runtime dependency beyond `git` and `bash`.
Exceeding either is the signal to stop and adopt an external tool instead.

## 8. Pilot definition and first proof
One pilot = a second real machine, provisioned from zero with the documented one-liner, on which
a doctrine rule authored on machine A visibly changes agent behaviour in both Claude Code and
Codex without any local editing. Artefact: a short log in `docs/` recording date, machine, the
six bars measured, and anything that needed a manual step.

## 9. Frozen
- Author once; `AGENTS.md` is the primary instruction artefact.
- Public repo; all machine and personal content gitignored.
- Two target agents in v1: Claude Code, Codex CLI.
- Installer is shell only, depends on `git` and `bash` alone.
- No-drift is a property, not an optimisation — a copy-based sync is not acceptable.
- Existing repo is evolved, not replaced.

## 10. Non-goals
Inherited from the contract, plus one added here.
- Secrets management.
- Dotfiles manager for shell, editor or OS.
- Machine provisioning beyond recording facts in `profile.md`.
- A general multi-agent config translation or sync engine.
- Lossless cross-agent translation of skills, hooks and subagents.
- **Added here: a GUI, web UI, or hosted service of any kind.** Terminal and files only.

## 11. Not in v1
Real, deferred, named so they stop leaking in.
- Cursor, Copilot, Windsurf, Gemini CLI targets.
- MCP server definitions synced across agents.
- LLM-assisted setup that reads the machine and decides what to install.
- Automatic sync on session start or exit (pull-on-open, push-on-close).
- Unattended promotion — the curator always proposes, the operator always approves. Added v0.3.
- Multi-operator or team use.
- Migrating transport to `agentsync` — revisit when it reaches v1.0.
- Per-machine conditional content beyond `profile.md`.
- Hooks and settings translated between agents.

## 12. Open — blocking
- Is a spare machine or clean VM available to run the §8 pilot?  ·  default: assume a container
  stands in for it, and record that the two-machine proof is pending.
- Should `~/.codex/AGENTS.md` be overwritten if it already holds hand-written content?  ·
  default: never overwrite; back it up and warn.
