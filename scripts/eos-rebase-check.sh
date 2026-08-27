#!/usr/bin/env bash
# eos-rebase-check.sh — czy łatki forków typu C nadal dadzą się nałożyć na upstream.
#
# PO CO. `CLAUDE.md` §11 wymaga od forków typu C **rebaseowalności**: łatka, której nie da
# się przenieść na nowy upstream, jest długiem, którego nikt nie umie spłacić. Nic tego nie
# mierzyło, więc konflikt ujawniłby się dopiero przy próbie synchronizacji — czyli wtedy,
# gdy najbardziej przeszkadza.
#
# Nie uruchamia prawdziwego rebase'u: używa `git merge-tree --write-tree`, które wykrywa
# konflikty bez dotykania drzewa roboczego.
#
#   scripts/eos-rebase-check.sh              # wszystkie forki z polem `upstream`
#   scripts/eos-rebase-check.sh eos-kernel   # jeden
#
# Wymaga sieci i pełnych obiektów, więc miejsce dla niego to zadanie **scheduled** (§13).
set -uo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$0")")" || exit 1
ONLY="${1:-}"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

entries=$(python3 - repos.toml <<'PY'
import re, sys
for b in open(sys.argv[1], encoding="utf-8").read().split("[[repo]]")[1:]:
    g = lambda k: (re.search(rf'^\s*{k}\s*=\s*"([^"]+)"', b, re.M) or [None, ""])[1]
    if g("upstream"):
        print("\t".join([g("name"), g("github"), g("upstream"), g("pinned_branch") or "master"]))
PY
)

printf '%-18s %-12s %s\n' "REPO" "STATUS" "SZCZEGÓŁY"
fail=0; checked=0
while IFS=$'\t' read -r name gh up branch; do
  [ -n "$ONLY" ] && [ "$name" != "$ONLY" ] && continue
  checked=$((checked + 1))
  d="$WORK/$name"
  git clone --quiet --no-checkout "$gh" "$d" 2>/dev/null || {
    printf '%-18s %-12s %s\n' "$name" "?" "nie udało się sklonować"; continue; }
  git -C "$d" remote add upstream "$up" 2>/dev/null
  git -C "$d" fetch --quiet upstream 2>/dev/null || {
    printf '%-18s %-12s %s\n' "$name" "?" "nie udało się pobrać upstreamu"; continue; }

  head_up="$(git -C "$d" rev-parse --verify --quiet upstream/HEAD 2>/dev/null \
             || git -C "$d" rev-parse --verify --quiet upstream/master 2>/dev/null \
             || git -C "$d" rev-parse --verify --quiet upstream/main 2>/dev/null)"
  [ -z "$head_up" ] && { printf '%-18s %-12s %s\n' "$name" "?" "nie znaleziono gałęzi upstreamu"; continue; }

  own=$(git -C "$d" rev-list --count "origin/$branch" --not --remotes=upstream 2>/dev/null || echo 0)
  if [ "$own" = "0" ]; then
    printf '%-18s %-12s %s\n' "$name" "lustro" "0 własnych commitów — nic do rebase'owania"
    continue
  fi

  if out=$(git -C "$d" merge-tree --write-tree "origin/$branch" "$head_up" 2>&1); then
    printf '%-18s %-12s %s\n' "$name" "OK" "$own łatek nakłada się czysto"
  else
    n=$(printf '%s\n' "$out" | grep -c "CONFLICT" || true)
    printf '%-18s %-12s %s\n' "$name" "KONFLIKT" "$own łatek, $n konfliktów"
    fail=1
  fi
done <<< "$entries"

echo "---- sprawdzonych=$checked ----"
if [ "$fail" -ne 0 ]; then
  echo "Konflikt oznacza, ze latka przestala byc rebaseowalna. Rozwiaz go teraz i opisz"
  echo "w tresci commita status wobec upstreamu (CLAUDE.md §11 typ C), a nie przy nastepnym syncu."
  exit 1
fi
