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
# `printf ... | while ...` ran this loop in a SUBSHELL of a pipeline, in a script without
# `set -e`. Nothing here could report anything: a failed `cp` was ignored, and a tracked file
# missing from the working tree (deleted, or a dangling symlink) was filtered out by the
# `[ -f "$f" ]` test without a word. The container downstream then compared whatever had
# actually been staged against the build tree and reported agreement -- over a smaller set than
# the "$count śledzonych plików do porównania" line had just promised. Count what really got
# staged, and say so when it differs.
staged=0
missing=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  if [ ! -f "$f" ]; then
    missing="$missing
  $f"
    continue
  fi
  mkdir -p "$STAGE/$(dirname "$f")" || { echo "sync: nie mogę utworzyć katalogu dla $f"; exit 1; }
  cp -p "$f" "$STAGE/$f" || { echo "sync: nie mogę skopiować $f do stagingu"; exit 1; }
  staged=$((staged + 1))
done <<< "$files"

if [ -n "$missing" ]; then
  echo "sync: UWAGA — $((count - staged)) z $count śledzonych plików NIE trafiło do stagingu"
  echo "  (śledzone w gicie, ale nieobecne w katalogu roboczym — usunięte albo wiszące dowiązanie):"
  printf '%s\n' "$missing"
  echo "  Porównanie poniżej dotyczy $staged plików, nie $count."
fi
echo "sync: $staged plików w stagingu"

podman run --rm -v eos-work:/work -v "$STAGE:/stage:ro" \
  ${APPLY:+--env APPLY=1} --env IMAGE="$IMAGE" "$IMAGE" bash -lc '
cd /work/redox || { echo "brak /work/redox w wolumenie"; exit 1; }
diff_n=0; miss_n=0
while IFS= read -r f; do
  if [ ! -f "$f" ]; then miss_n=$((miss_n+1)); echo "  BRAK:  $f"; continue; fi
  cmp -s "/stage/$f" "$f" || { diff_n=$((diff_n+1)); echo "  RÓŻNI: $f"; }
done < <(cd /stage && find . -type f | sed "s|^\./||")
echo "drzewo budowania: $diff_n różnych, $miss_n brakujących"
if [ -n "${APPLY:-}" ]; then
  # Count failures instead of trusting cp: an unreported copy failure is worse than the drift
  # this script exists to remove, because it leaves the tree looking synced. The count crosses
  # out of the subshell through a file, since the pipeline body runs in its own process.
  fail_f=$(mktemp); : > "$fail_f"
  (cd /stage && find . -type f -print0 | while IFS= read -r -d "" f; do
     f="${f#./}"
     # Only touch what actually differs: copying all 3700 files every run is slow and, worse,
     # rewrites mtimes the build depends on.
     cmp -s "/stage/$f" "/work/redox/$f" 2>/dev/null && continue
     mkdir -p "$(dirname "/work/redox/$f")"
     if cp -p "/stage/$f" "/work/redox/$f" 2>&1; then
       # `cp -p` carries the host mtime across, which is routinely OLDER than the build outputs
       # already sitting in the tree -- cargo and make compare mtimes, so a file whose content
       # changed can be treated as up to date and never rebuilt. That is how a synced tree still
       # builds the previous source. Stamp it now instead.
       touch "/work/redox/$f"
     else
       echo "$f" >> "$fail_f"
     fi
   done)
  # wc, not grep -c: grep exits 1 on no match, and `|| echo 0` then appends a second zero.
  fail_n=$(wc -l < "$fail_f" | tr -d " ")
  if [ "$fail_n" -gt 0 ]; then
    echo "NIE zastosowano w całości: $fail_n plików nie udało się skopiować:"
    sed "s/^/  /" "$fail_f"
    # "Permission denied" on a file root cannot even open is not a permission bit -- it is an
    # SELinux MCS label. A container started with `:Z` relabels what it touches with its own
    # private categories, and every later container is then denied. Say so, because the bare
    # errno sends you looking at chmod and ownership, which are fine.
    while IFS= read -r f; do
      [ -e "/work/redox/$f" ] || continue
      lbl=$(ls -Z "/work/redox/$f" 2>/dev/null | awk "{print \$1}")
      case "$lbl" in
        *:c*) echo "  ^ $f ma prywatną etykietę SELinux ($lbl) — powstał w kontenerze z ':Z'."
              echo "    napraw: podman run --rm --security-opt label=disable -v eos-work:/work \\"
              echo "              $IMAGE rm -f /work/redox/$f" ;;
      esac
    done < "$fail_f"
    rm -f "$fail_f"
    exit 1
  fi
  rm -f "$fail_f"
  # Verify rather than announce: re-compare every staged file against the tree we just wrote.
  left=0
  while IFS= read -r f; do
    cmp -s "/stage/$f" "/work/redox/$f" || { left=$((left+1)); echo "  NADAL RÓŻNI: $f"; }
  done < <(cd /stage && find . -type f | sed "s|^\./||")
  if [ "$left" -gt 0 ]; then
    echo "NIE zastosowano w całości: $left plików nadal się różni"
    exit 1
  fi
  echo "zastosowano i zweryfikowano: drzewo budowania odpowiada repozytorium (poza .config i artefaktami)"
else
  [ "$diff_n" -gt 0 ] || [ "$miss_n" -gt 0 ] && echo "uruchom z --apply, żeby wyrównać"
fi
exit 0'
