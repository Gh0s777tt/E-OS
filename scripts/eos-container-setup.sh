#!/usr/bin/env bash
# eos-container-setup.sh — (re)create the persistent `eosbuild` build container.
#
# WHY THIS EXISTS: the heavy CI tier (build-image, docs-pdf) runs inside a
# long-lived podman container named `eosbuild` on the `eos-heavy` runner. Until
# U-123 its creation was tribal knowledge — when the podman machine was
# recreated and the container vanished, every heavy job failed with
# "no container with name or ID \"eosbuild\" found" and there was no written
# way back. This script IS that way back, idempotent and safe to re-run.
#
# THE SHAPE (why it looks like this — see docs/ci.md + docs/build-troubleshooting.md):
#   * The container is PERSISTENT and carries the whole tree at /work/redox
#     (sources + build/ + prefix/ caches), so CI builds are incremental —
#     minutes, not hours. CI syncs each commit in with `git archive | tar -x`.
#   * The repo is NOT bind-mounted: on macOS podman the virtiofs mount cannot
#     serve cargo/rustc's mmap access pattern (EIO) — a from-scratch build over
#     a bind mount has never worked there. Everything lives inside the VM.
#   * Flags mirror mk/podman.mk PODMAN_OPTIONS: SYS_ADMIN + /dev/fuse are
#     required to assemble/mount the RedoxFS image; --network=host is the
#     documented trade-off for recipe fetching.
#
# Usage (run on the runner host, e.g. the mac):
#   scripts/eos-container-setup.sh              # create what's missing
#   scripts/eos-container-setup.sh --recreate   # DELETE the container (and its
#                                               # caches!) and build a fresh one
# Tunables via env: EOS_MACHINE, EOS_CONTAINER, EOS_IMAGE, EOS_REPO_URL,
#   EOS_MACHINE_CPUS, EOS_MACHINE_MEM_MB, EOS_MACHINE_DISK_GB.
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
EOS_MACHINE="${EOS_MACHINE:-eos-build}"
EOS_CONTAINER="${EOS_CONTAINER:-eosbuild}"
EOS_IMAGE="${EOS_IMAGE:-redox-base}"
EOS_REPO_URL="${EOS_REPO_URL:-https://gitlab.com/e-os/e-os.git}"
RECREATE=0
[ "${1:-}" = "--recreate" ] && RECREATE=1

command -v podman >/dev/null || { echo "error: podman not found (brew install podman)"; exit 1; }

# ── 1. podman machine (macOS/Windows hosts only — Linux podman is native) ──
if podman machine --help >/dev/null 2>&1 && [ "$(uname -s)" = "Darwin" ]; then
    if ! podman machine inspect "$EOS_MACHINE" >/dev/null 2>&1; then
        # Sizing: the full image build wants real resources. Defaults are
        # deliberately generous; override via env if the host is small.
        CPUS="${EOS_MACHINE_CPUS:-$(( $(sysctl -n hw.ncpu) - 2 ))}"; [ "$CPUS" -lt 4 ] && CPUS=4
        echo "==> creating podman machine '$EOS_MACHINE' (cpus=$CPUS, mem=${EOS_MACHINE_MEM_MB:-8192}MB, disk=${EOS_MACHINE_DISK_GB:-140}GB)"
        podman machine init "$EOS_MACHINE" \
            --cpus "$CPUS" \
            --memory "${EOS_MACHINE_MEM_MB:-8192}" \
            --disk-size "${EOS_MACHINE_DISK_GB:-140}"
    fi
    podman machine start "$EOS_MACHINE" 2>/dev/null || true   # idempotent
    # If macOS blocked the VM helper (vfkit/krunkit/gvproxy), `start` fails —
    # approve it under System Settings → Privacy & Security and re-run.
    podman info >/dev/null || { echo "error: podman machine not reachable — check Privacy & Security approvals for vfkit/krunkit/gvproxy, then re-run"; exit 1; }
fi

# ── 2. base image (Debian trixie + all recipe build deps) ──
if ! podman image exists "$EOS_IMAGE"; then
    echo "==> building image '$EOS_IMAGE' from podman/redox-base-containerfile"
    podman build --tag "$EOS_IMAGE" --file - < "$HERE/podman/redox-base-containerfile"
fi

# ── 3. the persistent container ──
if podman container exists "$EOS_CONTAINER"; then
    if [ "$RECREATE" = "1" ]; then
        echo "==> --recreate: removing existing '$EOS_CONTAINER' (this DELETES the /work/redox build caches)"
        podman rm -f "$EOS_CONTAINER"
    else
        echo "==> container '$EOS_CONTAINER' already exists — starting it (use --recreate to rebuild from scratch)"
        podman start "$EOS_CONTAINER" >/dev/null 2>&1 || true
        podman exec "$EOS_CONTAINER" true
        echo "OK: $EOS_CONTAINER is up."
        exit 0
    fi
fi
echo "==> creating container '$EOS_CONTAINER'"
# Flags mirror mk/podman.mk PODMAN_OPTIONS (minus --rm, minus the bind mounts —
# see the header). A detached `bash` under --interactive --tty keeps the
# container alive; CI then does `podman start` + `podman exec`.
podman run --detach --interactive --tty \
    --name "$EOS_CONTAINER" \
    --cap-add SYS_ADMIN --device /dev/fuse --network=host --pids-limit=-1 \
    --env PODMAN_BUILD=0 \
    --env PATH=/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    "$EOS_IMAGE" bash

# ── 4. toolchain inside (rustup + sccache/just/cbindgen, all SHA256-pinned) ──
echo "==> installing the pinned host toolchain (podman/rustinstall.sh)"
podman cp "$HERE/podman/rustinstall.sh" "$EOS_CONTAINER:/tmp/rustinstall.sh"
podman exec "$EOS_CONTAINER" bash /tmp/rustinstall.sh
podman exec "$EOS_CONTAINER" rm -f /tmp/rustinstall.sh

# ── 5. seed /work/redox (CI overwrites sources per-commit via git archive) ──
if ! podman exec "$EOS_CONTAINER" test -d /work/redox/.git 2>/dev/null; then
    echo "==> cloning $EOS_REPO_URL into /work/redox"
    podman exec "$EOS_CONTAINER" mkdir -p /work
    podman exec "$EOS_CONTAINER" git clone "$EOS_REPO_URL" /work/redox
fi

echo
echo "OK: container '$EOS_CONTAINER' is ready. Next steps:"
echo "  1. First full build (hours the first time; incremental after):"
echo "       podman exec $EOS_CONTAINER bash -lc 'cd /work/redox && make CI=1 ARCH=aarch64 CONFIG_NAME=eos all'"
echo "  2. Verify the CI probe:   podman exec $EOS_CONTAINER true"
echo "  3. Re-run the failed GitLab jobs (build-image / docs-pdf) or wait for the nightly schedule."
echo "     (docs-pdf apt-installs chromium inside the container on its first run.)"
echo "  4. Then: bump the two held pins and drop their scripts/pin-allowlist.txt entries (see U-114)."
