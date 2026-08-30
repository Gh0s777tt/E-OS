---
title: eos-pkg-aarch64
status: archived
last-reviewed: 2026-08-30
owner: Gh0s777tt
---

# eos-pkg-aarch64

**E-OS binary package repository — `aarch64`.** Part of the [**E-OS**](https://github.com/Gh0s777tt/E-OS)
ecosystem (a hardened, Crimson-branded downstream of [Redox OS](https://www.redox-os.org)).

This repo hosts the built `.pkgar` packages and the signed `repo.toml` index for
the `aarch64-unknown-redox` target. It is an **artifact repository**, not source — no code review
applies; only structure, signatures and retention.

## How it's published
`scripts/publish-repo-pages.sh` in the [main repo](https://github.com/Gh0s777tt/E-OS) pushes the packages here
as a single orphan commit (history discarded each publish, so the repo never grows)
and GitHub Pages serves them at the stable URL:

    https://gh0s777tt.github.io/eos-pkg-aarch64/pkg/aarch64-unknown-redox/

The `repo.toml` manifest is signed with the hybrid **ed25519 + ML-DSA-65**
(`tools/eos-repo-sign`, R-703); each `.pkgar` is separately ed25519-signed
(pkgar). Clients verify the manifest against an **in-image-pinned** key.

## Status
Currently an **empty placeholder** — populated on the next signed publish.

## Hosting
**GitLab (source of truth):** https://gitlab.com/e-os/eos-pkg-aarch64  
**GitHub (mirror + Pages host):** https://github.com/Gh0s777tt/eos-pkg-aarch64

## License
Packages inherit their recipe licenses (mostly MIT); the E-OS project as a whole is
AGPL-3.0. See the [main repo](https://github.com/Gh0s777tt/E-OS/blob/main/LICENSE).

---
[E-OS main repo](https://github.com/Gh0s777tt/E-OS) · [Package docs](https://github.com/Gh0s777tt/E-OS/blob/main/docs/reference/packages.md)
