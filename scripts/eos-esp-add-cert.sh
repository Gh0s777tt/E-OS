#!/usr/bin/env bash
# eos-esp-add-cert.sh — put the Secure Boot certificate, and the instructions for enrolling
# it, ON the installation medium (R-611c).
#
#   scripts/eos-esp-add-cert.sh <medium.img> [cert.pem]
#
# WHY THIS EXISTS. E-OS signs its bootloader with its OWN key, not a Microsoft-signed shim.
# On a stranger's x86_64 machine that means one unavoidable step by the owner: enrol our
# certificate in firmware. Shipping the certificate somewhere else -- a web page, a release
# note -- fails exactly when it is needed, because the person is standing in front of a
# firmware menu with a USB stick and no working machine. So it travels ON the stick.
#
# WHERE IT GOES. `EFI/EOS/eos-secureboot.der` and `EFI/EOS/README.txt`, beside the
# `EFI/BOOT/` the firmware already reads. DER, not PEM: UEFI key-enrolment menus take DER.
# sbverify wants PEM, so the verification below converts back rather than shipping the
# format that suits the test instead of the user.
#
# WHY A SEPARATE SCRIPT AND NOT mk/disk.mk. Writing into a FAT image needs mtools, and the
# build container does not have it; the debian image used here is the same one
# eos-secureboot-proof.sh already uses for exactly this reason. One implementation, called
# from eos-build.sh and from the CI job -- a second copy would drift the first time the
# layout changed.
set -euo pipefail

IMG="${1:?usage: eos-esp-add-cert.sh <medium.img> [cert.pem]}"
VOL="${EOS_BUILD_VOLUME:-eos-work}"
DEB="${EOS_DEB_IMAGE:-docker.io/library/debian:trixie}"
[ -f "$IMG" ] || { echo "esp-cert: image not found: $IMG" >&2; exit 1; }

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
cp "$IMG" "$WORK/medium.img"

# The certificate this build was signed with. Taken from the build tree rather than from a
# fixed path in the repo: the repo holds no private material, and the throwaway key used by
# eos-sb-setup-key.sh lives here too, so the shipped certificate always matches the
# bootloader actually on the medium. That correspondence is what the check at the end proves.
if [ $# -ge 2 ] && [ -n "${2:-}" ]; then
  cp "$2" "$WORK/our.crt"
else
  podman run --rm -v "$VOL":/work:ro "$DEB" \
    cat /work/redox/build/sb-signing/mok.crt > "$WORK/our.crt" 2>/dev/null || true
  [ -s "$WORK/our.crt" ] || {
    echo "esp-cert: no signing certificate at build/sb-signing/mok.crt in volume '$VOL'." >&2
    echo "          Run scripts/eos-sb-setup-key.sh first, or pass a certificate explicitly." >&2
    exit 1
  }
fi

# The ESP's offset is READ from the GPT, not assumed. Hard-coding 1 MiB would work today and
# break silently the first time the partition layout changed -- and R-609 plans exactly that
# (A/B slots repartition the disk).
ESP_OFF="$(python3 - "$WORK/medium.img" <<'PY'
import struct, sys, uuid
ESP = uuid.UUID('C12A7328-F81F-11D2-BA4B-00A0C93EC93B')
with open(sys.argv[1], 'rb') as fh:
    fh.seek(512); hdr = fh.read(92)
    if hdr[:8] != b'EFI PART':
        sys.exit('no GPT header')
    start, count, size = struct.unpack_from('<QII', hdr, 72)
    fh.seek(start * 512)
    for _ in range(count):
        e = fh.read(size)
        if len(e) < 128 or e[:16] == b'\0' * 16:
            continue
        if uuid.UUID(bytes_le=e[:16]) == ESP:
            print(struct.unpack_from('<Q', e, 32)[0] * 512)
            break
    else:
        sys.exit('no EFI System Partition in the GPT')
PY
)"
echo "esp-cert: ESP at byte offset $ESP_OFF"

cat > "$WORK/README.txt" <<'TXT'
E-OS Secure Boot certificate
============================

E-OS signs its own bootloader. It is NOT signed by Microsoft, so on a machine with
Secure Boot enabled the firmware will refuse to start it until you tell the firmware
to trust this certificate. That is one deliberate step, done once, by you.

  eos-secureboot.der   the certificate, in the format firmware menus expect

HOW TO ENROL IT

 1. Enter your firmware setup (usually Del, F2, F10 or F12 during power-on).
 2. Find Secure Boot settings. The certificate list is normally called "db",
    "Authorized Signatures", or "Trusted Signatures".
 3. Choose to add a key from a file, pick this USB stick, then
    EFI/EOS/eos-secureboot.der
 4. Save and exit. E-OS will now boot with Secure Boot left ON.

IF YOUR FIRMWARE HAS NO SUCH MENU

Some machines only allow enrolling keys through a shim's MokManager, and some allow
none at all. On those you must either turn Secure Boot off to install E-OS, or use a
different machine. Turning Secure Boot off is a real reduction in protection; it is
your decision to make knowingly, which is why this file does not pretend it is fine.

VERIFYING THIS CERTIFICATE MATCHES THE BOOTLOADER ON THIS STICK

On a Linux machine with sbsigntool installed:

    openssl x509 -inform DER -in EFI/EOS/eos-secureboot.der -out /tmp/eos.pem
    sbverify --cert /tmp/eos.pem EFI/BOOT/BOOTX64.EFI      # or BOOTAA64.EFI

It must say "Signature verification OK". If it does not, do not enrol this
certificate -- the stick is not what it claims to be.
TXT

echo "esp-cert: injecting into $(basename "$IMG")"
podman run --rm -v "$WORK":/w "$DEB" bash -euo pipefail -c "
  apt-get update -qq >/dev/null 2>&1
  apt-get install -y -qq mtools openssl sbsigntool >/dev/null 2>&1
  openssl x509 -in /w/our.crt -outform DER -out /w/eos-secureboot.der
  I=/w/medium.img@@$ESP_OFF
  mmd -i \"\$I\" ::/EFI/EOS 2>/dev/null || true
  mcopy -o -i \"\$I\" /w/eos-secureboot.der ::/EFI/EOS/eos-secureboot.der
  mcopy -o -i \"\$I\" /w/README.txt          ::/EFI/EOS/README.txt
  echo 'esp-cert: --- ESP now holds ---'
  mdir -i \"\$I\" -/ ::/EFI

  # The check the task asks for, and its negative control -- run HERE, against the files
  # actually on the medium, not against the sources they were copied from.
  mkdir -p /w/back
  mcopy -o -i \"\$I\" ::/EFI/EOS/eos-secureboot.der /w/back/cert.der
  BOOT=\$(mdir -i \"\$I\" -b ::/EFI/BOOT | grep -iE 'BOOT(X64|AA64)\.EFI' | head -1 | tr -d '\r')
  [ -n \"\$BOOT\" ] || { echo 'esp-cert: no bootloader in EFI/BOOT on this medium'; exit 1; }
  mcopy -o -i \"\$I\" \"\$BOOT\" /w/back/boot.efi
  openssl x509 -inform DER -in /w/back/cert.der -out /w/back/cert.pem
  sbverify --cert /w/back/cert.pem /w/back/boot.efi >/dev/null \
    || { echo 'esp-cert: FAIL -- the shipped certificate does NOT verify the shipped bootloader'; exit 1; }
  echo \"esp-cert: PASS -- shipped certificate verifies \$BOOT\"

  openssl req -new -x509 -newkey rsa:2048 -sha256 -days 1 -nodes \
    -subj '/CN=foreign not-ours/' -keyout /w/back/f.key -out /w/back/f.pem >/dev/null 2>&1
  if sbverify --cert /w/back/f.pem /w/back/boot.efi >/dev/null 2>&1; then
    echo 'esp-cert: FAIL -- a FOREIGN certificate also verified it; the check proves nothing'
    exit 1
  fi
  echo 'esp-cert: PASS -- a foreign certificate is refused (negative control)'
  shred -u /w/back/f.key 2>/dev/null || true
"

cp "$WORK/medium.img" "$IMG"
echo "esp-cert: done -- $(basename "$IMG") now carries EFI/EOS/eos-secureboot.der + README.txt"
