#!/usr/bin/env bash
# eos-sign-boot-payload.sh — sign the kernel and initfs so the bootloader will load them (V2-MS02).
#
# The bootloader verifies Ed25519 over SHA-512(role || len_le || data) and refuses to boot
# anything it cannot verify. The role tag stops a validly signed initfs from being accepted as
# a kernel; the length binds the size. This script produces the detached `.sig` files that go
# next to each payload.
#
#   scripts/eos-sign-boot-payload.sh <key.pem> kernel <file>   # -> <file>.sig
#   scripts/eos-sign-boot-payload.sh <key.pem> initfs <file>
#
# The key is an Ed25519 private key in PEM (openssl genpkey -algorithm ed25519). Generating and
# holding it is the operator's action, off-repo, exactly like the Secure Boot key -- this script
# never creates one.
set -euo pipefail

key="${1:?usage: $0 <key.pem> <kernel|initfs> <file>}"
role="${2:?role: kernel|initfs}"
file="${3:?path to payload}"

case "$role" in
  kernel) tag="e-os.boot.kernel" ;;
  initfs) tag="e-os.boot.initfs" ;;
  *) echo "role must be kernel|initfs" >&2; exit 2 ;;
esac
[ -f "$key" ]  || { echo "no key: $key" >&2; exit 1; }
[ -f "$file" ] || { echo "no payload: $file" >&2; exit 1; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# The signed message is the digest, not the payload: it keeps the bootloader from needing a
# second 21 MiB copy of the initfs to prepend a tag.
python3 - "$tag" "$file" "$tmp/digest" <<'PY'
import hashlib, sys
tag, path, out = sys.argv[1], sys.argv[2], sys.argv[3]
data = open(path, 'rb').read()
h = hashlib.sha512()
h.update(tag.encode())                      # 16-byte role tag, no padding needed: it is 16 chars
h.update(len(data).to_bytes(8, 'little'))   # length binds the size
h.update(data)
open(out, 'wb').write(h.digest())
PY

openssl pkeyutl -sign -inkey "$key" -rawin -in "$tmp/digest" -out "$file.sig"

sz=$(wc -c < "$file.sig" | tr -d ' ')
[ "$sz" = 64 ] || { echo "unexpected signature size $sz (want 64)" >&2; exit 1; }
echo "signed $role: $file.sig (64 B) over sha512($tag || len || data)"
