# eos-power: privileged reboot / shutdown from the GUI

**What this is:** the design of `eos-power`, the small privileged shim behind
E-OS Control's *Zasilanie* (power) tab, and the security reasoning for it. Read
it before touching `src/power.rs` in eos-control or the power path in `sys.rs` /
`ui/control.slint`. Shipped in U-109 (`R-D11`).

## The problem

Powering the machine off or rebooting means writing the kernel control
`sys:kstop` (`"shutdown"` / `"reboot"`) — the same mechanism coreutils `shutdown`
uses. That control is **root-only**. But E-OS Control is a desktop GUI launched
by the logged-in **user**, so a direct write returns `EPERM (Operation not
permitted)`. The button needs to run one privileged action without the app being
privileged.

## What we do

A dedicated, short-lived binary **`eos-power`** performs the elevation, exactly
the way `sudo` does it *internally* (Redox does not honour setuid bits for
privilege — elevation goes through the `sudo` daemon + scheme namespaces):

1. Open `/scheme/sudo`.
2. Write the user's password to it. The daemon checks **sudo-group membership +
   the password**; a wrong password / non-member returns `EPERM` here and we
   stop — no elevation.
3. Elevate our own process: `call_wo(dup(redox_cur_procfd_v0()), CallFlags::FD)`
   hands the daemon our process fd, and it raises our uid to 0.
4. `setns` into the elevated namespace the daemon prepared.
5. Now root: write `action` to `/scheme/sys/kstop`. The machine goes down.

E-OS Control drives it like this: the *Zasilanie* tab arms an action
(two-step confirm), reveals a **password field** (`input-type: password`), and on
confirm spawns `eos-power reboot|shutdown` and **pipes the password to its
stdin**. It waits for the shim: exit 0 = authenticated and `sys:kstop` written
(the machine is going down); non-zero = bad password / no permission, surfaced in
the status line.

## Why this shape (alternatives rejected)

- **Run E-OS Control itself as root** — rejected: a large Slint GUI (fonts, image
  decoders, an SQLite baseline, a network read) is far too much attack surface to
  hand uid 0. Here the GUI is **never** elevated; only the ~40-line
  single-purpose `eos-power` child is, and only for the microseconds between
  authenticating and writing `sys:kstop`.
- **A setuid `eos-power`** — rejected: Redox is a capability/namespace system and
  does not grant privilege from a setuid bit the way traditional Unix does;
  elevation must go through the `sudo` daemon.
- **Spawn `sudo shutdown`** — rejected: Redox `sudo` reads its password with
  `read_passwd` from a **TTY**, which a GUI-spawned child doesn't have, so it
  can't be fed non-interactively. Talking to `/scheme/sudo` ourselves lets us
  supply the password directly from stdin.
- **Empty-password shortcut** — ruled out by testing: the desktop user's password
  is *not* empty (first-boot sets it; a shell login as `user` with an empty
  password returns `Login incorrect`). So a real password is required, hence the
  dialog.

## Security properties

- **GUI never runs as root.** Only the throwaway `eos-power` process elevates.
- **Password-gated.** No password (or a wrong one, or a non-sudo user) → no
  elevation; `/scheme/sudo` enforces it.
- **Minimal capability.** `eos-power` does exactly one thing after elevating —
  write `sys:kstop`. It does not `exec` an arbitrary command. Blast radius even if
  it were abused is a **local reboot/poweroff**, which requires the user's
  password + local access anyway (a password-holding user could already run
  `sudo shutdown`). It does not broaden what such a user can already do.
- **No password leakage.** The password is passed on **stdin**, never argv, so it
  never appears in `ps`; it lives only transiently in the GUI's memory and the
  field is cleared after confirm.

Covered in the threat model under §4 *Privileged GUI actions*
(`docs/threat-model.md`).

## Verification

End-to-end, on the aarch64/QEMU loop: arm *Wyłącz*, type the password, confirm —
the **QEMU process exits**, i.e. the guest powered off (the clean, unambiguous
proof; `assets/screenshots/eos-control-power.png` shows the password dialog).
Root `shutdown -r` likewise triggers a reboot, though EDK2 has a separate
warm-reboot firmware flake under QEMU-aarch64, so poweroff is the tidy proof.

The elevation build surface is real and pinned: `libredox 0.1.18` with the
`mkns` feature, `redox_syscall 0.9` (imported as `syscall`), and the
`redox_cur_procfd_v0` relibc hook. `eos-power` is a second `[[bin]]` in the
eos-control crate (`default-run = eos-control`), installed to `/usr/bin` beside
the GUI.
