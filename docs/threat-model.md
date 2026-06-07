# 🛡️ E-OS Threat Model

> Status: **v2 (alpha)** · applies to E-OS `0.1.x` (Genesis). E-OS is a downstream
> of [Redox OS](https://www.redox-os.org); this model builds on Redox's microkernel
> and capability design. Companion docs: [Hardening Guide](hardening.md) ·
> [Disk Encryption](encryption.md) · [Security Policy](../SECURITY.md).

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
| **Malicious/compromised driver** | A buggy device driver | **Userspace driver isolation** — confined to its scheme; no ambient kernel authority. |
| **Physical / lost device** | Has the powered-off disk | **RedoxFS AES-XTS-128 full-disk encryption** (opt-in at install, see encryption.md). |
| **Supply chain** | Tampers with sources/deps | Recipes pinned to **E-OS source forks**; **reproducible** source builds; per-package **SBOM** (CycloneDX); **signed** release checksums (R-301/302). |

## 4. Attack surface (and the mitigation that covers it)

- **Syscalls / scheme IPC** → small kernel surface; Rust-implemented; capability-checked.
- **Userspace network stack** (`smoltcp`/netstack) → isolated process; no kernel network code.
- **Drivers** (nvmed, e1000d, xhcid, …) → userspace, per-scheme confinement.
- **Bootloader** → built from source (E-OS fork), verifiable; handles the encrypted-disk password prompt.
- **Login / auth** → `redox_users` with **argon2** password hashing; per-user scheme namespaces (`/etc/login_schemes.toml`).
- **Build pipeline** → forks + reproducible source + SBOM + checksums (+ optional minisign signing).

## 5. Inherited strengths (from Redox, kept by E-OS)

- **Memory safety** — kernel, `relibc`, drivers and userland in Rust → no use-after-free / buffer-overflow classes.
- **Microkernel** — minimal TCB; faults are contained to processes.
- **Everything-is-a-scheme** — capability-style, least-privilege resource access by construction.

## 6. Non-goals & residual risk (be honest)

E-OS is **pre-1.0 alpha**. It does **not** yet provide:

- **Formal verification** of the kernel or crypto.
- **UEFI Secure Boot** signing / a measured-boot (TPM) chain.
- **Hardened, audited defaults** across every service — the desktop image ships a
  passwordless `user` and `root:password` for convenience (**change these** —
  see hardening.md).
- **Mitigation of upstream gaps** — e.g. the aarch64 root-mount bug (`R-401b`).
- Protection against an attacker with **persistent privileged runtime access**.

Treat E-OS today as a **research / enthusiast** system. Report issues privately
per the [Security Policy](../SECURITY.md).
