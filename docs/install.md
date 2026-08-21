# 💿 Installing E-OS

E-OS ships a **graphical installer** as well as a text installer and the raw disk
image — pick whichever fits. Before anything, **verify your download** (see
[hardening.md](hardening.md)):

```sh
# No CI-published signed download exists yet — GitHub Actions is disabled on the
# account (see ROADMAP R-004). Build locally, then verify against the checksums
# the build emits:
scripts/make-release.sh                         # -> release/eos-<ver>-<arch>.img + SHA256SUMS
( cd release && sha256sum -c SHA256SUMS )        # verify the images
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
— **change these** before real use ([hardening.md](hardening.md)).

### Live / installer medium (USB-style, read-only)

Besides the pre-installed `harddrive.img`, E-OS builds a **bootable live ISO** — a
read-only medium that boots the full system (greeter + `installer-gui`) so you can try
it and then install to a real disk, exactly like a Linux live USB:

```sh
make CONFIG_NAME=eos ARCH=x86_64  build/x86_64/eos/redox-live.iso   # or ARCH=aarch64
# → boot the .iso in a UEFI VM, or flash it to a USB stick (dd, see §4)
```

Both arches are **verified** to boot the live ISO to `eos login:` (QEMU/UEFI: "Switching
to live disk" → E-OS 0.1.0 "Genesis" → login, 0 exceptions on aarch64 **and** x86_64):

![E-OS graphical greeter booted from the aarch64 live ISO](img/eos-aarch64-live-iso-greeter.png)

## 2. Graphical install (recommended)

E-OS includes **`redox_installer_gui`** — open **“Installer”** from the desktop
launcher (the red **E** menu). It walks you through:

- choosing the **target disk**,
- a **RedoxFS disk-encryption password (recommended)** → encrypted root
  (see [encryption.md](encryption.md)); an empty password installs unencrypted,

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
supported (`redox_installer <config.toml> <disk>`), where
`[general] encrypt_disk = "…"` enables FDE non-interactively.

## 4. Flash the image directly

The `harddrive.img` is a ready GPT/UEFI disk image — write it straight to a USB
stick or disk:

```sh
sudo dd if=build/x86_64/eos/harddrive.img of=/dev/sdX bs=4M conv=fsync status=progress
```

(Replace `/dev/sdX` with the real device — this **erases** it.) This path does not
prompt for encryption; use the installer (2/3) if you want an encrypted root.

### Live USB — the on-ramp to real hardware

For trying E-OS on a machine without touching its disks, build the **live image**
instead. It carries the whole filesystem and is loaded into RAM at boot, so nothing
is written to the host:

```sh
make CI=1 ARCH=x86_64 CONFIG_NAME=eos live      # -> build/x86_64/eos/redox-live.iso
sudo dd if=build/x86_64/eos/redox-live.iso of=/dev/sdX bs=4M conv=fsync status=progress
```

Despite the `.iso` name it is a **raw GPT image with a protective MBR**, so `dd` is
the right tool (not an ISO burner). Boot the target in **UEFI** mode. The bootloader
offers `l` to disable live mode; left alone it copies the ~1.4 GB filesystem into RAM
and lands on `eos login:`.

> **What to expect on real hardware.** E-OS has not been validated on metal — every
> boot claim in this repo is QEMU. The upstream results in [HARDWARE.md](../HARDWARE.md)
> are the best available forecast, and the recurring pattern there is *boots to the
> desktop, but touchpad/USB input and networking do not work*. That matches the known
> gaps: no I2C bus driver (`R-916`) blocks I2C-HID touchpads, and wired NIC coverage is
> thin (`R-910`). A boot that reaches the greeter without a working trackpad is the
> expected first result, not a regression — and reporting it is genuinely useful, since
> the hardware matrix currently has no E-OS rows at all.

## Architectures

- **x86_64** — boots end-to-end to the Crimson desktop (UEFI, NVMe). Both the
  pre-installed image and the live ISO boot to `eos login:` with 0 exceptions.
- **aarch64** — **boots to the graphical E-OS greeter/login** under QEMU `virt` (UEFI),
  and the live ISO boots the same way (verified). The early-boot blockers that once
  stopped it (`R-401b` FEAT_RNG emulation and the follow-on PCIe-INTx / signal-ordering
  fixes) are **fixed** — see `upstream/`. The extra **COSMIC apps** (store/settings/reader)
  are still deferred on aarch64 because their `fontconfig → host:gperf` build dependency
  publishes a redoxer host toolchain only for x86_64-linux build hosts; the base desktop
  (greeter, cosmic-edit/files/term, orbital) is present. Build aarch64 on an x86_64-linux
  host to get the full COSMIC app set.

See also: [getting-started.md](getting-started.md) · [building.md](building.md).
