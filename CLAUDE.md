# CLAUDE.md — E-OS working agreement & standards

Authoritative "how we work on E-OS" for both Claude Code and humans. It is a
**project contract**: read it before starting, follow it while working, and keep
it in step with reality. E-OS is a hardened downstream of Redox OS (Rust
microkernel; brand "Crimson", red/black `#E50914`).

Source of truth: **GitLab `gitlab.com/e-os/e-os`** (+ the pinned forks/apps).
GitHub `Gh0s777tt/*` is a read-only mirror. See `repos.toml` for the full repo map.

---

## 1. Definition of Done — nothing ships until ALL of these hold

A change (fix, feature, script, refactor, tech choice) is **not done** until:

1. **Compiles** — `cargo check` for the target in the build container.
2. **Integrates** — `make CI=1 … all` succeeds and, if it touches the image,
   `scripts/ci-boot-smoke.sh` PASSes (boot reaches `eos login:`).
3. **Runtime-proven, and negative-controlled** — real evidence, never assumption:
   serial log, `--selftest` marker, pcap, or a screendump. State the proof — and state
   that you saw the check **fail without the fix** and pass with it. A green check you
   have never seen go red is not evidence (§4.1); an identical before/after is not a fix,
   so revert it and say why (§4.4).
4. **Documented** — see §2. Every new function, script, API, and technology is
   documented **what + why**. No exceptions: undocumented = unfinished.
5. **Recorded** — a `CHANGELOG.md` entry (`[U-NNN]`, what + why + how verified),
   Conventional Commit message, small and self-contained.
6. **Pinned & pushed** — if a fork changed: get the commit onto **both hosts
   first**, then bump `repos.toml` + the recipe rev; `scripts/eos-repos.sh pins
   --strict` must be green (recipes fetch the exact rev from the GitHub mirror —
   an unpushed fork means the build silently uses stale code). *How "both hosts"
   happens differs by repo:* the **meta repo** has a GitLab→GitHub push-mirror —
   push **GitLab only** and let it replicate (a manual GitHub push races the
   mirror and fails; see docs/MAINTENANCE.md). The **forks** have no mirror
   configured yet (`eos-setup-mirrors.sh --apply` pending), so they DO need the
   manual push to both. If a pin can't be verified (gates down), record the hold
   in `scripts/pin-allowlist.txt` with a reason + removal condition (U-114) —
   never leave `pins --strict` silently red.

If you must defer any gate, say so explicitly and why — don't imply it's done.

## 2. Documentation is part of the work, not an afterthought

**Rule:** after every completed piece of work, update *every* doc it affects, so a
first-time reader understands *what* it is and *why* it exists. Prefer a single
source of truth + generation over hand-maintained copies (see §6 ideas).

**Documentation map — update the ones a change touches:**

| Doc | Purpose | Update when |
|-----|---------|-------------|
| `README.md` | Public front page: what E-OS is, features, status badges | user-facing feature/status changes (it carries a `SYNC:` header — keep it true) |
| `CHANGELOG.md` | Every change, numbered `U-NNN`, [Keep a Changelog] | **every** change |
| `ROADMAP.md` | Living plan; status keys ✅ 🚧 ⏳ | a roadmap item's status changes |
| `docs/*.md` → mdBook **docs site** | The deep manual (design, build, hardware, security, CI, …) | add/expand the relevant page; **list new pages in `docs/SUMMARY.md`** or mdBook ignores them |
| `docs/design-*.md` | One design doc per non-trivial subsystem: the *why*, the alternatives rejected, the pitfalls | you design or significantly change a subsystem |
| `HARDWARE.md` / `docs/hardware-*` | Device/arch support matrix | driver/arch support changes |
| `SECURITY.md` / `docs/threat-model.md` | Security posture & threat model | a hardening or trust-chain change |
| `repos.toml` | Repo + pin manifest (source of truth for the ecosystem) | any fork/app pin bump |
| per-app `README.md` (`eos-notes`, `eos-guard`, `eos-ui`, forks) | that component's own story | that component changes |

**Quality bar:** headings and a one-line "what is this / why does it exist" at the
top of every doc; explain trade-offs and rejected options (future-you needs the
*why*, not just the *what*); link related docs; keep examples runnable.

**Write the record so someone else can check it.** A sentence a reader cannot verify is
a claim, not documentation. Four rules, each of which this project has learned the hard
way — see §4 for the testing side of the same coin:

1. **Cite the evidence inline.** The command, the number, the `file:line`, the rev.
   "Interrupt storm on the shared line" is an opinion; "`virq 37` at 11 054 068 against
   8 851 on the timer, from `/scheme/sys/irq`" is a record (`U-157`).
2. **Scope the claim to what was measured — no wider.** State the arch, the host, the
   configuration. `U-146` claimed "two INTx lines cannot both work" from an
   initfs-phase measurement and was wrong the moment anyone looked at a later boot
   phase; `U-147` had to narrow it, and `U-148` had to narrow it again.
3. **Say what you did *not* verify**, in the same breath as what you did. An entry that
   only lists successes reads as a completeness claim it cannot support. "x86_64 is
   *expected* to be unaffected — unverified, no x86_64 image has been built on this
   host" is worth more than silence.
4. **Correct in place, and leave the correction visible.** When a document turns out to
   be wrong, fix it *and* record that it was wrong and why — do not quietly rewrite it.
   A reader who once relied on the old sentence needs to know it changed. §10.1 and §8
   both carry their own corrections for exactly this reason.

## 3. Code standards — the comments are documentation too

- **Doc-comments on every public item.** `//!` at the top of each module (what it
  is, why it exists); `///` on public functions/types (what it does, the invariant
  it holds, non-obvious constraints). Describe intent, not a restatement of the code.
- **Inline `//` for non-obvious decisions** — the comment that saves the next
  reader: *why this approach*, *what pitfall it avoids*, *what constraint forced it*.
  E-OS is full of these (e.g. `SQLITE_DISABLE_LFS` because relibc has no LFS64
  aliases; the custom Slint-on-orbital backend because winit can't run on Redox).
  When a choice looks odd, a one-line "why" is mandatory.
- **Match the surrounding code** — naming, idiom, comment density. Run `rustfmt`
  (lefthook + CI `rust-checks` enforce it; clippy is `-D warnings`).
- **Hardening baseline** — the E-OS-owned code builds `overflow-checks = true`
  (eos-kernel, eos-base, eos-relibc and the app crates — see `docs/hardening.md`;
  the ~1900 third-party ports and pure mirrors keep upstream flags); intentional
  wrapping uses `wrapping_*`/`Wrapping`. Daemons **exit gracefully / log**, never
  `.unwrap()` a recoverable error into an abort (the virtio-core lesson, `U-085`).

## 4. Verification discipline — test it, prove the test, audit the claim

Every fix passes three gates before "done", in order — this is the E-OS mantra:

1. **Compile** — `cargo check` in the container against the target sysroot.
2. **Integrate** — `make … all` + `boot-smoke` PASS.
3. **Runtime** — serial / selftest / pcap / screendump proof.

Headless GUI apps ship an `eos-<app> --selftest` that proves the non-visual core
(prints `…-SELFTEST-OK`, asserted from the boot serial via a throwaway init.d
probe — **never commit the probe**). GUI render is proven by screendump.

### 4.1 A test you have not seen fail is not a test

Passing proves nothing on its own — the test may be passing on the old code, on the
wrong tree, or on nothing at all. **Show it failing on the defect, then show it passing
on the fix.** Both halves, every time, and say so in the entry.

This is not theory here. Every one of these shipped green and protected nothing:

- The `gitleaks` pre-commit hook ended in `|| true`, so a planted private key committed
  cleanly (`U-140`).
- The bash-4 gate matched **its own regex literal** and failed on a clean tree (`U-159`).
- The negative control for that same gate was itself invalid: `git grep` only sees
  **tracked** files, so an untracked probe proved nothing until it was `git add -N`'d
  (`U-159`).
- A `cd` without `|| exit` in `ci-integrity.sh` — the gate itself — would have linted
  whatever directory it landed in and reported PASS on the wrong tree (`U-159`).

### 4.2 Prove the instrument before you trust a negative result

"No output" means one of two things: the code did not run, or **you are not measuring
what you think you are measuring**. Rule them apart before concluding anything.

`U-151` concluded that `redoxfs` "cannot be instrumented" after two channels produced
nothing. That was wrong: the `base` recipe copies `redoxfs` into `initfs/bin/`, so
rebuilding `r.redoxfs` alone left the initfs running the **old binary** (§9). The test
that settled it: an unconditional `panic!` at the top of `main()` — the boot still
reached a login prompt, which is impossible if that binary is the one running (`U-153`).
Three attempts were spent measuring a binary that never ran.

**Control your variables, too.** One `R-F18` experiment "passed" because moving a
`-device` to the end of the QEMU command line changed its PCI slot, so it stopped sharing
the interrupt line under test (`U-157`).

### 4.3 Measure; do not infer

Inference is where this project's wrong conclusions have come from, and they were
published three times before being corrected:

- The block point was read off **where the serial log stopped**, rather than from where
  the code signals readiness. `pcid-spawner` was blamed twice and was never involved
  (`U-146`, `U-147`, corrected in `U-148`).
- What settled it was making `init` narrate its own units (`U-150`), then polling the log
  by **wall clock** to find an 84-second gap the in-log timestamps could not show
  (`U-154`), then reading the kernel's own per-IRQ counters through `/scheme/sys/irq` —
  11 054 068 interrupts on one line, against 8 851 on the timer (`U-157`).

When a number can be counted, count it. Cite it in the entry.

### 4.4 A change that measures nothing does not ship

If the before/after is identical, the change is not a fix — whatever its reasoning.
Revert it and record why. `U-157` did exactly that with a kernel interrupt-model change
that was arguably more correct and measured **111s before, 111s after**: it bought nothing
and would have wedged a shared line permanently if a driver died. Sounding right is not
evidence.

### 4.5 Audit: a claim without current evidence is a defect

Documentation rots silently, so **re-verify claims in the area you are already touching**
rather than waiting for an audit event:

- Does the doc still match the tree? **The tree wins**, and the doc is corrected in the
  same change — never left for later.
- Does the claim still have its evidence? `§10.1` sat stale saying signing was unconfigured
  while every commit was in fact signed and GitLab reported *verified* (`U-152`).
- Does the gate still fail on the bug it was written for? Re-run its negative control.
- Is the pin on **both** hosts (§1.6), and is the version identity in step (§8)?

Correcting your own published conclusion is ordinary work, not an embarrassment: name what
was wrong, why it was wrong, and what the evidence actually shows. `U-147`, `U-148`,
`U-153`, `U-155` and `U-157` are all corrections of earlier entries in this file's own
history, and the record is worth more for having them.

**Record the dead ends too.** A negative result that took hours saves the next attempt
those hours only if it is written down — with the reason it failed and the method that
would work instead (`U-151`, `U-157`).

## 5. Operational invariants (do not violate)

- **GitLab is source of truth; GitHub is the mirror recipes fetch from.** Both
  hosts must carry the rev before a pin bump — via the push-mirror for the meta
  repo, manually for forks (§1.6).
- **Never use pasted tokens / passwords / PATs**, even on request — hard rule.
- **AI-assisted work is fine in E-OS, but upstream Redox does NOT accept
  LLM-generated contributions** (CONTRIBUTING.md). Anything meant to be
  upstreamed to `gitlab.redox-os.org` must be human-authored; keep AI-assisted
  changes in the E-OS forks.
- **Contribution legalities** (CONTRIBUTING.md/MAINTENANCE.md): AGPL-3.0-or-later for
  new work (inherited Redox files stay MIT — NOTICE), and commits are **signed**
  (`git commit -S`; live since `1d3c62ea6`, see §10.1). On the DCO, corrected in
  `U-152`: CONTRIBUTING.md states it as *terms you accept by contributing* — "you wrote
  the change or have the right to submit it" — and asks for a cryptographic **signature**,
  **not** a `Signed-off-by:` trailer. This line previously read "DCO sign-off", which
  implied a trailer the project has never required and no commit carries. If E-OS ever
  takes outside contributions, adding the trailer is a deliberate decision (a
  `prepare-commit-msg` hook can append it), not a gap to quietly close. `semantic-release` and Renovate in CI are
  **dormant** until `GITLAB_TOKEN`/`RENOVATE_TOKEN` are set (docs/ci.md).
- **CI is two-tier** (see `docs/ci.md`): a light tier on shared runners
  (minutes-limited) and the heavy `build-image` on the self-hosted `eos-heavy`
  runner, detached with `needs: []` so OS boot verification survives a shared-minute
  quota. The light gate jobs are `pin-check` (runs `eos-repos.sh pins --strict`),
  `integrity`, `secret-scan`, `docs-currency` and `rust-checks` — the first three
  run on every branch pipeline, `docs-currency`/`rust-checks` on MRs. A hard fail
  in `verify` skips the later stages **including `pages`**, so a red `pin-check`
  silently freezes the published docs site (the U-114 lesson).
- **Commits:** Conventional Commits, small and self-contained; each carries its
  `CHANGELOG` entry.

## 6. Ideas to keep raising the bar (documentation, quality, performance)

- **Single-source docs, generated outputs.** ✅ *Largely realized:* the mdBook
  `docs/` is the one canonical site (GitLab Pages `pages` job) and the PDF is
  generated *from it* in CI (`docs-pdf` job → `scripts/docs-pdf.sh`, which
  deliberately rejects the fragile mdbook-PDF plugin in favour of `print.html`
  + headless Chromium). Never hand-maintain parallel copies (they drift — the
  2026-08-14 audit caught `docs/ecosystem.md` hand-copying pin hashes; hashes
  now live only in `repos.toml`). Still open: a generator for the ecosystem
  role tables.
- **Doc-coverage gate.** 🚧 *Partially realized:* `docs-currency` already prints
  a non-blocking advisory when a new `pub` item lands without `///`. Still open:
  make it blocking and add `#![warn(missing_docs)]` to the app crates (that
  crate-level warning is this idea — it doesn't exist yet; §3 covers style,
  not enforcement).
- **An `ARCHITECTURE.md` + per-crate module docs** — ✅ `ARCHITECTURE.md` exists
  at the repo root (layers, repo map, build/ship flow). Still open: link every
  design doc from it and keep per-crate `//!` docs current.
- **Reproducibility:** deterministic image builds + published SBOM (`gen-sbom.py`
  already runs in CI) so any release is auditable and rebuildable.
- **Performance hygiene:** keep incremental build caches warm in the container;
  `cargo check -p <crate>` before a 15-min image rebuild; profile only with evidence.
- **Shared code over copies:** the `eos-ui` crate is the pattern — every new Slint
  app depends on it rather than re-implementing the backend.

## 7. Cadence — what happens on *every* change, not "later"

The Definition of Done (§1) says what must be true. This says **when**: all of it lands
with the change, in the same push. Deferring any of it is how the drift this project
keeps discovering gets created in the first place.

**Before you touch anything — three checks that cost seconds and have each already
saved a wasted hour:**

1. `git log --oneline -10` and `git status`. **Is this already done?** A session was once
   resumed mid-stream and re-implemented an entire entry byte-for-byte because nobody
   looked. The commit list was in front of it the whole time.
2. `git rev-parse HEAD origin/main` — are you where you think you are, and is the remote
   ahead? Never start work on a stale tree.
3. Confirm the finding is real **in the tree**, not in a report. `git show HEAD:<file>` is
   the evidence; a grep you half-read is not, and an agent's summary certainly is not.
   This project has twice "confirmed" a defect that did not exist.

**With the change, in the same commit or the same push:**

| What | Rule |
|---|---|
| **Docs** | Every doc the change touches, per the §2 map. A change that alters behaviour and not its docs is unfinished, not "documented later". |
| **CHANGELOG** | One `[U-NNN]` entry. **Verify the number is free** (`grep -m1 -oE '^- .\[U-[0-9]+\]' CHANGELOG.md`) — a duplicate number has happened. Say what changed, why, and how it was verified. State what you did **not** verify. |
| **ROADMAP** | If the change moves an item, move its marker — and if only part of the item shipped, keep it 🚧 with the remainder spelled out. Never ✅ an item whose gates you did not run. |
| **README** | Only if a user-facing claim changed. The `SYNC:` marker means *"README has been checked against every entry up to here"* — so bump it **only after actually doing that walk**, never as bookkeeping. |
| **Commit** | Conventional Commits, small, self-contained, one concern. Body explains *why* and lists the evidence. |
| **Push** | Meta repo: **GitLab only** — the push-mirror replicates to GitHub, and a manual GitHub push races it. **Branches land on the mirror within seconds; a TAG lands on the mirror's next run — measured ~5 minutes (`U-152`).** Two minutes of silence is not a failed mirror; check `update_status`/`last_error` via `glab api projects/:id/remote_mirrors` before concluding anything. Forks: **both hosts manually** (no mirror configured). Verify the mirror caught up before treating a pin as publishable. |
| **Gates** | `scripts/ci-integrity.sh`, `scripts/eos-repos.sh pins --strict`, and gitleaks locally before pushing; then watch the pipeline actually go green rather than assuming. |

**Continuous verification, not a quarterly event.** Re-run the audit questions whenever
you touch their area: does the doc still match the code, does the claim still have its
evidence, is the pin still on both hosts, does the gate still fail on the bug it was
written for. A test that passes on the old code too proves nothing — write the negative
control and *run it*.

## 8. Releases, tags and numbering — keep them in step

Version identity lives in four places and they must agree: the git **tag**, the README
`SYNC:` marker, the `CHANGELOG` head, and `ROADMAP` status.

- **Tag every release**, annotated and **signed** (`git tag -s`). Contributing already
  encourages commit signing; a release tag is the one object where it matters most,
  because it is what a user verifies before flashing an image.
- A tag is a claim about a tree. If `v0.1.0` names a commit hundreds of commits behind
  `main`, then either cut a new tag or stop calling `main` "v0.1.0" — pick one.
- `scripts/make-release.sh` regenerates `SHA256SUMS` + the CycloneDX SBOM and minisigns
  them; since `U-120` an unsigned publish is a hard failure unless `EOS_ALLOW_UNSIGNED=1`.
  Never publish with that flag to anywhere public.
- **That drift is closed (`U-152`, 2026-08-22).** It read: `v0.1.0` points at
  `b4d2bfab8` (2026-06-07), is unsigned, sits far behind `main` (232 commits by the end),
  while README calls it current. The cause of "unsigned" turned out to be structural —
  `v0.1.0` is a **lightweight** tag and so cannot carry a signature at all (§10.1).
  Resolved by **superseding, not rewriting**: `v0.1.0` stays as a historical marker
  (rewriting a published tag is worse than replacing it), and **`v0.2.0`** — annotated,
  signed, cut at `main` — is now the version README names. `v0.2.0` marks a **development
  milestone, not a published release**: no images are published, and `R-F16` is open (a
  second PCI storage controller stalls the boot on aarch64). Say that plainly wherever the
  version appears.

## 9. Where this actually runs

Build claims are only as good as the host they were made on, so the host is part of the
record.

- **Now — MacBook (Apple M4, `arm64`).** The tree lives on an **external USB SSD
  formatted exFAT**, which has no sparse files, no POSIX permissions and no journal.
  Consequences you will hit: `core.symlinks=false` and `core.filemode=false` in this
  clone, `._*` AppleDouble litter, and VM disk images that **cannot** sit on it directly.
- **Container data is therefore in APFS sparsebundles** on that same disk
  (`/Volumes/Project itp/{Docker,Podman}/`), mounted at `/Volumes/EOS-{Docker,Podman}`.
  `~/.local/share/containers` is a symlink into the podman one. **Mount before use** —
  `~/bin/mount-container-volumes.sh`, also wired to a LaunchAgent at login. A podman
  machine that refuses to start is almost always this.
- **When the sparsebundle detaches mid-session — and it will — the mount script alone is not enough.**
  It happened three times in one session (`U-162`). The reliable recovery, in order: `hdiutil detach
  -force` **every** attachment of the image (`hdiutil info` lists them), re-attach with
  `hdiutil attach -nomount`, `diskutil mount /dev/diskNsM`, then `podman machine stop` **and** `start` —
  the machine goes to a zombie state that reports *already running* while its SSH handshake fails. A
  volume that "failed to mount" or an APFS *container superblock is invalid* is almost always a stale
  attachment, not damage: the caches survived all three times. Never reach for `--wipe-caches`.

- **The caches are the asset.** `eos-work` (tree, `build/`, `prefix/`) and `eos-root`
  (toolchain, `~/.cargo`) are podman **named volumes** — `podman rm` does not touch them.
  With them warm the full gate is ~15 minutes end to end, not hours. `--wipe-caches` is
  the only command that destroys them; `--recreate` is cheap and safe.
- **Rebuilding one recipe is not enough when its binary ships in the initfs.** The `base`
  recipe lists `redoxfs` (and others) as dependencies and copies them into
  `initfs/bin/`, so `make r.redoxfs` leaves the initfs carrying the **old** binary. Any
  instrumentation you add then appears to do nothing, and the natural conclusion —
  *"this component cannot be logged"* — is wrong. It cost three failed attempts in
  `U-151`/`U-153`. Rebuild `r.<recipe>` **and** `r.base`, and verify before trusting a
  negative result:
  `strings recipes/core/base/target/<arch>/build/initfs/bin/<binary> | grep <marker>`.
  The check that settles it outright is an unconditional `panic!` at the top of the
  binary's `main()`: if the boot still succeeds, you are not running what you built.

- **Local `make … all` from the macOS checkout does not work** — podman-macOS virtiofs
  cannot serve cargo/rustc's mmap reads. Build **inside** the container, against the
  volumes. This is the supported path, not a workaround.
- **Only `/bin/bash` 3.2 is present.** Anything using bash 4 syntax (`${x^^}`,
  `declare -A`) breaks here even though it is fine in CI. Write scripts that run on the
  dev host.
- **Soon — desktop machine.** The same external disk moves there. Nothing above changes
  except speed; re-check that the sparsebundles mount and the podman machine starts
  before assuming a failure is a code problem.
- **x86_64 metal is a separate rig** and is where the only untested part of this project
  lives: no boot claim has ever been made on real hardware. `make … live` + `dd` to a
  USB stick is the on-ramp (`docs/install.md`).

## 10. Signatures, dangerous code, secrets

Three guarantees a security-focused OS cannot hand-wave. Each has a rule, a gate, and —
where the gate does not exist yet — an honest statement of that.

### 10.1 Signatures — verify, and sign by default

**Rule.** Commits are signed; release tags are signed **without exception** (`git tag -s`).
A tag is what a user checks before flashing an image, so an unsigned tag is a broken
promise, not a style lapse.

**Current state, re-measured 2026-08-22 (`U-152`) — commit signing is LIVE.** An earlier
version of this section said the opposite (all config unset, 0 keys, 0/20 signed). That
was true when written and is no longer; it sat here stale, which is exactly the drift
this file exists to prevent. Measured:

```
gpg.format = ssh                        user.signingkey = ~/.ssh/magazyn-wms-signing.pub
commit.gpgsign = true                   tag.gpgsign     = true
gpg.ssh.allowedSignersFile              = ~/.ssh/allowed_signers
git log --format='%h %G?'               → every commit since 1d3c62ea6 is G (good)
GitLab commit signature API             → verification_status: verified
```

The key is registered on GitLab as *"Ghost Empire / E-Bot — podpisy commitów"*, so the
platform shows **Verified**. Two things about it are worth knowing rather than guessing:

- **The file is named `magazyn-wms-signing`** — another project's key, reused here. It
  verifies correctly and its GitLab title is sensible, so this is a naming wart, not a
  defect. Revisit if E-OS ever has more than one committer.
- **GitHub is unconfirmed.** The `gh` token lacks the `admin:ssh_signing_key` scope, so
  the mirror's key list cannot be read from here. If the key is not registered there as a
  *signing* key (distinct from an *authentication* key), mirrored commits show
  *Unverified* on GitHub. Grant the scope with
  `gh auth refresh -h github.com -s admin:ssh_signing_key` and check.

**Generating a key remains a human action and is deliberately not automated** — a signing
key must never pass through tooling that logs.

**Tags are the part that was actually broken, and the reason was structural.** Both
pre-existing tags (`v0.1.0`, `eos-base-2026-06-06`) are **lightweight** — `git cat-file -t`
reports `commit`, not `tag` — so they carry no annotation and **cannot hold a signature at
all**; no amount of `-s` would have helped. `v0.2.0` (`U-152`) is the first annotated,
signed tag. Cut every future one with `git tag -s -m …`, never `git tag <name>`.

**Verify, don't assume** — `git log --show-signature -1`, `git tag -v <tag>`,
`git cat-file -t <tag>` (must print `tag`, not `commit`), and
`git log --format='%h %G?' -20` (`G` good, `N` none, `B` bad). An unsigned or lightweight
release tag is a release blocker.

### 10.2 Dangerous code must argue for itself

**Rule.** Every `unsafe` block carries a `// SAFETY:` note directly above it stating the
**invariant that makes it sound** — not what the code does, but why it cannot be
unsound. "Calls libc" is not a SAFETY note; "fd is owned and open for the lifetime of
this call, and openpty writes both out-params before returning 0" is.

**Gated** in `scripts/ci-integrity.sh` (check 4), which fails the build on an `unsafe`
without a SAFETY note within the three preceding lines. Introduced while E-OS-owned Rust
had **zero** `unsafe`, precisely so it can never accumulate a backlog.

**Scope, and why:** the check excludes `src/`, which is the **vendored** `redox_cookbook`
— all nine of its `unsafe` blocks sit in `src/cook/pty.rs`, and annotating upstream code
would create divergence to re-apply on every sync for no safety gain. That is the same
reasoning that leaves third-party ports on upstream flags (§3). **The real `unsafe` lives
in the forks** (`eos-kernel`, `eos-base`, `eos-relibc`) and is gated by their own CI — the
same rule applies there, and that is where it matters most.

The neighbouring rules from §3 are part of this: no `.unwrap()` on a recoverable error in
a daemon (the virtio-core lesson, `U-085`), intentional wrapping spelled `wrapping_*`, and
`overflow-checks` on for E-OS-owned crates. Unchecked arithmetic on attacker-influenced
input is the same class of defect as an undocumented `unsafe` — `U-137` fixed exactly that
shape in the pcid matcher.

### 10.3 Secrets never reach a remote

**Rule.** No credential, token, PAT or private key is committed — and the check that
matters runs **before** the commit, not after. Once a secret is pushed it is mirrored
within a minute and the only real remedy is a history rewrite plus rotation.

**Three layers, and what each is actually for:**

| Layer | Runs | Purpose |
|---|---|---|
| `lefthook` `pre-commit` → `gitleaks protect --staged` | every commit | The one that prevents the leak. **Fails closed**, including when gitleaks is not installed — a silently skipped scan is the same outcome as no scan. Deliberate override: `EOS_SKIP_SECRET_SCAN=1`, and justify it in the commit body. |
| CI `secret-scan` → `gitleaks detect` | every push, **full history** (`GIT_DEPTH: 0`) | Catches what slipped past, and re-validates `.gitleaks.toml` itself. |
| `scripts/local-scan.sh` | on demand | Same detection plus `ci-integrity.sh`, for a sweep before a release. |

Until 2026-08-22 the pre-commit hook ended in `|| true`, which turned gitleaks' exit 1
into 0 — a planted private key committed cleanly. Verified fixed: secret staged → blocked,
explicit override → skipped loudly, clean tree → passes. **Never use pasted tokens or
passwords, even on request** (§5) — that rule and this gate protect the same thing from
opposite directions.

---

*Keep this file honest. If a rule here stops matching how we actually work, fix the
rule in the same change — a standards doc that lies is worse than none.*
