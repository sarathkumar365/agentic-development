#!/usr/bin/env bash
# Evolution loop: push whatever the system learned on this machine back to the repo.
#
# Because sync.sh symlinks, edits made to skills while working are already changes in
# this repo's working tree. This commits and pushes them, and adopts any NEW skill or
# agent that was created directly in ~/.claude/ but never made it into the repo.
#
#   capture.sh                 review, adopt, commit, push
#   capture.sh --dry-run       show what would be captured
#   capture.sh -m "message"    custom commit message

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$HOME/.claude"
DRY=0
MSG=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    -m) MSG="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
done

say() { echo "[capture] $*"; }

# --- 1. adopt anything created directly in ~/.claude ------------------------
adopted=()
for group in skills agents commands; do
  [ -d "$DEST/$group" ] || continue
  while IFS= read -r -d '' item; do
    name="$(basename "$item")"
    [ -e "$REPO/$group/$name" ] && continue   # already tracked
    if [ "$DRY" = 1 ]; then
      say "would adopt $group/$name"
    else
      mkdir -p "$REPO/$group"
      cp -a "$item" "$REPO/$group/"
      rm -rf "$item"
      ln -s "$REPO/$group/$name" "$item"
      say "adopted $group/$name (now tracked and linked)"
    fi
    adopted+=("$group/$name")
  done < <(find "$DEST/$group" -mindepth 1 -maxdepth 1 ! -type l -print0 2>/dev/null)
done

# --- 2. what changed --------------------------------------------------------
cd "$REPO"
if [ -z "$(git status --porcelain)" ]; then
  say "nothing to capture - repo is clean"
  exit 0
fi

say "changes:"
git status --short | sed 's/^/  /'

if [ "$DRY" = 1 ]; then
  say "dry run - nothing committed"
  exit 0
fi

# --- 3. commit and push -----------------------------------------------------
if [ -z "$MSG" ]; then
  if [ ${#adopted[@]} -gt 0 ]; then
    MSG="feat: adopt ${adopted[*]}"
  else
    MSG="chore: capture agent config changes from $(hostname -s 2>/dev/null || echo machine)"
  fi
fi

git add -A
git commit -m "$MSG"
say "committed: $MSG"

if git remote get-url origin >/dev/null 2>&1; then
  git pull --rebase --autostash origin "$(git rev-parse --abbrev-ref HEAD)" || {
    say "rebase failed - resolve, then: git push"; exit 1; }
  git push
  say "pushed. Other machines get it with: bin/bootstrap.sh"
else
  say "no origin remote - committed locally only"
fi
