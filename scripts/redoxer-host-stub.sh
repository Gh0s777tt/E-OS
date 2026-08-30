#!/usr/bin/env sh
# redoxer-host-stub.sh — unblock from-source builds of recipes that carry a
# `host:` dev-dependency (e.g. netsurf → host:gperf).
#
# WHY THIS EXISTS
# ---------------
# The cookbook builds a host recipe by running its configure/make under
# `cookbook_redoxer env`, which calls redoxer's toolchain() *even for the host
# target*. For a host build redoxer needs no relibc toolchain at all — its
# generate_gnu_targets() resolves CC=gcc / CXX=g++ straight from the system
# compilers. But toolchain() unconditionally tries to DOWNLOAD a relibc
# "toolchain" for the host triple from
#     https://static.redox-os.org/toolchain/<host>/<host>/relibc-install.tar.gz
# and redox only publishes *cross* toolchains (host → redox), never host → host.
# So the fetch 404s (curl exit 22) and every host-dep recipe dies with
#     "redoxer env: unable to init toolchain: exit status: 22".
# That is the exact wall that made a from-source (PIE) netsurf unbuildable.
#
# THE FIX
# -------
# redoxer skips the whole download when ~/.redoxer/<target>/toolchain already
# exists (toolchain_inner: `if !toolchain_dir.is_dir() { …download… }`). So we
# pre-create that directory as a stub. It is per-target and therefore does NOT
# touch the genuine cross toolchain at ~/.redoxer/aarch64-unknown-redox/toolchain
# (that one is a different directory and still downloads/builds normally).
# bin/ carries the host cargo+rustc so a future *cargo*-based host recipe also
# works; a pure-C tool like gperf ignores it and just uses system gcc/g++.
#
# Idempotent. Run once per build container before cooking host-dep recipes
# (CI wires this into the image-build job; see docs/architecture/netsurf-pie.md).
set -eu

host_triple="$(rustc -vV | sed -n 's/^host: //p')"
: "${host_triple:?redoxer-host-stub: could not determine host triple from rustc}"

stub="${HOME}/.redoxer/${host_triple}/toolchain"
if [ -d "$stub" ]; then
    echo "redoxer-host-stub: already present ($stub)"
    exit 0
fi

# a half-finished download leaves this behind; clear it so nothing is confused
rm -rf "${HOME}/.redoxer/${host_triple}/toolchain.partial"
mkdir -p "$stub/bin"
for tool in cargo rustc; do
    p="$(command -v "$tool" 2>/dev/null || true)"
    [ -n "$p" ] && ln -sf "$p" "$stub/bin/$tool"
done
echo "redoxer-host-stub: created $stub (host triple $host_triple)"
