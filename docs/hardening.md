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

## ⚠️ Known limits (don't assume these)

- No **UEFI Secure Boot** / TPM measured-boot chain yet.
- No formal verification or completed security audit (pre-1.0).
- **aarch64** boots the bootloader but not yet to login (upstream `redoxfs`
  mount bug, `R-401b`) — treat aarch64 as experimental.

Found a hardening gap or a vuln? Report **privately** — see [SECURITY.md](../SECURITY.md).
