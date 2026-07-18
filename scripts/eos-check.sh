#!/usr/bin/env bash
# eos-check.sh — fast per-crate compile check against the Redox target sysroot,
# inside the build container. This is verification gate 1 (see CLAUDE.md): run it
# before a 15-minute `make … all` image rebuild to catch errors in seconds.
#
# Usage:
#   scripts/eos-check.sh <crate-dir-in-container> [-p <package>] [--arch aarch64|x86_64]
#
# Examples:
#   scripts/eos-check.sh /work/redox/recipes/core/base/source -p virtio-core
#   scripts/eos-check.sh /tmp/eos-notes                        # whole crate, aarch64
#
# It runs `cargo check` with the container's Rust toolchain + the cross linker.
# The container name defaults to $EOS_CONTAINER (else "eosbuild").
set -euo pipefail

CONTAINER="${EOS_CONTAINER:-eosbuild}"
ARCH="aarch64"
CRATE=""
PKG_ARGS=""

while [ $# -gt 0 ]; do
  case "$1" in
    --arch) ARCH="$2"; shift 2 ;;
    -p) PKG_ARGS="$PKG_ARGS -p $2"; shift 2 ;;
    *) CRATE="$1"; shift ;;
  esac
done
[ -n "$CRATE" ] || { echo "usage: eos-check.sh <crate-dir-in-container> [-p pkg] [--arch aarch64|x86_64]" >&2; exit 2; }

TARGET="${ARCH}-unknown-redox"
echo "eos-check: cargo check ${PKG_ARGS:-（whole crate）} in $CRATE for $TARGET"

# The prefix carries the target Rust toolchain (rustc/cargo) + the cross gcc used
# as the linker; bundled-C deps (e.g. SQLite) need the plain calls on relibc.
podman exec "$CONTAINER" bash -lc "
  set -e
  export PATH=/work/redox/prefix/${TARGET}/rust-install/bin:/work/redox/prefix/${TARGET}/gcc-install/bin:/root/.cargo/bin:\$PATH
  export CARGO_TARGET_${ARCH^^}_UNKNOWN_REDOX_LINKER=${TARGET}-gcc
  export CFLAGS_${ARCH}_unknown_redox=\"\${CFLAGS_${ARCH}_unknown_redox:-} -DSQLITE_DISABLE_LFS\"
  cd '${CRATE}'
  cargo check --target ${TARGET} --release ${PKG_ARGS}
"
echo "eos-check: OK"
