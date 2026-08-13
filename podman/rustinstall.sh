#!/usr/bin/env bash
# This must be run outside podman build so the build/podman volume mount to /root contains all home folder changes
#
# Supply-chain hardening (U-118): every binary this script fetches is pinned by
# SHA256 below. These tools participate in compiling the whole OS image, so TLS
# alone is not enough provenance — a swapped release asset or a MITM behind a
# TLS terminator must fail loudly, not install silently. rustup itself is
# installed from a *versioned* rustup-init (immutable archive path), replacing
# the classic `curl https://sh.rustup.rs | sh`.
#
# To bump a tool: change its version, download the new artifact, refresh the
# hash (`curl -sfL <url> | sha256sum`), and record the bump in CHANGELOG.md.
# rustup-init hashes can be cross-checked against the published sidecar:
#   https://static.rust-lang.org/rustup/archive/<ver>/<triple>/rustup-init.sha256
set -ex

ARCH="$(uname -m)"   # x86_64 | aarch64 — the two container hosts E-OS supports
RUSTUP_VER=1.29.0

case "${ARCH}" in
x86_64)
    RUSTUP_SHA=4acc9acc76d5079515b46346a485974457b5a79893cfb01112423c89aeb5aa10
    SCCACHE_SHA=782d2b5dd7ae0a55ebe368ab258114d0928d019ac2d949ab85d5d02f3926709e
    JUST_SHA=27e011cd6328fadd632e59233d2cf5f18460b8a8c4269acd324c1a8669f34db0
    CBINDGEN_SHA=2cc8a248e12632a0249f17d7370ad4a38c98292bdf7bb1357f737f8b6e8cc435
    CBINDGEN_NAME="ubuntu22.04"
    ;;
aarch64)
    RUSTUP_SHA=9732d6c5e2a098d3521fca8145d826ae0aaa067ef2385ead08e6feac88fa5792
    SCCACHE_SHA=3a6a3712b49da3d263bf2d30d702de4302793016019e800bfb81c0c69401d8f8
    JUST_SHA=3beb4967ce05883cf09ac12d6d128166eb4c6d0b03eff74b61018a6880655d7d
    CBINDGEN_SHA=a9f4b5322f9ea7b8637984e385ec1c73c8e4e42faf2818da85f87ab77a356ddc
    CBINDGEN_NAME="ubuntu22.04-aarch64"
    ;;
*)
    echo "rustinstall: unsupported container arch '${ARCH}'" >&2
    exit 1
    ;;
esac

# Download to a temp file, verify the pin, then hand the path to the caller.
# Verify-then-use: nothing untrusted is ever piped straight into tar or sh.
fetch() { # <url> <sha256> -> echoes verified temp path
    local url="$1" sha="$2" tmp
    tmp="$(mktemp)"
    wget -qO "${tmp}" --show-progress "${url}" >&2
    echo "${sha}  ${tmp}" | sha256sum -c - >&2 || {
        echo "rustinstall: SHA256 MISMATCH for ${url}" >&2
        echo "  expected ${sha}" >&2
        echo "  Refusing to install — either the release was re-published (verify + re-pin)" >&2
        echo "  or the download was tampered with." >&2
        rm -f "${tmp}"
        exit 1
    }
    echo "${tmp}"
}

echo "Installing rust (rustup-init ${RUSTUP_VER}, pinned)..."
T="$(fetch "https://static.rust-lang.org/rustup/archive/${RUSTUP_VER}/${ARCH}-unknown-linux-gnu/rustup-init" "${RUSTUP_SHA}")"
# rustup-init is a multicall binary that dispatches on argv[0] — it must run
# under its real name, not the random mktemp one.
RUSTUP_DIR="$(mktemp -d)"
mv "${T}" "${RUSTUP_DIR}/rustup-init"
chmod +x "${RUSTUP_DIR}/rustup-init"
"${RUSTUP_DIR}/rustup-init" -y --default-toolchain stable --profile minimal
rm -rf "${RUSTUP_DIR}"

echo "Downloading sccache..."
T="$(fetch "https://github.com/mozilla/sccache/releases/download/v0.15.0/sccache-v0.15.0-${ARCH}-unknown-linux-musl.tar.gz" "${SCCACHE_SHA}")"
tar -xzf "${T}" -C ~/.cargo/bin --strip-components=1 --wildcards '*/sccache'
rm -f "${T}"

echo "Downloading just..."
T="$(fetch "https://github.com/casey/just/releases/download/1.50.0/just-1.50.0-${ARCH}-unknown-linux-musl.tar.gz" "${JUST_SHA}")"
tar -xzf "${T}" -C ~/.cargo/bin --wildcards 'just'
rm -f "${T}"

echo "Downloading cbindgen..."
T="$(fetch "https://github.com/mozilla/cbindgen/releases/download/0.29.0/cbindgen-${CBINDGEN_NAME}" "${CBINDGEN_SHA}")"
install -m 0755 "${T}" ~/.cargo/bin/cbindgen
rm -f "${T}"
