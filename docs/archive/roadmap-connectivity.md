---
title: E-OS Connectivity Roadmap — USB · LAN · Bluetooth
status: archived
last-reviewed: 2026-08-30
owner: Gh0s777tt
---

# 🔌 E-OS Connectivity Roadmap — USB · LAN · Bluetooth

> Driver & stack roadmap for peripheral and network connectivity. Grounded in the
> actual `eos-base` driver tree (`drivers/`, `netstack/`). Companion to the main
> [ROADMAP](../../ROADMAP.md). Status keys: ✅ done · 🟡 partial · 🚧 in progress ·
> ⏳ planned · 🔬 research (needs real hardware).
>
> **Testability note.** Everything marked "QEMU-verifiable" can be developed and
> boot-tested in E-OS's headless QEMU harness. Items marked 🔬 need **real hardware**
> (QEMU emulates no Wi-Fi and effectively no Bluetooth), so they are development plans,
> not things the CI/dev loop can prove on its own.

---

## 1. USB

USB in E-OS is **xHCI-based** (`drivers/usb/xhcid`), so **all USB versions are already
covered at the controller level** — xHCI is backward-compatible and `xhcid` handles
Low/Full/High speed (USB 1.1/2.0) and SuperSpeed / SuperSpeed+ (USB 3.0–3.2). Support is
added **per device class** by writing a class driver and registering it in
`drivers/usb/xhcid/drivers.toml` (class/subclass/protocol → driver command). `usbhubd`
already handles hubs, so hub topology (many devices) works.

| Device class | Code | Driver | Status | Testable in QEMU |
|---|---|---|---|---|
| **HID** — keyboards, mice, gamepads | 3 | `usbhidd` | ✅ done | ✅ (`usb-kbd`, `usb-mouse`, `usb-tablet`) |
| Xbox 360 controller (vendor HID) | 0xFF/93 | `usbhidd` | ✅ done | ⚠️ (needs a passthrough pad) |
| **Hubs** — multi-device topology | 9 | `usbhubd` | ✅ done | ✅ (`usb-hub`) |
| **Mass storage** — flash drives, USB HDD | 8/6 | `usbscsid` | ✅ **done** — re-enabled + fixed (the "XHCI errors" were a `daemon`-crate `INIT_NOTIFY` bug, not SCSI/xHCI; `U-054`) | ✅ (`usb-storage`, verified: reads block 0) |
| **Audio** — headsets, speakers, mics | 1 | *(none — `usbaudiod` to write)* | ⏳ planned | ✅ (`usb-audio`) |
| **Printer** | 7 | *(none — `usbprinterd` to write)* | ⏳ planned | 🟡 (`usb-braille`/none-native; test via CUPS-less raw) |
| **CDC-ACM** — USB serial / modems | 2/2 | *(none — `usbserial` to write)* | ⏳ planned | ✅ (`usb-serial`) |
| **RNDIS / CDC-ECM** — USB-Ethernet | 2/2, 10 | **`usbnetd`** | ✅ **full duplex** — RNDIS driver: enumerate + handshake + MAC + `network.*` scheme + **TX and RX both verified**. RX=0 was the 2026-07-12 01:48 snapshot; the endpoint-numbering root cause (`U-056`) and the xhcid `O_NONBLOCK` deadlock (`U-057`) were both closed that same day, pcap-proven `DISCOVER → OFFER → REQUEST → ACK`. Records were lost to a branch migration and restored in `U-130` | 🟡 (`usb-net`; TX-only) |
| **UVC** — webcams | 14 | *(none)* | 🔬 later | 🟡 |

### USB work plan (priority order)

1. **Re-enable mass storage (`usbscsid`).** ✅ **Done (`U-054`).** The "xHCI error" turned
   out to be a `daemon`-crate `INIT_NOTIFY` bug (a subdriver spawned by `xhcid` got an invalid
   notify-pipe fd → abort), *not* a SCSI/xHCI issue. Fixed the daemon crate, re-enabled the
   mapping, verified reading a USB flash drive in QEMU (`-device usb-storage`). The daemon fix
   also unblocks any future xHCI subdriver (audio/printer/CDC).
2. **`usbserial` (CDC-ACM).** The *simplest* new class driver (two bulk endpoints, a
   control interface) — good first "new class" and immediately useful (serial consoles,
   Arduino, modems). QEMU-verifiable with `-device usb-serial`.
3. **`usbnetd` (CDC-ECM/RNDIS).** USB-Ethernet dongles → plug into the existing `netstack`
   as another link. Moderate effort. QEMU-verifiable with `-device usb-net`.
4. **`usbaudiod` (USB Audio Class 1.0, then 2.0).** Headsets / speakers / mics. **Largest
   of these** — isochronous endpoints, format/rate negotiation, feedback endpoints — and
   it must plug into the audio scheme alongside the PCI audio drivers
   (`ac97d`/`ihdad`/`sb16d`). Plan: UAC1 output (speakers) first, then input (mic), then
   UAC2. QEMU-verifiable with `-device usb-audio` (playback path).
5. **`usbprinterd` (Printer class).** Bulk-out (+optional bulk-in status). Raw printing
   first; a print spooler/driver ecosystem is a separate, larger effort.

**Effort:** re-enable storage ≈ days · CDC-ACM ≈ 1–2 weeks · USB-net ≈ 2–3 weeks ·
USB audio ≈ 4–8 weeks · printer ≈ 2–3 weeks (raw). Each is an isolated driver + a
`drivers.toml` line, so they ship incrementally without destabilising the core.

---

## 2. LAN (wired Ethernet) — develop to the max

**Already the strongest subsystem.** `netstack` (smoltcp: IP/ICMP/TCP/UDP + a router and
`netcfg`) rides on top of these PCI NIC drivers, each auto-spawned by `pcid` from its
`config.toml` PCI-ID match:

| NIC driver | Covers | Status |
|---|---|---|
| `virtio-netd` | virtio-net (VMs) | ✅ boot-verified in E-OS |
| `e1000d` | Intel 8254x/PRO/1000 (very common) | ✅ present; QEMU-verifiable (`-device e1000`) |
| `rtl8168d` | Realtek RTL8168/8111 (common desktop GbE) | ✅ present |
| `rtl8139d` | Realtek RTL8139 (legacy) | ✅ present; QEMU-verifiable (`-device rtl8139`) |
| `ixgbed` | Intel 82599 10GbE | ✅ present |

### LAN work plan (all QEMU-verifiable)

1. **Verify the driver set beyond virtio** — ✅ **done (2026-07):** E-OS boots with
   `-device e1000` and `pcid` auto-spawns `e1000d`, which binds the Intel NIC
   (`E1000 pci-0000-00-02.0 on: … IRQ …`) — login reached, 0 exceptions. Wired LAN is
   confirmed to work on a non-virtio NIC family, not just virtio-net.
2. **IPv6** — smoltcp supports it; wire it through `netstack`'s `ip`/`tcp`/`udp` schemes
   and `netcfg`. High value, no new hardware.
3. **More NIC coverage** — Realtek RTL8125 (2.5GbE), Intel I225/I226, Aquantia; and DHCPv6
   / SLAAC in `netcfg`.
4. **Throughput** — checksum offload, larger rings, zero-copy paths in the smoltcp glue.
5. **Bridging/VLAN** in the `router` module for appliance use.

---

## 3. Bluetooth — 🔬 full stack, needs real hardware

**E-OS/Redox has *no* Bluetooth today** — no HCI, no L2CAP, no profiles. This is a
ground-up subsystem. QEMU has effectively no usable BT emulation, so **every stage below
needs a real Bluetooth adapter** (USB BT dongles expose a standard **HCI-over-USB**
interface — class 0xE0 — which is the natural entry point and reuses `xhcid`).

### Layered architecture (bottom-up)

1. **HCI transport (`bthci`)** — talk to the controller. USB (class 0xE0, three endpoints:
   commands/events/ACL) first; UART-HCI later for embedded. Send HCI commands, receive
   events. *Milestone: reset the adapter, read its BD_ADDR, start/stop inquiry.*
2. **HCI host + L2CAP (`btd`)** — connection management + the L2CAP multiplexing layer that
   every profile rides on. *Milestone: establish an ACL link + an L2CAP channel to a peer.*
3. **SDP** — service discovery, so the host can find remote services and advertise its own.
4. **Pairing / security** — SSP (Secure Simple Pairing), link keys, encryption. Needs a
   key store; reuses E-OS's argon2/crypto where possible.
5. **Profiles** (each a separate daemon over L2CAP/RFCOMM):
   - **RFCOMM + SPP** — serial-over-BT (simplest profile, good first target).
   - **HID (HOGP)** — BT keyboards/mice → feed the existing `input`/`inputd` scheme.
   - **A2DP** — stereo audio to headphones/speakers (SBC codec first, then AAC/aptX) →
     plug into the audio scheme. This is the "Bluetooth headphones" the user wants.
   - **HFP** — headset mic/call audio.
6. **BLE (Bluetooth Low Energy)** — separate LE link layer + **GATT/ATT** + GAP for modern
   peripherals (wearables, sensors, LE audio). Large, can follow classic.

### Bluetooth phasing

| Phase | Deliverable | Rough effort | Hardware |
|---|---|---|---|
| B0 | `bthci` USB transport: reset + read BD_ADDR + inquiry | 2–4 weeks | USB BT dongle |
| B1 | `btd`: ACL + L2CAP + SDP | 1–2 months | dongle + a peer |
| B2 | Pairing/SSP + link-key store | 3–4 weeks | dongle + peer |
| B3 | RFCOMM/SPP + HID (HOGP) → `inputd` | 1–2 months | BT keyboard/mouse |
| B4 | A2DP (SBC) → audio scheme (BT headphones) | 2–3 months | BT headphones |
| B5 | BLE: LL + ATT/GATT + GAP | 2–4 months | LE peripheral |

**Total to "BT headphones + BT keyboard work":** roughly **6–12 months** of focused work,
all requiring hardware. This is a genuine subsystem, not a driver — best pursued upstream
in Redox too, so the whole ecosystem benefits.

---

## 4. Summary — what E-OS can do *now* vs *later*

- **Now, QEMU-verifiable (this dev loop):** wired LAN across multiple NIC families, USB HID
  (all keyboards/mice/gamepads), USB hubs, all USB *speeds*; re-enabling USB mass storage;
  writing CDC-ACM / USB-net / USB-audio / printer class drivers incrementally; IPv6.
- **Later, needs real hardware:** **Wi-Fi** (an even larger 🔬 project — 802.11 MAC +
  WPA-supplicant + per-chip firmware; see the main ROADMAP) and the full **Bluetooth**
  stack above. Both are development plans gated on hardware, not on E-OS design.
