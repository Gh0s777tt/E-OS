<!-- E-OS design document — produced 2026-07-13 by the roadmap audit. This is an engineering DESIGN PROPOSAL (maps to the R-8xx series in ROADMAP.md), not a shipped spec. -->

# E-OS Secure Driver Manager — Engineering Design

**Status:** Design proposal (greenfield; no driver-manager source exists today)
**Owner:** E-OS core
**Theme:** crimson `#E50914` on `#0a0a0a`
**Depends on:** update system (`pkg-lib`/`eos-update`), R-503 hybrid signing, R-1003 signed repo host, native Settings shell
**Scope codes:** R-800 … R-814 (this document defines the range)

---

## 0. Design premise and honest framing

The user goal is a "Driver Booster, but trustworthy": one place that detects all hardware, tells the user what is Missing / Outdated / OK, and installs every driver **only** from E-OS's own signed source, so a user never hunts a driver on the open web. That premise is sound and buys a real security win (§4), **but** it can only ever cover hardware for which an E-OS driver *exists*. Today that is **PCI + USB, wired-only**. Wi-Fi, Bluetooth, GPU-accel, sensors, most laptop touchpads (I2C-HID), Type-C PD — the very devices that historically drive users to sketchy driver sites — have **no driver in the substrate**. The Driver Manager must therefore do two honest things at once:

1. **Install** a signed driver where one exists.
2. **Report** "device present, no driver available yet" where one does not — which is itself an anti-scam UX win (the user is told authoritatively that the hardware is unsupported, instead of googling and landing on a malware "driver" page).

Everything below is designed so the **read side** (enumerate → inventory → diff against catalog → present list) is buildable in userspace **now, on aarch64/QEMU**, and the **write side** (per-driver packages + spawn-on-demand + hotplug) is staged behind the kernel/base plumbing it actually needs.

---

## 1. Device enumeration — a unified, machine-readable inventory

### 1.1 What exists today

Enumeration is real but **fragmented across three owners**, none of which produces a persisted, queryable inventory:

| Bus | Enumerator | Interface | IDs produced |
|---|---|---|---|
| PCI | `pcid` (`src/base-drivers/pcid/`) | `/scheme/pci` | `FullDeviceId { vendor, device, class, subclass, interface, revision }` per function |
| USB | `xhcid` (`src/base-drivers/usb/xhcid/`) | own port enumeration; matches `drivers.toml` | class / subclass / protocol / vendor / product |
| Platform (ACPI/DT) | `hwd` (`src/base-drivers/hwd/`) | none — `hwd.probe()` only `log::debug!`s `_HID`/`_CID` and dumps the DT tree | recognizes `PNP0C0A` (Battery), `PNP0C50` (I2C-HID) **by name only**; binds nothing |

Key facts that constrain the design:

- **PCI binding data is already programmatically readable**: `PciFunctionHandle.config().func.full_device_id` yields every ID — exactly what `pcid-spawner` consumes. A GUI/daemon can read the same path.
- **Platform devices are enumerated but never bound** (explicit TODO in `hwd`: *"HWD is meant to locate … devices … and start their drivers"*). So "detect all hardware" today means **PCI + USB only**; platform enumeration exists as debug logging, not as an inventory API.
- **PCI scan is incomplete on real HW**: `pcid` scans bus 0, bus 0x80, and bridge-discovered buses; multi-segment ECAM/MCFG host bridges beyond the first are unhandled (FIXME: *"Use full ACPI for enumerating the host bridges"*). Fine in QEMU, a gap on real machines.
- `acpid` is **not** spawned on the aarch64 DeviceTree path (it starts inside `AcpiBackend::new()`), so an inventory built "in hwd" must not assume ACPI is live on the primary dev arch.

### 1.2 Proposed: `eos-devd` + `/scheme/devices` (R-800)

A new userspace daemon `eos-devd` (crate under `src/base-drivers/`) that **aggregates** the three enumerators into one read-only, machine-readable inventory. It does **not** bind drivers; it observes.

**Backends (read-only adapters):**
- `pci`: connect each function on `/scheme/pci`, read `full_device_id` + BAR/IRQ summary + bound-driver hint.
- `usb`: read `xhcid`'s enumerated port table (add a read-only `xhcid` query op; §5.2).
- `platform`: consume `hwd`'s ACPI `_HID/_CID` and DT `compatible` strings (promote the existing `log::debug!` data into a structured emit).

**Inventory record (stable, versioned schema):**

```toml
# /scheme/devices  — one record per device, TOML/JSON-serializable
[[device]]
uid        = "pci:0000:00:03.0"        # stable per-bus address key
bus        = "pci"                     # pci | usb | platform
vendor     = "0x8086"
device     = "0x100e"
class      = "0x02"                    # network controller
subclass   = "0x00"
interface  = "0x00"
revision   = "0x03"
ids        = ["PCI\\VEN_8086&DEV_100E"] # canonical match strings (see §3.1)
bound      = true
driver     = "e1000d"                  # bound daemon cmd, or null
driver_pkg = "drv-e1000d"              # owning pkgar, or null
state      = "ok"                      # ok | unbound | no-driver | error
```

- `uid` is the **stable identity** for hotplug diffing and for the "device X present, no driver" persisted record (§3.4).
- The inventory is exposed as a scheme (`lsdev`/`lspci`/`lsusb`-style) **and** dumped to `/var/lib/eos-devd/inventory.toml` so the Settings GUI and `eos-update` can read it without holding the daemon open.

**Effort:** userspace-only, buildable and testable **now on aarch64/QEMU** for PCI+USB. Platform-device inventory (`hwd` promotion) is a follow-on because it needs the `hwd.probe()` TODO work.

---

## 2. Driver catalog — a signed ID→package database

### 2.1 What the catalog replaces

Today the "device DB" is **static TOMLs compiled into the image**, scattered across three catalogs and baked into the monolithic `base.pkgar`:

- `/lib/pcid.d/initfs.toml` — boot-critical (aarch64: `nvmed`, `virtio-blkd`, `virtio-gpud`; **`ahcid`/`ided` entries are dead** — binaries absent from the aarch64 initfs).
- `/usr/lib/pcid.d/*.toml` — 10 PCI entries on aarch64 (`ac97d`, `e1000d`, `ihdad`, `ihdgd`, `ixgbed`, `rtl8139d`, `rtl8168d`, `vboxd`, `virtio-netd`, `xhcid`) — **`ac97d.toml` and `vboxd.toml` are dead** (binaries exist nowhere in the tree; a match would `Command::new("/usr/lib/drivers/ac97d")` → fail → device stays unbound).
- `xhcid/drivers.toml` — USB class/subclass/protocol, a second incompatible format (`subclass = -1` wildcards, `$SCHEME/$PORT` args).

"Updating a driver" = replacing the whole core OS package. Dead entries already advertise non-existent drivers. There is no version, no arch tag, no signature on the match data.

### 2.2 Proposed: signed `eos-driver-catalog` pkgar (R-801)

A single, versioned, **repo-served** catalog packaged as its own pkgar and signed with the **R-503 hybrid ed25519 + ML-DSA-65** key — the same trust root as the update system.

```toml
# eos-driver-catalog/catalog.toml
schema        = 1
catalog_version = 20260712          # monotonic; anti-rollback (§4.4)
generated_from  = ["pcid.d", "xhcid/drivers.toml", "initfs.toml"]

[[driver]]
pkg        = "drv-e1000d"
version    = "0.1.0"
arch       = "aarch64"
binary     = "/usr/lib/drivers/e1000d"
provides   = "network"
# match rules — superset of pcid + xhcid formats, one schema (§3.1)
match      = [
  { bus="pci", class="0x02", vendor="0x8086", device=["0x100e","0x10d3","0x153a"] },
]
sha256     = "…"                    # of the drv-e1000d pkgar
supersedes = ["drv-e1000d@<0.1.0"]  # for "Outdated" detection
```

**Generation & validation gate:** the catalog is generated from the shipped `pcid.d/*` + `xhcid/drivers.toml` + `initfs.toml`, so **day-one coverage equals shipped coverage**, and a build-time gate **rejects any catalog entry whose `binary` is not present in the built image** — this kills the current `ac97d`/`vboxd`/dead-`ahcid` class of "advertise a driver that can't bind" bugs by construction.

**Hosting:** published to the R-1003 signed repo (`eos-pkg-<arch>`). The publish path (`scripts/publish-repo-pages.sh`, orphan-commit push to Pages) does **not** require GitHub Actions, so it is operationally unblocked — the genuine blockers are (a) first publish never run, (b) no E-OS-owned off-repo signing key generated, (c) `/etc/pkg.d` not wired. All three are §7 phase-0 items.

### 2.3 Reconciling three catalog formats

The catalog schema is a **superset** that carries a `bus` discriminator (`pci`/`usb`/`platform`) so `pcid` config-struct semantics, `xhcid` class/subclass/protocol wildcards, and future platform `compatible`-string matches all serialize into one signed file. The runtime keeps consuming the native per-bus TOMLs (unchanged binding path); the catalog is the **authoritative superset** the manager diffs against and the generator round-trips to the native TOMLs during a driver package install.

---

## 3. Matching engine — the "Driver Booster" list

### 3.1 Canonical match keys

Normalize every device to canonical ID strings so PCI and USB share one matcher:

```
PCI\VEN_8086&DEV_100E&CC_0200
USB\VID_0BDA&PID_8153&CLASS_02
PLATFORM\compatible=brcm,bcm2835-sdhci     # platform (phase 2)
```

Matching precedence (most→least specific), mirroring `pcid`'s existing `match_function`:
`vendor+device` → `device_id_range`/`ids-map` → `class+subclass+interface` → `class+subclass` → `class`.

### 3.2 Classification

For each inventory record, resolve against the catalog and assign:

| State | Condition | GUI section |
|---|---|---|
| **OK** | bound driver == best catalog match, version current | green |
| **Outdated** | bound driver present but catalog has a newer `version` (via `supersedes`) | amber — "Update" |
| **Missing** | device matches a catalog driver, but nothing is bound | red — "Install" |
| **No driver** | device present, **no catalog entry** (Wi-Fi/BT/GPU/sensor today) | grey — "Unsupported (no driver yet)" |
| **Error** | driver bound but reported failure / not verified on this HW class | orange |

The **"No driver"** row is the honesty feature: it names the hardware (`hwd` already recognizes `PNP0C0A`, `PNP0C50`) and states no signed driver exists — instead of silence that pushes users to web searches.

### 3.3 Untrusted-input hardening (critical — R-802)

The moment the catalog becomes a **downloaded, user-updatable file**, the current matcher becomes an attack surface:

- `DriverConfig.match_function` parses vendor keys with `i64::from_str_radix(..).unwrap()` → **a malformed or hostile catalog entry panics `pcid-spawner` and breaks ALL driver binding at boot** (DoS / bricked binding).

**Required before any catalog is fetched over the network:**
1. Replace every `unwrap()` in the match path with skip-on-error (a bad entry is ignored, not fatal).
2. The catalog loader **verifies the pkgar signature first** (§4), then validates schema, rejects duplicate `uid`/oversized/malformed entries, and enforces `binary`-exists **before** the matcher ever consumes it.
3. Same defensive-arithmetic pass flagged elsewhere in the forks (`checked_add` on offsets) applies to any catalog-driven index math.

### 3.4 Persisted inventory + missing-driver ledger

`eos-devd` writes `/var/lib/eos-devd/inventory.toml` and a `missing.toml` (devices in `no-driver`/`missing` state) so: (a) the Settings GUI renders instantly without a live scan, (b) `eos-update` can surface "a driver is now available for hardware you have," and (c) support/telemetry-free diagnostics are reproducible.

---

## 4. Secure delivery — drivers only from our signed repo

### 4.1 The pipeline (reuses the update system end-to-end)

A driver install is **an update transaction with a device-match trigger**. It reuses `pkg-lib`'s verified path exactly:

```
detect (eos-devd) → match (catalog) → resolve drv-<x> pkgar
   → fetch from signed repo → verify catalog sig (ed25519 + ML-DSA advisory→required)
   → verify drv pkgar (ed25519 header + blake3 per-entry)
   → anti-rollback check → stage → atomic commit → spawn-on-demand (§5)
```

Every layer already exists and is **enforced, not advisory**: `pkgar` `Header::new` runs `sign::verify` and returns `InvalidSignature` before any file is written; each entry is blake3-verified during extraction; install is near-atomic (`.pkgar.*` tempfiles → rename, with abort).

### 4.2 Trust-chain fixes this design mandates (inherited from update-system audit)

The Driver Manager must **not** ship until these are closed, because a driver runs with hardware access:

1. **Pin the E-OS signing pubkey in the image** — today remote keys are **TOFU** (`add_remote` sets `pubkey:None`, fetches `id_ed25519.pub.toml` from the *same host* that serves packages). Bake the key into a config file so a MITM/hostile mirror cannot supply its own key + self-consistent signed driver. Note the current asymmetry: the **installer path pins** a key (`installer_key`), only the **post-install remote path** is unpinned — exactly the path a Driver Manager uses.
2. **Sign and verify the manifest/catalog** — `repo.toml`/per-package tomls remain unauthenticated **client-side**. The publisher half is already wired: `publish-repo-pages.sh` emits `repo.toml.sig` via `tools/eos-repo-sign` (hard-fails unsigned since `U-120`). Still missing: `catalog.toml.sig` for the driver catalog, and fetch+verify in `pkg-lib` — without which the signature that already exists protects nothing on the device.
3. **Enforce `https://`** in `add_remote` (any scheme accepted today).
4. **Anti-rollback** — a validly-signed *older* `drv-*` still verifies today; reject a catalog/driver older than installed via the monotonic `catalog_version`.

### 4.3 Capability guarantee for installed drivers

Every driver, once installed, runs under E-OS's boot-verified hardening: **W⊕X at the syscall boundary, mmap/ld.so ASLR, overflow-checks** (Fala-B / R-306). So even a *legitimately signed but buggy* driver runs in a hardened userspace daemon (Redox drivers are userspace, not kernel modules — a structural safety advantage over Windows/Linux kernel-mode drivers).

### 4.4 Security win — quantified honestly

**Threat removed:** the entire "hunt for a driver online / fake-driver installer / drive-by driver update" class. In the Windows ecosystem this is a top real-world initial-access vector — malicious "driver updater" utilities, SEO/scam-link driver sites, and trojanized `.exe` "drivers" are a documented, high-frequency infection path. By construction, E-OS has **exactly one driver source** (the signed repo), and every driver is **blake3 + ed25519 (+ ML-DSA-65) verified before install** and runs under W⊕X/ASLR. To ship a malicious driver an attacker needs the **off-repo private signing key**, not a convincing website + a user who clicks "Download driver."

**Magnitude of the class removed** (attack-surface elimination, not a measured incident rate):
- **Delivery vector:** eliminated — no user-initiated web download of drivers exists as a supported flow.
- **Payload trust:** eliminated for unsigned/mis-signed artifacts — enforced signature check aborts before write.
- **Privilege model:** reduced blast radius — userspace daemon under W⊕X vs. kernel-mode driver.

**Residual risk the design must still name honestly:** (a) supply-chain compromise of the signing key (mitigated by hybrid PQ + off-repo custody + rotation — note there is **no on-device key-revocation/rotation mechanism yet**, a gap to add); (b) a *signed-but-vulnerable* driver (mitigated by anti-rollback + userspace hardening); (c) the "No driver" categories (Wi-Fi/BT/GPU) where E-OS simply cannot help — the manager must say so rather than imply coverage.

---

## 5. Missing Redox/kernel plumbing (the hard part)

This is where the honest effort lives. The read side is userspace; the write side needs base/`pcid` surgery; hotplug and platform binding need work partly upstream.

### 5.1 Spawn-a-driver post-install without reboot (R-803 — medium, base work)

Today `pcid-spawner` is **one-shot at boot**: a single `/scheme/pci` pass (actually **two** passes — the initfs `initfs.toml` pass that mounts root, then the rootfs `/usr/lib/pcid.d/*` pass). There is **no re-scan / rebind control interface**. A just-installed driver cannot bind until reboot.

**Design:** add a control op to `pcid` (write to a new `/scheme/pci` control node, or a `pcid-spawner --bind <pci-addr> --driver <cmd>` one-shot) that **reuses the existing `PCID_CLIENT_CHANNEL` fd-passing model** to hand the driver its PCI channel live. `eos-update` invokes this after a driver pkgar commits, so install → bind happens without reboot. QEMU-testable on aarch64.

### 5.2 Hotplug / uevent equivalent (R-804 — XL, needs real HW)

There is **no event bus**: nothing emits "device added/removed," PCI hot-add is unhandled, USB classes beyond `xhcid`'s own port polling need a reboot. A Driver-Booster-style *live-reactive* UX (plug a dongle → offer its driver) requires a **uevent/netlink equivalent**.

**Design:** `eos-devd` becomes the event hub — `xhcid` already polls ports (extend it to emit add/remove events to `eos-devd`); `pcid` gains a hot-add notification (real-HW ACPI hotplug). `eos-devd` diffs inventory `uid`s and pushes events to the Settings GUI + `eos-update`. QEMU can exercise USB hot-add (`device_add usb-…`); PCI hotplug realistically needs real hardware.

### 5.3 Platform / ACPI / DeviceTree binding (R-805 — L, real HW)

`hwd.probe()` only logs `_HID/_CID` and DT `compatible`. Implement the existing TODO: a **match-table (same pattern as `pcid.d`)** mapping ACPI `_HID/_CID` and DT `compatible` → driver command, so SoC/laptop peripherals (I2C-HID touchpad, EC, SD/eMMC) can bind. **Blocked upstream** on the absent **I2C bus subsystem** (Redox has none) for the I2C-HID/sensor/Type-C-PD slice — flag this as a hard dependency, not a Driver-Manager deliverable.

### 5.4 Packaging a driver as pkgar (R-806 — L, base recipe restructure)

Today all driver binaries + their `pcid.d` TOMLs ship inside `base.pkgar` via `make install-base`. **Split into per-driver pkgar packages** (`drv-e1000d`, `drv-ihdgd`, …), each carrying: its binary, its match manifest (supported IDs, arch, version, sha), and an install hook that registers its `pcid.d`/`xhcid` TOML fragment. `base` keeps only **boot-critical initfs drivers** (`nvmed`, `virtio-blkd`, `virtio-gpud`, `ps2d`, `vesad`, `ahcid`, `ided`) — those must **never** be hot-managed (they mount root). The package boundary must span **three catalog owners** (`initfs.toml`, `/usr/lib/pcid.d/*`, `xhcid/drivers.toml`) and **two roots** (initfs image vs rootfs) — this is the real fragmentation, not a flat "base.pkgar."

### 5.5 Capability / permission model for drivers (R-807 — M/L)

Redox drivers are userspace daemons that acquire hardware via scheme access (`/scheme/pci` channel, MMIO/IRQ caps handed by `pcid`). Define a **driver capability manifest** in each `drv-*` package declaring what it may touch (PCI class it binds, IRQ, MMIO ranges, which schemes it may register). `pcid`/`eos-devd` enforce that a driver only binds devices matching its declared class and only registers its declared scheme — so a compromised/rogue signed driver cannot silently claim unrelated devices. This is the on-device analog of least privilege and pairs with the W⊕X/ASLR runtime hardening.

---

## 6. GUI — Settings → Drivers

### 6.1 The host problem (blocker)

There is **no Settings/control-panel app on either arch today** — `cosmic-settings` is deferred (aarch64 cannot build it: `fontconfig→host:gperf` redoxer host-toolchain 404), and it is not registered in the x86_64 config either. The flagship "Settings → Drivers" pane **has nowhere to live**.

**Resolution (shared with update-system):** ship a **native E-OS Settings** app on **orbital/orbclient** (no libcosmic/fontconfig/gperf dependency, so it builds on the aarch64 host and dodges the toolchain 404 and the disabled-CI bottleneck). Structure it as a panel host — Update, **Drivers**, Display, Network, Audio, Users, Date&Time. Integration surface already exists: the launcher discovers apps via freedesktop `.desktop` entries (`launcher/src/package.rs`), so the app appears in Start + (once wired) the tray gear.

### 6.2 The Drivers pane

Red/black (`#E50914`/`#0a0a0a`) list, Driver-Booster layout, backed by `eos-devd` inventory + catalog diff:

- **Sections:** Outdated (Update all) · Missing (Install all) · OK · Unsupported (no driver yet) · Error.
- **Per row:** device name + vendor/device IDs, current vs available version, bound driver, one-click **Install / Update** — which calls the **`eos-update` verified pipeline** (§4), never a browser, never an arbitrary URL.
- **Unsupported rows** explicitly say "No E-OS driver exists for this device yet" (the anti-scam message).
- **Progress + result** reuse the update pane's check/download/verify/apply UI; **rollback** entry per driver (A/B, §7 phase 3).
- **Never** offers a "download from web" affordance — the absence is a feature.

---

## 7. Phased plan (R-8xx) with substrate honesty

| Phase | Codes | Deliverable | Where | Effort |
|---|---|---|---|---|
| **0 — Delivery backend** | R-808 | Generate off-repo E-OS signing key; run first `publish-repo-pages.sh`; wire `/etc/pkg.d/50_eos` (guarded so a dead URL degrades gracefully); **pin pubkey in image**; enforce `https://` | either | S–M |
| **1 — Read side** | R-800, R-801, R-802 | `eos-devd` + `/scheme/devices` (PCI+USB inventory); signed `eos-driver-catalog` pkgar seeded from `pcid.d`+`xhcid`; harden matcher (`unwrap`→skip, signed+validated catalog loader, `binary`-exists gate) | **now, aarch64/QEMU** | M |
| **2 — Write side** | R-806, R-803 | Split drivers into per-driver `drv-*` pkgar; `pcid` spawn-on-demand (bind live, no reboot) | mostly QEMU; base recipe work | L + M |
| **3 — GUI + safety** | R-809, R-810, R-807 | Native Settings shell + **Drivers pane**; driver A/B + auto-rollback on post-update boot-fail watchdog; driver capability manifests | either | M–L |
| **4 — Hotplug + platform** | R-804, R-805 | uevent/hotplug bus via `eos-devd`; `hwd` platform-device binding (ACPI `_HID`/DT `compatible` → driver) | **needs real HW** (+ upstream I2C for the touchpad/sensor slice) | XL + L |
| **5 — Real-HW coverage** | R-811…R-814 | Verify present-but-unverified drivers on silicon (`ihdgd`, `bcm2835-sdhcid`, `rtl8168d`, `ixgbed`); multi-segment ECAM scan; key rotation/revocation on-device; delta driver updates | **needs real HW / x86 rig** | M–XL |

**Now-in-QEMU vs needs-real-HW summary:**
- **Buildable & verifiable now on the aarch64/QEMU dev host:** R-800, R-801, R-802, R-806, R-803, R-809, R-810 (PCI+USB paths). This is the entire read side plus the core write side and GUI — the demonstrable "Driver Manager" MVP.
- **Needs the Windows/real-HW rig:** R-804 (PCI hotplug), R-805 (platform binding), R-811–814 (silicon verification, multi-ECAM). These are where "detect *all* hardware" and "live-reactive" honestly live.
- **Blocked outside this project's control:** the Wi-Fi/BT/GPU/sensor **substrate** — the manager will *report* these devices (`no-driver`) but cannot install a driver that does not exist. Never version-promise them.

---

## 8. Effort verdict (how much is kernel work)

- **~60% userspace, buildable now:** enumeration daemon, catalog format + signing integration, matching engine, GUI. No kernel changes. This is the bulk of the *visible* Driver Manager.
- **~25% base/driver-framework work:** per-driver pkgar split, `pcid` spawn-on-demand control op, capability manifests, catalog↔native-TOML round-trip. Base recipe + `pcid`/`xhcid` surgery, not kernel proper.
- **~15% genuinely hard / real-HW / partly upstream:** hotplug event bus, platform-device binding (gated on Redox's absent **I2C bus**), multi-segment ECAM, real-silicon verification. This is where the honest "not soon, not in QEMU" caveats belong.

The Driver Manager is **not** primarily kernel work — Redox's userspace-driver model is the reason. The kernel is already hardened (W⊕X/ASLR/overflow-checks) and needs **no changes** for phases 0–3. The risk is not the kernel; it is (a) the trust-chain fixes (§4.2) that must land before any network-fetched driver, and (b) resisting the temptation to advertise coverage (Wi-Fi/BT/GPU) the substrate cannot deliver.