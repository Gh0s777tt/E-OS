# NetSurf on E-OS: the PIE / host-toolchain story (R-D06)

**What this is:** why E-OS builds NetSurf *from source as a PIE* instead of using
the upstream prebuilt, how the build was unblocked, and the one wall that still
stands. **Status: partial** — the browser now *loads, runs and opens a window*;
it still crashes during the first content render. Read this before touching
`recipes/web/netsurf/recipe.toml` or `scripts/redoxer-host-stub.sh`.

## The symptom

Clicking **Netsurf** on the desktop did nothing useful: the process faulted the
instant it was loaded. Serial showed a data abort at load — a translation fault
from the ELF loader, `ESR_EL1 = 0x92000047`.

## Root cause — three layers, peeled one at a time

1. **The shipped binary was a non-PIE `ET_EXEC`.** aarch64-unknown-redox only
   loads *position-independent* executables; relibc's `ld.so` maps a PIE at a
   randomised base. A fixed-address `ET_EXEC` cannot be placed and faults at
   load. `file netsurf-fb` → `ELF … executable, … ` (not `pie executable`).

2. **We were shipping the upstream prebuilt, not our own build.** The cookbook
   config sets `COOKBOOK_OPTS += --repo-binary` (mk/config.mk), which makes
   `cook` **download** `static.redox-os.org/pkg/aarch64-unknown-redox/netsurf.pkgar`
   — the upstream non-PIE `ET_EXEC` — rather than compile from source. So no
   recipe flag change could ever affect the binary in the image: it wasn't being
   built at all.

3. **Forcing a from-source build hit a host-toolchain 404.** NetSurf needs
   `host:gperf` (a build-time perfect-hash generator). The cookbook builds host
   recipes through `cookbook_redoxer env`, which calls redoxer's `toolchain()`
   **even for the host target**. `toolchain()` unconditionally tries to download
   a relibc toolchain for the *host* triple from
   `static.redox-os.org/toolchain/<host>/<host>/…` — a URL redox never publishes
   (it only ships *cross* toolchains, host→redox). The fetch 404s and the build
   dies: `redoxer env: unable to init toolchain: exit status: 22`.

## The fixes

### Layer 3 — `scripts/redoxer-host-stub.sh`

For a host build redoxer needs no relibc toolchain: `generate_gnu_targets()`
resolves `CC=gcc` / `CXX=g++` from the system compilers when
`host_target() == target()`. The download is a pure misfire, and redoxer skips
it entirely when `~/.redoxer/<target>/toolchain` already exists. The script
pre-creates that directory as a stub. It is **per-target**, so it never touches
the genuine cross toolchain at `~/.redoxer/aarch64-unknown-redox/toolchain`.
Proof: after the stub, `cookbook_redoxer env` prints `CC=gcc CXX=g++` and
`host:gperf` builds; the full from-source `cook netsurf` reaches
`cook netsurf - successful`.

*Rejected alternative:* patching redoxer to not fetch for host targets — correct
upstream, but redoxer is a pinned dev-tool dependency of the cookbook; a
per-target stub is a one-line-of-intent, in-repo fix we fully control.

### Layers 1 & 2 — PIE CC-wrapper in the recipe

With the source build working, the recipe forces a PIE. NetSurf-all is a tree of
nested sub-makes that compile many static libs later linked into `netsurf-fb`,
so injecting `-fPIC` via `CFLAGS` is not guaranteed to reach every object.
Instead the recipe wraps `CC` (`.pie/cc`): **every** compile gets `-fPIC`, and
the **final link** (an invocation with neither `-c` nor `-shared`) gets `-pie`.
Result, verified on the staged binary and inside the image:

```
$ readelf -h netsurf-fb | grep Type
  Type:  DYN (Position-Independent Executable file)
$ file netsurf-fb
  ELF 64-bit LSB pie executable, ARM aarch64, … interpreter /lib/ld.so.1
```

Because our recipe now differs from upstream, `--repo-binary` no longer matches a
remote prebuilt and `cook` always builds from source → the image always gets the
PIE. (Confirmed: cooking with `--repo-binary` leaves the locally-built pkgar
byte-identical; it is not re-downloaded.)

## Current status — what works, what doesn't

**Works (proven by boot + screendump):** the PIE `netsurf-fb` now *loads and
runs* — no more load-time fault. It initialises SDL over the orbital video
driver (`Setting mode 800x600@32`) and **opens an 800×600 window on the
desktop** with orbital decorations.

**Open (R-D06 remains):** the window body stays black and the process then
crashes during its first content render — a userspace data abort at a
*deterministic code location* (crash `ELR` page-offset `0x718`, fault `FAR`
offset `0xf83`; the absolute addresses vary run-to-run because a PIE is loaded at
a randomised base). A non-page-aligned `funmap` warning
(`length 0x1d4c00 instead of 0x1d5000`) is logged just before the fault and is
the leading suspect. This is a separate, deeper NetSurf-on-Redox rendering bug
(framebuffer/`libnsfb` surface handling, the SDL-orbital surface, or freetype),
independent of the toolchain and PIE work above.

### Next step for the render crash

Symbolicate the fault: NetSurf is built with `-g`, so `ELR − load_base` →
`addr2line` gives the exact source line. The blocker is obtaining the PIE load
base at crash time on Redox (no `/proc/<pid>/maps`); options are an `ld.so`
debug env, a fixed-base (ASLR-off) load for one diagnostic run, or bisecting the
render path. Once the line is known the fix likely lands in the NetSurf
framebuffer frontend or the SDL-orbital surface, not in this recipe.
