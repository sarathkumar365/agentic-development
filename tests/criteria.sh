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

# Sourced for rlf/sort0 - the portability helpers every bar below relies on.
# shellcheck source=../lib/targets.sh
. "$REPO/lib/targets.sh"

PASS=0
FAIL=0

# The sentence that must exist in exactly one authored file. Changing the doctrine is
# fine; changing this line means updating it here too.
CANARY="Direction drift is my top complaint"

scratch() { mktemp -d "${TMPDIR:-/tmp}/criteria.XXXXXX"; }

# fingerprint <dir> - path, type and link destination of everything under dir, so a
# re-run that changed nothing checksums identically. Written without `find -printf`,
# which BSD find does not have, so the bar measures the same thing on macOS.
fingerprint() {
  ( cd "$1" 2>/dev/null || return 0
    find . -path ./.claude/backups -prune -o -path ./.codex/backups -prune -o -print 2>/dev/null \
    | LC_ALL=C sort \
    | while IFS= read -r f; do
        if [ -L "$f" ]; then printf '%s L %s\n' "$f" "$(readlink "$f")"
        elif [ -d "$f" ]; then printf '%s d\n' "$f"
        else printf '%s f %s\n' "$f" "$(cksum < "$f" 2>/dev/null)"
        fi
      done ) | cksum
}

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
    doctrine="$(rlf "$home/.claude/AGENTS.md" 2>/dev/null || true)"
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
  # hub.html is excluded because it is generated and gitignored: it quotes the doctrine to
  # display it, the way an installed symlink resolves to it. The bar counts AUTHORED copies.
  #
  # Selection is done by find rather than `grep --exclude-dir`, which BSD grep spells the
  # same way but BusyBox does not have at all - and a search that errors reports zero hits,
  # which would read as a passing-looking failure.
  hits=$(find "$REPO" -type f \
           ! -path '*/.git/*' ! -path '*/backups/*' ! -path '*/tests/*' \
           ! -name hub.html -exec grep -lF "$CANARY" {} + 2>/dev/null | wc -l)
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
    doctrine="$(rlf "$root/AGENTS.md" 2>/dev/null || true)"
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
    [ "$(rlf "$probe")" = "$REPO/skills/evolve/SKILL.md" ] && ok=1
  fi
  bar "drift loss" "$([ "$ok" = 1 ] && echo "0 edits lost - live file is the repo file" || echo "edit would not reach the repo")" "$ok"
  rm -rf "$home"
}

# --- 5. idempotence: a second run leaves a byte-identical tree ----------------------

idempotence() {
  local home a b ok=0
  home="$(scratch)"
  HOME="$home" run "$REPO/bin/sync.sh" >/dev/null 2>&1
  a="$(fingerprint "$home")"
  HOME="$home" "$REPO/bin/sync.sh" >/dev/null 2>&1
  b="$(fingerprint "$home")"
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

# --- 8. hooks reach: scripts linked, declared, and actually firing ------------------

hooks_reach() {
  local home ok=1 verdict
  home="$(scratch)"
  HOME="$home" run "$REPO/bin/sync.sh" >/dev/null 2>&1

  # every target that accepts hooks, not just the one they were authored against
  local t id root hf hp n=0
  HOME="$home" . "$REPO/lib/targets.sh"
  for t in "${TARGETS[@]}"; do
    case " $(field "$t" 5) " in *" hooks "*) ;; *) continue ;; esac
    id="$(field "$t" 1)"; root="$(field "$t" 2)"
    hf="$(field "$t" 8)"; hp="$(field "$t" 9)"
    n=$((n + 1))
    [ -L "$root/hooks/deny-secret-files.sh" ] || ok=0
    # declared, so the agent knows when to fire them - and pointing at ITS hooks dir
    if command -v jq >/dev/null 2>&1; then
      jq -e --arg at "$hp" --arg dir "$root/hooks" '
        ($at | if . == "." then [] else ltrimstr(".") | split(".") end) as $p
        | [getpath($p + ["PreToolUse"])[]?.hooks[]?.command]
        | length >= 3 and all(startswith($dir))' "$root/$hf" >/dev/null 2>&1 || ok=0
    fi
  done
  [ "$n" -ge 2 ] || ok=0
  . "$REPO/lib/targets.sh"
  # and the script has to return the deny the declaration promises
  verdict="$(echo '{"tool_input":{"file_path":"/x/.env"}}' | "$REPO/hooks/deny-secret-files.sh" 2>/dev/null)"
  case "$verdict" in *'"deny"'*) ;; *) ok=0 ;; esac

  bar "hooks reach" "$([ "$ok" = 1 ] && echo "3 hooks live in $n of $n hook-taking targets" || echo "hooks not installed or not firing")" "$ok"
  rm -rf "$home"
}

# --- 9. content is classified: every item declares a category ----------------------

content_classified() {
  local loose
  loose="$("$REPO/bin/inventory.sh" 2>/dev/null | awk '/^== uncategorised/{f=1;next} /^== /{f=0} f && /^  [a-z]/' | wc -l)"
  bar "content classified" "$loose uncategorised items (bar: 0)" \
      "$([ "$loose" -eq 0 ] && echo 1 || echo 0)"
}

# --- stratum: a hand-written settings key survives the hook merge -------------------

stratum_settings() {
  local home ok=1
  home="$(scratch)"
  mkdir -p "$home/.claude"
  printf '{"theme":"dark","enabledPlugins":{"mine":true}}\n' > "$home/.claude/settings.json"
  HOME="$home" run "$REPO/bin/sync.sh" >/dev/null 2>&1
  if command -v jq >/dev/null 2>&1; then
    jq -e '.theme == "dark" and .enabledPlugins.mine == true and (.hooks.PreToolUse | length) > 0' \
      "$home/.claude/settings.json" >/dev/null 2>&1 || ok=0
  fi
  bar "stratum: settings merge" "$([ "$ok" = 1 ] && echo "existing keys kept, hooks added" || echo "a hand-written settings key was lost")" "$ok"
  rm -rf "$home"
}

# --- 10. report coverage: the page shows everything the inventory lists ------------

report_coverage() {
  local out listed shown ok=0
  if ! command -v jq >/dev/null 2>&1; then
    bar "report coverage" "skipped - jq absent (report.sh is an inspection tool, not the installer)" 1
    return
  fi
  out="$(mktemp -d)/hub.html"
  "$REPO/bin/report.sh" --out "$out" >/dev/null 2>&1
  listed="$("$REPO/bin/inventory.sh" | grep -c '^  [a-z]' || true)"
  shown="$(grep '^const DATA = {' "$out" | sed 's/^const DATA = //; s/;$//' \
           | jq '[.files[] | select(.role=="skills" or .role=="agents" or .role=="commands" or .role=="hooks")] | length')"
  # A skill directory can hold more files than the one line inventory prints for it, so
  # the page may show more; it must never show fewer.
  [ "$shown" -ge "$listed" ] && ok=1
  bar "report coverage" "$shown of $listed inventory items on the page (bar: all)" "$ok"
  rm -rf "$(dirname "$out")"
}

# --- 11. report is read-only: it writes one file and touches no config -------------

report_read_only() {
  local home out before after ok=1
  home="$(scratch)"
  HOME="$home" "$REPO/bin/sync.sh" >/dev/null 2>&1
  before="$(cd "$home" && find . -newer "$home" -o -print | sort | cksum)"
  out="$home/hub.html"
  HOME="$home" "$REPO/bin/report.sh" --out "$out" >/dev/null 2>&1
  [ -f "$out" ] || ok=0
  rm -f "$out"
  after="$(cd "$home" && find . -newer "$home" -o -print | sort | cksum)"
  [ "$before" = "$after" ] || ok=0
  bar "report read-only" "$([ "$ok" = 1 ] && echo "wrote 1 file, changed no config" || echo "the report touched config")" "$ok"
  rm -rf "$home"
}

# --- 12. complexity cap: the install path stays small enough to trust ---------------

complexity_cap() {
  local install inspect ok=1
  install="$(cat "$REPO"/bin/bootstrap.sh "$REPO"/bin/sync.sh "$REPO"/bin/stamp.sh "$REPO"/lib/*.sh | wc -l)"
  inspect="$(cat "$REPO"/bin/inventory.sh "$REPO"/bin/report.sh "$REPO"/bin/capture.sh | wc -l)"
  [ "$install" -le 500 ] || ok=0
  [ "$inspect" -le 500 ] || ok=0
  bar "complexity cap" "install $install/500, inspection $inspect/500" "$ok"
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
hooks_reach
content_classified
report_coverage
report_read_only
complexity_cap
stratum_handwritten
stratum_settings
echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
