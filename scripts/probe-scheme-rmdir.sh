#!/usr/bin/env bash
# probe-scheme-rmdir.sh — czy `rmdir /scheme/<nazwa>` wyrejestrowuje schemat (R-F19).
#
# PO CO. `redoxfs::unmount_path()` na Redoksie sprowadza się do
# `fs::remove_dir("/scheme/<nazwa>")`, a instalator woła je po udanej instalacji i dostaje
# `EPERM` (`U-166`). Z lektury wynika, że to żądanie **nie** trafia do menedżera schematów,
# tylko **do samego demona redoxfs**, który słusznie odmawia usunięcia własnego korzenia
# (`unlink_internal`: brak rodzica → `EPERM`). Ta sonda sprawdza to na żywym systemie,
# zamiast wnioskować z kodu — w tej okolicy `U-166` zapisało trzy błędne hipotezy.
#
# KONTROLA INSTRUMENTU (§4.2). Sama `EPERM` niczego nie dowodzi, jeśli wszystko tutaj
# zwraca `EPERM`. Dlatego sonda pyta o trzy rzeczy naraz:
#   * `/scheme/file`      — korzeń schematu redoxfs   → oczekiwane EPERM
#   * `/scheme/nieistnieje` — schemat, którego nie ma  → oczekiwane ENOENT (inny błąd!)
#   * `/scheme/file/nie-ma` — zwykła ścieżka w schemacie → oczekiwane ENOENT
# Jeśli wszystkie trzy dadzą to samo, sonda nic nie mierzy i wynik trzeba odrzucić.
#
# NIEDESTRUKCYJNE. Sprawdzenie „brak rodzica" w redoxfs zachodzi PRZED jakąkolwiek
# modyfikacją, więc nawet trafienie w korzeń nic nie zapisuje. Mimo to pracujemy na
# kopii obrazu, nie na oryginale.
set -uo pipefail

IMG="${1:?usage: probe-scheme-rmdir.sh <image> [timeout]}"
TIMEOUT="${2:-300}"
QEMU="$(command -v qemu-system-aarch64 || echo /opt/homebrew/bin/qemu-system-aarch64)"
FW_CODE=/opt/homebrew/share/qemu/edk2-aarch64-code.fd
FW_VARS=/opt/homebrew/share/qemu/edk2-arm-vars.fd
[ -x "$QEMU" ] || { echo "probe: qemu-system-aarch64 nie znaleziony"; exit 1; }

WORK="$(mktemp -d)"; QPID=""
cleanup() { [ -n "$QPID" ] && kill "$QPID" 2>/dev/null; rm -rf "$WORK"; }
trap cleanup EXIT

cp "$FW_VARS" "$WORK/vars.fd"
cp "$IMG" "$WORK/src.img"          # kopia — oryginał nietykalny
SER="$WORK/ser.sock"; MON="$WORK/mon.sock"

"$QEMU" -machine virt -cpu cortex-a72 -smp 4 -m 2048 \
  -drive "if=pflash,unit=0,format=raw,readonly=on,file=$FW_CODE" \
  -drive "if=pflash,unit=1,format=raw,file=$WORK/vars.fd" \
  -device ramfb -device qemu-xhci -device usb-kbd -device virtio-rng-pci \
  -display none -serial "unix:$SER,server,nowait" -monitor "unix:$MON,server,nowait" \
  -drive "file=$WORK/src.img,if=none,id=d0,format=raw" -device "nvme,drive=d0,serial=eos" &
QPID=$!

python3 "$(dirname "$0")/probe-scheme-rmdir.py" "$SER" "$TIMEOUT"
rc=$?
exit $rc
