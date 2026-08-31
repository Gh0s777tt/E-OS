#!/usr/bin/env bash
# make-release — assemble checksummed (optionally signed) E-OS release artifacts
# locally. GitHub Actions is disabled account-wide, so the tag->build->sign
# pipeline (R-301/R-303) cannot run; this reproduces it on any build host.
#
# It renames the built disk images to their release names, packages the install
# medium beside them (R-611b), regenerates SHA256SUMS over the ACTUAL artifacts,
# and signs the checksum file when a minisign secret key is supplied (the key is
# user-held, never in the repo).
#
# Usage:
#   [VERSION=0.2.0] [ARCHES="aarch64 x86_64"] \
#     [MINISIGN_SECRET_KEY=keys/eos-release.key] scripts/make-release.sh
#
# VERSION defaults to the build system's EOS_VERSION rather than to a literal here.
# It used to default to 0.1.0 while mk/config.mk stamped 0.2.0 into the medium's
# filename, so the script and the artifact could disagree with nothing to notice it.
# Exit 2 means the toolchain could not answer (broken instrument); exit 1 means an
# artifact is missing or inconsistent (real defect) -- the same split as ci-integrity.sh.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# A release is always the `eos` config. .config sets CONFIG_NAME with `?=`, so the
# environment wins over it -- and the disk-image path below is fixed at `eos`. Without
# pinning it here, `CONFIG_NAME=desktop scripts/make-release.sh` would take the medium
# from one config and the disk image from another, silently, in the same SHA256SUMS.
RELEASE_CONFIG=eos

ask_make() { # <target> [VAR=value...] -- exit 2 on a broken toolchain, never a silent empty string
  local out
  if ! out="$(make -s -C "$ROOT" "$@" 2>&1)"; then
    echo "!! could not ask make for '$1': $out" >&2
    echo "   That is a broken toolchain, not a missing artifact." >&2
    exit 2
  fi
  # The status was checked above, so trimming to the last line here cannot swallow it.
  printf '%s\n' "$out" | tail -n 1
}

VERSION="${VERSION:-$(ask_make print-eos-version)}"
if [ -z "$VERSION" ]; then
  echo "!! make print-eos-version returned nothing; cannot name the release." >&2
  exit 2
fi
ARCHES="${ARCHES:-aarch64 x86_64}"
OUT="$ROOT/release"
mkdir -p "$OUT"
: > "$OUT/SHA256SUMS"
for arch in $ARCHES; do
  img="$ROOT/build/$arch/$RELEASE_CONFIG/harddrive.img"
  if [ ! -f "$img" ]; then
    echo "!! missing $img — build it first: make CI=1 ARCH=$arch CONFIG_NAME=$RELEASE_CONFIG all" >&2
    exit 1
  fi
  name="eos-${VERSION}-${arch}.img"
  cp -f "$img" "$OUT/$name"
  ( cd "$OUT" && sha256sum "$name" >> SHA256SUMS )
  echo "packaged $name"

  # R-611b: the install medium ships BESIDE the disk image and its sha256 goes into the
  # SAME SHA256SUMS, so the signature covers it too. Until now the loop took only
  # harddrive.img, and a missing medium was silence rather than an error.
  #
  # The NAME comes from mk/config.mk through make, so the naming rule keeps one home. A
  # second copy of the pattern here would drift the first time the medium was renamed --
  # the last rename touched ~30 references and is why print-installer-medium exists.
  medium_rel="$(ask_make print-installer-medium ARCH="$arch" CONFIG_NAME="$RELEASE_CONFIG")"
  medium_name="$(basename "$medium_rel")"
  case "$medium_name" in
    eos-*-"$arch"-installer.img) ;;
    *)
      echo "!! make returned '$medium_name', which is not eos-<version>-$arch-installer.img." >&2
      echo "   INSTALLER_MEDIUM_NAME in mk/config.mk changed shape; teach this script the new one" >&2
      echo "   instead of letting it guess -- a wrong guess here would package the wrong file." >&2
      exit 2
      ;;
  esac
  medium_ver="${medium_name#eos-}"
  medium_ver="${medium_ver%-"$arch"-installer.img}"

  medium="$ROOT/$medium_rel"
  if [ ! -f "$medium" ]; then
    echo "!! missing $medium — build it first:" >&2
    echo "   make CI=1 ARCH=$arch CONFIG_NAME=$RELEASE_CONFIG $medium_rel" >&2
    exit 1
  fi
  if [ "$medium_ver" != "$VERSION" ]; then
    echo "!! version mismatch: releasing $VERSION, but the medium was built as $medium_ver" >&2
    echo "   ($medium_name). The version is baked into the filename AND into the medium's own" >&2
    echo "   boot configuration, so relabelling it here would ship an image that contradicts" >&2
    echo "   itself. Rebuild instead: EOS_VERSION=$VERSION make CI=1 ARCH=$arch ..." >&2
    exit 1
  fi
  cp -f "$medium" "$OUT/$medium_name"
  ( cd "$OUT" && sha256sum "$medium_name" >> SHA256SUMS )
  echo "packaged $medium_name"

  # SBOM (R-302): regenerate from THIS build's cooked package metadata and fold it
  # into the SAME SHA256SUMS that gets signed, so the bill of materials is covered
  # by the release signature. Skipped if the cookbook repo/ metadata isn't present.
  repo_dir="$ROOT/repo/${arch}-unknown-redox"
  if [ -d "$repo_dir" ] && command -v python3 >/dev/null 2>&1; then
    sbom="eos-${VERSION}-${arch}.cdx.json"
    ts="$(git -C "$ROOT" show -s --format=%cI HEAD 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
    commit="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
    python3 "$ROOT/scripts/gen-sbom.py" --repo-dir "$repo_dir" --target "${arch}-unknown-redox" \
      --eos-version "$VERSION" --eos-commit "$commit" --timestamp "$ts" --out "$OUT/$sbom"
    ( cd "$OUT" && sha256sum "$sbom" >> SHA256SUMS )
    echo "packaged $sbom"
  else
    echo "note: no repo/${arch}-unknown-redox metadata — SBOM skipped for $arch"
  fi
done
if [ -n "${MINISIGN_SECRET_KEY:-}" ]; then
  minisign -Sm "$OUT/SHA256SUMS" -s "$MINISIGN_SECRET_KEY"
  echo "signed -> release/SHA256SUMS.minisig"
elif [ "${EOS_ALLOW_UNSIGNED:-0}" = "1" ]; then
  # U-120: unsigned releases are opt-in, never the silent default.
  rm -f "$OUT/SHA256SUMS.minisig"
  echo "WARNING: EOS_ALLOW_UNSIGNED=1 — SHA256SUMS is UNSIGNED (removed any stale .minisig)."
else
  echo "error: no MINISIGN_SECRET_KEY set — refusing to assemble an UNSIGNED release." >&2
  echo "  Sign:   MINISIGN_SECRET_KEY=/path/off-repo/eos-release.key $0 ..." >&2
  echo "  Or opt in explicitly (dev only): EOS_ALLOW_UNSIGNED=1 $0 ..." >&2
  exit 1
fi
