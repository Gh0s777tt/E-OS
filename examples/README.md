---
title: Runnable examples
status: current
last-reviewed: 2026-08-30
owner: Gh0s777tt
---

# Examples

Every example here is a script that runs on the build host and was executed before being committed.
Each prints what it verified. They are deliberately small: they demonstrate the parts of E-OS that
are hard to understand from prose — the signature chain and the pin/verification gates.

| Example | What it demonstrates | Needs |
|---|---|---|
| [`verify-repo-signature.sh`](verify-repo-signature.sh) | the hybrid ed25519 + ML-DSA-65 index signature, and that it refuses a tampered index | `tools/eos-repo-sign` built |
| [`inspect-image.sh`](inspect-image.sh) | what a built image actually contains — packages, binaries, pinned keys, package sources | a built image, `podman` |
| [`check-pins.sh`](check-pins.sh) | that every pinned fork revision matches its published branch head | network, `glab` |

Run them from the repository root.
