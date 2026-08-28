#!/usr/bin/env bash
# eos-key-bootstrap.sh — YOUR one command to bring the repo-signing key into existence
# and wire everything that depends on it (R-701 / R-702).
#
# WHY THIS SCRIPT EXISTS AND WHY *YOU* RUN IT, NOT THE ASSISTANT.
# The release-signing key is the root of trust for every package E-OS will ever ship. Its
# whole value is that exactly one party holds it. Anything an assistant runs goes through
# tool calls whose output is captured into a session transcript, so a key generated there
# could never again be attested as uncopied -- and "probably not copied" is not a property
# you can build a supply chain on. So generation stays a human act (CLAUDE.md 10.3), and
# everything AROUND it is automated here, which is the part that was actually costing time.
#
#   scripts/eos-key-bootstrap.sh
#
# It never prints key material. `eos-repo-sign keygen` writes the secret with mode 0600 and
# refuses to clobber an existing file, so re-running this cannot silently rotate the key and
# strand every client pinning the old public half.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
SEC="keys/eos-repo-sign.secret.toml"
PUB="keys/eos-repo-sign.pub.toml"

step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
fail() { printf '\033[31mFAIL:\033[0m %s\n' "$1" >&2; exit 1; }

step "1/5  sanity"
[ -f "$SEC" ] && fail "$SEC already exists. Rotating a signing key strands every client
       pinning the old public half, so this script will not do it by accident.
       If you truly mean to rotate, move the old pair away first and read keys/README.md."

# Resolve the signing tool the same way publish-repo.sh does, so both agree on what runs.
SIGN_BIN="${EOS_REPO_SIGN_BIN:-$ROOT/tools/eos-repo-sign/target/release/eos-repo-sign}"
[ -x "$SIGN_BIN" ] || SIGN_BIN="$(command -v eos-repo-sign 2>/dev/null || true)"

if [ -z "$SIGN_BIN" ] || [ ! -x "$SIGN_BIN" ]; then
  # Deliberately NOT falling back to the build container, even though the toolchain lives
  # there (eos-root volume, /root/.cargo/bin). A signing key generated inside a shared VM
  # and written back through virtiofs is a key whose 0600 mode is not guaranteed, whose
  # lifetime you do not control, and whose provenance you cannot attest. For this one file
  # it is worth insisting on the host.
  if command -v cargo >/dev/null 2>&1; then
    echo "    building eos-repo-sign with the host toolchain"
    ( cd tools/eos-repo-sign && cargo build --release --quiet )
    SIGN_BIN="$ROOT/tools/eos-repo-sign/target/release/eos-repo-sign"
  elif command -v rustup >/dev/null 2>&1; then
    fail "rustup is installed but no toolchain is. Run this once, then re-run this script:

           rustup default stable

       The key is generated on YOUR machine on purpose. The build container has cargo, but
       a signing key written back out of a shared VM is not one whose protection you can
       vouch for."
  else
    fail "no Rust toolchain on this host. Install one (https://rustup.rs), then re-run.
       See keys/README.md for why this does not happen in the build container."
  fi
fi
echo "    no existing key; signing tool at ${SIGN_BIN#$ROOT/}"

step "2/5  generate the hybrid keypair (ed25519 + ML-DSA-65)"
"$SIGN_BIN" keygen "$SEC" "$PUB"

step "3/5  verify the secret really is protected"
mode=$(stat -f '%Lp' "$SEC" 2>/dev/null || stat -c '%a' "$SEC")
[ "$mode" = "600" ] || fail "$SEC has mode $mode, expected 600"
git check-ignore -q "$SEC" || fail "$SEC is NOT gitignored — refusing to continue"
grep -q "secret_keys" "$SEC" || fail "$SEC does not look like a secret key file"
grep -q "secret_keys" "$PUB" && fail "$PUB contains SECRET material — stop and delete both"
echo "    mode 600, gitignored, public half carries no secret material"

step "4/5  pin the public key into the image configs"
bash scripts/eos-pin-repo-key.sh "$PUB"

step "5/5  prove no secret reached anything tracked"
bash scripts/ci-integrity.sh >/dev/null || fail "integrity gate failed after pinning"
if git ls-files --error-unmatch "$SEC" >/dev/null 2>&1; then
  fail "$SEC is TRACKED by git. Remove it from the index before doing anything else."
fi
echo "    integrity gate passes; the secret is not tracked"

cat <<'DONE'

Done. What exists now:

  keys/eos-repo-sign.secret.toml   mode 0600, gitignored, NEVER commit or paste it
  keys/eos-repo-sign.pub.toml      public half, safe to commit
  config/{aarch64,x86_64}/eos.toml now embed the public key at
                                   /etc/pkg/eos-repo-sign.pub.toml inside the image

BACK THE SECRET UP NOW, offline. There is no recovery: lose it and every client pinning the
public half has to be re-imaged. `eos-repo-sign keygen` deliberately refuses to overwrite,
so it cannot be regenerated in place.

Next, in order:
  1. rebuild the image so the pinned key is actually in it
  2. scripts/publish-repo-pages.sh   -- the first signed publish (R-008)
  3. wire /etc/pkg.d/50_eos to that published repo (R-701)
DONE
