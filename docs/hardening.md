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
- **`overflow-checks` across all E-OS Rust code** — E-OS builds `eos-kernel`,
  `eos-base` (every driver + daemon) and `eos-relibc` (the C library under every
  program) with `overflow-checks = true` (upstream Redox does not), so an *unintended*
  integer overflow — a classic exploit primitive even in safe Rust — is a controlled
  abort (`panic = "abort"`), not a silent wrap. Intentional wrapping uses `wrapping_*` /
  `Wrapping`, so this only fires on genuine bugs. (Verified: all three build and the
  image boots to login with 0 overflow panics / 0 exceptions.)
- **No debug flood / smaller info leak** — the kernel's aarch64/riscv64 `debug!`
  macro is gated behind `KERNEL_DEBUG` (default off), so hot-path internals aren't
  streamed to the console in production.
- **User-space mmap ASLR** — upstream Redox has *no* ASLR (KASLR is unimplemented and
  there is no user-space load/heap randomization), so "map anywhere" allocations land
  at deterministic addresses — a gift to exploit chains. E-OS randomizes them: the
  kernel's `find_free_near` now places each non-fixed mapping at a page-aligned random
  offset *inside* the chosen free hole instead of always at its start, so the heap,
  `mmap`'d libraries and stacks are unpredictable per boot. Offsets come from a
  splitmix64 PRNG seeded from a cycle counter (`CNTVCT_EL0` on aarch64, `RDTSC` on
  x86_64) and re-mixed with fresh jitter per call, bounded to `ASLR_MAX_SLACK_PAGES`
  and gated by `KERNEL_ASLR`. `MAP_FIXED` is unaffected. (Verified: aarch64 image
  boots to login with 0 exceptions / 0 panics — the entire user-space bring-up runs
  through the randomized allocator without a single fault; and a diagnostic kernel
  confirmed the map-anywhere bases actually *move* between two cold boots while
  fixed/hinted regions stay put.)
- **User-space W⊕X enforcement** — upstream Redox lets a process `mmap`/`mprotect`/
  `mremap` a page as `PROT_WRITE | PROT_EXEC`, i.e. writable *and* executable, which is
  the textbook shellcode-injection primitive (write attacker bytes, jump to them). E-OS
  strips `PROT_EXEC` from any **user-space** request that also asks for `PROT_WRITE`, at
  the syscall boundary (`SYS_FMAP` / `SYS_MPROTECT` / `SYS_MREMAP`, via `wx_sanitize`),
  so a running program can never hold a W+X page — code must be mapped read-only-
  executable. The one trusted exception, the kernel's one-shot `bootstrap` blob (mapped
  RWX through the *internal* `AddrSpace::mmap` path, not a syscall), is deliberately left
  untouched. Gated by `KERNEL_WX_USER`. (Verified: aarch64 boots to login with 0
  exceptions / 0 panics — the whole base userland runs without needing a W+X page.)

## 🔒 Build-time hardening (enforced in the E-OS image)

| Measure | Where | State |
|---|---|---|
| `overflow-checks = true` | `eos-kernel` release profile | ✅ on (boot-verified) |
| `overflow-checks = true` | `eos-base` release profile (all drivers + daemons) | ✅ on (boot-verified) |
| `overflow-checks = true` | `eos-relibc` release profile (the C library under every program) | ✅ on (boot-verified) |
| `panic = "abort"` (no unwinding) | `eos-kernel` + `eos-relibc` release profiles | ✅ on |
| `KERNEL_DEBUG` off (no debug flood) | `eos-kernel` | ✅ default off |
| User-space **mmap ASLR** (randomized base for non-fixed maps) | `eos-kernel` (`find_free_near`, gated by `KERNEL_ASLR`) | ✅ on (boot-verified; upstream has none) |
| User-space **W⊕X** (no writable+executable pages for user processes) | `eos-kernel` (`wx_sanitize` at `SYS_FMAP`/`SYS_MPROTECT`/`SYS_MREMAP`, gated by `KERNEL_WX_USER`) | ✅ on (boot-verified; upstream allows RWX) |
| **Kernel-space W⊕X** memory | kernel paging | ▫ Mostly — a few necessary x86 W+X pages remain (the SMP AP trampoline and the runtime `alternative` code-patcher); aarch64 has none. Auditing/eliminating these is tracked. |
| Hardened `RUSTFLAGS` (RELRO/PIE/stack-protector for C ports) | build env | ⏳ planned — `.cargo/config.toml` `rustflags` are currently empty. |

## ⚠️ Known limits (don't assume these)

- No **UEFI Secure Boot** / TPM measured-boot chain yet.
- No formal verification or completed security audit (pre-1.0).
- The **third-party ports** (the ~1900 cookbook recipes for `vim`, `curl`, `gcc`, the
  COSMIC desktop, …) build with their own upstream flags — E-OS's `overflow-checks`
  covers the code it owns (kernel + base + relibc), not those.

Found a hardening gap or a vuln? Report **privately** — see [SECURITY.md](../SECURITY.md).
