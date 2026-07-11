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
   its authority (E-OS's capability-style sandbox). Tighten `/etc/login_schemes.toml`
   for the interactive `user`. Concretely, the default `user` list grants three **raw
   hardware / kernel-driver capabilities** that an interactive desktop user never needs
   — device drivers run in a system context, not as `user` — so they are safe to drop:
   ```diff
     [user_schemes.user]
     schemes = [
   -   "memory",   # mapping raw physical / device memory  — drivers only
   -   "irq",      # registering hardware interrupt lines   — drivers only
   -   "serio",    # raw PS/2-style device input            — owned by inputd; the
   +               #   user receives input via the `orbital` scheme, and on USB-input
   +               #   machines (e.g. QEMU virt) `serio` is unused entirely
       ...
     ]
   ```
   Keep everything else (network, `orbital`/`display*`, `sudo`, `proc`/`pty`, `audio`,
   `file`, IPC, and `debug` for the serial getty). **Note:** this is left as an opt-in
   rather than the shipped default because the post-login graphical session can't be
   driven end-to-end under the current headless test harness (QEMU-on-macOS delivers no
   serial input and GUI login automation is unreliable), so E-OS can't yet *boot-verify*
   the change the way it does the kernel hardenings — apply it and confirm login on your
   own display before relying on it. The removed schemes were confirmed driver-context by
   inspection (input on the test image is handled by `usbhidd`, not `user`-held `serio`),
   and the tightened image boots to the greeter with zero scheme-permission errors.

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
| User-space **mmap ASLR** (randomized base for non-fixed maps) | `eos-kernel` (`find_free_near`, gated by `KERNEL_ASLR`) | ✅ on (boot-verified **aarch64 + x86_64**; upstream has none) |
| User-space **W⊕X** (no *simultaneously* writable+executable pages) | `eos-kernel` (`wx_sanitize` at `SYS_FMAP`/`SYS_MPROTECT`/`SYS_MREMAP`, gated by `KERNEL_WX_USER`) | ✅ on (boot-verified **aarch64 + x86_64**; upstream allows RWX) |
| **Kernel-space W⊕X** memory | kernel paging | ✅ No *persistent* W+X pages (audited). The only x86 W+X mappings are two **transient early-boot windows** that are torn down: the SMP AP trampoline (mapped W+X, written, then **unmapped** once the APs are up — `acpi/madt/arch/x86.rs`) and the `alternative` self-modifying-code patcher (W+X to patch, then **remapped R-X** — `arch/x86_64/alternative.rs`). aarch64 has neither. |
| Hardened `RUSTFLAGS` (RELRO/BIND_NOW) | build env | ▫ Low marginal value here — E-OS's userland is memory-safe Rust, mostly statically linked, and the loader loads code into anonymous memory (no classic PLT/GOT lazy-binding for `-z now` to protect); enabling it would force a full-world rebuild for negligible gain. The C **ports** (which would benefit) build with their own toolchain flags, not `.cargo/config.toml`. Left as a deliberate no-op rather than a pending gap. |

## ⚠️ Known limits (don't assume these)

- No **UEFI Secure Boot** / TPM measured-boot chain yet.
- No formal verification or completed security audit (pre-1.0).
- The **third-party ports** (the ~1900 cookbook recipes for `vim`, `curl`, `gcc`, the
  COSMIC desktop, …) build with their own upstream flags — E-OS's `overflow-checks`
  covers the code it owns (kernel + base + relibc), not those.
- **W⊕X is simultaneous-only, not temporal.** E-OS blocks a page from being *at once*
  writable and executable, but not the `mmap(RW)` → write → `mprotect(R-X)` *sequence*
  (dropping write as it gains execute). This is a deliberate limit: Redox's dynamic
  loader (`ld.so`) reads each shared object into **anonymous** memory and then
  `mprotect`s it executable — it does not map code file-backed — so denying "anonymous
  memory may gain `PROT_EXEC`" breaks every dynamically-loaded program (empirically:
  `ld.so mprotect failed: EACCES` on `rm`, `sudo`, `orbital`, …). Full temporal W⊕X
  would require the loader to map code file-backed, or a capability gating executable
  memory — tracked as future work.

Found a hardening gap or a vuln? Report **privately** — see [SECURITY.md](../SECURITY.md).
