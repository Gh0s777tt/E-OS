# 🗺️ The plan — editions, compartmentalisation, and the order to build them in

> **What this is.** `ROADMAP.md` lists *items*. This document answers the three questions the
> item list cannot: **who is E-OS for**, **what security model are we actually building**, and
> **in what order**, because for several of these the order *is* the control. Written
> 2026-08-22 (`U-142`) from the audit recorded in `U-141`; every claim below was checked in
> the tree or against a live API, and where something is unverified it says so.

---

## 1. Where the project actually stands

E-OS is a hardened Redox downstream with a **real, verified desktop on aarch64 under QEMU** —
not a prototype, and not something anyone has booted on metal. The hardening is in the code,
not just the prose: `overflow-checks` across kernel/relibc/base, mmap ASLR with guard bands,
W⊕X at the syscall boundary, AES-XTS FDE with ARMv8 crypto extensions, and scheme namespaces
as a working unprivileged confinement primitive.

Three things are missing, and they are not features:

1. **The trust chain is open at both ends.** No `keys/eos-repo-sign.pub.toml` exists, and every
   shipped image still carries `/etc/pkg.d/50_redox → https://static.redox-os.org/pkg`
   (`config/base.toml:120-121`) — so `pkg install` fetches upstream binaries built without
   E-OS flags, over a TOFU-keyed channel.
2. **Nothing gates `main`.** `only_allow_merge_if_pipeline_succeeds = false`, **0 merge
   requests** across 10 088 commits. Every CI job reports *after* the push.
3. **Zero real hardware.** Every boot claim is QEMU.

---

## 2. Three editions, one base

The same base, three package sets and three defaults. Not three forks.

### 2.1 Desktop (the current product)

Closest to shipping. What an ordinary user will miss on day one, none of which has a roadmap
item today: **removable-media automount** (`usbscsid` exists; nothing mounts a stick),
**printing**, **accessibility and UI scaling**, **screen brightness**, **backup/restore and a
recovery path**, **a trash/undelete**, and **an i18n string catalogue** — the UI already ships
hard-coded Polish strings (`eos-control settings.rs`) while the docs are English.

> Note for anyone reading old notes: there is **no i18n gate in `CLAUDE.md`**. An earlier
> version of `docs/reality-ledger.md` claimed there was; it was fabricated (see `U-126`).
> i18n is work to *schedule*, not a rule being violated.

### 2.2 Gaming (honest position: not yet possible)

**E-OS does not run games, and the roadmap should say so out loud.** The blocker is not 3D
alone — it is a chain, and every link is missing:

| Link | State |
|---|---|
| Linux ABI compatibility, or native ports | none, and no item |
| GPU acceleration (GEM/dma-fence class layer) | none — `R-930` documents the absence |
| Gamepad input | none — `usbhidd` covers keyboard/mouse |
| Low-latency audio | `ihdad` times out on the codec RIRB response and `audiod` exits |

Two design decisions worth taking **now**, while they are cheap: treat executable memory as a
capability (a JIT needs it; a text editor must not have it), and treat GPU passthrough as
gated on IOMMU rather than something to bolt on later.

### 2.3 Server (does not exist yet — and the placeholder is dangerous)

There is **no server edition**: no `config/*/eos-server.toml`, no roadmap item, no headless
boot-smoke. What *does* sit next to `eos.toml` is `config/x86_64/server-demo.toml` with
`PermitRootLogin yes`, `PasswordAuthentication yes` and `PermitEmptyPasswords yes` — one
syllable away from the real config. Worse, `config/desktop.toml:3` does
`include = [..., "server.toml"]`, so the desktop image pulls the server package set.

Three things a server edition needs that the desktop does not:

- **Unattended install.** `R-602`'s OOBE forces `passwd` before a shell on *every* path — correct
  for a desktop, fatal for a server that must boot without a human at the console. The rule to
  add: an account seeded with a public key and a locked password **satisfies** R-602.
- **A firewall.** `R-904` is `P1` for the desktop; for a server it is `P0`.
- **Its own boot-smoke** asserting a headless console and `sshd`, not a greeter.

---

## 3. Compartmentalisation: what transfers from Qubes and Tails, and what does not

The scheme model reproduces most of Qubes' **visibility** model without a hypervisor. It does
**not** reproduce its **hardware** isolation. That distinction has to be written down before
anyone puts "Qubes-like" in a README.

### 3.1 The asset already in the tree

`recipes/core/contain` exists and `config/desktop-contain.toml` is a complete sandboxed
session: `contain_orblogin`, `getty --contain`, and an `/etc/contain.toml` that passes a
narrow scheme set (`rand null tcp udp thisproc pty orbital display.vesa`), **brokers** the
file scheme (`sandbox_schemes = ["file"]` — mediated, not handed over) and allowlists paths
via `files`/`rofiles`/`dirs`/`rodirs`.

It is **disabled**: `config/server.toml:14` reads `#contain = {} # needs to update
dependencies`, the recipe has no `rev`, and no `contain.pkgar` is in the built repo. This is
the single largest unused asset the audit found — a working AppVM-equivalent, switched off.

### 3.2 The mapping

| Qubes / Tails pattern | Equivalent here | Blocker |
|---|---|---|
| **AppVM compartment** | `contain` — already built, see above | Package disabled, recipe unpinned |
| **Per-application namespace** | `Namespace::fork()` + `NsDup::IssueRegister` — kernel side complete and unprivileged | The namespace is set **once per session** in `login.rs`, so every app inherits the user's full authority. Needs a policy layer (`/etc/eos/appns.d/<app>.toml`) in the launcher |
| **qrexec / split-GPG** | Already done twice: `eos-power`, `eos-netcfg` — a narrow named channel with policy instead of ambient authority. Generalise into an `eos-broker` convention | Clipboard and file transfer between compartments — the usual leak path — do not exist |
| **Network qube** | `netstack` is *already* a separate user-space process. A second instance on another interface, bound under `tcp`/`udp` in a narrower namespace, gives "this app only goes through the VPN" with no VM | Zero filtering (`R-904`), and `ip` sits in the user namespace |
| **Driver domains** | Drivers are separate processes — but without an IOMMU this is logical isolation, not hardware isolation | `Dmar::init` is commented out; no `iommu`/`smmu` path in the kernel. `R-F13` |
| **USB qube** | **Not reachable** — it depends on handing a controller to a VM behind an IOMMU. Do **not** fake it. The achievable version gates *trust*, not isolation: `eos-devd` asks before binding a driver to a newly-attached HID or mass-storage device. That stops BadUSB, which is the realistic home scenario | `R-801` |
| **dom0 has no network** | Structurally satisfied — the microkernel + `initnsmgr` + bootloader contain no network code and nowhere to run a browser. Name this as a microkernel advantage rather than importing an operational rule with no referent here | nothing |
| **Tails: amnesia** | **Already built**, as a side effect of the live image — the bootloader copies ~1.4 GB into RAM, verified on both arches (`U-133`). What is missing is making it a *product*: an `eos-live-amnesic` variant that mounts no host disk, says so on the login screen, and uses an ephemeral key for `/tmp` and `$HOME` | none — high value, low cost |
| **Tails: MAC randomisation** | `ifaces/<if>/mac` is writable with validation, and the privileged `eos-netcfg` shim already exists and is screen-verified | Needs a `randomize-mac` subcommand and a toggle; the interface name is hard-coded |
| **Tails: persistent volume** | A second RedoxFS under a **separate scheme name** (`file.persist`) — in Tails persistence is bind-mounts in a global namespace; here it is a capability an app either holds or does not. Simpler than the original | No notion of persistence in configs or GUI |
| **Tails: Tor by default** | — | **Do not promise this.** No tor port, no firewall, `ip` in the user namespace. Without all three it is a guarantee the system cannot keep, and the failure is silent — worse than not offering it |

### 3.3 The honest limit

Everything above is isolation **between processes of the same user**, enforced by the kernel's
scheme namespaces. It is *not* protection against a malicious driver reprogramming DMA, and it
is not a hypervisor boundary. Until there is an IOMMU, that sentence belongs in
`docs/threat-model.md` verbatim.

---

## 4. Order of work — and why this order

Several of these are only correct in sequence. Where that is true, the reason is stated.

| # | Step | Why here |
|---|---|---|
| 1 | Turn on **"pipelines must succeed"** and move work onto merge requests | Until something blocks `main`, every gate added below is a notification after the fact. It also wakes `docs-currency`, which has never run |
| 2 | **Delete `50_redox`** from the E-OS image config (`R-701a`) | Two lines, pure subtraction, independent of the key. Removes the one channel by which a shipped image undermines its own hardening. Holding it behind the whole trust chain is the same artificial dependency `U-137` removed from `R-803` |
| 3 | **Keygen → sign and publish indexes (`R-008`) → pin in configs (`R-702`) → enforce (`R-703`)** | Only this order is safe. Pinning flips `pkg-lib` to fail-closed, so every already-published index must be signed **before** an image carrying the pinned key reaches anyone. Reversed, it breaks updates for everybody |
| 4 | **Pins + `blake3` for the recipes that actually ship** (`R-F11`) | Right after (3), because a signature over content fetched without an integrity check is a signature over nothing. This is **13 packages of 74**, not 2051 — the tree-wide ratio is inherited third-party ports and out of scope |
| 5 | **Remove `ip`/`icmp` from `user_schemes.user`** (`config/base.toml:44-48`) | One line, boot-verifiable, and it must precede `R-904`: a firewall built while raw sockets sit in the user namespace is trivially bypassed |
| 6 | **`R-601` — install-to-second-disk harness** | First purely functional step. The only missing proof of the "daily driver" claim, and doable entirely on the current Mac |
| 7 | **Fork push-mirrors** (`eos-setup-mirrors.sh --apply`, excluding `role = "pkg"`) | Now, because pin bumps start flowing and manual double-pushes silently build stale code. The `eos-pkg-*` exception is mandatory or the mirror overwrites what (3) published |
| 8 | **`shellcheck` + `cargo-deny`/`cargo test` on the root manifest** (`R-F14`, `R-F15`) | After (1) so gates actually block, and after (6) so the first shellcheck run over 44 scripts lands with a baseline rather than mid-task |
| 9 | **Rewrite the security documents that overstate** | Here, because after eight steps most of those sentences need rewriting anyway — one pass instead of two. `U-141` already did the worst of it |
| 10 | **Enable `contain` and add per-application namespace policy** | The compartmentalisation work only means something once (2)-(5) closed the paths around it. Starting here would be building a wall with the gate open |

---

## 5. What we deliberately do not promise

Writing these down is part of the plan, because the failure mode of a security project is a
promise it cannot keep.

- **Not "Qubes-like".** No hypervisor, no IOMMU, no driver domains in the hardware sense.
- **Not "Tor by default".** See §3.2.
- **Not a gaming platform**, until the chain in §2.2 exists.
- **Not validated on hardware.** Every boot claim in this repo is QEMU until someone boots the
  live USB on the x86 rig and records what happened — including the parts that fail.
