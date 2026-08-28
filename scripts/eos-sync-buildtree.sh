#!/usr/bin/env bash
# eos-sync-buildtree.sh — make the container's build tree equal to THIS repo.
#
# WHY THIS EXISTS. `make` does not build from this repo. It builds from /work/redox inside
# the `eos-work` volume, which is a separate clone of the GitHub mirror. Nothing kept the
# two in step, so they drifted -- measured when this script was written: the build tree sat
# at 6e7f6432 (U-076), **165 commits behind**, with 109 modified and 89 untracked files
# accumulated by hand-copying whatever a given task happened to need.
#
# That is not a tidiness problem, it is a correctness one. Every "the image ships X" claim
# is a claim about an artifact built from THAT tree, and there was no way to know whether it
# matched the repo the claim was written in. The key-pinning work is the concrete example:
# scripts/eos-pin-repo-key.sh edited config/aarch64/eos.toml here, the build used the copy
# over there, and /etc/pkg/ came out with no key in it and no error anywhere.
#
#   scripts/eos-sync-buildtree.sh            # report the drift
#   scripts/eos-sync-buildtree.sh --apply    # copy this repo's tracked files across
#
# `.config` is deliberately NOT copied: the host needs PODMAN_BUILD=1 and the container
# needs 0, so one file cannot serve both (mk/config.mk:49). Build outputs, fetched recipe
# sources and the prefix are left alone -- they are the 37 GB of cache the whole workflow
# depends on.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
APPLY=""; [ "${1:-}" = "--apply" ] && APPLY=1
IMAGE="${EOS_BUILD_IMAGE:-localhost/redox-base:latest}"

# Tracked files only: untracked host files are scratch, and copying them would push the
# drift the other way.
files=$(git ls-files 2>/dev/null | grep -vE '^\.config$')
count=$(printf '%s\n' "$files" | grep -c . || true)
echo "repo: $count śledzonych plików do porównania"

STAGE="$(mktemp -d)"; trap 'rm -rf "$STAGE"' EXIT
printf '%s\n' "$files" | while IFS= read -r f; do
  [ -n "$f" ] && [ -f "$f" ] || continue
  mkdir -p "$STAGE/$(dirname "$f")"
  cp -p "$f" "$STAGE/$f"
done

podman run --rm -v eos-work:/work -v "$STAGE:/stage:ro" \
  ${APPLY:+--env APPLY=1} "$IMAGE" bash -lc '
cd /work/redox || { echo "brak /work/redox w wolumenie"; exit 1; }
diff_n=0; miss_n=0
while IFS= read -r f; do
  if [ ! -f "$f" ]; then miss_n=$((miss_n+1)); echo "  BRAK:  $f"; continue; fi
  cmp -s "/stage/$f" "$f" || { diff_n=$((diff_n+1)); echo "  RÓŻNI: $f"; }
done < <(cd /stage && find . -type f | sed "s|^\./||")
echo "drzewo budowania: $diff_n różnych, $miss_n brakujących"
if [ -n "${APPLY:-}" ]; then
  (cd /stage && find . -type f -print0 | while IFS= read -r -d "" f; do
     f="${f#./}"; mkdir -p "$(dirname "/work/redox/$f")"; cp -p "/stage/$f" "/work/redox/$f"
   done)
  echo "zastosowano: drzewo budowania odpowiada repozytorium (poza .config i artefaktami)"
else
  [ "$diff_n" -gt 0 ] || [ "$miss_n" -gt 0 ] && echo "uruchom z --apply, żeby wyrównać"
fi
exit 0'
