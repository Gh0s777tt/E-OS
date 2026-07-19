# Changelog

All notable changes to E-OS, following [Keep a Changelog](https://keepachangelog.com)
and [Semantic Versioning](https://semver.org). Every change is numbered `[U-NNN]`.
History before `U-071` predates this file and lives in the git log (`git log`).

## [Unreleased]

### Added & Changed
- `[U-104]` **netsurf: fix the first-render crash — the browser renders now (`R-D06` ✅)** — meta-repo
  only (`recipes/web/netsurf/recipe.toml`, `docs/design-netsurf-pie.md`). After U-103 the PIE netsurf
  loaded and opened a window, but the body stayed black and it crashed on the first content render — a
  **use-after-munmap of the 800×600×4 window buffer** (`funmap length 0x1d4c00` = 1,920,000 = 800·600·4
  was the tell; fault `FAR` offset `0xf83` = near the top-left of that buffer). Chain, read from source:
  libnsfb (`surface/sdl.c`) caches `nsfb->ptr = SDL surface pixels`; the Redox SDL orbital driver backs
  that with `orb_window_data()` (orbclient's mmap of the window); a `SDL_RESIZABLE` window makes
  orbclient's `Window::events()` `unmap`+`remap` that buffer on the resize event orbital sends on first
  map — invalidating the pointer libnsfb still holds → netsurf's first plot writes into freed memory.
  Fix: a `sed` in the recipe drops `SDL_RESIZABLE` from libnsfb's two `SDL_SetVideoMode` sites, so
  orbclient's `resizable` stays false and the buffer is never remapped out from under `nsfb->ptr`.
  **Verified (boot + screendump):** netsurf renders `welcome.html` in full — toolbar, address bar, the
  NetSurf logo image, headings, links, a search box (`assets/screenshots/eos-netsurf-welcome.png`); the
  serial no longer logs an `UNHANDLED EXCEPTION` for `netsurf-fb`. Trade-off: the window is fixed-size
  for now (proper resize = libnsfb re-fetching the pointer after each remap; tracked as `R-D07`).
- `[U-103]` **netsurf: build from source as a PIE (partial — `R-D06`)** — meta-repo only
  (`recipes/web/netsurf/recipe.toml`, `scripts/redoxer-host-stub.sh`, `docs/design-netsurf-pie.md`).
  The browser died the instant it was clicked (data abort, `ESR 0x92000047`): the image shipped the
  **upstream non-PIE `ET_EXEC` prebuilt** (pulled by `--repo-binary`), and aarch64-Redox only loads PIEs.
  A from-source build was itself blocked because `host:gperf` builds via `cookbook_redoxer`, whose
  `toolchain()` tried to **download a host→host relibc toolchain that redox never publishes → 404**
  (`unable to init toolchain`). Fixes: **(1)** `scripts/redoxer-host-stub.sh` pre-creates the per-target
  `~/.redoxer/<host>/toolchain` stub so redoxer skips the misfired download (host builds use system
  `gcc`/`g++`); it never touches the real cross toolchain. **(2)** a **CC-wrapper** in the recipe forces
  `-fPIC` on every compile and `-pie` on the final link. Verified: `host:gperf` + `cook netsurf` now build
  from source; `netsurf-fb` is a `DYN`/`pie executable` (`readelf`/`file`) both staged and inside the
  image; with the recipe now differing from upstream, `--repo-binary` no longer re-downloads the prebuilt
  (local pkgar stays byte-identical). **Runtime: partial** — the PIE `netsurf-fb` now *loads, runs and
  opens an 800×600 window* on the desktop (boot + screendump; the load-time crash is gone), **but** the
  window body stays black and it then crashes during the first content render — a deterministic-location
  data abort (crash `ELR` page-offset `0x718`, `FAR` offset `0xf83`). That render crash is a separate,
  deeper netsurf-on-Redox bug and stays open under `R-D06`; full analysis in `docs/design-netsurf-pie.md`.
- `[U-102]` **Notifications: a minimal daemon + client (`eos-notifyd` / `eos-notify`)** — `R-D03`
  (eos-orbutils `60c262d → 8ad7cd8`). E-OS had no way to surface "updates available" / driver events.
  Adds two launcher-crate binaries: **`eos-notifyd`** polls `/tmp/eos-notify` for a `"title\nbody"`
  message and shows it as a crimson **top-right toast** (orbclient, `WindowFlag::Front`, rounded panel +
  accent bar, ~4 s auto-dismiss); **`eos-notify <title> [body]`** writes that file. The launcher spawns
  `eos-notifyd` alongside `desktop`/`background`. Deliberately **minimal** — the file transport is a
  placeholder for a proper `notify:` scheme / socket, and a toast blocks new ones while up — but enough
  for the update daemon (`R-705`) to notify. Verified: the launcher crate cross-compiles all five bins;
  both `eos-notify`/`eos-notifyd` staged to `/usr/bin`; aarch64 image cooked; **render-verified** —
  `eos-notify "Aktualizacje" "…"` popped the themed toast top-right (`assets/screenshots/eos-notify-toast.png`).
- `[U-101]` **Status tray: real icons + click-to-Settings** — first step of `R-D02` (eos-orbutils
  `7b1268b → 60c262d`). The launcher loaded `/usr/share/ui/icons/status/tray-{net,vol,set}.png`, but those
  files **never existed anywhere**, so the tray was invisible *and* a dead click target. Ship three 32-px
  crimson glyphs — a signal-bars network icon, a speaker with sound arcs, a settings gear — staged by the
  recipe to `/usr/share/icons/status` (which `/usr/share/ui/icons` symlinks to); and make a click anywhere
  on the tray open **E-OS Settings** (`draw()` records the tray's x-span, which depends on the clock-text
  width, and the bar's click handler hit-tests it). This lands the R-D02 "gear launches Settings" goal now
  that the Settings shell (`R-D01`) exists. Verified: aarch64 image cooked from the pin with the icons
  staged; **render-verified** — the bar now shows the three tray glyphs left of the clock, and clicking the
  tray opens the E-OS Settings window (`assets/screenshots/eos-tray-settings.png`). Live state reflection
  (net from netstack, a volume popup via audiod — audio is absent on the QEMU dev loop) is the R-D02 follow-up.
- `[U-100]` **Compositor screenshot — Super-P → `/home/user/screenshot-N.bmp`** (`R-D04`; eos-orbital
  `7ee7c04 → 38226c7`). E-OS had no screenshot tool, and a standalone one **can't** work: orbital is the
  DRM master, so the full composited desktop image exists only in orbital's own CPU shadow buffer — the
  capture has to live in the compositor. **Super-P** copies that shadow buffer (`Display::screenshot`) and
  writes it as an uncompressed 32-bit (BGRA) BMP via a tiny hand-rolled encoder — **no image-codec
  dependency** — with a per-shot counter so captures don't overwrite. Adds `Compositor::displays_mut` and
  a shortcuts-list entry. Verified: orbital cross-compiles for `aarch64-unknown-redox`; aarch64 image
  cooked from the pin; **render-verified end-to-end** — pressing Super-P created `/home/user/screenshot-0.bmp`
  of exactly **1,920,054 bytes** (= 54-byte header + 800×600×4), a valid BMP (magic `BM`, header 800×600),
  and the file, **extracted from the image via redoxfs and viewed**, shows the real desktop at that instant
  (icons, taskbar with the `U-098` local-time clock, and — since Super was held — the shortcuts overlay,
  which now lists the new *"Super-P: Screenshot"* entry). `assets/screenshots/eos-screenshot-selfshot.png`.
- `[U-099]` **Launcher Start-menu type-to-search — completes `R-D05`** (eos-orbutils `94dcc91 → 7b1268b`).
  Opening Start showed a fixed category list with no keyboard input. The top-level menu now carries a
  **search box**: typing filters a flat list of **every** app by name (case-insensitive) and shows a live
  **result count**; **Enter** launches the highlighted (or first) match, **Backspace** narrows, **Esc**
  closes, and an empty query restores the category view (nothing regresses). The query is fed from
  orbital **`TextInput`** events — a `Key` event carries only the scancode, which is why the first
  attempt (reading `key_event.character`) typed nothing. The Start window is created **once at a
  worst-case fixed height** and never resized or recreated, so it keeps focus (stays open while typing)
  and never clips results — resizing a live transparent window clipped later matches, and recreating it
  dropped focus and closed the menu. Verified: launcher cross-compiles for `aarch64-unknown-redox`;
  aarch64 image cooked from the pin; **render-verified** — the Start menu reads *"Szukaj: vi_
  (3 wyników)"* and shows all three matches (`GVim`, `Viewer`, `Vim`) with the menu staying open. With
  `U-098` this closes `R-D05` (search **+** local-time clock).
- `[U-098]` **Launcher clock: local date + timezone (was UTC `HH:MM` only)** — first half of `R-D05`.
  The bar clock computed `ts % 86400` straight from `CLOCK_REALTIME`, so it showed raw **UTC** with no
  date. The launcher (`eos-orbutils` `cf121dc → 94dcc91`) now reads a timezone offset (seconds east of
  UTC) from **`/etc/tz-offset`** — a distinct path from Debian's zone-*name* file — falling back to a
  numeric `TZ` env, default UTC; applies it; and renders the full local **`YYYY-MM-DD  HH:MM  UTC±H`**
  via a small Howard-Hinnant civil-from-epoch helper (no `chrono` dependency), at 1× font (the string is
  wider than the old `HH:MM`). Ships a default **`/etc/tz-offset = 7200`** (UTC+2, Poland CEST — correct
  for the current season) in `config/{aarch64,x86_64}/eos.toml`. A fixed offset has **no DST/named-zone**;
  that waits on a tz database + per-machine timezone at OOBE (`R-606`). Verified: launcher cross-compiles
  (`cargo check` for `aarch64-unknown-redox`); aarch64 image cooked from the pin + config; **render-verified**
  — captured at host **UTC 10:58**, the bar reads **`2026-07-19  12:58  UTC+2`** (exactly +2 h), fed by
  the shipped `/etc/tz-offset`. Remaining half of `R-D05`: type-to-search in the Start menu.
- `[U-097]` **E-OS Control v3 — rank processes by memory + a total-memory readout** (a task
  manager's first job is answering "what's eating my RAM?"; the list was in kernel order, which
  doesn't). Bumps `eos-control` recipe pin `fed7e32 → 7729720`. The Processes tab now **ranks rows
  by private memory descending** — groups by their *summed* total, instances within an expanded
  group likewise, ties broken by name so refreshes stay deterministic — so the biggest users float
  to the top. The aggregate is surfaced too: a new **"Pamięć (prywatna)"** tile on Overview and a
  **"N procesów · X pamięci · wg pamięci ↓"** footer on the Processes tab, both fed by a summed
  `Overview.mem_bytes`. Verified: cross-build links for `aarch64-unknown-redox`; host `--selftest`
  green; aarch64 image cooked from the pinned rev; **GUI render-verified** on the image — Overview
  shows *"Pamięć (prywatna) 468.4 MB"*, and the Processes list is ordered strictly by the memory
  column (`redoxfs` 81.3 MB → `virtio-netd ×3` 65.7 MB → `background ×2` 46.4 MB → `eos-control`
  39.5 MB → `login ×3` 29.2 MB) with the footer reading *"44 procesów · 468.4 MB pamięci · wg
  pamięci ↓"*. Grouping, human labels and force-kill from `U-096` remain intact.
- `[U-096]` **E-OS Control v2 — process grouping + force-kill on the Processes tab** (user's request:
  don't scatter duplicate windows like Windows' task manager, and let me force-close a stuck process).
  Bumps `eos-control` recipe pin `af7a932 → fed7e32`. **Grouping:** many instances of one program (a
  browser with several windows is the motivating case) collapse into a single `name ×N` header carrying
  the *summed* private memory and the *union* of the group's open resources; collapsed by default for a
  tidy view, expand/collapse remembered per app name — no more hunting duplicates down a flat list.
  **Force-kill:** select a process and confirm (the dialog names the exact pid + process) to end it; on
  Redox this is `libredox::call::kill` with `SIGKILL` — relibc routes it to the kernel's unblockable
  **ForceKill** (the raw `redox_syscall` crate no longer exposes `kill`), POSIX `kill(2)` on a host.
  `selftest.rs` gains an end-to-end kill proof (spawn a child, force-kill it, confirm it dies ≤3 s) and a
  byte parse/format roundtrip that underpins the group memory sums. Verified: cross-build links for
  `aarch64-unknown-redox`; host `--selftest` green (system + security + **kill** + byte roundtrip);
  aarch64 image cooked from the pinned rev; on the image, **GUI render-verified** — the Processes tab
  shows live group headers (`[init] ×3` 25.4 MB, `logd ×2` 7.5 MB) beside ungrouped single rows, and a
  selected process (`PID 52 /usr/bin/sleep`) is force-killed through the confirm dialog → status
  *"Zakończono PID 52"*; the boot/console selftest marker `EOS-CONTROL-SELFTEST-OK` proves `kill_core`
  (spawn + ForceKill + confirm-gone) on the **real E-OS kernel**. (A force-killed process may linger
  briefly as an unreaped zombie in `sys:context` until its parent reaps it — standard Unix semantics,
  not a kill failure; the manager faithfully shows what the kernel reports.)
- `[U-095]` **E-OS Control — one unified control center replaces the separate system + security tools** —
  new pinned repo `eos-control` (dev+CI: gitlab.com/e-os/eos-control, GitHub mirror; AGPL-3.0-or-later),
  recipe `recipes/gui/eos-control`, shipped in `config/{aarch64,x86_64}/eos.toml` **instead of**
  `eos-sysmon` + `eos-guard` (whose repos remain, archived). One tabbed app: **Overview** (system health),
  **Processes**, and **Security**. Rationale (the user's call — why split security/monitoring across apps?):
  on a capability-secure microkernel *what a process can touch* is at once its resource profile and its
  security profile, so they're two views of one truth. The Processes tab is a task manager meant to beat
  Windows': every process carries a **human label** ("orbital = desktop server", "pcid = PCI driver
  manager") so cryptic names never lose you, and a **capability inspector** shows, per process, exactly
  which schemes/resources it holds open (parsed from `sys:iostat`) — impossible on Windows. The Security
  tab is the ported `eos-guard` (blake3 integrity baseline + diff, permission audit, tamper-evident
  digest). Built on the shared `eos-ui`; `sys:` scheme reads on Redox, `/proc` on a host.
  `eos-control --selftest` proves both the system and security cores (`EOS-CONTROL-SELFTEST-OK`). Verified:
  cross-build + host selftest green; aarch64 image build + boot-smoke; boot probe prints the selftest
  marker on the serial; GUI render-verified (all three tabs) on the image.
- `[U-094]` **E-OS Sysmon — the third original app (system monitor), first built straight from the app
  guide** — new pinned repo `eos-sysmon` (dev+CI: gitlab.com/e-os/eos-sysmon, GitHub mirror;
  AGPL-3.0-or-later), recipe `recipes/gui/eos-sysmon`, enabled in `config/{aarch64,x86_64}/eos.toml`,
  launcher entry + crimson icon (`usr/share/ui/apps/50_eos-sysmon`). A Crimson system monitor: system
  identity, logical CPU count and the **live process list** (2 s refresh), read from the kernel `sys:`
  scheme (`sys:uname` / `sys:cpu` / `sys:context`); a host build reads `/proc` so the CLI/selftest half
  stays honest. It's the first app written **directly from the new `docs/creating-an-eos-app.md`
  skeleton** — logic (`sysinfo.rs`) split from UI, GUI behind the default `gui` feature on the shared
  `eos-ui` backend, no storage — and it cross-built for `aarch64-unknown-redox` and passed
  `EOS-SYSMON-SELFTEST-OK` on the first try, validating the guide. Verified: cross-build + host selftest
  green; aarch64 image build + boot-smoke; boot probe prints `EOS-SYSMON-SELFTEST-OK` on the serial;
  GUI render-verified on the image.
- `[U-093]` **Documentation standard + tooling — `CLAUDE.md`, `ARCHITECTURE.md`, an app guide, a docs PDF,
  and enforcement** — makes "every change updates its docs" an explicit, discoverable, partly-enforced
  standard. Adds **`CLAUDE.md`** (the working agreement: three verification gates, a Definition of Done, a
  documentation map, code/comment standards, hosting invariants — linked from `CONTRIBUTING.md`), a root
  **`ARCHITECTURE.md`** (top-down layer map + hosting, cross-linked with `docs/architecture.md`),
  **`docs/creating-an-eos-app.md`** (the `eos-ui`-based app skeleton pattern), and a downloadable
  **docs PDF**: `scripts/docs-pdf.sh` renders the mdBook `print.html` with headless Chromium (no fragile
  PDF plugin — verified locally, 3.6 MB / whole manual) and a self-hosted `docs-pdf` CI job publishes it
  (`needs: []`, `allow_failure`, tags/schedules). Enforcement: `docs-currency` now also advises on new
  public items missing a doc-comment, `eos-ui` gains `#![warn(missing_docs)]` (clean), a
  `.gitlab/merge_request_templates/Default.md` carries the Definition-of-Done checklist, and
  `scripts/eos-check.sh` gives a fast per-crate compile check before a full image rebuild. Also restores
  `docs/design-desktop-environment.md` + `docs/design-xhcid-nonblocking-transfers.md`, which the GitLab
  migration had dropped (they existed only in the stale Desktop checkout). The mdBook build was verified
  locally (35 pages, `print.html`, new pages listed in `SUMMARY.md`).
- `[U-092]` **Heavy `build-image` detached from the shared-runner light tier (`needs: []`)** — the
  self-hosted `eos-heavy` OS build + boot-smoke — the only job that actually boots the OS — spends no
  shared CI minutes, but sat in a stage after the light tier, so a `ci_quota_exceeded` failure there
  skipped it. `needs: []` (on `build-image` and the manual x86_64 variant) makes OS verification survive an
  exhausted free-tier budget. Verified: with the whole light tier failing on quota, `build-image` still ran
  and passed on `eos-heavy`. See [docs/ci.md](docs/ci.md) *CI minutes*. The cap itself is a resource choice
  (monthly reset / buy minutes / a light-tier self-hosted runner).
- `[U-091]` **`pages` must not block the OS build (`allow_failure`)** — the docs-publish job runs on
  budget-limited shared runners and failed with `stuck_pending_no_matching_runners` once free minutes were
  spent; because `docs` sits before `build`, that hard failure had skipped `build-image` and reddened
  `main`. `allow_failure: true` keeps a cosmetic docs hiccup from failing the pipeline or blocking OS
  verification.
- `[U-090]` **Guard v2 — a permission audit on every scan + a tamper-evident baseline** — two hardening
  additions to `eos-guard` (`544476b`→`0626360`, v0.1.0→v0.2.0). (1) **Permission audit:** every scan now
  flags setuid (`0o4000`), setgid (`0o2000`) and world-writable (`0o0002`) files as **OSTRZEŻENIE**
  regardless of whether they changed — so a setuid binary is surfaced on the very first scan, not only if
  it's modified (v1 only warned on world-writable *unchanged* files). (2) **Baseline integrity digest:**
  `set_baseline` records a blake3 digest over the canonical (path-sorted) baseline rows in `meta`; a scan
  recomputes it and reports **⚠ WZORZEC NARUSZONY** if the baseline was edited out of band or corrupted —
  a file-integrity monitor whose baseline can be silently rewritten is theatre. (Honest scope: the digest
  lives in the same DB, so it catches corruption and naive tampering, not an attacker who also recomputes
  it; a key-signed baseline is the `R-711` class, future work.) The `--selftest` grew matching assertions:
  a setuid file in the throwaway tree must produce a WARN, a fresh baseline must pass its own digest, and a
  raw out-of-band `UPDATE baseline SET hash=…` must be caught (`verify_baseline()` returns false). Verified:
  cross-build for `aarch64-unknown-redox` + host `GUARD-SELFTEST-OK`; eos-guard CI green; aarch64 image
  build + boot-smoke, `GUARD-SELFTEST-OK` on the serial console.
- `[U-089]` **E-OS Guard — the second E-OS original application: a filesystem integrity monitor
  (blake3 + SQLite), and the first proof that `eos-ui` carries a second app** — new pinned repo
  `eos-guard` (dev+CI: gitlab.com/e-os/eos-guard, GitHub mirror; AGPL-3.0-or-later), recipe
  `recipes/gui/eos-guard`, enabled in `config/{aarch64,x86_64}/eos.toml`, launcher entry + crimson shield
  icon (`usr/share/ui/apps/40_eos-guard`). Guard baselines directory trees — the blake3 hash + size/mode/
  mtime of every regular file, stored in SQLite/WAL at `~/.local/share/eos-guard/baseline.db` — and diffs
  a later scan against the baseline, surfacing **ZMIENIONY** (hash changed), **NOWY**, **USUNIĘTY**, and
  **OSTRZEŻENIE** (a world-writable security lint), with a colour-coded Crimson Slint UI (roots field,
  Baseline/Scan buttons, summary chips, findings list). blake3 is the portable-Rust build
  (`default-features = false` — the same hash `pkgar`/the SBOM use); SQLite is bundled with
  `-DSQLITE_DISABLE_LFS`; scans are capped at 20k files so a huge tree can't wedge the single-threaded
  event loop. **The whole GUI is one `eos_ui::init("E-OS Guard")` call** — Guard reuses the `U-088`
  shared backend with zero new platform code, validating the crate for a second consumer. `eos-guard
  --selftest` is the headless proof (baseline a throwaway tree → assert a clean re-scan is all-OK →
  mutate/add/remove files → assert the diff reports exactly 1 MODIFIED + 1 NEW + 1 REMOVED, and WAL is
  active), printing `GUARD-SELFTEST-OK`; wired into the repo CI and used as a boot probe. Verified:
  blake3 cross-compiles for `aarch64-unknown-redox`; eos-guard CI green; cross-build against the
  git-pinned `eos-ui` + host selftest green; aarch64 image build + boot-smoke, `GUARD-SELFTEST-OK` on the
  serial console, and the app window renders + scans via clicks (screendumps `assets/screenshots/`).

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
- `[U-084]` **Fork CI revived — pipelines run in the `e-os` namespace (9 forks) + collective build-neutral
  pin bump** — upstream `.gitlab-ci.yml` workflow rules gate pipelines to `$CI_PROJECT_NAMESPACE ==
  "redox-os"` (or to a branch name the fork doesn't develop on — `eos-pkgutils` lives on `eos`), so every
  pipeline in these forks was silently dead in the `e-os` namespace. The 9 affected forks (kernel, relibc,
  base, redoxfs, pkgutils, orbclient, orbital, orbutils, liborbital) now add a namespace-only rule ahead of
  the upstream arms (branch names vary — `eos-july`/`eos`/`master` — so the rule must not depend on them);
  QEMU-based test jobs (`redoxer exec/test`) are `allow_failure` because gitlab.com shared runners have no
  KVM — they run best-effort and cannot permanently redden the pipeline (real boot coverage stays with the
  heavy `build-image` boot-smoke). All 9 files validated via the GitLab CI lint API; pushed to GitLab +
  GitHub before the bump. The revived gates paid off on the very first runs: `fmt` caught unformatted
  E-OS code in **three** forks (pkgutils `pkg-lib`; base drivers — daemon/rtl8139d/usbnetd/pcid/raid1d/
  xhcid/virtio-core; relibc `ld_so` — all reformatted, zero semantic change), and pkgutils'
  `cargo test --locked` exposed a **stale `Cargo.lock`** from `U-081`: the R-703 ed25519 code shipped
  without its lock entries (the image build never noticed — the cook doesn't build `--locked`); the lock
  now adds exactly the ed25519-dalek dependency tree, no existing entry changes, and the CI test command
  passes (2/2). redoxfs `test:linux` is gated best-effort — the FUSE unmount races the test's
  `remove_dir` on shared runners (environment flake, not a code failure). First fully green pipelines:
  **kernel** (fmt + x86_64/aarch64/i586/riscv64gc builds; even the QEMU boot test passed on a shared
  runner), orbclient, orbital, orbutils, liborbital. Pins bumped collectively (build-neutral: CI rules +
  formatting + lockfile only), `pins --strict` 22 ok / 0 drift; verified by aarch64 container build +
  boot-smoke. Docs: [docs/ci.md](docs/ci.md) gained a *Fork pipelines* section.
- `[U-086]` **E-OS Notes — the first E-OS original application ships in the image (Slint 1.17 +
  SQLite/WAL over a custom Orbital backend)** — new pinned repo `eos-notes` (dev+CI:
  gitlab.com/e-os/eos-notes, GitHub mirror recipes fetch from; AGPL-3.0-or-later), recipe
  `recipes/gui/eos-notes`, enabled in `config/{aarch64,x86_64}/eos.toml`, launcher entry + crimson icon
  (`usr/share/ui/apps/30_eos-notes`). Sidebar with substring search, autosaving title+body editor,
  WAL-mode SQLite at `~/.local/share/eos-notes/notes.db`; `eos-notes --selftest` is the headless storage
  proof (create → reopen → readback → search → delete + `journal_mode == wal`), gated in the repo CI and
  used as a boot probe. **The stack choice is the real story:** the backlog's *iced* is a dead end (the
  Redox iced fork is 0.6 — no multiline text widget; modern iced/libcosmic is blocked by host:gperf on
  the aarch64 build host), and BOTH winit paths fail on today's Redox — slint ≥1.13's winit backend does
  not even compile for Redox (unconditional x11 imports, orbital lacks pump_events), while the
  upstream-proven slint 1.1.1 + winit 0.28 pair aborts at runtime because its event loop opens the
  legacy `event:` scheme the modern kernel removed (ENOSYS). E-OS therefore drives modern Slint through
  its **own `slint::platform::Platform` over orbclient** (`src/orbital_platform.rs`:
  MinimalSoftwareWindow + SoftwareRenderer → ARGB swizzle into the orbital window; orbital events →
  slint pointer/key/scroll/resize; timers drive animations), with the image's DejaVu TTFs registered
  into fontique at startup (fontique has no Redox font discovery — an empty collection panics the
  renderer) and a `/scheme/orbital` DISPLAY default for shell launches. Bundled SQLite builds with
  `-DSQLITE_DISABLE_LFS` (relibc ships no LFS64 aliases); the GUI sits behind the default `gui` feature
  so hosts/CI build the CLI half with `--no-default-features`. **Verified:** eos-notes CI green; aarch64
  image build + boot-smoke PASS; the boot probe prints `EOS-NOTES-SELFTEST-OK` on the serial console
  (0 panics); GUI render-verified on the image — the window shows sidebar/editor and a live `0 notatek`
  status straight from SQLite (screendumps `assets/screenshots/eos-notes-v1.png` and
  `eos-notes-desktop-icon.png`). Full interactive verification (mouse + typing) landed in `U-087`.
- `[U-088]` **`eos-ui` — the Slint-on-Orbital backend is now a shared crate; `eos-notes` consumes it** —
  extracted the ~200-line custom `slint::platform::Platform` (software renderer over orbclient:
  pointer/keyboard/scroll/resize + the `TextInput` glyph path) and the fontique bootstrap out of
  `eos-notes` into a new reusable library, new repo `eos-ui` (dev+CI: gitlab.com/e-os/eos-ui, GitHub
  mirror; AGPL-3.0-or-later). A GUI app is now one `eos_ui::init("Title")` call away from a window
  (no-op on non-Redox hosts, so a host development build still works). `eos-notes` drops its inlined
  `orbital_platform.rs` + `register_system_fonts` and takes `eos-ui` as a rev-pinned git dependency
  (`c53180d`); `orbclient` and the `unstable-fontique-010` feature move into `eos-ui`. Done now — before
  the second GUI app (guard/veil) exists — so the backend is written once, not copy-pasted. The window
  title is parameterized (was hard-coded `E-OS Notes`); behaviour is otherwise identical. Verified:
  `eos-ui` cross-checks clean for `aarch64-unknown-redox` and its CI is green; `eos-notes`
  (`bad75e5`→`9f9eae6`) cross-builds against the git-pinned `eos-ui` + host selftest green; aarch64 image
  build + boot-smoke, `EOS-NOTES-SELFTEST-OK` on the serial, and the app window still renders.
  `eos-ui` is tracked in `repos.toml` (a git dependency locked by each consumer's `Cargo.lock`, not a
  standalone image package).
- `[U-087]` **E-OS Notes verified fully interactive — and a headless GUI click-harness that proves it** —
  drove the built image end-to-end with real input events: the mouse cursor tracks, the desktop
  **E-OS Notes** icon highlights on hover, a **double-click opens the app window**, the sidebar `+` button
  **creates a note** (status flips `0 notatek`→`1 notatek`, a dated row appears — a live SQLite `INSERT`
  with a correct `2026-07-18` timestamp, i.e. `U-083`'s RTC working), and **typed text now lands in the
  title/body fields**. Two findings on the way: (1) the earlier "mouse doesn't work" belief was a
  **harness bug, not E-OS** — QEMU HMP `mouse_move` is *relative* and never drives an absolute device;
  QMP `input-send-event` with `abs` axes reaches the usb-tablet fine (cursor moved to exactly the sent
  `value·resolution/32767`). (2) A real backend bug: **typed glyphs never reached a focused field** —
  orbital delivers printable characters as a separate `TextInputEvent` (inputd runs the scancode through
  the active keymap, then *clears* `character` on the following `KeyEvent`, which carries only
  navigation), and the orbclient platform backend only handled `KeyEvent`. Now it handles
  `EventOption::TextInput` → `WindowEvent::KeyPressed` (Enter/Backspace/arrows still come through the
  KeyEvent scancode path; no double-insert since those KeyEvents carry `character='\0'`). eos-notes
  `5ca5c49`→`bad75e5`. **Proven end-to-end on the built image** (`assets/screenshots/eos-notes-typed.png`):
  launched `eos-notes` from the GUI terminal → clicked `+` (a note appears, `Zapisano`/saved) → clicked the
  title, typed **`ghost`** → clicked the body, typed **`eos dziala`** (with a space) — both land in the
  fields, autosaved to SQLite. Harness notes for the next run: log in by **clicking** the greeter's
  Password field + Login button (keyboard focus on the modal greeter is unreliable); the desktop-icon
  double-click is flaky under QMP timing (launch from the taskbar terminal instead); `sendkey` only
  covers lowercase/space/minus (a QEMU-monitor limit, not E-OS). Verified: cross-build + host selftest
  green, aarch64 image build + boot-smoke, interactive click/type screendumps.

### Fixed
- `[U-085]` **Standalone installer writes the right EFI boot file without env `TARGET`; virtio drivers no
  longer abort on a legacy-only device** — two backlog follow-ups, pins bumped. **eos-installer**
  `75b6bd5`→`f9d82a1`: `get_target()` read only the `TARGET` env var (with a compile-time fallback) and
  defaulted to `x86_64-unknown-redox` — a standalone run without the env wrote `BOOTX64.EFI` into an
  aarch64 disk's ESP, which boots to the EFI shell. The target now resolves as `TARGET` env >
  `[general] target` (new config field, set in `config/*/eos.toml`) > compile-time `TARGET` > warned
  default, and is carried explicitly via `DiskOption::target` (TUI/GUI in-image installs keep the baked
  compile-time target). **Proven at the artifact level** (fixed installer, local cookbook, no `TARGET` in
  the env): config `target=aarch64-unknown-redox` → `EFI/BOOT/BOOTAA64.EFI`, PE machine ARM64; no target
  anywhere → a warning + the historical `BOOTX64.EFI` (PE x86-64). The fork's `gui-build` CI job also got
  an image (it ran on the runner default, no cargo — permanently red). **eos-base** `544d76d`→`d633641`:
  `virtio-core::probe_device` expect-panicked (= abort) when a device exposed no modern (virtio 1.0) PCI
  capabilities, so a pure-legacy virtio device took the driver down (the `T9`/harness class). Missing
  capabilities now map to the existing `Error::InCapable`; the first legacy-only boot-probe then caught the
  second half of the bug — the drivers' own `daemon_runner` wrappers `.unwrap()`-ed the returned error,
  turning it right back into an abort — so virtio-netd/blkd/gpud now log the error and `process::exit(1)`
  cleanly. QEMU exposes a transitional device only with `disable-legacy=off,disable-modern=off`.
  Verified: aarch64 container build + boot-smoke PASS, plus a legacy-only boot-probe
  (`virtio-net-pci,disable-modern=on` attached): serial shows `virtio-core: … legacy-only devices are
  unsupported` → `virtio-netd: exiting: the device is incapable of Common` → a clean spawner-logged exit,
  0 panics, boot reaches `eos login:`.
- `[U-083]` **aarch64 system clock no longer stuck at 1970 on an ACPI boot — TLS cert validation unblocked** —
  the kernel only programs the RTC on a Device-Tree boot (`rtc::init`, reached from `init_devicetree`); the
  E-OS aarch64 image boots via UEFI/ACPI (since `R-401f`), so `init_devicetree` never ran, the clock stayed at
  the Unix epoch, and every TLS certificate-validity check failed (a silent blocker for HTTPS, package updates,
  and the browser). Fixed **without a kernel/ABI change**: the **bootloader** (`eos-bootloader`
  `f1ba665`→`05dadec`) already runs in UEFI, so it reads the firmware wall-clock via Runtime Services `GetTime`
  and exports it to the kernel env as `BOOT_TIME=<unix_secs>` (new `Os::boot_time_epoch()`, overridden only for
  UEFI; `days_from_civil` converts the broken-down UTC). **`rtcd`** (`eos-base` `dd41f1da`→`efc07c3e`), which was
  a no-op on aarch64, now reads `BOOT_TIME` from `/scheme/sys/env` and writes the offset to
  `/scheme/sys/update_time_offset` — the same sink x86 uses for the CMOS RTC. Platform-independent (works on
  QEMU + real UEFI hardware); absent `BOOT_TIME` (e.g. a BIOS boot) is a no-op. Both pieces compile-verified
  (bootloader for `aarch64-unknown-uefi`, rtcd for `aarch64-unknown-redox`) before pinning.
- `[U-082]` **Installer GUI produced a non-bootable disk; randd trusted failed rdrand (`G1`, entropy)** —
  two audit-surfaced fork fixes, pins bumped. **eos-installer** `05bf2eb`→`75b6bd5`: the GUI installer read
  the bootloader from the stale path `<root>/boot/bootloader.{bios,efi}` (removed years ago — the `bootloader`
  package installs to `usr/lib/boot/`, and the TUI already reads from there). The `else` branch silently
  substituted an empty buffer, so a GUI install wrote a **0-byte `EFI/BOOT/*.EFI`** and the disk would not
  boot; the GUI now reads `usr/lib/boot/` like the TUI. **eos-base** `a5cf1b0c`→`dd41f1da`: `randd` read the
  x86 `rdrand` instruction without checking the carry flag (CF=0 ⇒ generation failed, destination is 0) and
  marked the RNG seeded regardless — it now retries up to 10× per word, reads CF via `setc`, and only sets
  `have_seeded` when every word succeeded. Verified: aarch64 heavy build + boot-smoke; the x86 `rdrand` path
  is exercised by the manual `build-image-x86_64` job (it is `cfg(target_arch = "x86_64")`).
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
