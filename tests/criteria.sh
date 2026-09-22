#!/usr/bin/env bash
# The ship criteria from docs/product-spec-v1.md section 6, as executable checks.
#
# Each bar prints its measured value, not just a verdict, so a regression shows as a
# number moving rather than a check flipping. Everything runs against a scratch HOME,
# so the cold-machine case is testable without a container and nothing here can touch
# the operator's real config.
#
#   tests/criteria.sh          run every bar
#   tests/criteria.sh -v       also show the commands each bar ran

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERBOSE=0
[ "${1:-}" = "-v" ] && VERBOSE=1

PASS=0
FAIL=0

# The sentence that must exist in exactly one authored file. Changing the doctrine is
# fine; changing this line means updating it here too.
CANARY="Direction drift is my top complaint"

scratch() { mktemp -d "${TMPDIR:-/tmp}/criteria.XXXXXX"; }

bar() {
  local name="$1" measured="$2" ok="$3"
  if [ "$ok" = 1 ]; then
    printf 'PASS  %-26s %s\n' "$name" "$measured"
    PASS=$((PASS + 1))
  else
    printf 'FAIL  %-26s %s\n' "$name" "$measured"
    FAIL=$((FAIL + 1))
  fi
}

run() { [ "$VERBOSE" = 1 ] && echo "      \$ $*" >&2; "$@"; }

# --- 1. cold machine: empty HOME reaches a configured state, no manual steps --------

cold_machine() {
  local home start elapsed ok=0 doctrine
  home="$(scratch)"
  start=$(date +%s)
  if HOME="$home" run "$REPO/bin/sync.sh" >/dev/null 2>&1; then
    doctrine="$(readlink -f "$home/.claude/AGENTS.md" 2>/dev/null || true)"
    [ "$doctrine" = "$REPO/AGENTS.md" ] && ok=1
  fi
  elapsed=$(( $(date +%s) - start ))
  bar "cold machine" "${elapsed}s to configured (bar: 300s, 0 prompts)" \
      "$([ "$ok" = 1 ] && [ "$elapsed" -le 300 ] && echo 1 || echo 0)"
  rm -rf "$home"
}

# --- 2. rule duplication: the canary exists in exactly one authored file ------------

rule_duplication() {
  local hits
  # tests/ is excluded because this harness necessarily names the canary to search for it.
  hits=$(grep -rl --exclude-dir=.git --exclude-dir=backups --exclude-dir=tests \
           -F "$CANARY" "$REPO" 2>/dev/null | wc -l)
  bar "rule duplication" "$hits authored copies (bar: exactly 1)" \
      "$([ "$hits" -eq 1 ] && echo 1 || echo 0)"
}

# --- 3. cross-agent reach: every detected target resolves to the same doctrine ------

cross_agent_reach() {
  local home reached=0 total=0 t root doctrine
  home="$(scratch)"
  HOME="$home" run "$REPO/bin/sync.sh" >/dev/null 2>&1
  # shellcheck source=../lib/targets.sh
  HOME="$home" . "$REPO/lib/targets.sh"
  for t in "${TARGETS[@]}"; do
    root="$(field "$t" 2)"
    total=$((total + 1))
    doctrine="$(readlink -f "$root/AGENTS.md" 2>/dev/null || true)"
    [ "$doctrine" = "$REPO/AGENTS.md" ] && reached=$((reached + 1))
  done
  bar "cross-agent reach" "$reached of $total targets on one doctrine" \
      "$([ "$reached" -eq "$total" ] && [ "$total" -ge 2 ] && echo 1 || echo 0)"
  rm -rf "$home"
  # restore the real target roots for later bars
  # shellcheck source=../lib/targets.sh
  . "$REPO/lib/targets.sh"
}

# --- 4. drift loss: an edit through the link is visible in the repo -----------------

drift_loss() {
  local home probe ok=0
  home="$(scratch)"
  HOME="$home" run "$REPO/bin/sync.sh" >/dev/null 2>&1
  probe="$home/.claude/skills/evolve/SKILL.md"
  if [ -L "$home/.claude/skills/evolve" ] && [ -w "$probe" ]; then
    # writing through the link must land on the repo file, not a copy
    [ "$(readlink -f "$probe")" = "$REPO/skills/evolve/SKILL.md" ] && ok=1
  fi
  bar "drift loss" "$([ "$ok" = 1 ] && echo "0 edits lost - live file is the repo file" || echo "edit would not reach the repo")" "$ok"
  rm -rf "$home"
}

# --- 5. idempotence: a second run leaves a byte-identical tree ----------------------

idempotence() {
  local home a b ok=0
  home="$(scratch)"
  HOME="$home" run "$REPO/bin/sync.sh" >/dev/null 2>&1
  a="$(cd "$home" && find . -path ./.claude/backups -prune -o \( -printf '%p %y ' -print0 \) 2>/dev/null | sort | cksum)"
  HOME="$home" "$REPO/bin/sync.sh" >/dev/null 2>&1
  b="$(cd "$home" && find . -path ./.claude/backups -prune -o \( -printf '%p %y ' -print0 \) 2>/dev/null | sort | cksum)"
  [ "$a" = "$b" ] && ok=1
  bar "idempotence" "$([ "$ok" = 1 ] && echo "identical tree on re-run" || echo "tree changed on re-run")" "$ok"
  rm -rf "$home"
}

# --- 6. project stamp: an empty repo gets rules in effect ---------------------------

project_stamp() {
  local proj start elapsed ok=0
  proj="$(scratch)"
  ( cd "$proj" && git init -q . ) 2>/dev/null
  start=$(date +%s)
  if [ -x "$REPO/bin/stamp.sh" ] && run "$REPO/bin/stamp.sh" "$proj" >/dev/null 2>&1; then
    [ -f "$proj/AGENTS.md" ] && ok=1
    # a project file must not restate doctrine
    if [ -f "$proj/CLAUDE.md" ] && grep -qF "$CANARY" "$proj/CLAUDE.md" 2>/dev/null; then ok=0; fi
  fi
  elapsed=$(( $(date +%s) - start ))
  bar "project stamp" "${elapsed}s to rules-in-effect (bar: 30s)" \
      "$([ "$ok" = 1 ] && [ "$elapsed" -le 30 ] && echo 1 || echo 0)"
  rm -rf "$proj"
}

# --- 7. curated promotion: no path commits without an explicit message --------------

curated_promotion() {
  local out ok=0
  out="$("$REPO/bin/capture.sh" --commit 2>&1 || true)"
  case "$out" in *"needs -m"*) ok=1 ;; esac
  bar "curated promotion" "$([ "$ok" = 1 ] && echo "0 unapproved commit paths" || echo "capture.sh committed without a message")" "$ok"
}

# --- strata: hand-written agent files are never destroyed ---------------------------

stratum_handwritten() {
  local home ok=1 backup
  home="$(scratch)"
  mkdir -p "$home/.claude" "$home/.codex"
  printf 'hand written claude\n' > "$home/.claude/CLAUDE.md"
  printf 'hand written codex\n'  > "$home/.codex/AGENTS.md"
  HOME="$home" run "$REPO/bin/sync.sh" >/dev/null 2>&1
  for backup in "$home/.claude/backups"/*/CLAUDE.md "$home/.codex/backups"/*/AGENTS.md; do
    [ -f "$backup" ] || ok=0
  done
  grep -q 'hand written claude' "$home/.claude/backups"/*/CLAUDE.md 2>/dev/null || ok=0
  bar "stratum: hand-written" "$([ "$ok" = 1 ] && echo "both files backed up readably" || echo "a hand-written file was lost")" "$ok"
  rm -rf "$home"
}

echo "Ship criteria - docs/product-spec-v1.md section 6"
echo
cold_machine
rule_duplication
cross_agent_reach
drift_loss
idempotence
project_stamp
curated_promotion
stratum_handwritten
echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
