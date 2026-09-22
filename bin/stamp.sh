#!/usr/bin/env bash
# Stamp a project's agent rules into a target repository.
#
# The project's working agreement is authored once, in AGENTS.md, because that is the
# file every agent reads. Per-agent files are pointer stubs, generated only for targets
# that prefer their own filename — never a second copy of the rules.
#
#   stamp.sh                 stamp into the current directory
#   stamp.sh /path/to/repo   stamp into that directory
#   stamp.sh --dry-run [dir] show what would be written
#
# Refuses to overwrite an existing AGENTS.md. Re-stamping a project is not a thing this
# does: move the old file aside first, deliberately.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKELETON="$REPO/templates/project-skeleton/files"
# shellcheck source=../lib/targets.sh
. "$REPO/lib/targets.sh"

DRY=0
TARGET="."
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
    *) TARGET="$arg" ;;
  esac
done

say() { echo "[stamp] $*"; }

[ -d "$TARGET" ] || { echo "no such directory: $TARGET" >&2; exit 1; }
TARGET="$(cd "$TARGET" && pwd)"

if [ -e "$TARGET/AGENTS.md" ]; then
  echo "refusing: $TARGET/AGENTS.md already exists." >&2
  echo "Move it aside first if you really mean to re-stamp." >&2
  exit 1
fi

if [ "$DRY" = 1 ]; then
  say "would write $TARGET/AGENTS.md and the Docs/ tree"
else
  # AGENTS.md and the docs tree are the content. Any per-agent file in the skeleton is
  # regenerated below from the target table, so it is not copied.
  cp -R "$SKELETON/." "$TARGET/"
  rm -f "$TARGET/CLAUDE.md"
  say "wrote $TARGET/AGENTS.md"
fi

# --- per-agent stubs ---------------------------------------------------------------
# Only import-mode agents need one. A link-mode agent reads AGENTS.md directly, so
# writing anything for it would create the duplicate this system exists to prevent.

# shellcheck disable=SC2153  # TARGETS comes from lib/targets.sh, unrelated to TARGET
for t in "${TARGETS[@]}"; do
  id="$(field "$t" 1)"
  doctrine_path="$(field "$t" 3)"
  doctrine_mode="$(field "$t" 4)"

  [ "$doctrine_mode" = import ] || { say "$id reads AGENTS.md directly - no stub needed"; continue; }

  if [ "$DRY" = 1 ]; then
    say "would write $TARGET/$doctrine_path (stub importing AGENTS.md)"
    continue
  fi

  cat > "$TARGET/$doctrine_path" <<EOF
# $id instructions

This file carries no rules of its own. The project's working agreement is
agent-agnostic and lives in AGENTS.md:

@AGENTS.md

Global doctrine — response style, decide-don't-interrogate, phase discipline — is
installed separately by bin/sync.sh. Add only ${id}-specific rules below this line.
EOF
  say "wrote $TARGET/$doctrine_path (stub)"
done

[ "$DRY" = 1 ] && exit 0

say "done."
say "Next: fill in AGENTS.md - project name, invariants, non-goals, conventions."
