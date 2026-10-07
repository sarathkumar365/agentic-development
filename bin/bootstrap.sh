#!/usr/bin/env bash
# One command to make a fresh machine work like every other machine.
#
#   curl -fsSL https://raw.githubusercontent.com/sarathkumar365/agentic-development/main/bin/bootstrap.sh | bash
#
# Or, from an existing clone:
#   ~/agentic-development/bin/bootstrap.sh
#
# Idempotent. Safe to re-run. Installs nothing without saying so first.

set -euo pipefail

REPO_URL="https://github.com/sarathkumar365/agentic-development.git"
REPO_DIR="${AGENTIC_DIR:-$HOME/agentic-development}"

say()  { echo "[bootstrap] $*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# --- 1. prerequisites -------------------------------------------------------
missing=()
for tool in git curl; do have "$tool" || missing+=("$tool"); done
if [ ${#missing[@]} -gt 0 ]; then
  say "missing required tools: ${missing[*]}"
  say "install them and re-run."
  exit 1
fi

if ! have gh; then
  say "gh (GitHub CLI) not found - optional, but project-init needs it to create repos."
  say "  https://cli.github.com"
fi

# --- 2. the repo ------------------------------------------------------------
if [ -d "$REPO_DIR/.git" ]; then
  say "repo present at $REPO_DIR - pulling"
  git -C "$REPO_DIR" pull --ff-only \
    || say "WARNING: pull failed - installing from $(git -C "$REPO_DIR" rev-parse --short HEAD), which may be behind origin"
else
  say "cloning into $REPO_DIR"
  git clone "$REPO_URL" "$REPO_DIR"
fi

# A clone from before AGENTS.md became the doctrine has a different layout, and its own
# sync.sh would install that old system. Refuse rather than install it quietly.
if [ ! -f "$REPO_DIR/AGENTS.md" ] || [ ! -f "$REPO_DIR/lib/targets.sh" ]; then
  say "$REPO_DIR is an old layout of this repo. Move it aside, or set AGENTIC_DIR to a current clone."
  exit 1
fi

# --- 3. link config into every detected agent --------------------------------
# Which agents exist, and where their config lives, is lib/targets.sh's knowledge, not
# this script's. sync.sh also seeds profile.md for agents that can import it.
"$REPO_DIR/bin/sync.sh"

# --- 4. next steps ---------------------------------------------------------
say ""
say "done. Next:"
. "$REPO_DIR/lib/targets.sh"  # profile.md exists only where an agent can import it
for t in "${TARGETS[@]}"; do p="$(field "$t" 2)/profile.md"; [ -f "$p" ] && say "  - Edit $p (machine specs, never committed)."; done
say "  - Restart each agent so skills and agents load."
say "  - Verify with: $REPO_DIR/bin/inventory.sh --roles"
say ""
say "To push improvements back:  $REPO_DIR/bin/capture.sh"
