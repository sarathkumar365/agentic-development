#!/usr/bin/env bash
# Link this repo's agent config into ~/.claude/ so the repo IS the live config.
#
# Symlinks by default. That makes the sync two-way by construction: editing a skill
# while working edits the file in this repo, so nothing is ever lost on the next sync.
#
#   sync.sh            symlink (default)
#   sync.sh --copy     copy instead of symlink (for machines where symlinks are awkward)
#   sync.sh --dry-run  show what would happen, change nothing
#   sync.sh --status   report what is linked, copied, diverged or untracked
#
# Anything already at a destination path is backed up to ~/.claude/backups/<timestamp>/
# before being replaced. Nothing is deleted.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$HOME/.claude"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$DEST/backups/$STAMP"

MODE=link
DRY=0
STATUS=0
for arg in "$@"; do
  case "$arg" in
    --copy)    MODE=copy ;;
    --dry-run) DRY=1 ;;
    --status)  STATUS=1 ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

say() { echo "[sync] $*"; }

backup() {
  local path="$1"
  { [ -e "$path" ] || [ -L "$path" ]; } || return 0
  if [ "$DRY" = 1 ]; then say "would back up $path"; return 0; fi
  mkdir -p "$BACKUP"
  cp -a "$path" "$BACKUP/" 2>/dev/null || true
  say "backed up $(basename "$path") -> $BACKUP/"
}

install_one() {
  local src="$1" dst="$2"

  if [ "$MODE" = link ] && [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
    return 0
  fi

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    backup "$dst"
    [ "$DRY" = 1 ] || rm -rf "$dst"
  fi

  if [ "$DRY" = 1 ]; then say "would $MODE $dst"; return 0; fi

  mkdir -p "$(dirname "$dst")"
  if [ "$MODE" = link ]; then ln -s "$src" "$dst"; else cp -a "$src" "$dst"; fi
  say "$MODE $dst"
}

report_status() {
  local src dst rel state
  printf '%-44s %s\n' "PATH" "STATE"
  while IFS= read -r -d '' src; do
    rel="${src#"$REPO"/}"
    dst="$DEST/$rel"
    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then state=linked
    elif [ -e "$dst" ]; then state=copied-or-diverged
    else state=missing; fi
    printf '%-44s %s\n' "$rel" "$state"
  done < <(find "$REPO/skills" "$REPO/agents" "$REPO/commands" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)

  echo
  say "untracked in ~/.claude (candidates for capture.sh):"
  for d in skills agents commands; do
    [ -d "$DEST/$d" ] || continue
    find "$DEST/$d" -mindepth 1 -maxdepth 1 ! -type l -printf '  %p\n' 2>/dev/null
  done
}

if [ "$STATUS" = 1 ]; then report_status; exit 0; fi

say "repo: $REPO"
say "mode: $MODE"

for group in skills agents commands; do
  [ -d "$REPO/$group" ] || continue
  mkdir -p "$DEST/$group"
  while IFS= read -r -d '' item; do
    install_one "$item" "$DEST/$group/$(basename "$item")"
  done < <(find "$REPO/$group" -mindepth 1 -maxdepth 1 -print0)
done

install_one "$REPO/home/CLAUDE.md" "$DEST/CLAUDE.md"

if [ ! -e "$DEST/profile.md" ]; then
  if [ "$DRY" = 1 ]; then
    say "would create $DEST/profile.md from home/profile.md.example"
  else
    cp "$REPO/home/profile.md.example" "$DEST/profile.md"
    say "created $DEST/profile.md (edit it - machine-specific, never committed)"
  fi
fi

say "done. Restart Claude Code to pick up skills and agents."
