#!/usr/bin/env bash
# eos-repos.sh — manage the E-OS multi-repo ecosystem from repos.toml.
#
# repos.toml is the SINGLE SOURCE OF TRUTH for the repo list. This script reads
# it and drives clone/update/status/pins/mirrors across every repo.
#
# Hosting model: GitLab is the source of truth (dev + CI); GitHub is a
# read-only mirror. `clone`/`update` therefore default to the GitLab remote.
#
# Usage:
#   scripts/eos-repos.sh list                 # print the manifest as a table
#   scripts/eos-repos.sh clone  [DIR] [--from github|gitlab]
#   scripts/eos-repos.sh update [DIR]         # fetch --all --prune in each clone
#   scripts/eos-repos.sh status               # GitHub <-> GitLab sync matrix
#   scripts/eos-repos.sh pins                 # recipe pin == fork tip? (drift check)
#   scripts/eos-repos.sh mirrors              # GitLab push-mirror state per repo (needs glab)
#
# Env: EOS_REPOS_MANIFEST overrides the manifest path.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="${EOS_REPOS_MANIFEST:-$HERE/repos.toml}"
[ -f "$MANIFEST" ] || { echo "manifest not found: $MANIFEST" >&2; exit 1; }

# Emit one TAB-separated line per repo:
#   name  github  gitlab  role  pinned  recipe  branch  rev
_parse() {
  python3 - "$MANIFEST" <<'PY'
import sys, re
blocks = open(sys.argv[1]).read().split('[[repo]]')
for b in blocks[1:]:
    def g(k):
        m = re.search(rf'^\s*{k}\s*=\s*"?([^"\n]+?)"?\s*$', b, re.M)
        return m.group(1).strip() if m else ''
    print('\t'.join([g('name'), g('github'), g('gitlab'), g('role'),
                     g('pinned_in_recipe'), g('recipe'), g('pinned_branch'), g('pinned_rev')]))
PY
}

cmd_list() {
  printf "%-18s %-14s %-6s %s\n" "REPO" "ROLE" "PIN?" "RECIPE / BRANCH"
  while IFS=$'\t' read -r name gh gl role pinned recipe br rev; do
    printf "%-18s %-14s %-6s %s\n" "$name" "$role" "${pinned:-false}" "${recipe:+$recipe @ $br}"
  done < <(_parse)
}

cmd_clone() {
  local dir="${1:-eos-ecosystem}" from="gitlab"
  shift || true
  [ "${1:-}" = "--from" ] && from="${2:-gitlab}"
  mkdir -p "$dir"
  while IFS=$'\t' read -r name gh gl role pinned recipe br rev; do
    local url; [ "$from" = "github" ] && url="$gh" || url="$gl"
    if [ -d "$dir/$name/.git" ]; then echo "= $name (exists)"; else
      echo "+ cloning $name from $from"; git clone --quiet "$url" "$dir/$name"; fi
  done < <(_parse)
}

cmd_update() {
  local dir="${1:-eos-ecosystem}"
  while IFS=$'\t' read -r name gh gl role pinned recipe br rev; do
    [ -d "$dir/$name/.git" ] || { echo "? $name (not cloned)"; continue; }
    echo "~ $name"; git -C "$dir/$name" fetch --all --prune --tags --quiet
  done < <(_parse)
}

cmd_status() {
  printf "%-18s | %-3s | %-9s | %-9s | %s\n" "REPO" "GL?" "GH h/t" "GL h/t" "VERDICT"
  local sync=0 drift=0 missing=0
  while IFS=$'\t' read -r name gh gl role pinned recipe br rev; do
    local a b an bn
    a=$(git ls-remote "$gh" </dev/null 2>/dev/null); b=$(git ls-remote "$gl" </dev/null 2>/dev/null)
    an=$(echo "$a" | grep -E 'refs/(heads|tags)/' | awk '{print $2" "$1}' | sort)
    bn=$(echo "$b" | grep -E 'refs/(heads|tags)/' | awk '{print $2" "$1}' | sort)
    local ah at bh bt v gext="yes"
    ah=$(echo "$a"|grep -c 'refs/heads/' || true); at=$(echo "$a"|grep -c 'refs/tags/' || true)
    bh=$(echo "$b"|grep -c 'refs/heads/' || true); bt=$(echo "$b"|grep -c 'refs/tags/' || true)
    if [ -z "$b" ]; then v="GITLAB-MISSING"; gext="NO"; missing=$((missing+1))
    elif [ "$an" = "$bn" ]; then v="IN-SYNC"; sync=$((sync+1))
    else v="DRIFT"; drift=$((drift+1)); fi
    printf "%-18s | %-3s | %-9s | %-9s | %s\n" "$name" "$gext" "$ah/$at" "$bh/$bt" "$v"
  done < <(_parse)
  echo "---- in-sync=$sync drift=$drift gitlab-missing=$missing ----"
}

cmd_pins() {
  printf "%-16s | %-12s | %-11s | %-11s | %s\n" "FORK" "BRANCH" "PIN" "FORK-TIP" "STATUS"
  local ok=0 drift=0
  while IFS=$'\t' read -r name gh gl role pinned recipe br rev; do
    [ "$pinned" = "true" ] || continue
    local head
    head=$(git ls-remote "$gh" "refs/heads/$br" </dev/null 2>/dev/null | awk '{print $1}')
    local st
    if [ -z "$head" ]; then st="BRANCH-GONE:$br"; drift=$((drift+1))
    elif [ "$rev" = "$head" ]; then st="OK(tip)"; ok=$((ok+1))
    else st="DRIFT (recipe behind fork)"; drift=$((drift+1)); fi
    printf "%-16s | %-12s | %-11s | %-11s | %s\n" "$name" "$br" "${rev:0:10}" "${head:0:10}" "$st"
  done < <(_parse)
  echo "---- pins ok=$ok drift=$drift ----"
}

cmd_mirrors() {
  command -v glab >/dev/null || { echo "glab not found (needed for GitLab API)"; exit 1; }
  printf "%-18s | %-8s | %-11s | %s\n" "REPO" "vis" "push-mirror" "last_success"
  while IFS=$'\t' read -r name gh gl role pinned recipe br rev; do
    local path; path=$(echo "$gl" | sed -E 's#https://gitlab.com/(.*)\.git#\1#')
    local enc; enc=$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1],safe=''))" "$path")
    local vis; vis=$(glab api "projects/$enc" 2>/dev/null | python3 -c "import sys,json;print(json.load(sys.stdin).get('visibility','?'))" 2>/dev/null || echo '?')
    local info; info=$(glab api "projects/$enc/remote_mirrors" 2>/dev/null | python3 -c "
import sys,json
try: d=json.load(sys.stdin)
except: print('API-ERR|-'); sys.exit()
if not d: print('none|-')
else:
    m=d[0]; h='github' if 'github' in m.get('url','') else 'other'
    print(f\"->{h}({'on' if m.get('enabled') else 'off'})|{m.get('last_successful_update_at') or '-'}\")" 2>/dev/null || echo 'API-ERR|-')
    printf "%-18s | %-8s | %-11s | %s\n" "$name" "$vis" "${info%%|*}" "${info##*|}"
  done < <(_parse)
}

case "${1:-}" in
  list)    cmd_list ;;
  clone)   shift; cmd_clone "$@" ;;
  update)  shift; cmd_update "$@" ;;
  status)  cmd_status ;;
  pins)    cmd_pins ;;
  mirrors) cmd_mirrors ;;
  *) sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
