---
title: Reusing upstream driver code in E-OS — Linux · NVIDIA · AMD · Intel
status: archived
last-reviewed: 2026-08-30
owner: Gh0s777tt
---

# 🔍 Reusing upstream driver code in E-OS — Linux · NVIDIA · AMD · Intel

> Can code from the big vendor repos (torvalds/linux, NVIDIA, AMD, Intel) shorten E-OS
> driver development — by reusing, porting, referencing, or integrating — instead of
> writing everything from scratch? This is the grounded, per-repo answer.
>
> ⚖️ **Not legal advice.** This is engineering-informed license analysis. SPDX headers
> vary per file and drift over time — audit the **actual per-file license text** and get
> qualified counsel before shipping, especially for the AGPL-3.0 network/source clause and
> for any dual-licensed file where you elect the permissive arm.

## The two gating facts (everything follows from these)

1. **Two license targets, two rules.** E-OS's **driver layer is MIT** (from Redox) — you
   **cannot** copy or link *copyleft* code into it without destroying the MIT grant. The
   **distro aggregate is AGPL-3.0** — it can combine with the GPLv3 family and Apache-2.0,
   but **not with GPL-2.0-*only*** (no "or later", no AGPLv3 §13 bridge; GPLv2 §2(b) forbids
   relicensing a derivative). **The Linux kernel is GPL-2.0-only.**
2. **Execution model.** Vendor code is C for Linux's **monolithic in-kernel** model
   (kobject / DMA-API / `mac80211` / `cfg80211` / DRM). Redox needs **Rust userspace**
   drivers over scheme IPC. Even where the license allows it, the API model usually **does
   not port as code**.

> **Structural advantage:** Redox drivers are *separate userspace processes* talking over
> scheme IPC (message passing at a syscall boundary) = the FSF "pipes/sockets = separate
> programs / mere aggregation" case. So a GPL driver, shipped as its **own standalone GPL
> package**, does not force its license onto the MIT layer or the AGPL core. The real
> blocker for Linux Wi-Fi/BT is thus (a) the **MIT-layer policy** (no copyleft as MIT) and
> (b) that the **core frameworks** (`mac80211`/`cfg80211`, `net/bluetooth`) are
> **GPL-2.0-only**, which has no Redox analog anyway.

## The four reuse modes (verified)

| Mode | Allowed from | Verdict |
|---|---|---|
| **A. Incorporate code** (copy/link/port) | **Permissive only** — MIT, BSD-2/3, ISC, 0BSD, Apache-2.0 (Apache stays Apache + NOTICE + patent grant; one-way OK into AGPL) | ✅ for permissive · ❌ for any GPL/LGPL into the MIT layer |
| **B. Reference-only** | Read **GPL** source for **non-copyrightable facts** — register maps/addresses, bit-fields, init/reset sequences, command formats, protocol constants (17 U.S.C. §102(b)) — then **clean-reimplement in Rust** | ✅ for *facts* · ❌ copying *expression* (structure/comments/logic order) |
| **C. Firmware blob** | Ship redistributable binaries **as-is** (linux-firmware `WHENCE`) | ✅ **Confirmed** — does **not** touch E-OS source license (AGPLv3/GPLv3 §5 aggregate; §7 "System Libraries") |
| **D. Port/rewrite C→Rust** | A translation is a **derivative work** — the *source's* license still governs incorporation | ✅ only if source is permissive · ❌ "rewriting GPL in Rust does not launder it" |

**The single biggest finding:** best-in-class **permissive** alternatives already exist for
exactly E-OS's gaps, so you **rarely need to touch GPL at all**.

---

## Wi-Fi — the hardest gap (no Rust shortcut; a MAC must be built)

- **License is *not* the blocker for chip drivers.** Many are permissive: `ath9k` = **ISC**
  (no firmware!), `brcmfmac`/`mt76` = **ISC**, `iwlwifi`/`rtw88`/`rtw89` = dual
  **GPL-2.0 OR BSD-3-Clause**, `ath10k/11k/12k` = **BSD-3-Clause-Clear OR GPL-2.0**.
- **The real blocker is the execution model:** every one targets **`mac80211`+`cfg80211`
  (GPL-2.0-only)**, which E-OS lacks. You must first build a Rust **SoftMAC/MLME** ("mac80211
  equivalent"). There is **no host-side pure-Rust 802.11 stack anywhere** (all Rust Wi-Fi is
  ESP32-embedded/blob-dependent).
- **Cleanest path:**
  - **MAC:** port/reference **FreeBSD `net80211`** (**BSD-2-Clause**) + its BSD chip drivers
    (`iwm`/`ath`/`rtwn`) — permissive, simpler than Linux mac80211, copy/port is fully legal.
  - **Security:** **`wpa_supplicant`/`hostapd`** — **BSD-3-Clause since v2.10 (Jan 2022)** —
    the **one place real code (not just specs) is cleanly reusable**. **Do not** reimplement
    WPA3/SAE/EAP; port it and write a Redox `driver_redox.c`/`l2_packet` backend.
  - **Frames:** **`ieee80211-rs`** (MIT/Apache, `no_std`) — the one reusable Rust Wi-Fi
    *component* (a frame codec, not a stack).
  - **Firmware:** ship `iwlwifi-*`/`ath*` blobs from linux-firmware as-is.
- **First target:** `ath9k` (ISC, blob-free) for a native MAC, **or** a **FullMAC** chip
  (`brcmfmac` on Raspberry Pi — an E-OS aarch64 target) which offloads the MAC and lowers the
  bar. Realistic effort: **many months**; **needs real hardware** (QEMU emulates no Wi-Fi).

## Bluetooth — best opportunity, and it's Rust-native

- **`trouble` + `bt-hci`** (embassy-rs, **Apache-2.0 OR MIT**) — a transport-agnostic **BLE
  host stack** already running on std/Linux over HCI sockets. E-OS gets **L2CAP + GATT** by
  writing **one** `bt-hci` transport shim over the USB scheme. **Top recommendation** —
  native language, native model, permissive (pick the MIT arm → drops into the MIT layer).
- **Caveats:** `trouble` is **BLE-only** (no Classic BR/EDR → **no classic A2DP audio/HFP**
  yet), SMP/pairing partial, not yet qualified. `burble` (**MPL-2.0**) is the reference for
  the missing SMP crypto.
- **For Classic BT** (A2DP "Bluetooth headphones") + an open controller: port **Zephyr BT**
  (**Apache-2.0**, RTOS not Linux — close to Redox) or **Apache NimBLE** (**Apache-2.0**,
  built to be ported).
- **BlueZ** (Linux host stack) = **GPL-2.0** → reference-only. `bluer`/`bluez-async` wrap
  BlueZ → architecturally useless (copy only their Rust *API shape* for E-OS's GATT scheme).
- **Firmware:** Intel `ibt-*`, Broadcom, etc. blobs shippable; `btintel` init = GPL reference.
- **Needs real hardware** (QEMU has no usable BT). But the software path is the clearest of
  all the gaps.

## USB classes (audio / printer / CDC-serial / CDC-ethernet)

- Linux `snd-usb-audio`/`cdc-acm`/`usbnet`/`usblp` = **GPL-2.0** → **reference-only**.
- **Better:** the **USB-IF class specifications are open** (usb.org) — implement directly
  from the spec in Rust on `xhcid`, cleaner than mining GPL drivers. Rust `usb-device`/`nusb`
  ecosystem for shapes.
- Unblocked by the **`daemon` INIT_NOTIFY fix** (U-054) that got USB mass storage working.

## GPU acceleration — long horizon, not a shortcut

- **NVIDIA `open-gpu-kernel-modules`** = **per-file MIT** (license is *fine* for both the MIT
  layer and AGPL core) — but Turing+ delegates to **GSP firmware** over a versioned proprietary
  RPC + a huge in-kernel infra → **reference-only, not a real shortcut**. Rust **Nouveau/Nova**
  is a closer bring-up model.
- **AMD `amdgpu`** = many **MIT** files (but they live in the Linux tree and call **GPL-2.0**
  DRM/TTM/dma-fence APIs → **not liftable**). **AMDVLK/PAL** (GPUOpen, **MIT**) = best
  long-horizon **spec reference** for RDNA/GCN 3D, but presupposes a Vulkan/KMS substrate.
- **Intel `media-driver`/IGC/compute-runtime** = **MIT** but **no DRM substrate** to plug into.
- **Verdict:** no GPU-accel shortcut exists; a KMS/DRM-equivalent must come first. E-OS's
  `virtio-gpu` + framebuffer is the pragmatic near-term display path.

## LAN — essentially already solved

- E-OS ships **`smoltcp`** (**0BSD** — the most permissive license in the whole survey).
  Only action: a **version bump** for IPv6 SLAAC/multicast + TCP fixes. Highest-certainty,
  lowest-effort win. Wired NIC coverage (e1000/rtl/ixgbe/virtio) is already good and
  e1000 is boot-verified (U-053).

---

## Per-vendor bottom line

| Vendor | Wi-Fi | Bluetooth | GPU | Net | Net verdict |
|---|---|---|---|---|---|
| **Linux** | chip drivers ISC/dual-BSD (**reference/port**); `mac80211` GPL-2.0 (**reference-only**) | `net/bluetooth`/BlueZ GPL-2.0 (**reference-only**) | DRM GPL-2.0 (**reference-only**) | drivers GPL-2.0 | **Spec goldmine + `wpa_supplicant` (BSD = real code) + firmware.** Not driver code-reuse. |
| **Intel** | `iwlwifi` **dual GPL/BSD** (best-licensed Wi-Fi chip driver) + **mandatory firmware** | `btintel` init (GPL ref) + **firmware** | `media-driver` MIT (no substrate) | e1000/igb/ixgbe (GPL) | **Most useful vendor** — dual-license chip layer + firmware blobs. Rust repos = no driver value. |
| **NVIDIA** | **none** | **none** | `open-gpu-kernel-modules` **MIT** but GSP-locked (**reference-only**) | Mellanox = wrong class | **Near-zero** for E-OS priorities. |
| **AMD** | **none** (RZ600 = rebadged MediaTek MT7921 → `mt76`) | **none** | `amdgpu` MIT-ish (not liftable) · **AMDVLK MIT** (long-horizon 3D ref) | Pensando (wrong class) | **Dead end** for Wi-Fi/BT; GPU is a distant reference. Firmware blobs only. |

## Recommended plan (what actually shortens development)

1. **Bluetooth LE — start here.** Adopt **`trouble` + `bt-hci`** (MIT arm), write a
   USB-Bluetooth transport driver over the USB scheme → L2CAP + GATT. Rust-native, permissive,
   the clearest path. *(Needs a BT adapter on the rig to test.)*
2. **Wi-Fi security:** port **`wpa_supplicant`** (BSD-3-Clause) — never reimplement WPA3.
3. **Wi-Fi MAC:** port/reference **FreeBSD `net80211`** (BSD-2) + a BSD chip driver; first
   target `ath9k` (ISC) or a FullMAC (`brcmfmac`, RPi).
4. **Firmware:** create a **segregated non-free firmware package** (Debian-style) sourced
   from linux-firmware, with each `WHENCE`/`LICENSE` reproduced.
5. **USB classes:** implement **CDC-ACM** first from the USB-IF spec on `xhcid` (the daemon
   fix already unblocked subdrivers).
6. **smoltcp bump** for IPv6 — quick, high-certainty.

## Hard cautions

- **Per-file audit.** Dual `GPL-2.0 OR BSD-3-Clause` trees (e.g. `iwlwifi`) **mix** dual-
  licensed and GPL-2.0-only helper files — elect the permissive arm **only** on files that
  actually carry it. Verify every SPDX header.
- **No laundering.** Porting/translating **GPL** framework code (`mac80211`, `net/bluetooth`,
  USB class drivers) to Rust is a **derivative work** — it does **not** relicense it. Only
  reference **non-copyrightable facts**.
- **Maturity risk.** `trouble` ("future qualification"), `ieee80211-rs` ("not for production
  yet"), `burble` (pre-1.0) are early — expect to harden them.
- **AGPL network clause.** If any of this ends up in network-facing code, the AGPL-3.0 §13
  source-offer obligation applies — review with counsel.
