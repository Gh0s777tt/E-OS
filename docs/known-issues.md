# 🐞 Known Issues

## `R-401b` — aarch64 boot stops at the RedoxFS root mount

**Status:** open · **upstream** (Redox) · *not* E-OS-specific.

The E-OS **aarch64** image builds with full branding and boots the red/black E-OS
bootloader under QEMU `virt`, but the kernel **does not reach `eos login:`** — the
`redoxfs` user-space process faults while mounting the RedoxFS root.

### Symptom (serial)

```
... synchronous_exception_at_el0 ...
kernel::context::signal: UNHANDLED EXCEPTION, CPU #0, PID 18, NAME /scheme/initfs/bin/redoxfs
thread 'main' panicked at src/bin/mount.rs:396:
  called `Result::unwrap()` on an `Err` value: UnexpectedEof "failed to fill whole buffer"
redoxfs ... failed with exit status: 101
```

### Diagnosis

- The **bootloader finds RedoxFS** on the disk (`RedoxFS …: 697 MiB`) — so the disk
  and the UEFI block-IO path are fine.
- The fault is a **synchronous exception at EL0** (user space) inside `redoxfs`.
  The trace value `0x92000007` decodes as `ESR_EL1`: `EC = 0x24` (Data Abort from a
  lower EL), `DFSC = 0x07` (**translation fault, level 3**) — i.e. `redoxfs`
  dereferenced an **unmapped page** while reading the filesystem. The
  `UnexpectedEof` is the downstream symptom of the aborted read.
- **Reproduced identically with NVMe *and* `virtio-blk`** → it is **not** a
  disk-driver issue.

### Conclusion

An upstream **aarch64 memory-mapping bug** in `redoxfs` / `relibc` (or the kernel's
user-space page mapping on aarch64), **unrelated to E-OS branding** — E-OS only
replaces images and strings; the kernel, `redoxfs` and `relibc` are upstream Redox.
A real fix belongs in `redox-os/{redoxfs,relibc,kernel}`.

### Workaround

None yet — use **x86_64** for a full desktop. The aarch64 image remains useful for
verifying the bootloader/branding and the cross-arch build. Tracked as
[`R-401b`](../ROADMAP.md).
