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
  say "install them and re-run. Debian/Ubuntu: sudo apt install ${missing[*]}"
  exit 1
fi

if ! have claude; then
  say "Claude Code not found."
  say "install it, then re-run this script:"
  say "  curl -fsSL https://claude.ai/install.sh | bash"
  say "continuing anyway - config will be in place when you do install it."
fi

if ! have gh; then
  say "gh (GitHub CLI) not found - optional, but project-init needs it to create repos."
  say "  https://cli.github.com"
fi

# --- 2. the repo ------------------------------------------------------------
if [ -d "$REPO_DIR/.git" ]; then
  say "repo present at $REPO_DIR - pulling"
  git -C "$REPO_DIR" pull --ff-only || say "pull skipped (local changes or no network)"
else
  say "cloning into $REPO_DIR"
  git clone "$REPO_URL" "$REPO_DIR"
fi

# --- 3. link config into ~/.claude -----------------------------------------
"$REPO_DIR/bin/sync.sh"

# --- 4. per-machine profile -------------------------------------------------
PROFILE="$HOME/.claude/profile.md"
if [ -f "$PROFILE" ] && ! grep -q "RTX 2070" "$PROFILE" 2>/dev/null; then
  say "profile.md already customised - left alone"
else
  say "profile.md is at $PROFILE - edit it with THIS machine's hardware and accounts"
  if have nvidia-smi; then
    say "detected GPU: $(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null | head -1)"
  fi
  if have free; then
    say "detected RAM: $(free -g | awk '/^Mem:/{print $2" GB"}')"
  fi
fi

# --- 5. convenience ---------------------------------------------------------
say ""
say "done. Next:"
say "  1. Edit $PROFILE with this machine's specs."
say "  2. Restart Claude Code so skills and agents load."
say "  3. Verify with: claude --version && ls ~/.claude/skills"
say ""
say "To push improvements back:  $REPO_DIR/bin/capture.sh"
