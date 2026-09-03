#!/usr/bin/env bash
# eos-check-assets.sh -- ci-integrity check 16: tracked images and binary assets stay tidy.
#
# Refuses three things, each measured once in this tree before the gate existed:
#   1. two tracked assets with the SAME content under different paths (assets/ vs docs/img/
#      carried byte-identical screenshots; every doc edit had to remember both copies);
#   2. a tracked asset over the size limit (CLAUDE.md §7: nothing > 5 MB without asking);
#   3. an orphan: an image no tracked document, page, recipe or workflow references by name.
#      An orphan is either dead weight or a screenshot whose caption was deleted -- both need
#      a human, neither should sit silently in git.
#
# Scope: `git ls-files` under assets/ docs/img/ and any tracked *.png *.jpg *.jpeg *.gif *.svg
# *.webp *.ico elsewhere (recipes' own assets are upstream's and are skipped, ADR-0003).
# Exit 0 clean, 1 on any defect, 2 if the check cannot run (no git, no md5 tool).
# Negative test: run with EOS_ASSETS_SELFTEST=1 -- creates two identical files and an orphan in a
# scratch git repo and expects exit 1.  Host is macOS: BSD md5 -q; falls back to md5sum.
#
# Usage: bash scripts/eos-check-assets.sh [--max-mb N] [--warn-orphans]
set -uo pipefail

MAX_MB=5
WARN_ORPHANS=0
for a in "$@"; do
  case "$a" in
    --max-mb=*) MAX_MB="${a#*=}" ;;
    --warn-orphans) WARN_ORPHANS=1 ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown argument: $a" >&2; exit 2 ;;
  esac
done
case "$MAX_MB" in ''|*[!0-9]*) echo "CANNOT RUN: --max-mb must be an integer, got '$MAX_MB'" >&2; exit 2 ;; esac

if command -v md5 >/dev/null 2>&1; then hash_of() { md5 -q "$1"; }
elif command -v md5sum >/dev/null 2>&1; then hash_of() { md5sum "$1" | cut -d' ' -f1; }
else echo "CANNOT RUN: neither md5 nor md5sum on PATH" >&2; exit 2; fi
size_of() { stat -f %z "$1" 2>/dev/null || stat -c %s "$1"; }

run_check() {  # runs inside a git work tree; prints findings; returns 0/1/2
  git rev-parse --show-toplevel >/dev/null 2>&1 || { echo "CANNOT RUN: not a git work tree" >&2; return 2; }
  local fail=0 n=0 dups=0 big=0 orphans=0
  local list; list="$(mktemp)"; local hashes; hashes="$(mktemp)"
  git ls-files -z -- 'assets/*' 'docs/img/*' '*.png' '*.jpg' '*.jpeg' '*.gif' '*.svg' '*.webp' '*.ico' \
    | tr '\0' '\n' | grep -v '^recipes/' | grep -vE '(^|/)\._' | sort -u > "$list"
  n=$(wc -l < "$list" | tr -d ' ')
  if [ "$n" -eq 0 ]; then echo "assets-check: no tracked assets found -- nothing measured"; rm -f "$list" "$hashes"; return 2; fi

  # 1. duplicates by content
  while IFS= read -r f; do [ -f "$f" ] && printf '%s  %s\n' "$(hash_of "$f")" "$f"; done < "$list" > "$hashes"
  while IFS= read -r h; do
    [ -n "$h" ] || continue
    echo "FAIL: identical content under several paths:"; grep "^$h " "$hashes" | sed 's/^[0-9a-f]*  /      /'
    dups=$((dups + 1)); fail=1
  done < <(cut -d' ' -f1 "$hashes" | sort | uniq -d)

  # 2. size limit
  local limit=$((MAX_MB * 1024 * 1024))
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    local s; s=$(size_of "$f")
    if [ "$s" -gt "$limit" ]; then echo "FAIL: $f is $s bytes (> ${MAX_MB} MB, CLAUDE.md §7)"; big=$((big + 1)); fail=1; fi
  done < "$list"

  # 3. orphans -- referenced by basename anywhere in tracked text files outside the asset dirs
  local refs; refs="$(mktemp)"
  git ls-files -z -- '*.md' '*.html' '*.toml' '*.rs' '*.yml' '*.yaml' '*.json' '*.txt' '*.sh' '*.py' \
      'Makefile' '*.mk' '*.css' '*.slint' '*.desktop' '*.cfg' '*.conf' '*.ipxe' \
    | tr '\0' '\n' | grep -vE '^(assets|docs/img)/' | sort -u > "$refs"
  while IFS= read -r f; do
    local b; b=$(basename "$f")
    if ! xargs -0 grep -lqF -- "$b" < <(tr '\n' '\0' < "$refs") 2>/dev/null; then
      if [ "$WARN_ORPHANS" -eq 1 ]; then echo "warn: $f is referenced by no tracked document"; else echo "FAIL: $f is referenced by no tracked document"; fail=1; fi
      orphans=$((orphans + 1))
    fi
  done < "$list"
  rm -f "$list" "$hashes" "$refs"
  echo "assets-check: $n tracked assets -- $dups duplicate groups, $big over ${MAX_MB} MB, $orphans orphans$( [ "$WARN_ORPHANS" -eq 1 ] && printf ' (warn only)')"
  return "$fail"
}

if [ "${EOS_ASSETS_SELFTEST:-0}" = "1" ]; then
  T="$(mktemp -d)"; ( cd "$T" && git init -q . && mkdir -p assets docs && printf 'x' > assets/a.png && printf 'x' > assets/b.png \
      && printf 'y' > assets/orphan.png && printf 'see a.png and b.png\n' > docs/x.md && git add -A && git -c user.email=t@t -c user.name=t commit -qm t )
  ( cd "$T" && run_check ); rc=$?
  rm -rf "$T"
  if [ "$rc" -eq 1 ]; then echo "selftest ok: duplicate + orphan detected, exit 1"; exit 0; fi
  echo "SELFTEST FAILED: expected exit 1, got $rc"; exit 1
fi

cd "$(dirname "$0")/.." || exit 2
run_check
