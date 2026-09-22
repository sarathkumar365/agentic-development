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

## Block table

| ID | Block | Depends on | Done when | Notes |
|----|-------|-----------|-----------|-------|
| B0 | Role + adapter contract, declared as data in `lib/targets.sh` and `lib/content.sh` | — | Both files source cleanly under `bash -n` and `shellcheck`; a throwaway caller prints the full role×target matrix including which pairs are skips; no agent path appears anywhere outside `lib/targets.sh` (grep proves it) | Data and pure functions only, no filesystem writes |
| B1 | Test harness — scratch `HOME`, assertions, cold-machine fixture | B0 | `tests/run.sh` passes on an empty scratch `HOME` and fails loudly when a deliberately broken assertion is introduced; runs with zero network and zero installed agents | Joins Thread 1 first, not last — every later block's *Done when* is checked by it |
| B2 | Link layer — one idempotent `install_one` with backup, extracted from `sync.sh` | B0, B1 | Called twice, the second call writes nothing and the tree is byte-identical (`diff -r`); a pre-existing real file at the destination is moved to `backups/<stamp>/` and never deleted; a path containing a space survives | The single seam that makes the symlink-vs-copy mechanism swappable |
| B3 | Doctrine source — author `AGENTS.md` at repo root from `home/CLAUDE.md`; `home/CLAUDE.md` becomes a stub that imports it | B0 | The canary sentence appears exactly once across the repo in a non-generated file; `home/CLAUDE.md` contains no rule text of its own; a Claude session started against the installed tree still obeys a doctrine rule | Content move, no script changes. Directly serves the "rule duplication = 1" bar |
| B4 | Claude adapter — `sync.sh` drives targets through B0/B2 instead of hardcoded `~/.claude` paths | B0, B2, B3 | `sync.sh` produces the identical tree it produces today (`diff -r` against a pre-change capture); `grep -r '\.claude' bin/` returns nothing | Refactor with a before/after fixture as the proof |
| B5 | Codex adapter — `~/.codex/AGENTS.md` and `~/.codex/skills/` fed from the same source | B0, B2, B3, B4 | After install, `~/.codex/AGENTS.md` resolves to the repo doctrine; an existing hand-written `~/.codex/AGENTS.md` is backed up and the operator warned, never silently replaced; a fresh `codex` session obeys a doctrine rule | Second target is what makes the wedge true rather than claimed |
| B6 | Installed-file registry — record what was linked, so status and uninstall are exact | B2, B4 | `sync.sh --status` reports `linked` for every installed path on a fresh install and `diverged` after a destination is replaced by a real file; removing a skill from the repo makes its stale link visible | Today status re-derives by walking the repo; that cannot see what an earlier version installed |
| B7 | Ship-criteria harness — the six §6 bars as executable checks | B1, B4, B5 | `tests/criteria.sh` prints pass/fail per bar with the measured number; at least one bar can be made to fail by reverting a block | Named explicitly per Phase 4 step 4. Without it the spec numbers are decoration |
| B8 | Cold-machine stratum — `bootstrap.sh` verified in a clean container | B4, B5, B7 | In a container with only `git` and `bash`, the documented one-liner reaches a configured state in ≤ 5 min with zero manual steps; re-running changes nothing | Covers strata 1 and 3 from spec §6 |
| B9 | Pre-existing-config stratum — never destroy a hand-written agent file | B2, B5, B8 | Install onto a `HOME` that already has hand-written `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`: both are backed up, both backups are readable, and the operator sees a warning naming each | Spec §6 stratum 2 and spec §12's second blocking question, answered as "never overwrite" |
| B10 | Project stamping — one command writes a target repo's `AGENTS.md` plus per-agent shims | B0, B3 | Run against an empty git repo: `AGENTS.md` and `CLAUDE.md` exist, `CLAUDE.md` holds no duplicated rule text, and a session opened in that repo obeys a project rule; refuses to overwrite an existing `AGENTS.md` | Replaces `templates/project-skeleton/init.sh` with the adapter-driven version |
| B11 | CI — GitHub Actions running `tests/run.sh`, `tests/criteria.sh`, `shellcheck` | B1, B7 | A pull request with a shellcheck violation or a failing bar is red; a clean one is green | Stack §: the only place shellcheck is mandatory |
| B12 | README and docs rewritten to the narrowed idea | B4, B5, B10 | README describes a content library with a thin installer, names `AGENTS.md` as primary, and no longer claims to be a general sync engine; the three-properties table matches the v0.2 contract | The current README sells the thing Phase 1 killed |

## Threads

**Thread 1 — thin end-to-end, nothing clever.**
B0 → B1 → B2 → B3 → B4 → B5
Done when: a doctrine rule written once in `AGENTS.md` changes how both Claude Code and Codex
behave on this machine, with no copy of that rule anywhere else.

**Thread 2 — quality, where the spec's numbers get checked.**
B6 → B7 → B8 → B9 → B11
Done when: all six ship-criteria bars in spec §6 report measured pass, including in the three
hard strata, and CI fails a pull request that breaks any of them.

**Thread 3 — the loop, where the system takes on new work without structural change.**
B10 → B12
Done when: a brand-new project gets its rules in under 30 seconds, and the documentation
describes what the system actually is.

## Harness
B1 (`tests/run.sh`) is the general harness; B7 (`tests/criteria.sh`) is the ship-criteria harness.
B1 joins Thread 1 as its second block, deliberately before any behaviour is refactored, so that
B2–B5 have a before/after fixture to prove against rather than an assertion that nothing broke.
B7 joins Thread 2 and is what turns spec §6 from prose into a gate.

## Blocked
| Item | Unblocked by |
|---|---|
| Two-machine pilot (spec §8) | A second physical machine or a clean VM. B8's container stands in meanwhile; the pilot stays recorded as pending, and the claim "works on any machine" is not made until it runs |
| Exactly what Codex reads for skills and commands | Inspecting `~/.codex/skills/` and the installed Codex version during B5. Until then B5 assumes doctrine + skills only, and `commands` is a skip for that target |

Neither blocks Thread 1. Nothing else waits on anything external.

## Parked
| Decision | Forced by |
|---|---|
| Adopt `agentsync` as transport | Revisit at its v1.0. B2 is the only block that would change |
| Windows / WSL paths | First Windows machine. Would touch B0 adapters and B2 |
| macOS path and `readlink` differences | First macOS machine. B2 and B8 |
| MCP server definitions | Spec §11, not in v1 |
| Whether `commands` needs a Codex equivalent | B5 |
| Copy mode (`--copy`) survival | B2 — decide whether a copy fallback is still worth its branch, given no-drift is frozen |
