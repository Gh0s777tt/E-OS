# 📓 Changelog

All notable changes to **E-OS** are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> **Legend:** `Added` · `Changed` · `Deprecated` · `Removed` · `Fixed` · `Security`
> Each release is numbered (`SemVer`) and code-named. Entries are intentionally
> verbose — every line should tell you *what* changed and *why*.

---

## [Unreleased]

### Added
- `[U-066]` **Execution roadmap to an installable daily-driver + reality ledger** — a
  23-agent grounded audit (recon → adversarial verify → flagship design → completeness
  critic) distilled into a living execution roadmap in [ROADMAP.md](ROADMAP.md): seven new
  series — `R-0xx` CI/release-integrity recovery (**GitHub Actions is disabled
  account-wide**, so the advertised CI image build / Pages site / release signing / CodeQL /
  gitleaks / cargo-audit pipeline is inert), `R-Fxx` immediate correctness+security fixes,
  `R-Dxx` native Settings shell, `R-6xx` installer→daily-driver + first-boot OOBE, `R-7xx`
  in-OS update system (`Settings → Update`), `R-8xx` secure driver manager
  (`Settings → Drivers`), `R-9xx` connectivity + an honest T1–T4 hardware triage of the
  full capability wishlist. Flagship designs in
  [docs/update-system-design.md](docs/update-system-design.md) and
  [docs/driver-manager-design.md](docs/driver-manager-design.md); 14 additional feature
  proposals in [docs/feature-proposals.md](docs/feature-proposals.md); the honest
  done-vs-claimed baseline in [docs/reality-ledger.md](docs/reality-ledger.md) (`R-001`).
  Planning + docs only — no runtime change.
- `[U-056]` **DE Phase 2 — animated smoke wallpaper** (eos-orbutils `0a114f3`):
  `background` rewritten from a static blit into a ~30 fps particle loop —
  150 pre-blurred crimson smoke puffs (15 Hz tick) + up to 16 sparks (30 Hz),
  sprites pre-rendered per (color, size, alpha level), dirty 32 px tiles restored
  from the cached base image and sent to orbital as merged Y-damage spans.
  Verified: consecutive QEMU screendumps all differ; diff bbox equals the smoke
  band; the launcher clock keeps ticking.
- `[U-057]` **DE Phase 3 — desktop icons layer + COSMIC crimson theme.** New
  `desktop` binary in the launcher crate (eos-orbutils `59ab58b`): labelled,
  double-clickable icons for apps and `~/Desktop` files on a transparent Back
  window; deterministic z-order via a DESKTOP-READY handshake with the bar
  (Back windows keep creation order); shared launcher code extracted to
  `launcher/src/ui.rs`. Plus `config/aarch64/eos.toml` (`4a022180`): a
  `~/Desktop/Welcome.txt` starter file and 24 cosmic-config files generated with
  the exact libcosmic checkout cosmic-files 1.2.0 is built from — dark mode
  pinned, accent `#E50914` (verified visually in cosmic-files after U-058).
- `[U-059]` **Desktop icon dedupe** (eos-orbutils `63d1202`): the same app used to
  appear twice (UI_PATH manifest + XDG desktop entry). Entries are now keyed by
  the exec binary name, preferring the XDG variant; 12 -> 9 unique icons.
- `[U-060]` **Hardware-capabilities roadmap recreated** —
  [docs/hardware-capabilities-roadmap.md](docs/hardware-capabilities-roadmap.md)
  (the original was lost with a working-notes wipe): the `R-50x` series —
  RAID-1 mirror daemon → aarch64 crypto-extension acceleration for FDE →
  post-quantum (hybrid) package signing — with recommended order, realistic
  per-item scope and QEMU verification plans. Linked from [ROADMAP.md](ROADMAP.md).
- `[U-061]` **R-501: RAID-1 mirror daemon (`raid1d`) — implemented and verified
  end-to-end on aarch64.** New `drivers/storage/raid1d` crate in eos-base
  (modeled on `lived` + driver-block `DiskScheme`): members are whole disks
  with an E-OS superblock in their last 4 KiB (magic/UUID/index/generation);
  the boot service assembles `disk.raid1`, writes go to all active members,
  reads fall back, stale members are excluded by generation. Verified in QEMU:
  `create` -> boot-assembly -> `redoxfs-mkfs`/mount -> write -> **boot with one
  member removed -> data still readable (degraded)**. Constraints learned:
  disk schemes require block-multiple I/O; scheme dir listings carry trailing
  newlines; `daemon::Daemon` forbids manual starts (assembly is service-only).
  **Platform bug found on the way** (R-401d follow-up, open): a second storage
  controller on aarch64 hangs the boot on an unrouted INTx line, or panics
  nvmed (`drivers/executor` IRQ ack) on a shared one — verification used
  multiple namespaces on the system controller; a real multi-controller fix
  is kernel-side work.
- `[U-063]` **R-502: hardware AES-XTS for the FDE path (ARMv8 Crypto Extensions),
  runtime-detected.** RedoxFS's AES-XTS now uses the `aes` crate's ARMv8 hardware
  backend when the CPU advertises AES, constant-time software otherwise — no
  SIGILL risk, clean fallback. Upstream `cpufeatures` has no Redox aarch64
  detection (the ISAR registers are EL1-only), so the redoxfs fork vendors
  `cpufeatures` with a Redox branch that reads `/scheme/sys/cpu` (the same role
  `getauxval(AT_HWCAP)` plays on Linux); the recipe sets `--cfg aes_armv8`.
  RedoxFS prints the selected backend at mkfs/open. **Verified in QEMU**:
  `redoxfs-mkfs --encrypt` on `-cpu max` and `-cpu cortex-a53` both report
  `AES-XTS backend: hardware (ARMv8 Crypto Extensions)` and create a valid
  encrypted volume. Note: every aarch64 CPU model in QEMU/TCG here exposes AES,
  so the software branch isn't reachable by CPU choice (verified by build +
  code); and throughput is not measurable under TCG (both paths run as host
  software) — real-hardware benchmarking is deferred to `R-403`.
- `[U-064]` **R-503: hybrid post-quantum package signing (prototype).** New
  build-host tool `tools/eos-repo-sign` signs the repo manifest (`repo.toml`,
  which carries every package's blake3 hash) with **ed25519 + ML-DSA-65**
  (FIPS 204, RustCrypto `ml-dsa` 0.1) — a forgery must break both, and the
  transition never weakens today's ed25519 trust. Verified against the real
  `repo/aarch64-unknown-redox/repo.toml`: hybrid verify passes, `--classical-only`
  passes (pre-migration verifiers keep working), and a one-byte tamper fails both
  algorithms. Rollout stages, key custody and non-goals documented in
  [docs/security.md](docs/security.md). Completes the `R-50x` hardware-capabilities
  series (`R-501` RAID-1, `R-502` aarch64 crypto acceleration, `R-503` PQ signing).
- `[U-065]` **R-501b: raid1d resync/rebuild + split-brain safety + status.**
  A degraded member is now rebuilt (data copied from the authoritative member)
  instead of merely excluded. Superblock v2 adds `last_full_sync` + `member_count`
  so the daemon tells an in-sync mirror from divergence. **Two data-loss holes
  found by an adversarial pre-build review and fixed before shipping:** (1) a
  runtime write failure now bumps the survivors' on-disk generation, so the next
  assembly resyncs the dropped disk instead of silently blessing it; (2)
  `last_full_sync` detects split-brain (two members each advanced to the same
  generation while the other was absent) and rebuilds deterministically with a
  loud warning. `raid1d status` reads a daemon-written state file so it works
  while the daemon holds the members. **Verified end-to-end in QEMU (5-boot
  sequence):** create -> write `v1` (A+B) -> degraded write `v2`+`extra` (A only,
  A gen 3 / B gen 2) -> reunite -> serial shows `resync 25..100% / rebuild
  complete`, both at gen 4 -> **boot B alone -> `v2`+`extra` present**, proving B
  received A's degraded-window writes. eos-base `1ab5035f`.
- `[U-055]` **New driver: `usbnetd` — USB networking (RNDIS), written from scratch in Rust.**
  E-OS gains a **USB network class driver** (USB-Ethernet dongles / QEMU `usb-net`) — the
  first brand-new USB class E-OS adds on top of the base Redox set. It is a userspace xHCI
  subdriver that enumerates the **CDC-Data** interface, runs the **RNDIS control handshake**
  (`INITIALIZE` → `QUERY OID_802_3_PERMANENT_ADDRESS` → `SET OID_GEN_CURRENT_PACKET_FILTER`
  over EP0 `SEND`/`GET_ENCAPSULATED_*` class requests), and exposes a standard `network.*`
  scheme via the shared `driver-network` crate, so the **smoltcp netstack treats a USB NIC
  exactly like a PCI one**. TX wraps Ethernet frames in `RNDIS_PACKET_MSG`; RX runs on a
  background thread + queue so the scheme event loop never blocks on the synchronous xHCI
  transfer API. **Written clean from the public RNDIS/CDC specifications** (protocol constants
  are non-copyrightable facts) per E-OS's licensing policy — no GPL code, memory-safe Rust,
  userspace/microkernel-isolated, matching E-OS's security model. **Boot-verified** (aarch64,
  `-device usb-net`): `xhcid` loads the subdriver for the class-10 interface, RNDIS comes up
  and reads the correct MAC (`52:54:00:12:34:56`), the network scheme registers, and the
  system reaches login with **0 exceptions / 0 panics**. **RX is event-driven:** the receive
  thread pokes a notify pipe after queueing each frame, and the event loop subscribes to it and
  ticks the scheme (which posts an `EVENT_READ` fevent when `available_for_read() > 0`), so
  asynchronously-received frames reach the netstack promptly instead of waiting for an unrelated
  scheme op. **TX verified end-to-end** (2026-07-12): with usb-net as the only NIC, the netstack
  routed a real **DHCP DISCOVER through usbnetd** — the driver logged `TX frame #0 (590 bytes)`,
  i.e. it enumerated, ran RNDIS, registered with the netstack, *and the netstack actually
  transmitted an Ethernet frame through the RNDIS bulk-out endpoint*. *(Remaining, precisely
  localized: **RX delivers no frames yet** — a ping/DHCP self-test showed `TX=1, RX=0`, so the
  DHCP OFFER / ARP replies aren't reaching the receive path. TX + enumeration + RNDIS + MAC +
  scheme are all confirmed working; the receive path — `bulk_in.transfer_read` in the RX thread,
  or a QEMU-RNDIS state detail — is the last mile and needs packet-level visibility or the rig to
  finish. The driver is otherwise correct-by-construction against the RNDIS spec.)*
  `eos-base@bcb359dd`, recipe re-pinned.
  This was unblocked by the `daemon` INIT_NOTIFY fix (`U-054`). See
  [docs/roadmap-connectivity.md](docs/roadmap-connectivity.md).
- `[U-054]` **USB mass storage works — root-caused a daemon-framework bug and re-enabled it.**
  USB flash drives / disks (`usbscsid`, class 8) were **disabled upstream** ("until it is more
  reliable" — "causes XHCI errors"). Investigation showed the failure was **not** in the SCSI
  or xHCI layer at all: `usbscsid` aborted at startup in the shared **`daemon`** crate
  (`daemon/src/lib.rs`), because a driver spawned by `xhcid` (not by `init`) inherits the
  parent's `INIT_NOTIFY` env var but **not a valid notify-pipe fd** — the parent's fd is
  `CLOEXEC`/already consumed — so `fcntl(FD_CLOEXEC)` returned `EBADF` and the daemon
  `panic!`ed → abort. **Fix:** make the notify pipe **optional** — on `EBADF`, skip the
  readiness notification (`write_pipe = None`, `ready*()` becomes a no-op) instead of aborting;
  init-spawned daemons (valid fd) are unchanged. Then re-enabled the class-8/subclass-6 →
  `usbscsid` mapping in `xhcid/drivers.toml`, and removed a debug block-0 dump in `usbscsid`
  (leaked disk contents to the console + panicked on a not-yet-ready device). **Verified in
  QEMU** with `-device usb-storage`: `xhcid` loads the SCSI subdriver, `usbscsid` starts
  cleanly, `Inquiry version: 5`, `SCSI initialized`, and it **reads the flash drive** (block 0
  returned the exact test marker written to the image) — login reached, 0 exceptions. So the
  upstream "unreliable" was a spawn-plumbing bug, now fixed; USB storage is usable. This also
  unblocks **any** future xHCI subdriver (audio/printer/CDC) that uses the daemon framework.
  `eos-base@71359c6e`, recipe re-pinned. See [docs/roadmap-connectivity.md](docs/roadmap-connectivity.md).
- `[U-053]` **Connectivity roadmap (USB · LAN · Bluetooth) + wired-LAN driver-diversity
  verified.** New [`docs/roadmap-connectivity.md`](docs/roadmap-connectivity.md) surveys the
  actual `eos-base` driver tree and lays out the plan for **USB** (all versions already via
  xHCI; per-class drivers — HID ✅, mass storage, CDC-serial, USB-Ethernet, USB-audio,
  printer), **LAN** (multi-NIC + IPv6 + throughput), and a ground-up **Bluetooth** stack
  (HCI → L2CAP → SDP → pairing → profiles A2DP/HID/RFCOMM → BLE), each with effort estimates
  and an explicit note of what is QEMU-verifiable vs needs real hardware (Wi-Fi and BT
  both need hardware — QEMU emulates neither). **LAN verified beyond virtio:** E-OS boots
  with an Intel **e1000** NIC and `pcid` auto-spawns `e1000d`, which binds the device
  (login reached, 0 exceptions) — confirming the wired-Ethernet stack (smoltcp netstack +
  the e1000/rtl/ixgbe/virtio driver family) is not virtio-only.
- `[U-052]` **ASLR now covers the dynamic linker (`ld.so`) itself.** Follow-up to `U-051`,
  which had noted the linker's own base as a remaining gap. The Redox `ld_script`s pinned
  `ld.so` at a fixed `0x20000000`, so the loader mapped it `MAP_FIXED` there — the linker's
  code, a rich source of ROP gadgets, sat at a **predictable** address on every boot. E-OS
  now links `ld.so` at **vaddr 0** (like ordinary PIE binaries) in all Redox `ld_script`s,
  so the loader maps it *map-anywhere* (`NULL` hint) and the kernel mmap ASLR (`U-045`)
  randomizes its base per boot — closing the last easy ASLR gap in the user-space load
  chain (executable + libraries were already covered per `U-051`; now the linker too).
  **Boot-verified on both aarch64 and x86_64**: each image reaches login with **0
  exceptions / 0 panics** — `ld.so`'s self-relocation works correctly at the randomized
  base on both. `eos-relibc@9e0bc824`, recipe re-pinned; `docs/hardening.md` updated.
- `[U-051]` **Deeper ASLR hardening: exec/library base confirmed randomized + guard bands.**
  Working through the "risky" hardening backlog: **(1) full-executable ASLR was already
  achieved** by `U-045` — E-OS/Redox userspace binaries are **PIE linked at vaddr 0**
  (confirmed via `readelf`), and the relibc loader maps them with a *map-anywhere* (`NULL`-
  hint) anonymous `mmap` that flows through `find_free_near`, so the code base (not just the
  heap) is randomized per boot; no risky loader change was needed. **(2) Guard bands** —
  `find_free_near` now keeps a minimum unmapped margin (`ASLR_GUARD_PAGES`, default 4) on
  both sides of each map-anywhere allocation when its hole has room, so a linear overflow
  past a mapping faults on unmapped space instead of corrupting the neighbour. Best-effort
  (shrinks to fit tight holes, never `ENOMEM`); a *soft* guard, not a hard `PROT_NONE` page.
  `eos-kernel@e20d5765`, recipe re-pinned; boot-verified (login, 0 exceptions).
  **Assessed and deliberately NOT done** (honest risk/reward): *hard* `PROT_NONE` guard
  pages (would need grant-model + demand-paging-fault-handler surgery on the core mmap path —
  high boot-breakage risk for modest marginal value in a memory-safe userland); restoring the optional virtio-rng
  driver (`R-402`, a known userspace deadlock, redundant with the kernel's jitter entropy);
  full temporal W⊕X (needs relibc to map code file-backed — its loader does anon→`mprotect(+X)`).
- `[U-050]` **Bootloader fork rebased onto current mainline (removes fork debt, adopts the
  native FDE fix).** Follow-up to `U-049`: rather than carry a custom encrypted-boot patch,
  the `eos-bootloader` fork was **rebased onto current `redox-os/bootloader` master**
  (`b74f53a`), which already contains the proper fix (`f520862`, `seen_enokey`). The fork was
  only 2 commits behind and its E-OS delta is just 4 theming commits (red/black theme + banner,
  README, LICENSE) — all cherry-picked cleanly; the custom `ENOKEY` patch was **dropped** as
  redundant. Net result: E-OS's bootloader is now *current mainline + E-OS theming*, with the
  encrypted-boot fix coming from upstream instead of a local patch (`eos-bootloader@f1ba665`,
  branch `eos-rebased`, recipe re-pinned). **Both paths re-verified on the rebased bootloader:**
  the normal image boots to `eos login:` (0 exceptions), and the encrypted image prompts for the
  password, unlocks the AES-XTS root, and reaches `eos login:` (0 exceptions) — the encrypted-boot
  path is now verified on **both aarch64 and x86_64** under UEFI.
- `[U-049]` **Full-disk encryption now actually boots — bootloader fix + end-to-end
  verification.** E-OS advertises RedoxFS AES-XTS full-disk encryption, but the UEFI boot
  path was **broken**: an encrypted root **panicked** the bootloader (`Failed to open
  RedoxFS`) instead of prompting for the password. Root cause: the UEFI `filesystem()`
  partition scan (`os/uefi/mod.rs`) treated the `ENOKEY` that an encrypted RedoxFS returns
  as a generic error — logging *"BlockIo error: Required key not available"* and skipping
  the device — then returned `ENOENT`; the unlock loop in `main.rs` only prompts for a
  password on `ENOKEY`, so it saw `ENOENT` and panicked. Since **both** aarch64 and x86_64
  use the UEFI bootloader, encrypted roots could not boot on either (the BIOS path was
  fine, as it returns `open()` directly). **Fix:** propagate `ENOKEY`/`EKEYREJECTED` from
  the scan so the unlock loop prompts ([`eos-bootloader@083d9fae`](https://github.com/Gh0s777tt/eos-bootloader),
  recipe re-pinned). **Verified end-to-end** (aarch64/UEFI, QEMU): built an encrypted
  image (`[general] encrypt_disk`), booted it — bootloader prompts `RedoxFS password
  (1/10):`, the password is accepted, the **AES-XTS** root unlocks, the kernel loads from
  it, and it reaches `eos login:` with **0 exceptions / 0 panics**. **Not an upstream bug:**
  mainline `redox-os/bootloader` already fixes this (commit `f520862`, "Fix UEFI support for
  encrypted partitions", via a `seen_enokey` flag) — the E-OS bootloader fork was **pinned to
  a rev predating that fix**, so it had regressed; our patch restores the correct behavior
  (functionally equivalent). Also verified the fix does **not** regress the normal unencrypted
  image (rebuilt + booted to `eos login:`, 0 exceptions). `docs/encryption.md` updated from
  "chain in place / mkfs verified" to full boot-unlock verified.
- `[U-048]` **Bootable live / installer ISO — verified on aarch64.** Besides the
  pre-installed `harddrive.img`, E-OS now has a confirmed **live ISO** (`make
  CONFIG_NAME=eos build/<arch>/eos/redox-live.iso`) — a read-only medium that boots the
  full system with the graphical greeter and `installer-gui`, i.e. a "try it then install
  to disk" flow like a Linux live USB. The **aarch64** live ISO was boot-tested under QEMU
  `virt`/UEFI: the loader hands off, the kernel comes up, **"Switching to live disk"**,
  the E-OS `0.1.0 "Genesis"` banner renders, and it reaches the greeter / `eos login:`
  with **0 exceptions / 0 panics** — on the fully-hardened kernel (overflow-checks + ASLR
  + W⊕X). This is a concrete step toward "installable like a normal OS": the medium boots
  and carries the installer. `docs/install.md` updated — added the live-ISO build/flash
  path and corrected the stale "aarch64 is experimental / awaits a RedoxFS fix" note (that
  blocker was fixed; aarch64 boots to the graphical greeter, with only the extra COSMIC
  apps still deferred to an x86_64-linux build host).
- `[U-047]` **Hardening (Fala B): audit & guidance for the remaining W⊕X / RUSTFLAGS /
   scheme-namespace items** — closing out Fala B by resolving the three tracked gaps with
   evidence instead of leaving them vague. (1) **Kernel-space W⊕X audited:** there are *no
   persistent* x86 W+X pages — the two sites are transient early-boot windows that are torn
   down (the SMP AP trampoline is mapped W+X, written, then **unmapped**; the `alternative`
   self-modifying-code patcher goes W+X to patch then **remaps R-X**). `docs/hardening.md`
   now states this precisely (was "a few necessary x86 W+X pages remain"). (2) **`RUSTFLAGS`
   RELRO/BIND_NOW assessed:** low marginal value for E-OS's memory-safe, mostly-static Rust
   userland whose loader maps code into anonymous memory (no classic PLT/GOT for `-z now` to
   protect), and it would force a full-world rebuild — documented as a deliberate no-op, not
   a pending gap; the C ports that *would* benefit build with their own flags. (3)
   **Least-privilege `login_schemes.toml`:** identified three raw driver-only schemes safe to
   drop from the interactive `user` (`memory`, `irq`, `serio` — input is handled by `usbhidd`,
   not `user`-held `serio`) and shipped a ready-to-apply diff + rationale in the hardening
   guide. Left as **operator opt-in, not the default**, because the post-login graphical
   session can't be driven end-to-end under the headless test harness (QEMU-on-macOS delivers
   no serial input; GUI-login automation proved unreliable — even a `root`/`password` attempt
   couldn't be driven past the greeter), so E-OS can't yet *boot-verify* it the way it does the
   kernel hardenings. A tightened build was confirmed to boot to the greeter with 0
   scheme-permission errors; full session verification awaits a driveable display (the x86 rig).
   **(4) Cross-arch verification of the whole Fala B stack:** the `x86_64` E-OS image was
   rebuilt on the current pins (`overflow-checks` kernel+base+relibc, ASLR, W⊕X) and **boots
   to `eos login:` with 0 exceptions / 0 panics** (E-OS Bootloader 1.0.0 on x86_64/UEFI) —
   confirming the hardening is not aarch64-only and that the x86_64-specific ASLR entropy path
   (`RDTSC`) compiles and runs. Both arches now boot the fully-hardened kernel clean.
- `[U-001]` Project automation: GitHub Actions CI, **CodeQL** code scanning,
  **gitleaks** secret scanning and **Dependabot** dependency updates.
- `[U-002]` `CODEOWNERS`, issue/PR templates, `FUNDING.yml`.
- `[U-004]` **Custom build config** `config/x86_64/eos.toml` — the E-OS desktop
  variant (`make CI=1 CONFIG_NAME=eos all`).
- `[U-005]` **OS-level rebranding** via `postinstall` file overrides:
  `/etc/os-release`, `/etc/issue` login banner, hostname and `/etc/motd` → E-OS.
- `[U-006]` First desktop screenshot — `assets/screenshots/eos-cosmic-desktop.png`
  (COSMIC running on E-OS under QEMU/KVM).
- `[U-007]` **Red/black E-OS bootloader** — `"E-OS Bootloader"` banner + red-on-black
  theme (selection black-on-red), built from source. Change set:
  `patches/bootloader-eos-red-black.patch`; screenshot `assets/screenshots/eos-bootloader.png`.
- `[U-008]` **aarch64 boots to the full branded desktop** (2026-06-08). E-OS now
  reaches the graphical E-OS COSMIC desktop on **aarch64** under QEMU `virt` (with
  `-machine virt,acpi=off`); it previously died at early boot. Screenshot
  `assets/screenshots/eos-aarch64-desktop.png`. Both x86_64 and aarch64 build from
  the same recipes and boot to the desktop.
- `[U-009]` **Downstream kernel/base/relibc forks** carrying the aarch64 (and one
  cross-arch relibc) fixes — [`Gh0s777tt/eos-kernel`](https://github.com/Gh0s777tt/eos-kernel)
  (`master` @ `35bdc7d3`), [`Gh0s777tt/eos-base`](https://github.com/Gh0s777tt/eos-base)
  (`main` @ `6c695a10`), and [`Gh0s777tt/eos-relibc`](https://github.com/Gh0s777tt/eos-relibc)
  (`eos-tls` @ `0d30e9ea`). The `core/kernel` + `core/base` + `core/relibc` recipes are
  **pinned** to them. Reproducibility **empirically verified** (2026-06-10): a forced clean
  re-fetch of all three forks (`u.*` to delete the cached sources, the state of a fresh clone)
  re-cooked straight from the GitHub origins and rebuilt an aarch64 image that boots to login
  with 0 aborts — plus an x86_64 regression build.
- `[U-010]` **Upstream-ready patches + submission guide** — `upstream/` holds clean
  `git am` patches (4 kernel, 2 base, 1 relibc) and a `gitlab.redox-os.org` merge-request
  guide, plus `upstream/MR-DESCRIPTIONS.md` (paste-ready MR titles/bodies). All seven
  re-verified to `git am` cleanly onto current mainline (2026-06-10).
- `[U-017]` **Downstream relibc fork — RETIRED.** It briefly carried an aarch64 `verify()`
  workaround, but `R-401e` (`[U-018]`) fixes the true cause in the **kernel**, so
  `core/relibc` is back on **strict upstream relibc** (`@ bcc1a0d4`) and the fork is no
  longer used. The upstream-ready fix is now the kernel patch `upstream/kernel/0003-*`.
- `[U-021]` **Hardware support matrix** — `docs/hardware-matrix.md` records the driver
  coverage verified by live QEMU boots on **x86_64** (q35/KVM) and **aarch64** (`virt`,
  `-cpu cortex-a72`): nvmed, ahcid, virtio-blk/gpu/net, e1000/e1000e, rtl8139, ihda, xhci.
  `scripts/qemu-driver-check.sh [x86_64|aarch64]` regenerates it from a single
  kitchen-sink boot.
- `[U-031]` **x86_64 regression build + both-arch boot verification on macOS.** After
  U-029/U-030, rebuilt **both** arches from source (all seven forks forced via `scr.*`)
  and boot-tested them on the Apple-Silicon rig: **x86_64** (q35/TCG, headless) reaches
  `eos login:` with the `E-OS Bootloader` banner and 0 unhandled exceptions;
  **aarch64** (virt/TCG, ramfb) reaches the graphical **red/black E-OS greeter** with 0
  exceptions once `orbital`/`orbutils` are pinned (`assets/screenshots/eos-aarch64-greeter-macos-build.png`).
- `[U-032]` **Upstream patch set re-verified against July mainline.** The 7 upstream-ready
  patches were re-checked against current `redox-os` `master` (kernel `fbfe439`, base
  `9e12870`, relibc `d589900`): 4 kernel + 2 base still `git am` cleanly, the 1 relibc
  patch needs only a trivial 3-way merge (an upstream `.expect()`→`.expect_notls()`
  rename), and **none** of the fixes have landed upstream — so the forks remain
  necessary. `upstream/README.md` verification note updated.
- `[U-046]` **Hardening (Fala B): user-space W⊕X (no writable+executable pages).**
  Upstream Redox lets a process `mmap`/`mprotect`/`mremap` a page as
  `PROT_WRITE | PROT_EXEC` — writable *and* executable at once, the textbook
  shellcode-injection primitive (write attacker bytes into a page, jump into it). E-OS
  now **strips `PROT_EXEC` from any user-space request that also asks for `PROT_WRITE`**,
  at the syscall boundary (`SYS_FMAP` / `SYS_MPROTECT` / `SYS_MREMAP`, via a new
  `wx_sanitize`), so a running program can never obtain a W+X page — code must be mapped
  read-only-executable. Enforcement lives at the syscall entry, **not** in the shared
  `page_flags()` conversion, on purpose: the kernel's trusted one-shot `bootstrap` blob
  is legitimately mapped RWX through the *internal* `AddrSpace::mmap` path (not a
  syscall) and must stay executable. Gated by `KERNEL_WX_USER`. **First attempt
  (self-corrected):** enforcing inside `page_flags()` also disarmed the bootstrap RWX
  mapping, and the aarch64 image faulted `[bootstrap]` with a synchronous EL0 exception
  on its very first instruction — proving the enforcement was live, but at the wrong
  layer; moved to the syscall boundary. **Boot-verified:** the aarch64 image reaches
  login with **0 unhandled exceptions / 0 panics** — the whole base userland (init,
  drivers, login) runs without needing a single W+X page. `eos-kernel@4d3c8e94`, recipe
  re-pinned; `docs/hardening.md` updated (kernel-space vs user-space W⊕X split out).
  **Scope — simultaneous, not temporal:** this blocks a page from being W and X *at
  once*, but not the `mmap(RW)` → write → `mprotect(R-X)` *sequence*. A stronger temporal
  variant (deny anonymous memory ever gaining `PROT_EXEC`) was implemented and tested,
  but **reverted**: Redox's `ld.so` loads every shared object into *anonymous* memory and
  then `mprotect`s it executable (it does not map code file-backed), so the rule faulted
  every dynamically-loaded program (`ld.so mprotect failed: EACCES` on `rm`, `sudo`,
  `orbital`, …). Full temporal W⊕X needs loader rework and is tracked as future work; the
  shipped kernel keeps the working simultaneous-W⊕X rule.
- `[U-045]` **Hardening (Fala B): user-space `mmap` ASLR.** Upstream Redox has **no**
  ASLR — KASLR is unimplemented and there is no user-space load/heap randomization, so
  "map anywhere" allocations (heap, `mmap`'d libraries, stacks) land at deterministic
  addresses, which hands an attacker predictable targets. E-OS randomizes them: the
  kernel's `find_free_near` now places each non-fixed mapping at a **page-aligned random
  offset inside** the chosen free hole rather than always at its start. The offset comes
  from a splitmix64 PRNG seeded from a cycle counter (`CNTVCT_EL0` on aarch64, `RDTSC` on
  x86_64) and re-mixed with fresh jitter per call, **bounded** by `ASLR_MAX_SLACK_PAGES`
  (avoids flinging a small allocation to the far end of a huge hole) and **gated** by the
  `KERNEL_ASLR` const. `MAP_FIXED` is unaffected. All arithmetic is `wrapping_*`/
  `saturating_*` so it composes with `overflow-checks` (U-044). **Boot-verified:** the
  aarch64 image reaches login with **0 unhandled exceptions / 0 panics** — the entire
  user-space bring-up (init, drivers, login) now runs through the randomized allocator
  without a single fault, proving every returned span is in-bounds and correctly aligned.
  **Randomization empirically proven** (2026-07-11): a throwaway diagnostic kernel logged
  the base of the first few anonymous user `mmap`s across two cold boots — the
  *map-anywhere* allocations moved (`0x6294000` → `0xaf6a000`, ~141 MiB apart; `0xf6000`
  → `0x12b000`, 53 pages apart) while the fixed/hinted regions (`0x400000000000`,
  `0x7ffffffec000`) stayed put, exactly as designed — confirming the entropy source is
  live (not stuck at 0) and the offset is bounded by hole size. The diagnostic kernel was
  discarded; the shipping kernel carries no such print.
  `eos-kernel@8b5cc736`, recipe re-pinned; `docs/hardening.md` updated.
- `[U-044]` **Hardening (Fala B): `overflow-checks` in the release kernel.** E-OS now
  builds `eos-kernel` with `overflow-checks = true` in its release profile (upstream
  Redox does not). An *unintended* integer overflow — a classic exploit primitive even
  in memory-safe Rust — is now a controlled abort (`panic = "abort"`) instead of a
  silent wrap; intentional wrapping uses `wrapping_*`/`Wrapping`, so this only fires on
  genuine bugs. **Boot-verified:** the aarch64 image reaches login with **0 overflow
  panics / 0 unhandled exceptions**, so no hot path relied on implicit wrapping.
  `eos-kernel@ffd0e6b3`, recipe re-pinned. **Extended to `eos-base`** — all drivers
  and daemons (`eos-base@98039b88`) now build with `overflow-checks = true` too; they
  parse untrusted input (disk, network, USB), so this is where it matters most.
  Boot-verified: the image reaches login with **0 overflow panics** and the drivers
  (acpid/fbcond/nvmed/…) come up clean. **Also extended to `eos-relibc@be0fb67f`** — the
  C library under *every* program — completing the trilogy: **all E-OS-owned Rust code
  (kernel + base + relibc) now aborts on unintended integer overflow.** The relibc build
  required a toolchain-sysroot rebuild; boot-verified with 0 overflow panics (all
  relibc-linked userspace runs clean). `docs/hardening.md` gained a build-time hardening
  table (kernel + base + relibc overflow-checks, `panic=abort`, `KERNEL_DEBUG` off, a
  W⊕X audit noting the few necessary x86 W+X pages, and empty `RUSTFLAGS` as a tracked
  gap) and its stale "aarch64 not yet to login" limit was removed.
- `[U-043]` **Serial console login — the image-side pieces (ACPI PL011 RXE init +
  a serial getty); interactive input is a QEMU/macOS host limit, not an E-OS bug.**
  Root-caused why the headless serial console showed output but took no input, in
  three layers: **(1)** the ACPI/SPCR serial path created the PL011 and enabled its
  IRQ but never called `SerialPort::init()`, which sets the control register
  (`RXE | TXE | UARTEN`) — without `RXE` the receiver is off (fixed in
  `eos-kernel@3c642030`; the device-tree path already inits); **(2)** there was **no
  serial getty** — login runs via `getty` on `/scheme/fbcon` (the framebuffer
  console), never on the serial, so nothing read serial input (added a
  `getty /scheme/debug` init.d service — `getty` treats a non-numeric TTY arg as a
  literal scheme path); **(3)** with both fixed, a kernel-side diagnostic proved the
  serial RX interrupt **never fires on keypress (0 IRQs)** — QEMU on macOS does not
  deliver `-serial unix:…,server` **input** to the guest UART (output works). So the
  two E-OS fixes are correct and enable serial login on real hardware / a serial
  backend that forwards input; they can't be runtime-verified under QEMU-macOS. The
  real interactive paths — the graphical greeter and `ssh` (openssh ships) — work.
- `[U-042]` **Kernel: gate the aarch64/riscv64 `debug!` flood behind `KERNEL_DEBUG`
  (default off) — quieter, faster boots.** Upstream's kernel `debug!` macro printed
  **unconditionally** on aarch64/riscv64 (cfg-gated to those arches, no level check;
  a no-op on x86), emitting a `DEBUG` line on **every** `call_fdread` and similar hot
  paths. That floods the console — visibly slowing every QEMU TCG boot. Added a
  crate-root `KERNEL_DEBUG` constant (default `false`) and gated the macro on it
  (`eos-kernel@cf54bc11`, recipe re-pinned); one flip re-enables it for bring-up.
  **Verified:** the rebuilt aarch64 image boots with **zero** `DEBUG --` lines on the
  serial console (was thousands). *(A separate finding: aarch64 serial **input** (UART
  RX) is not delivered to the login getty on the July image, so an interactive serial
  login can't be driven — this is unrelated to the flood and is a tracked follow-up;
  the `eos` CLI was instead runtime-verified via a boot-time self-test, below.)*
- `[U-040]` **`R-209` — the `eos` system command.** `recipes/other/eos` now ships
  `/usr/bin/eos`: `eos info` (E-OS/kernel/build details), `eos doctor` (quick health
  check — entropy source, home, hostname), `eos welcome`, `eos help`. Written in ion
  syntax verified construct-by-construct against ion's own test corpus (`fn`, `if/else
  if`, `test $x = "y"`, `test -f/-e/-d`, `$len(@args)`, `@args[1]`). **Runtime-verified**
  (2026-07-11) via a boot-time self-test that ran all four subcommands and captured
  their output on the serial console: `eos info` prints the E-OS banner + `uname -a`
  (kernel `cf54bc11`) + os-release; `eos doctor` reports `[ok]` for the entropy source,
  home and hostname; `eos help` prints usage; an unknown command prints the error +
  usage. `eos-welcome`'s app list was corrected to what actually ships.
- `[U-041]` **`R-207` follow-up — COSMIC GUI apps blocked on the aarch64 build host.**
  `cosmic-store`/`settings`/`reader` pull `fontconfig` → `host:gperf`, whose redoxer
  host toolchain Redox publishes **only for x86_64-linux** build hosts. On this Apple
  Silicon (aarch64) build host the toolchain fetch 404s; the apps build fine on an
  x86_64-linux host (the WSL2 rig). The config note records this accurately; the CLI
  toolbox (nano/vim/git/curl/wget/ripgrep/nushell/openssh) ships on both arches.
- `[U-039]` **Upstream patch set refreshed & expanded to 13 patches — ready to submit.**
  Regenerated `upstream/` from the rebased forks (`eos-july`): **6 kernel, 6 base, 1
  relibc**, up from 7. Two new kernel fixes found during the rebase are now included —
  the virtual-timer IRQ registration (`kernel/0005`) and the level-INTx EOI deadlock
  (`kernel/0006`) — plus previously-uncontributed base fixes (`_PRT` cfg-gate,
  virtio-core INTx, randd RNDRRS, ihdad boot-hang). **All 13 `git am` cleanly onto a
  fresh mainline clone** (kernel `@ 20a813c5`, base `@ 2f06b013`, relibc `@ 284852a0`);
  none have landed upstream. `upstream/MR-DESCRIPTIONS.md` and `README.md` updated with
  the new patches and a no-new-account submission path (sign in to gitlab.redox-os.org
  with an existing gitlab.com account). Submission itself is the maintainer's account
  step — the patches are prepared and verified. — the whole boot→desktop
  stack is now under `Gh0s777tt`.** Mirrored the **16** Redox-authored components E-OS
  ships (that weren't already forked) into `Gh0s777tt/eos-*` and re-pointed their recipes,
  each pinned to an exact rev: `redoxfs`, `orbital`, `orbutils`, `orbterm`, `orbclient`,
  `liborbital`, `ion`, `coreutils`, `extrautils`, `netutils`, `netdb`, `pkgutils`, `pkgar`,
  `installer`, `redoxer`, `redox-fatfs`. Together with the 6 modified forks, **all 22
  Redox-authored packages in the E-OS image build from E-OS-owned repos** — editable
  freely, reproducible, independent of `gitlab.redox-os.org`. The ~1900 third-party
  software ports (vim/curl/gcc/COSMIC-from-pop-os/…) are deliberately **not** vendored —
  they are upstream projects, not Redox. New `docs/forks.md` (the full map + policy) and
  `scripts/sync-forks.sh` (report/fast-forward the pure mirrors vs upstream).
- `[U-037]` **`R-207` — usable CLI toolbox out of the box.** A fresh E-OS install shipped
  only an editor, file manager, terminal and netsurf. `config/*/eos.toml` now adds a
  practical CLI toolbox — `nano`, `vim`, `git`, `curl`, `wget`, `ripgrep`, `nushell`,
  `openssh` (both arches; filesystem grown 700 → 1400 MiB; `eos-welcome` updated). The
  extra COSMIC GUI apps (store/settings/reader) are **deferred**: their cookbook build
  pulls `fontconfig`, which needs the `gperf` host tool (`recipes/wip`) that the
  `REPO_BINARY` resolver does not auto-build — a follow-up. `cosmic-monitor` is dropped
  outright (its version fails to compile against the current `libcosmic`).
- `[U-036]` **`main` PROMOTED to the July fork rebase — all upstream-drift workaround
  pins removed.** With both arches validated (aarch64 greeter + x86_64 `eos login:`, 0
  exceptions each), the recipes now build the rebased forks: `core/kernel` →
  `eos-july@bf4b264e`, `core/base` → `eos-july@969c64b9`, `core/relibc` →
  `eos-july@963b8f91`, `core/userutils` → `eos-july@260d7725`, and `redoxfs`/`orbital`/
  `orbutils` are **unpinned** (the three U-030 SBOM pins are gone — the rebase resolved
  the relibc-ABI drift that required them). E-OS's forks are now current with July
  mainline, carry the same fixes plus the new INTx deadlock fix, and ship no workaround
  pins. `docs/known-issues.md` marks the rebase promoted.
- `[U-035]` **July rebase now boots to the greeter on aarch64 — `virtio-rngd` dropped
  from the July line.** After the INTx fix (U-034) the only remaining blocker was a
  `virtio-rngd`-specific userspace deadlock (proven isolated: the same image with no
  `virtio-rng` device reached login). Root-causing it needs userspace thread-state
  instrumentation; pragmatically, the **optional** R-402 `virtio-rng` entropy driver was
  reverted on `eos-base@969c64b9` (the kernel R-401b jitter entropy still seeds randd —
  no zero-seed regression). The fully-rebased July aarch64 image (kernel `bf4b264e`, base
  `969c64b9`, relibc `963b8f91`, userutils `260d772`, all `eos-july`; redoxfs/orbital/
  orbutils on July HEAD, **no workaround pins**) now boots to the **graphical E-OS
  greeter with 0 exceptions and a `virtio-rng` device attached** — the exact config that
  used to deadlock — CPU 100%+ throughout. **The July rebase is complete and validated on
  aarch64.** Remaining before promoting it over the June forks on `main`: an x86_64
  cross-build/boot check (in progress). `virtio-rngd` root-cause and the upstream MRs
  (now including the INTx fix) are follow-ups.
- `[U-034]` **aarch64 kernel INTx deadlock fixed — the rebased July stack now boots to
  login.** Root-caused the WFI deadlock (U-033): on aarch64 the kernel deferred the GIC
  **EOI** of a userspace-handled level-triggered INTx to the driver's scheme ack,
  leaving the interrupt active (GIC priority raised) and blocking the generic-timer PPI
  until the driver acks — but the driver can't be scheduled to ack without the timer, a
  circular deadlock. Fix (`eos-kernel@bf4b264e`, aarch64-only; riscv64 PLIC already EOIs
  in-handler, x86 unchanged): `dtb::irqchip::trigger_virq` masks + EOIs the line
  in-kernel before notifying userspace, and the driver's ack re-enables it instead of a
  double-EOI. **An upstream-worthy mainline aarch64 bug fix.** With it the rebased July
  stack (kernel `bf4b264e`, base `3e10b86f`, relibc `963b8f91`, userutils `260d772`, all
  `eos-july`; redoxfs/orbital/orbutils on July HEAD, no pins) **boots to `eos login:`
  with 0 exceptions** (verified headless on macOS/M4). **One isolated item remains:** a
  `virtio-rngd`-specific userspace deadlock (our optional R-402 driver) — with a
  `virtio-rng` device attached the boot freezes post-seed at ~5% CPU (timer alive, all
  userspace blocked); the *same image* with no `virtio-rng` device reaches login cleanly,
  so it is a `virtio-rngd`/July-runtime interaction, not the INTx path. `main` stays on
  the validated June forks + pins. Details: `docs/known-issues.md`.
- `[U-033]` **Fork rebase onto July upstream — executed in full, root cause of U-030
  confirmed, promotion blocked on a virtio-INTx deadlock.** All **four** code forks
  were rebased onto current mainline via a full `git rebase --onto` carrying the
  **complete** E-OS delta (not just the `upstream/` patch subset) and pushed to
  `eos-{kernel,base,relibc,userutils}` branch `eos-july` (kernel `cb14af3b`/8 commits,
  base `3e10b86f`/13, relibc `963b8f91`/1, userutils `260d772`/4). The exercise
  **confirmed U-030's root cause is relibc ABI drift** (`undefined reference to
  redox_fcntl_v0` when the July userland links against the June sysroot) and surfaced
  three rebase lessons the earlier patch-only attempt hid: a fork carries more than its
  `upstream/` patches (dropping R-402 virtio-core INTx made `virtio-netd` panic on
  `enable_msix unimplemented!()`); all code forks must move together (June userutils vs
  July relibc made `sudo` panic `Function not implemented`); the toolchain **sysroot
  relibc must be rebuilt** and **`Cargo.lock` regenerated** (else `driver-graphics`
  fails on two `redox_syscall` versions). The fully-rebased image **builds, links, and
  boots with 0 unhandled exceptions** (all drivers init: nvmed INTx, `virtio-net` MAC,
  `virtio-rng` seed) — but then **deadlocks**: after `virtio-rng` seeds, all CPUs go to
  WFI (QEMU 0% CPU) waiting on the shared `virtio-rng`/`virtio-netd` **INTx** line, and
  never reach the greeter. **`main` stays on the validated June forks + pins** (greeter,
  0 exceptions); the rebase is complete on the `eos-july` branches, blocked on the
  shared-INTx deadlock (kernel/driver debugging needed — the shared-INTx patch
  `kernel/0002` is implicated). Details: `docs/known-issues.md`.
- `[U-030]` **Upstream-drift boot blocker: unpinned `redoxfs` (0.9.1, July HEAD)
  aborted every aarch64 boot against the June-pinned forks — root-caused by
  disasm, fixed by pinning to the SBOM-validated rev.** The initfs `redoxfs`
  (PID 17) died deterministically at relibc start (`brk #1`, EC=0x3C) before
  mounting root, under TCG `cortex-a72` **and** HVF/M4, `-smp 1` **and** `4`.
  Disassembly at the fault ELR showed the shared abort landing pad: `verify()`
  **passed** (`X0=0` — R-401e works), the abort came from a later TCB/TLS-setup
  NULL check (`cbz x9`, `X9=0`, `X8=0x0000800000000000`). Pinning
  `recipes/core/redoxfs` to `af493b9f` (the 0.1.0 SBOM rev) makes the same build
  boot to `eos login:`. Deeper TLS-layout interaction deferred to the planned
  fork rebase; `orbital` (same drift class) logged one non-blocking exception
  headless and is a watch item. Details: `docs/known-issues.md`. *(First E-OS
  image built AND boot-verified on macOS/Apple Silicon — Podman VM build,
  QEMU TCG boot.)*
- `[U-029]` **Fresh-clone builds silently shipped UPSTREAM binaries for all six
  pinned forks — found by the first macOS build, fixed in CI + docs.** Under
  `REPO_BINARY=1` the cook resolver compares local `source_info.toml` with the
  packaged state; on a fresh clone the pinned-source recipes were never fetched,
  so there is nothing to compare and the resolver silently takes the upstream
  binary — the built image had `eos login:`=0, `E-OS Bootloader`=0,
  `redox login:`=1 and **no R-401\*/R-402a fixes** (an aarch64 image that may not
  boot; `make f.<pkg>` alone doesn't help — with `--repo-binary` it reports
  `cached` without fetching source). This also invalidated the CI image guarantee:
  `build.yml` forced only the three branding forks (`scr.bootloader/userutils/orbdata`),
  so CI images shipped upstream kernel/base/relibc. **Fixed:** `build.yml` now
  forces all six (`scr.kernel scr.base scr.relibc scr.bootloader scr.userutils
  scr.orbdata`) and gained a verification step comparing each package's
  `source_identifier` in `repo/<target>/<pkg>.toml` against the pinned fork rev;
  the trap + both fixes documented in `docs/build-troubleshooting.md`. *(The 0.1.0
  release-image builds were done on the dev rig with sources fetched, so they were
  not affected; the risk was fresh clones and CI.)*
- `[U-028]` **`R-1003` — public package-repo hosting infrastructure.** Per-arch
  GitHub Pages hosting repos created with Pages enabled
  ([`eos-pkg-x86_64`](https://github.com/Gh0s777tt/eos-pkg-x86_64),
  [`eos-pkg-aarch64`](https://github.com/Gh0s777tt/eos-pkg-aarch64)) — Pages was
  chosen because the `pkg` client requires the nested `<base>/<target>/<pkg>.pkgar`
  layout that flat release assets cannot serve. New publisher
  `scripts/publish-repo-pages.sh`: stages `pkg/<target>/` + the public signing key,
  rejects >100 MB blobs (GitHub's limit) up front, and force-pushes one orphan
  commit per publish so the hosting repos never accumulate history. Stable URLs:
  `https://gh0s777tt.github.io/eos-pkg-<arch>/pkg`. `docs/packages.md` updated;
  `/etc/pkg.d/50_eos` is deliberately not pre-wired into images until the repo is
  populated (a dead repo URL would degrade `pkg`).
- `[U-027]` **`R-206` — `eos` meta-package + first-boot welcome (BOOT-VERIFIED
  2026-07-10** — aarch64 QEMU serial session: `eos login:` → `eos-welcome` prints
  the full quick start; `uname -a` reports the fork kernel `6ee1f796`; `whoami`
  runs clean — **the first E-OS image built and verified entirely on
  macOS/Apple Silicon).** New source-less recipe `recipes/other/eos` (the `myfiles`
  pattern) ships `/usr/bin/eos-welcome` — an ion-compatible quick-start command
  (getting around, install-to-disk with encryption, accounts, docs links) — plus
  `/usr/share/eos/eos-release`. Registered as `eos = {}` in both
  `config/x86_64/eos.toml` and `config/aarch64/eos.toml`; the configs also add
  `/home/user/Welcome.txt` (the proven `demo.toml` pattern, visible in COSMIC Files)
  and extend `/etc/motd` (printed by `login`) with a pointer to `eos-welcome`.
- `[U-022]` **`docs/build-troubleshooting.md`** — fix for the `make CONFIG_NAME=eos all`
  "Package `ncursesw` not found" failure (cook `r.terminfo` + deps first; `terminfo` has
  no `source_info.toml` under `REPO_BINARY`, so the resolver marks it and its dependent
  `ncursesw` outdated and never publishes them), plus the headless-QEMU smoke-test recipe.

### Changed
- `[U-003]` Documentation expanded under `docs/` (architecture, building, security, FAQ).
- `[U-014]` `core/kernel` + `core/base` recipes now build from the E-OS forks (pinned
  by commit) instead of tracking upstream HEAD. `docs/known-issues.md` rewritten
  (R-401b/c/d **resolved**, with the true root cause and the aarch64 QEMU command);
  `ROADMAP.md` `R-401b` → ✅.
- `[U-026]` The three branding recipes (`core/bootloader`, `core/userutils`,
  `gui/orbdata`) are now **rev-pinned** to their fork heads like kernel/base/relibc —
  previously they tracked a branch, so a push to a fork could silently change the build.

### Fixed
- `[U-058]` **Every dynamically linked GUI app crashed on aarch64 at startup**
  (`UNHANDLED EXCEPTION`; latent since the first aarch64 desktop — apps had never
  been launched during earlier phase verifications). Root cause: two `ld.so` bugs
  in relibc, both only reachable on `Resolve::Now` targets (aarch64 — x86_64
  defaults to lazy binding): (1) an unresolved **weak** PLT symbol panicked the
  loader instead of binding to 0 per the System V gABI (killed cosmic-files on
  zstd's optional `ZSTD_trace_*` hooks); (2) eager `d_val - load_base` arithmetic
  in dynamic-section parsing overflowed for non-PIE executables under our
  release overflow-checks hardening. Fixed in eos-relibc `7e9a95d0` (`R-402b`);
  cosmic-files and cosmic-term now run (crimson-themed). Known issue: netsurf-fb
  (the image's only ET_EXEC binary) still crashes deeper in library-region
  relocations — findings and two fix paths documented in
  [docs/known-issues.md](docs/known-issues.md).
- `[U-062]` **aarch64 AES/PMULL/SHA feature detection was broken** (`R-502a`).
  `ID_AA64ISAR0_EL1` crypto fields are cumulative (AES: `0b0001`=AES,
  `0b0010`=AES+PMULL; SHA2: `0b0001`=SHA256, `0b0010`=+SHA512), but the
  detectors used exact-equality and `cpu_info` printed `aes` only when
  `has_feat_aes() && has_feat_pmull()` — i.e. `aes==1 && aes==2`, never true —
  so `/scheme/sys/cpu` hid AES even on CPUs that have it. Use `>=` for the
  cumulative fields and print `aes`/`pmull`/`sha2` independently. Verified:
  `-cpu max`, `cortex-a72` and `cortex-a53` now correctly list `sha2 aes pmull`.
  This is the detection channel RedoxFS FDE (U-063) consumes.
- `[U-011]` **`R-401b` — the real aarch64 boot blocker (mis-diagnosed for a whole
  prior session).** `randd` executed `mrs xN, RNDRRS` (FEAT_RNG / ARMv8.5)
  **unconditionally** → an UNDEFINED instruction on non-FEAT_RNG CPUs (Cortex-A72/A53,
  Raspberry Pi, `-cpu cortex-a72`) → `randd` died → the `rand:` scheme never started →
  every daemon that seeds a HashMap panicked `failed to generate random data: ENODEV`
  → no boot. The original report blamed an upstream `redoxfs`/`PAGE_SIZE` memory bug;
  that was **wrong** — redoxfs was the *last* domino. **Fix:** the kernel now traps the
  UNDEF and **emulates RNDR/RNDRRS** in the aarch64 synchronous-exception handler. The
  emulation folds in real **CPU-jitter entropy** per read (CNTVCT timing deltas — the
  jitterentropy technique — not a single-seed PRNG); `eos-kernel @ 35bdc7d3`,
  `upstream/kernel/0004`.
- `[U-012]` **`R-401c` — nvmed never received its PCIe interrupt on aarch64.** aarch64
  has **no MSI**; nvmed hard-coded `intx:false`, and INTx is only *routed* when Redox
  boots from a **device tree**, not ACPI. **Fix:** nvmed runs in **INTx mode** on
  non-x86 (base), and the image boots with **`-machine virt,acpi=off`** so the PCIe
  interrupt-map is present.
- `[U-013]` **`R-401d` — shared PCIe INTx IRQ rejected.** The kernel reserved shared
  INTx GIC SPIs **exclusively**, so `nvmed` failed `open IRQ: EEXIST`. **Fix:** allow
  shared phandle-IRQ opens (the kernel's `irq_trigger` already fans an IRQ out to
  every registered handle).
- `[U-016]` **The aarch64 shell/desktop could not run *any* external program — a
  mis-diagnosed relibc abort.** The prior session logged this as a "cosmetic,
  intermittent `/usr/bin/background` null-deref inside relibc"; it is in fact a
  **deterministic `brk #1` abort** (an explicit trap, *not* a memory fault — `ESR_EL1`
  `EC=0x3C`) that hit **every** `fork`+`exec`-spawned binary — `whoami`, `ls`, `env`,
  `background`, the whole desktop session (16/16 reproductions). Root cause:
  `relibc_start_v1` → `relibc_verify_host` → `Sys::verify()` issues `SYS_YIELD` (a
  Redox-vs-Linux host check) and aborts unless it returns `Ok`; on aarch64 a freshly
  `fork`+`exec`'d process's **first** syscall returns a stale `-1` (the input, never
  overwritten by the kernel) instead of `YIELD`'s `0`, so the check spuriously failed.
  **Fix:** the **`Gh0s777tt/eos-relibc`** fork issues the yield for its side effect but
  does not treat its unreliable result as fatal on aarch64 (x86_64 keeps the strict
  check). Verified by binary disasm **and** boot: `whoami`/`uname`/`ls`/`env` all run with
  **zero aborts**. The deeper kernel bug (the first syscall after `exec` returns a stale
  `x0` on aarch64) is now **fixed at the source in `[U-018]`** — and the real cause turned
  out *not* to be a stale `x0` but a signal-vs-syscall-return ordering bug. With the kernel
  fixed (`[U-018]`), relibc has been **reverted to strict upstream** (`@ bcc1a0d4`) — the
  workaround is gone.
- `[U-018]` **`R-401e` — the aarch64 kernel root cause behind the `verify()` abort
  (`[U-016]`), now fixed in the kernel.** The "first syscall after `exec` returns a stale
  `x0`" diagnosis from the prior session was **wrong**. Real cause: `sched_yield` calls
  `signal_handler` *inside* the `SYS_YIELD` syscall, **before** the aarch64 SVC handler
  commits the syscall return to `scratch.x0`. On aarch64 *alone*, `sig_archdep_reg()` is
  `scratch.x0` — which is **also** the syscall return register (x86/x86_64 use the flags
  register, riscv64 a temporary `t0`). So a signal delivered to a context **during** its
  yield saved the stale syscall *input* `x0` (`verify()`'s `YIELD` passes `!0` in every
  arg) and `sigreturn` restored it over the real return (`0`) — the interrupted program
  then saw `x0 = -1` and aborted. Only `fork`+`exec`'d processes with a signal pending
  during their first yield were hit, which is exactly why shell-spawned `whoami` failed but
  init-spawned daemons did not. **Fix** ([`Gh0s777tt/eos-kernel`](https://github.com/Gh0s777tt/eos-kernel)
  `master` @ `97ca1607`, `core/kernel` recipe re-pinned): commit the yield's return (`0`)
  into the frame **before** the signal check, `cfg`-scoped to aarch64 (the only arch where
  `x0` is the return register). **Validated** by booting the fixed kernel on the
  **unpatched-relibc** image — `whoami`/`uname`/`ls` all run with **0 aborts** (was 16/16) —
  so the kernel fix alone is sufficient. The relibc `[U-016]`/`[U-017]` workaround has
  accordingly been **reverted to strict upstream relibc** (`core/relibc` re-pinned to
  `@ bcc1a0d4`), and R-401e added to `upstream/kernel/0003-*` (the relibc workaround patch
  retired). Verified end-to-end: the rebuilt production image boots **strict** upstream relibc
  on the R-401e kernel with **0 aborts** — disasm confirms the strict `verify()` abort branch
  (`svc; cmn w0,#0x84; b.cs`) is present in the shipped `libc.so`, so it would abort 16/16
  without the kernel fix. **x86_64 non-regression confirmed** — rebuilt + KVM-boot-verified
  with the same recipes (kernel `@ 97ca1607`, strict upstream relibc): `whoami`/`uname` run,
  0 aborts, `uname` reports the x86_64 kernel `@ 97ca1607`; R-401e is `cfg`-scoped so x86_64
  is unaffected.
- `[U-019]` **`R-401f` — aarch64 no longer needs `-machine virt,acpi=off`.** Under a UEFI/ACPI
  boot, `pcid` got the ECAM from MCFG but **no PCIe interrupt-map** (that only exists under a
  device tree), so it could not route legacy **INTx** — `nvmed` hung waiting for its IRQ, which is
  exactly why aarch64 had to force a device-tree boot with `acpi=off`. **Fix** (pcid-only;
  [`Gh0s777tt/eos-base`](https://github.com/Gh0s777tt/eos-base) `@ 6c695a10`): pcid reads
  `\_SB.PCIx._PRT` from acpid's `acpi:/symbols`, resolves each entry's PCI interrupt link device
  (`_SB.Lxxx`) to its GSI via the link's `_CRS` (Extended-Interrupt descriptor), and routes it to
  the matching **GIC SPI** by opening `irq:phandle-0` (phandle 0 = the MADT-registered GIC; aarch64
  builds with `cfg(dtb)` so the phandle IRQ path is available under ACPI). The `_PRT` is read
  **before** pcid registers with acpid, to avoid a deadlock against acpid's AML-interpreter build.
  No kernel or acpid change. **Verified** on the production image: boots with **both** `-machine
  virt` (ACPI) **and** `-machine virt,acpi=off` (device tree) — `nvmed` initializes, redoxfs
  mounts, login reached, `whoami`=`user` in both. (The `/usr/bin/background` data-abort
  occasionally seen in these boots was a then-undiagnosed relibc TLS bug, unrelated to R-401f —
  since root-caused and **fixed in `[U-020]`**.) **Cross-arch
  gate**: the `_PRT` routing is `cfg!`-gated to **non-x86** — on x86/x86_64 legacy INTx is routed
  by plain IRQ line (PIC/IOAPIC) and `irq:phandle-N` does not exist in non-`dtb` kernels, so those
  arches keep their existing path untouched (and pcid no longer risks triggering acpid's AML build
  before registering its `pci_fd`). **x86_64 non-regression verified** with the new base under KVM:
  login reached, 0 aborts, and zero `phandle`/`_PRT` activity in the boot log; aarch64 ACPI boot
  re-verified on the gated rev (`_PRT` routing resolves, nvmed up, login, `whoami`=`user`).
  Upstream: `upstream/base/0002` (single squashed patch, gate included).
- `[U-020]` **`R-402a` — the "intermittent `/usr/bin/background` crash" was a systemic relibc
  TLS-ABI bug on BOTH arches: every thread crashed on exit.** Hunted with a kernel-side fault-map dump
  (`EOS-FAULT`/`EOS-MAP`): ion's background-job threads crashed **deterministically (5/5)** at the
  same PC — symbolized to `relibc::pthread::exit_current_thread` walking `CLEANUP_LL_HEAD`, a
  `#[thread_local]` that read garbage (`8`) instead of NULL. Root cause: relibc's static-TLS
  machinery reused **x86 conventions on aarch64**, leaving three planes inconsistent — module
  images copied at `cum+memsz` (end-relative `Master::offset`) while local-exec reads expect
  `TP+16+offset`, TLSDESC descriptors missing the 16-byte TCB bias (every dynamic TLS access
  shifted −16, boundary variables reading the *neighbouring module's* data), the TPOFF reloc using
  the x86 negative form, `__tlsdesc_dynamic` subtracting the TCB pointer instead of TP (broken
  dlopen TLS), and static binaries' `.tdata` displaced the same way (initializers silently read
  as zeros). "Intermittent" was an illusion: only thread-spawning programs (ion jobs, the
  wallpaper renderer) hit thread-exit, deterministically per build. **The same repro then exposed
  x86_64** — 3/3 ion job threads crashed with a near-null fault at `0x70`, **baseline-verified
  pre-existing on strict unpatched upstream** (no prior x86_64 test had ever spawned `&` jobs).
  Probing it the same way (memory-map dump → symbolization → ld.so module-table trace →
  pthread-key trace) pinned a *different* mechanism: relibc's backwards x86 placement used the
  **raw `p_memsz`** for the distance-from-end while the static linker computes local-exec offsets
  from **`align_up(p_memsz, p_align)`** — for ion (`memsz 0x2c8`, `align 0x10`) the `.tdata` image
  lands 8 bytes above the local-exec plane, overlaying neighbouring thread-locals with shifted
  initializer bytes; Rust std's thread-dtor list head read a shifted nonzero constant and the std
  dtor walked a garbage list at thread exit. (The x86 static-TLSDESC descriptor also had a wrong
  sign — corrected too, though no current binary emits it.) **Fix**
  ([`Gh0s777tt/eos-relibc`](https://github.com/Gh0s777tt/eos-relibc) branch `eos-tls`
  `@ 0d30e9ea`, one clean commit over upstream `bcc1a0d4`, `core/relibc` re-pinned): explicit
  per-arch offset conventions — x86/x86_64 keep the backwards layout but with **alignment-correct
  placement** and a correctly signed TLSDESC; aarch64/riscv64 use forward, `p_align`-aligned
  start-based offsets with the aarch64 TCB bias in TLSDESC/TPOFF, and the dynamic resolver
  subtracts TP. **Verified**: the ion job repro goes **5/5 → 0 (aarch64)** and **3/3 → 0
  (x86_64)**; full production boots on both arches stay clean. Upstream has no fix for this
  (checked `master`); upstream-ready patch in `upstream/relibc/0001-*`. The patch also adds a
  **regression test** (`tests/pthread/tls_initexit.c`, registered in the relibc suite) that
  exercises both failure modes — thread-local `.tdata` initializers read by spawned threads,
  and a clean thread exit (the cleanup-stack/destructor walks over the TLS block) — so this
  can never silently come back. Upstream bug-fix patch count is now **4 kernel + 2 base + 1
  relibc**.
- `[U-023]` **e1000e — the default `q35` NIC — now binds.** QEMU's `q35` default NIC is
  the Intel 82574L (`8086:10d3`); the stock `e1000d` PCI map omitted it, so default-q35
  networking bound no driver. `e1000d` is register-compatible with the 82574L, so a
  `/usr/lib/pcid.d/e1000e.toml` overlay (`config/x86_64/eos.toml`) makes it bind and
  initialise the card — verified end-to-end on the built eos image (`qemu -device e1000e`).
- `[U-024]` **Restored license files.** `LICENSE` (AGPL-3.0) + `licenses/Redox-OS-MIT.txt`
  on the meta repo and `LICENSE` (MIT) on the six `eos-*` forks had been removed; restored
  from git history so AGPL-3.0 distribution and Redox's MIT attribution are intact again.
- `[U-025]` **License restore completed on non-default branches.** `[U-024]` only covered
  the default branches; `LICENSE` was still missing on `lts/0.1`, `eos-base`,
  `archive/redox-0.4.1` and `archive/redox-mirror-2019` (meta repo, both remotes) and on
  `eos-relibc` branch `eos-tls` (the branch the `core/relibc` recipe pins). Restored on
  all of them (cherry-pick of `48ec6293` / reverts of the "Delete LICENSE" commits).

### Known
- `[U-015]` aarch64 now boots under **both** ACPI (`-machine virt`) and device tree
  (`-machine virt,acpi=off`); the `acpi=off` workaround is **no longer required** as of
  `[U-019]` (`R-401f`). The GitLab mirror (`gitlab.com/Gh0s777tt/e-os`) is kept **in sync**
  with GitHub.

### Planned
- See **[ROADMAP.md](ROADMAP.md)** for what's coming in `v0.2.0` and beyond.

---

## [0.1.0] — "Genesis" — 2026-06-06

> 🎉 **First verified-bootable E-OS base.** E-OS is re-founded on **modern upstream
> Redox OS** (the 2019 mirror is archived) and boots end-to-end under QEMU/KVM.

### Added
- `[0.1.0-001]` **Modern Redox base.** Re-based onto upstream Redox build system
  commit `84d78137` (`0.9.0-6174`), Rust toolchain `nightly-2026-05-24`, full
  **COSMIC desktop** config (`config/desktop.toml`).
- `[0.1.0-002]` **Reproducible build environment**: WSL2 Ubuntu + rootless
  **Podman 5.7** (crun), **QEMU 10.2.1** with KVM. Documented in
  [`EOS_BUILD_STATE.md`](EOS_BUILD_STATE.md).
- `[0.1.0-003]` **Verified boot.** `build/x86_64/desktop/harddrive.img` (681 MB,
  RedoxFS 647 MiB) boots: UEFI → bootloader → kernel → init → drivers
  (`nvmed`, `ahcid`, `xhcid`, `ihdad`, `e1000d`) → `login:` prompt.
- `[0.1.0-004]` **E-OS brand & repo identity** — Netflix-red/black README,
  documentation set, changelog, roadmap, branding assets.

### Changed
- `[0.1.0-005]` **License → AGPL-3.0.** E-OS as a whole is now strong-copyleft
  (anti-appropriation). Inherited Redox components remain **MIT**; original
  notices preserved in `licenses/Redox-OS-MIT.txt` and [`NOTICE`](NOTICE).
- `[0.1.0-006]` Original Redox `README` preserved at `docs/REDOX-README.md`.

### Fixed
- `[0.1.0-007]` **Headless build crash.** `repo cook` panicked
  `slice index starts at 1 but ends at 0` (`src/bin/repo.rs:1693`) when its TUI
  ran without a real terminal (`panel_height == 0`). **Resolution:** build with
  **`CI=1`** to disable the TUI (`config.rs`: `tui = !(CI set & non-empty)`).
- `[0.1.0-008]` **KVM permissions** for `make qemu` — user added to the `kvm`
  group (`/dev/kvm` is `root:kvm 0660`).

### Security
- `[U-067]` **pkgar-core: `read_at` no longer panics on a truncated package (`R-F03`)** —
  `PackageBuf::read_at` called `buf.copy_from_slice(&src[start..end])`, but `calculate_range`
  clamps `end` to the source length, so a truncated/short `.pkgar` (or an offset past the end)
  made `end-start != buf.len()` and the copy **panicked** — reachable from the install/update
  trust path via a crafted short archive. It now copies only the available bytes and returns
  the real count; the absolute offset in `read_entry` uses `checked_add` against a hostile
  `entry.offset`. Regression test `read_at_truncated_source_does_not_panic`
  (`cargo test -p pkgar-core`: 3 ok). Fork `eos-pkgar` `ee2bcb2a`→`cb8ae7b`; recipe pin bumped.
  Also **verified `R-F01`** (the audit's plaintext-password print) does **not** reproduce on the
  shipping installer rev `05bf2eb` — it was a stale-clone artifact, tracked by `R-F02`.
- `[0.1.0-009]` Strong-copyleft licensing (AGPL-3.0) adopted as a deliberate
  anti-appropriation measure for the distribution.

### Provenance
- Verified base saved on both remotes as branch **`eos-base`** + tag
  **`eos-base-2026-06-06`** (commit `60ba2d1e`). The 2019 Redox mirror is
  retained on the legacy `master` (GitLab) / `0.4.1` (GitHub) branches.

---

[Unreleased]: https://github.com/Gh0s777tt/E-OS/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Gh0s777tt/E-OS/releases/tag/v0.1.0
