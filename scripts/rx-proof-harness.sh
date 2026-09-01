#!/usr/bin/env bash
# T3 — E-OS NIC RX proof harness (virtio-net / e1000 / e1000e / rtl8139).
#
# Boots a BUILT E-OS image headlessly in QEMU with SLIRP user-net + filter-dump pcap,
# lets the auto-start network services (init.d 10_smolnetd -> netstack, 10_dhcpd -> dhcpd,
# oneshot_async) run on their own, then parses the captured pcap to PROVE the guest
# RECEIVES frames: a full DHCP DORA (OFFER + guest REQUEST + ACK). ICMP echo-reply and
# ARP-reply are reported as extra RX evidence when present. Refutes the "RX=0" finding
# (findings/cross-siec.md §7) with a host-side pcap, the same way usbnetd was measured.
#
# READ-ONLY on the source tree: only reads the image; writes pcap+serial+report to a work
# dir. Does NOT build or modify anything. Mirrors scripts/ci-boot-smoke.sh (aarch64 boot)
# and mk/qemu.mk:232 (canonical -object filter-dump ... file=network.pcap).
#
# Why passive DHCP is the anchor: the network comes up automatically at boot, so the proof
# needs no interaction at all. The old reason given here — that serial input is NOT
# delivered to the guest on macOS QEMU — is wrong: the "0 RX interrupts" note was a symptom
# of the GICD_ICENABLER read-modify-write fixed in U-153. install-smoke-drive.py drives the
# login prompt and the installer TUI over the serial socket today. So we boot, wait, capture
# because it is simpler, not because typing is impossible.
#
# Usage:
#   rx-proof-harness.sh <image> [aarch64|x86_64] [virtio|e1000|e1000e|rtl8139|all] [login_timeout] [settle]
#     image          aarch64: harddrive.img / *.img ; x86_64: *.iso (live) or *.img
#     arch           aarch64 (default) | x86_64
#     nic            virtio (default) | e1000 | e1000e | rtl8139 | all
#     login_timeout  s to reach login (default: aarch64 420 TCG / x86_64 900)
#     settle         s to wait after login for DHCP DORA (default 90)
#
# PASS  <=>  pcap has OFFER>=1 AND REQUEST>=1 AND ACK>=1  (DISCOVER-only == RX=0 == FAIL).
set -uo pipefail

IMG="${1:?usage: rx-proof-harness.sh <image> [aarch64|x86_64] [virtio|e1000|e1000e|rtl8139|all] [login_timeout] [settle]}"
ARCH="${2:-aarch64}"
NIC="${3:-virtio}"
TIMEOUT="${4:-}"
SETTLE="${5:-90}"
[ -f "$IMG" ] || { echo "rx-proof: image not found: $IMG" >&2; exit 2; }

case "$ARCH" in
  aarch64)
    QEMU="$(command -v qemu-system-aarch64 || echo /opt/homebrew/bin/qemu-system-aarch64)"
    FW_CODE="/opt/homebrew/share/qemu/edk2-aarch64-code.fd"
    FW_VARS_SRC="/opt/homebrew/share/qemu/edk2-arm-vars.fd"
    : "${TIMEOUT:=420}"
    ;;
  x86_64|x86|amd64)
    ARCH=x86_64
    QEMU="$(command -v qemu-system-x86_64 || echo /opt/homebrew/bin/qemu-system-x86_64)"
    FW_CODE="/opt/homebrew/share/qemu/edk2-x86_64-code.fd"
    : "${TIMEOUT:=900}"
    ;;
  *) echo "rx-proof: unknown arch '$ARCH' (use aarch64|x86_64)" >&2; exit 2 ;;
esac
[ -x "$QEMU" ] || { echo "rx-proof: qemu not found: $QEMU" >&2; exit 2; }
[ -f "$FW_CODE" ] || { echo "rx-proof: firmware not found: $FW_CODE" >&2; exit 2; }

OUTDIR="${RXPROOF_OUT:-$(cd "$(dirname "$IMG")" && pwd)/rxproof-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$OUTDIR"

# ------------------------------------------------------------------ pcap parser
PARSER="$OUTDIR/parse_rx.py"
cat > "$PARSER" <<'PYEOF'
import struct, sys
fn = sys.argv[1] if len(sys.argv) > 1 else "network.pcap"
try:
    data = open(fn, "rb").read()
except OSError as e:
    print("PCAP MISSING:", e); print("RESULT: FAIL (no pcap)"); sys.exit(1)
if len(data) < 24:
    print("pcap too short:", len(data)); print("RESULT: FAIL (empty pcap)"); sys.exit(1)
magic = data[:4]
if   magic == b"\xd4\xc3\xb2\xa1": endian = "<"          # usec, little
elif magic == b"\xa1\xb2\xc3\xd4": endian = ">"          # usec, big
elif magic == b"\x4d\x3c\xb2\xa1": endian = "<"          # nsec, little
elif magic == b"\xa1\xb2\x3c\x4d": endian = ">"          # nsec, big
else:
    print("unknown pcap magic", magic.hex()); print("RESULT: FAIL (bad pcap)"); sys.exit(1)
DHCP = {1:"DISCOVER",2:"OFFER",3:"REQUEST",4:"DECLINE",5:"ACK",6:"NAK",7:"RELEASE",8:"INFORM"}
cnt  = {k:0 for k in ("DISCOVER","OFFER","REQUEST","ACK","NAK")}
icmp_req = icmp_reply = arp_req = arp_reply = frames = 0
off = 24
while off + 16 <= len(data):
    ts_sec, ts_usec, incl, orig = struct.unpack(endian + "IIII", data[off:off+16]); off += 16
    pkt = data[off:off+incl]; off += incl; frames += 1
    if len(pkt) < 14: continue
    et = struct.unpack(">H", pkt[12:14])[0]
    if et == 0x0806 and len(pkt) >= 22:                  # ARP
        op = struct.unpack(">H", pkt[20:22])[0]
        if   op == 1: arp_req += 1
        elif op == 2: arp_reply += 1
    elif et == 0x0800 and len(pkt) >= 34:                # IPv4
        proto = pkt[23]
        if proto == 17 and len(pkt) >= 42:               # UDP
            ihl = (pkt[14] & 0xF) * 4; u = 14 + ihl
            if u + 4 <= len(pkt):
                sport, dport = struct.unpack(">HH", pkt[u:u+4])
                if (sport, dport) in ((68,67),(67,68)):  # BOOTP/DHCP
                    b = u + 8; opts = pkt[b+240:]; i = 0; mt = None
                    while i < len(opts) - 1:
                        o = opts[i]
                        if o == 0: i += 1; continue
                        if o == 255: break
                        ln = opts[i+1]
                        if o == 53 and ln >= 1: mt = DHCP.get(opts[i+2]); break
                        i += 2 + ln
                    if mt in cnt: cnt[mt] += 1
        elif proto == 1 and len(pkt) >= 35:              # ICMP
            t = pkt[34]
            if   t == 8: icmp_req += 1
            elif t == 0: icmp_reply += 1
print("pcap:", fn)
print("frames captured:", frames)
print("DHCP  DISCOVER=%d OFFER=%d REQUEST=%d ACK=%d NAK=%d" %
      (cnt['DISCOVER'], cnt['OFFER'], cnt['REQUEST'], cnt['ACK'], cnt['NAK']))
print("ICMP  echo-request(TX)=%d echo-reply(RX)=%d" % (icmp_req, icmp_reply))
print("ARP   request=%d reply(RX)=%d" % (arp_req, arp_reply))
print("extra RX evidence: ICMP echo-reply=%s ARP-reply=%s" %
      ("YES" if icmp_reply >= 1 else "no", "YES" if arp_reply >= 1 else "no"))
dhcp_rx = cnt['OFFER'] >= 1 and cnt['REQUEST'] >= 1 and cnt['ACK'] >= 1
if dhcp_rx:
    print("RESULT: PASS (DHCP DORA complete -> guest RX proven)"); sys.exit(0)
if cnt['OFFER'] >= 1 and cnt['REQUEST'] == 0:
    print("RESULT: FAIL (OFFER on wire but guest emitted no REQUEST -> NIC RX path dropped it; RX=0, matches cross-siec.md §7)")
elif cnt['DISCOVER'] >= 1 and cnt['OFFER'] == 0:
    print("RESULT: FAIL (no OFFER on wire -> SLIRP/capture issue, RX inconclusive)")
else:
    print("RESULT: FAIL (incomplete DHCP handshake -> RX not proven)")
sys.exit(1)
PYEOF

# ------------------------------------------------------------------ nic -> qemu device
dev_for() {
  case "$1" in
    virtio)  echo "virtio-net-pci,disable-legacy=off,disable-modern=off" ;;  # TRANSITIONAL: id 0x1000 (virtio-netd matches) WITH modern caps (virtio-core is modern-only; disable-modern=on strips them -> "virtio common capability missing" panic)
    e1000)   echo "e1000" ;;                                                # 82540em, 0x100e (stock e1000d)
    e1000e)  echo "e1000e" ;;                                               # 82574L, 0x10d3 (x86_64 e1000e.toml overlay)
    rtl8139) echo "rtl8139" ;;                                              # rtl8139d (present, untested per cross-siec.md)
    *) echo "" ;;
  esac
}

run_one() {
  local nic="$1" dev; dev="$(dev_for "$nic")"
  [ -n "$dev" ] || { echo "rx-proof: unknown nic '$nic'" >&2; return 2; }
  if [ "$ARCH" = aarch64 ] && [ "$nic" = e1000e ]; then
    echo "rx-proof: WARN e1000e(82574L,0x10D3) is claimed only by the x86_64 e1000e.toml overlay;" >&2
    echo "          on aarch64 the stock e1000d map won't bind it -> expect FAIL. Use e1000 or virtio." >&2
  fi

  local WORK; WORK="$(mktemp -d)"
  local SERIAL="$OUTDIR/serial-$ARCH-$nic.log"; : > "$SERIAL"
  local MON="$WORK/mon.sock"
  local PCAP="$OUTDIR/rx-$ARCH-$nic.pcap"; rm -f "$PCAP"
  local QPID=""

  mon() { python3 - "$MON" "$1" <<'PY' 2>/dev/null || true
import socket, sys, time
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
try: s.connect(sys.argv[1])
except OSError: sys.exit(0)
s.settimeout(2); time.sleep(0.3)
s.sendall((sys.argv[2] + '\n').encode()); time.sleep(0.5)
try: s.recv(65536)
except Exception: pass
s.close()
PY
  }

  # canonical SLIRP user-net + explicit NIC + filter-dump pcap (mk/qemu.mk:232 pattern)
  local NET=(-netdev user,id=net0 -device "${dev},netdev=net0"
             -object "filter-dump,id=f0,netdev=net0,file=$PCAP")
  local A=()
  if [ "$ARCH" = aarch64 ]; then
    cp "$FW_VARS_SRC" "$WORK/vars.fd"
    A=(-machine virt -cpu cortex-a72 -smp 4 -m 2048
       -drive "if=pflash,unit=0,format=raw,readonly=on,file=$FW_CODE"
       -drive "if=pflash,unit=1,format=raw,file=$WORK/vars.fd"
       -device ramfb -device qemu-xhci -device usb-kbd -device usb-tablet -device virtio-rng-pci
       -display none -serial "file:$SERIAL" -monitor "unix:$MON,server,nowait"
       -drive "file=$IMG,if=none,id=disk0,format=raw" -device "nvme,drive=disk0,serial=eos"
       "${NET[@]}")
  else
    A=(-machine q35 -smp 4 -m 2048 -display none
       -serial "file:$SERIAL" -monitor "unix:$MON,server,nowait"
       -device qemu-xhci -device usb-kbd -device usb-tablet
       -drive "if=pflash,unit=0,format=raw,readonly=on,file=$FW_CODE")
    case "$IMG" in
      *.iso) A+=(-cdrom "$IMG") ;;
      *)     A+=(-drive "file=$IMG,if=none,id=disk0,format=raw" -device "nvme,drive=disk0,serial=eos") ;;
    esac
    A+=("${NET[@]}")
  fi

  echo "rx-proof[$ARCH/$nic]: booting -device ${dev}  (pcap=$PCAP, login<=${TIMEOUT}s, settle=${SETTLE}s)"
  # ${A[@]+...} rather than "${A[@]}": both branches above assign a non-empty array TODAY, so
  # this is safe today -- but `local A=()` plus `set -u` is one edit away from fatal on bash 3.2,
  # which is what /bin/bash is on the reference host. Measured, on this very construct in
  # ci-install-smoke.sh: `VIDEO_ARGS[@]: unbound variable`, before qemu started. The guard
  # expands identically when the array has elements (verified: `-x`, `a b`, `-y` preserved with
  # quoting intact), so it costs nothing and stops depending on control flow the next editor
  # may change. Gated by scripts/eos-check-unbound-arrays.py (ci-integrity check 13).
  "$QEMU" ${A[@]+"${A[@]}"} & QPID=$!

  local strip='s/\x1b\[[0-9;?]*[a-zA-Z]//g'
  local sent=0 login=0 deadline=$(( $(date +%s) + TIMEOUT ))
  while [ "$(date +%s)" -lt "$deadline" ]; do
    sleep 5
    kill -0 "$QPID" 2>/dev/null || { echo "rx-proof[$ARCH/$nic]: qemu exited early during boot"; break; }
    local txt; txt="$(sed "$strip" "$SERIAL" 2>/dev/null)"
    if [ "$sent" -lt 3 ] && printf '%s' "$txt" | grep -qaiE 'Redox Loader|E-OS|Genesis|BdsDxe|Arrow keys|resolution'; then
      mon 'sendkey ret'; sent=$((sent+1))
      [ "$ARCH" = x86_64 ] && { sleep 4; mon 'sendkey ret'; }   # x86_64 shows two video menus
    fi
    if printf '%s' "$txt" | grep -qaiE 'eos login:|^Login:|Username:'; then login=1; break; fi
    if printf '%s' "$txt" | grep -qaiE 'KERNEL PANIC|RELIBC PANIC|UNHANDLED EXCEPTION'; then
      echo "rx-proof[$ARCH/$nic]: panic/exception during boot:"; printf '%s\n' "$txt" | grep -aiE 'PANIC|UNHANDLED' | tail -5
      break
    fi
  done
  if [ "$sent" -eq 0 ]; then mon 'sendkey ret'; fi   # blind retry if menu never matched

  if [ "$login" = 1 ]; then
    echo "rx-proof[$ARCH/$nic]: login reached; settling ${SETTLE}s for netstack+dhcpd (10_dhcpd.service oneshot_async)…"
    local sd=$(( $(date +%s) + SETTLE ))
    while [ "$(date +%s)" -lt "$sd" ]; do sleep 5; kill -0 "$QPID" 2>/dev/null || break; done
    grep -qaiE 'lease|bound|10\.0\.2\.15' "$SERIAL" && echo "rx-proof[$ARCH/$nic]: (serial shows a lease hint)"
  else
    echo "rx-proof[$ARCH/$nic]: WARN never saw login prompt before timeout; parsing whatever was captured. Last serial:"
    sed "$strip" "$SERIAL" 2>/dev/null | tail -20
  fi

  # clean shutdown -> filter-dump closes -> pcap buffer flushed to disk
  mon 'quit'
  local k=0; while kill -0 "$QPID" 2>/dev/null && [ "$k" -lt 12 ]; do sleep 1; k=$((k+1)); done
  kill "$QPID" 2>/dev/null; wait "$QPID" 2>/dev/null
  rm -rf "$WORK"

  echo "----- pcap parse [$ARCH/$nic] -----"
  python3 "$PARSER" "$PCAP"; local rc=$?
  echo "----- end [$ARCH/$nic] rc=$rc (serial: $SERIAL) -----"
  return $rc
}

# ------------------------------------------------------------------ dispatch
declare -a NICS
if [ "$NIC" = all ]; then
  if [ "$ARCH" = aarch64 ]; then NICS=(virtio e1000); else NICS=(e1000e virtio); fi
else
  NICS=("$NIC")
fi

overall=0
for n in "${NICS[@]}"; do run_one "$n" || overall=1; done

echo
if [ "$overall" -eq 0 ]; then echo "rx-proof: OVERALL PASS ($ARCH: ${NICS[*]})";
else echo "rx-proof: OVERALL FAIL ($ARCH: ${NICS[*]})"; fi
echo "rx-proof: artifacts in $OUTDIR"
exit "$overall"
