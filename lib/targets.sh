#!/usr/bin/env bash
# The target agents this repo installs into, and the only place their paths are named.
#
# Sourced by bin/sync.sh and bin/capture.sh. A new agent is one more row here and no
# other edit anywhere.
#
#   id | root | doctrine_path | doctrine_mode | accepts | restart_hint | conf_file | hooks_file | hooks_path
#
# doctrine_mode
#   link    the agent reads AGENTS.md natively; symlink it straight to the source
#   import  the agent prefers its own filename; install AGENTS.md alongside a stub
#           that imports it, because an @import resolves next to the importing file
#   conf    the agent reads no instruction file unless its config names one; symlink
#           AGENTS.md into the root and point the agent's own config file at it
#
# conf_file  only for doctrine_mode=conf: the agent's own config file, which usually
#            lives outside root. Named here so no script hardcodes an agent's path.
#
# hooks_file, hooks_path
#            only for targets that accept hooks: the file to write, relative to root, and
#            the jq path inside it that holds the declaration. Hook scripts are
#            inert until the agent is told which event fires them, and every agent keeps
#            that declaration somewhere different: Claude Code nests it under `.hooks` in
#            settings.json, Codex keeps it at the top level of hooks/hooks.json. Both read
#            the same event names (PreToolUse, PostToolUse, SessionStart, ...) and the same
#            decision schema, so one authored hook script serves both.
#
# accepts   space-separated content roles this agent can take. A role the agent has no
#           equivalent for is skipped, not an error.

# shellcheck disable=SC2034  # consumed by the scripts that source this file
TARGETS=(
  "claude|$HOME/.claude|CLAUDE.md|import|skills agents commands hooks|restart Claude Code||settings.json|.hooks"
  "codex|${CODEX_HOME:-$HOME/.codex}|AGENTS.md|link|skills agents hooks|start a new codex session||hooks/hooks.json|."
  "aider|$HOME/.aider|AGENTS.md|conf||start a new aider session|$HOME/.aider.conf.yml||"
)

# --- portability ------------------------------------------------------------------
#
# macOS ships BSD userland: `find -printf` does not exist, `sort -z` does not exist, and
# `readlink -f` only arrived in macOS 12.3. These three do the same jobs with flags both
# userlands have, so no script below has to know which machine it is on.

# rlf <path> - canonical absolute path, following a symlink chain. Stands in for
# `readlink -f`, which is the one GNU flag this repo genuinely cannot do without: the
# whole no-drift property is "does this link resolve to the repo file".
rlf() {
  local p="$1" t d b n=0
  { [ -e "$p" ] || [ -L "$p" ]; } || return 1
  while [ -L "$p" ] && [ "$n" -lt 40 ]; do
    t="$(readlink "$p")"
    case "$t" in /*) p="$t" ;; *) p="$(dirname "$p")/$t" ;; esac
    n=$((n + 1))
  done
  d="$(dirname "$p")"; b="$(basename "$p")"
  d="$(cd "$d" 2>/dev/null && pwd -P)" || return 1
  case "$d" in */) printf '%s%s\n' "$d" "$b" ;; *) printf '%s/%s\n' "$d" "$b" ;; esac
}

# sort0 - sort a NUL-separated stream. Stands in for `sort -z`. Assumes no newline inside
# a path, which holds for everything this repo publishes and installs.
sort0() { tr '\0' '\n' | LC_ALL=C sort | tr '\n' '\0'; }

# field <row> <n> - one column out of a target row
field() { printf '%s' "$1" | cut -d'|' -f"$2"; }

# detected <root> <id> - is this agent present on this machine
detected() {
  local root="$1" id="$2"
  [ -d "$root" ] || command -v "$id" >/dev/null 2>&1
}
