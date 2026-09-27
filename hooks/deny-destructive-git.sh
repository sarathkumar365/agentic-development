#!/usr/bin/env bash
# category: safety
# PreToolUse on Bash. Deny the git commands that destroy work irrecoverably.
#
# Push-to-main is deliberately NOT here. Whether main is pushable is a property of one
# repo, so it belongs in that repo's own settings (see templates/project-skeleton), not
# in a global rule that would block every repo whose trunk is the working branch.
set -euo pipefail
cmd="$(jq -r '.tool_input.command // ""')"
deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"
  exit 0
}
echo "$cmd" | grep -qE 'git[[:space:]]+(reset[[:space:]]+--hard|push[[:space:]]+(--force|-f)|clean[[:space:]]+-[a-z]*f|branch[[:space:]]+-D)' \
  && deny "Destructive git command blocked. Confirm with the operator and run it from the terminal if intended."
exit 0
