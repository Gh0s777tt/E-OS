---
title: Installing E-OS
status: current
last-reviewed: 2026-08-31
owner: Gh0s777tt
---

# 💿 Installing E-OS

E-OS ships a **graphical installer** as well as a text installer and the raw disk
image — pick whichever fits. Before anything, **verify your download** (see
[hardening.md](../security/hardening.md)):

```sh
# No CI-published signed download exists yet — GitHub Actions is disabled on the
# account (see ROADMAP R-004). Build locally, then verify against the checksums
# the build emits:
scripts/make-release.sh          # -> release/eos-<ver>-<arch>.img              (installed system)
                                 #    release/eos-<ver>-<arch>-installer.img    (write this to USB)
                                 #    release/SHA256SUMS
( cd release && sha256sum -c SHA256SUMS )        # verify BOTH artefacts
# If you signed with the release key, also:
#   minisign -Vm release/SHA256SUMS -p keys/eos-release.pub
```

---

## 1. Just try it (no install)

The release image **is** a bootable system. Run it in a VM:

```sh
make CONFIG_NAME=eos qemu          # x86_64, KVM-accelerated
# or boot build/x86_64/eos/harddrive.img in any UEFI VM (NVMe disk)
```

Default logins: **`user`** (no password) · **`root`** / `password`
— **change these** before real use ([hardening.md](../security/hardening.md)).

### The installation medium (USB)

Besides the pre-installed `harddrive.img`, E-OS builds a **bootable installation
medium** — it boots the full system (greeter + `installer-gui`) so you can try it and
then install to a real disk, exactly like a Linux live USB:

```sh
make CI=1 ARCH=x86_64 CONFIG_NAME=eos live      # or ARCH=aarch64
# -> build/x86_64/eos/eos-0.2.0-x86_64-installer.img
```

Ask the build system for the name rather than typing it — it carries the version, so it
changes when `EOS_VERSION` does:

```sh
make print-installer-medium ARCH=x86_64 CONFIG_NAME=eos
```

> **This artefact was renamed in `R-611a`**; if you have an older command line that
> builds a live *ISO*, that target no longer exists — the old filename is recorded in
> `ROADMAP.md` under `R-611a`. The file genuinely *is* ISO 9660 with a hybrid MBR+GPT, so
> the old name was not a lie about the format. It was a lie about the **use**: `.iso`
> tells you to burn a disc, and E-OS has no optical-drive driver, so that disc could not
> boot. Write it with `dd` (§4).

Both arches boot this medium to `eos login:` under QEMU/UEFI ("Switching to live disk"
-> E-OS 0.1.0 "Genesis" -> login, 0 exceptions on aarch64 **and** x86_64). Two caveats,
because neither is cosmetic:

- The greeting says **0.1.0 "Genesis"** while the medium is named **0.2.0**. That is not
  a typo here: `config/*/eos.toml` still stamps `0.1.0 (Genesis)` into `/etc/os-release`
  while `EOS_VERSION` names the artefacts. Reconciling the two is its own change.
- **Every boot claim in this repository is QEMU.** Firmware on a real machine is not
  QEMU's firmware; that first bare-metal run is `R-607b`, and it is open.

![E-OS graphical greeter booted from the aarch64 installation medium](../img/eos-aarch64-live-iso-greeter.png)

## 2. Graphical install (recommended)

E-OS includes **`redox_installer_gui`** — open **“Installer”** from the desktop
launcher (the red **E** menu). It walks you through:

- choosing the **target disk**,
- a **RedoxFS disk-encryption password (recommended)** → encrypted root
  (see [encryption.md](../guides/encryption.md)); an empty password installs unencrypted,

then writes E-OS to the disk. Reboot and remove the install medium.

> ⚠️ **It does not create accounts, and it does not let you pick packages.** The
> installer clones the defaults from the image config, so a fresh install lands
> with the shipped accounts — a **passwordless `user`** and **`root` / `password`**
> — and the package set baked into the image. You are not asked to change them
> during install: the first login forces a password change instead (the OOBE, on
> both the text console and the graphical greeter). Account/hostname/locale
> collection at install time is `R-603`, still open.

## 3. Text install (headless)

For servers / no-GUI installs, run the TUI installer:

```sh
redox_installer_tui            # prompts for disk + RedoxFS password
```

The TUI has the same limits as the GUI above: no account creation, no package
selection (`installer_tui` TODO#3 is unimplemented — `R-603`).

Both front-ends drive the same engine (`redox_installer`); a config-file install is also
supported, where `[general] encrypt_disk = "…"` enables FDE non-interactively:

```sh
redox_installer /dev/sdX --config=install.toml     # disk is POSITIONAL, config is a flag
```

> Earlier versions of this page had these the other way round (`redox_installer
> <config.toml> <disk>`). That was wrong, and not harmlessly: the first positional
> argument is the **install target**, so following the old line would have pointed the
> installer at your TOML file. Measured in installer revision `74726c889b`, which was the pin until 2026-09-01 (now `2aae3ace0bbf`) --
> `src/bin/installer.rs:208` takes `parser.args.first()` as the path handed to
> `redox_installer::install(config, path)`, while the config comes from `-c/--config`.

## 4. Flash the image directly

The `harddrive.img` is a ready GPT/UEFI disk image — write it straight to a USB
stick or disk:

```sh
sudo dd if=build/x86_64/eos/harddrive.img of=/dev/sdX bs=4M conv=fsync status=progress
```

(Replace `/dev/sdX` with the real device — this **erases** it.) This path does not
prompt for encryption; use the installer (2/3) if you want an encrypted root.

### Installation USB — the on-ramp to real hardware

For trying E-OS on a machine without touching its disks, write the **installation
medium** instead. It carries the whole filesystem and is loaded into RAM at boot, so
nothing is written to the host:

```sh
make CI=1 ARCH=x86_64 CONFIG_NAME=eos live
MEDIUM=$(make -s print-installer-medium ARCH=x86_64 CONFIG_NAME=eos)
sudo dd if="$MEDIUM" of=/dev/sdX bs=4M conv=fsync status=progress
```

From a release rather than a build tree, write the file `make-release.sh` packaged and
check it first — its hash is in the same `SHA256SUMS` the release signature covers:

```sh
( cd release && sha256sum -c SHA256SUMS )
sudo dd if=release/eos-0.2.0-x86_64-installer.img of=/dev/sdX bs=4M conv=fsync status=progress
```

It is a **raw GPT image with a protective MBR**, so `dd` is the right tool, not an ISO
burner. Boot the target in **UEFI** mode. The bootloader offers `l` to disable live mode;
left alone it copies the filesystem (**1.37 GiB**, measured) into RAM and lands on
`eos login:`.

> **What to expect on real hardware.** E-OS has not been validated on metal — every
> boot claim in this repo is QEMU. The upstream results in [HARDWARE.md](../../HARDWARE.md)
> are the best available forecast, and the recurring pattern there is *boots to the
> desktop, but touchpad/USB input and networking do not work*. That matches the known
> gaps: no I2C bus driver (`R-916`) blocks I2C-HID touchpads, and wired NIC coverage is
> thin (`R-910`). A boot that reaches the greeter without a working trackpad is the
> expected first result, not a regression — and reporting it is genuinely useful, since
> the hardware matrix currently has no E-OS rows at all.

## Architectures

- **x86_64** — boots end-to-end to the Crimson desktop (UEFI, NVMe). Both the
  pre-installed image and the installation medium boot to `eos login:` with 0 exceptions,
  under QEMU.
- **aarch64** — **boots to the graphical E-OS greeter/login** under QEMU `virt` (UEFI),
  and the installation medium boots the same way (verified). The early-boot blockers that once
  stopped it (`R-401b` FEAT_RNG emulation and the follow-on PCIe-INTx / signal-ordering
  fixes) are **fixed** — see `upstream/`. The extra **COSMIC apps** (store/settings/reader)
  are still deferred on aarch64 because their `fontconfig → host:gperf` build dependency
  publishes a redoxer host toolchain only for x86_64-linux build hosts; the base desktop
  (greeter, cosmic-edit/files/term, orbital) is present. Build aarch64 on an x86_64-linux
  host to get the full COSMIC app set.

See also: [getting-started.md](index.md) · [building.md](building.md).
