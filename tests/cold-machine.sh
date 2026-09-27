#!/usr/bin/env bash
# The cold-machine stratum: a container with nothing but git and bash.
#
# tests/criteria.sh fakes a cold machine with a scratch HOME, which cannot catch a
# dependency the host happens to provide. This runs the documented install path in a
# container that has neither agent installed and no tooling beyond the base image.
#
#   tests/cold-machine.sh        run it
#
# Needs docker. Skips with a notice, not a failure, when docker is absent — a machine
# without a container runtime must still be able to run the rest of the suite.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v docker >/dev/null 2>&1; then
  echo "SKIP  cold machine (container)   docker not installed on this machine"
  exit 0
fi

# Nothing is pre-created. A container with neither CLI installed and no agent directory is
# the real cold machine, and sync.sh must still lay the config down for both targets.
# shellcheck disable=SC2016  # this body must expand inside the container, not here
script='
set -e
export HOME=/root
# rlf stands in for `readlink -f`; sourced here for the same reason the scripts do.
. /repo/lib/targets.sh
start=$(date +%s)
/repo/bin/sync.sh >/tmp/first.log 2>&1
elapsed=$(( $(date +%s) - start ))

[ "$(rlf "$HOME/.claude/AGENTS.md")" = /repo/AGENTS.md ] || { echo "claude doctrine not linked"; exit 1; }
[ "$(rlf "$HOME/.codex/AGENTS.md")"  = /repo/AGENTS.md ] || { echo "codex doctrine not linked"; exit 1; }
[ "$(rlf "$HOME/.aider/AGENTS.md")"  = /repo/AGENTS.md ] || { echo "aider doctrine not linked"; exit 1; }
[ -L "$HOME/.claude/skills/evolve" ] || { echo "skills not linked"; exit 1; }
[ -L "$HOME/.claude/hooks/deny-secret-files.sh" ] || { echo "hooks not linked"; exit 1; }
[ -f "$HOME/.aider.conf.yml" ] || { echo "aider conf not written"; exit 1; }

# The base image has no jq, so hook DECLARATION must degrade to a loud warning rather
# than a silent skip or a crash. The scripts are still linked; only the wiring waits.
if ! command -v jq >/dev/null 2>&1; then
  grep -q "jq absent" /tmp/first.log || { echo "jq-absent path did not warn"; exit 1; }
fi

grep -qiE "password|sudo|\[y/n\]|press enter" /tmp/first.log && { echo "install prompted"; exit 1; }

/repo/bin/sync.sh >/tmp/second.log 2>&1
writes=$(grep -cE "^\[sync\] (link|copy|backed up|created) " /tmp/second.log || true)
[ "$writes" = 0 ] || { echo "re-run wrote $writes times"; sed -n 1,5p /tmp/second.log; exit 1; }

echo "configured in ${elapsed}s, zero prompts, re-run wrote nothing"
'

out=$(docker run --rm -v "$REPO:/repo:ro" debian:stable-slim \
        bash -c "apt-get update -qq >/dev/null 2>&1 && apt-get install -y -qq git >/dev/null 2>&1; $script" 2>&1)
status=$?

if [ "$status" -eq 0 ]; then
  echo "PASS  cold machine (container)  ${out##*$'\n'}"
else
  echo "FAIL  cold machine (container)  ${out}"
fi
exit "$status"
