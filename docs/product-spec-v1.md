# Product Spec v1 — agentic-development
Derived from: idea-contract.md v0.3 (LOCKED), market-landscape.md (verdict: NARROW)
Amended 2026-09-25: hooks and a third target agent unparked from §11 on the operator's
instruction; content classification and an inventory view added to P0; the §7 complexity cap
raised once, with the number and the reason stated in that section.
Amended 2026-09-25 (second): §10's blanket "no GUI" non-goal narrowed to no server and no
hosted service, admitting one generated read-only HTML page. Discovery of unsupported agent
directories added — reporting only, never installing.

Framing note: single operator, no customers, no revenue. Sections that assume a market (price,
pilot) are answered in the equivalent personal terms — cost of ownership and first real use.

## 0. Value proposition in one line
Every agent on every machine the operator touches starts already knowing his doctrine, his
pipeline and his project rules, from one repo and one command.

## 1. First user and vertical
**Decision** — the operator himself, on Claude Code, Codex CLI and Aider, on the machines he
already uses. Aider added 2026-09-25 on the same test that admitted the other two: it is
installed here (`aider 0.86.2`), so the claim that it honours the doctrine is checkable rather
than asserted. **Why** — both agents are installed on this machine today (`codex` on PATH, `~/.codex/`
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
9. **Hooks as a content role** — added 2026-09-25. Hook scripts live in `hooks/` and are linked
   like any other role, and their declaration is merged into the agent's settings file. A hook
   the agent is not told about does nothing, so linking without declaring would not be a
   feature. The merge is additive: keys this repo does not own are never touched.
11. **Generated hub page** — added 2026-09-25. `bin/report.sh` renders the whole configured
    system as one self-contained HTML file: every file's contents, its category, and which
    targets take it, plus what was found on the machine that nothing supports. It is a view of
    the repo, never a source of truth for it — generated, gitignored, and regenerated rather
    than edited. Read-only by construction: it renders commands to copy and executes none.
12. **Agent discovery** — added 2026-09-25. The install path acts on the declared target table
    only. A scan reports directories that look like agent config but have no adapter, so an
    unsupported agent is visible rather than silently ignored. It never installs into one:
    finding `~/.gemini` proves a directory exists and says nothing about which file that agent
    reads, so writing into it would produce broken files in a format nobody verified.
10. **Inventory view** — added 2026-09-25. One command that reports what the configured system
    consists of, grouped by use case, with where each item lands. The operator's stated need is
    to *see* the system, not only to install it. Grouping comes from a `category:` field in each
    item's own header, so adding content changes the output and nothing else — no registry file
    to keep in step, which would violate contract invariant 5.

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
| Hooks reach | Every hook linked, declared and firing | Install to a scratch `HOME`; assert each script is a symlink, the settings file declares at least as many commands as there are scripts, and a probe payload returns the documented `deny` | Per release |
| Content classified | 0 uncategorised items | `bin/inventory.sh` groups every item under a named category; anything landing in `uncategorised` fails | Per release |
| Report coverage | Every inventory item appears on the page | Generate the page, count its skill/agent/command/hook entries against `bin/inventory.sh`; fewer fails | Per release |
| Report read-only | 1 file written, 0 config touched | Generate into a scratch `HOME` and checksum the config tree before and after; any difference fails | Per release |

**Stratification clause** — bars must hold in the hard conditions, not the average one:
machine with no prior agent directory at all (cold start); machine that already has a
hand-written `CLAUDE.md` (installer must not destroy it); machine whose `settings.json` already
holds hand-written keys (the hook merge must keep every one of them); machine without `jq` (hook
scripts still link, declaration degrades to a loud warning); and a re-run after local edits
(no silent overwrite). Failing any stratum means not shipped.

**The one that is the company**: *rule duplication = 1*. It is the whole thesis. If a standing
instruction ends up hand-maintained in two files, this is a dotfiles repo with extra steps, and
every other metric can pass while the project has failed.

## 7. Price shape
No price. Cost of ownership is the budget, and it is capped — as two budgets, not one,
because the two halves of this repo carry different risk.

| Budget | Files | Cap | Now |
|---|---|---|---|
| **Install path** | `bin/bootstrap.sh`, `bin/sync.sh`, `bin/stamp.sh`, `lib/` | **500 lines** | 497 |
| **Inspection tools** | `bin/inventory.sh`, `bin/report.sh`, `bin/capture.sh` | **500 lines** | 492 |

Both are close to the line. The next change to either half has to remove something first.
That is the cap working, not a problem to be solved by moving it.

No runtime dependency beyond `git` and `bash` on the install path. Exceeding either cap is the
signal to stop and adopt an external tool instead.

Cap history, and a correction. The original cap was one number — 500 lines across all of `bin/`.
It was raised to 700 earlier on 2026-09-25 to absorb the hooks role, the third target and the
inventory view. **That raise is retracted.** Raising a complexity cap to fit the code just
written is the exact failure the cap exists to catch, and doing it twice in one session would
have made the number meaningless.

What replaced it is a split, not a bigger number. The cap protects one specific thing: §3's
promise that a cold machine with nothing but `git` and `bash` reaches a configured state. Only
the install path can break that promise. `report.sh` and `inventory.sh` never run during an
install, are allowed to require `jq`, and can fail entirely without a machine being any less
configured — so holding them to the same budget as the installer measured the wrong risk. Under
the split the installer is back under its original 500 and has never exceeded it.

`jq` is a conditional dependency, not a new hard one. On the install path, its absence degrades
only the hook declaration, to a printed instruction. `report.sh` requires it outright and says so.

Not counted: `tests/` (never shipped), and `web/hub.template.html` (markup and styling, which is
content — the cap measures logic).

## 8. Pilot definition and first proof
One pilot = a second real machine, provisioned from zero with the documented one-liner, on which
a doctrine rule authored on machine A visibly changes agent behaviour in both Claude Code and
Codex without any local editing. Artefact: a short log in `docs/` recording date, machine, the
six bars measured, and anything that needed a manual step.

## 9. Frozen
- Author once; `AGENTS.md` is the primary instruction artefact.
- Public repo; all machine and personal content gitignored.
- Three target agents in v1: Claude Code, Codex CLI, Aider. A fourth is one row in
  `lib/targets.sh`, never a change to a script.
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
- **A server, a web framework, or a hosted service of any kind.** Narrowed 2026-09-25 from
  "a GUI of any kind". What is now allowed is exactly one thing: a generated, self-contained,
  read-only HTML file, produced by a shell script from the same data the terminal tools read,
  opened from the filesystem. What stays excluded is anything with a process behind it — a dev
  server, a framework, a build step, a package manager, a page that can change the system. The
  line is not "graphical vs terminal", it is **whether anything must be running**. A file is a
  file; a service is a new thing to own, and §3's zero-dependency bootstrap forbids it.
- **A page that acts.** The hub renders commands for the operator to run. It never installs,
  edits, deletes or executes. An interactive control would need a server, which is the
  non-goal above, and would put a second promotion path beside the curator.

## 11. Not in v1
Real, deferred, named so they stop leaking in.
- Cursor, Copilot, Windsurf, Gemini CLI targets — none of them installed here, so support would
  be written blind. Each is one row in `lib/targets.sh` on the day one appears.
- MCP server definitions synced across agents.
- LLM-assisted setup that reads the machine and decides what to install.
- Installing into a discovered but undeclared agent. Discovery reports; adding support stays a
  deliberate row in `lib/targets.sh`, written against that agent's actual documented format.
- Automatic sync on session start or exit (pull-on-open, push-on-close).
- Unattended promotion — the curator always proposes, the operator always approves. Added v0.3.
- Multi-operator or team use.
- Migrating transport to `agentsync` — revisit when it reaches v1.0.
- Per-machine conditional content beyond `profile.md`.
- Hooks *translated between* agents. Partially unparked 2026-09-25: hooks now install and are
  declared for Claude Code, whose format they are written in. Rewriting a Claude hook into
  another agent's hook system stays out — that is the lossless-translation non-goal.

## 12. Open — blocking
- Is a spare machine or clean VM available to run the §8 pilot?  ·  default: assume a container
  stands in for it, and record that the two-machine proof is pending.
- Should `~/.codex/AGENTS.md` be overwritten if it already holds hand-written content?  ·
  default: never overwrite; back it up and warn.
