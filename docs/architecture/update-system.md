---
title: E-OS In-OS Update System — Engineering Design
status: current
last-reviewed: 2026-08-30
owner: Gh0s777tt
---

<!-- E-OS design document — produced 2026-07-13 by the roadmap audit. This is an engineering DESIGN PROPOSAL (maps to the R-7xx series in ROADMAP.md), not a shipped spec. -->

# E-OS In-OS Update System — Engineering Design

**Status:** Design proposal (greenfield UI/daemon over an existing verified package substrate)
**Scope:** `Settings → Update` end-to-end: check → resolve → download → verify → stage → apply → rollback, from inside a booted E-OS.
**Substrate that already exists (source-backed):** `pkg` CLI + `pkg-lib` (eos-pkgutils), pkgar ed25519 verification enforced pre-apply (`pkgar-core` `Header::new` → `sign::verify`), blake3 content addressing, near-atomic `Transaction` (`.pkgar.*` tempfile → rename), signed pkgar repo produced every build (`repo.toml` + per-package `.pkgar`), non-Actions publisher `scripts/publish-repo-pages.sh`, hybrid ed25519+ML-DSA-65 build-host signer `tools/eos-repo-sign` (R-503).

**Honest framing before any design:** the cryptographic *primitive* (per-package ed25519) is real and enforced; the *trust chain around it* is not. Today the manifest/per-package `*.toml` are unauthenticated client-side, the signing pubkey is fetched TOFU from the same host that serves packages (`repo_manager.rs` `add_remote` sets `pubkey:None`, syncs lazily), there is no anti-rollback, and — the correction the recon missed — the shipped image already points `/etc/pkg.d/50_redox` at `https://static.redox-os.org/pkg` (upstream Redox), so a fresh box updates from the *wrong* source against an *unpinned* key. The update system is therefore not "add a GUI over a working updater"; it is "close the trust chain, add a delivery backend E-OS actually owns, then build the daemon and pane." This design orders the work accordingly.

---

## 1. Architecture — Components & Placement

Three cooperating layers. The lower two are mandatory for security; the GUI is the visible deliverable.

### 1.1 `pkg-lib` (existing, hardened) — the verified transaction core
Location: `src/eos-pkgutils/` (crate behind the `pkg` binary). Already does: multi-remote config from `/etc/pkg.d`, per-remote key sync, HTTPS+curl-fallback download, blake3 compare (installed vs manifest), pkgar open with signature enforcement, near-atomic commit.

**Changes required here (not new components):**
- `verify_manifest()` — fetch `repo.toml.sig`, verify against a **pinned** key before any `repo.toml`/`*.toml` value is trusted (§3).
- `pinned trust root` — load key from image path, stop TOFU (`add_remote` must not `pubkey:None` for the official remote).
- `anti_rollback()` — reject a manifest whose monotonic `index`/`timestamp` is older than the last-applied value persisted locally.
- Pin downloaded package blake3 to the manifest blake3 *before* open (currently open-then-verify; also assert the served hash equals the signed-manifest hash).
- Fix `pkgar-core` `PackageBuf::read_at` truncation panic (confirmed regression, `package.rs`) so a truncated-but-validly-signed-header package errors instead of panicking.

### 1.2 `eos-updated` (new) — the update daemon/service
Location: new crate `src/eos-updated/`, packaged into base initfs services; service file `config/…/services/40_eos-updated.service` (numbered after netstack `10_*`/`25_raid1d`). Runs as a privileged system service (needs write to root + bootloader flag file).

Responsibilities — a persisted state machine, not a UI:

```
Idle ──check──▶ Checking ──(manifest verified, diff computed)──▶ Available
Available ──download──▶ Downloading ──(all pkgs blake3+sig ok)──▶ Staged
Staged ──apply──▶ Applying ──(commit journal)──▶ Applied ──▶ (reboot? if base/kernel)
Applying ──(crash/fail)──▶ Recovering ──▶ RolledBack
```

- Exposes a control/query scheme `/scheme/eos-update` (same pattern as `/scheme/netcfg`): readable nodes `status`, `available`, `history`, `progress`; writable command nodes `check`, `download`, `apply`, `rollback`, `schedule`. This is the API both the CLI and GUI talk to — neither re-implements verification.
- Owns the **journal** (`/var/lib/eos-update/journal.toml`) and **staging area** (`/var/lib/eos-update/staged/`).
- Owns the scheduler timer (periodic `check`) and emits desktop notifications via the notifications daemon proposed in the desktop-maturity track (until that exists, notifications degrade to a `status` node the tray/GUI polls).
- Never bypasses `pkg-lib`; it orchestrates it and adds staging/journal/rollback/scheduling that `pkg-lib`'s in-process `Transaction` cannot survive a power loss to provide.

### 1.3 `eos-update` (new, thin) — CLI wrapper
Location: `src/eos-updated/` (same crate, second binary) or a small `eos-update` bin. A thin front-end over `/scheme/eos-update` for headless/offline/scripted use and for the `no-GUI` server image. Subcommands mirror the state machine: `eos-update check|list|apply|rollback|history|schedule`. Distinct from `pkg update` (which stays as the low-level package tool); `eos-update` is the *system* updater with staging+rollback semantics.

### 1.4 `Settings → Update` GUI pane (new) — the visible deliverable
**Critical placement blocker (from desktop-maturity audit):** there is **no Settings/control-panel app on either arch** today — `cosmic-settings` is deferred (aarch64 `host:gperf` 404; not registered in x86_64 `eos.toml` either). The Update pane has nowhere to live. Therefore the pane depends on the proposed **native orbital-based "E-OS Settings" host** (orbital/orbclient, no libcosmic/fontconfig/gperf dependency so it builds on the aarch64 dev host and dodges the CI bottleneck). The Update pane is one panel inside that host, registered via a `.desktop` entry (the launcher already discovers apps through freedesktop entries — `launcher/src/package.rs from_desktop_entry`).

Built red-on-black (#E50914 / #0a0a0a). Talks only to `/scheme/eos-update`. No verification logic in the GUI.

---

## 2. Repo / Channel Model, Metadata, "What Changed"

### 2.1 Channels
Reuse the already-live branch structure (`origin/lts/0.1` exists, independent of Actions):
- **`stable`** — current release line (`0.1.x` "Genesis").
- **`lts`** — long-term (`lts/0.1`), security backports only.
- (future) **`edge`** — build-tip, opt-in.

A channel maps to a repo base URL. `/etc/pkg.d/50_eos` selects the channel by URL; the GUI channel selector rewrites that file (an admin/"Change account settings"-class action → confirm in-pane).

### 2.2 Metadata — reuse `repo.toml`, add a signed envelope
Keep the existing `repo.toml` (name→blake3, `build_id`) and per-package `{name}.toml` that `pkg-lib` already consumes. **Do not invent a new format.** Add exactly three things alongside it:
- `repo.toml.sig` — detached hybrid signature (ed25519 + ML-DSA-65) produced by `tools/eos-repo-sign` (R-503), covering the manifest bytes.
- A monotonic **`index`** integer and **`timestamp`** inside the signed manifest → freshness/anti-rollback anchor.
- A `channel` field and an `eos_version` field so the client can refuse cross-channel or downgrade manifests.

### 2.3 Computing "what changed"
Already implemented and correct in principle: `pkg-lib` compares **installed blake3** (from the local package-state DB, `package_state.rs`) against **manifest blake3** and selects only changed packages (`pkg update` reinstalls only diffs). The daemon wraps this to produce a human diff for the pane:
- `Package | installed-ver | available-ver | size | category(base/kernel/app/driver) | reboot-required?`
- `reboot-required` is true if the changed set intersects the **protected/base set** (`kernel`, `base`, `base-initfs`, `relibc`, …) — those take the staged apply-on-reboot path (§4).
- Changelog text: fetch an optional signed `CHANGES.md` per build_id from the repo for the "what's new" panel.

**Blocking correctness fix before this ships:** because installed E-OS blake3 hashes differ from upstream Redox's for same-named packages, pointing at `static.redox-os.org` makes the diff flag *nearly everything* as changed and pull upstream builds over E-OS ones. The channel URL **must** be an E-OS-owned repo (§6) or the diff is both wrong and a supply-chain downgrade.

---

## 3. Trust Model — verify BEFORE apply, chained to R-503

Ordering of checks on every update (all must pass or the transaction never touches the live FS):

1. **Pinned root key.** Ship the E-OS signing **public** key(s) baked into the image (e.g. `/etc/eos/keys/eos-repo.pub.toml`, referenced by `/etc/pkg.d/50_eos`). Stop the TOFU download of the signing key over the package channel for the official remote (`repo_manager.rs add_remote`/`sync_keys_internal` must load the pinned key, not fetch `{url}/id_ed25519.pub.toml`). This closes the #1 root-of-trust flaw the verifier flagged (unpinned TOFU key), which is *above* the unsigned-manifest issue in severity because it undermines even the per-package check on first contact.
2. **Manifest signature.** `verify_manifest()`: fetch `repo.toml.sig`, verify hybrid signature against the pinned key. **ed25519 enforced now; ML-DSA-65 advisory→required per R-503 stage plan.** Reject on failure — nothing downstream is trusted until this passes. This closes the unauthenticated-manifest rollback/freeze hole.
3. **Freshness / anti-rollback.** Reject if manifest `index` < last-applied index (persisted in the journal) or `timestamp` older than installed. Blocks a validly-signed *older* manifest/package (the current downgrade-attack gap).
4. **Per-package signature + hash pin.** Existing enforced pkgar ed25519 (`Header::new` → `sign::verify`, embedded-pubkey match) **plus** a new pre-open assertion that the downloaded package blake3 equals the signed-manifest blake3 (binds package↔manifest).
5. **Per-entry blake3** during extraction (already enforced, `entry_reader.verify()`).
6. **Path-traversal guard** on every entry (already enforced, `check_path`).

Only after 1–6 does staging (§4) begin. Apply is gated on the full chain; a failure at any step aborts with a typed error (fix the `repo.pubkey.unwrap()` panic → typed error, so a missing key is a clean failure not a DoS).

**Key custody.** Private signing keys live **off-repo** on the build/publish rig, encrypted at rest (libsodium secretbox + argon2 passphrase, mode 0600 — the custody model `tools/eos-repo-sign` already uses). Public keys pinned in-image. No private key ever in the tree or logs (CLAUDE.md security). Add an on-device **keyring with rotation/revocation** hook (currently absent — single embedded key, no rotation path) so the R-503 PQ migration can rotate keys without a reinstall.

**Audit.** Every apply/rollback writes an audit record (who/when/from-index→to-index/package set) to the journal, consistent with the project's "each sensitive read/write audited" posture.

---

## 4. Atomicity & Rollback

The hard constraint: `pkg-lib`'s `Transaction::commit` mutates the live FS via a pop-loop of per-file renames with **no persisted journal** and its restart state is purely in-memory (evaporates on power loss — exactly the case that matters on real disks). So atomicity must be added *around* it by `eos-updated`, tiered by what Redox/RedoxFS can actually do today.

### 4.1 What the substrate offers (honest)
- **RedoxFS**: no mature snapshot/subvolume primitive to rely on for CoW rollback today → cannot promise btrfs-style snapshots yet.
- **raid1d** (R-501, real): userspace RAID-1 mirror, degraded boot verified. Usable as a *poor-man's A/B* substrate but not designed as an update rollback mechanism; not a general answer.
- **A/B slots**: no bootloader slot-switching today → must be built.

Therefore: **generational file-level staging + journal now (QEMU-doable); A/B or snapshot later (needs bootloader work / RedoxFS features).**

### 4.2 Tier 1 — App/userspace packages (doable now, QEMU-verifiable)
1. **Staged download+verify**: all packages downloaded and fully verified (§3) into `/var/lib/eos-update/staged/` before any live mutation. A dead URL or failed verify aborts with zero live-FS change.
2. **Snapshot-of-replaced-files**: before commit, copy the exact files a package will overwrite into `/var/lib/eos-update/rollback/<index>/` and record the package-state DB delta.
3. **Journaled commit**: write a `journal.toml` "intent" record (packages, files, from/to index) *fsync'd* before the rename loop; mark each file done; write "committed" at the end. On next boot `eos-updated` reads the journal: incomplete → **resume or revert** using the rollback copies. This gives crash-consistency the in-memory `Transaction` cannot.
4. **`eos-update rollback`**: restore the saved files + package-state delta, decrement applied-index. One generation back guaranteed; keep N generations by config.

### 4.3 Tier 2 — Base/kernel/relibc (apply-on-reboot + boot fallback)
Live in-place replacement of a running kernel/relibc is unsafe. Instead:
1. Stage kernel/base/relibc into a **pending slot** (`/var/lib/eos-update/pending/`).
2. Set a **bootloader flag** (`/boot/eos-update-pending`) — the E-OS from-source bootloader reads it and applies+verifies the pending set on next boot, *before* pivoting to the new system.
3. **Boot-fail watchdog**: a monotonic boot-attempt counter; if the new kernel fails to reach a "healthy" checkpoint N times, the bootloader auto-reverts to the previous kernel/base (keep the prior kernel image). This is the safety net that prevents a bad kernel update from bricking a real install.
4. This is the honest ceiling for now: it is **not** verifiable end-to-end on the Apple-Silicon QEMU host for the GUI-driven flow (serial-input/GUI-automation limits), and the bootloader-revert path needs the x86/real-HW rig to prove. Mark accordingly in the reality ledger.

### 4.4 Tier 3 — True A/B root or RedoxFS snapshots (later, real-HW)
Full A/B root slots (two RedoxFS roots, bootloader toggles active slot, update writes inactive slot, one-reboot rollback) or snapshot-backed updates. Needs bootloader slot support + RedoxFS snapshot primitive — neither exists today; explicitly deferred, not promised.

---

## 5. UX — Settings → Update Pane

Lives in the native E-OS Settings host (§1.4). Red-on-black.

- **Check**: "Check for updates" button + auto-check status ("Up to date · last checked 10 min ago" / "3 updates available"). Reads `/scheme/eos-update/status`.
- **Available list**: per-package rows (name, old→new version, size, category badge, "restart required" tag for base/kernel). "What's new" changelog panel from signed `CHANGES.md`.
- **Download / Apply**: staged model made visible — Download (verify) then Apply as distinct steps so the user sees "verified, ready to apply." Progress bar from `/scheme/eos-update/progress`. Base/kernel updates show an explicit "will apply on next restart" affordance.
- **History & rollback**: list of applied generations (index, date, package set) with a "Roll back to previous" action → calls `rollback`. This is the in-OS revert the current abort()-only path cannot provide.
- **Scheduling**: Off / Check daily / Check weekly; "download automatically" and "apply security updates automatically" toggles (default: notify-only, consistent with a cautious daily-driver). Writes the daemon timer config.
- **Notifications**: "Updates available" desktop notification via the notifications daemon; until that ships, the tray gear/indicator (once the tray is made functional — desktop-maturity "now" item) surfaces a badge polled from `status`.
- **Offline / degraded**: a dead or unreachable repo degrades gracefully — pane shows "Could not reach update server" (no crash, no partial state), because verify/stage happen before any live mutation. Fully offline images (server profile) use `eos-update` CLI against a local-file remote.
- **Channel selector**: stable / lts, gated behind a confirm (rewrites `/etc/pkg.d/50_eos`).

---

## 6. Non-Actions Publish Path (delivery backend)

The update system has **no backend until this exists**, and the recon's "just write the UI" framing understates it: GitHub Actions is disabled account-wide, so R-1003 (pkgar publish to Pages) and tag-signing are dead. A working `check` needs a reachable, signed repo.

**Path (all local, no Actions):**
1. **Build** produces the pkgar repo (already happens: `repo.toml` + `.pkgar` per arch).
2. **Sign locally**: ✅ **DONE** — `scripts/publish-repo-pages.sh` calls `tools/eos-repo-sign` and emits `repo.toml.sig` (hybrid ed25519+ML-DSA-65), and since `U-120` a missing signing key is a hard failure instead of a silent unsigned publish. The R-503 "security theater as shipped" gap has therefore moved entirely to the *other* side of the wire: the manifest signature still authenticates nothing at runtime, because no key is pinned (step 3, `R-702`) and no client verifies it (`R-703`).
3. **Generate the off-repo E-OS signing key** (does not exist yet) with encrypted-at-rest custody; pin its public half into the image.
4. **Publish**: the existing `publish-repo-pages.sh` force-pushes an orphan commit of `pkg/<target>/` + `repo.toml` + `repo.toml.sig` + `id_ed25519.pub.toml` to `eos-pkg-<arch>` Pages **and/or a GitLab Pages / GitLab release** (GitLab CI is a viable non-Actions runner; the "GitLab mirror" is currently fiction — single `origin` remote — so this also makes the mirror claim real). Static hosting itself needs no Actions.
5. **Wire the client**: ship `/etc/pkg.d/50_eos` (guarded so a dead URL degrades gracefully) pointing at the E-OS channel URL, and **remove/repoint** the default `/etc/pkg.d/50_redox` so a fresh install stops trusting/updating from upstream Redox.
6. **Run the first publish** — never been done; until it runs, `check` has nothing to talk to.

`SHA256SUMS` for release images must be regenerated over the *actual* retained artifact and minisigned locally (`make release` target), fixing the phantom-checksum problem so out-of-band downloads verify too.

---

## 7. Phased Delivery Plan (R-7xx)

Mapping to the update-system code range. Each phase tagged with where it's provable. "QEMU-now" = aarch64 on the dev Mac; "x86/real-HW" = separate rig.

| Phase | Code | Deliverable | Depends on | Provable |
|---|---|---|---|---|
| **P0 — Backend & trust root** | **R-701** | Local signed-publish: wire `eos-repo-sign` into `publish-repo-pages.sh` (emit `repo.toml.sig`), generate off-repo E-OS key, pin pubkey in image, run first publish to Pages/GitLab, ship guarded `/etc/pkg.d/50_eos`, repoint away from upstream Redox. | §6 | QEMU-now (client fetch); publish on any host |
| **P0 — Manifest verify** | **R-702** | `pkg-lib` `verify_manifest()` (ed25519 enforced, ML-DSA advisory), stop TOFU for official remote, anti-rollback (index/timestamp), package↔manifest hash pin, fix `read_at` truncation panic + `pubkey.unwrap()`→typed error. | R-701 | QEMU-now (unit + e2e with mismatched/old/tampered manifest) |
| **P1 — Daemon core** | **R-703** | `eos-updated` service + `/scheme/eos-update`, journaled Tier-1 staging & commit, `eos-update` CLI (check/list/apply/rollback/history). | R-702 | QEMU-now (app-package update + power-loss journal-resume in QEMU) |
| **P1 — Rollback (Tier 1)** | **R-704** | Snapshot-of-replaced-files + generational rollback + audit log. | R-703 | QEMU-now |
| **P2 — Settings host + pane** | **R-705** | Native orbital E-OS Settings app (host) **+** Update pane (check/download/apply/history/schedule), notifications, tray badge. | R-703; Settings host (desktop track) | QEMU-now for render; GUI-driven apply limited on Mac-QEMU → screenshot-verify + x86 rig for full drive |
| **P2 — Scheduling/offline** | **R-706** | Timer-based auto-check, notify/download/auto-apply policies, offline/degraded handling, channel selector. | R-705 | QEMU-now |
| **P3 — Base/kernel apply-on-reboot** | **R-707** | Pending-slot staging for kernel/base/relibc, bootloader `eos-update-pending` flag, boot-fail watchdog auto-revert. | R-703; from-source bootloader | **x86/real-HW** (bootloader revert unprovable in Mac-QEMU GUI loop) |
| **P4 — A/B / snapshots / deltas** | **R-708** | A/B root slots or RedoxFS-snapshot-backed updates; delta/differential package fetch. | R-707; RedoxFS snapshot or bootloader slots | **real-HW**, deferred |

**Reality-ledger tags to carry (so "done" can't drift):** R-701/702/703/704/706 are QEMU-now and should be boot-verified on aarch64 before any "done." R-705 GUI *apply* is single-substrate-limited (render verifiable on aarch64; full GUI-driven apply needs the x86 rig — same GUI-automation ceiling that blocks installer verification). R-707/708 are real-HW and must never be marked ✅ from QEMU alone.

**What is genuinely doable in QEMU now vs not:** the entire trust chain (P0–P1) and Tier-1 staged/rollback updates are fully exercisable on the aarch64 dev host — this is the high-value, honest near-term slice. The base/kernel apply-on-reboot safety net and any A/B/snapshot work are gated on the from-source bootloader and real hardware and must be scheduled on the x86/real-HW rig. The one non-negotiable prerequisite before *any* of it is meaningful: run the first signed publish and repoint the client off upstream Redox — without that, `Settings → Update` has no authenticated backend to talk to.