#!/usr/bin/env bash
# What this machine's agent config actually consists of, in one screen.
#
# Reads the content itself rather than any registry, so adding a skill changes this
# output and nothing else. Grouping comes from the `category:` line in each item's
# frontmatter; anything without one shows as uncategorised, which is the nudge to add it.
#
#   inventory.sh             everything, grouped by category
#   inventory.sh <category>  one category only
#   inventory.sh --roles     per-role and per-target counts, no item list

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/targets.sh
. "$REPO/lib/targets.sh"

ONLY=""
ROLES=0
for arg in "$@"; do
  case "$arg" in
    --roles)   ROLES=1 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    -*) echo "unknown flag: $arg" >&2; exit 2 ;;
    *)  ONLY="$arg" ;;
  esac
done

ROLES_ALL="skills agents hooks"

# meta <file> <key> - one declared value, empty if absent. Documents declare it in YAML
# frontmatter, scripts in a leading comment; both forms are read, and only the header is
# searched, so a later mention of the same word in the body is never mistaken for a field.
meta() {
  awk -v k="$2" '
    NR==1 && $0=="---" { fm=1; next }
    fm && $0=="---" { exit }
    !fm && NR>8 { exit }
    { line=$0; sub(/^# */,"",line) }
    index(line, k ":")==1 { sub("^" k ": *","",line); print line; exit }
  ' "$1"
}


# entry <path> - the descriptive file for one item, whatever shape the role uses
entry() { [ -d "$1" ] && echo "$1/SKILL.md" || echo "$1"; }

# where <role> - which targets accept this role, comma separated
where() {
  local t out="" id
  for t in "${TARGETS[@]}"; do
    id="$(field "$t" 1)"
    case " $(field "$t" 5) " in *" $1 "*) out="${out:+$out,}$id" ;; esac
  done
  echo "${out:--}"
}

if [ "$ROLES" = 1 ]; then
  printf '%-10s %-6s %s\n' "ROLE" "ITEMS" "INSTALLED INTO"
  for role in $ROLES_ALL; do
    n=0
    [ -d "$REPO/$role" ] && n="$(find "$REPO/$role" -mindepth 1 -maxdepth 1 | wc -l)"
    printf '%-10s %-6s %s\n' "$role" "$n" "$(where "$role")"
  done
  echo
  printf '%-10s %-28s %s\n' "TARGET" "ROOT" "DETECTED"
  for t in "${TARGETS[@]}"; do
    id="$(field "$t" 1)"; root="$(field "$t" 2)"
    detected "$root" "$id" && d=yes || d=no
    printf '%-10s %-28s %s\n' "$id" "$root" "$d"
  done
  exit 0
fi

# One pass over every item, emitting "category<TAB>role<TAB>name<TAB>summary", so the
# grouping is a sort rather than a nested walk.
collect() {
  local role item file cat name sum
  for role in $ROLES_ALL; do
    [ -d "$REPO/$role" ] || continue
    while IFS= read -r -d '' item; do
      file="$(entry "$item")"
      name="$(basename "$item")"; name="${name%.md}"; name="${name%.sh}"
      if [ -f "$file" ]; then
        cat="$(meta "$file" category)"
        sum="$(meta "$file" description)"
        # A block description (`description: |`) puts the text on the next lines.
        [ "$sum" = "|" ] && sum="$(sed -n '/^description: |/{n;p;q;}' "$file" | sed 's/^ *//')"
        # A hook is a script, not a document: its first plain header comment is the summary.
        [ -z "$sum" ] && sum="$(awk 'NR>1 && /^#/ { s=$0; sub(/^# */,"",s);
              if (s !~ /^[a-z_]+:/ && s != "") { print s; exit } } !/^#/ && NR>1 { exit }' "$file")"
      else
        cat=""; sum=""
      fi
      printf '%s\t%s\t%s\t%s\n' "${cat:-uncategorised}" "$role" "$name" "${sum:0:82}"
    done < <(find "$REPO/$role" -mindepth 1 -maxdepth 1 -print0 | sort0)
  done
}

current=""
while IFS=$'\t' read -r cat role name sum; do
  [ -n "$ONLY" ] && [ "$cat" != "$ONLY" ] && continue
  if [ "$cat" != "$current" ]; then
    current="$cat"
    printf '\n== %s\n' "$cat"
  fi
  printf '  %-9s %-14s %s\n' "$role" "$name" "$sum"
done < <(collect | sort -t$'\t' -k1,1 -k2,2 -k3,3)

if [ -z "$ONLY" ]; then
  echo
  echo "bin/inventory.sh --roles   # per-role counts and where each lands"
  echo "bin/sync.sh --status       # whether each item is actually linked on this machine"
fi
