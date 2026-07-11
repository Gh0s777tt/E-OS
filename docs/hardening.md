# 🔧 E-OS Hardening Guide

> Practical steps to reduce the attack surface of an E-OS install. Companion to the
> [Threat Model](threat-model.md), [Disk Encryption](encryption.md) and
> [Security Policy](../SECURITY.md). E-OS is pre-1.0 — apply judgement.

The default desktop image favours **convenience** (a passwordless `user`, a known
`root:password`) so it boots straight to a usable desktop. **Before any real use,**
work through the checklist below.

---

## ✅ Checklist (most impact first)

1. **Change the default credentials.** The shipped `user` has no password and
   `root` is `password`. Set strong passwords:
   ```sh
   passwd            # current user
   sudo passwd root  # root
   ```
   Passwords are hashed with **argon2** (`redox_users`).

2. **Encrypt the disk.** Install (or re-create) E-OS on a **RedoxFS AES-XTS-128**
   encrypted root so a lost/stolen device protects data at rest. See
   [encryption.md](encryption.md). This is the single biggest win against the
   *physical/lost-device* adversary.

3. **Run the latest tag.** Only the latest release + `main` get security fixes
   (see [SECURITY.md](../SECURITY.md)). Track releases and rebuild.

4. **Verify what you boot.** Check release artifacts before flashing:
   ```sh
   minisign -Vm SHA256SUMS -p eos-release.pub   # key: keys/eos-release.pub
   sha256sum -c SHA256SUMS
   ```
   Or **build from source** — E-OS recipes are pinned to the
   `github.com/Gh0s777tt/eos-*` forks and reproduce all branding from a clean clone.

5. **Minimize the package set.** The desktop image is large. For servers /
   appliances, build a slimmer config (e.g. `CONFIG_NAME=server` or a custom
   `config/<arch>/<name>.toml`) so unused code never ships. Less code = less surface.

6. **Reduce exposed services.** The network stack runs **in userspace**, but you
   still shouldn't run what you don't need. Don't enable the demo SSH config
   (`server-demo.toml` sets `PermitEmptyPasswords yes` — **never** in production).

7. **Use least-privilege scheme namespaces.** A user's reachable **schemes** define
   its authority. Tighten `/etc/login_schemes.toml` to drop schemes a given user
   doesn't need (network, audio, …). This is E-OS's capability-style sandboxing.

8. **Avoid working as root.** Use a normal user; escalate with `sudo` only when
   required. The microkernel + scheme model already contains userspace faults — keep
   ambient authority low.

## 🧱 Defense-in-depth E-OS gives you for free

- **Memory-safe** kernel + drivers + userland (Rust) — no buffer-overflow class.
- **Userspace drivers / netstack / fs** — a compromise is a *process*, not the kernel.
- **Capability schemes** — least privilege by construction.
- **`overflow-checks` in the release kernel** — E-OS builds `eos-kernel` with
  `overflow-checks = true` (upstream Redox does not), so an *unintended* integer
  overflow — a classic exploit primitive even in safe Rust — is a controlled abort
  (`panic = "abort"`), not a silent wrap. Intentional wrapping uses `wrapping_*` /
  `Wrapping`, so this only fires on genuine bugs. (Verified: the image boots to login
  with 0 overflow panics.)
- **No debug flood / smaller info leak** — the kernel's aarch64/riscv64 `debug!`
  macro is gated behind `KERNEL_DEBUG` (default off), so hot-path internals aren't
  streamed to the console in production.

## 🔒 Build-time hardening (enforced in the E-OS image)

| Measure | Where | State |
|---|---|---|
| `overflow-checks = true` | `eos-kernel` release profile | ✅ on (boot-verified) |
| `panic = "abort"` (no unwinding) | `eos-kernel` release profile | ✅ on (upstream default) |
| `KERNEL_DEBUG` off (no debug flood) | `eos-kernel` | ✅ default off |
| **W⊕X** memory | kernel paging | ▫ Mostly — a few necessary x86 W+X pages remain (the SMP AP trampoline and the runtime `alternative` code-patcher); aarch64 has none. Auditing/eliminating these is tracked. |
| Hardened `RUSTFLAGS` (RELRO/PIE/stack-protector for C ports) | build env | ⏳ planned — `.cargo/config.toml` `rustflags` are currently empty. |

## ⚠️ Known limits (don't assume these)

- No **UEFI Secure Boot** / TPM measured-boot chain yet.
- No formal verification or completed security audit (pre-1.0).
- Userspace binaries (base/relibc/ports) don't yet build with `overflow-checks` —
  only the kernel does; extending it is a tracked follow-up.

Found a hardening gap or a vuln? Report **privately** — see [SECURITY.md](../SECURITY.md).
