#!/usr/bin/env bash
# Plumbing for curated promotion. It surveys; it does not decide.
#
# Because sync.sh symlinks, an edit made to a skill while working is already a change in
# this repo's working tree. That is deliberate — nothing is ever lost. But nothing reaches
# git history on its own: the curator agent reads this survey, decides what is a durable
# improvement, and calls --commit with a message for that one thing.
#
#   capture.sh                  survey: what changed, and what exists loose in an agent dir
#   capture.sh --adopt <path>   move one loose file or directory into the repo and link it
#   capture.sh --commit -m MSG  commit the staged-and-unstaged tree with MSG, then push
#
# There is deliberately no "commit everything with a generated message" path. That is the
# unattended promotion this system excludes (docs/idea-contract.md, invariant 4).

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/targets.sh
. "$REPO/lib/targets.sh"

ACTION=survey
ADOPT=""
MSG=""

while [ $# -gt 0 ]; do
  case "$1" in
    --adopt)  ACTION=adopt; ADOPT="${2:-}"; shift 2 ;;
    --commit) ACTION=commit; shift ;;
    -m)       MSG="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
done

say() { echo "[capture] $*"; }

# --- survey ------------------------------------------------------------------------

survey() {
  cd "$REPO"

  echo "## Tracked changes (edits that reached the repo through a symlink)"
  if [ -z "$(git status --porcelain)" ]; then
    echo "  none - working tree is clean"
  else
    git status --short | sed 's/^/  /'
    echo
    echo "## Diff summary"
    git diff --stat | sed 's/^/  /'
  fi

  echo
  echo "## Loose content (created inside an agent directory, never tracked here)"
  local t id root accepts group found=0
  for t in "${TARGETS[@]}"; do
    id="$(field "$t" 1)"; root="$(field "$t" 2)"; accepts="$(field "$t" 5)"
    detected "$root" "$id" || continue
    for group in $accepts; do
      [ -d "$root/$group" ] || continue
      while IFS= read -r -d '' item; do
        case "$(basename "$item")" in .*) continue ;; esac
        echo "  $id  $item"
        found=1
      done < <(find "$root/$group" -mindepth 1 -maxdepth 1 ! -type l -print0 2>/dev/null)
    done
  done
  [ "$found" = 1 ] || echo "  none"

  echo
  echo "Nothing above is committed. Decide what is durable, then:"
  echo "  bin/capture.sh --adopt <path>        # for loose content worth keeping"
  echo "  bin/capture.sh --commit -m \"<msg>\"   # for the change you chose to keep"
}

# --- adopt one loose item ----------------------------------------------------------

adopt_one() {
  local item="$1"
  [ -n "$item" ] || { echo "--adopt needs a path" >&2; exit 2; }
  [ -e "$item" ] || { echo "no such path: $item" >&2; exit 2; }
  [ -L "$item" ] && { say "$item is already a link into the repo - nothing to adopt"; exit 0; }

  local group name
  group="$(basename "$(dirname "$item")")"
  name="$(basename "$item")"
  case "$group" in
    skills|agents|commands) ;;
    *) echo "refusing: $item is not inside skills/, agents/ or commands/" >&2; exit 2 ;;
  esac
  [ -e "$REPO/$group/$name" ] && { echo "refusing: $group/$name already exists in the repo" >&2; exit 2; }

  mkdir -p "$REPO/$group"
  cp -a "$item" "$REPO/$group/"
  rm -rf "$item"
  ln -s "$REPO/$group/$name" "$item"
  say "adopted $group/$name - now tracked, and linked back so the live copy still works"
  say "review it, then: bin/capture.sh --commit -m \"feat: add $group/$name\""
}

# --- commit what was chosen --------------------------------------------------------

commit_chosen() {
  [ -n "$MSG" ] || { echo "--commit needs -m \"<message>\". No generated messages: the whole point is that a person chose this change." >&2; exit 2; }
  cd "$REPO"
  [ -n "$(git status --porcelain)" ] || { say "nothing to commit - working tree is clean"; exit 0; }

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
}

case "$ACTION" in
  survey) survey ;;
  adopt)  adopt_one "$ADOPT" ;;
  commit) commit_chosen ;;
esac
