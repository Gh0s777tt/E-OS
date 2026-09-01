---
title: E-OS Threat Model
status: current
last-reviewed: 2026-08-30
owner: Gh0s777tt
---

# 🛡️ E-OS Threat Model

> Status: **v3 (alpha)** · revised 2026-08-30 · applies to E-OS `0.2.x`. E-OS is a
> downstream of [Redox OS](https://www.redox-os.org); this model builds on Redox's
> microkernel and capability design. Companion docs: [Hardening Guide](hardening.md) ·
> [Disk Encryption](../guides/encryption.md) · [Security Policy](../../SECURITY.md).

This document states **what E-OS protects, from whom, and how** — and, just as
importantly, what it does **not** yet protect. It is a living document; pre-1.0
E-OS makes **no stability or completeness guarantees**.

**What changed in v3, and why it is written as a revision rather than a rewrite.**
Almost everything §1–§6 said about the *running system* survived re-checking and is left
standing; **two carried-over statements did not**, and both are corrected in place with the
old wording named rather than quietly dropped (CLAUDE.md §2, rule 4) — §3 called the
CycloneDX document a *per-package* SBOM when it is per-**image**, and §6 illustrated the
"we do not fix upstream's gaps" non-goal with `R-401b`, a bug that has been **closed since
2026-06-08**. What v2 did not model at all is the **path that produces the image** — the
signing keys, the machine they live on, and the gates that were supposed to be watching.
Three findings from the 2026-08-30 security audit forced that gap open: `C-1` (the
package-signing key was trust-on-first-use — now closed, §7.1), `C-7` (every CI gate had
been dead since 2026-08-28, so *"CI catches this"* was not a mitigation for anything in
that window, §7.2) and `C-11` (the signing keys sit on the machine that runs CI, §7.3).
Those live in a new §7. §2 gains the trust boundaries that actually authenticate
something, §8 says what was deliberately **not** examined. Section numbers 1–6 are
unchanged on purpose: other documents cite them.

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

### 2.1 The boundaries that actually authenticate something

The diagram above is about *authority at runtime*. It says nothing about **where the bits
came from**, which is the boundary an attacker on the supply chain crosses. There are six
such boundaries in E-OS today, and they are listed with their real state rather than their
intended one — the intended one is what a threat model is for, and it is not evidence.

| Boundary | What it authenticates | Where enforced | State (checked 2026-08-30) |
|---|---|---|---|
| **Per-package pkgar signature** | Each `.pkgar` — ed25519 + blake3, checked **before commit** | `eos-pkgar` / `pkg-lib` in the image | **Enforced.** The one link that never depended on the index, and the reason a TOFU key was a first-contact problem rather than a total one. |
| **Signed package index (hybrid)** | `repo.toml` lists every package's blake3, so one signature over it authenticates the whole repo. Signed ed25519 **+ ML-DSA-65** (FIPS 204) by `tools/eos-repo-sign` | publisher: `scripts/publish-repo-pages.sh`; client: `pkg-lib` `manifest_sig::verify_manifest_ed25519` reached from `verify_repo_manifest` | **ed25519 enforced and fail-closed once a key is pinned** (missing `.sig` → `RepoManifestUnsigned`, bad `.sig` → `RepoManifestSigInvalid`). **The ML-DSA-65 half is carried but verified by no client** — post-quantum coverage is a publish-side property today, not a client-side one. |
| **Pinned trust anchor** | Which key the two rows above are checked against | `/etc/pkg/eos-repo-sign.pub.toml`, baked into the image | **Pinned** — this is `C-1`, closed. See §7.1 for what pinning does and does not buy. |
| **minisign release checksums** | The images a human downloads — `SHA256SUMS` + `SHA256SUMS.minisig`, key `keys/eos-release.pub` | `scripts/make-release.sh`; verified by the downloader, by hand | **Works, and is a different key for a different job.** It does not authenticate packages, and the package key does not authenticate releases. Conflating the two is the mistake `keys/README.md` §1–§2 exists to prevent. |
| **Secure Boot + SBAT** | firmware → `bootloader.efi`, signed `sbsign` with an operator-held key (ADR-0005); `scripts/eos-add-sbat.py` adds an `.sbat` section so E-OS owns a **revocation lane** instead of waiting on a DBX entry only Microsoft can publish (ADR-0006) | UEFI firmware | **Proven under QEMU with real edk2 firmware** — `scripts/eos-secureboot-proof.sh` runs three cases including the negative ones. It requires the **machine owner** to enroll the key (or aarch64, where the owner already owns the trust store). |
| **Boot verification** | bootloader → kernel + `initfs`, Ed25519 over a domain-separated SHA-512 (`V2-MS02`) | `eos-bootloader` | **Proven** by `scripts/eos-boot-verify-proof.sh` (good image boots, one flipped kernel byte is refused). §6 states in detail what this does **not** buy — read that before quoting this row. |

The first three rows are one chain, and a chain has the strength of its weakest link, not
the sum of its links: a pinned key is worth nothing if the source it guards is never
enabled, and an enabled source is worth nothing if the key is not pinned. `ci-integrity.sh`
check 9 encodes exactly that pairing — an image config carrying an **active** E-OS package
remote must also pin the key, or the gate fails.

## 3. Adversaries & what each can do

| Adversary | Assumed capability | Primary defense |
|---|---|---|
| **Remote network** | Sends packets to exposed services | Network stack runs **in userspace** (a crash/compromise is contained, not kernel-level); minimize exposed services (see hardening). |
| **Local unprivileged process** | Runs as a normal user | **Capability schemes** — a process only reaches the schemes in its namespace; Rust memory-safety removes whole bug classes; user/root separation. |
| **Malicious/compromised driver** | A buggy device driver | **Partial.** At the *syscall* level: userspace, confined to its scheme, no ambient kernel authority. At the *bus* level: **none** — there is no IOMMU, so the driver can programme its device to DMA anywhere in physical memory. See §6. |
| **Physical / lost device** | Has the powered-off disk | **RedoxFS AES-XTS-128 full-disk encryption** (opt-in at install, see encryption.md). |
| **Supply chain — the delivery channel** | Controls the host serving packages, or sits on the wire | **Now real, and it was not in v2.** Per-package pkgar ed25519 always held; the *index* is signed and the verifying key is **pinned in the image** rather than fetched from the package host (§7.1, `C-1`). Residual: rollback/freeze — an older correctly-signed index still verifies. |
| **Supply chain — the sources** | Tampers with sources/deps | Recipes pinned to **E-OS source forks**; a per-**image** CycloneDX **SBOM** (one component per shipped package, `scripts/gen-sbom.py` — not one document per package; see §8 for how stale it is); **signed** release checksums. Toolchain and CI helper binaries are SHA256-pinned download-verify-extract, never `curl \| sh` / `curl \| tar`. **Reproducibility is claimed nowhere here**: nobody has yet built the same commit twice and compared, so it is an aim, not a defense (§8). |
| **Supply chain — the build machine** | Has, or gets, code execution on the host that builds and signs | **Weak, and stated plainly.** The signing keys and the CI runner are the same machine (§7.3, `C-11`). There is no HSM, no separate signer, no attestation of the builder. |

## 4. Attack surface (and the mitigation that covers it)

- **Syscalls / scheme IPC** → small kernel surface; Rust-implemented; capability-checked.
- **Userspace network stack** (`smoltcp`/netstack) → isolated process; no kernel network code.
- **Drivers** (nvmed, e1000d, xhcid, …) → userspace, per-scheme confinement.
- **Bootloader** → built from source (E-OS fork), verifiable; handles the encrypted-disk password prompt.
- **Login / auth** → `redox_users` with **argon2** password hashing; per-user scheme namespaces (`/etc/login_schemes.toml`).
- **Privileged GUI actions** (`eos-power`, the control-panel reboot/shutdown) → `sys:kstop` is root-only, and the GUI runs as the desktop user. Rather than run the GUI as root, a **short-lived `eos-power` shim** elevates via `/scheme/sudo` (the same daemon `sudo` uses — it checks sudo-group membership **and** the user's password, which the GUI pipes on the shim's **stdin**, never argv, so it never appears in `ps`) and then does exactly one thing: write `sys:kstop`. Blast radius even if the shim were abused is a **local reboot/poweroff** — and it still requires the user's password plus local access, which a password-holding user could already spend on `sudo shutdown`. The GUI process itself is **never elevated**; the password is held only transiently in the GUI and cleared after use. See `docs/architecture/eos-power.md`.
- **Package install / update path** → per-package pkgar ed25519 + blake3, over an index signed
  by a key **pinned in the image** (§2.1, §7.1). The x86_64 image does not enable an E-OS
  package source at all today, so on that arch this surface is currently closed by absence
  rather than by verification — which is a weaker statement and is meant to be.
- **Build pipeline** → pinned forks + SBOM + checksums + minisign release signing. Its own
  attack surface — the runner, the keys on it, and the gates that were not running — is
  §7, not this list. A pipeline is not only a mitigation; it is also a target.

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
- **Mitigation of upstream gaps.** E-OS does not undertake to fix what it inherits. The
  standing example is upstream's own `//TODO (hangs on real hardware): Dmar::init(&this);`
  in `eos-base` — an IOMMU that upstream disabled and E-OS has not re-enabled (see the DMA
  bullet below). *Corrected in v3 (CLAUDE.md §2, rule 4): this bullet used to cite the
  aarch64 root-mount bug `R-401b`, which is **closed** — it was the last symptom of a
  four-layer `RNDRRS` cascade fixed in the kernel and base forks on 2026-06-08. A non-goal
  illustrated by a resolved bug reads as a live risk that is not there.*
- Protection against an attacker with **persistent privileged runtime access**.
- **A safe scratch directory for package downloads.** The 2026-08-30 audit records, in its
  appendix, a fixed-path download directory (`/tmp/pkg_download`) reachable by an
  unprivileged local user, giving an **arbitrary root-owned write** when `pkg` runs as root:
  the classic shape is a pre-created path or symlink that the privileged process then writes
  through. Two things must be said about this entry and both matter:
  - **It is recorded here, not confirmed here.** The code is in the `eos-pkgutils` fork, which
    is not part of this tree — a grep of the meta repo for `pkg_download` returns **zero
    hits**, and in this project that is not evidence of anything (the same mistake cost
    `U-126`/`U-134` a published, wrong conclusion about `verify_manifest`). Treat it as an
    open finding awaiting verification **in the fork**, at the pinned revision, with the
    negative control run.
  - It is a **local privilege-escalation** boundary, not a supply-chain one. The signature
    checks in §2.1 are irrelevant to it: the bytes are authentic, the *path they land on* is
    the defect. Pinning a key does not close it.
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

## 7. The release path is inside the TCB

§1 lists the build/supply chain as an asset and §2 draws no boundary around it. That was the
omission. Everything a user installs is authenticated by keys that one person holds, on one
machine, and validated by gates that run — or do not — on that same machine. The three
findings below are what that costs, stated as they were found.

### 7.1 `C-1` — the package key was trust-on-first-use. It is now pinned.

**What it was.** `pkg-lib`'s `add_remote` set `pubkey: None` and fetched
`id_ed25519.pub.toml` **from the same host that serves the packages**. An attacker holding
that endpoint — a hostile mirror, a MITM, a compromised Pages account — supplies their own
key *and* packages signed with it, and every per-package signature checks out perfectly
against the wrong root. The per-package ed25519 was never the weak link; the question *which
key* was. The installer path already pinned a key (`installer_key`); only the **post-install
remote path** was unpinned — which is exactly the path `pkg update` and the future driver
manager use. This is `M-02` of AUDIT-2026-07-13 restated by the 2026-08-30 audit as `C-1`.

**Where that paragraph comes from, per §8's own rule.** The `add_remote` behaviour is code in
the `eos-pkgutils` fork and **cannot be grepped from this tree** — it is taken from
`ROADMAP.md` `R-702`/`R-703`, and it is corroborated by the half that *is* here: `M-02` is
filed against `scripts/publish-repo-pages.sh`, which stages `build/id_ed25519.pub.toml` next
to the very packages it authenticates. Note also that the fork revision is recorded
inconsistently in this repo — `ROADMAP.md` `R-703` says `eos-pkgutils@14505ecd`, while
`recipes/core/pkgutils/recipe.toml` pins `e28063ee`. Re-read the client code at the recipe's
revision before quoting this paragraph as current.

**What closed it, and how far.** The public half of the hybrid key
(`keys/eos-repo-sign.pub.toml`, ed25519 + ML-DSA-65) is generated by the operator with
`scripts/eos-key-bootstrap.sh` and embedded **inline** into `config/{aarch64,x86_64}/eos.toml`
by `scripts/eos-pin-repo-key.sh`, landing at `/etc/pkg/eos-repo-sign.pub.toml` — the path
`pkg-lib`'s `REPO_SIGN_PUBKEY_PATH` actually reads. A key sitting in `keys/` alone changes
nothing at runtime; the install step is the fix, not book-keeping. Measured in a **running
image** (`U-197`): the file is present at **4075 B**, byte-identical to the repo copy, and
the `no pinned repo-manifest key` warning is gone from the log. Once a key is present,
`verify_repo_manifest` **fails closed** — a missing `repo.toml.sig` is `RepoManifestUnsigned`,
an invalid one `RepoManifestSigInvalid` — rather than warning and proceeding.

**What is still not proven, said in the same breath.** Three things:

- **The fail-closed path has never been exercised by a client.** The absence of a warning is
  not the presence of a verification: `pkg list` reads local packages. Be precise about which
  half is missing, because the other half is done: `R-008`/`U-209` published a **live signed
  repo** — `publish-repo-pages.sh aarch64-unknown-redox` signed `repo.toml` hybrid (ed25519
  64 B + ML-DSA-65 3309 B) and put **78 packages, 893 MB** on Pages, with `repo.toml`,
  `repo.toml.sig` and `eos-repo-sign.pub.toml` all returning HTTP 200. What is still owed is
  the **client** half: an image with the active `50_eos` that boots, fetches from that host,
  and *refuses* a tampered index. `U-210` records that as the next step and says what it
  costs — an aarch64 rebuild plus QEMU with outbound network — and that it will be settled by
  booting, not by assuming. Nothing has been run against it yet, at any layer.
- **The two architectures are not in the same state.** `config/aarch64/eos.toml` ships an
  **active** `/etc/pkg.d/50_eos`; `config/x86_64/eos.toml` still ships it **commented out**,
  because that repo is not published. x86_64 is protected by having no source, not by
  verification.
- **Rollback and freeze are untouched.** A correctly signed *older* index still verifies.
  There is no anti-rollback and no timestamp/expiry.

**One correction that belongs in the record** (CLAUDE.md §2, rule 4): `keys/README.md` §2
still heads the trust anchor *"Trust anchor (R-702) — THE ONE MISSING PIECE"* and states
*"What does **not** exist is `eos-repo-sign.pub.toml` — this directory holds only
`eos-release.pub`"*. Both sentences were true when written and are **no longer true** —
`keys/eos-repo-sign.pub.toml` is 4075 B in that same directory, both image configs carry it
inline, and `ci-integrity.sh` check 9 enforces the pairing. `keys/README.md` needs the same
correction this section just made; do not cite it as current for `C-1`.

### 7.2 `C-7` — "CI catches this" was not a mitigation, and still needs care as one

Since **2026-08-28** every GitLab job has failed in roughly **0 s** with
`ci_quota_exceeded` — free-tier minutes exhausted, the light tier dead, `pages` surfacing it
first as `stuck_pending_no_matching_runners` (`docs/operations/ci.md`). The jobs still *appear* in the
pipeline list. That is the dangerous part: a red that means "nothing ran" reads, at a glance,
like a red that means "something was measured and failed", and a skipped stage reads like a
passed one.

**Consequence for this document, applied backwards.** Any mitigation of the form *the gate
catches it* — secret scanning on full history, `cargo-deny check advisories`, `pins --strict`,
`ci-integrity.sh`, shellcheck, the coverage floor — **was not in force** for anything merged
in that window. Every such claim in a security document has a start date and an end date, and
this one has both. Assume commits landed in that window unmeasured, and re-run the gates over
that range rather than trusting the pipeline history.

**What actually gated during the window**, since something must be said and it should not be
optimistic: the **local hooks** (`lefthook.yml` — `gitleaks` fails closed on `pre-commit`,
`clippy -D warnings` and `ci-integrity.sh` on `pre-push`), which are **opt-in** and require
`lefthook install`; and the self-hosted `eos-heavy` jobs, which carry `needs: []` precisely so
a quota-exhausted light tier cannot skip them — but which need a runner attached, and `U-152`
records that none currently is.

**Do not treat the GitHub Actions suite as the closure of this window.** GitHub Actions does
not execute for this repository — established by experiment on 2026-08-30, not assumed: a
minimal `on: push` workflow, pushed straight to github.com on a fresh branch, produced **no
workflow run at all**. The workflows are correct and reviewable; they are not, today,
evidence that anything ran. The only verification available for them right now is `actionlint`
and local `act` runs (which cannot exercise harden-runner, CodeQL, Pages deploy, cosign OIDC or
release-please). A gate nobody has seen fail is not a gate — CLAUDE.md §4.1 — and a gate that
cannot execute is not one either.

### 7.3 `C-11` — the signing keys live on the machine that runs CI

The heavy CI tier runs on a runner tagged `eos-heavy`, which is the maintainer's Mac, with a
**shell executor** — job steps run as that user on that host, not inside a disposable
container. The same host holds the signing material:

- **Package/index signing.** `scripts/eos-key-bootstrap.sh` defaults the secret half to
  `$HOME/.eos-keys/eos-repo-sign.secret.toml` (mode `0600`, off-repo, on the internal disk —
  deliberately off the exFAT project volume, which stores no POSIX permissions at all).
- **Secure Boot signing.** `scripts/eos-sb-setup-key.sh` **copies** the operator's `mok.key`
  to `/work/redox/build/sb-signing/mok.key`, because the bootloader recipe signs from there
  during `cook`. That path is not incidental to CI, and the chain is readable in this tree:
  the script writes into podman volume `eos-work` (`scripts/eos-sb-setup-key.sh:18`),
  `scripts/eos-container-setup.sh:51,118` builds the `eosbuild` container with that same
  volume mounted at `/work`, and the `build-image` job runs `make` inside `eosbuild` at
  `/work/redox` (`.gitlab-ci.yml:382`). So the key sits in a filesystem the CI job's own
  container has mounted — read from the tree, not observed on the runner. It is removed only
  by an explicit `--clear`; a key left behind after a build stays there.
- **The package-repo signing key** used for the 78 already-published packages exists in
  `build/id_ed25519.toml` in the build volume, in **one copy, with no backup** (CLAUDE.md
  §21.2/§21.3).

**The threat this creates.** Any code that reaches execution on that runner — a malicious
merge request that a shell-executor job runs, a compromised dependency of a build script, a
compromised container image pulled by the build — can read the key and sign anything E-OS
will ever ship. There is no HSM, no separate signing host, no attestation of the builder,
and no way for a client to tell a key used on a clean build from the same key used on a
compromised one. Both `CLAUDE.md` §14 and this model name **HSM or Vault** as the target;
until then the compensating controls are the honest ones and they are administrative, not
technical: key generation is a deliberate **human** act that never passes through tooling
that logs (CLAUDE.md §10.1, which §14 points at for exactly this), `ci-integrity.sh` check 10
fails if secret material of the right *shape* ever becomes tracked (it checks the material,
not the filename), and the pinned public half means a rotation invalidates every client that
pinned the old one — which is a cost, not a control.

**Loss of the key is not recoverable.** `eos-repo-sign keygen` refuses to overwrite an
existing file, so the key cannot be "regenerated in place"; losing it means re-imaging every
client that pinned the public half.

## 8. Out of scope, and what is unverified

A threat model that does not say where it stopped looking implies it looked everywhere. It
did not.

**Deliberately out of scope for this document and for the audits behind it:**

- **Upstream Redox code.** AUDIT-2026-07-13 audited the **E-OS-authored surface only** and
  skipped 3347 files of the vendored upstream cookbook, on purpose. §5's "inherited
  strengths" are inherited **claims** as much as inherited code.
- **The vendored `src/` cookbook**, by the same rule and by an explicit strictness split: the
  root manifest gets `cargo test` + `cargo-deny check advisories` only, while
  `tools/eos-repo-sign` gets fmt, `clippy -D warnings`, tests, full `cargo-deny` and a
  coverage floor. Licences and sources on vendored code are upstream's choices; gating them
  would mean re-litigating a tree we do not own (ADR-0003).
- **Fork code is not in this tree.** `eos-kernel`, `eos-base`, `eos-pkgutils`, `eos-pkgar`,
  `eos-redoxfs` and the rest live in their own repositories. A grep here cannot see them, and
  this project has now made that exact error three times, each time concluding *absence* from
  a search that could not have seen the thing (`U-126` cited `src/base-drivers/*`, a path that
  was never versioned; `U-126`/`U-134` declared `pkg-lib` had no `verify_manifest` after
  grepping the meta repo, which does not contain `pkg-lib`; `U-224` declared the index-signing
  secret key non-existent after looking in `keys/`, while it sits in the operator's off-repo
  store, exactly where it belongs). Anything asserted about `pkg-lib` or a driver in this
  document is sourced from a **pinned revision of the fork**, and is flagged where it is not.
- **Fuzzing and `miri`.** Both deliberately skipped *here*: the parsers worth fuzzing
  (`pkgar`, RedoxFS, `redox_installer`) live in forks, and E-OS-authored Rust in this repo
  contains zero `unsafe` blocks (`ci-integrity.sh` check 4).

**Known-unverified, and not to be quoted as done:**

- **Build reproducibility.** The obstacles were removed (`.config` and `cookbook.lock` are
  tracked) but **the comparison has never been run**. Until someone builds one commit twice
  and diffs the images, "reproducible" is an aim.
- **Client-side signature verification against a live source** (§7.1). Say this one exactly:
  the *publisher* side is live and measured (`R-008`/`U-209` — signed index, 78 packages,
  HTTP 200), and `50_eos` is active in `config/aarch64/eos.toml`, but **no client run has
  been attempted at all** — not a fetch, not a partial one. `U-210` states plainly that the
  image with the active source has not been rebuilt or booted against the live host yet.
  Nothing here should be read as a partially-completed verification.
- **The `/tmp/pkg_download` finding** (§6) — recorded from the audit appendix, not
  reproduced against the fork.
- **x86_64 on real hardware.** Scope this carefully, because the wider claim is false and has
  already cost this project once: x86_64 **has** been built and booted on this host — first in
  `U-169`, measured in `U-172`, with `boot-smoke` reaching a login prompt — and `U-189` had to
  strike the *"not on this aarch64 build host"* sentence out of `config/x86_64/eos.toml`
  precisely because that stale line was the stated reason nobody exercised x86_64. What is
  unverified is narrower and real: every one of those runs was under **TCG emulation**,
  `build-image-x86_64` is `manual` and non-blocking, and no x86_64 boot has happened on
  physical firmware — that is blocked on a rig which is not the development machine.
- **Image SBOMs.** `build-image` does regenerate one from the cooked package metadata
  (`scripts/gen-sbom.py`, `.gitlab-ci.yml:387`), so "produced by hand" is not the whole
  story — but it is emitted as a **pipeline artefact and never committed**, and it runs only
  on the `eos-heavy` runner, which is tag-manual or scheduled and has no runner attached
  (§7.2). The consequence is what matters: `sbom/` still holds `0.1.0` documents only, while
  `v0.2.0` shipped, and nothing guarantees one exists per shipped version.

The 2026-08-30 security audit is cited above by finding ID (`C-1`, `C-7`, `C-11`). **That
audit page is not committed to this tree** — `docs/audit/` currently holds only
`AUDIT-2026-07-13.md` and `AUDIT-2026-08-14.md` — so these IDs cannot be followed to their
evidence from here. Commit the audit, or the IDs in this section are labels rather than
citations.

Treat E-OS today as a **research / enthusiast** system. Report issues privately
per the [Security Policy](../../SECURITY.md).
