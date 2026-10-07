#!/usr/bin/env bash
# Render the configured system as one self-contained HTML page: every skill, agent,
# hook and doctrine file, with what is installed where on this machine.
#
# It shows the content the hub DISTRIBUTES, not the paperwork behind building the hub.
# docs/ and README.md are this repo's own specs and plans - they are never installed into
# any agent, so they are not part of what the operator is configured with.
#
#   report.sh              write the page, print its path
#   report.sh --open       write it and open it in the browser
#   report.sh --out PATH   write somewhere other than the repo root
#
# Read-only by construction. It reports; it installs, edits and deletes nothing, and the
# commands it shows are for the operator to run. Needs jq - this is an inspection tool,
# never part of the install path, so a machine without jq still configures normally.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/targets.sh
. "$REPO/lib/targets.sh"

OUT="$REPO/hub.html"
OPEN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --open)    OPEN=1; shift ;;
    --out)     OUT="${2:?--out needs a path}"; shift 2 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
done

command -v jq >/dev/null 2>&1 || { echo "report.sh needs jq. Everything else works without it." >&2; exit 2; }

TEMPLATE="$REPO/web/hub.template.html"
[ -f "$TEMPLATE" ] || { echo "missing $TEMPLATE" >&2; exit 2; }

ROLES="skills agents hooks"

# Directory names that are recognisably agent config but have no row in lib/targets.sh.
# Listed so the page can say "found, unsupported" instead of silently ignoring them -
# and only ever to report. Installing into an unknown format writes broken files.
KNOWN_AGENTS="cursor:Cursor gemini:Gemini CLI copilot:GitHub Copilot windsurf:Windsurf
continue:Continue opencode:OpenCode crush:Crush amp:Amp goose:Goose cline:Cline zed:Zed"

# --- which targets accept a role, and which are present here ------------------------

targets_json() {
  local t id root accepts doctrine dj
  printf '['
  local first=1
  for t in "${TARGETS[@]}"; do
    id="$(field "$t" 1)"; root="$(field "$t" 2)"; accepts="$(field "$t" 5)"
    doctrine="$(rlf "$root/AGENTS.md" 2>/dev/null || true)"
    [ "$doctrine" = "$REPO/AGENTS.md" ] && dj=true || dj=false
    [ "$first" = 1 ] || printf ','
    first=0
    jq -nc --arg id "$id" --arg root "$root" --arg dp "$(field "$t" 3)" \
          --arg dm "$(field "$t" 4)" --arg ac "$accepts" --arg rh "$(field "$t" 6)" \
          --argjson det "$(detected "$root" "$id" && echo true || echo false)" \
          --argjson dok "$dj" \
      '{id:$id,root:$root,doctrine_path:$dp,doctrine_mode:$dm,accepts:$ac,restart_hint:$rh,detected:$det,doctrine_ok:$dok}'
  done
  printf ']'
}

# --- agent directories on this machine that nothing here supports -------------------

discovered_json() {
  local pair name label dir
  printf '['
  local first=1
  for pair in $KNOWN_AGENTS; do
    name="${pair%%:*}"; label="${pair#*:}"
    for dir in "$HOME/.$name" "$HOME/.config/$name"; do
      [ -d "$dir" ] || continue
      case " $(for t in "${TARGETS[@]}"; do field "$t" 2; printf ' '; done) " in *" $dir "*) continue ;; esac
      [ "$first" = 1 ] || printf ','
      first=0
      jq -nc --arg d "$dir" --arg n "${label//_/ } config directory" '{dir:$d,note:$n}'
    done
  done
  printf ']'
}

# --- every readable file, with its declared category and where it lands -------------

# declared <file> <key> - a value from YAML frontmatter or a leading "# key:" comment
declared() {
  awk -v k="$2" '
    NR==1 && $0=="---" { fm=1; next }
    fm && $0=="---" { exit }
    !fm && NR>8 { exit }
    { line=$0; sub(/^# */,"",line) }
    index(line, k ":")==1 { sub("^" k ": *","",line); print line; exit }
  ' "$1"
}

# reach <role> - ids of the targets that take this role, as a JSON array
reach() {
  local t out=()
  for t in "${TARGETS[@]}"; do
    case " $(field "$t" 5) " in *" $1 "*) out+=("$(field "$t" 1)") ;; esac
  done
  [ "${#out[@]}" -gt 0 ] && printf '%s\n' "${out[@]}" | jq -Rnc '[inputs]' || echo '[]'
}

# one_file <path> <role> <fallback-category>
one_file() {
  local path="$1" role="$2" fallback="$3" rel cat sum lang label
  rel="${path#"$REPO"/}"
  # A skill is a directory whose entry point is always called SKILL.md, so the file name
  # names nothing. The directory is what the operator calls it.
  label="$(basename "$path")"
  [ "$label" = SKILL.md ] && label="$(basename "$(dirname "$path")")"
  # The extension is noise in a list where the role column already says what the thing is,
  # and the full path stays on the page as the breadcrumb. AGENTS.md keeps its, because the
  # filename IS the standard - "AGENTS" alone names nothing.
  [ "$label" = AGENTS.md ] || label="${label%.md}"
  case "$path" in
    *.md)   lang=markdown ;;
    *.sh)   lang=shell ;;
    *.json) lang=json ;;
    *.yml|*.yaml) lang=yaml ;;
    *) lang=text ;;
  esac
  cat="$(declared "$path" category)"; [ -n "$cat" ] || cat="$fallback"
  sum="$(declared "$path" description)"
  [ "$sum" = "|" ] && sum="$(sed -n '/^description: |/{n;p;q;}' "$path" | sed 's/^ *//')"
  [ -n "$sum" ] || sum="$(awk 'NR>1 && /^#/ { s=$0; sub(/^# */,"",s);
        if (s !~ /^[a-z_]+:/ && s != "") { print s; exit } } !/^#/ && NR>1 { exit }' "$path")"

  # Group by the top-level folder only. A skill lives in skills/<name>/SKILL.md, and the
  # operator thinks of it as one of the skills, not as its own folder.
  local dir="${rel%%/*}"; [ "$dir" = "$rel" ] && dir="root"
  jq -nc --arg p "$rel" --arg n "$label" --arg d "$dir" \
        --arg r "$role" --arg c "$cat" --arg s "$sum" --arg l "$lang" \
        --arg z "$(du -h "$path" | cut -f1)B" --argjson i "$(reach "$role")" \
        --rawfile b "$path" \
    '{path:$p,name:$n,dir:$d,role:$r,category:$c,summary:$s,lang:$l,size:$z,installed:$i,body:$b}'
}

files_json() {
  local role item f
  {
    for role in $ROLES; do
      [ -d "$REPO/$role" ] || continue
      while IFS= read -r -d '' item; do
        if [ -d "$item" ]; then
          while IFS= read -r -d '' f; do one_file "$f" "$role" ""; done \
            < <(find "$item" -type f \( -name '*.md' -o -name '*.sh' -o -name '*.json' \) -print0 | sort0)
        else
          one_file "$item" "$role" ""
        fi
      done < <(find "$REPO/$role" -mindepth 1 -maxdepth 1 -print0 | sort0)
    done
    one_file "$REPO/AGENTS.md" doctrine doctrine
    one_file "$REPO/home/settings.hooks.json" hooks safety
    one_file "$REPO/lib/targets.sh" plumbing plumbing
    while IFS= read -r -d '' f; do one_file "$f" plumbing plumbing; done \
      < <(find "$REPO/bin" -maxdepth 1 -name '*.sh' -print0 | sort0)
  } | jq -sc '.'
}

# The file bodies run to well over a hundred kilobytes, which is past the kernel's argv
# limit, so every part goes to a temp file and jq slurps it rather than being passed one
# enormous --argjson.
# roles_json - one row per content role: who takes it, who has it, and what is missing.
# The page needs this to answer "is this installed for codex?" without guessing.
roles_json() {
  local role t id root taken here n
  printf '['
  local first=1
  for role in $ROLES; do
    [ -d "$REPO/$role" ] || continue
    n="$(find "$REPO/$role" -mindepth 1 -maxdepth 1 | wc -l)"
    taken='[]'; here='[]'
    for t in "${TARGETS[@]}"; do
      id="$(field "$t" 1)"; root="$(field "$t" 2)"
      case " $(field "$t" 5) " in *" $role "*) ;; *) continue ;; esac
      taken="$(jq -c --arg i "$id" '. + [$i]' <<<"$taken")"
      # present means the link is actually there, not merely that the target accepts it
      if [ -d "$root/$role" ] && [ -n "$(find "$root/$role" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
        here="$(jq -c --arg i "$id" '. + [$i]' <<<"$here")"
      fi
    done
    [ "$first" = 1 ] || printf ','
    first=0
    jq -nc --arg r "$role" --argjson n "$n" --argjson takes "$taken" --argjson has "$here" \
      '{role:$r,count:$n,takes:$takes,has:$has}'
  done
  printf ']'
}

payload() {
  local d
  d="$(mktemp -d)"
  targets_json    > "$d/targets.json"
  roles_json      > "$d/roles.json"
  discovered_json > "$d/discovered.json"
  files_json      > "$d/files.json"
  printf '%s\n' 'bin/bootstrap.sh' 'bin/sync.sh --status' 'bin/inventory.sh --roles' \
                'bin/report.sh --open' 'tests/criteria.sh' | jq -Rc '.' | jq -sc '.' > "$d/commands.json"

  jq -nc \
    --arg generated "$(date '+%Y-%m-%d %H:%M')" \
    --arg repo "$REPO" \
    --slurpfile targets    "$d/targets.json" \
    --slurpfile roles      "$d/roles.json" \
    --slurpfile discovered "$d/discovered.json" \
    --slurpfile files      "$d/files.json" \
    --slurpfile commands   "$d/commands.json" \
    '{generated:$generated,repo:$repo,
      targets:$targets[0],roles:$roles[0],discovered:$discovered[0],
      files:$files[0],commands:$commands[0]}'
  rm -rf "$d"
}

# Splice at the placeholder rather than substituting. awk's index() is a literal search,
# so neither the marker nor the payload can be read as a regex or a replacement pattern -
# and the payload is full of the characters that would otherwise be.
marker='/*__PAYLOAD__*/'
grep -qF "$marker" "$TEMPLATE" || { echo "template has no $marker placeholder" >&2; exit 2; }

tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
# A file that contains "</script>" would end the page's script early. "<\/" is the same
# string in JSON and cannot close a tag.
payload | sed 's#</#<\\/#g' > "$tmp"

awk -v marker="$marker" -v data="$tmp" '
  !done {
    at = index($0, marker)
    if (at) {
      printf "%s", substr($0, 1, at - 1)
      while ((getline chunk < data) > 0) printf "%s", chunk
      close(data)
      # Whatever followed the marker was only there to keep the bare template valid
      # JavaScript, so it is dropped rather than emitted after the payload.
      print ";"
      done = 1
      next
    }
  }
  { print }
' "$TEMPLATE" > "$OUT"

echo "$OUT"
if [ "$OPEN" = 1 ]; then
  for o in xdg-open open sensible-browser; do
    command -v "$o" >/dev/null 2>&1 && { "$o" "$OUT" >/dev/null 2>&1 & exit 0; }
  done
  echo "no browser opener found - open $OUT yourself" >&2
fi
