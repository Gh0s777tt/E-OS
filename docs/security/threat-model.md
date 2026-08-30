---
title: E-OS Threat Model
status: current
last-reviewed: 2026-08-30
owner: Gh0s777tt
---

# 🛡️ E-OS Threat Model

> Status: **v2 (alpha)** · applies to E-OS `0.1.x` (Genesis). E-OS is a downstream
> of [Redox OS](https://www.redox-os.org); this model builds on Redox's microkernel
> and capability design. Companion docs: [Hardening Guide](hardening.md) ·
> [Disk Encryption](../guides/encryption.md) · [Security Policy](../../SECURITY.md).

This document states **what E-OS protects, from whom, and how** — and, just as
importantly, what it does **not** yet protect. It is a living document; pre-1.0
E-OS makes **no stability or completeness guarantees**.

---

## 1. Assets

| Asset | Why it matters |
|---|---|
| **User data at rest** (RedoxFS) | Documents, credentials, keys on disk. |
| **System integrity** | Kernel, drivers, userland not tampered with at rest or runtime. |
| **Credentials** | User/root passwords (argon2 in `redox_users`), disk-encryption key. |
| **The boot chain** | Bootloader → kernel → init → login must load expected code. |
| **Capability namespaces** | A process's set of reachable **schemes** = its authority. |
| **Build/supply chain** | The recipes, forks and toolchain that produce the image. |

## 2. Trust boundaries

```
┌─ physical disk ─────────────────────────────────────────────┐
│  RedoxFS (optionally AES-XTS-128 encrypted, see encryption)  │
└─────────────────────────────────────────────────────────────┘
        │ (bootloader unlocks)         ▲ data-at-rest boundary
        ▼
┌─ Kernel space (TCB) ─ microkernel: scheduling, memory, IPC, schemes ─┐
└──────────────────────────────────────────────────────────────────────┘
        ▲ syscall / scheme-IPC boundary
        ▼
┌─ User space ────────────────────────────────────────────────┐
│  drivers · redoxfs · netstack · orbital · login · apps       │
│  each confined to its **scheme namespace** (least authority) │
└──────────────────────────────────────────────────────────────┘
        ▲ user/root + per-user namespace boundary
```

The **trusted computing base (TCB) is small**: the microkernel plus the bootloader.
Drivers, the filesystem, the network stack and the display server run **in user
space** — a compromised driver is a compromised *process*, not a kernel.

## 3. Adversaries & what each can do

| Adversary | Assumed capability | Primary defense |
|---|---|---|
| **Remote network** | Sends packets to exposed services | Network stack runs **in userspace** (a crash/compromise is contained, not kernel-level); minimize exposed services (see hardening). |
| **Local unprivileged process** | Runs as a normal user | **Capability schemes** — a process only reaches the schemes in its namespace; Rust memory-safety removes whole bug classes; user/root separation. |
| **Malicious/compromised driver** | A buggy device driver | **Partial.** At the *syscall* level: userspace, confined to its scheme, no ambient kernel authority. At the *bus* level: **none** — there is no IOMMU, so the driver can programme its device to DMA anywhere in physical memory. See §6. |
| **Physical / lost device** | Has the powered-off disk | **RedoxFS AES-XTS-128 full-disk encryption** (opt-in at install, see encryption.md). |
| **Supply chain** | Tampers with sources/deps | Recipes pinned to **E-OS source forks**; **reproducible** source builds; per-package **SBOM** (CycloneDX); **signed** release checksums (R-301/302). |

## 4. Attack surface (and the mitigation that covers it)

- **Syscalls / scheme IPC** → small kernel surface; Rust-implemented; capability-checked.
- **Userspace network stack** (`smoltcp`/netstack) → isolated process; no kernel network code.
- **Drivers** (nvmed, e1000d, xhcid, …) → userspace, per-scheme confinement.
- **Bootloader** → built from source (E-OS fork), verifiable; handles the encrypted-disk password prompt.
- **Login / auth** → `redox_users` with **argon2** password hashing; per-user scheme namespaces (`/etc/login_schemes.toml`).
- **Privileged GUI actions** (`eos-power`, the control-panel reboot/shutdown) → `sys:kstop` is root-only, and the GUI runs as the desktop user. Rather than run the GUI as root, a **short-lived `eos-power` shim** elevates via `/scheme/sudo` (the same daemon `sudo` uses — it checks sudo-group membership **and** the user's password, which the GUI pipes on the shim's **stdin**, never argv, so it never appears in `ps`) and then does exactly one thing: write `sys:kstop`. Blast radius even if the shim were abused is a **local reboot/poweroff** — and it still requires the user's password plus local access, which a password-holding user could already spend on `sudo shutdown`. The GUI process itself is **never elevated**; the password is held only transiently in the GUI and cleared after use. See `docs/architecture/eos-power.md`.
- **Build pipeline** → forks + reproducible source + SBOM + checksums (+ optional minisign signing).

## 5. Inherited strengths (from Redox, kept by E-OS)

- **Memory safety** — kernel, `relibc`, drivers and userland in Rust → no use-after-free / buffer-overflow classes.
- **Microkernel** — minimal TCB; faults are contained to processes.
- **Everything-is-a-scheme** — capability-style, least-privilege resource access by construction.

## 6. Non-goals & residual risk (be honest)

E-OS is **pre-1.0 alpha**. It does **not** yet provide:

- **Formal verification** of the kernel or crypto.
- A **measured-boot (TPM)** chain (`R-913`). Secure Boot signing of the bootloader exists
  (ADR-0005), and since `V2-MS02` the bootloader **verifies the kernel and initfs** it loads
  (Ed25519 over a domain-separated SHA-512; proven by `scripts/eos-boot-verify-proof.sh`, which
  boots an untouched image and gets a refusal from one with a single flipped kernel byte).
  **Say only what that buys**, because the gap either side of it is wide:
  - It does **not** make the boot chain verified. `initfs` carries only the disk drivers;
    `xhcid`, `e1000d`, `usbhidd`, `usbscsid`, `ihdad`, `rtl8168d` and ten more load from the
    **unsigned** root after mount, via `pcid` — and with no IOMMU (`Dmar::init` is still a TODO)
    a substituted driver reaches DMA, i.e. the same compromise by a different file.
  - It does **not** stop rollback: an older, correctly signed, vulnerable kernel still verifies.
  - On **BIOS** it is evidence of tampering, not a trust anchor — stage1/2/3 are raw sectors
    nothing authenticates, so an attacker who can write the kernel can replace the verifier.
  - In **live** mode the whole disk image is read into RAM unverified before the kernel is
    taken from it.
- **Hardened, audited defaults** across every service — the desktop image ships a
  passwordless `user` and `root:password` for convenience (**change these** —
  see hardening.md).
- **Mitigation of upstream gaps** — e.g. the aarch64 root-mount bug (`R-401b`).
- Protection against an attacker with **persistent privileged runtime access**.
- **DMA isolation for drivers — there is none.** This is the one place where the document
  used to promise more than the system delivers, so it is stated plainly rather than
  softened. Running drivers in user space removes their *kernel* authority: a compromised
  `nvmed` is a compromised process, and every syscall it makes is capability-checked against
  its scheme namespace. It does **not** remove their *device* authority. A driver programmes
  a real bus-mastering device, and with no IOMMU that device can read and write **any**
  physical address — including kernel memory — without the kernel being involved at all.
  Nothing in the scheme model can see that traffic, let alone stop it.

  Verified rather than assumed (`U-187`), at the pinned revisions: in `eos-base`,
  `drivers/acpid/src/acpi.rs:461` reads
  `//TODO (hangs on real hardware): Dmar::init(&this);` — the DMAR table is parsed
  (`drivers/acpid/src/acpi/dmar/mod.rs` exists) but **never initialised**, and the reason is
  upstream's own: it hung on real hardware. In `eos-kernel`, a search of the entire `src/`
  tree for `iommu`, `smmu` or `dmar` returns **zero files** — there is no IOMMU path in the
  kernel at all, on any architecture. So on current hardware the honest statement is: user-space drivers
  reduce the *blast radius of a bug* and give a crashed driver a restartable boundary; they
  do not contain a *hostile* driver. Treat any driver you load as trusted code.

  Real containment needs SMMUv3 on aarch64 (and VT-d/AMD-Vi on x86_64), tracked separately —
  it is a large piece of work, not a documentation fix.

Treat E-OS today as a **research / enthusiast** system. Report issues privately
per the [Security Policy](../../SECURITY.md).
