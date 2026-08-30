---
title: Third-party licenses
status: current
last-reviewed: 2026-08-30
owner: Gh0s777tt
---

# Third-party licenses

E-OS as a whole is distributed under **AGPL-3.0-or-later** ([`LICENSE`](../../LICENSE)). It
incorporates third-party code under other licenses. This document records what those licenses are
and why the combination is coherent.

## Method

Generated from `cargo metadata --format-version 1` over the two Rust workspaces this repository
owns, and from the recipe sources for the shipped operating-system packages. Regenerate with:

```bash
cargo metadata --format-version 1 | python3 -c "import json,sys;from collections import Counter;print(Counter(p.get('license') or '(none)' for p in json.load(sys.stdin)['packages']))"
```

**Last regenerated:** 2026-08-30.

## Host tooling — `redox_cookbook` workspace

163 packages in the dependency graph. Every SPDX identifier that appears anywhere in it:

`0BSD` · `Apache-2.0` · `BSD-1-Clause` · `BSD-2-Clause` · `BSD-3-Clause` · `BSL-1.0` ·
`CC0-1.0` · `LGPL-2.1-or-later` · `LLVM-exception` · `MIT` · `MIT-0` · `MPL-2.0` ·
`Unicode-3.0` · `Unlicense` · `Zlib`

Distribution by declared expression:

| License expression | Packages |
|---|---|
| `MIT OR Apache-2.0` | 85 |
| `MIT` | 35 |
| `Apache-2.0 OR MIT` | 8 |
| `MIT/Apache-2.0` | 6 |
| `Unlicense OR MIT` | 5 |
| `Apache-2.0 WITH LLVM-exception OR Apache-2.0 OR MIT` | 3 |
| `Zlib OR Apache-2.0 OR MIT` | 2 |
| `BSD-3-Clause` | 2 |
| `Unlicense/MIT` | 2 |
| remainder (one each) | `0BSD OR MIT OR Apache-2.0`, `BSD-2-Clause`, `CC0-1.0 OR Apache-2.0 OR Apache-2.0 WITH LLVM-exception`, `CC0-1.0 OR MIT-0 OR Apache-2.0`, `MIT OR Apache-2.0 OR BSD-1-Clause`, `MIT OR Apache-2.0 OR LGPL-2.1-or-later`, `(MIT OR Apache-2.0) AND Unicode-3.0`, and others |

One package declares no `license` field: **`redox_cookbook`** itself, the vendored upstream build
engine in [`src/`](../../src). It is covered by this repository's licensing and by
[`NOTICE`](../../NOTICE).

## E-OS-authored tooling — `tools/eos-repo-sign`

57 packages. Same permissive picture: `MIT OR Apache-2.0` (27), `Apache-2.0 OR MIT` (19),
`BSD-3-Clause` (3), `MIT/Apache-2.0` (2), `MIT` (2), plus single occurrences of
`MIT OR Apache-2.0 OR BSD-1-Clause`, `MIT OR Apache-2.0 OR LGPL-2.1-or-later`,
`(MIT OR Apache-2.0) AND Unicode-3.0` and `Apache-2.0 WITH LLVM-exception OR Apache-2.0 OR MIT`.

## Compatibility assessment

**Result: no conflict found.**

Every identifier above is either permissive (`MIT`, `Apache-2.0`, the BSD family, `Zlib`, `BSL-1.0`,
`0BSD`, `Unlicense`, `CC0-1.0`, `MIT-0`, `Unicode-3.0`) or a weak copyleft that permits combination
with a stronger copyleft (`MPL-2.0`, `LGPL-2.1-or-later`). Combining permissive and weak-copyleft
code into an AGPL-3.0-or-later distribution is the direction the licenses allow.

A scan for identifiers that would conflict — `GPL-2.0-only`, `CDDL`, `EPL`, `MPL-1.x`, `SSPL`,
`BUSL`, Commons Clause, or proprietary terms — returned **no matches**.

Two obligations follow from this and are met:

1. **Apache-2.0** requires preserving `NOTICE` content. [`NOTICE`](../../NOTICE) exists at the
   repository root.
2. **MIT** and the BSD family require preserving copyright and permission notices. Upstream Redox's
   MIT text is retained verbatim at [`licenses/Redox-OS-MIT.txt`](../../licenses/Redox-OS-MIT.txt).

## Operating-system packages

The image ships 65 packages. Their upstreams carry their own licenses — GNU components under
GPL-3.0-or-later (`bash`, `gettext`, `diffutils`, `findutils`, `sed`, `grep`, `wget`, `nano`),
OpenSSL 3.x under Apache-2.0, OpenSSH under its BSD-style license, NetSurf under GPL-2.0-or-later,
`vim` under the Vim license, `git` under GPL-2.0-only.

**`git` is GPL-2.0-only, which is incompatible with GPL-3/AGPL-3 for *linking*.** It ships as a
**separate executable**, not linked into any AGPL-covered binary, so the incompatibility does not
arise: aggregation on the same medium is explicitly permitted. This is recorded here because it is
the one place where the question is worth asking rather than assumed.

## Enforcement

`cargo-deny` policy lives in [`deny.toml`](../../deny.toml) and runs in CI. It is the mechanism
that keeps this document from silently going stale — but note that CI has not executed since
2026-08-28 (see [`docs/audit/03-security-audit-2026-08-30.md`](../audit/03-security-audit-2026-08-30.md) §2),
so this regeneration was performed by hand.
