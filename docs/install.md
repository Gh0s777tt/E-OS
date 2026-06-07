# 💿 Installing E-OS

E-OS ships a **graphical installer** as well as a text installer and the raw disk
image — pick whichever fits. Before anything, **verify your download** (see
[hardening.md](hardening.md)):

```sh
minisign -Vm SHA256SUMS -p eos-release.pub   # key: keys/eos-release.pub
sha256sum -c SHA256SUMS                        # checks the .img files
```

---

## 1. Just try it (no install)

The release image **is** a bootable system. Run it in a VM:

```sh
make CONFIG_NAME=eos qemu          # x86_64, KVM-accelerated
# or boot eos-0.1.0-x86_64.img in any UEFI VM (NVMe disk)
```

Default logins: **`user`** (no password) · **`root`** / `password`
— **change these** before real use ([hardening.md](hardening.md)).

## 2. Graphical install (recommended)

E-OS includes **`redox_installer_gui`** — open **“Installer”** from the desktop
launcher (the red **E** menu). It walks you through:

- choosing the **target disk**,
- creating **users / passwords**,
- an optional **RedoxFS disk-encryption password** → encrypted root
  (see [encryption.md](encryption.md)),
- the package set,

then writes E-OS to the disk. Reboot and remove the install medium.

## 3. Text install (headless)

For servers / no-GUI installs, run the TUI installer:

```sh
redox_installer_tui            # prompts for disk, users, encryption, packages
```

Both GUIs drive the same engine (`redox_installer`); a config-file install is also
supported (`redox_installer <config.toml> <disk>`), where
`[general] encrypt_disk = "…"` enables FDE non-interactively.

## 4. Flash the image directly

The `harddrive.img` is a ready GPT/UEFI disk image — write it straight to a USB
stick or disk:

```sh
sudo dd if=eos-0.1.0-x86_64.img of=/dev/sdX bs=4M conv=fsync status=progress
```

(Replace `/dev/sdX` with the real device — this **erases** it.) This path does not
prompt for encryption; use the installer (2/3) if you want an encrypted root.

## Architectures

- **x86_64** — boots end-to-end to the COSMIC desktop (UEFI, NVMe).
- **aarch64** — the image builds with full branding and boots the E-OS bootloader
  under QEMU `virt`; full boot-to-login awaits an upstream RedoxFS fix
  (ROADMAP `R-401b`). Treat aarch64 as experimental.

See also: [getting-started.md](getting-started.md) · [building.md](building.md).
