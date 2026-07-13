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
