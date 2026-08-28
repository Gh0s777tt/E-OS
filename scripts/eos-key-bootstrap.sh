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
# The SECRET half defaults OFF-REPO. Two reasons, and the second was found the hard way:
#
#   1. A signing key has no business living in a working tree at all -- one `git add -f`, one
#      stray archive of the project directory, and it is gone.
#   2. This project directory sits on an exFAT volume mounted `noowners` (U-194). exFAT
#      stores NO POSIX permissions: the tool asks for 0600, the file reports 700, and chmod
#      is a no-op there. The 0600 the key deserves cannot be applied on that filesystem at
#      all, so the key must live somewhere the OS can actually protect it.
#
# EOS_REPO_SIGN_KEY is the name publish-repo.sh and publish-repo-pages.sh have used since
# U-120, so it is the one that counts: setting it once lets the same value drive generation
# AND publishing. This script briefly introduced a second name for the same thing
# (EOS_REPO_SIGN_SECRET, U-195) -- kept as an alias so instructions already handed out do not
# break, but a second name for one concept is a defect, not a feature.
SEC="${EOS_REPO_SIGN_KEY:-${EOS_REPO_SIGN_SECRET:-$HOME/.eos-keys/eos-repo-sign.secret.toml}}"
PUB="keys/eos-repo-sign.pub.toml"
mkdir -p "$(dirname "$SEC")" 2>/dev/null || true

step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
fail() { printf '\033[31mFAIL:\033[0m %s\n' "$1" >&2; exit 1; }

step "1/5  sanity"
# Three states, three different right answers. An earlier version failed on "the secret
# exists" alone, which also blocked the legitimate RESUME case added below -- a run that had
# already written both halves and stopped on a later check could never be restarted, because
# this guard fired before step 2 ever looked (U-195).
if [ -f "$SEC" ] && [ ! -f "$PUB" ]; then
  fail "$SEC exists but $PUB does not.
       That is a half-state this script will not guess its way out of: regenerating would
       rotate a key whose public half may already be pinned somewhere, and stranding every
       client that pinned it is not something to do by accident.
       Move the secret aside and read keys/README.md."
fi
if [ ! -f "$SEC" ] && [ -f "$PUB" ]; then
  fail "$PUB exists but its secret half is not at
         $SEC
       If the secret lives elsewhere, point EOS_REPO_SIGN_SECRET at it and re-run.
       If it is genuinely lost, this key can no longer sign anything and must be rotated --
       see keys/README.md and R-F26 for what that costs."
fi

# Resolve the signing tool the same way publish-repo.sh does, so both agree on what runs.
SIGN_BIN="${EOS_REPO_SIGN_BIN:-$ROOT/tools/eos-repo-sign/target/release/eos-repo-sign}"
[ -x "$SIGN_BIN" ] || SIGN_BIN="$(command -v eos-repo-sign 2>/dev/null || true)"

# Only GENERATING needs the tool. When both halves already exist this run only verifies and
# pins them, and demanding a Rust toolchain for that was a pointless wall: an operator whose
# keys were already written would have had to install a compiler to finish pinning them
# (U-195).
NEED_TOOL=1
[ -f "$SEC" ] && [ -f "$PUB" ] && NEED_TOOL=0

if [ "$NEED_TOOL" = "0" ]; then
  echo "    both halves already exist — no signing tool needed for this run"
elif [ -z "$SIGN_BIN" ] || [ ! -x "$SIGN_BIN" ]; then
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
[ "$NEED_TOOL" = "1" ] && echo "    no existing key; signing tool at ${SIGN_BIN#$ROOT/}"

step "2/5  generate the hybrid keypair (ed25519 + ML-DSA-65)"
if [ -f "$SEC" ] && [ -f "$PUB" ]; then
  # Resume rather than regenerate. A half-finished run -- keys written, a later check
  # failing -- used to be a dead end: keygen refuses to overwrite (rightly, since silently
  # rotating strands every client pinning the old public half), so re-running failed on the
  # existing public file and the operator was stuck with a valid key and no way forward.
  echo "    both halves already exist — skipping generation, continuing with them"
  echo "      secret: $SEC"
  echo "      public: $PUB"
else
  "$SIGN_BIN" keygen "$SEC" "$PUB"
fi

step "3/5  verify the secret really is protected"
mode=$(stat -f '%Lp' "$SEC" 2>/dev/null || stat -c '%a' "$SEC")
if [ "$mode" != "600" ]; then
  # Distinguish "someone loosened the permissions" from "this filesystem cannot express
  # them". Both are unsafe, but they need different fixes, and a bare "expected 600" sent
  # the operator looking for a chmod that would have silently done nothing (U-194).
  probe="$(dirname "$SEC")/.eos-mode-probe.$$"
  : > "$probe" 2>/dev/null && chmod 600 "$probe" 2>/dev/null
  pmode=$(stat -f '%Lp' "$probe" 2>/dev/null || stat -c '%a' "$probe" 2>/dev/null)
  rm -f "$probe"
  if [ "$pmode" != "600" ]; then
    fail "$SEC has mode $mode, and this filesystem cannot store 0600 at all
       (a freshly chmod-ed probe file came back as $pmode). exFAT and FAT keep no POSIX
       permissions, and a volume mounted \`noowners\` ignores ownership too, so the key has
       NO filesystem protection here -- any account that can read the volume can read it.
       Put the secret on the internal disk instead:
           EOS_REPO_SIGN_SECRET=\"\$HOME/.eos-keys/eos-repo-sign.secret.toml\" $0"
  fi
  fail "$SEC has mode $mode, expected 600 -- run: chmod 600 \"$SEC\""
fi
case "$SEC" in
  "$ROOT"/*|keys/*)
    git check-ignore -q "$SEC" || fail "$SEC sits inside the repo and is NOT gitignored — refusing to continue" ;;
  *) echo "    secret is off-repo ($SEC) — git cannot reach it, which is the point" ;;
esac
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

echo
echo "Done. What exists now:"
echo
printf "  %s\n" "$SEC"
echo "      the SECRET half - mode 0600, off-repo, NEVER commit or paste it"
cat <<'DONE'
  keys/eos-repo-sign.pub.toml
      the public half - safe to commit
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
