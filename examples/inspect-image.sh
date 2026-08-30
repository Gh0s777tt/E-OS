#!/usr/bin/env bash
# Reads a built E-OS image and prints what it actually contains, rather than what
# the documentation claims. Mounts a COPY: redoxfs has no read-only mode and
# mounting modifies the image (CLAUDE.md 8, trap P-6).
set -euo pipefail
IMG="${1:?usage: examples/inspect-image.sh <path-to-harddrive.img>}"
[ -f "$IMG" ] || { echo "no such image: $IMG"; exit 1; }

podman run --rm --cap-add SYS_ADMIN --device /dev/fuse \
  -v eos-work:/work -v "$(cd "$(dirname "$IMG")" && pwd)":/img:ro \
  localhost/redox-base:latest bash -lc '
    cp "/img/'"$(basename "$IMG")"'" /tmp/copy.img
    m=/tmp/m; mkdir -p $m
    /work/redox/build/fstools/bin/redoxfs /tmp/copy.img $m >/dev/null 2>&1 &
    sleep 10
    echo "== installed packages =="
    grep -c "^\[installed\." $m/etc/pkg/packages.toml
    echo "== binaries in /usr/bin =="
    ls $m/usr/bin | wc -l
    echo "== drivers =="
    ls $m/usr/lib/drivers | tr "\n" " "; echo
    echo "== pinned trust anchors =="
    ls $m/etc/pkg/
    echo "== package sources (commented out means no update channel) =="
    grep -h "^[^#]" $m/etc/pkg.d/* 2>/dev/null || echo "  (none active)"
    fusermount -u $m 2>/dev/null || true'
