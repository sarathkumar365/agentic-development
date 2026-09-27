# Build Plan v1 — agentic-development
Traces to: product-spec-v1.md, stack-v1.md

## B0 enabler — the contract every other block talks through

There are no types in a shell project, so the enabler is the two data shapes the scripts agree
on. Getting these wrong is what forces a rewrite later, which is why they are block zero.

### Content role
What the repo publishes, named by role rather than by any agent's directory name (stack §
"content root").

| Field | Values | Meaning |
|---|---|---|
| `role` | `doctrine` \| `skills` \| `agents` \| `commands` \| `profile` | What the content is for |
| `source` | path relative to repo root | Where it lives here |
| `kind` | `file` \| `dir-of-items` | Whether the whole path installs, or each child installs |
| `required` | `yes` \| `no` | Whether a target that cannot accept this role is an error or a skip |

Roles in v1: `doctrine` → `AGENTS.md` (file, required); `skills` → `skills/` (dir-of-items);
`agents` → `agents/` (dir-of-items); `commands` → `commands/` (dir-of-items);
`profile` → `home/profile.md.example` (file, seeded once, never relinked).

### Target adapter
One per agent product. Holds only that agent's knowledge (stack § "target adapter").

| Field | Meaning | Claude Code | Codex CLI |
|---|---|---|---|
| `id` | short name | `claude` | `codex` |
| `root` | config dir | `~/.claude` | `~/.codex` |
| `detect` | how to tell it is installed | `~/.claude` exists or `claude` on PATH | `~/.codex` exists or `codex` on PATH |
| `doctrine_path` | where standing instructions go | `CLAUDE.md` | `AGENTS.md` |
| `doctrine_mode` | `import` or `link` | `import` — a stub with `@` pointing at the source | `link` — symlink straight to the source |
| `accepts` | roles it can take | doctrine, skills, agents, commands | doctrine, skills |
| `restart_hint` | what the operator must do after install | restart Claude Code | new `codex` session |

Adding Cursor later is one more column, not a change to any script. That property is the point of
B0 and is what B1 verifies.

## Scope correction (2026-09-21)

The first cut of this plan had thirteen blocks, of which six were adapter, link-layer and
registry work — that is the sync engine Phase 1 said not to build. Corrected: the existing
`bin/sync.sh` (267 lines, already symlinking, already idempotent in practice) is extended in
place rather than re-architected. No external tool is adopted; `agentsync` stays parked at its
v1.0. The blocks below are what is actually missing.

The B0 contract above is kept, but shrinks to a convention inside `sync.sh` rather than a
`lib/` layer of its own: one table of target definitions at the top of the file. It earns a
`lib/` only when a third target arrives.

## Block table

| ID | Block | Depends on | Done when | Notes |
|----|-------|-----------|-----------|-------|
| B1 | Doctrine source — author `AGENTS.md` at repo root; `home/CLAUDE.md` becomes a stub that imports it | — | The canary sentence appears exactly once repo-wide in a non-generated file; `home/CLAUDE.md` carries no rule text of its own; a Claude session started against the installed tree still obeys a doctrine rule | Pure content move. Serves the "rule duplication = 1" bar directly |
| B2 | Target table in `sync.sh` — the two agents declared as data at the top of the file | B1 | `grep -n '\.claude\|\.codex' bin/sync.sh` shows hits only inside the table; adding a third row is the only edit a new agent needs | The shrunk B0. Convention, not a framework |
| B3 | Codex target — `~/.codex/AGENTS.md` and `~/.codex/skills/` fed from the same source | B2 | `~/.codex/AGENTS.md` resolves to the repo doctrine; a hand-written file there is backed up and the operator warned, never silently replaced; a fresh `codex` session obeys a doctrine rule | Makes the wedge true rather than claimed |
| B4 | Curator agent — reads uncommitted local changes, proposes durable skills, agents or doctrine amendments, commits only what is approved | B1 | Given three local edits of which one is durable, it proposes that one, explains why the other two are noise, and commits nothing without an explicit yes | The self-improvement loop. Replaces `capture.sh`'s indiscriminate adoption |
| B5 | Retire `capture.sh` — deprecate or reduce it to the plumbing the curator calls | B4 | No documented path commits local changes without review; `capture.sh` either no longer exists or is invoked only by the curator | Two promotion paths is the failure mode this avoids |
| B6 | Ship-criteria harness — the seven §6 bars as executable checks against a scratch `HOME` | B1, B2, B3 | `tests/criteria.sh` prints pass/fail per bar with the measured number; at least one bar can be made to fail by reverting a block | Without it the spec numbers are decoration |
| B7 | Hard strata — cold machine, and a machine with hand-written agent files | B3, B6 | In a container with only `git` and `bash`, the documented one-liner configures the machine with zero manual steps and a re-run changes nothing; installing over hand-written `CLAUDE.md` and `AGENTS.md` backs both up with a warning | Spec §6 strata 1–3 |
| B8 | Project stamping — one command writes a target repo's `AGENTS.md` plus per-agent shims | B1, B2 | Run against an empty git repo: `AGENTS.md` exists, any `CLAUDE.md` holds no duplicated rule text, a session opened there obeys a project rule, and an existing `AGENTS.md` is refused not overwritten | Replaces `templates/project-skeleton/init.sh` |
| B9 | CI — GitHub Actions running `tests/criteria.sh` and `shellcheck` | B6 | A pull request with a shellcheck violation or a failing bar is red | The only place shellcheck is mandatory |
| B10 | README and docs rewritten to the narrowed idea | B3, B4, B8 | README describes a content library with a thin installer, names `AGENTS.md` as primary, documents curated promotion, and no longer claims to be a general sync engine | The current README sells the thing Phase 1 killed |

## Blocks added 2026-09-25

The operator asked for five things the narrowed v1 did not cover: use-case classification, a way
to see the configured system, hooks, a bigger skill library, and more target agents. Four are
blocks; the fifth is content, not code, and is handled below under Blocked.

| ID | Block | Depends on | Done when | Notes |
|----|-------|-----------|-----------|-------|
| B11 | Classification — every skill, agent, command and hook declares `category:` in its own header | B1 | `bin/inventory.sh` reports 0 uncategorised items, and adding a category requires editing no index | Contract invariant 5 forbids a registry, so the field lives with the content |
| B12 | Inventory view — `bin/inventory.sh`, grouped by category, plus `--roles` for per-role and per-target counts | B11, B2 | One command shows every item, its role, its summary and which targets take it | Contract invariant 8 (legibility). This is the "see my system" requirement |
| B13 | Hooks role — `hooks/` linked like any other role, declared by an additive `jq` merge into the agent's `settings.json` | B2 | Scripts are symlinks, the settings file declares them, a probe payload returns the documented verdict, and every pre-existing settings key survives | Push-to-main deliberately stays a project hook, not a global one |
| B14 | Third target — Aider, via a new `conf` doctrine mode and a `conf_file` column | B2, B3 | `~/.aider/AGENTS.md` resolves to the repo doctrine and `~/.aider.conf.yml` names it; a hand-written conf is never edited, only reported | Proves the one-row property with an agent that reads no instruction file by default |
| B15 | Bars and strata for the above, plus the complexity cap split into install-path and inspection budgets in spec §7 (the 700-line raise was retracted) | B11-B14, B6 | `tests/criteria.sh` reports 11 bars; the container stratum asserts the jq-absent path warns rather than fails | The cap raise is written down because the cap exists to catch exactly this growth |

| B16 | Hub page — `bin/report.sh` renders the system as one self-contained read-only HTML file, with a markdown renderer, a file tree and per-file install state | B11, B12 | Every inventory item appears on the page, a scratch `HOME` is byte-identical before and after generating it, and the page opens with no server and no network | Needs spec §10 narrowed from "no GUI" to "no server". Template lives in `web/`, not `bin/`, so the cap measures shell code |
| B17 | Discovery — report agent directories present on the machine with no row in `lib/targets.sh` | B2 | A known-agent directory with no adapter is listed on the page and by nothing else; no install path ever writes into one | Report, never install: a directory name does not tell you the format |

**Thread 5 — seeing it.**
B16 → B17.
Done when: one file, opened from disk, shows every skill's text, every hook's script, which
agents take each, and what is installed here that nothing supports.

**Thread 4 — the hub as a hub.**
B11 → B12, and B13 → B14 in parallel, both closing at B15.
Done when: one command shows the whole configured system grouped by use case, hooks install and
fire, and three agents read one doctrine.

## Threads

**Thread 1 — the wedge.**
B1 → B2 → B3
Done when: a doctrine rule written once in `AGENTS.md` changes how both Claude Code and Codex
behave on this machine, with no copy of that rule anywhere else.

**Thread 2 — the loop.**
B4 → B5
Done when: a week of local edits produces a reviewed, committed improvement to the repo, and
nothing unapproved was ever committed.

**Thread 3 — proof and truth.**
B6 → B7 → B8 → B9 → B10
Done when: all seven ship-criteria bars report measured pass in the hard strata, CI gates them,
and the documentation describes what the system actually is.

## Harness
B6 (`tests/criteria.sh`) is the harness, and it is the only one — the earlier plan's separate
general harness was overhead for a 300-line shell project. It runs against a scratch `HOME` so
the cold-machine case is testable without a container, and B7 adds the container run on top.

## Blocked
| Item | Unblocked by |
|---|---|
| B18 portability | Done 2026-09-27: `rlf`/`sort0` in `lib/targets.sh`, no `find -printf`, no `grep --exclude-dir`; suite green under GNU and BusyBox. Remaining macOS risk is paths and bash 3.2, which only a Mac can settle |
| Two-machine pilot (spec §8) | A second physical machine or a clean VM. B7's container stands in meanwhile; the claim "works on any machine" is not made until the pilot runs. Container run logged in docs/pilot-log.md |
| A skill library beyond the idea pipeline (coding, scraping, infra categories) | The operator naming the workflows he actually repeats. The taxonomy and the inventory that will hold them are done; inventing skills for guessed workflows would put untriggerable content in every session's context, which is worse than an empty category |
| Cursor, Copilot, Windsurf, Gemini CLI targets | One of them being installed on a machine. Each is one row in `lib/targets.sh` |
| Exactly what Codex reads for skills and commands | Inspecting `~/.codex/skills/` and the installed Codex version during B3. Until then B3 assumes doctrine and skills only |

## Parked
| Decision | Forced by |
|---|---|
| Adopt `agentsync` as transport | Its v1.0. B2 is the only block that would change |
| A real `lib/` layer for targets | The third target agent |
| Windows / WSL and macOS paths | First such machine |
| MCP server definitions | Spec §11, not in v1 |
| Installed-file registry for exact uninstall | First time a stale link causes a real problem |
| Copy mode (`--copy`) survival | B2 — decide whether a copy fallback still earns its branch |
