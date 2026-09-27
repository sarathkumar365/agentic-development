#!/usr/bin/env bash
# category: safety
# PreToolUse on Read|Edit|Write. Deny any path that is a real secrets file.
# Example, sample and template variants are allowed - they carry no secret.
set -euo pipefail
fp="$(jq -r '.tool_input.file_path // ""')"
case "$fp" in *.example|*.sample|*.template) exit 0 ;; esac
echo "$fp" | grep -qE '(\.env($|\.)|credentials\.json|id_rsa|\.pem$)' || exit 0
cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Secrets must not enter agent context. .env, credentials.json, private keys are blocked; .example/.sample/.template are allowed."}}
JSON
