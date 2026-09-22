#!/usr/bin/env bash
# Link this repo's agent config into each installed agent's config directory, so the
# repo IS the live config.
#
# Symlinks by default. That makes local edits visible as repo changes immediately, so
# nothing written while working is ever lost. Nothing reaches git history on its own —
# promotion is curated (see docs/idea-contract.md, invariant 4).
#
#   sync.sh            symlink (default)
#   sync.sh --copy     copy instead of symlink (for machines where symlinks are awkward)
#   sync.sh --dry-run  show what would happen, change nothing
#   sync.sh --status   report what is linked, copied, diverged or untracked
#   sync.sh --targets  list target agents and whether each is detected here
#   sync.sh --all      install for every target, detected or not
#
# Anything already at a destination path is backed up to <root>/backups/<timestamp>/
# before being replaced. Nothing is deleted.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

# shellcheck source=../lib/targets.sh
. "$REPO/lib/targets.sh"

# --- flags -------------------------------------------------------------------------

# shellcheck disable=SC2209  # "link" is a literal mode name, not a command
MODE=link
DRY=0
STATUS=0
LIST=0
ALL=0
for arg in "$@"; do
  case "$arg" in
    --copy)    MODE=copy ;;
    --dry-run) DRY=1 ;;
    --status)  STATUS=1 ;;
    --targets) LIST=1 ;;
    --all)     ALL=1 ;;
    -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

say() { echo "[sync] $*"; }

backup() {
  local path="$1" root="$2"
  { [ -e "$path" ] || [ -L "$path" ]; } || return 0
  if [ "$DRY" = 1 ]; then say "would back up $path"; return 0; fi
  mkdir -p "$root/backups/$STAMP"
  cp -a "$path" "$root/backups/$STAMP/" 2>/dev/null || true
  say "backed up $(basename "$path") -> $root/backups/$STAMP/"
}

install_one() {
  local src="$1" dst="$2" root="$3"

  if [ "$MODE" = link ] && [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
    return 0
  fi

  # A real file here is hand-written content this repo did not create. Never replace one
  # silently — back it up and say so loudly enough that it can be merged back by hand.
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    say "WARNING: $dst is not a link. Backing it up; merge anything you still want."
  fi

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    backup "$dst" "$root"
    [ "$DRY" = 1 ] || rm -rf "$dst"
  fi

  if [ "$DRY" = 1 ]; then say "would $MODE $dst"; return 0; fi

  mkdir -p "$(dirname "$dst")"
  if [ "$MODE" = link ]; then ln -s "$src" "$dst"; else cp -a "$src" "$dst"; fi
  say "$MODE $dst"
}

install_target() {
  local t="$1"
  local id root doctrine_path doctrine_mode accepts hint group
  id="$(field "$t" 1)"; root="$(field "$t" 2)"
  doctrine_path="$(field "$t" 3)"; doctrine_mode="$(field "$t" 4)"
  accepts="$(field "$t" 5)"; hint="$(field "$t" 6)"

  say "target: $id ($root)"

  for group in $accepts; do
    [ -d "$REPO/$group" ] || continue
    [ "$DRY" = 1 ] || mkdir -p "$root/$group"
    while IFS= read -r -d '' item; do
      install_one "$item" "$root/$group/$(basename "$item")" "$root"
    done < <(find "$REPO/$group" -mindepth 1 -maxdepth 1 -print0)
  done

  # AGENTS.md is the single authored doctrine. In import mode the agent's own file is a
  # stub beside it; in link mode the agent reads AGENTS.md directly.
  install_one "$REPO/AGENTS.md" "$root/AGENTS.md" "$root"
  if [ "$doctrine_mode" = import ]; then
    install_one "$REPO/home/CLAUDE.md" "$root/$doctrine_path" "$root"
  fi

  # profile.md is only reachable by an agent that supports file imports. Seeding it for a
  # link-mode agent would leave an unread file the operator is invited to maintain.
  if [ "$doctrine_mode" = import ] && [ ! -e "$root/profile.md" ]; then
    if [ "$DRY" = 1 ]; then
      say "would create $root/profile.md from home/profile.md.example"
    else
      cp "$REPO/home/profile.md.example" "$root/profile.md"
      say "created $root/profile.md (edit it - machine-specific, never committed)"
    fi
  fi

  say "$id done. $hint to pick it up."
}

report_status() {
  local t id root src dst rel state accepts group
  for t in "${TARGETS[@]}"; do
    id="$(field "$t" 1)"; root="$(field "$t" 2)"; accepts="$(field "$t" 5)"
    detected "$root" "$id" || { say "$id: not installed here, skipped"; continue; }

    echo
    printf '%-8s %-38s %s\n' "TARGET" "PATH" "STATE"
    for group in $accepts; do
      [ -d "$REPO/$group" ] || continue
      while IFS= read -r -d '' src; do
        rel="${src#"$REPO"/}"
        dst="$root/$rel"
        if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then state=linked
        elif [ -e "$dst" ]; then state=copied-or-diverged
        else state=missing; fi
        printf '%-8s %-38s %s\n' "$id" "$rel" "$state"
      done < <(find "$REPO/$group" -mindepth 1 -maxdepth 1 -print0)
    done

    echo
    say "$id: untracked (candidates for curation):"
    for group in $accepts; do
      [ -d "$root/$group" ] || continue
      find "$root/$group" -mindepth 1 -maxdepth 1 ! -type l -printf '  %p\n' 2>/dev/null
    done
  done
}

list_targets() {
  local t id root
  printf '%-8s %-26s %s\n' "TARGET" "ROOT" "DETECTED"
  for t in "${TARGETS[@]}"; do
    id="$(field "$t" 1)"; root="$(field "$t" 2)"
    if detected "$root" "$id"; then printf '%-8s %-26s %s\n' "$id" "$root" "yes"
    else printf '%-8s %-26s %s\n' "$id" "$root" "no"; fi
  done
}

if [ "$LIST" = 1 ]; then list_targets; exit 0; fi
if [ "$STATUS" = 1 ]; then report_status; exit 0; fi

say "repo: $REPO"
say "mode: $MODE"

# On a machine where no agent is installed yet, installing nothing would leave the
# operator with a configured repo and an unconfigured machine. Lay the config down
# anyway so the first agent installed picks it up with no second command.
any_detected=0
for t in "${TARGETS[@]}"; do
  detected "$(field "$t" 2)" "$(field "$t" 1)" && any_detected=1
done
if [ "$any_detected" = 0 ] && [ "$ALL" = 0 ]; then
  say "no target agent detected - installing for all of them so the first one installed finds it"
  ALL=1
fi

for t in "${TARGETS[@]}"; do
  if [ "$ALL" = 1 ] || detected "$(field "$t" 2)" "$(field "$t" 1)"; then
    install_target "$t"
  else
    say "target: $(field "$t" 1) not installed here, skipped"
  fi
done
