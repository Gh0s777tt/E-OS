---
title: Hardware capabilities roadmap (R-50x)
status: archived
last-reviewed: 2026-08-30
owner: Gh0s777tt
---

# Hardware capabilities roadmap (`R-50x`)

Backend/storage/crypto capabilities that take E-OS beyond "boots and runs a
desktop": each item lists the **recommended order**, a **realistic scope** for
one end-to-end phase (code → build → QEMU boot → verification → commit), and
explicit non-goals so scope doesn't creep. Recreated 2026-07-12 after the
original working notes were lost; the order below is the recommended one.

Verification target throughout: **aarch64 QEMU `virt`** (ramfb, NVMe), the same
rig every phase in this repo is verified on. Real-hardware follow-ups belong to
`R-403` (hardware test matrix).

---

## R-501 — RAID-1 mirror daemon (`raid1d`) — *first* — ✅ DELIVERED (U-042)

**Why first:** pure userspace, exercises the scheme/daemon machinery we already
know, immediately useful (mirrored root/data on two disks), and it unlocks
degraded-boot stories that fit E-OS's resilience branding.

**Scope (MVP, one phase):**
- A userspace block-scheme daemon that opens two underlying disk schemes and
  exposes one mirrored logical block device for RedoxFS (or the installer) to
  sit on.
- A tiny on-disk superblock (per member, last 4 KiB: magic, array UUID, member
  index, generation counter) so members are identified positively — no
  accidental mirroring of unrelated disks.
- Writes go to both members (fail the write only if **both** fail); reads come
  from the primary with automatic fallback to the secondary on error.
- **Degraded mode:** boot and serve with one member missing/failed, loudly
  logged.
- An `eos raid` (or `raid1ctl`) helper to initialize members (`create`) and
  inspect state (`status`).
- QEMU verification: two NVMe disks → `create` → RedoxFS `mkfs`+mount on the
  mirror → write data → power off → boot with **one** disk → data readable,
  degraded warning in the log.

**Non-goals (MVP):** resync/rebuild after re-adding a member (documented as
R-501b), RAID-0/5/6, hotplug, write-intent bitmaps, more than 2 members, boot
*from* the mirror (the mirror serves data volumes first; root-on-RAID lands
with R-501c after the installer learns about it).

## R-502 — aarch64 crypto-extension acceleration for FDE — ✅ DELIVERED (U-043/U-044)

**Why second:** the FDE path (R-305, RedoxFS AES-XTS) is pure-software today;
ARMv8 Crypto Extensions (AES/PMULL/SHA2) are present on the QEMU `cortex-a72`,
`cortex-a53` and `max` models (confirmed once the kernel ISAR decode bug U-043
was fixed) and on every realistic deployment target, and the whole change lives in
the userspace `redoxfs` daemon — no kernel work.

**Scope (one phase):**
- Wire the `aes` crate's ARMv8 hardware backend (runtime-detected, with clean
  software fallback) into the RedoxFS encryption path used by the FDE image.
- Benchmark: sequential read/write on an encrypted volume before/after, numbers
  recorded in `docs/guides/encryption.md`.
- Verify FDE boot (existing `fde_unlock.sh` flow) still unlocks and mounts.

**Non-goals:** kernel-side crypto, SHA acceleration for pkgar (separate,
smaller follow-up R-502b), x86 AES-NI (already handled by the crates upstream).

## R-503 — post-quantum (hybrid) package signing — ✅ DELIVERED (U-045)

**Why third:** highest ceremony, least code urgency. The pkgar repo signing is
ed25519 today (R-1003); the PQ transition should be **hybrid** (classical +
ML-DSA) so nothing gets weaker.

**Scope (one phase, tooling-first):**
- A scoping prototype in the repo tooling: sign `repo.toml`/pkgar metadata with
  ed25519 **and** ML-DSA-65 (via a vetted Rust implementation), verify both on
  install; images keep working with classical-only verifiers.
- A written migration plan in `docs/security/index.md` (key custody, rollout stages,
  fallback).

**Non-goals:** PQ TLS/ssh (upstream-dependent), PQ FDE-KDF (the KDF is not the
quantum-exposed part), replacing ed25519 outright.

## Horizon (unnumbered until scoped)

- NVMe SMART/health surfacing (`eos doctor` integration).
- TRIM/discard pass-through end-to-end (nvmed → RedoxFS).
- virtio-gpu path for QEMU (replaces ramfb; resolution switching + speed).
- Multi-queue NVMe / io parallelism in the storage daemons.
