#!/usr/bin/env bash
# The ship criteria, as executable checks.
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

# --- 3. cross-agent reach: every declared target resolves to the same doctrine ------
#
# --all, because detection also looks at PATH: on a machine with some agents installed a
# plain run skips the rest, and the bar would measure this machine rather than the repo.

cross_agent_reach() {
  local home reached=0 total=0 t root doctrine
  home="$(scratch)"
  HOME="$home" run "$REPO/bin/sync.sh" --all >/dev/null 2>&1
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

# Runs against a scratch repo holding a copy of capture.sh, so a regression here commits
# into that copy and never into this repo.
curated_promotion() {
  local r out head ok=1
  r="$(scratch)"
  mkdir -p "$r/bin" "$r/lib"
  cp "$REPO/bin/capture.sh" "$r/bin/"; cp "$REPO/lib/targets.sh" "$r/lib/"
  ( cd "$r" && git init -q . && git add -A && git -c user.name=t -c user.email=t@t commit -qm init ) >/dev/null 2>&1
  echo chosen > "$r/chosen"; echo noise > "$r/noise"
  head="$(git -C "$r" rev-parse HEAD)"

  # no message, and a message with no paths, must both refuse and commit nothing
  out="$("$r/bin/capture.sh" --commit 2>&1 || true)"
  case "$out" in *"needs -m"*) ;; *) ok=0 ;; esac
  out="$("$r/bin/capture.sh" --commit -m sweep 2>&1 || true)"
  case "$out" in *"needs the paths"*) ;; *) ok=0 ;; esac
  [ "$(git -C "$r" rev-parse HEAD)" = "$head" ] || ok=0

  # a named path commits that path and leaves the rest of the dirty tree alone
  ( cd "$r" && GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t \
      bin/capture.sh --commit -m chosen chosen ) >/dev/null 2>&1
  [ "$(git -C "$r" show --name-only --format= HEAD)" = chosen ] || ok=0
  [ -n "$(git -C "$r" status --porcelain -- noise)" ] || ok=0

  bar "curated promotion" "$([ "$ok" = 1 ] && echo "0 unapproved commit paths, 0 swept files" || echo "capture.sh committed what nobody chose")" "$ok"
  rm -rf "$r"
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
  local t root hf hp n=0
  HOME="$home" . "$REPO/lib/targets.sh"
  for t in "${TARGETS[@]}"; do
    case " $(field "$t" 5) " in *" hooks "*) ;; *) continue ;; esac
    root="$(field "$t" 2)"
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
  [ "$n" -ge 1 ] || ok=0
  . "$REPO/lib/targets.sh"
  # and the script has to return the deny the declaration promises
  verdict="$(echo '{"tool_input":{"file_path":"/x/.env"}}' | "$REPO/hooks/deny-secret-files.sh" 2>/dev/null)"
  case "$verdict" in *'"deny"'*) ;; *) ok=0 ;; esac

  bar "hooks reach" "$([ "$ok" = 1 ] && echo "$(ls "$REPO"/hooks | wc -l | tr -d " ") hooks live in $n of $n hook-taking targets" || echo "hooks not installed or not firing")" "$ok"
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
           | jq '[.files[] | select(.role=="skills" or .role=="agents" or .role=="hooks")] | length')"
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
  before="$(fingerprint "$home")"
  out="$home/hub.html"
  HOME="$home" "$REPO/bin/report.sh" --out "$out" >/dev/null 2>&1
  [ -f "$out" ] || ok=0
  rm -f "$out"
  after="$(fingerprint "$home")"
  [ "$before" = "$after" ] || ok=0
  bar "report read-only" "$([ "$ok" = 1 ] && echo "wrote 1 file, changed no config" || echo "the report touched config")" "$ok"
  rm -rf "$home"
}

# --- 11b. stale prune: links whose source left the repo are removed, nothing else ----

stale_prune() {
  local home ok=1 c="" s
  home="$(scratch)"
  HOME="$home" run "$REPO/bin/sync.sh" >/dev/null 2>&1
  c="$home/.claude"; s="$c/settings.json"
  ln -s "$REPO/skills/no-such-skill" "$c/skills/ghost"
  ln -s "$REPO/hooks/no-such-hook.sh" "$c/hooks/no-such-hook.sh"
  mkdir -p "$home/.codex/agents" "$c/skills/hand-made"
  ln -s "$REPO/agents/curator.md" "$home/.codex/agents/curator.md"
  ln -s /tmp "$c/skills/elsewhere"
  jq --arg cmd "$c/hooks/no-such-hook.sh" '.hooks.PreToolUse += [{matcher:"Bash",hooks:[{type:"command",command:$cmd}]}]' "$s" > "$s.tmp" && mv "$s.tmp" "$s"
  HOME="$home" run "$REPO/bin/sync.sh" >/dev/null 2>&1
  [ ! -L "$c/skills/ghost" ] && [ ! -L "$c/hooks/no-such-hook.sh" ] && [ ! -L "$home/.codex/agents/curator.md" ] || ok=0
  [ -d "$c/skills/hand-made" ] && [ -L "$c/skills/elsewhere" ] && [ -L "$c/skills/feature" ] || ok=0
  grep -q no-such-hook "$s" && ok=0
  bar "stale prune" "$([ "$ok" = 1 ] && echo "3 stale links and 1 stale hook removed, others kept" || echo "stale content left or wrong thing removed")" "$ok"
  rm -rf "$home"
}

# --- 11c. commit gate: no commit without a review newer than the changes ------------

commit_gate() {
  local r ok=1 g="$REPO/hooks/git-guard.sh" c="commit"
  r="$(scratch)"
  git -C "$r" init -q && touch "$r/a" && git -C "$r" add a
  ask() { jq -nc --arg c "$1" --arg d "$2" '{tool_input:{command:$c},cwd:$d}' | "$g"; }
  case "$(ask "git $c -m x" "$r")" in *deny*) ;; *) ok=0 ;; esac
  case "$(ask "git -C $r $c -m x" /)" in *deny*) ;; *) ok=0 ;; esac
  mkdir -p "$r/.claude" && sleep 1 && touch "$r/.claude/.reviewed"
  [ -z "$(ask "git $c -m x" "$r")" ] || ok=0
  sleep 1 && echo y > "$r/a"
  case "$(ask 'git push' "$r")" in *deny*) ;; *) ok=0 ;; esac
  [ -z "$(ask 'git status' "$r")" ] || ok=0
  bar "commit gate" "$([ "$ok" = 1 ] && echo "blocks unreviewed, -C and stale; allows reviewed" || echo "gate let a commit through or blocked a reviewed one")" "$ok"
  rm -rf "$r"
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

echo "Ship criteria"
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
stale_prune
commit_gate
complexity_cap
stratum_handwritten
stratum_settings
echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
