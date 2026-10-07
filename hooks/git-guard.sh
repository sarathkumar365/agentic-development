#!/usr/bin/env bash
# category: safety
# PreToolUse on Bash. No commit or push without a code review the operator has seen.
#
# The review is recorded as a marker file, .claude/.reviewed, in the repo being committed.
# The marker must be newer than every changed and untracked file, so an edit made after the
# review blocks the commit until the review is re-run. Projects should gitignore the marker.
set -euo pipefail
input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""')"
deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"
  exit 0
}

# `git -C <dir> commit` commits in <dir>, not in the session's working directory.
re='git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+(commit|push)([[:space:]]|$)'
grep -qE "$re" <<<"$cmd" || exit 0

dir="$(printf '%s' "$input" | jq -r '.cwd // "."')"
cdir="$(printf '%s' "$cmd" | sed -nE 's/.*git[[:space:]]+-C[[:space:]]+"?([^"[:space:]]+)"?.*/\1/p' | head -1)"
if [ -n "$cdir" ]; then
  cdir="${cdir/#\~/$HOME}"
  case "$cdir" in /*) dir="$cdir" ;; *) dir="$dir/$cdir" ;; esac
fi
root="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)" || exit 0
marker="$root/.claude/.reviewed"

[ -f "$marker" ] || deny "No code review recorded for this change. Run /code-review, report the findings to the operator, get their explicit go-ahead, then run: touch $marker"

# GNU stat first; BSD stat (macOS) reads -c as an error and falls through.
mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1"; }
# Unstaged, staged and untracked. Not `diff HEAD`: a repo with no commit yet has no HEAD.
newest="$( { git -C "$root" diff --name-only; git -C "$root" diff --name-only --cached
  git -C "$root" ls-files --others --exclude-standard; } 2>/dev/null \
  | while IFS= read -r f; do if [ -f "$root/$f" ]; then mtime "$root/$f"; fi; done | sort -n | tail -1)"

if [ -n "$newest" ] && [ "$(mtime "$marker")" -lt "$newest" ]; then
  deny "Files changed after the last review. Re-run /code-review, report to the operator, then run: touch $marker"
fi
exit 0
