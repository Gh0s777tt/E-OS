# NetSurf on E-OS: the PIE / host-toolchain story (R-D06)

**What this is:** why E-OS builds NetSurf *from source as a PIE* instead of using
the upstream prebuilt, and the three bugs that stood between "clicking the
browser instantly crashes" and a working browser. **Status: working** — NetSurf
now launches and renders (proof: it paints `welcome.html` — toolbar, address bar,
the NetSurf logo image, headings, links and a search box; `assets/screenshots/
eos-netsurf-welcome.png`). Read this before touching
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

## Layer 4 — the render crash: use-after-munmap of the window buffer

With a PIE that loaded and ran, NetSurf opened an 800×600 window but its body
stayed black and it then crashed during the first content render — a userspace
data abort at a *deterministic code location* (crash `ELR` page-offset `0x718`,
fault `FAR` offset `0xf83`; absolute addresses varied run-to-run because a PIE
loads at a randomised base). The tell was the `funmap` warning logged just
before the fault: `length 0x1d4c00` = **1,920,000 = 800 × 600 × 4** — exactly the
32-bpp framebuffer surface. So the crash was a **use-after-munmap of the window
pixel buffer**, and the fault offset `0xf83` sits near the top-left of that
buffer — where NetSurf starts plotting the page.

The chain, read from source:

1. libnsfb's SDL surface (`libnsfb/src/surface/sdl.c`) opens the screen with
   `SDL_SetVideoMode(…, SDL_SWSURFACE | SDL_RESIZABLE)` and caches the pixel
   pointer: `nsfb->ptr = sdl_screen->pixels`.
2. The Redox SDL orbital driver backs that surface with an orbital window:
   `current->pixels = orb_window_data(window)` — a pointer into orbclient's mmap
   of the window (the 1,920,000-byte buffer). `SDL_RESIZABLE` →
   `ORB_WINDOW_RESIZABLE` → orbclient's `Window { resizable: true }`.
3. In orbclient's event pump (`Window::events()`), a **resizable** window reacts
   to the `EVENT_RESIZE` orbital sends on first map by calling `set_size()`,
   which `unmap()`s the old buffer (**the 1,920,000 `funmap`**) and `remap()`s a
   new one at a new address — but libnsfb still holds the *old* `nsfb->ptr`.
4. NetSurf's first plot writes into the freed buffer → data abort.

### The fix (`recipes/web/netsurf/recipe.toml`)

Drop `SDL_RESIZABLE` from libnsfb's two `SDL_SetVideoMode` call sites (a `sed`
after the source rsync). That leaves orbclient's `resizable` false, so
`events()` never remaps the buffer out from under `nsfb->ptr`, and the page
renders. Verified by boot + screendump: NetSurf paints `welcome.html` in full
(`assets/screenshots/eos-netsurf-welcome.png`), and the serial no longer records
an `UNHANDLED EXCEPTION` for `netsurf-fb`.

**Trade-off / follow-up:** the NetSurf window is fixed-size for now. Proper
resize support needs libnsfb to re-fetch `nsfb->ptr` (and post an
`SDL_VIDEORESIZE`) *after* orbclient remaps — the correct home for that is the
SDL orbital driver / libnsfb, not this recipe. Until then, resizable is off.

## Launch & homepage

Verified the real desktop path (not just a shell launch): clicking the **Netsurf
icon on the launcher bar** opens the browser, no crash. The Redox netsurf config
overrode netsurf's own `about:welcome` default with `https://www.redox-os.org/`,
but Redox networking (netstack/DNS/TLS + the curl/openssl fetch path) is not
functional on the aarch64/QEMU loop yet — a click-launch of that homepage showed
a blank page. A `sed` in the recipe restores the local `about:welcome` default
(netsurf's `Makefile.config` override), so clicking Netsurf renders the welcome
page immediately. Flip the homepage back to a web URL once networking works
(`R-D10`).
