#!/usr/bin/env bash
# eos-setup-mirrors.sh — create GitLab -> GitHub push mirrors for every repo in
# repos.toml, so GitHub stays a read-only mirror of the GitLab source of truth.
#
# You run this yourself: it needs a GitHub Personal Access Token, which is read
# from an env var and embedded ONLY in the local GitLab API call. The token is
# never printed, echoed, or committed.
#
#   1. Create a GitHub PAT (classic) with scope: repo
#        GitHub -> Settings -> Developer settings -> Personal access tokens
#        -> Tokens (classic) -> Generate new token -> scope: repo
#   2. export GITHUB_MIRROR_PAT=ghp_xxxxxxxx
#   3. scripts/eos-setup-mirrors.sh            # DRY RUN — shows what it would do
#   4. scripts/eos-setup-mirrors.sh --apply    # creates the mirrors
#
# Idempotent: repos that already push-mirror to github are skipped.
# Requires: glab (authenticated), python3.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="${EOS_REPOS_MANIFEST:-$HERE/repos.toml}"
GH_USER="${GITHUB_MIRROR_USER:-Gh0s777tt}"
APPLY=0; [ "${1:-}" = "--apply" ] && APPLY=1

command -v glab >/dev/null || { echo "glab not found"; exit 1; }
[ -f "$MANIFEST" ] || { echo "manifest not found: $MANIFEST"; exit 1; }
if [ -z "${GITHUB_MIRROR_PAT:-}" ]; then
  echo "ERROR: set GITHUB_MIRROR_PAT to your GitHub PAT (scope: repo) first." >&2; exit 1
fi

_parse() { python3 - "$MANIFEST" <<'PY'
import sys, re
for b in open(sys.argv[1]).read().split('[[repo]]')[1:]:
    g=lambda k:(re.search(rf'^\s*{k}\s*=\s*"?([^"\n]+?)"?\s*$',b,re.M) or [None,''])[1].strip() if re.search(rf'^\s*{k}\s*=',b,re.M) else ''
    print('\t'.join([g('name'), g('github'), g('gitlab')]))
PY
}

created=0; skipped=0
while IFS=$'\t' read -r name gh gl; do
  path=$(echo "$gl" | sed -E 's#https://gitlab.com/(.*)\.git#\1#')
  enc=$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1],safe=''))" "$path")
  # already mirrored to github?
  has=$(glab api "projects/$enc/remote_mirrors" 2>/dev/null | python3 -c "import sys,json
try: d=json.load(sys.stdin)
except: print('0'); sys.exit()
print('1' if any('github' in m.get('url','') for m in d) else '0')")
  if [ "$has" = "1" ]; then echo "= $name : github mirror already present — skip"; skipped=$((skipped+1)); continue; fi
  # target URL with embedded credentials (NEVER printed)
  target="https://${GH_USER}:${GITHUB_MIRROR_PAT}@${gh#https://}"
  if [ "$APPLY" = "1" ]; then
    glab api "projects/$enc/remote_mirrors" -X POST \
      -f "url=$target" -f "enabled=true" -f "only_protected_branches=false" -f "keep_divergent_refs=false" >/dev/null \
      && { echo "+ $name : push mirror -> github created"; created=$((created+1)); } \
      || echo "! $name : FAILED to create mirror"
  else
    echo "+ $name : WOULD create push mirror -> github (dry-run)"; created=$((created+1))
  fi
done < <(_parse)

echo "---- ${APPLY:+applied }created=$created skipped=$skipped ----"
[ "$APPLY" = "0" ] && echo "(dry run — re-run with --apply to create the mirrors)"
