# E-OS Hardware & Platform Capabilities — honest reality map + roadmap

> A grounded triage of the "what a modern OS should support" wishlist against what a **hardened
> Redox microkernel downstream** can realistically do. The goal is focus, not a spec sheet: to
> separate *"we can build this now"* from *"this needs the x86 rig"* from *"this is a multi-year
> subsystem"* from *"not for a hobby microkernel."*

## What E-OS actually is (so the plan is real, not marketing)

- A **Rust microkernel** OS (Redox lineage): userspace drivers over scheme IPC, strong isolation,
  security-first. Runs on **x86_64 + aarch64** (both boot-verified), riscv64 experimental.
- **Confirmed today:** UEFI boot, framebuffer graphics (**no GPU acceleration**), xHCI USB
  (HID / mass-storage / **networking** — U-055/57), wired LAN (e1000/rtl/ixgbe/virtio + smoltcp),
  **NVMe**, **full-disk encryption** (RedoxFS AES-XTS), basic PCI audio (ac97/ihda/sb16), the Fala B
  hardening stack (ASLR / W^X / overflow-checks).
- **Confirmed missing:** any GPU/DRM/Vulkan stack, Wi-Fi, Bluetooth, a modern audio pipeline,
  HDR/color management, power management beyond basic ACPI, most modern-laptop peripherals.
- **The honest niche:** E-OS competes on **security + auditability + connectivity + a distinctive
  desktop**, *not* on GPU/HDR/AI/gaming. The wishlist below is triaged against that reality.

## The single biggest gate: **there is no GPU stack on Redox**

Verified (2026): `virtio-gpud`/`vesad` are **2D-framebuffer only**; Redox's DRM is nascent
(read-only APIs); the first native Intel GPU driver only *began* upstream in 2025/26; the only
working GL/Vulkan is **llvmpipe (CPU software)**. Consequence: **all of §2 (displays/HDR/VRR),
the GPU/RT/DX12/Vulkan parts of §5, DirectStorage, and AR/VR are blocked on a GPU/DRM subsystem
that does not exist** and is a multi-year effort even upstream. E-OS should **track Redox's GPU
work, not build it alone.** This one fact removes ~a third of the wishlist from near-term scope.

## Legend
✅ **HAVE** · 🟢 **BUILDABLE NOW** (mostly QEMU-verifiable on the MacBook) · 🟡 **NEEDS THE RIG**
(buildable driver, but requires the physical x86 box w/ Intel/AMD + Nvidia/AMD GPU to test) ·
🟠 **FOUNDATIONAL** (needs a large missing subsystem; months–years) · 🔴 **OUT OF SCOPE** (far-future
HW / not applicable to a hobby microkernel)

---

## §1 Interfaces & connectivity
| Item | Tier | Note |
|---|---|---|
| USB 1.1–3.2 (all speeds) | ✅ | xHCI (`xhcid`) — backward-compatible, all speeds |
| USB device classes (HID, storage, **net**) | ✅ | done; audio/printer/CDC-serial = 🟢 (audio needs xHCI **isoch** first) |
| Wired LAN 1G | ✅ | e1000/rtl/ixgbe/virtio + smoltcp |
| 2.5G / 5G Ethernet (RTL8125, Intel I225/226) | 🟡 | new NIC driver; `igb`/`e1000e` partly QEMU-testable, real 2.5G needs the rig |
| 10G+ (ixgbe present) / 25–100G | 🟡/🔴 | ixgbe exists; 25G+ = enterprise NICs, huge drivers, rig-only |
| Wi-Fi 6/7/8 (802.11be/bn, MLO, 320MHz) | 🟠🟡 | **no 802.11 stack exists** — a Rust SoftMAC/MLME + wpa_supplicant(BSD) + firmware; months, rig-only. See `roadmap-connectivity.md` |
| Bluetooth 5/6 + LE Audio/Auracast | 🟠🟡 | **no BT stack** — HCI/L2CAP/profiles ground-up; `trouble`+`bt-hci` (Apache/MIT) is the path; rig-only |
| USB4 v2 / Thunderbolt 5 | 🟡🔴 | TB/USB4 = PCIe+DP tunneling over USB-C; large TB host-controller driver, no framework, rig-only, long-horizon |
| HDMI 2.1 / DP 2.1 output | 🟠 | display output ⇒ needs the GPU/mode-setting stack (see the GPU gate) |
| 5G/mmWave modem + eSIM | 🔴 | MBIM/QMI modem stack + carrier cert; out of realistic scope |
| NFC / UWB | 🔴 | niche HW drivers, rig-only, low priority |

## §2 Displays & graphics — **almost entirely blocked on the GPU gate**
| Item | Tier | Note |
|---|---|---|
| Framebuffer output (current) | ✅ | via bootloader GOP / virtio-gpu 2D |
| Higher-res / mode selection | 🟢 | pick GOP modes in the bootloader — doable now |
| Multi-monitor (2D) | 🟡 | virtio-gpu multi-scanout / real display driver; partial |
| HDR / Dolby Vision / HDR10+ | 🟠🔴 | needs GPU + an HDR compositor pipeline — foundational |
| VRR / FreeSync / G-Sync | 🟠 | needs GPU driver + mode-setting |
| High refresh (120–540 Hz) | 🟠 | needs GPU/display driver |
| Color mgmt (ICC v4, hardware LUT) | 🟠 | software ICC in the compositor is *partly* doable; hardware LUT needs the GPU driver |
| 8K/10K/16K, local dimming | 🔴 | GPU + panel features, out of scope |

## §3 Audio
| Item | Tier | Note |
|---|---|---|
| Basic PCI audio (ac97/ihda/sb16) | ✅ | present |
| USB Audio Class (UAC1/2) | 🟢🟠 | **blocked on xHCI isochronous** endpoints (`xhcid` returns ENOSYS for isoch today) → add isoch, then a UAC driver. Good, bounded project |
| Hi-Res (32-bit/384kHz/DSD) | 🟡 | DAC-driver + format negotiation in the audio scheme; needs HW |
| Spatial audio (Atmos/DTS:X/HRTF) | 🟠 | a software DSP/HRTF layer — big audio-framework effort |
| LE Audio / Auracast | 🟠 | needs the Bluetooth stack first |

## §4 Storage
| Item | Tier | Note |
|---|---|---|
| NVMe (PCIe) | ✅ | `nvmed` — E-OS boots from it |
| Full-disk encryption | ✅ | RedoxFS AES-XTS (FDE verified) |
| **AES-NI / SHA HW-accel** for FDE | 🟢 | use `aes`/`sha2` RustCrypto with CPU intrinsics — buildable, QEMU-testable, fits the hardened identity |
| **Software RAID 0/1/5/10** | 🟢 | a RAID scheme over block devices — buildable, QEMU-testable |
| NVMe 2.0 / PCIe 5/6 | 🟡 | same driver, newer PCIe gen is HW/firmware; rig |
| UFS 4 | 🔴 | mobile controller, rig-only, low priority |
| DirectStorage (GPU decompress) | 🔴 | needs GPU — out of scope |

## §5 CPU / GPU / AI
| Item | Tier | Note |
|---|---|---|
| x86-64 + ARM64 | ✅ | both boot-verified this project |
| RISC-V | 🟡 | Redox riscv64 experimental |
| New CPU gens (Arrow/Lunar Lake, Zen 5/6) | ✅ | "just work" if the arch + basic drivers are there |
| GPU (Vulkan/DX12/OpenGL/RT/Mesh/VRS) | 🟠🔴 | **the GPU gate** — foundational, realistically out of reach for E-OS alone; software GL (llvmpipe) only |
| NPU / AI accelerators | 🔴 | vendor NPU drivers + ML runtime; rig/out-of-scope |
| Local LLM (CPU) | 🟠 | a small CPU-inference model (candle/llama.cpp) *ported* to Redox is conceivable but a big research item; slow |

## §6 Input
| Item | Tier | Note |
|---|---|---|
| Keyboard (NKRO) / mouse / basic gamepad | ✅ | `usbhidd` (Xbox360 pad noted) |
| Precision touchpad / multi-touch / gestures | 🟢🟡 | HID multitouch parse + a gesture layer; buildable, some need HW |
| DualSense / gamepad haptics / adaptive triggers | 🟢🟡 | vendor HID reports; buildable, needs the pad |
| Touchscreen / active pen (Wacom/MPP) | 🟡 | HID digitizer driver; rig |
| RGB / macros | 🟡 | vendor-specific; rig |
| Eye/face tracking, always-on voice | 🟠🔴 | needs camera/CV or a speech engine — foundational |

## §7 Power management
| Item | Tier | Note |
|---|---|---|
| ACPI power-off / reboot | ✅ | basic `acpid` |
| Battery status, per-app profiles | 🟡🟠 | ACPI battery + a PM framework; needs HW |
| Modern Standby / S0ix, dynamic power sharing | 🟠 | large ACPI/PM subsystem; rig |
| USB-PD 240W / solar / wireless | 🔴 | EC/firmware, minimal OS role |

## §8 Hardware security — **E-OS's home turf**
| Item | Tier | Note |
|---|---|---|
| Microkernel isolation + Fala B (ASLR/W^X/overflow-checks) | ✅ | the microkernel analog of VBS/HVCI — already shipped |
| **TPM 2.0 driver (TIS/CRB)** | 🟢 | QEMU can emulate TPM 2.0 (`tpm-tis` + swtpm) — **QEMU-testable**, high-value for a hardened OS |
| **Measured / Secure Boot** | 🟢🟡 | extend PCRs via TPM + sign the bootloader; buildable, partly QEMU-testable |
| Hardware root of trust | 🟡 | TPM-anchored; needs the TPM/HW |
| Biometrics (fingerprint/Face/iris), privacy LEDs | 🔴 | HW+driver, rig-only, low priority |

## §9 Sensors
| Item | Tier | Note |
|---|---|---|
| ALS / accel / gyro / mag / proximity / baro | 🟡 | I2C/HID sensor drivers + a sensor scheme; rig, niche |
| LiDAR/ToF, under-display fingerprint, haptics | 🔴 | specialized HW, rig/out-of-scope |

## §10 Future tech
| Item | Tier | Note |
|---|---|---|
| **Post-quantum cryptography (ML-KEM/ML-DSA)** | 🟢 | **pure software**, RustCrypto `ml-kem`/`ml-dsa` — buildable now, QEMU-testable, *perfectly* on-brand for a hardened OS |
| Wi-Fi 8 / BT 7 / USB4 v3 / PCIe 7 | 🔴 | far-future HW; design connectivity APIs to not preclude them |
| CXL 3.x / optical / neuromorphic | 🔴 | out of scope |
| AR/VR OpenXR | 🔴 | needs GPU + XR runtime — foundational |

---

## The actual near-term plan (what's worth building, ranked)

### Do now on the MacBook (QEMU-verifiable, fits E-OS's security/connectivity niche)
1. **Post-quantum crypto** — adopt ML-KEM/ML-DSA in TLS/signing/FDE-key-wrap (RustCrypto). Pure software, high-value, on-brand.
2. **TPM 2.0 driver + measured boot** — QEMU emulates TPM 2.0; a TIS/CRB driver + PCR extension. Anchors the "hardened" story.
3. **AES-NI / SHA acceleration** for the existing FDE — swap in CPU-intrinsic crypto.
4. **Software RAID** over block devices — a RAID scheme; QEMU-testable with multiple disks.
5. **More USB classes** — add xHCI **isochronous** support (currently ENOSYS), then USB Audio; plus CDC-serial / printer. Builds on the USB work already done this project.
6. **The desktop environment** — the red/black "Crimson" shell (see `design-desktop-environment.md`); theming is landing now, verifiable via graphical boot.
7. **Higher-res framebuffer / basic multi-scanout** via the bootloader + virtio-gpu 2D.

### Do on the x86 rig (Intel/AMD + Nvidia/AMD GPU) — buildable drivers that need real hardware
- Wi-Fi (the 802.11 stack — the biggest connectivity project) and Bluetooth (`trouble`+`bt-hci`).
- 2.5G/5G NIC drivers (RTL8125, Intel I225/226); real 10G+ testing.
- HID advanced (DualSense haptics, touchscreen/pen, RGB), sensors, battery/ACPI-PM.
- **GPU bring-up experiments** — this is where AMD/Nvidia hardware matters, but treat it as *tracking/contributing to* Redox's own GPU effort, not a solo E-OS build.

### Explicitly deferred / out of scope (document, don't burn effort)
- The full GPU/DRM/Vulkan stack, HDR/VRR/color pipeline, DirectStorage, AR/VR, NPU/AI-accel, 5G modem, TB5/USB4, 25–100G, UFS, neuromorphic/optical/CXL/PCIe7. These are either foundational multi-year subsystems or far-future hardware; keep the connectivity/driver **APIs forward-compatible** so they *can* be added, but don't schedule them.

**Bottom line:** the realistic, high-value E-OS roadmap is **security primitives (PQ crypto, TPM, HW-accel FDE, RAID) + finishing the connectivity story (USB classes, then Wi-Fi/BT on the rig) + a polished distinctive desktop** — not chasing a flagship-2026 GPU/HDR/AI spec sheet that a hobby microkernel can't reach. The wishlist is a great *north star*; this file is the *route*.
