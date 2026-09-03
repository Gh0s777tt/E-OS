# RFC 0001 — A hypervisor interface in the Redox kernel

| | |
|---|---|
| **RFC** | 0001 |
| **Title** | A hypervisor interface in the Redox kernel (`hv:`) |
| **Status** | **Draft — not submitted.** Written to be sent to Redox upstream for discussion before any code is written |
| **Authors** | E-OS project (downstream distribution of Redox OS) |
| **Target** | `redox-os/kernel`, x86_64 first, aarch64 second |
| **Review date** | 2026-09-03 |
| **Measured against** | `redox-os/kernel` `f4d59db5` (2026-09-02), `redox-os/bootloader` `cc922ec0` (2026-08-25), `redox-os/base` `2b737f75` (2026-09-02), `redox-os/syscall` `4cc3baaf` (2026-08-21), `redox-os/libredox` `b2e7c8ba` (2026-09-01); E-OS forks `eos-kernel` `68a51035` and `eos-base` `816546df`. Full hashes and clean-tree assertions in §11.0. |
| **Owner** | Gh0s777tt |
| **Downstream tracking id** | `CS-201` (E-OS ROADMAP §11.4) |

> **Why this document exists before any code.** E-OS is a downstream distribution of Redox. A
> hypervisor is not a feature that can be carried as a downstream patch set: it touches the
> address-space model, the scheme table, the interrupt path and the boot exception level. A fork
> that adds one and is not upstream is a fork that cannot be rebased. So the design goes to
> upstream first, and the first line of implementation waits for the answer. If upstream says no,
> §10 says what happens and why that outcome is worse for both sides.

---

## 1. Summary

Add to the Redox kernel a **minimal hardware-virtualisation interface**, exposed as a new global
kernel scheme `hv:`, which:

- owns the CPU-vendor virtualisation state (VMCS on Intel VMX, VMCB on AMD SVM, EL2 state on
  aarch64) — because only the kernel can execute `vmlaunch` / `vmrun` / manage `HCR_EL2`;
- builds a **second-stage translation** (EPT on Intel, NPT on AMD, stage-2 on aarch64) over
  frames that are already owned by an ordinary user process;
- **routes every VM exit it does not itself have to service back to an unprivileged user-space
  process** — the VMM — over the ordinary scheme read/write path;
- does **not** emulate a single device. No virtio, no interrupt controller model, no BIOS, no
  console. All of that is user-space, out of the kernel, and out of this RFC.

The kernel-side deliverable is deliberately close to the smallest thing that can work: a VCPU
lifecycle, a second-stage page table, and an exit-record queue. Everything above it is a normal
Redox program that can be killed, restarted, sandboxed and run as a non-root user.

This is the microkernel version of the split KVM made: a thin privileged mechanism, all policy
and device emulation outside. The difference from KVM is that the interface is a **scheme**, not
a pile of `ioctl`s, which fits Redox's existing model and its existing namespace-based sandboxing
for free.

---

## 2. Motivation

### 2.1 The concrete need

E-OS is building a cloud platform (product name **E-Cloud**; downstream register `CS-*`). The
platform's own roadmap is explicit that the host must be E-OS itself rather than E-OS running as
a guest under somebody else's hypervisor. Everything in that plan's third tier — virtual
machines, Linux and Windows guests, VM-shaped tenant isolation — sits behind exactly one missing
capability, and it is a kernel capability.

That is not a wish. It has been measured. §11 of this document reproduces the commands.

### 2.2 What isolation on Redox is today, stated precisely

Redox's isolation primitive is the **scheme namespace**: a process can be given a narrowed set of
schemes, and narrowing is unprivileged and one-way. That is a genuinely good primitive, and
downstream we use it — the sandboxed-session configuration passes a narrow scheme set, brokers the
file scheme rather than handing it over, and allowlists paths.

But it must be described for what it is:

> Scheme namespaces are isolation **between processes of the same machine, enforced in software by
> the kernel**. They are not protection against a malicious or compromised driver reprogramming
> DMA, and they are not a hypervisor boundary.

Three consequences follow, and each of them is a reason for this RFC:

1. **There is no way to run an unmodified foreign OS.** A guest kernel wants to run privileged
   instructions and manage its own page tables. Scheme namespaces cannot offer that at any price.
   Today the only route on Redox is full software emulation (a TCG-only QEMU port), which is slow
   by construction and is an interim, not a product.
2. **There is no boundary that survives a driver bug.** Redox drivers are separate user-space
   processes, which is better than a monolith — but without an IOMMU that is *logical* separation.
   A device programmed to DMA anywhere still DMAs anywhere.
3. **The strongest compartment Redox can offer stops at the same-machine, same-kernel line.** For
   a multi-tenant platform, "different tenants, same kernel, isolated by kernel-enforced namespaces"
   is a defensible model only as long as the kernel has no exploitable bug. Hardware
   virtualisation gives a second, independent boundary whose failure modes are different. Defence
   in depth is the entire argument; it is not a performance argument.

### 2.3 Why this belongs upstream and not in a fork

- It changes the **address-space model**: second-stage tables must be built over frames whose
  lifetime is already managed by `AddrSpace`/`Grant`. A downstream patch here conflicts with
  every upstream memory change, forever.
- It changes the **global scheme table**, which is a fixed-size array with a compile-time
  assertion (§11.6).
- On aarch64 it changes **which exception level the kernel runs at** — specifically, it asks the
  boot chain to *stop* dropping from EL2 to EL1, which both the bootloader and the kernel's own
  secondary-CPU trampoline deliberately do today (§5.6, §11.4). That is not patchable in isolation;
  it inverts an existing, intentional design decision in two repositories.
- A hypervisor is a security boundary. A security boundary maintained by one downstream, reviewed
  by nobody else, is worth less than no boundary at all, because it will be advertised as one.

We would rather have a smaller design accepted upstream than a larger one carried alone.

---

## 3. Non-goals

Explicitly **out of scope for this RFC**. Listing them is part of the proposal: an interface that
promises these is a different, much larger interface.

| Not proposed | Why |
|---|---|
| **Device emulation in the kernel** | virtio, PCI config space, interrupt-controller models, serial, RTC, BIOS/UEFI firmware — all user-space. The kernel must not grow a device model. |
| **A VMM** | The user-space VMM is a separate program and a separate proposal (downstream `CS-202`). This RFC defines only the interface it talks to. |
| **Nested virtualisation** | Running a hypervisor inside a Redox guest. Large, and not needed for any motivating use case. The interface should not *forbid* it later, but nothing here implements it. |
| **Live migration, snapshotting, checkpointing** | Policy, and it belongs to the VMM plus a defined state-serialisation format. Out of scope. |
| **Windows guests specifically** | Needs UEFI and TPM emulation in the VMM and a licensing answer that is not a technical question. |
| **GPU or accelerator passthrough** | Needs the IOMMU work of §5.7 *and* a driver stack Redox does not have. |
| **Paravirtualised Redox-on-Redox** | A guest interface for cooperative guests may be worth doing later; it is not this. |
| **Any performance target** | This RFC proposes a mechanism, not a number. Claiming a number before the mechanism exists would be inventing evidence. |
| **A schedule** | No dates. Downstream, nothing in this tier has a date either, deliberately. |

---

## 4. Current state, as measured

Full commands and raw output are in §11, and `_probe/remeasure.sh` re-runs every one of them and
fails if any has changed. Measured on a clean, pinned checkout of upstream `redox-os/kernel` at
`f4d59db53e86ea4b4218905f4053dc1644aa3fa3` (2026-09-02), kernel version `0.5.12`, 192 `.rs` files.

| Question | Measured answer |
|---|---|
| Is there any VMX/SVM code? | **No.** `vmcs`, `vmcb`, `vmlaunch`, `vmresume`, `vmrun`, `vmxon`, `svm_`, `npt_` — **0 occurrences** across 192 `.rs` files. |
| Any EPT code? | **No.** The one `ept_` match is the substring in `accept_head_leak`, a comment in `src/scheme/user.rs:454`. |
| So what mentions virtualisation? | Exactly one thing on x86: `src/arch/x86_shared/device/cpu.rs:131-132` prints the CPUID `vmx` flag in the CPU-info string. It is a **string**, not a capability. |
| Is VMX ever *enabled*? | **No.** Six CR4 writes (UMIP, SMEP, PPMC, SMAP, FSGSBASE, OSXSAVE). Zero `CR4.VMXE` writes, zero `IA32_FEATURE_CONTROL` accesses. |
| What exception level does the kernel run at? | **EL1 — and it gets there on purpose, from EL2.** The bootloader reads `CurrentEL`, and if it finds EL2 it programs `HCR_EL2`, `SPSR_EL2`, `ELR_EL2` and `eret`s down to EL1 (`bootloader/src/os/uefi/arch/aarch64.rs:48-121`). The kernel's secondary-CPU trampoline does the same for APs entered at EL2 (`src/arch/aarch64/device/cpu/boot.rs:81-117`), and refuses to boot a CPU entered at any other level (`STATE_BAD_ENTRY_EL`). |
| Does the kernel know its exception level? | **Yes.** `CurrentEL` is read at `boot.rs:81` and the EL2 branch programs `hcr_el2`, `cnthctl_el2`, `cntvoff_el2`, `cptr_el2`, `hstr_el2`, `mdcr_el2`, `elr_el2` and `spsr_el2` before the `eret` at `:117`. |
| How does the kernel reach PSCI? | **Through a runtime-selected conduit, not a hard-coded `hvc`.** `src/arch/aarch64/device/psci.rs` (8367 bytes) reads the device tree `method` property of an `arm,psci-1.0`/`arm,psci-0.2` node, falls back to the ACPI FADT ARM boot-architecture flags, probes `PSCI_VERSION` before publishing the conduit, and refuses PSCI v0.1. `src/arch/aarch64/stop.rs` contains **zero** `hvc` instructions; it calls `psci::system_reset()` / `psci::system_off()` and halts with a named error if they fail. |
| Is there EL2 state handling for *hosting*? | **No.** Every EL2 register write above is part of *leaving* EL2. There is no `VTTBR_EL2`, no stage-2 table, no `HCR_EL2.VM`, no guest context. |
| The ACPI GTDT EL2 fields, then? | Parsed and **never read**. `src/acpi/gtdt.rs:16-17` declares `el2_timer_gsiv` / `el2_timer_flags`; `gtdt.rs:45` selects the **EL1** timer (`non_secure_el1_timer_gsiv`, `virtual_el1_timer_gsiv`). The `virtual_el2_*` fields are commented out entirely. Zero reads of any `el2_*` field. |
| Is there an IOMMU path **in the kernel**? | **No.** `dmar`, `iommu`, `smmu` — **0 occurrences** in the whole kernel tree, and `src/acpi/mod.rs` declares no DMAR module. |
| Is there one **anywhere in Redox**? | **A parser, yes; enforcement, no.** `redox-os/base` carries a complete 529-line DMAR/VT-d table parser at `drivers/acpid/src/acpi/dmar/mod.rs`, whose entry point is commented out: `//TODO (hangs on real hardware): Dmar::init(&this);` (`drivers/acpid/src/acpi.rs:454`). Even enabled it only **logs** DRHD registers — it writes no root table and enables no translation (§11.5). |

**Reading of this table, corrected.** An earlier draft of this RFC said Redox aarch64 "is at zero,
cleanly" on exception levels and that "the kernel does not know or care which exception level it was
entered at". **That was wrong**, and it was wrong in the most expensive direction: it would have told
Redox maintainers that code they had already written did not exist. The measurement had been taken
against the E-OS fork (`68a5103`, 2026-08-29), which predates this upstream work. See §11.0 for how
that inference failed and why the failure was structural rather than careless.

The corrected reading is narrower and, for this RFC, better:

- **On x86_64, Redox really is at zero.** Nothing to undo, nothing to break. That half of the
  original claim survives re-measurement against upstream unchanged.
- **On aarch64, Redox is not at zero — it is at a deliberate, opposite position.** The boot chain
  detects EL2 and *leaves* it, in two places, on purpose. The kernel already selects its firmware
  conduit at runtime. So the aarch64 work this RFC needs is not "teach the kernel about exception
  levels"; that is done. It is "ask the boot chain to stop doing something it currently does
  deliberately", which is a different, smaller, and more contentious request. §5.6 states it that way.

## 5. Design sketch

### 5.1 Shape

```
   user space                        │  kernel
                                     │
   ┌──────────────┐  scheme calls    │   ┌────────────────────────────┐
   │  VMM process │◄────────────────►│   │  hv: (new global scheme)   │
   │ (unprivileged)│  open/read/     │   │  ────────────────────────  │
   │              │  write/fmap      │   │  VM objects                │
   │ virtio, PCI, │                  │   │  VCPU objects              │
   │ firmware,    │                  │   │  2nd-stage tables (EPT/    │
   │ console, disk│                  │   │    NPT/stage-2)            │
   └──────┬───────┘                  │   │  exit records              │
          │ owns guest RAM as        │   └─────────────┬──────────────┘
          │ ordinary anonymous       │                 │ vmlaunch / vmrun / eret
          │ mappings in its OWN      │                 ▼
          │ address space            │        ┌──────────────────┐
          └──────────────────────────┼───────►│   guest (VMX     │
                                     │        │   non-root /     │
                                     │        │   EL1 under EL2) │
                                     │        └──────────────────┘
```

The kernel is the mechanism. The VMM is a normal program with no special privilege beyond an open
handle to `hv:`.

### 5.2 The `hv:` scheme surface

A path hierarchy, using ordinary Redox scheme operations. Sketch, deliberately small:

| Path | Operation | Meaning |
|---|---|---|
| `hv:` | `open` | Probe. Reading returns a capability record: vendor (`vmx`/`svm`/`el2`), whether the CPU supports it, whether it is *enabled* (§6.3), second-stage page sizes, max VCPUs. Fails closed (§6.3) if virtualisation is off. |
| `hv:vm` | `open` | Create a VM. The returned handle **owns** the VM; closing it destroys the VM and every VCPU under it. |
| `hv:vm/<id>/mem` | `write` | Register a guest-physical region: `{ guest_phys, len, flags }` describing a range **of the caller's own address space**. The kernel maps the backing frames into the second-stage table. |
| `hv:vm/<id>/vcpu` | `open` | Create a VCPU. The handle is the VCPU. |
| `hv:vm/<id>/vcpu/<n>/regs` | `read`/`write` | Architectural register file, as a versioned, fixed-layout struct. |
| `hv:vm/<id>/vcpu/<n>/run` | `read` | **The core call.** Enters the guest, blocks, and returns one *exit record* when the guest exits for a reason the kernel does not service itself. |
| `hv:vm/<id>/vcpu/<n>/run` | `write` | Supply the result of the previous exit (e.g. the data for an MMIO read) and resume. |
| `hv:vm/<id>/irq` | `write` | Inject an interrupt/event into the guest. |

Notes on why this shape:

- **`run` is a blocking read.** This is the natural Redox spelling of "enter guest, come back with
  a reason", and it composes with the existing event/wait machinery, so a VMM can be single- or
  multi-threaded without new kernel concepts.
- **The exit record is a fixed, versioned struct**, not a string. It must carry a version field
  from the first commit, because it is the one structure that will be extended forever.
- **No `ioctl` analogue is introduced.** Everything is open/read/write/close on paths. This is the
  main reason a scheme is better here than a KVM-style device: `hv:` is a scheme *name*, so
  Redox's existing namespace narrowing already answers "which processes may create VMs" — it is
  simply whether `hv` is in the process's scheme set. No new permission concept is needed.

### 5.3 Memory: reuse the existing model, do not invent one

Guest-physical memory should be **the VMM's own memory**. The VMM allocates ordinary anonymous
mappings and declares them as guest-physical ranges; the kernel builds the second-stage table over
the same frames.

Redox already has the vocabulary for this. `Provider` in `src/context/memory.rs:1182` distinguishes
`Allocated`, `AllocatedShared`, `PhysBorrowed`, `External { address_space, src_base, .. }` and
`FmapBorrowed`. `External` is *precisely* "memory borrowed directly from another address space",
which is the relationship between a VM's second-stage table and the VMM that owns the pages.

The proposal is therefore: **no new backing kind.** The second-stage table is a second translation
over frames already tracked by `AddrSpace`, and the existing pinning/refcount rules
(`is_pinned_userscheme_borrow`, `pin_refcount`) are what stop a VMM from freeing memory a guest is
running on. Getting this right is most of the kernel-side risk, and it is also exactly why this
cannot be a downstream patch: it is intimate with upstream's memory code.

Open sub-questions in §8.

### 5.4 Exit handling

Two classes, and the split is the whole performance story:

- **Serviced in the kernel** — the small, hot, boring set: second-stage faults on already-registered
  RAM, and (if the design admits it) a timer. Nothing that needs policy.
- **Returned to the VMM** — everything else: MMIO to unregistered addresses, port I/O, `cpuid`,
  `hlt`, MSR access, and every fault the kernel does not recognise.

**The default must be "return it to user space", not "handle it".** A kernel that grows exit
handlers grows a device model, and then it is not a microkernel. The list of kernel-serviced exits
should be short, closed, and require an RFC of its own to extend.

### 5.5 x86_64 first

x86_64 is proposed first for reasons that are about testability, not preference:

- VMX and SVM are entered from the kernel's *existing* exception level. Nothing about the boot
  contract changes. It is additive.
- The state is well-documented and the lifecycle is mechanical: `VMXON` → allocate and initialise a
  VMCS → `VMPTRLD` → `VMLAUNCH`, then `VMRESUME` per re-entry, with exit reason read from the VMCS.
  AMD SVM is the same shape with a VMCB and `VMRUN`.
- Enabling requires `CR4.VMXE` and `IA32_FEATURE_CONTROL` — neither of which the kernel touches
  today (§11.3), so the change is visible and self-contained.

The proposal is: **Intel VMX + EPT and AMD SVM + NPT behind the same `hv:` surface.** The scheme
surface must not leak vendor detail beyond the capability record.

**Which of the two is written first is a rig question, not a design question, and the rig answers
it.** §11.7 measures that the E-OS reference host's QEMU exposes `svm=True` and `npt=True` under
plain TCG and refuses only the `vmx` bit. So the AMD half is developable today on hardware the
project already has, and the Intel half is not. An earlier draft of this RFC asserted the opposite
ordering ("VMX first, SVM second") and then reported that neither could be worked on here; the
second half of that was a measurement error (§7.0).

### 5.6 aarch64: what upstream has already built, and the one thing that is left

**This section is a correction.** An earlier draft proposed, as new work, that "the kernel must
learn its own exception level (`CurrentEL`) and choose its PSCI conduit accordingly", and called
that "a change every aarch64 Redox platform feels". **Upstream has already done both**, and this
RFC should build on it rather than propose it. The measurements are in §11.4; the reason the draft
got it wrong is in §11.0.

**Prior art, measured at `f4d59db`:**

| Already upstream | Where |
|---|---|
| The bootloader reads `CurrentEL`, and drops EL2→EL1 when it finds EL2 | `bootloader/src/os/uefi/arch/aarch64.rs:48-121` |
| ...setting `HCR_EL2` with, in the source's own words, *"disable hypervisor call"* | `aarch64.rs:102-105` (`(1<<31) \| (1<<29)`) |
| The kernel's AP trampoline reads `CurrentEL`, drops EL2→EL1 for secondaries, and refuses any other entry level | `src/arch/aarch64/device/cpu/boot.rs:81-117`, `STATE_BAD_ENTRY_EL` |
| PSCI conduit selected at runtime: `hvc` or `smc`, from the DT `method` property or the ACPI FADT flags | `src/arch/aarch64/device/psci.rs:26-47, 100-179` |
| `PSCI_VERSION` probed before the conduit is published, so a half-initialised interface cannot be used | `psci.rs:61-93` |
| `SMC` emitted as `.inst 0xd4000003` because the Redox aarch64 target does not advertise EL3 | `psci.rs:248-260` |
| A unit test that the conduit parser rejects `"SMC"` and `""` | `psci.rs:272-278` |
| `stop.rs` free of any hard-coded `hvc` | `src/arch/aarch64/stop.rs` — 0 occurrences |

That is a more complete PSCI-conduit abstraction than this RFC was going to ask for. **Q2 is
therefore withdrawn** (§8): there is no separate PSCI-conduit RFC to write, because the conduit
work is merged.

**What is actually left, stated precisely.** To *host* guests, the kernel must be at EL2. The boot
chain currently detects EL2 and leaves it, twice, on purpose. So the request is not "add exception
level awareness"; it is:

1. **Add a mode in which the boot chain does not drop to EL1.** The bootloader's EL2 branch and the
   kernel's AP trampoline both need a path that stays at EL2 (VHE — `HCR_EL2.E2H` — being the
   arrangement that lets a kernel written for EL1 run at EL2 largely unchanged). This is a change to
   `redox-os/bootloader` as well as `redox-os/kernel`, which the earlier draft did not notice.
2. **Reconcile that mode with the PSCI conduit that already exists.** A kernel that stays at EL2 is
   the thing `HVC` would have trapped to, so it must reach PSCI by `SMC`, or not at all where there
   is no EL3. `psci.rs` can already select `smc`; what it cannot yet do is *require* it because the
   kernel occupies EL2. That is a small, local change to a module that already has the structure
   for it — not a new abstraction.
3. **Keep the existing drop-to-EL1 as the default.** Every aarch64 Redox platform that will never
   run a VM should see no behavioural change at all. The earlier draft's claim that "this is a
   change every aarch64 Redox platform feels" is false if the EL2-resident mode is opt-in, and
   making it opt-in is cheap.

**On hosts that boot Redox at EL1 from above.** A kernel entered at EL1 by a hypervisor above it
cannot offer `hv:` unless nested virtualisation is available to it; `hv:` must report "unsupported"
and fail closed (§6.3). This is unchanged from the earlier draft, but its worked example was wrong.
The draft said "which is what happens under macOS/HVF". **Measured, that is not the constraint on
this host**: `hv_vm_config_get_el2_supported()` returns `HV_SUCCESS` with `el2_supported=1` on the
E-OS reference machine (§11.7). What refuses is QEMU 11.0.2, whose `mach-virt` HVF backend does not
reference the Hypervisor.framework EL2 API at all — measured as zero `_hv_vm_config_*_el2` imports
in a binary that imports 37 other Hypervisor.framework symbols. The macOS host is capable; the
emulator in front of it has not wired the capability up.

### 5.7 IOMMU is a prerequisite for exactly one feature, and a benefit to everything else

Device assignment (giving a guest a real PCI device) **must not** be implemented without an IOMMU.
Without translation between device and physical addresses, an assigned device can DMA over the
host. That is not a weaker guarantee; it is the absence of one.

**Measured today, and the earlier draft got the scope of this wrong too.** It said "no `dmar`, no
`iommu`, no `smmu`, anywhere". That is true of the **kernel** and false of **Redox**. `redox-os/base`
already carries a complete DMAR (Intel VT-d) table parser — 529 lines at
`drivers/acpid/src/acpi/dmar/mod.rs` — and its entry point is disabled by a one-line comment with a
stated reason: `//TODO (hangs on real hardware): Dmar::init(&this);`. The parser is upstream's, not
E-OS's: it is byte-identical in intent at both `redox-os/base` `2b737f7` and the E-OS fork
`816546d`, differing only in line number (§11.5).

What is genuinely absent is **enforcement**, and that finding is stronger than the one it replaces.
`Dmar::init` reads DRHD registers and `log::debug!`s them. It writes no root table, builds no
domains, assigns no device to one, and enables no translation. So the accurate statement is:

> Redox can **read** the table that describes the IOMMU. Nothing in Redox **programs** the IOMMU,
> on either architecture, and on aarch64 there is not even a parser — `smmu` is zero occurrences
> everywhere measured.

So:

- **This RFC does not propose device assignment.** It is deferred until IOMMU support exists.
- The `hv:` interface must be designed so that assignment can be added later without breaking it —
  but must not ship a stub that pretends.
- Worth stating for upstream's benefit: **IOMMU support is valuable to Redox with or without this
  RFC.** Redox's drivers are already separate processes; an IOMMU is what turns that architectural
  separation into an enforced one. It is arguably the higher-value piece of work in this document,
  and it is usable immediately. If upstream wants only one of the two things proposed here, we
  would advocate for the IOMMU.
- **And it starts further along than the earlier draft implied.** A parser exists, upstream wrote
  it, and there is a recorded reason it is off — "hangs on real hardware". That comment is a lead,
  not a blocker: the first question for the IOMMU track is *why* it hangs, not *how to parse DMAR*.
  Q9 is asked on that footing.

---

## 6. Security model

### 6.1 The VMM is unprivileged, and this is the point

The VMM is an ordinary process. It is not root, has no ambient authority, holds no special
capability beyond `hv:` being in its scheme namespace, and can be killed at any time. Compromising
it should get an attacker: the guest's memory (which it already owns and provides), and the ability
to make `hv:` calls it could already make. It should **not** get the host kernel.

This is the strongest argument for doing this in Redox specifically. In a monolithic kernel the
VMM's neighbours are the whole kernel. Here the VMM is a process among processes, and the sandbox
it runs in is the one Redox already has.

### 6.2 What the kernel must guarantee

These are the properties a reviewer should hold the implementation to. Each is stated so that it
can be **falsified by a test**, not merely asserted.

| # | Guarantee | How it is falsified |
|---|---|---|
| G1 | A guest cannot read or write any host frame not registered by its own VMM through `hv:vm/<id>/mem`. | Guest writes a physical address outside every registered region; host memory changes. |
| G2 | A guest cannot cause the host kernel to execute guest-controlled data or to fault unrecoverably. | A malformed guest state panics the host rather than killing the VM. |
| G3 | A malicious **VMM** cannot escalate. Every value it supplies through `regs`, `mem` and `run` is validated against architectural rules before it reaches a VMCS/VMCB/EL2 register. | A VMM writes a reserved or illegal control field and the host faults, hangs, or gains the VMM privilege. |
| G4 | A VMM cannot free, unmap or shrink guest memory while a VCPU is running on it. | VMM unmaps a registered region during `run`; the kernel touches a freed frame. |
| G5 | VM and VCPU objects are destroyed completely when their handles close or the process dies — including second-stage tables and any pinned frames. | Kill the VMM mid-`run`; frames stay pinned or leak. |
| G6 | A process without `hv` in its scheme namespace cannot create a VM by any path. | A narrowed process reaches `hv:` indirectly. |
| G7 | Timing/side-channel exposure is **stated, not silently assumed away**. Sibling-hyperthread and cache-sharing attacks are *not* claimed to be mitigated by this design. | A document claims isolation this design does not provide. |

**G7 is deliberate.** Writing down what is *not* defended against is part of the boundary. A
hypervisor advertised as more than it is, is a liability.

### 6.3 Fail closed, with one explicit escape

Virtualisation must be **off unless explicitly enabled**, and the escape must be visible:

- `hv:` is not registered at all unless the platform supports virtualisation *and* the kernel was
  configured to enable it.
- Probing an unsupported or disabled platform returns a **specific** error meaning "not available
  here", distinguishable from "you are not allowed" and from "it broke". A caller must be able to
  tell *the mechanism is absent* from *the mechanism refused you* — those need opposite reactions.
- Anything that weakens a guarantee (e.g. a future device-assignment path without an IOMMU) must
  require an explicit, named opt-in and must be impossible to reach by default. A build that
  silently allows it is a bug, not a convenience.

### 6.4 Attack surface added, honestly

Adding `hv:` **increases** the kernel's attack surface. That is the cost side of the ledger and it
should be in the RFC, not discovered in review:

- New privileged instructions executed on kernel state (`vmlaunch`, `vmrun`, EL2 register writes).
- A new second-stage page-table implementation — historically a rich source of bugs.
- A new user-facing kernel interface accepting complex structured input from an untrusted process,
  which is precisely the shape of input that deserves fuzzing (§7, stage 5).

The mitigation is that the surface is **small and closed**: one scheme, a fixed set of paths, a
versioned fixed-layout exit record, no device model. If the kernel-side diff cannot be kept small,
that is itself evidence the design is wrong.

---

## 7. Staged plan, and what each stage can actually be tested on

Two rules govern this plan, both inherited from the downstream project's working contract and both
worth restating because they are what make a plan checkable:

1. **Every stage has an acceptance gate that can fail.** A gate that can only pass is not a gate.
2. **Every gate has a named negative test** — the specific way to break the thing and watch the gate
   go red. A check nobody has seen fail is a hypothesis, not a check.

### 7.0 Stage 0 — establish the rig, before anything else

**This stage exists because of a measurement.** An earlier draft of this RFC used this stage to
argue that the reference host could develop neither x86_64 path and therefore that the ordering of
§5.5 was inverted. **That argument was built on a measurement that had been taken and then not
read.** The probe in `_probe/rig_probe.py` was run before that draft was written and shows the
opposite for AMD. The corrected table:

Host: `uname -m` → `arm64`; `machdep.cpu.brand_string` → `Apple M4`; macOS `26.6.1`; QEMU `11.0.2`;
accelerators in the QEMU binary: `hvf`, `tcg`.

| Target | Can it be developed on the E-OS reference host? |
|---|---|
| **x86_64 Intel VMX + EPT** | **No.** QEMU's TCG reports `vmx=False` for every CPU model and prints `TCG doesn't support requested feature: CPUID[eax=01h].ECX.vmx [bit 5]` when the flag is forced. Needs an x86_64 host with VT-x, or KVM nested virtualisation — hardware the project does not have. |
| **x86_64 AMD SVM + NPT** | **Yes, under TCG.** Measured through QEMU's own `query-cpu-model-expansion` under `-accel tcg`: `-cpu max` → `svm=True npt=True vmx=False`; `-cpu EPYC` → `svm=True npt=True nrip-save=True`. `-cpu max,+svm` and `-cpu max,+svm,+npt` are accepted with **no warning of any kind**, while `+vmx` is refused. Slow, but present. |
| **aarch64 EL2** | **Yes, under TCG only.** `qemu-system-aarch64 -M virt,virtualization=on -accel tcg` starts (rc=0, no stderr). Under `-accel hvf` the same line is refused. |
| **aarch64 EL2 under HVF acceleration** | **Not through this QEMU.** The refusal is QEMU's, not the host's: `hv_vm_config_get_el2_supported()` returns `HV_SUCCESS`, `el2_supported=1` on this machine, and the QEMU binary imports 37 Hypervisor.framework symbols and **none** matching `_hv_vm_config_*_el2`. A QEMU that wires that API up, or a different VMM, would change this row. |

**The ordering is not inverted.** §5.5 argues x86_64 first on design grounds — additive, better
documented, does not touch the boot contract. The rig can host the **AMD half of exactly that**:
SVM plus NPT is the second-stage translation §1 and §5.5 name, and it is sufficient substrate for
stages 1 through 5 of §7.1 (capability probe, VM/VCPU lifecycle, second-stage tables, first guest
entry, exit routing). The earlier draft's conclusion — that the proposer could test only aarch64,
the harder boot-contract-changing path, and that this forced the ordering question — **does not
survive its own probe output**. What is genuinely blocked here is the Intel half, and only that.

- **Gate:** a written, reproducible rig description per architecture, including the honest entry
  "cannot be tested here" where that is the answer. `_probe/rig_probe.py` is that description in
  executable form.
- **Negative test:** `_probe/rig_probe.py` exits **2**, not 0 and not 1, when its instrument cannot
  run — measured by putting a non-QEMU binary on `PATH` under the name `qemu-system-aarch64`: the
  probe reaches the artefact check, finds no `Hypervisor.framework` link, and refuses to report an
  empty EL2-import result as a finding. A probe that reported "no EL2 API" from a binary it could
  not read would look identical to a true negative.
- **Second negative test:** `_probe/hv_el2_probe.sh` builds a mutant of its own C probe with the
  framework call removed and asserts the answer *changes* (`el2_supported=1` → `0`). If it does not
  change, the probe exits 1 and says the value it reports is the initialiser's, not the framework's.
  **That exit-1 branch has now been seen red, rather than asserted** — an earlier revision described
  it without ever running it, which is the definition §5.4 of the downstream contract rejects. Fed a
  source whose `el2` value is discarded after the framework call (so the `sed` target still matches
  and both builds print `0`), the probe reports `FAIL -- removing the framework call did not change
  the answer` and exits **1**. Fed a source where the call is already absent, the `sed` no longer
  matches and it exits **2** — instrument, not finding. All three exit codes are now measured.

### 7.1 Stages

Each row: what is built, the gate that must pass, and the specific way to make that gate fail.

| # | Stage | Acceptance gate | Negative test (must be seen red) |
|---|---|---|---|
| 1 | **Capability detection and `hv:` probe.** No VM objects yet. CPUID feature reads (`svm`/`vmx`), `ID_AA64MMFR1_EL1` and the exception level the boot chain already knows on aarch64 (§5.6), capability record, fail-closed registration (§6.3). | On a supporting platform the probe reports support; on a non-supporting one `hv:` is absent and the error distinguishes "unavailable" from "denied". | Force the feature bit off in the emulated CPU and assert the probe reports unavailable — **and** assert the error differs from the permission error. If both paths return the same error, the interface has failed its own §6.3 requirement. |
| 2 | **VM and VCPU object lifecycle.** Create, enumerate, destroy. No guest entry. | Handle close destroys the VM; killing the VMM process destroys everything it owned. | Kill the VMM between create and destroy; assert every frame is unpinned and no allocation leaks (G5). Run it in a loop and watch the counters — a leak of one frame per iteration is the failure this catches. |
| 3 | **Second-stage tables.** NPT / EPT / stage-2 built over the VMM's registered regions. Still no guest entry; the table is inspected, not used. | A registered region produces the expected second-stage mapping; unregistering removes it. | Attempt to unmap a region while it is marked in use and assert the kernel **refuses** (G4). Also register an unaligned/overlapping region and assert rejection rather than a corrupt table. |
| 4 | **First guest entry.** A guest of a few instructions that immediately triggers a known exit. | `run` returns an exit record with the expected reason and instruction pointer. | Write a deliberately illegal control field through `regs` before `run` and assert a clean `EINVAL`-class error — **not** a host fault, hang or panic (G3). This is the single most important negative test in the plan: it is the difference between a validated interface and an escalation path. |
| 5 | **Exit routing and the MMIO round trip.** Exit to VMM, VMM supplies a value, guest resumes. Fuzzing of the `hv:` input surface begins here. | A guest reads an MMIO address, the VMM answers, the guest observes the answer. | Have the VMM return malformed or out-of-range results for an exit and assert the kernel rejects them. Fuzz `regs`/`mem`/`run` inputs; any host crash is a stage-5 blocker, not a stage-6 bug. |
| 6 | **A real guest kernel boots.** Linux first — best documented, most forgiving of an incomplete VMM, and the failure messages are legible. | A Linux kernel reaches userspace inside the guest. | Withdraw one required piece (e.g. a device the VMM is expected to provide) and assert the failure is a clean, reported error rather than a silent hang. A harness whose only outcomes are "boots" and "hangs forever" cannot tell a regression from a slow day. |
| 7 | **IOMMU support.** Independent track (§5.7). Valuable to Redox with or without this RFC. Not greenfield: `base` already parses DMAR and logs DRHD registers behind a disabled call (§11.5), so stage 7 starts at *programming* the unit, not at reading the table — and at finding out what "hangs on real hardware" meant. | Device DMA is translated; a device cannot reach memory outside its domain. | Point a device at an address outside its domain and assert the transaction faults. If nothing faults, the IOMMU is configured but not enforcing — which looks identical to working, from every other angle. |
| 8 | **Device assignment.** Gated on stage 7 and **only** on stage 7. | An assigned device works inside a guest and cannot reach host memory. | Attempt assignment on a build without IOMMU support and assert it is **refused**, not warned about. |

**Rule across all stages:** verify the artefact, not the exit code. "The build passed" is not
evidence that a hypervisor ran; a guest exit record read back and checked is.

---

## 8. Open questions for upstream

These are genuine questions, not rhetorical ones. Several would change the design substantially,
and that is why this document exists before the code.

**Q1 — Is a hypervisor wanted in Redox at all?**
The most important question, and the one this RFC cannot answer for upstream. A microkernel project
may reasonably hold that the kernel should not grow this, even thinly. If the answer is no, we would
rather hear it now than after the work. A *reasoned* no is a useful outcome of this RFC.

**Q2 — WITHDRAWN.** *Was: "should the aarch64 EL2 / PSCI-conduit change be a separate RFC?"*
The question is moot. The PSCI-conduit abstraction it proposed **is already merged upstream**
(`src/arch/aarch64/device/psci.rs` at `f4d59db`, §11.4), and so is `CurrentEL` awareness in both the
bootloader and the kernel's AP trampoline. The question was generated by measuring the E-OS fork and
inferring upstream's state from it (§11.0). It is left visible rather than deleted, because a
withdrawn question that says why is more useful to a reviewer than a question that quietly vanishes.

**Q2′ — Should the EL2-resident boot mode be a separate RFC, and does it belong in the bootloader?**
What is genuinely left of the old Q2 (§5.6): a mode in which the boot chain **stops** dropping EL2→EL1.
That touches `redox-os/bootloader` (`src/os/uefi/arch/aarch64.rs:48-121`) as well as the kernel's AP
trampoline. Two questions follow. Does upstream want that as its own proposal, given it spans two
repositories? And is "default unchanged, EL2-resident opt-in" acceptable as the compatibility
contract, so that platforms which never run a VM see no behavioural change at all?

**Q3 — Which x86_64 vendor should lead, given the rig?**
*Re-opened on a corrected footing.* §5.5 argues x86_64 first on design grounds and that argument
stands. §7.0 now measures that the reference host **can** develop the AMD half (TCG exposes
`svm=True`, `npt=True`) and **cannot** develop the Intel half (`vmx=False`, refused). The earlier
draft asked upstream to choose between architectures because it believed neither x86_64 path was
testable; that premise was wrong. The question that remains is narrower and answerable: **is SVM +
NPT an acceptable first implementation**, with VMX + EPT second behind the same `hv:` surface, or
does upstream consider Intel-first non-negotiable — in which case the blocker is x86_64 hardware,
and that is a procurement question rather than a design one.

**Q4 — Is a scheme the right interface?**
`hv:` reuses namespace narrowing as the permission model for free, which is elegant. But it puts a
complex, performance-sensitive, structured-binary protocol through a file-shaped API. Would upstream
prefer a dedicated syscall surface, and if so what is the permission story that replaces "is `hv` in
your namespace"?

**Q5 — The memory model.**
Is `Provider::External` the right basis for guest-physical memory (§5.3), or should second-stage
mappings be a new `Provider` variant? Who owns pinning, and what precisely happens when a VMM
`munmap`s a region a VCPU is running on — refuse, or unmap-and-fault-the-guest?

**Q6 — Which exits may the kernel service?**
We propose a short, closed list that requires an RFC to extend (§5.4). Does upstream agree that the
list should be closed by policy? If it is open, the kernel grows a device model by increments and
nobody ever decides to let it.

**Q7 — ABI stability of the exit record.**
It is the one structure that will be extended forever. Where does it live — `redox_syscall`? What
is the versioning and compatibility commitment from the first commit?

**Q8 — The global scheme budget.**
`MAX_GLOBAL_SCHEMES` is 16 and 11 are used, with a compile-time assertion (§11.6). `hv:` makes 12.
Is spending one of the four remaining slots acceptable, or should this be a user-scheme-like
registration instead?

**Q9 — Should the IOMMU land first, on its own merits — and what does "hangs on real hardware" mean?**
We think there is a good case that it should (§5.7): it hardens Redox's existing driver separation
immediately, benefits every user, and is a prerequisite for only one part of this RFC. If upstream
wants exactly one thing from this document, we would nominate the IOMMU.

*Sharpened by re-measurement.* This RFC previously implied the IOMMU track starts from nothing. It
does not: `redox-os/base` already has a 529-line DMAR parser whose entry point is disabled by
`//TODO (hangs on real hardware)` (§11.5). So the question upstream can actually answer is narrower
and cheaper: **what hangs, and where?** Is it the DRHD register reads in `Dmar::init`, the mapping
that precedes them, or the ACPI path around it? Whoever wrote that comment knows something this
document does not, and it is the first thing the IOMMU track needs. Nothing about VT-d beyond
parsing has been attempted, so the answer is not blocked on design — it is blocked on one person's
memory of a hang.

**Q10 — Who maintains it?**
A hypervisor is a permanent maintenance and security-response commitment. E-OS is willing to do the
work and carry the review burden, but a security boundary with a bus factor of one is a bad
boundary. What would upstream need to see — co-maintainership, a review commitment, a test rig in
CI — before accepting code of this kind?

---

## 9. Alternatives considered

### 9.1 User-space only, with a minimal kernel trampoline

*Idea:* keep essentially everything in user space; the kernel exposes only enough to execute the
entry instruction.

*Assessment:* this is not really an alternative, it is a slider setting on the same design, and it
is the setting this RFC already aims at. `vmlaunch`/`vmrun` and EL2 register writes are privileged
by architecture; no amount of design moves them out of the kernel. What *can* move out is
everything else, and this RFC moves all of it out. The genuine open question — how thin can the
kernel half be? — is Q4/Q6, not a separate proposal.

*Rejected as a distinct option; adopted as the design's guiding constraint.*

### 9.2 A separate type-1 hypervisor below Redox (Xen/Jailhouse shape)

*Idea:* a small standalone hypervisor binary at VMX-root / EL2, with Redox running above it as a
privileged control domain, rather than a hypervisor interface inside the Redox kernel.

*Assessment:* this deserves serious consideration and is the strongest alternative, particularly for
a microkernel project, because it keeps the Redox kernel entirely unchanged and puts the
virtualisation TCB in a separate, separately auditable artefact. Against it: it is a **second
kernel** to write, boot, schedule and maintain; it fragments the driver and memory story (who owns
the hardware?); Redox loses direct control of the machine it is supposed to be the host of; and the
boot chain grows a component that the verified-boot chain must also cover. It is plausibly *more*
total work than this RFC, not less.

*Not proposed here, but if upstream's answer to Q1 is "not in the kernel", this is the design we
would want to discuss next, and we would rather discuss it than fork.*

### 9.3 Emulation only (no hardware virtualisation)

*Idea:* accept a TCG-based emulator as the answer for guests.

*Assessment:* this is the honest interim and downstream already records it as such (`CS-204`). It is
slow by construction — orders of magnitude, not percentages — which is acceptable for occasional
compatibility work and unacceptable as the basis of a hosting product. It also does not deliver the
second isolation boundary of §2.2, which is the security half of the motivation and does not depend
on speed at all.

*Kept as the interim. Rejected as the destination.*

### 9.4 Run Redox as a guest under someone else's hypervisor

*Idea:* do not host; be hosted.

*Assessment:* technically the least work and it is what happens today. It is rejected on product
grounds rather than technical ones: it makes the platform's isolation properties someone else's
property, and it forecloses the stated goal of E-OS being the host. It also does nothing for the
security argument in §2.2, which is about what Redox can offer *its own* users.

*Rejected.*

### 9.5 Do nothing

*Assessment:* a legitimate outcome, and cheaper than every option above. The cost is stated plainly:
Redox cannot run unmodified foreign operating systems, and its strongest isolation boundary remains
a software one in the kernel. If upstream judges that acceptable for Redox's goals, that is a
coherent position and the correct response is §10, not a fork made in irritation.

---

## 10. If upstream declines

Stated plainly, because the downstream cost of a decline is the honest counterweight to the cost of
acceptance, and it should be visible to both sides.

The E-OS kernel is a **type-C repository**: a fork of upstream carried with a small set of
justified, rebaseable patches. The whole maintenance model depends on `git rebase` onto upstream
continuing to succeed. Downstream's own register already states the risk in one line: this work
*"must be designed with Redox upstream or it becomes an unrebaseable fork"*.

If upstream declines and E-OS implements it anyway:

1. **The fork stops being rebaseable.** A hypervisor touches `context/memory.rs`, the scheme table,
   the interrupt path and, on aarch64, the boot exception level. These are among the most actively
   changed files upstream. Conflicts would be structural and continuous, not occasional — the patch
   set would stop being a patch set and become a divergent kernel.
2. **A security boundary would be maintained by one project and reviewed by nobody else.** This is
   the worst part, and it is worse than not having the boundary. An unreviewed hypervisor still gets
   described as a hypervisor in a feature list, and users would reasonably assume the guarantees of
   the ones that were reviewed.
3. **Upstream fixes would arrive late or not at all**, in exactly the subsystem where late security
   fixes matter most.
4. **The work would be wasted twice** if upstream later implements its own, incompatible interface.

Therefore, if upstream declines, the downstream response is **not** to implement it anyway. It is to:

- keep the interim (TCG emulation) and label it honestly as slow and interim;
- pursue the IOMMU work separately (Q9), which we believe is independently wanted and does not carry
  the same rebase risk;
- state in downstream documentation that VM-based isolation is **not** a property E-OS provides, and
  that its compartmentalisation is kernel-enforced scheme namespaces — which is the sentence
  downstream already commits to in its own threat model.

A decline is a worse outcome for the platform than an acceptance. It is a much better outcome than
an unrebaseable fork, and this document is written by people who would rather be told no than
maintain one.

---

## 11. Measurements

Everything asserted about the current state of the kernel is reproducible against a pinned,
clean checkout. `_probe/remeasure.sh` re-runs every assertion in this section and exits non-zero
if any has changed; `_probe/rig_probe.py` and `_probe/hv_el2_probe.sh` re-run §11.7. Where a claim
could not be measured it is in §12, not here.

### 11.0 Provenance, and the inference that failed

**Measured against pinned upstream clones, both clean:**

```
$ git -C _ref/upstream-kernel rev-parse HEAD
f4d59db53e86ea4b4218905f4053dc1644aa3fa3
$ git -C _ref/upstream-kernel log -1 --format='%ad %s' --date=iso
2026-09-02 13:16:09 +0200 Add additional counter for syscall switches.
$ git -C _ref/upstream-kernel remote -v
origin	https://gitlab.redox-os.org/redox-os/kernel.git (fetch)
$ git -C _ref/upstream-kernel status --porcelain | wc -l
       0
$ git -C _ref/upstream-bootloader rev-parse HEAD
cc922ec0bb3f9dd31cce589bb513ab2f15ac9746
$ git -C _ref/upstream-bootloader remote -v
origin	https://gitlab.redox-os.org/redox-os/bootloader.git (fetch)
```

**Four further trees were added in revision 3**, because two claims in §11.8 and one in §11.5 turned
out to be about repositories this document had never opened. Redox keeps its drivers in
`redox-os/base` and its namespace protocol in `redox-os/libredox`; neither is the kernel, and neither
can be measured by grepping it.

```
$ for r in upstream-base eos-base upstream-syscall upstream-libredox; do
    printf '%-18s %s  dirty=%s\n' "$r" \
      "$(git -C _ref/$r rev-parse HEAD)" \
      "$(git -C _ref/$r status --porcelain | wc -l | tr -d ' ')"; done
upstream-base      2b737f7511652872fd614d18f4020c6827cbaab8  dirty=0
eos-base           816546df2a294f638eecc16eee61407d86c050c9  dirty=0
upstream-syscall   4cc3baafdcbca65660d7ad4c52b7900e1fd32315  dirty=0
upstream-libredox  b2e7c8ba1db3e0effe93fd1ad025879e970e69d5  dirty=0
```

`eos-base` is pinned at the `pinned_rev` downstream `repos.toml` records for it, so the fork
measured here is the one the E-OS image is actually built from, not a snapshot of `main`.

Kernel `Cargo.toml` → `name = "kernel"`, `version = "0.5.12"`. Below, `$KERNEL` is
`_ref/upstream-kernel` and `$BOOT` is `_ref/upstream-bootloader`. The E-OS fork clone
(`_ref/eos-kernel`, `68a510358d134cfeaa188423241e727c3ff1de54`, 2026-08-29, clean) is quoted only
where a fork/upstream difference is the point.

**How output is transcribed.** Command output below is real, not summarised, with two
presentational edits applied consistently and nowhere else: the absolute tree prefix is replaced by
`$KERNEL`/`$BOOT` (or dropped, leaving `src/...`), and in §11.3 the repeated `x86::controlregs::`
qualifier is elided for width. Nothing is reordered, and no printed line is omitted from a quoted
block unless an ellipsis marks the gap.

#### The inference that failed, and why it is written down here

An earlier revision of this section measured the **E-OS fork** and reasoned:

> "None of the findings below concern patched code; all concern *absence*, and the E-OS patch set
> adds no virtualisation code."

That inference is valid in exactly one direction and only under one condition. It reads

> absent in the fork **and** the fork adds no such code ⟹ absent in upstream

which requires **fork = upstream + patches**, i.e. that the fork is rebased onto current upstream.
It was not. The fork's HEAD is dated 2026-08-29; upstream's is 2026-09-02, and the aarch64 PSCI and
`CurrentEL` work landed in between. Measured directly:

```
$ ls -la $KERNEL/src/arch/aarch64/device/psci.rs
-rw-r--r--  1 ...  8367 ... src/arch/aarch64/device/psci.rs

$ ls -la _ref/eos-kernel/src/arch/aarch64/device/psci.rs
ls: src/arch/aarch64/device/psci.rs: No such file or directory

$ grep -n "hvc" _ref/eos-kernel/src/arch/aarch64/stop.rs
8:        asm!("hvc   #0",
17:        asm!("hvc   #0",
28:        asm!("hvc   #0",

$ grep -c "hvc" $KERNEL/src/arch/aarch64/stop.rs
0
```

So **absence in a fork that is behind upstream says nothing about upstream.** The error was
structural, not careless: the sentence looked like a hedge, and hedges are read as caution rather
than as load-bearing logic. Its cost, had this document been sent, would have been telling Redox
maintainers to write code they had already merged.

**Two rules follow, and both are now enforced by `_probe/remeasure.sh`:**

1. A claim about upstream is measured on a **pinned, clean upstream checkout**, and the hash is
   quoted next to the claim. The script refuses to run against an unpinned or dirty tree and exits
   **2** — instrument failure, not a finding — unless `EOS_RFC_ALLOW_UNPINNED=1` is set, in which
   case it prints two warning lines saying the results are not pinned.
2. Fork-versus-upstream differences are reported as differences, never used as evidence about
   upstream in either direction.
3. **Added in revision 3, after the same error recurred with different nouns.** Before pinning a
   tree, establish *which repository the claim is about*. Revision 2 checked a statement about
   `redox-os/base`'s ACPI driver, and a statement about `libredox`'s namespace protocol, by grepping
   `redox-os/kernel` — and reported both as "not reproduced" (§11.5, §11.8). Redox is not one
   repository, so "measured against pinned upstream" is only meaningful once the *right* upstream is
   named. `remeasure.sh` now pins seven trees and asserts each one clean.

**Negative tests for that gate, measured, not asserted:**

```
$ echo "// negative test marker" >> $KERNEL/src/lib.rs
$ bash _probe/remeasure.sh ; echo "exit=$?"
FAIL (instrument): upstream-kernel is HEAD=f4d59db... dirty=1, expected f4d59db... clean
                   (set EOS_RFC_ALLOW_UNPINNED=1 to override)
exit=2

$ EOS_RFC_ALLOW_UNPINNED=1 bash _probe/remeasure.sh ; echo "exit=$?"
WARNING: upstream-kernel is HEAD=f4d59db... dirty=1, expected f4d59db... clean
WARNING: EOS_RFC_ALLOW_UNPINNED=1 -- results below are NOT pinned
  FAIL  rs_file_count            expected 192, measured 193
exit=1
```

The gate distinguishes the two failures the way `ci-integrity.sh` does: **2** means it could not
run, **1** means the tree disagrees with this document.

**Mutation test — the gate goes red, and the right assertion goes red:**

```
$ EOS_RFC_MUTATE=psci_module bash _probe/remeasure.sh
  ok    hvc_in_stop              = 0
  (mutating assertion 'psci_module': expecting '__mutated_present__')
  FAIL  psci_module              expected __mutated_present__, measured present
remeasure: FAIL -- the tree disagrees with RFC 0001 section 11        exit=1

$ EOS_RFC_MUTATE=hvc_in_stop bash _probe/remeasure.sh | grep -E "^  (ok|FAIL)  (psci_module|hvc_in_stop)"
  FAIL  hvc_in_stop              expected __mutated_0__, measured 0    exit=1
```

Each mutation reddens exactly one assertion, and it is the named one. **Revision 3 stopped
spot-checking this and measured it for every assertion.** Looping `EOS_RFC_MUTATE` over all 28 names
from `remeasure.sh --list`: 28 runs, each producing exactly **one** `FAIL` line, each naming the
mutated assertion, each exiting **1**. Two spot checks are consistent with a gate that only reddens
the two assertions anyone tried.

**Clean run:**

```
$ bash _probe/remeasure.sh ; echo "exit=$?"
== pins ==
  ok    upstream_pin             = f4d59db53e86ea4b4218905f4053dc1644aa3fa3
  ok    bootloader_pin           = cc922ec0bb3f9dd31cce589bb513ab2f15ac9746
  ok    fork_pin                 = 68a510358d134cfeaa188423241e727c3ff1de54
  ok    base_pin                 = 2b737f7511652872fd614d18f4020c6827cbaab8
  ok    fork_base_pin            = 816546df2a294f638eecc16eee61407d86c050c9
  ok    syscall_pin              = 4cc3baafdcbca65660d7ad4c52b7900e1fd32315
  ok    libredox_pin             = b2e7c8ba1db3e0effe93fd1ad025879e970e69d5
== 11.1 instrument check ==
  ok    vmx_instrument           = 2
  ok    rs_file_count            = 192
== 11.2 virtualisation tokens (upstream) ==
  ok    vmx_tokens               = 0
  ok    ept_substring            = 1
== 11.3 CR4 ==
  ok    cr4_no_vmxe              = 0
== 11.4 aarch64 ==
  ok    hvc_in_stop              = 0
  ok    psci_module              = present
  ok    psci_conduit_test        = 1
  ok    currentel_in_boot        = 1
  ok    el2_regs_in_boot         = 8
  ok    bootloader_currentel     = 2
== 11.5 IOMMU ==
  ok    iommu_in_kernel          = 0
  ok    dmar_parser_in_base      = present
  ok    dmar_init_commented      = 1
  ok    dmar_init_commented_fork = 1
== 11.6 scheme table ==
  ok    scheme_count             = 11
  ok    scheme_max               = 16
== 11.8 namespace ==
  ok    namespace_fork_anywhere  = 0
  ok    namespace_in_syscall     = 0
  ok    nsdup_in_libredox        = 1
  ok    initnsmgr_in_base        = present

remeasure: PASS -- every RFC 0001 section 11 assertion holds at the pinned revisions
exit=0
```

### 11.1 Instrument check, before any claim of absence

A negative result from an unchecked instrument is not a result. Before reporting that something is
absent, the search is shown finding something known to be present:

```
$ grep -rn "vmx" $KERNEL/src
src/arch/x86_shared/device/cpu.rs:131:        if info.has_vmx() {
src/arch/x86_shared/device/cpu.rs:132:            write!(w, " vmx")?

$ find $KERNEL/src -name '*.rs' | wc -l
     192
```

The search works, over 192 files, and finds the one known reference. Absence results below are
therefore meaningful. (The earlier draft reported 182 files — that was the unpinned fork snapshot.
Neither pinned tree has that count: the fork clone has 188, upstream 192.)

### 11.2 No VMX/SVM/EPT implementation exists

```
$ for t in vmcs VMCS vmcb VMCB vmlaunch vmresume vmrun vmxon svm_ ept_ npt_; do
    echo "$t = $(grep -rniI --include='*.rs' -- "$t" $KERNEL/src | wc -l)"; done
vmcs = 0
VMCS = 0
vmcb = 0
VMCB = 0
vmlaunch = 0
vmresume = 0
vmrun = 0
vmxon = 0
svm_ = 0
ept_ = 1
npt_ = 0
```

The single `ept_` match is a substring, not a hit:

```
$ grep -rniI --include='*.rs' "ept_" $KERNEL/src
src/scheme/user.rs:454:    // TODO: Hypothetical accept_head_leak, accept_tail_leak options might be useful for
```

**Result: zero virtualisation implementation on x86.** The only reference is the CPUID flag printed
at `cpu.rs:131-132`.

Re-run on the **two kernel trees** — upstream `f4d59db` and the E-OS fork `68a5103` — these counts
are identical:

```
$ for T in upstream-kernel eos-kernel; do
    s=0; for t in vmcs VMCS vmcb VMCB vmlaunch vmresume vmrun vmxon svm_ npt_; do
      s=$((s + $(grep -rniI --include='*.rs' -- "$t" _ref/$T/src | wc -l))); done
    echo "$T vmx_tokens=$s ept_=$(grep -rniI --include='*.rs' 'ept_' _ref/$T/src | wc -l | tr -d ' ') rs_files=$(find _ref/$T/src -name '*.rs' | wc -l | tr -d ' ')"; done
upstream-kernel vmx_tokens=0 ept_=1 rs_files=192
eos-kernel vmx_tokens=0 ept_=1 rs_files=188
```

This is the one §11 finding that did **not** move between fork and upstream, and therefore the one
place the fork could legitimately have stood in as a proxy — had anyone checked that it could,
rather than assuming it. (The earlier revision's sentence here named "all three trees" and then
excluded one of them in a parenthesis; there are two kernel trees, and the bootloader is not one of
them.)

### 11.3 VMX is never enabled

```
$ grep -rniI -e "IA32_FEATURE_CONTROL" -e "VMXE" $KERNEL/src/arch/x86_shared $KERNEL/src/arch/x86_64
    (no output)

$ grep -rn "cr4_write" $KERNEL/src/arch/x86_64
src/arch/x86_64/alternative.rs:62:            cr4_write(cr4() | Cr4::CR4_ENABLE_SMAP);
src/arch/x86_64/alternative.rs:75:            cr4_write(
src/arch/x86_64/alternative.rs:88:            cr4_write(
src/arch/x86_64/misc.rs:14:            cr4_write(cr4() | Cr4::CR4_ENABLE_UMIP);
src/arch/x86_64/misc.rs:20:            cr4_write(cr4() | Cr4::CR4_ENABLE_SMEP);
src/arch/x86_64/misc.rs:34:            cr4_write(cr4() | Cr4::CR4_ENABLE_PPMC);
```

Six CR4 writes (UMIP, SMEP, PPMC, SMAP, and at `:75`/`:88` FSGSBASE and OSXSAVE), none of them
`VMXE`; no `IA32_FEATURE_CONTROL` access in either x86 directory. The `vmx` CPUID bit is read for a diagnostic
string and never acted upon. (The earlier draft counted five writes; upstream has a sixth, `PPMC`.)

### 11.4 aarch64: PSCI conduit and exception level — what upstream already has

This subsection replaces an earlier one that reported the opposite, having measured the fork.

**`stop.rs` contains no `hvc`:**

```
$ grep -c "hvc" $KERNEL/src/arch/aarch64/stop.rs
0

$ sed -n '13,19p' $KERNEL/src/arch/aarch64/stop.rs
pub unsafe fn kreset() -> ! {
    println!("kreset");
    match psci::system_reset() {
        Ok(()) => unreachable!(),
        Err(error) => halt_after_failed_psci("SYSTEM_RESET", error),
    }
}
```

**A PSCI module selects the conduit at runtime:**

```
$ ls -la $KERNEL/src/arch/aarch64/device/psci.rs
-rw-r--r--  1 ...  8367 ...

$ grep -n "CONDUIT_HVC\|CONDUIT_SMC\|enum Conduit\|fn from_method\|mod tests" \
      $KERNEL/src/arch/aarch64/device/psci.rs
14:const CONDUIT_HVC: u8 = 1;
15:const CONDUIT_SMC: u8 = 2;
20:enum Conduit {
26:    fn from_method(method: &str) -> Option<Self> {
36:            Self::Hvc => CONDUIT_HVC,
37:            Self::Smc => CONDUIT_SMC,
51:        CONDUIT_HVC => Some(Conduit::Hvc),
52:        CONDUIT_SMC => Some(Conduit::Smc),
269:mod tests {

$ sed -n '272,278p' $KERNEL/src/arch/aarch64/device/psci.rs
    fn accepts_only_standard_dt_conduit_names() {
        assert_eq!(Conduit::from_method("smc"), Some(Conduit::Smc));
        assert_eq!(Conduit::from_method("hvc"), Some(Conduit::Hvc));
        assert_eq!(Conduit::from_method("SMC"), None);
        assert_eq!(Conduit::from_method(""), None);
    }
```

Conduit sources, in order: the device-tree `method` property of an `arm,psci-1.0` / `arm,psci-0.2`
node (`psci.rs:100-128`), then the ACPI FADT ARM boot-architecture flags, `PSCI_COMPLIANT` and
`PSCI_USE_HVC` (`psci.rs:133-179`). `PSCI_VERSION` is invoked and checked for v0.2+ *before* the
conduit is published (`psci.rs:61-93`), so a half-initialised interface cannot be used. `SMC` is
emitted as `.inst 0xd4000003` with the comment that LLVM rejects the mnemonic on a Redox target that
does not advertise EL3 (`psci.rs:248-260`).

**The kernel reads `CurrentEL` and deliberately drops EL2→EL1 for secondary CPUs:**

```
$ grep -n "CurrentEL\|hcr_el2\|cnthctl_el2\|cntvoff_el2\|cptr_el2\|hstr_el2\|mdcr_el2\|elr_el2\|spsr_el2\|eret" \
      $KERNEL/src/arch/aarch64/device/cpu/boot.rs
81:    mrs x12, CurrentEL
103:    msr hcr_el2, x12
104:    mrs x12, cnthctl_el2
106:    msr cnthctl_el2, x12
107:    msr cntvoff_el2, xzr
109:    msr cptr_el2, x12
110:    msr hstr_el2, xzr
111:    msr mdcr_el2, xzr
113:    msr elr_el2, x12
115:    msr spsr_el2, x12
117:    eret

$ sed -n '81,93p' $KERNEL/src/arch/aarch64/device/cpu/boot.rs
    mrs x12, CurrentEL
    cmp x12, #0x8
    b.eq .Lap_from_el2
    cmp x12, #0x4
    b.eq .Lap_at_el1
    mov w14, #{state_bad_entry_el}
    str w14, [x19, #{state}]
    dsb sy
    sev
    b .Lap_park

.Lap_from_el2:
    // PSCI may select EL2 as the first Non-secure Exception level. Initialize
```

An AP entered at neither EL2 nor EL1 is refused with `STATE_BAD_ENTRY_EL`, surfaced by
`start_secondaries()` as `"CPU logical {}: unsupported exception level"` (`boot.rs:553-558`).

**The bootloader does the same for the boot CPU, and disables `HVC` on the way down:**

```
$ grep -n "currentel\|hcr_el2\|spsr_el2\|elr_el2\|eret" $BOOT/src/os/uefi/arch/aarch64.rs
48:        let currentel: u64;
50:            "mrs {0}, currentel", // Read current exception level
51:            out(reg) currentel,
53:        if currentel == (2 << 2) {
104:                "msr hcr_el2, {0}",
110:                "msr spsr_el2, {0}",
117:                "msr elr_el2, {0}",
118:                "eret",
122:        } else if currentel == (1 << 2) {
207:    let currentel: u64;
210:            "mrs {0}, currentel", // Read current exception level
211:            out(reg) currentel,
214:    log::info!("Currently in EL{}", (currentel >> 2) & 3);

$ sed -n '102,106p' $BOOT/src/os/uefi/arch/aarch64.rs
            // Configure execution state of EL1 as aarch64 and disable hypervisor call.
            asm!(
                "msr hcr_el2, {0}",
                in(reg) ((1u64 << 31) | (1u64 << 29)),
            );
```

The comment is the bootloader's own. This is why a hard-coded `hvc #0` in `stop.rs` was a defect
worth fixing upstream, and why an EL2-resident Redox has to reach PSCI by `SMC`.

**The ACPI GTDT EL2 fields exist and are never read:**

```
$ sed -n '14,25p' $KERNEL/src/acpi/gtdt.rs
    pub virtual_el1_timer_gsiv: u32,
    pub virtual_el1_timer_flags: u32,
    pub el2_timer_gsiv: u32,
    pub el2_timer_flags: u32,
    pub cnt_read_base: u64,
    pub platform_timer_count: u32,
    pub platform_timer_offset: u32,
    /*TODO: we don't need these yet, and they cause short tables to fail parsing
    pub virtual_el2_timer_gsiv: u32,
    pub virtual_el2_timer_flags: u32,
    */

$ grep -rn "el2_timer\|virtual_el2" $KERNEL/src
src/acpi/gtdt.rs:16:    pub el2_timer_gsiv: u32,
src/acpi/gtdt.rs:17:    pub el2_timer_flags: u32,
src/acpi/gtdt.rs:22:    pub virtual_el2_timer_gsiv: u32,
src/acpi/gtdt.rs:23:    pub virtual_el2_timer_flags: u32,
```

All four hits are the declarations themselves (two of them inside the comment block); there is no
read site. The timer actually selected is EL1 (`gtdt.rs:45`):
`generic_timer::init_acpi(gtdt.non_secure_el1_timer_gsiv, gtdt.virtual_el1_timer_gsiv)`.

### 11.5 No IOMMU path in the kernel — and a parser in `base` that an earlier revision missed

**This subsection replaces one titled "No IOMMU path anywhere".** The word *anywhere* was
generalised from a single tree, which is the same mistake §11.0 records for aarch64, committed a
second time in the same document. The kernel result below is unchanged and correct. What follows it
is the part that was never measured.

**Kernel: zero, confirmed.**

```
$ grep -rniI -e "dmar" -e "iommu" -e "smmu" $KERNEL --include='*.rs' --include='*.toml' --include='*.md'
    (no output)

$ grep -n "mod dmar" $KERNEL/src/acpi/mod.rs
    (no output)

$ sed -n '19,33p' $KERNEL/src/acpi/mod.rs
#[cfg(target_arch = "aarch64")]
mod gtdt;
pub mod hpet;
pub mod madt;
mod rsdp;
mod rsdt;
mod rxsdt;
pub mod sdt;
#[cfg(any(target_arch = "x86", target_arch = "x86_64", target_arch = "aarch64"))]
pub mod slit;
#[cfg(target_arch = "aarch64")]
mod spcr;
#[cfg(any(target_arch = "x86", target_arch = "x86_64", target_arch = "aarch64"))]
pub mod srat;
mod xsdt;
```

Zero occurrences of any of the three tokens in the entire kernel tree, and no DMAR module is
declared. (Upstream declares `slit` and `srat` that the fork snapshot did not; neither is an IOMMU.)

**`base`: a complete DMAR parser, with its entry point commented out.** The drivers do not live in
the kernel — they live in `redox-os/base` — so a claim about *Redox* had to be measured there too,
and was not. Measured on pinned clean clones, `redox-os/base` `2b737f7511652872fd614d18f4020c6827cbaab8`
(2026-09-02) and the E-OS fork `eos-base` `816546df2a294f638eecc16eee61407d86c050c9`:

```
$ grep -rn "Dmar::init" _ref/upstream-base --include='*.rs'
drivers/acpid/src/acpi.rs:454:        //TODO (hangs on real hardware): Dmar::init(&this);

$ grep -rn "Dmar::init" _ref/eos-base --include='*.rs'
drivers/acpid/src/acpi.rs:461:        //TODO (hangs on real hardware): Dmar::init(&this);

$ wc -l _ref/upstream-base/drivers/acpid/src/acpi/dmar/mod.rs
     529

$ sed -n '450,454p' _ref/upstream-base/drivers/acpid/src/acpi.rs
            this.new_index(&table.signature());
        }

        Fadt::init(&mut this);
        //TODO (hangs on real hardware): Dmar::init(&this);
```

The module is not a stub. It parses DRHD, RMRR, ATSR, RHSA, ANDD and SATC remapping structures with
length checks and named error paths. It is **upstream's own code and upstream's own TODO** — the
fork carries it unmodified apart from a seven-line offset, which is why the disabled state is not an
E-OS divergence.

**What it does when enabled, which is the finding that actually matters:**

```
$ sed -n '73,88p' _ref/upstream-base/drivers/acpid/src/acpi/dmar/mod.rs
        for dmar_entry in dmar.iter() {
            log::debug!("DMAR entry: {:?}", dmar_entry);
            match dmar_entry {
                DmarEntry::Drhd(dmar_drhd) => {
                    let drhd = dmar_drhd.map();

                    log::debug!("VER: {:X}", drhd.version.read());
                    log::debug!("CAP: {:X}", drhd.cap.read());
                    log::debug!("EXT_CAP: {:X}", drhd.ext_cap.read());
                    log::debug!("GCMD: {:X}", drhd.gl_cmd.read());
                    log::debug!("GSTS: {:X}", drhd.gl_sts.read());
                    log::debug!("RT: {:X}", drhd.root_table.read());
                }
                _ => (),
            }
        }
```

Six register **reads** into a debug log. No write to `root_table`, no domain, no device-to-domain
assignment, no `GCMD.TE`. So the correct finding is narrower in scope and stronger in substance than
"no `dmar` anywhere": **Redox can read the table that describes the IOMMU and cannot program it.**
On aarch64 not even that — `smmu` is zero occurrences in every tree measured here.

**Why this was missed, recorded because it is the second instance of one pattern.** The falsifying
file was inside this artefact's own `_ref/` directory the whole time, as `_ref/eos-base-acpi.rs`,
listed in Appendix A of the previous revision as *"a single fork file kept from an earlier reading;
not cited by this revision"*. It contains `pub mod dmar;` at line 27 and the commented `Dmar::init`
at line 461. The reviewer's finding against revision 1 was that the artefact's own directory
contained the evidence that falsified its caveats; revision 2 closed that for `_ref/upstream-kernel`
and left it open for `_ref/eos-base-acpi.rs`. A file listed as "not cited" is not thereby
irrelevant — that judgement had not been measured either.

### 11.6 The global scheme table has room for `hv:`

```
$ sed -n '/pub const ALL_KERNEL_SCHEMES/,/^];/p' $KERNEL/src/scheme/mod.rs
pub const ALL_KERNEL_SCHEMES: &[GlobalSchemes] = &[
    GlobalSchemes::Debug,
    GlobalSchemes::Event,
    GlobalSchemes::Memory,
    GlobalSchemes::Pipe,
    GlobalSchemes::Serio,
    GlobalSchemes::Irq,
    GlobalSchemes::Time,
    GlobalSchemes::Sys,
    GlobalSchemes::Proc,
    GlobalSchemes::Acpi,
    #[cfg(dtb)]
    GlobalSchemes::Dtb,
];

$ grep -n "MAX_GLOBAL_SCHEMES\|KERNEL_SCHEMES_COUNT\|assert!(1 +" $KERNEL/src/scheme/mod.rs
174:static SCHEME_LIST_NEXT_ID: AtomicUsize = AtomicUsize::new(MAX_GLOBAL_SCHEMES);
474:pub const MAX_GLOBAL_SCHEMES: usize = 16;
475:pub const KERNEL_SCHEMES_COUNT: usize = ALL_KERNEL_SCHEMES.len();
477:    assert!(1 + KERNEL_SCHEMES_COUNT < MAX_GLOBAL_SCHEMES);
```

Eleven global kernel schemes (`Dtb` behind `#[cfg(dtb)]`). The compile-time assertion currently
reads `1 + 11 < 16`. Adding `hv:` makes it `1 + 12 < 16` — still true, with three slots to spare.
**Adding this scheme does not require enlarging the table.**

### 11.7 The test rig, measured — and a claim withdrawn

Host: `uname -m` → `arm64`; `machdep.cpu.brand_string` → `Apple M4`; macOS `26.6.1`; QEMU `11.0.2`;
`qemu-system-aarch64 -accel help` → `hvf`, `tcg`.

An earlier draft reported only two lines here — the TCG `vmx` refusal and the HVF `mach-virt`
refusal — and generalised each into a platform-capability claim. Both generalisations were wrong.
Full probe output:

```
$ python3 _probe/rig_probe.py ; echo "exit=$?"
== x86_64 under TCG: which vendor extension is actually offered? ==
  [tcg max ] vmx=False  svm=True  npt=True  nrip-save=False  lm=True
  [tcg EPYC] vmx=False  svm=True  npt=True  nrip-save=True  lm=True
== x86_64 under TCG: which flag does QEMU refuse on the command line? ==
  -cpu max,+vmx         rc=0 vendor-flag-refusals=["qemu-system-x86_64: warning: TCG doesn't support requested feature: CPUID[eax=01h].ECX.vmx [bit 5]"]
  -cpu max,+svm         rc=0 vendor-flag-refusals=none
  -cpu max,+svm,+npt    rc=0 vendor-flag-refusals=none
== aarch64: is the EL2 refusal the host, or QEMU's HVF backend? ==
  accel=hvf virtualization=off: rc=0 stderr=''
  accel=hvf virtualization=on: rc=1 stderr='qemu-system-aarch64: mach-virt: HVF does not support providing Virtualization extensions to the guest CPU'
  accel=tcg virtualization=off: rc=0 stderr=''
  accel=tcg virtualization=on: rc=0 stderr=''
== artefact check: does this QEMU binary use the Hypervisor.framework EL2 API? ==
  Hypervisor.framework imports found: 37 (instrument check: _hv_vm_create present)
  imports mentioning el2: none
exit=0
```

**Withdrawn claim 1 — "x86_64 VMX/SVM: no".** The row was titled VMX/SVM and only VMX was measured.
QEMU's own CPU-model expansion under `-accel tcg` reports `svm=True` **and** `npt=True` for both
`max` and `EPYC`, and QEMU accepts `-cpu max,+svm,+npt` with no warning while refusing `+vmx`. The
expansion is requested with `type: "static"`, which is the accelerator-filtered set, and `max` is by
construction "what this accelerator supports". NPT is the AMD second-stage translation named in §1
and §5.5, so the substrate for §7.1 stages 1–5 exists on this host. §7.0 and §5.5 are corrected.

**Withdrawn claim 2 — "HVF refuses to pass them through, so acceleration is unavailable".** That
attributed QEMU's refusal to the host. Measured directly against the framework:

```
$ bash _probe/hv_el2_probe.sh ; echo "exit=$?"
== real probe ==
  hv_vm_config_get_el2_supported: ret=0x0 el2_supported=1
== mutation: framework call removed ==
  hv_vm_config_get_el2_supported: ret=0x0 el2_supported=0
hv_el2_probe: PASS -- the answer changes when the framework call is removed,
              so the reported el2_supported value is the framework's, not the initialiser's.
exit=0
```

`ret=0x0` is `HV_SUCCESS`; `el2_supported=1` is the host saying it supports guest EL2. The
constraint is therefore QEMU's, and that is confirmed at the artefact level rather than by argument:

```
$ otool -L $(which qemu-system-aarch64) | grep -i hypervisor
	/System/Library/Frameworks/Hypervisor.framework/Versions/A/Hypervisor (compatibility version 1.0.0, current version 259.5.15)

$ nm -u $(which qemu-system-aarch64) | grep -c "_hv_"
      37
$ nm -u $(which qemu-system-aarch64) | grep -c "_hv_vm_config_.*_el2"
       0
$ nm -u $(which qemu-system-aarch64) | grep "_hv_vm_"
_hv_vm_config_create
_hv_vm_config_get_default_ipa_size
_hv_vm_config_get_max_ipa_size
_hv_vm_config_set_ipa_size
_hv_vm_create
_hv_vm_map
_hv_vm_protect
_hv_vm_unmap
```

QEMU 11.0.2 links Hypervisor.framework and imports 37 of its symbols, including `_hv_vm_create`
(the instrument check: a symbol that *must* be there for HVF to work at all). It imports **none** of
the EL2 configuration API. So the correct statement is: *this QEMU has not wired up the host's EL2
support*, not *this host has no EL2 support*.

> **An instrument that had to be discarded, recorded because it produced a confident wrong answer.**
> The first attempt at the check above used `strings -a` on the QEMU binary. It reported zero
> matches for `hv_vm_config_get_el2_supported` — the "right" answer. It also reported **zero
> matches for `hv_vm_create`**, which must be present. Undefined symbols live in the Mach-O import
> table, not in the string section, so `strings` could not have found any of them. Had the
> instrument check been skipped, a true conclusion would have been published on evidence that
> supported nothing. `nm -u` is the correct instrument, and `rig_probe.py` refuses to report the
> EL2 result unless `_hv_vm_create` is found first.

**A second discarded instrument, same section.** `hv_el2.c` is signed with
`com.apple.security.hypervisor`, and the entitlement was initially treated as the thing that made
the probe authoritative. Measured: an **unentitled** build of the same binary returns the same
`ret=0x0 el2_supported=1`. `hv_vm_config_get_el2_supported()` is a capability query that does not
require the entitlement, so the entitlement is not load-bearing for this result. What *is*
load-bearing is the mutation above: removing the framework call flips the answer to `0`, which is
what proves the `1` came from macOS rather than from `bool el2 = false;`.

### 11.8 Divergences found against downstream's own notes

Recorded because the downstream roadmap is cited as a source elsewhere in this document. Downstream
citations are pinned to `ROADMAP.md` at commit `4673d7930` on `main`.

**Two of these rows were themselves wrong in revision 2, and for the same reason twice: a statement
about one repository was checked against a different one.** The kernel is not where Redox keeps its
drivers or its namespace manager, so a downstream sentence about either could never have been
confirmed or refuted by grepping `redox-os/kernel`. Both are now measured where the code lives.

| Downstream statement | Where it is about | What was measured |
|---|---|---|
| "`Dmar::init` is commented out" (`ROADMAP.md:2422`, sourced from `R-F13` at `:1528`, which names `eos-base`, `drivers/acpid/src/acpi.rs:461`) | `redox-os/base` / `eos-base` — **not** the kernel | **Reproduced exactly.** `drivers/acpid/src/acpi.rs:461` in `eos-base` `816546d` and `:454` in upstream `base` `2b737f7`, both reading `//TODO (hangs on real hardware): Dmar::init(&this);`, above a 529-line parser (§11.5). Revision 2 of this document reported "**did not reproduce**" — it had grepped the kernel for a claim the downstream register explicitly locates in `eos-base`, and the file that settles it was sitting in `_ref/`. |
| "`Namespace::fork()` + `NsDup::IssueRegister` — kernel side complete" (`ROADMAP.md:2419`) | `libredox` + a **user-space daemon** in `base` | **The symbol does not exist, and the guess about where it lives was wrong.** `Namespace::fork` is **0 occurrences** across all six pinned trees (both kernels, both `base`s, `redox_syscall`, `libredox`). Revision 2 guessed `redox_syscall` and marked it `[UNVERIFIED]`; `redox_syscall` `4cc3baa` contains the string `namespace` **zero** times. The real location: `NsDup` is `libredox::protocol::NsDup` (`libredox` `b2e7c8b`, `src/lib.rs:1207`), with variants `ForkNs`, `ShrinkPermissions`, `IssueRegister`; they are serviced by `bootstrap/src/initnsmgr.rs` in `base` — **user space**, not the kernel. |
| "ACPI GTDT timer fields" (`ROADMAP.md:1690`) | `redox-os/kernel` | **Reproduced, and the RFC's own paraphrase of it was wrong.** Revision 2 rendered this as *"ACPI GTDT **EL2** timer fields"*, inserting a word the roadmap does not contain, and then graded its own insertion "partly reproduced". The roadmap says only "ACPI GTDT timer fields", which is true. Separately measured: `el2_timer_gsiv`/`el2_timer_flags` are live struct fields, `virtual_el2_timer_gsiv`/`virtual_el2_timer_flags` are **commented out** with the note that they *"cause short tables to fail parsing"*, and none of the four is ever read (§11.4). |

```
$ grep -rniI "Namespace::fork" _ref/{upstream-kernel,eos-kernel,upstream-base,eos-base,upstream-syscall,upstream-libredox} --include='*.rs' | wc -l
       0
$ grep -rniI "namespace" _ref/upstream-syscall --include='*.rs' | wc -l
       0
$ sed -n '1206,1212p' _ref/upstream-libredox/src/lib.rs
    #[repr(usize)]
    pub enum NsDup {
        ForkNs = 0,
        ShrinkPermissions = 1,
        IssueRegister = 2,
    }
    impl NsDup {
$ grep -n "NsDup::" _ref/upstream-base/bootstrap/src/initnsmgr.rs
341:        let Some(kind) = NsDup::try_from_raw(raw_kind) else {
347:            NsDup::ForkNs => {
351:            NsDup::ShrinkPermissions => self.shrink_permissions(
355:            NsDup::IssueRegister => {
```

**Why the second row matters beyond bookkeeping.** §2.2 of this RFC argues that Redox's isolation
primitive is a software boundary enforced by the kernel. The measurement above says something
sharper: the namespace *manager* is an ordinary user-space process, and the kernel's role is the
handle and permission machinery underneath it. That does not weaken §2.2's argument — a user-space
policy daemon is exactly the microkernel shape — but it does mean "kernel side complete" is not the
right description of it, and a hypervisor RFC that leaned on that phrase would be leaning on air.

**The pattern, stated once so it is not repeated a third time.** Revision 1 measured the fork and
inferred upstream. Revision 2 measured the kernel and inferred Redox. Both are the same error with
different nouns: *the tree that was convenient to grep was treated as the tree the claim was about.*
The rule §11.0 already states — measure the thing the claim names — needed extending: **first
establish which repository a claim is even about, then pin that one.**

---

## 12. [UNVERIFIED] register

Everything this document asserts without having measured it. Listed so that no reader has to guess
which sentences carry evidence.

**Three entries were closed by re-measurement and are recorded as closed rather than deleted**, so
that a reader can see the correction happened:

| # | Was | Closed by |
|---|---|---|
| ~~U1~~ | "The revision of the kernel tree measured in §11 — the tree is a snapshot, not a git checkout; no commit hash exists to quote." | **Closed.** Two clean pinned clones already sat in `_ref/`, created before the first draft was written. §11 is now measured against `redox-os/kernel` `f4d59db` and `redox-os/bootloader` `cc922ec`, both quoted, both re-runnable via `_probe/remeasure.sh`. The caveat was never true; it was written without looking in the artefact's own directory. |
| ~~U2~~ | "That upstream `redox-os/kernel` is in the same state — only the E-OS fork was measured." | **Closed, and it was not in the same state.** §11.2's x86 counts are identical on both trees, but §11.4's aarch64 findings are not: upstream has `psci.rs` and `CurrentEL` handling the fork lacks. Closing this cost one command; leaving it open cost §4, §5.6, Q2 and Q3 (§11.0). |
| ~~U9~~ | "That QEMU TCG has no VMX support at all, as opposed to refusing this one CPUID bit." | **Superseded and narrowed.** `query-cpu-model-expansion` under `-accel tcg` reports `vmx=False` for `max` (the accelerator-defined model), which is stronger than the command-line warning. The finding that matters is the *converse*, and it is now measured, not assumed: `svm=True`, `npt=True` (§11.7). |
| ~~U16~~ | *(opened and closed in revision 3.)* "That `Namespace::fork()` / `NsDup::IssueRegister` live in `redox_syscall` rather than the kernel — not investigated, because this RFC does not depend on it." | **Closed, and the guess was wrong.** `redox_syscall` `4cc3baa` contains `namespace` zero times. `NsDup` is `libredox::protocol::NsDup`; the daemon that services it is `base/bootstrap/src/initnsmgr.rs`, in user space (§11.8). Cost to close: two `grep`s. "This RFC does not depend on it" was the reason given for not looking — but the RFC *does* cite the sentence, in §11.8, as a measured divergence. Citing a claim is depending on it. |

Still open:

| # | Statement | Why it is unverified |
|---|---|---|
| U3 | **The venue, format and process for submitting an RFC to Redox.** | Not researched. Whether Redox accepts RFCs as merge requests, forum threads, chat discussion, or not at all, is unknown to this document. This should be settled before sending, and may change the format entirely. |
| U4 | **That `Provider::External` is a workable basis for second-stage mappings.** | Read from `context/memory.rs:1182-1226` and judged plausible. Nothing was built. Design intent offered for review, not a validated approach — question Q5. |
| U5 | **That a scheme is a workable interface for a performance-sensitive exit path.** | No prototype, no measurement. Question Q4. |
| U6 | **Every performance characterisation.** | "Slow by construction" about TCG emulation is an architectural argument, not a benchmark. No figure appears in this document because none was measured. |
| U7 | **That the aarch64 VHE approach (`HCR_EL2.E2H`) is the right EL2 strategy for Redox.** | Named from general knowledge of the architecture. It is now known what it would have to *replace* — the deliberate EL2→EL1 drop in `bootloader/src/os/uefi/arch/aarch64.rs:53-121` and `kernel/src/arch/aarch64/device/cpu/boot.rs:92-117` (§11.4) — but no VHE path has been written or tried. |
| U8 | **That an x86_64 host with VT-x or nested KVM would be a sufficient rig for the Intel half.** | Asserted from the shape of the problem; the project has no such host to test the claim on (§7.0). The AMD half no longer depends on this: it is measured developable here (§11.7). |
| U10 | **The guarantees G1–G7 (§6.2) are achievable as stated.** | Requirements written to be falsifiable, not results. No implementation exists to hold to them. |
| U11 | **That Windows guests need "UEFI + TPM emulation and a licensing answer".** | Inherited from downstream's register, not independently verified. Out of scope either way (§3). |
| U12 | **Sizing, effort and difficulty of every stage in §7.** | No estimate is given anywhere in this document, deliberately. Where a reader infers one, it is not supported. |
| U13 | **That a QEMU newer than 11.0.2 exposes the Hypervisor.framework EL2 API.** | §11.7 measures only that 11.0.2 does not import it. Whether any released QEMU does, and whether `-M virt,virtualization=on -accel hvf` would then work, was not tested. |
| U14 | **That TCG's SVM emulation is complete enough to run stages 1–5 to completion.** | Measured: the feature bits are exposed and accepted (`svm=True`, `npt=True`). *Not* measured: that a guest actually executes `VMRUN` correctly under TCG, because no guest exists to run. This is the next thing to test, and it is cheap. |
| U15 | **That upstream would accept an opt-in EL2-resident boot mode at all.** | §5.6 assumes "default unchanged, EL2-resident opt-in" is an acceptable compatibility contract. That is a guess about upstream's preferences, which is what Q2′ asks. |

---

## 13. Status of this document

**Draft. Not submitted, not posted anywhere.** It was produced as a design artefact for review
inside the E-OS project first, per an explicit decision that the RFC precedes the first line of
implementation.

**Revision 2 (2026-09-03) is a correction, not an extension.** An internal review re-ran the
commands and found that three of this document's load-bearing claims were wrong, all in the same
way: a measurement had been taken and then not read, or taken against the wrong tree. §4, §5.5,
§5.6, §7.0, §11 and Q2/Q3 were rewritten; U1, U2 and U9 were closed; two of the three original
pre-send blockers were closed by material that already existed in this artefact's own directory.
The wrong claims are quoted where they were wrong rather than silently removed, because a reviewer
who read revision 1 needs to know which sentences changed.

**Revision 3 (2026-09-03) is a second correction, of the same error at a different scale.**
Revision 2 fixed "measured the fork, claimed upstream". It did not notice it was also doing
"measured the kernel, claimed Redox". Three findings changed:

| Was | Is |
|---|---|
| §11.8: downstream's "`Dmar::init` is commented out" — **"did not reproduce"** | **Reproduces exactly**, in `redox-os/base` `:454` and `eos-base` `:461`. The downstream register names `eos-base` in the same row; this document grepped the kernel (§11.5, §11.8). |
| §5.7 / §11.5: "no `dmar`, no `iommu`, no `smmu`, **anywhere**" | True of the kernel. False of Redox: a 529-line DMAR parser exists in `base`, disabled by `//TODO (hangs on real hardware)`. The replacement finding is narrower and stronger — Redox can *read* the IOMMU's table and cannot *program* it (§11.5). |
| §11.8: "`Namespace::fork` … presumably lives in `redox_syscall` — **[UNVERIFIED]**" | Wrong guess, closable in two greps. `redox_syscall` never says `namespace`; `NsDup` is in `libredox`, serviced by a **user-space** daemon in `base` (§11.8, U16). |

Three smaller defects in the same pass, all of the document's own stated contract being broken by
the document: §11.3's `grep` output was **reordered** and §11.4's two `grep` blocks each **omitted
printed lines without an ellipsis**, while §11.0 promised neither would happen; and §11.8 quoted the
downstream roadmap as saying "ACPI GTDT **EL2** timer fields" when it says "ACPI GTDT timer fields",
then graded the inserted word. All are corrected against the pinned trees.

Coverage of the gate itself was raised from two spot-checked mutations to **all 28**, and
`hv_el2_probe.sh`'s exit-1 branch was seen red for the first time rather than described (§7.0).
`remeasure.sh` now pins **seven** trees, not three.

Before it goes to upstream, one thing must still happen:

1. **Settle U3** — how Redox actually wants to receive a proposal of this size.

Closed since revision 1:

- ~~Re-measure §11 on a pinned clone of upstream `redox-os/kernel` at a named revision.~~ Done:
  `f4d59db53e86ea4b4218905f4053dc1644aa3fa3`, plus `redox-os/bootloader` `cc922ec0bb3f9dd31cce589bb513ab2f15ac9746`,
  both clean, both asserted by `_probe/remeasure.sh` (§11.0).
- ~~Decide Q2/Q3 internally — lead with x86_64 and acquire a rig, or lead with aarch64.~~ The
  dilemma was an artefact of the measurement error. Q2 is withdrawn (the PSCI-conduit work is
  merged upstream); Q3 is re-opened as a narrower vendor question, and the rig can host the AMD
  half of the x86_64 path today (§7.0, §11.7).

No code should be written against this design until upstream has answered Q1.

---

## Appendix A — files in this artefact

| Path | What it is |
|---|---|
| `0001-hypervisor-in-redox.md` | this document |
| `_probe/remeasure.sh` | re-runs and asserts every §11 measurement against **seven** pinned trees (both kernels, the bootloader, both `base`s, `redox_syscall`, `libredox`) — 28 assertions; exit 1 = a tree disagrees, 2 = instrument could not run; `EOS_RFC_ALLOW_UNPINNED=1` escape, `EOS_RFC_MUTATE=<name>` negative test, `--list` prints the names so the mutation loop can cover all of them |
| `_probe/rig_probe.py` | §11.7 rig measurement: TCG vendor-extension expansion, QEMU aarch64 EL2 refusals, and the Hypervisor.framework import check, each behind an instrument check |
| `_probe/hv_el2_probe.sh` | builds, signs, runs `hv_el2.c` and its mutant; asserts the reported `el2_supported` value changes when the framework call is removed |
| `_probe/hv_el2.c`, `_probe/hv.entitlements`, `_probe/hv_el2` | the Hypervisor.framework EL2 probe, its entitlement, and a signed build |
| `_probe/tcg_flag_probe.py`, `_probe/qmp_probe.py`, `_probe/hvf_el2_probe.py` | the original single-purpose probes, kept because §11.7 quotes their output |
| `_ref/upstream-kernel` | pinned clean clone, `redox-os/kernel` @ `f4d59db53e86ea4b4218905f4053dc1644aa3fa3` |
| `_ref/upstream-bootloader` | pinned clean clone, `redox-os/bootloader` @ `cc922ec0bb3f9dd31cce589bb513ab2f15ac9746` |
| `_ref/eos-kernel` | pinned clean clone, E-OS fork @ `68a510358d134cfeaa188423241e727c3ff1de54`, quoted only for fork/upstream differences |
| `_ref/upstream-base` | pinned clean clone, `redox-os/base` @ `2b737f7511652872fd614d18f4020c6827cbaab8` — where Redox's **drivers** live, and therefore where §11.5's DMAR finding is measured |
| `_ref/eos-base` | pinned clean clone, `eos-base` @ `816546df2a294f638eecc16eee61407d86c050c9` (the `pinned_rev` in downstream `repos.toml`) |
| `_ref/upstream-syscall` | pinned clean clone, `redox-os/syscall` @ `4cc3baafdcbca65660d7ad4c52b7900e1fd32315` — measured to refute revision 2's guess about where the namespace API lives (§11.8) |
| `_ref/upstream-libredox` | pinned clean clone, `redox-os/libredox` @ `b2e7c8ba1db3e0effe93fd1ad025879e970e69d5` — where `NsDup` actually is |
| `_ref/eos-base-acpi.rs` | one fork file kept from an earlier reading. **Revision 2 listed it as "not cited by this revision"; that was the same defect one level down** — it contains `pub mod dmar;` and the commented `Dmar::init`, and it falsified revision 2's §11.8 first row. Superseded by the two pinned `base` clones above, kept only so the correction has a visible subject. |

Revision 1 of this document listed only the `.md` as its output. That omission mattered: `_ref/`
contained the pinned upstream clone whose existence falsified revision 1's two headline
`[UNVERIFIED]` entries, and `_probe/` contained the probe output that falsified its §7.0 ordering
argument. **A file list that omits the evidence is part of the defect, not bookkeeping.**

Revision 3 adds the second half of that lesson: **listing a file is not reading it.** `_ref/eos-base-acpi.rs`
was named in revision 2's own appendix, and dismissed there in the same line — "not cited by this
revision" — while it held the counter-evidence to a row of §11.8. An inventory that records a file
and a judgement about its irrelevance, without measuring the judgement, is a more confident version
of the original omission.
