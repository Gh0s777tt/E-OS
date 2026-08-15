#!/usr/bin/env bash
# Publish an E-OS binary package repository to its GitHub Pages host (R-1003).
#
#   scripts/publish-repo-pages.sh [TARGET]      # default: x86_64-unknown-redox
#
# Pushes repo/<TARGET> (the signed .pkgar files + repo.toml + the public signing
# key) to the eos-pkg-<arch> repository as a single orphan commit on `main`
# (history is discarded on every publish, so the hosting repo never grows).
# GitHub Pages then serves it at the stable repo URL:
#
#   https://gh0s777tt.github.io/eos-pkg-<arch>/pkg/<TARGET>/<pkg>.pkgar
#   https://gh0s777tt.github.io/eos-pkg-<arch>/pkg/id_ed25519.pub.toml
#
# Auth: uses your ambient git credentials (gh auth, credential helper or SSH).
# Override the push remote with EOS_PKG_REMOTE. See docs/packages.md.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${1:-x86_64-unknown-redox}"
ARCH="${TARGET%%-*}"
REPO="repo/${TARGET}"
PUB="build/id_ed25519.pub.toml"
REMOTE="${EOS_PKG_REMOTE:-https://github.com/Gh0s777tt/eos-pkg-${ARCH}.git}"

[ -d "$REPO" ] || { echo "error: $REPO not found — run a build first"; exit 1; }
[ -f "$REPO/repo.toml" ] || { echo "error: $REPO/repo.toml missing"; exit 1; }

# GitHub refuses blobs >100 MB (and Pages won't serve them) — check up front.
oversized=$(find "$REPO" -name '*.pkgar' -size +99M | sort)
if [ -n "$oversized" ]; then
    echo "error: package(s) exceed GitHub's 100 MB blob limit:"
    echo "$oversized"
    echo "host these on a different backend or split the recipe."
    exit 1
fi

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

mkdir -p "$stage/pkg/$TARGET"
cp "$REPO"/repo.toml "$REPO"/*.pkgar "$stage/pkg/$TARGET/"
if [ -f "$PUB" ]; then
    cp "$PUB" "$stage/pkg/"
else
    echo "warning: $PUB missing (packages unverifiable by clients)"
fi

# R-703: sign the repo.toml MANIFEST (which lists every package's blake3 hash)
# with the hybrid ed25519+ML-DSA-65 key, so a host/MITM cannot swap the index
# to freeze, roll back or substitute packages. The SECRET key is user-held and
# passed via $EOS_REPO_SIGN_KEY — NEVER in the repo. Clients *will* verify
# repo.toml.sig against an in-image-pinned public key — but that half is NOT
# BUILT: keys/eos-repo-sign.pub.toml has never been committed (R-702) and pkg-lib
# has no verify_manifest() (R-703). Signing here is necessary but not yet
# sufficient — the signature authenticates nothing on a device until both land.
sign_manifest() {
    local dir="$1"
    local bin="${EOS_REPO_SIGN_BIN:-$ROOT/tools/eos-repo-sign/target/release/eos-repo-sign}"
    [ -x "$bin" ] || bin="$(command -v eos-repo-sign 2>/dev/null || true)"
    local pub="${EOS_REPO_SIGN_PUB:-$ROOT/keys/eos-repo-sign.pub.toml}"
    if [ -z "${EOS_REPO_SIGN_KEY:-}" ]; then
        # U-120: publishing an unsigned index to the public internet is no longer
        # the default-open path — a MITM/host can swap an unsigned index to
        # freeze, roll back or substitute packages (R-703). Dev flows that
        # genuinely want it must say so explicitly.
        if [ "${EOS_ALLOW_UNSIGNED:-0}" = "1" ]; then
            echo "WARNING: EOS_ALLOW_UNSIGNED=1 — repo.toml published UNSIGNED (no PQ manifest signature; see docs/security.md and R-703)." >&2
            return 0
        fi
        echo "error: EOS_REPO_SIGN_KEY unset — refusing to publish an UNSIGNED repo.toml to public hosting." >&2
        echo "  Sign:   EOS_REPO_SIGN_KEY=/path/off-repo/secret.toml $0 ..." >&2
        echo "  Or opt in explicitly (dev only): EOS_ALLOW_UNSIGNED=1 $0 ..." >&2
        exit 1
    fi
    [ -n "$bin" ] && [ -x "$bin" ] || { echo "error: eos-repo-sign not built — run: (cd tools/eos-repo-sign && cargo build --release)"; exit 1; }
    "$bin" sign "$EOS_REPO_SIGN_KEY" "$dir/repo.toml"
    if [ -f "$pub" ]; then
        cp "$pub" "$dir/../eos-repo-sign.pub.toml"   # convenience mirror; clients still pin the in-image key
    else
        echo "WARNING: $pub missing — commit your eos-repo-sign public key so clients have a pinned trust anchor (keygen: eos-repo-sign keygen secret.toml keys/eos-repo-sign.pub.toml)." >&2
    fi
    echo "signed repo.toml (hybrid ed25519 + ML-DSA-65) -> repo.toml.sig"
}
sign_manifest "$stage/pkg/$TARGET"

# Pages plumbing: no Jekyll processing; a minimal index for humans.
touch "$stage/.nojekyll"
n=$(ls "$REPO"/*.pkgar | wc -l | tr -d ' ')
build_id=$(sed -n 's/^build_id *= *//p' "$REPO/repo.toml" | head -1)
cat > "$stage/index.html" <<HTML
<!doctype html><meta charset="utf-8"><title>E-OS package repo (${TARGET})</title>
<body style="background:#000;color:#eee;font-family:monospace">
<h1 style="color:#E50914">E-OS package repository — ${TARGET}</h1>
<p>${n} signed .pkgar packages · build_id ${build_id:-unknown}</p>
<p>Index: <a href="pkg/${TARGET}/repo.toml">pkg/${TARGET}/repo.toml</a> ·
Key: <a href="pkg/id_ed25519.pub.toml">pkg/id_ed25519.pub.toml</a> ·
<a href="https://github.com/Gh0s777tt/E-OS">github.com/Gh0s777tt/E-OS</a></p>
HTML

git -C "$stage" init -q -b main
git -C "$stage" add -A
git -C "$stage" -c user.name="E-OS repo publisher" \
                -c user.email="dzierzawskii98.dam@gmail.com" \
    commit -q -m "pkg repo ${TARGET}: ${n} packages, build_id ${build_id:-unknown}"
git -C "$stage" push --force "$REMOTE" main:main

echo "published: ${n} packages ($(du -sh "$REPO" | cut -f1)) -> ${REMOTE%.git}"
echo "stable URL: https://gh0s777tt.github.io/eos-pkg-${ARCH}/pkg/${TARGET}/"
