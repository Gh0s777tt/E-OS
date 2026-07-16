# Changelog

All notable changes to E-OS, following [Keep a Changelog](https://keepachangelog.com)
and [Semantic Versioning](https://semver.org). Every change is numbered `[U-NNN]`.
History before `U-071` predates this file and lives in the git log (`git log`).

## [Unreleased]

### Added & Changed

- `[U-071]` **E-OS Settings — native Crimson control panel (`R-D01`, Foundation B)** — new
  `eos-settings` bin in the launcher crate (eos-orbutils `061dfd3`): an orbital/orbclient panel host with
  NO libcosmic/fontconfig dependency (builds on the aarch64 host, dodges the cosmic-settings toolchain gap),
  crimson sidebar (System, Security, Updates, Drivers, Network, Display, Audio, Date&Time, User). Real
  System/Security/clock data; Update/Driver panes are honest stubs tagged with their roadmap codes. Ships
  `apps/15_eos-settings` + a crimson gear icon. Verified: compiles for aarch64-unknown-redox, links,
  installs, integrated, and RUNS against the live orbital server (PID 51, no crash). Pixel-render not
  screenshotted under QEMU due to `R-F08`.
- `[U-072]` **Graphical session no longer blocked by audio (`R-F07`) + display regression surfaced (`R-F08`)**
  — greeter `20_orbital` had `requires_weak … 20_audiod.service`; `audiod` exits without signalling readiness
  on machines without working audio (aarch64 QEMU `ihdad` I/O-fails), so the desktop session hung and the
  greeter never started — a P0 daily-driver regression hidden because recent work used the text getty.
  Dropped the audiod dependency in `config/desktop-minimal.toml`; verified `orbital` now starts
  (`/scheme/orbital` present). Open (`R-F08`): orbital runs but its output doesn't reach the QEMU ramfb
  (greeter on VT3, not visible) — see [docs/known-issues.md](docs/known-issues.md).
- `[U-073]` **R-D01 Settings render-verified end-to-end + `R-F08` root-caused** — booted the aarch64
  image to the graphical desktop (fix `R-F07`) and confirmed the `eos-settings` window renders correctly:
  crimson sidebar with all 9 panels, real System data (`aarch64`, Genesis), themed footer
  (`assets/screenshots/eos-settings-panel.png`, `eos-desktop.png`). The desktop is reached with `Super+F3`;
  `R-F08` (greeter VT not auto-activated on boot) root-caused to `inputd` activating only the first-created
  VT (the bootlog wins after the init reorg) — downgraded P0→P1 with fix candidates in
  [docs/known-issues.md](docs/known-issues.md).
- `[U-074]` **`R-F08` fully root-caused** (docs only) — instrumented `inputd` to trace the VT
  lifecycle on the serial console: the greeter renders on VT3, then the lazy `fbcond` text-console
  service (`00_fbcond`, VT2) spawns after orbital and its display-open activates VT2, stealing the
  framebuffer. `getty 2`, `on_close` and the keyboard were ruled out. Precise trace + three fix
  candidates in [docs/known-issues.md](docs/known-issues.md); no code shipped (instrumentation reverted).
- `[U-075]` **vesad: don't panic on a malformed bootloader-env line (`R-F09`)** — `vesad`
  (`drivers/graphics/vesad/src/main.rs`) parsed `/scheme/sys/env` with `line.split_once('=').unwrap()`,
  aborting the display driver on any line without `=` (found while debugging `R-F08`). Now uses `filter_map`
  to skip malformed lines. `cargo check` `aarch64-unknown-redox`: clean. Fork `eos-base` `d4f193c9`→`98f22879`;
  recipe pin bumped.
- `[U-076]` **First-boot forces a password on the shipped passwordless account (`R-602`)** — the
  `login` program (eos-userutils) now, in its blank-password branch, runs `passwd <user>` (as root, before
  the shell starts) in a loop until a password is set, so the default `user` (no password) can no longer log
  straight into a shell. **Verified end-to-end in aarch64 QEMU**: `login: user` → `E-OS first-boot setup` →
  `passwd` → `Password set.` → shell (`assets/screenshots/eos-oobe-firstboot.png`). Closes the live P0
  default-creds exposure for the text/getty login path. Fork `eos-userutils` `260d7725`→`b12240d`; recipe pin
  bumped. Follow-ups: the graphical greeter (`orblogin`) blank-password path and root's weak default
  `password` (not caught by `is_passwd_blank`).
- `[U-077]` **First-boot also forces a change of the default `root/password` (`R-602`)** — extends
  `U-076`: `login` (eos-userutils) now refuses to open a shell for an account still using the shipped
  default password. The blank-password loop and a new default-password check share one helper
  (`force_first_boot_passwd`); the check is **order-independent** — since `root`'s hash isn't blank
  (`is_passwd_blank` can't catch it), it triggers whenever `password` is actually used to log in.
  **Verified end-to-end in aarch64 QEMU**: `login: root` + `password` → `The account 'root' is using the
  default password.` → `passwd` → `Password set.` → `root:~#` shell
  (`assets/screenshots/eos-oobe-root.png`). This retires the second half of the live P0 default-creds
  exposure (`root/password`) on the text/getty path. `cargo check` `aarch64-unknown-redox`: clean. Fork
  `eos-userutils` `b12240d`→`799088a`; recipe pin bumped. Remaining `R-602` follow-up: the graphical
  greeter (`orblogin`) login path and per-machine identity (hostname/locale/keymap/machine-id/SSH keys).
- `[U-079]` **The graphical greeter now enforces the first-boot password too (`R-602`)** — closes the
  final, and since `R-F08` the **default**, exposure: the desktop greeter (`orblogin`, eos-orbutils) let a
  default-credential account (blank `user`, or `root`/"password") log **straight to the desktop** because
  it only called `verify_passwd` (a blank password verifies against `""`). It now runs the same first-boot
  rule as the text `login`, in-window: on a default-credential login it switches to **New password → Confirm
  password**, sets the password (`set_passwd` + `save`), and only then starts the session. **Verified
  end-to-end in aarch64 QEMU** (keyboard-driven): boot → greeter → empty password → `First-boot setup: /
  New password:` → `Confirm password:` → full crimson desktop (`assets/screenshots/eos-greeter-setpw.png`,
  `eos-desktop-after-oobe.png`). Fix detail worth noting: `save()` needs `Config::default().writeable(true)`
  — plain `Config::default()` opens the users DB read-only (`EBADF` on save), the same builder `passwd`
  uses. Field labels update live (the panel is re-rendered on the mode switch). Fork `eos-orbutils`
  `061dfd3`→`3ac6436`; recipe pin bumped. This makes the P0 shipped-default-credentials exposure closed on
  **every** login path (text/getty + serial + graphical greeter). Remaining `R-602`: per-machine identity
  (hostname/locale/keymap/machine-id/SSH host keys).

### Fixed
- `[U-081]` **Security-fix pins land in the image — base/redoxfs/pkgutils bumped (K-01, K-06, UB fix, R-703)** —
  three deferred fork fixes, verified by the heavy-tier CI build + QEMU boot-smoke, are now pinned into the
  built image: **eos-base** `98f22879`→`a5cf1b0c` (K-01: `raid1d` validates the superblock before assembling;
  K-06: `randd` mixes CNTVCT+splitmix jitter into the seed after the RNDRRS loop; `pcid` resolves link-GSI by
  walking ACPI resource descriptors instead of scanning raw `0x89` bytes), **eos-redoxfs** `ce461328`→`ec25394`
  (vendored `cpufeatures`: `from_utf8_unchecked` on `/scheme/sys/cpu` replaced with validated `from_utf8` —
  removes UB on malformed scheme output), **eos-pkgutils** `master@7e89ac2e`→`eos@5643d21` (R-703: client-side
  ed25519 verification of the `repo.toml` manifest signature + regression test rejecting a tampered index).
  The GitHub mirrors for `eos-base`/`eos-redoxfs` (which recipes fetch from) were fast-forward-synced first —
  they lagged the GitLab source of truth. `repos.toml` pins regenerated to match.
- `[U-080]` **Live-ISO text console (VT2) works again — `getty 2` no longer starved at boot (`R-601`)** —
  on the live ISO the fbcon text console (`Super+F2`) was black: `getty 2` never ran, so install-to-disk could
  not be driven from a text login. Root-caused (4-way parallel source analysis + empirical mount-diff) to the
  E-OS-custom `25_raid1d.service` being declared **`type = "notify"`**. `init` drains services on a single
  thread and blocks on a `notify` service until it signals readiness; `raid1d` calls `daemon.ready()` only
  **after** `assemble()` probes every `/scheme/disk.*` (open R+W + read the trailing 4 KiB superblock). On the
  live medium that probe hits the physical NVMe the bootloader read from, whose I/O stalls on an INTx IRQ that
  never routes on aarch64 (the `R-401d`/`R-501` platform bug) — so `raid1d` never signals ready, `init`'s drain
  freezes, and `30_console` (queued immediately after it, and after both the greeter `20_orbital` and the
  dep-free `30_serial-getty.service`) never spawns `getty 2`. The on-disk filesystem is byte-identical between
  live and installed (verified by mounting both images and diffing `/usr/lib/init.d` — every file md5-identical),
  which **corrects** the earlier "a live init.d fallback lacks `getty 2`" hypothesis: the fault was purely
  runtime. **Fix:** `config/{aarch64,x86_64}/eos.toml` set `25_raid1d.service` to **`type = "oneshot_async"`** —
  nothing does `requires_weak 25_raid1d` and root is mounted by `50_rootfs` in the initfs phase (never from
  `disk.raid1`), so `init` gains nothing by awaiting raid1d and can spawn it and move on. **Verified end-to-end
  in aarch64 QEMU**: the live ISO's `Super+F2` now shows the full getty
  (`assets/screenshots/eos-live-vt2-getty.png`) — E-OS issue banner + `eos login:` (bright 3846 px vs 0 before)
  — with the greeter (VT3) and bootlog (VT1) unchanged and boot still landing straight on the greeter (`R-F08`
  intact). Config-only, no `init`/`raid1d` code change; both arches in parity. Unblocks the `R-601`
  install-to-disk harness. Deeper hardening tracked as a follow-up (raid1d should `ready()` before
  `assemble()`, and `init`'s notify wait should time out so no single service can freeze boot).
- `[U-078]` **Boot lands directly on the graphical greeter — no more `Super+F3` (`R-F08`)** — the
  aarch64 image now boots straight to the crimson E-OS greeter (`assets/screenshots/eos-greeter.png`),
  zero key presses. Real root cause, found via an `inputd` serial trace (it **corrects** the earlier
  display-handoff hypothesis in `U-073`/`U-074`): the VT-2 activation is the init service
  `/usr/lib/init.d/30_console` running **`inputd -A 2`**. The installer concatenates all `[[files]]`
  with no dedup (`redox_installer`'s `Config::merge` → `files.extend`), and because `desktop.toml`
  includes BOTH `desktop-minimal.toml` and `server.toml` (each pulling `minimal.toml`), the
  `server→minimal` copy of `30_console` (with `inputd -A 2`) lands **last** on disk and wins — stealing
  the foreground to the text console (VT2) *after* `20_orbital` activates the greeter's VT3. **Fix:**
  `config/{aarch64,x86_64}/eos.toml` (the root config, merged dead-last) pins `30_console` **without**
  `inputd -A 2` — the VT2 getty stays reachable via `Super+F2`, and `requires_weak 20_orbital` orders it
  after the greeter. Config-only; no `inputd`/recipe code change (instrumentation reverted). Both arches
  kept in parity. Full trace + reasoning in [docs/known-issues.md](docs/known-issues.md).
