#!/usr/bin/env bash
# The target agents this repo installs into, and the only place their paths are named.
#
# Sourced by bin/sync.sh and bin/capture.sh. A new agent is one more row here and no
# other edit anywhere.
#
#   id | root | doctrine_path | doctrine_mode | accepts | restart_hint
#
# doctrine_mode
#   link    the agent reads AGENTS.md natively; symlink it straight to the source
#   import  the agent prefers its own filename; install AGENTS.md alongside a stub
#           that imports it, because an @import resolves next to the importing file
#
# accepts   space-separated content roles this agent can take. A role the agent has no
#           equivalent for is skipped, not an error.

TARGETS=(
  "claude|$HOME/.claude|CLAUDE.md|import|skills agents commands|restart Claude Code"
  "codex|${CODEX_HOME:-$HOME/.codex}|AGENTS.md|link|skills|start a new codex session"
)

# field <row> <n> - one column out of a target row
field() { printf '%s' "$1" | cut -d'|' -f"$2"; }

# detected <root> <id> - is this agent present on this machine
detected() {
  local root="$1" id="$2"
  [ -d "$root" ] || command -v "$id" >/dev/null 2>&1
}
