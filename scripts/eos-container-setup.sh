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
# THE SHAPE (why it looks like this — see docs/operations/ci.md + docs/getting-started/build-troubleshooting.md):
#   * The build state lives in two PERSISTENT NAMED VOLUMES, not in the
#     container's writable layer:
#         eos-work:/work    the tree at /work/redox (sources + build/ + prefix/)
#         eos-root:/root    the host toolchain and ~/.cargo registry caches
#     This is the whole reason the U-114 outage was survivable: `podman rm`
#     does NOT touch named volumes, so when the container vanished the ~37 GB of
#     incremental caches were still there — a rebuilt container that re-mounts
#     these volumes is warm in seconds (`cargo check` in ~6 s), not hours.
#     A container created WITHOUT them looks identical and silently orphans the
#     caches, which is exactly the trap this script used to walk into.
#   * CI syncs each commit into /work/redox with `git archive | tar -x`, so the
#     git revision sitting in the volume is irrelevant — only the caches matter.
#   * The repo is NOT bind-mounted from the host: on macOS podman the virtiofs
#     mount cannot serve cargo/rustc's mmap access pattern (EIO) — a from-scratch
#     build over a bind mount has never worked there.
#   * Flags mirror mk/podman.mk PODMAN_OPTIONS: SYS_ADMIN + /dev/fuse are
#     required to assemble/mount the RedoxFS image; --network=host is the
#     documented trade-off for recipe fetching. Omitting /dev/fuse yields a
#     container that execs fine but cannot assemble an image — verify it is
#     present before blaming the build.
#
# Usage (run on the runner host, e.g. the mac):
#   scripts/eos-container-setup.sh              # create what's missing
#   scripts/eos-container-setup.sh --recreate   # rebuild the CONTAINER only;
#                                               # the cache volumes are KEPT, so
#                                               # this is cheap and safe
#   scripts/eos-container-setup.sh --wipe-caches
#                                               # also delete eos-work/eos-root —
#                                               # the next build takes HOURS
# Tunables via env: EOS_MACHINE, EOS_CONTAINER, EOS_IMAGE, EOS_REPO_URL,
#   EOS_WORK_VOLUME, EOS_ROOT_VOLUME,
#   EOS_MACHINE_CPUS, EOS_MACHINE_MEM_MB, EOS_MACHINE_DISK_GB.
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
EOS_MACHINE="${EOS_MACHINE:-eos-build}"
EOS_CONTAINER="${EOS_CONTAINER:-eosbuild}"
EOS_IMAGE="${EOS_IMAGE:-redox-base}"
EOS_REPO_URL="${EOS_REPO_URL:-https://gitlab.com/e-os/e-os.git}"
EOS_WORK_VOLUME="${EOS_WORK_VOLUME:-eos-work}"
EOS_ROOT_VOLUME="${EOS_ROOT_VOLUME:-eos-root}"
RECREATE=0
WIPE_CACHES=0
case "${1:-}" in
    --recreate)    RECREATE=1 ;;
    --wipe-caches) RECREATE=1; WIPE_CACHES=1 ;;
    "")            ;;
    *) echo "error: unknown flag '$1' (expected --recreate or --wipe-caches)" >&2; exit 2 ;;
esac

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
        # `podman rm` leaves named volumes alone (only `rm -v` would take them),
        # so this drops the container and KEEPS the caches. That is the point.
        echo "==> --recreate: removing container '$EOS_CONTAINER' (cache volumes are kept)"
        podman rm -f "$EOS_CONTAINER"
    else
        echo "==> container '$EOS_CONTAINER' already exists — starting it (use --recreate to rebuild it)"
        podman start "$EOS_CONTAINER" >/dev/null 2>&1 || true
        podman exec "$EOS_CONTAINER" true
        echo "OK: $EOS_CONTAINER is up."
        exit 0
    fi
fi

if [ "$WIPE_CACHES" = "1" ]; then
    echo "==> --wipe-caches: deleting volumes '$EOS_WORK_VOLUME' and '$EOS_ROOT_VOLUME' — the next build takes HOURS"
    podman volume rm "$EOS_WORK_VOLUME" "$EOS_ROOT_VOLUME" 2>/dev/null || true
fi

echo "==> creating container '$EOS_CONTAINER'"
# Flags mirror mk/podman.mk PODMAN_OPTIONS (minus --rm, and with the host bind
# mounts replaced by named volumes — see the header). A detached `bash` under
# --interactive --tty keeps the container alive; CI then does `podman start` +
# `podman exec`. podman creates either volume on demand if it does not exist,
# so a first run and a post-outage recovery take the identical code path.
podman run --detach --interactive --tty \
    --name "$EOS_CONTAINER" \
    --cap-add SYS_ADMIN --device /dev/fuse --network=host --pids-limit=-1 \
    --volume "$EOS_WORK_VOLUME:/work" --volume "$EOS_ROOT_VOLUME:/root" \
    --env PODMAN_BUILD=0 \
    --env PATH=/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    "$EOS_IMAGE" bash

# ── 4. toolchain inside (rustup + sccache/just/cbindgen, all SHA256-pinned) ──
# It installs into /root, which is the eos-root volume — so after a --recreate it
# is already there and re-running it would just re-download the pinned tarballs.
if podman exec "$EOS_CONTAINER" test -x /root/.cargo/bin/cargo 2>/dev/null; then
    echo "==> host toolchain already present in '$EOS_ROOT_VOLUME' ($(podman exec "$EOS_CONTAINER" cargo --version))"
else
    echo "==> installing the pinned host toolchain (podman/rustinstall.sh)"
    podman cp "$HERE/podman/rustinstall.sh" "$EOS_CONTAINER:/tmp/rustinstall.sh"
    podman exec "$EOS_CONTAINER" bash /tmp/rustinstall.sh
    podman exec "$EOS_CONTAINER" rm -f /tmp/rustinstall.sh
fi

# ── 5. seed /work/redox (CI overwrites sources per-commit via git archive) ──
if ! podman exec "$EOS_CONTAINER" test -d /work/redox/.git 2>/dev/null; then
    echo "==> cloning $EOS_REPO_URL into /work/redox"
    podman exec "$EOS_CONTAINER" mkdir -p /work
    podman exec "$EOS_CONTAINER" git clone "$EOS_REPO_URL" /work/redox
fi

echo
echo "==> sanity check (a container that execs but cannot mount RedoxFS is the silent failure)"
# Spelled out as if/else rather than `test … && echo`: under `set -e` a bare
# failing test would abort the script here with no message at all — the sanity
# check has to be loudest exactly when it fails.
if podman exec "$EOS_CONTAINER" test -c /dev/fuse; then
    echo "    /dev/fuse: present"
else
    echo "    /dev/fuse: MISSING — this container can exec and compile but cannot assemble a RedoxFS image" >&2
fi
podman exec "$EOS_CONTAINER" sh -c 'du -sh /work/redox 2>/dev/null || echo "    /work/redox: empty (first run — expect a from-scratch build)"'
echo
echo "OK: container '$EOS_CONTAINER' is ready. Next steps:"
echo "  1. Gate 1 — prove the caches are warm before committing to an image build:"
echo "       scripts/eos-check.sh /work/redox/recipes/core/base/source -p virtio-core"
echo "     A warm tree finishes in seconds; a cold one means the volumes were lost."
echo "  2. Full build (hours from cold; minutes when incremental):"
echo "       podman exec $EOS_CONTAINER bash -lc 'cd /work/redox && make CI=1 ARCH=aarch64 CONFIG_NAME=eos all'"
echo "  3. Verify the CI probe:   podman exec $EOS_CONTAINER true"
echo "  4. Re-run the failed GitLab jobs (build-image / docs-pdf) or wait for the nightly schedule."
echo "     (docs-pdf apt-installs chromium inside the container on its first run.)"
echo "  5. Then: bump the two held pins and drop their scripts/pin-allowlist.txt entries (see U-124)."
