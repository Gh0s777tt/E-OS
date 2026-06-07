# 🐞 Known Issues

_No issue currently blocks a full **aarch64** or **x86_64** desktop boot._
Resolved items are kept below for the record.

---

## ✅ `R-401b / R-401c / R-401d` — aarch64 boot-to-login (RESOLVED 2026-06-08)

E-OS **aarch64** now boots under QEMU `virt` all the way to the graphical E-OS
COSMIC desktop (login greeter, wallpaper, taskbar, working USB keyboard).

![E-OS aarch64 desktop](../assets/screenshots/eos-aarch64-desktop.png)

The original report — a `redoxfs` root-mount Data Abort — turned out to be the
**last** symptom of a chain of **four** aarch64 bugs. The earlier diagnosis (an
upstream `redoxfs`/`relibc`/`PAGE_SIZE` memory bug) was **wrong**: `redoxfs` was the
last domino, not the cause. The tell is the serial cascade order — **`randd` crashes
first**, then a flood of `failed to generate random data: ENODEV`, then `nvmed`, then
`redoxfs`.

| # | Bug | Fix |
|---|---|---|
| `R-401b` | `randd` runs `mrs xN, RNDRRS` (FEAT_RNG, ARMv8.5) unconditionally → **UNDEF** on non-FEAT_RNG aarch64 (Cortex-A72/A53, Raspberry Pi, `-cpu cortex-a72`) → kills the `rand:` scheme → every daemon that seeds a HashMap panics `ENODEV` → cascade kills `nvmed` & `redoxfs` (the "Data Abort" in the original report). | **kernel:** trap-and-emulate `RNDR`/`RNDRRS` in the aarch64 synchronous-exception handler. |
| `R-401c` | aarch64 has **no MSI**; `nvmed` falls back to INTx but hard-codes `intx:false`, and the INTx IRQ is only *routed* when Redox boots from a **device tree**, not ACPI. | **base:** `nvmed` runs in INTx mode on non-x86. **Boot:** `-machine virt,acpi=off` forces device-tree boot, so the PCIe interrupt-map exists. |
| `R-401d` | the kernel reserved shared PCIe **INTx** GIC SPIs *exclusively* → `nvmed` failed with `open IRQ: EEXIST`. | **kernel:** allow shared phandle-IRQ opens (`irq_trigger` already fans out to every handle). |

The kernel & base fixes live in the **`Gh0s777tt/eos-kernel`** and
**`Gh0s777tt/eos-base`** forks (the `core/kernel` / `core/base` recipes are pinned
to them, so a fresh clone reproduces). Clean upstream patches + a submission guide
are in [`upstream/`](../upstream/README.md).

### Running the aarch64 image

```sh
qemu-system-aarch64 -machine virt,acpi=off -cpu cortex-a72 -m 2048 -smp 4 \
  -drive if=pflash,unit=0,file=/usr/share/AAVMF/AAVMF_CODE.fd,readonly=on,format=raw \
  -drive if=pflash,unit=1,file=AAVMF_VARS.fd,format=raw \
  -device ramfb -device qemu-xhci -device usb-kbd -device virtio-rng-pci -display none \
  -drive file=build/aarch64/eos/harddrive.img,if=none,id=disk0,format=raw \
  -device nvme,drive=disk0,serial=eos
```

> ⚠️ **`-machine virt,acpi=off` is required** — it selects device-tree boot, which is
> what carries the PCIe interrupt routing on aarch64. There is no KVM for aarch64 on
> an x86 host, so QEMU runs under TCG and the boot is slow (minutes).

### Remaining minor items (non-blocking)

- `/usr/bin/background` (wallpaper renderer) **intermittently** takes a post-login
  Data Abort on aarch64 — a null-pointer deref (FAR=`0x8`) **inside relibc**
  (`libc.so`), *not* in background's own code (background is a 1.7 MB PIE; the crash
  PCs land in the 4 MB libc.so loaded high). Cosmetic: the desktop and wallpaper
  render fine, and it does not reliably reproduce (a clean diagnostic boot did not
  hit it). A precise fix is a deeper relibc investigation — a good upstream candidate.
- `netstack` / `audiod` exit on QEMU `virt` (no virtual net/audio device) — harmless.
- The emulated `RNDR` entropy (R-401b) is a **boot stopgap**, *not* a strong CSPRNG
  seed. A real entropy source (interrupt-timing jitter / a hardware RNG) is the
  proper long-term fix.
