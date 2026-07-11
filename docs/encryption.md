# 🔒 E-OS Full-Disk Encryption (RedoxFS)

> How to run E-OS with an encrypted root. Companion to the
> [Threat Model](threat-model.md), [Hardening Guide](hardening.md) and
> [Security Policy](../SECURITY.md).

E-OS inherits **RedoxFS** full-disk encryption: **AES-XTS-128** for the data,
with the key derived from your password (**argon2**). It protects **data at rest** —
the *physical / lost-device* adversary in the [threat model](threat-model.md).

The whole chain is in place:

| Stage | Mechanism |
|---|---|
| **Create** an encrypted root | `redoxfs-mkfs --encrypt` (AES-XTS-128) |
| **Install** with encryption | installer prompts *"redoxfs password (empty for none)"*, or config `[general] encrypt_disk = "…"` |
| **Boot** an encrypted root | the **E-OS bootloader** prompts `RedoxFS password (attempt/attempts):` and unlocks |

> ✅ **Verified end-to-end (2026-07-11, aarch64/UEFI):** an image installed with
> `[general] encrypt_disk` boots the encrypted root all the way to `eos login:` —
> the bootloader prompts `RedoxFS password (1/10):`, accepts the password, unlocks
> the **AES-XTS** RedoxFS, loads the kernel from it, and reaches login with **0
> exceptions / 0 panics**. `redoxfs-mkfs --encrypt` likewise produces a distinct
> encrypted on-disk header.
>
> ⚠️ **This required an E-OS bootloader fix.** The UEFI boot path previously
> **panicked** (`Failed to open RedoxFS`) on an encrypted root instead of prompting:
> its partition scan swallowed the `ENOKEY` that an encrypted RedoxFS returns
> (logging it as a generic *"BlockIo error: Required key not available"* and skipping
> the device), so the caller — which only prompts for a password on `ENOKEY` — saw
> `ENOENT` and gave up. Fixed by propagating `ENOKEY`/`EKEYREJECTED` from the scan
> ([`eos-bootloader@083d9fae`](https://github.com/Gh0s777tt/eos-bootloader)); the
> BIOS path was already correct. This affected **both** aarch64 and x86_64 under
> UEFI, so it is also an upstream-Redox bug (candidate for `upstream/`).

---

## Design note: encrypt at **install time**, not in the shipped image

The prebuilt, distributable `harddrive.img` is **unencrypted by design** — a public
image with a *baked-in* password protects nothing (everyone has the password).
Encryption is meant to be applied with **your own** password, at install time, so
**only you** can unlock the disk.

## 1. Recommended — encrypt while installing

When you install E-OS to a real disk with the **installer**, answer the
`redoxfs password` prompt with a strong password. The root is created as an
encrypted RedoxFS; nothing else changes.

For an unattended/config-driven install, set it in the install config:

```toml
[general]
encrypt_disk = "your-strong-password"
```

## 2. Build a (locally) encrypted image — for testing

Pass the mkfs flag through the build (you'll be prompted for the password at the
filesystem-creation step; needs a TTY):

```sh
make CI=1 CONFIG_NAME=eos REDOXFS_MKFS_FLAGS=--encrypt all
```

`config/<arch>/eos.toml` (and `mk/config.mk`) already expose
`REDOXFS_MKFS_FLAGS` for exactly this.

## 3. Encrypt a RedoxFS image by hand

```sh
# build/fstools/bin/redoxfs-mkfs is produced by `make fstools`
redoxfs-mkfs --encrypt /path/to/disk.img
# -> "redoxfs-mkfs: password:"  (enter a strong password at the TTY)
```

## Booting an encrypted E-OS

The E-OS bootloader (red/black, built from source) detects the encrypted RedoxFS
and prompts:

```
RedoxFS password (1/3):
```

Enter the password to derive the key and unlock the root. Wrong entries are
re-prompted up to the attempt limit. The password is entered on **every** boot —
there is no key-escrow or auto-unlock (by design).

## Caveats

- **Pre-1.0:** the crypto is AES-XTS-128 implemented in Rust, but E-OS has **not**
  had a third-party cryptographic audit. Don't rely on it for high-assurance use yet.
- No **TPM / Secure Boot** binding — the password alone protects the disk; an
  attacker who can tamper with the (unencrypted) bootloader could attack the prompt.
  See the [threat model](threat-model.md) non-goals.
- Choose a **strong** password — it is the only secret protecting the disk.
