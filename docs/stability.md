# 🧱 E-OS Stability & Compatibility Policy

> What you can rely on across E-OS versions — and what you can't yet. Companion to
> the [Roadmap](../ROADMAP.md) and [Security Policy](../SECURITY.md).

E-OS is **pre-1.0 (alpha)**. This page states the policy that *will* govern
stability, and is explicit about what is **not** guaranteed today so you can plan.

---

## Versioning

E-OS follows [SemVer](https://semver.org): `MAJOR.MINOR.PATCH`.

| Phase | Meaning for you |
|---|---|
| **`0.x` (now)** | **No stability guarantees.** Any release may change the ABI, on-disk format, package set, defaults or APIs. Pin an exact version. |
| **`1.0`+** | The compatibility promise below takes effect. |

## The 1.0 compatibility promise (target)

From `1.0.0`, within a major series:

- **No breaking changes** to the documented syscall / scheme surface in a MINOR or PATCH release.
- **On-disk RedoxFS format** stays readable; migrations, if any, are forward and documented.
- **Package ABI** (`relibc`, core libraries) is stable within the major; rebuilds aren't forced by a PATCH.
- **Deprecations** ship at least one MINOR release before removal, listed in [CHANGELOG.md](../CHANGELOG.md).
- Breaking changes happen **only** on a MAJOR bump.

## Support lines

| Line | Branch | Support |
|---|---|---|
| **Rolling** | `main` | latest features + security fixes |
| **LTS** | `lts/0.1` | security **backports** for the 0.1 “Genesis” line — pin here for stability |
| Checkpoint | `eos-base` | the verified base snapshot |

Pick **`lts/0.1`** for a deployment you don't want to chase; track `main` for the latest.

## What is *not* stable yet (be explicit)

- The **syscall/scheme ABI** — inherited from upstream Redox, still evolving.
- **On-disk format**, **default credentials/services**, **the package set**.
- **aarch64** — experimental (boots the bootloader, not yet to login — `R-401b`).

When `relibc` / the kernel ABI stabilises upstream and E-OS reaches `1.0`, this
page becomes a binding promise rather than a plan. Until then: **pin versions, use
the LTS line, and read the [CHANGELOG](../CHANGELOG.md) before upgrading.**
