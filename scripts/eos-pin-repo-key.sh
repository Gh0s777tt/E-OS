#!/usr/bin/env bash
# eos-pin-repo-key.sh — install the repo-signing PUBLIC key into the image configs (R-702).
#
# WHY THIS EXISTS: `pkg-lib` already verifies the package index — `verify_repo_manifest()`
# calls `manifest_sig::verify_manifest_ed25519()` and **fails closed** once a key is pinned
# (missing signature -> RepoManifestUnsigned, invalid -> RepoManifestSigInvalid). It looks
# for that key at `/etc/pkg/eos-repo-sign.pub.toml` *inside the image*. Nothing was putting
# it there, so generating `keys/eos-repo-sign.pub.toml` on its own changes nothing: the
# client keeps printing "no pinned repo-manifest key … NOT signature-verified" and carrying
# on. This script closes that gap, which makes R-702 two commands instead of a research
# project (see keys/README.md for the keygen half).
#
# The installer's `[[files]]` entries have no `from`/`source` field — content is inline — so
# the key text is embedded into config/{aarch64,x86_64}/eos.toml between managed markers.
# Idempotent: a re-run replaces the block instead of appending a second one.
#
#   scripts/eos-pin-repo-key.sh [path/to/eos-repo-sign.pub.toml]
#
# SAFETY: this refuses to embed a SECRET key. `eos-repo-sign keygen` writes `[secret_keys]`
# + `ml_dsa_65_seed` for the secret half and `[public_keys]` + `ml_dsa_65` for the public
# one; only the public file may ever reach a config, and a config is world-readable inside
# every shipped image.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PUB="${1:-$ROOT/keys/eos-repo-sign.pub.toml}"
IMAGE_PATH="/etc/pkg/eos-repo-sign.pub.toml"      # must match pkg-lib REPO_SIGN_PUBKEY_PATH
CONFIGS=("$ROOT/config/aarch64/eos.toml" "$ROOT/config/x86_64/eos.toml")

if [ ! -f "$PUB" ]; then
    echo "error: no public key at $PUB" >&2
    echo "  Generate one first (the secret half never enters the repo):" >&2
    echo "    cargo build --release --manifest-path tools/eos-repo-sign/Cargo.toml" >&2
    echo "    tools/eos-repo-sign/target/release/eos-repo-sign keygen \\" >&2
    echo "        /path/off-repo/eos-repo-sign.secret.toml  keys/eos-repo-sign.pub.toml" >&2
    exit 1
fi

# Refuse the secret half, loudly and before anything is written.
if grep -qE '\[secret_keys\]|ml_dsa_65_seed' "$PUB"; then
    echo "error: $PUB looks like a SECRET key file ([secret_keys]/ml_dsa_65_seed)." >&2
    echo "  Never bake that into an image. Pass the PUBLIC half instead." >&2
    exit 1
fi
grep -qE '^[[:space:]]*ed25519[[:space:]]*=' "$PUB" || {
    echo "error: $PUB has no ed25519 field — pkg-lib's load_pinned_ed25519() would reject it." >&2
    exit 1
}

python3 - "$IMAGE_PATH" "$PUB" "${CONFIGS[@]}" <<'PY'
import io, re, sys

image_path, pub_path, *configs = sys.argv[1:]
key_text = io.open(pub_path, encoding="utf-8").read().rstrip("\n")

# 32-byte ed25519 key = 64 hex chars. Catching this here beats shipping an image
# whose only failure mode is a runtime "pinned manifest key is not a valid ed25519 key".
m = re.search(r'^\s*ed25519\s*=\s*"([0-9a-fA-F]+)"', key_text, re.M)
if not m or len(m.group(1)) != 64:
    sys.exit(f"error: ed25519 field is not 64 hex chars (got {len(m.group(1)) if m else 0})")

BEGIN = "# >>> R-702 pinned repo-signing public key (managed by scripts/eos-pin-repo-key.sh) >>>"
END   = "# <<< R-702 pinned repo-signing public key <<<"
block = (
    f'{BEGIN}\n'
    '# Pinned trust anchor for the package index. pkg-lib reads this path and, once it\n'
    '# exists, treats a missing or invalid repo.toml.sig as a hard error instead of a\n'
    '# warning. Regenerate with scripts/eos-pin-repo-key.sh; do not hand-edit.\n'
    '[[files]]\n'
    f'path = "{image_path}"\n'
    'mode = 0o644\n'
    'data = """\n'
    f'{key_text}\n'
    '"""\n'
    f'{END}\n'
)

for cfg in configs:
    t = io.open(cfg, encoding="utf-8", newline="").read()
    pat = re.compile(re.escape(BEGIN) + r".*?" + re.escape(END) + r"\n", re.S)
    if pat.search(t):
        t = pat.sub(block, t)
        action = "updated"
    else:
        t = t.rstrip("\n") + "\n\n" + block
        action = "added"
    io.open(cfg, "w", encoding="utf-8", newline="").write(t)
    print(f"  {action}: {cfg}")
PY

echo
echo "OK: key pinned at $IMAGE_PATH in $(( ${#CONFIGS[@]} )) config(s)."
echo "Next: rebuild the image so the key is actually present, then confirm the client"
echo "stops warning:  make CI=1 ARCH=aarch64 CONFIG_NAME=eos all"
echo "A boot that still prints 'no pinned repo-manifest key' means the file did not land."
