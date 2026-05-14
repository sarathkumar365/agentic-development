#!/usr/bin/env bash
# Stamp the standard project skeleton into a target directory.
#
# Usage:
#   init.sh                # stamp into current directory
#   init.sh /path/to/repo  # stamp into specified directory

set -euo pipefail

SKELETON="$(cd "$(dirname "${BASH_SOURCE[0]}")/files" && pwd)"
TARGET="${1:-.}"

if [ ! -d "$TARGET" ]; then
  echo "Error: target directory does not exist: $TARGET" >&2
  exit 1
fi

# Refuse to overwrite an existing AGENTS.md to avoid clobbering real work.
if [ -e "$TARGET/AGENTS.md" ]; then
  echo "Error: $TARGET/AGENTS.md already exists. Refusing to overwrite." >&2
  echo "Move or rename the existing AGENTS.md first if you want to re-stamp." >&2
  exit 1
fi

echo "[init] Stamping skeleton from $SKELETON into $TARGET"

# Copy contents (including dotfiles like .claude/) but not the parent dir itself.
cp -R "$SKELETON/." "$TARGET/"

echo "[init] Done. Files created:"
(cd "$TARGET" && find AGENTS.md Docs .claude -type f 2>/dev/null | sort)

echo
echo "Next steps:"
echo "  1. Edit AGENTS.md — fill in project name, domain, primary goal."
echo "  2. Review .claude/settings.json hooks — adjust if your branch strategy differs."
echo "  3. Open /hooks in Claude Code (or restart) to activate the safety hooks."
