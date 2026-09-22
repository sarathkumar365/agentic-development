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
start=$(date +%s)
/repo/bin/sync.sh >/tmp/first.log 2>&1
elapsed=$(( $(date +%s) - start ))

[ "$(readlink -f "$HOME/.claude/AGENTS.md")" = /repo/AGENTS.md ] || { echo "claude doctrine not linked"; exit 1; }
[ "$(readlink -f "$HOME/.codex/AGENTS.md")"  = /repo/AGENTS.md ] || { echo "codex doctrine not linked"; exit 1; }
[ -L "$HOME/.claude/skills/evolve" ] || { echo "skills not linked"; exit 1; }

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
