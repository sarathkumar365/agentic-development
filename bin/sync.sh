#!/usr/bin/env bash
# Sync agent configs from this repo into each agent's expected location.
#
# Source of truth: this repo's per-agent subdirs (claude/, codex/, etc.)
# Destination:    ~/.claude/, ~/.codex/, etc.
#
# Additive by default (does not delete files in destination that aren't in source).
# Pass --clean to mirror exactly (deletes destination files not in source).

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLEAN=""
if [ "${1:-}" = "--clean" ]; then
  CLEAN="--delete"
  echo "[sync] --clean mode: destination will mirror source exactly"
fi

sync_agent() {
  local agent="$1"          # e.g. claude
  local src="$REPO/$agent"
  local dest="$HOME/.$agent"

  if [ ! -d "$src" ]; then
    return 0
  fi

  mkdir -p "$dest"
  echo "[sync] $src/ → $dest/"
  rsync -a $CLEAN \
    --exclude='.DS_Store' \
    "$src/" "$dest/"
}

# Add agents here as you start using them.
sync_agent claude
# sync_agent codex
# sync_agent cursor

echo "[sync] done"
