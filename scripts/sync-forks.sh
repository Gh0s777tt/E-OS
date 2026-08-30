#!/usr/bin/env bash
# Sync the E-OS vendored Redox mirrors with upstream redox-os.
#
#   scripts/sync-forks.sh [--push]
#
# For each pure mirror (the components E-OS vendors but does not patch) this
# fetches the matching redox-os upstream and, with --push, fast-forwards our
# Gh0s777tt/eos-<name> mirror to it. Run it periodically to pull upstream fixes;
# then bump the `rev = ` pins in the recipes to the new heads and rebuild.
#
# Auth for --push: ambient git credentials (gh auth / credential helper / SSH),
# or set EOS_GH_TOKEN.
#
# NOTE: the six *modified* forks (kernel, base, relibc, userutils, bootloader,
# orbdata) are NOT pure mirrors — they carry E-OS commits. Updating those means
# rebasing our commits onto new upstream (see docs/reference/known-issues.md, U-033), not a
# fast-forward, so they are intentionally excluded here.
set -u

# pure mirrors: eos-<name>  <->  gitlab.redox-os.org/redox-os/<name>
MIRRORS="redoxfs orbital orbutils orbterm orbclient liborbital ion coreutils \
extrautils netutils netdb pkgutils pkgar installer redoxer redox-fatfs"

PUSH=0; [ "${1:-}" = "--push" ] && PUSH=1
TOK="${EOS_GH_TOKEN:-}"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
cd "$WORK" || exit 1

printf '%-14s %-12s %-12s %s\n' COMPONENT OURS UPSTREAM STATUS
for name in $MIRRORS; do
  up="https://gitlab.redox-os.org/redox-os/${name}.git"
  ours="https://github.com/Gh0s777tt/eos-${name}.git"
  [ -n "$TOK" ] && ourspush="https://x-access-token:${TOK}@github.com/Gh0s777tt/eos-${name}.git" || ourspush="$ours"

  git clone -q --bare "$ours" m.git 2>/dev/null || { printf '%-14s %s\n' "$name" "CLONE_FAIL"; continue; }
  o=$(git -C m.git rev-parse HEAD 2>/dev/null)
  git -C m.git remote add up "$up" && git -C m.git fetch -q up 2>/dev/null
  u=$(git -C m.git rev-parse up/master 2>/dev/null || git -C m.git rev-parse up/main 2>/dev/null)

  if [ "$o" = "$u" ]; then st="up-to-date"
  elif git -C m.git merge-base --is-ancestor "$o" "$u" 2>/dev/null; then
    st="behind"
    if [ "$PUSH" = 1 ]; then
      git -C m.git push -q "$ourspush" "$u:refs/heads/master" 2>/dev/null && st="pushed" || st="push_fail"
    fi
  else st="diverged(manual)"; fi

  printf '%-14s %-12.12s %-12.12s %s\n' "$name" "$o" "$u" "$st"
  rm -rf m.git
done
