#!/usr/bin/env bash
# eos-mirror-drift.sh — czy zadeklarowany typ repozytorium zgadza się z pomiarem.
#
# PO CO. `CLAUDE.md` §11 dzieli repozytoria na typy, a różnica między typem B (lustro,
# READ-ONLY) a typem C (fork z łatkami) to **czy fork niesie własny kod**. Dopóki nikt tego
# nie mierzył, granica rozmywała się po cichu: `U-164` pokazał, że `eos-pkgutils` figurował
# jako lustro, a niósł kliencką weryfikację podpisu manifestu (`R-703`) — której przez to
# nie było w obrazie. `U-169` zmierzył wszystkie 22 forki i znalazł kolejne cztery.
#
# KRYTERIUM. Commity ponad upstreamem dzielimy po **plikach**, nie po treści opisu:
# README / LICENSE / konfiguracja CI to obudowa forka (nadal lustro), cokolwiek innego
# to kod E-OS (fork typu C). Typ zadeklarowany jest w `repos.toml` w polu `type`.
#
#   scripts/eos-mirror-drift.sh              # sprawdź wszystkie, wyjdź != 0 przy rozjeździe
#   scripts/eos-mirror-drift.sh eos-netdb    # jedno repo
#   scripts/eos-mirror-drift.sh --list       # wypisz każdy własny commit i plik
#
# Wymaga sieci, więc miejsce dla niego to zadanie **scheduled**, nie każdy push (§13).
set -uo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$0")")" || exit 1
LIST=0; ONLY=""
for a in "$@"; do case "$a" in --list) LIST=1 ;; *) ONLY="$a" ;; esac; done
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

# Pliki, które fork może mieć własne, nie przestając być lustrem.
is_boilerplate() {
  case "$1" in
    README*|*/README*|LICENSE*|*/LICENSE*|COPYING*|.gitlab-ci.yml|.github/*|.gitignore) return 0 ;;
    *) return 1 ;;
  esac
}

entries=$(python3 - repos.toml <<'PY'
import re, sys
for b in open(sys.argv[1], encoding="utf-8").read().split("[[repo]]")[1:]:
    g = lambda k: (re.search(rf'^\s*{k}\s*=\s*"([^"]+)"', b, re.M) or [None, ""])[1]
    if g("upstream"):
        print("\t".join([g("name"), g("github"), g("upstream"),
                         g("pinned_branch") or "master", g("type") or "?"]))
PY
)

printf '%-18s %-5s %-9s %-9s %s\n' "REPO" "TYP" "WŁASNYCH" "WERDYKT" "OSTATNI WŁASNY COMMIT"
fail=0; checked=0; unknown=0
while IFS=$'\t' read -r name gh up branch declared; do
  [ -n "$ONLY" ] && [ "$name" != "$ONLY" ] && continue
  checked=$((checked + 1))
  d="$WORK/$name"
  if ! git clone --quiet --filter=blob:none --no-checkout "$gh" "$d" 2>/dev/null; then
    printf '%-18s %-5s %-9s %-9s %s\n' "$name" "$declared" "?" "?" "nie udało się sklonować forka"
    unknown=$((unknown + 1)); continue
  fi
  git -C "$d" remote add upstream "$up" 2>/dev/null
  if ! git -C "$d" fetch --quiet --filter=blob:none upstream 2>/dev/null; then
    printf '%-18s %-5s %-9s %-9s %s\n' "$name" "$declared" "?" "?" "nie udało się pobrać upstreamu"
    unknown=$((unknown + 1)); continue
  fi

  own=$(git -C "$d" rev-list --count "origin/$branch" --not --remotes=upstream 2>/dev/null || echo 0)
  last=$(git -C "$d" log -1 --format='%s' "origin/$branch" --not --remotes=upstream 2>/dev/null | cut -c1-40)

  # Pliki dotknięte WYŁĄCZNIE przez nasze commity — liczone od punktu rozejścia.
  mb=$(git -C "$d" merge-base "origin/$branch" upstream/HEAD 2>/dev/null \
       || git -C "$d" merge-base "origin/$branch" "upstream/$branch" 2>/dev/null)
  code=0; code_files=""
  if [ -n "$mb" ]; then
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      if ! is_boilerplate "$f"; then code=$((code + 1)); code_files="$code_files $f"; fi
    done <<< "$(git -C "$d" diff --name-only "$mb" "origin/$branch" 2>/dev/null)"
  fi

  # Zmierzony typ: cokolwiek poza obudową ⇒ fork typu C.
  measured="B"; [ "$code" -gt 0 ] && measured="C"
  if [ "$declared" = "$measured" ]; then verdict="OK"
  elif [ "$declared" = "?" ]; then verdict="BRAK"; fail=1
  else verdict="≠ $measured"; fail=1; fi

  printf '%-18s %-5s %-9s %-9s %s\n' "$name" "$declared" "$own" "$verdict" "${last:-—}"
  if [ "$LIST" = "1" ] && [ "${own:-0}" != "0" ]; then
    git -C "$d" log --format='      · %s' "origin/$branch" --not --remotes=upstream 2>/dev/null | cut -c1-92
    [ "$code" -gt 0 ] && printf '      → własny kod (%d plików):%s\n' "$code" "$(echo "$code_files" | cut -c1-70)"
  fi
  if [ "$verdict" != "OK" ] && [ "$code" -gt 0 ]; then
    printf '      → niesie własny kod, m.in.:%s\n' "$(echo "$code_files" | cut -c1-70)"
  fi
done <<< "$entries"

echo "---- sprawdzonych=$checked, nierozstrzygniętych=$unknown ----"
# Repozytoria nierozstrzygnięte (nieudany clone albo fetch, wiersze 50-58) były zliczane
# i wypisywane, ale NIE wpływały na kod wyjścia — a skrypt kończył się zdaniem "Każdy fork ma
# typ zgodny z tym, co faktycznie niesie". To zdanie jest nieprawdziwe, gdy części forków
# w ogóle nie zmierzono, a trwała awaria (repo skasowane, przemianowane, zepsute
# uwierzytelnienie) wyglądała dokładnie tak samo jak chwilowy problem z siecią: zielono.
#
# Konwencja projektu jest tu ustalona: `cannot()` w ci-integrity.sh (U-177) wypisuje
# "FAIL (instrument)" i ustawia fail=1. "Nie dało się zmierzyć" jest czerwone, tylko nazwane
# inaczej niż "zmierzono i się nie zgadza".
if [ "$unknown" -ne 0 ]; then
  echo "FAIL (instrument): $unknown repozytorium/-ów nierozstrzygniętych — ich typu NIE zmierzono."
  echo "  Nie mogę twierdzić, że każdy fork jest zgodny, skoro części nie sprawdziłem."
  echo "  Bywa przejściowe (sieć); jeśli wraca, sprawdź czy fork istnieje i czy da się go sklonować."
  fail=1
fi
if [ "$fail" -ne 0 ]; then
  cat <<'MSG'
Zadeklarowany typ nie zgadza sie z pomiarem. To nie jest kosmetyka: repo opisane jako
lustro (typ B) nikt nie audytuje ani nie testuje jak kodu E-OS, wiec wlasny kod chowa sie
w nim niezauwazony - dokladnie tak zginela kliencka weryfikacja podpisu (U-164).
Popraw pole `type` w repos.toml ALBO usun kod z forka. Nie popraw samego opisu w CLAUDE.md.
MSG
  exit 1
fi
echo "Kazdy fork ma typ zgodny z tym, co faktycznie niesie."
