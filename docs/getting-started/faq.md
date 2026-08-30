---
title: E-OS FAQ
status: current
last-reviewed: 2026-08-30
owner: Gh0s777tt
---

# ❓ E-OS FAQ

### Is E-OS an original, from-scratch operating system?

**No — and it doesn't claim to be.** E-OS is a **downstream distribution of
[Redox OS](https://www.redox-os.org)**, a Rust microkernel OS by Jeremy Soller
and the Redox community. E-OS's contribution is the *distribution*: curation,
hardening, branding, tooling and documentation. Upstream gets permanent credit
(see [`../NOTICE`](../../NOTICE) and the README).

### What's the relationship to Redox, exactly?

E-OS **re-bases** on current upstream Redox rather than forking and drifting. The
kernel, relibc, RedoxFS, drivers and build system are Redox's; E-OS layers its
identity and roadmap on top. This keeps us current and gives full credit.

### Why was the old 2019 content replaced?

The original repos mirrored Redox ~0.5.0 (2019). The build system was rewritten
since (xargo → Podman, COSMIC desktop, RedoxFS rewrite), so the 2019 tree is
effectively unbuildable today. We archived it (`master`/`0.4.1` branches, tags
`0.0.1`–`0.5.0`) and re-founded on the modern base — see
[CHANGELOG](../../CHANGELOG.md) `v0.1.0`.

### Why AGPL-3.0 and not MIT like Redox?

To resist appropriation: AGPL requires anyone who modifies **or serves** E-OS to
publish their source. Redox's MIT code remains MIT (permits this); E-OS's own
work and the combined distribution are AGPL-3.0. See
[`../LICENSE`](../../LICENSE) and [`../NOTICE`](../../NOTICE).

### What hardware works?

Today: **x86_64 (UEFI)** under QEMU/KVM, with NVMe, e1000 networking, xHCI USB
and Intel HDA audio. Real-hardware and **aarch64** are on the
[roadmap](../../ROADMAP.md) (v0.4.0).

### How do I build / run it?

See **[getting-started.md](index.md)**. Short version:
`make CI=1 all` then `make qemu`. Remember the **`CI=1`** rule
([building.md](building.md)).

### It won't build / boot — help?

Check the troubleshooting table in **[building.md](building.md)**. The top two:
pass **`CI=1`**, and add yourself to the **`kvm`** group for `make qemu`.

### How can I contribute?

Read **[../CONTRIBUTING.md](../../CONTRIBUTING.md)**. Issues, PRs, docs and roadmap
ideas are all welcome. Contributions are licensed **AGPL-3.0-or-later**.

### Is E-OS production-ready?

**No.** It's **alpha** (v0.1.x). Great for learning, hacking and contributing —
not for daily/production use yet.

### Who makes E-OS?

Maintained by **Damian ([@Gh0s777tt](https://github.com/Gh0s777tt))**, building on
the work of the entire Redox OS community.
