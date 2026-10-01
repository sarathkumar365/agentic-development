#!/usr/bin/env bash
# category: safety
# PreToolUse on Edit|Write. Warn - never block - when the agent edits its own constraints.
set -euo pipefail
fp="$(jq -r '.tool_input.file_path // ""')"
echo "$fp" | grep -qE '(AGENTS\.md|CLAUDE\.md)$' || exit 0
printf '{"systemMessage":"Agent is modifying its own constraints file (%s). Review the diff before approving."}\n' "$fp"
