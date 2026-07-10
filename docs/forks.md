# 🍴 E-OS forks & vendored components

E-OS vendors the **Redox-authored OS components** it ships into the
[`Gh0s777tt`](https://github.com/Gh0s777tt) organisation, so the whole
boot→desktop operating system is under E-OS control — editable freely and
independent of `gitlab.redox-os.org` availability. Third-party software *ports*
(the ~1900 cookbook recipes for `vim`, `curl`, `gcc`, the COSMIC desktop from
pop-os, etc.) are **not** vendored — they are upstream projects, not Redox, and
each recipe still fetches from its own upstream.

Every recipe below pins an exact `rev`, so a fresh clone builds reproducibly
from our mirrors.

## Modified forks (carry E-OS commits)

These are rebased onto current Redox mainline (July) and carry E-OS fixes; they
are **not** plain mirrors. Updating them means rebasing our commits onto new
upstream (see [known-issues.md](known-issues.md), U-033), not a fast-forward.

| Fork | Upstream | E-OS work |
|---|---|---|
| [`eos-kernel`](https://github.com/Gh0s777tt/eos-kernel) | redox-os/kernel | aarch64 FEAT_RNG emul, INTx, sched_yield, virtual-timer, INTx-EOI deadlock fix |
| [`eos-base`](https://github.com/Gh0s777tt/eos-base) | redox-os/base | nvmed INTx, pcid `_PRT`, virtio-core INTx |
| [`eos-relibc`](https://github.com/Gh0s777tt/eos-relibc) | redox-os/relibc | static-TLS layout / TLSDESC / TPOFF fix |
| [`eos-userutils`](https://github.com/Gh0s777tt/eos-userutils) | redox-os/userutils | `eos login:` prompt |
| [`eos-bootloader`](https://github.com/Gh0s777tt/eos-bootloader) | redox-os/bootloader | red/black theme + banner |
| [`eos-orbdata`](https://github.com/Gh0s777tt/eos-orbdata) | redox-os/orbdata | greeter, wallpaper, launcher icon |

## Vendored mirrors (pure mirrors, unmodified — yet)

The rest of the E-OS boot→desktop OS. Currently plain mirrors of upstream at a
pinned rev; edit any of them the moment you need to, then bump its `rev` pin.

| Mirror | Upstream | Role |
|---|---|---|
| [`eos-redoxfs`](https://github.com/Gh0s777tt/eos-redoxfs) | redox-os/redoxfs | filesystem |
| [`eos-orbital`](https://github.com/Gh0s777tt/eos-orbital) | redox-os/orbital | display server |
| [`eos-orbutils`](https://github.com/Gh0s777tt/eos-orbutils) | redox-os/orbutils | greeter / launcher |
| [`eos-orbterm`](https://github.com/Gh0s777tt/eos-orbterm) | redox-os/orbterm | terminal |
| [`eos-orbclient`](https://github.com/Gh0s777tt/eos-orbclient) | redox-os/orbclient | orbital client lib |
| [`eos-liborbital`](https://github.com/Gh0s777tt/eos-liborbital) | redox-os/liborbital | orbital C lib |
| [`eos-ion`](https://github.com/Gh0s777tt/eos-ion) | redox-os/ion | default shell |
| [`eos-coreutils`](https://github.com/Gh0s777tt/eos-coreutils) | redox-os/coreutils | core commands |
| [`eos-extrautils`](https://github.com/Gh0s777tt/eos-extrautils) | redox-os/extrautils | extra commands |
| [`eos-netutils`](https://github.com/Gh0s777tt/eos-netutils) | redox-os/netutils | network commands |
| [`eos-netdb`](https://github.com/Gh0s777tt/eos-netdb) | redox-os/netdb | name resolution data |
| [`eos-pkgutils`](https://github.com/Gh0s777tt/eos-pkgutils) | redox-os/pkgutils | `pkg` client |
| [`eos-pkgar`](https://github.com/Gh0s777tt/eos-pkgar) | redox-os/pkgar | package archive format |
| [`eos-installer`](https://github.com/Gh0s777tt/eos-installer) | redox-os/installer | installer engine |
| [`eos-redoxer`](https://github.com/Gh0s777tt/eos-redoxer) | redox-os/redoxer | build/test helper |
| [`eos-redox-fatfs`](https://github.com/Gh0s777tt/eos-redox-fatfs) | redox-os/redox-fatfs | FAT filesystem |

## Keeping them current

`scripts/sync-forks.sh` reports, for each **mirror**, whether ours is
up-to-date / behind / diverged versus upstream; `--push` fast-forwards the
behind ones. After syncing, bump the `rev` pins in the recipes and rebuild. The
modified forks are excluded (they need a rebase, not a fast-forward).

## Why not vendor everything?

The cookbook has ~2000 recipes; only ~70 are Redox-authored, and E-OS ships
~22 of those in the boot→desktop image — that is what we vendor. Mirroring the
~1900 third-party ports (or the Redox dev/test/demo repos we never touch) would
be pure maintenance cost for no benefit: those already build from their own
upstreams and are not part of the OS we control.
