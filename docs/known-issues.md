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

- **aarch64 kernel: the first syscall after `exec` returns a stale `x0`** (follow-up).
  This is the *root* cause behind the relibc `verify()` abort resolved below — a freshly
  `fork`+`exec`'d process's very first syscall returns its input register instead of the
  kernel's result. relibc now tolerates it on aarch64, but the proper fix is in the kernel
  (the aarch64 `exec`/`sigreturn`-to-entry transition or the syscall-return register
  handling). Worth fixing because it could mask other first-call return bugs.
- `netstack` / `audiod` exit on QEMU `virt` (no virtual net/audio device) — harmless.
- The emulated `RNDR` entropy (R-401b) is a **boot stopgap**, *not* a strong CSPRNG
  seed. A real entropy source (interrupt-timing jitter / a hardware RNG) is the
  proper long-term fix.

---

## ✅ `relibc verify()` — every aarch64 shell/desktop program aborted (RESOLVED 2026-06-08)

An earlier note here called this a "cosmetic, intermittent `/usr/bin/background`
null-deref inside relibc". That was wrong on every count:

- It is a **`brk #1`** — an explicit **abort/trap**, *not* a memory fault. The serial dump
  has `ESR_EL1` `EC=0x3C` ("BRK instruction execution"); the printed `FAR_EL1` is stale
  and irrelevant.
- It is **deterministic**, not intermittent: **every** `fork`+`exec`-spawned program
  aborted — `whoami`, `id`, `ls`, `env`, `background` (16/16). The aarch64 shell could not
  run a single external command. Only long-lived, init/`pcid`-spawned processes (drivers,
  the `ion` shell itself) survive — which is why the desktop still "rendered".
- It happens in **`relibc_start_v1`** (the program entry), *before* `main`.

**Root cause.** `relibc_start_v1` → `relibc_verify_host()` → `Sys::verify()`:

```rust
fn verify() -> bool {
    // SYS_YIELD is a no-op on Redox; the same number is a different, failing syscall
    // on Linux — a heuristic to refuse running a Redox binary on Linux.
    syscall::syscall5(syscall::number::SYS_YIELD, !0, !0, !0, !0, !0).is_ok()
}
```

On aarch64 a freshly `fork`+`exec`'d process's **first** syscall returns a stale `-1`
(the input `x0`, never overwritten by the kernel) instead of `YIELD`'s `0`. `verify()`
reads `-1`, concludes "not Redox", and aborts. Confirmed two ways: NOP-ing the abort
branch in `libc.so` made `whoami`/`ls`/`env` work with zero crashes, and the fault
symbolizes to the exact `brk #1` at `relibc_start_v1+0xf48` (a `handle_alloc_error`/abort
landing pad reached from the `cmn w0,#0x84; b.cs` error check right after the yield `svc`).

**Fix (relibc).** The [`Gh0s777tt/eos-relibc`](https://github.com/Gh0s777tt/eos-relibc)
fork (`eos` @ `beb93474`, recipe pinned) issues the yield for its side effect but does not
treat its unreliable result as fatal on aarch64; **x86_64 keeps the strict check**.
Verified by binary disasm + boot: `whoami`/`uname`/`ls`/`env` all run, zero aborts.
Upstream-ready patch: [`upstream/relibc/`](../upstream/relibc/).

**The real root fix (kernel, follow-up).** The relibc change is a workaround. The proper
fix stops the first post-`exec` syscall from returning a stale `x0` on aarch64 — most
likely in the kernel's aarch64 `exec`/`sigreturn`-to-entry transition or its syscall
return-register handling. See *Remaining minor items* above.
