---
title: Architecture
status: current
last-reviewed: 2026-08-30
owner: Gh0s777tt
---

# Architecture

This document describes what the code does, verified against the built image on 2026-08-30. Where a
diagram shows a boundary, that boundary exists in the source and the file:line is given.

## Contents

- [Component map](#component-map)
- [Boot flow](#boot-flow)
- [Update flow](#update-flow)
- [Data flow](#data-flow)
- [Trust boundaries](#trust-boundaries)
- [Build topology](#build-topology)

---

## Component map

E-OS is a microkernel system. The kernel provides scheduling, memory and IPC; **drivers,
filesystems, the RAID layer and the network stack are ordinary user-space processes**. A driver
fault does not take the kernel with it.

Resources are addressed as **schemes** — URL-like namespaces such as `file:`, `tcp:`, `display:`,
`proc:`. Access is granted per user by an explicit allowlist in `/etc/login_schemes.toml`.

```mermaid
graph TB
  subgraph K["Kernel — Rust, minimal TCB"]
    SCHED[scheduler] --- MEM[memory] --- IPC[scheme IPC]
  end

  subgraph D["User-space drivers — 16 processes"]
    PCID[pcid · pcid-spawner]
    NET["e1000d · rtl8168d · ixgbed<br/>virtio-netd · usbnetd"]
    USB["xhcid · usbctl · usbhubd<br/>usbhidd · usbscsid"]
    SND["ac97d · ihdad · sb16d · audiod"]
    VID["ihdgd · fbcond · vboxd"]
    IN[inputd]
  end

  subgraph S["System services"]
    FS["redoxfs<br/>+ raid1d"]
    NS["netstack · dhcpd · dns"]
    PTY[ptyd] 
    IPCD[ipcd]
  end

  subgraph U["User space"]
    ORB["orbital<br/>display server · WM · compositor"]
    LOG["orblogin · launcher · background"]
    APP["cosmic-edit · cosmic-files · cosmic-term<br/>netsurf-fb · eos-notes · eos-control"]
    CLI["ion · bash · nushell · pkg · installer"]
  end

  K --> D
  K --> S
  D --> S
  S --> ORB
  ORB --> LOG --> APP
  K --> CLI

  style K fill:#8b0000,stroke:#e50914,color:#fff
  style D fill:#4a1010,stroke:#c0392b,color:#fff
```

**Verified:** the driver list is `/lib/drivers` and `/usr/lib/drivers` in the built image; the
application list is `/usr/bin` plus `/ui/apps` launcher entries.

---

## Boot flow

The distinguishing property of E-OS: **the bootloader authenticates what it loads before it uses
it**. Not after, and not by magic bytes.

```mermaid
sequenceDiagram
    participant FW as UEFI firmware
    participant BL as bootloader.efi
    participant FS as RedoxFS
    participant K as kernel

    FW->>BL: verify Authenticode signature (+ SBAT revocation)
    Note over FW,BL: SBAT is stamped BEFORE signing —<br/>Authenticode covers the whole file
    BL->>FS: read kernel bytes
    BL->>FS: read kernel.sig
    alt signature missing
        BL--xBL: panic — refuse to boot unverified code
    end
    alt verification key is all zeros
        BL--xBL: panic — built without a boot key
    end
    BL->>BL: ed25519 verify over SHA-512(ROLE_KERNEL ‖ len_le ‖ data)
    BL->>BL: only now check ELF magic
    BL->>FS: read initfs + initfs.sig
    BL->>BL: same, with ROLE_INITFS — a signed initfs cannot verify as a kernel
    BL->>K: transfer control
    K->>K: start user-space drivers, then redoxfs, then orbital
```

**Source:** `eos-bootloader/src/main.rs:436-451` and `src/eos_boot_verify.rs:16-17, 49-56, 72-81`.

**Known weakness — closed.** The whole block is behind `#[cfg(feature = "verify-boot")]`, and the
feature is enabled only when `build/boot-signing/boot.pub.bin` exists
(`recipes/core/bootloader/recipe.toml:26-36`). Without that key the recipe now **refuses to
build**: it writes the reason to stderr and exits 1, unless `EOS_ALLOW_UNVERIFIED_BOOT=1` is set
explicitly.

It used to fail **open** — print a warning and build a bootloader that verifies nothing. That was
worse than it sounds: `scripts/eos-build.sh` pipes make through `tail`, so the warning never
reached the operator, and a machine without the key produced an image indistinguishable from a
verified one. Recorded as `C-2`; the fix asked for was exactly the explicit opt-in that is now
in place.

---

## Update flow

Complete, correct, and **switched off** on x86_64.

```mermaid
sequenceDiagram
    participant P as pkg (on device)
    participant R as package repository
    participant IMG as pinned keys in image

    P->>R: GET repo.toml + repo.toml.sig
    P->>IMG: read /etc/pkg/eos-repo-sign.pub.toml
    P->>P: verify hybrid ed25519 + ML-DSA-65
    alt signature missing or invalid
        P--xP: RepoManifestUnsigned / SigInvalid — refuse
    end
    P->>P: check serial >= watermark (rollback)
    P->>P: check expires > now (freeze)
    P->>R: GET <package>.pkgar
    P->>P: blake3(package header) == entry in verified index
    alt mismatch
        P--xP: ManifestHashMismatch — refuse, do not extract
    end
    P->>IMG: read [pubkeys.local] from /etc/pkg/packages.toml
    P->>P: verify per-package ed25519 signature
    P->>P: extract
```

**Two facts that belong together.** The mechanism above is real and tested (33 tests in
`eos-pkgutils`). And **both entries in `/etc/pkg.d/` are commented out**, so on x86_64 no update can
occur at all. The aarch64 channel is published but its live index predates `serial`/`expires`.
Tracked as `C-4` and `C-12`.

The index-enforcement exemption is load-bearing rather than lax: during an image build
`redox_installer` has already written the pinned key into the new sysroot while `repo.toml.sig` does
not exist yet, so a source with no remotes is exempt. Without that exemption every build would fail.
It is a named function with its own test so it is not deleted as redundant.

---

## Data flow

```mermaid
graph LR
  subgraph DEV["Device"]
    APPD[application] -->|scheme call| KERN[kernel]
    KERN -->|file:| RFS[redoxfs]
    RFS -->|AES-XTS if enabled| DISK[(disk)]
    KERN -->|tcp: udp: icmp:| NSTK[netstack]
    NSTK --> NIC[network driver]
  end

  subgraph OFF["Off device"]
    NIC -->|TLS: rustls in pkg<br/>OpenSSL 3.5.3 in curl/git| NET((network))
  end

  style DISK fill:#1a1a1a,stroke:#555,color:#aaa
```

- **At rest:** AES-XTS in RedoxFS, offered by the installer, **not on by default**. Hardware
  accelerated on aarch64; software path on x86_64. The key-derivation function has **not** been
  audited — recorded as an open question.
- **In transit:** `pkg` uses rustls (currently carrying `rustls-webpki 0.103.4` with six advisories,
  finding `C-3`); `curl`, `git` and `wget` use OpenSSL 3.5.3.
- **Passwords:** argon2id, `m=19456, t=2, p=1`, in `/etc/shadow`.

---

## Trust boundaries

```mermaid
graph TD
  UP["static.redox-os.org<br/><b>PINNED</b> — key pinned in-tree at keys/upstream-redox-pkg.pub.toml"]:::warn
  MIR["github.com/Gh0s777tt mirror<br/>22 of 26 recipes fetch from here"]:::warn
  BLD["build machine<br/>4 private keys live here"]:::warn
  IMGX["signed image + pinned keys"]:::ok
  DEVU["device — user account<br/>25 schemes, no raw IP, <b>no sandbox</b>"]:::warn
  DEVR["device — root"]:::ok

  UP -->|30 of 65 packages<br/>as prebuilt binaries| BLD
  MIR -->|source for 22 recipes| BLD
  BLD -->|ed25519 + hybrid PQ signatures| IMGX
  IMGX --> DEVR
  DEVR -->|login_schemes.toml| DEVU

  classDef ok fill:#14532d,stroke:#22c55e,color:#fff
  classDef warn fill:#4a3410,stroke:#d97706,color:#fff
  classDef bad fill:#4a1010,stroke:#dc2626,color:#fff
```

| Boundary | Enforced by | State |
|---|---|---|
| Firmware → bootloader | Authenticode + SBAT | **enforced** |
| Bootloader → kernel/initfs | ed25519 with domain separation | **enforced**, fail-closed at runtime **and** at build time — a missing key aborts the bootloader build unless `EOS_ALLOW_UNVERIFIED_BOOT=1` (`C-2`) |
| Repository → device | hybrid signature + pinned key + blake3 on bytes + serial/expires | **enforced**, currently unused (`C-4`) |
| Upstream binaries → build | key pinned in-tree at `keys/upstream-redox-pkg.pub.toml`, written over whatever `sync_keys()` fetches | **partly enforced** — the key no longer comes from the serving host; the binaries themselves are still upstream's (`C-1`) |
| Source mirror → build | nothing compares GitLab and GitHub heads | **not enforced** |
| root → user | `/etc/login_schemes.toml` allowlist, `ip` removed | **enforced per account** |
| application → application | — | **absent** (`C-5`) |

The weakest link is at the **start** of the chain, not the end. Layers 3–5 are carefully built and
work; the entry — fetching upstream binaries and sources from a mirror — has no anchor.

---

## Build topology

```mermaid
graph LR
  REPO["E-OS repo<br/>recipes · config · cookbook"] -->|eos-sync-buildtree.sh| VOL[(podman volume<br/>eos-work)]
  VOL -->|make in container| PKGS["85 .pkgar packages"]
  PKGS -->|repo_builder| IDX["repo.toml + serial"]
  IDX -->|eos-repo-sign| SIG["repo.toml.sig<br/>ed25519 + ML-DSA-65"]
  PKGS --> IMGB["harddrive.img · live.iso"]
  IMGB -->|sbsign| SB["Secure Boot signed EFI"]
```

The checkout lives on exFAT, which podman cannot bind-mount, so the build tree is a **separate git
history inside a podman volume**. Two consequences that have both caused real defects: `make` from
the project directory does not work, and anything counting commits inside the container counts the
wrong history (which is why the index `serial` is computed on the host).
