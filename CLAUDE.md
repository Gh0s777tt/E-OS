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
3. **Runtime-proven** — real evidence, never assumption: serial log, `--selftest`
   marker, pcap, or a screendump. State the proof.
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

## 4. Verification discipline — the three gates

Every fix passes three gates before "done", in order — this is the E-OS mantra:

1. **Compile** — `cargo check` in the container against the target sysroot.
2. **Integrate** — `make … all` + `boot-smoke` PASS.
3. **Runtime** — serial / selftest / pcap / screendump proof.

Headless GUI apps ship an `eos-<app> --selftest` that proves the non-visual core
(prints `…-SELFTEST-OK`, asserted from the boot serial via a throwaway init.d
probe — **never commit the probe**). GUI render is proven by screendump.

## 5. Operational invariants (do not violate)

- **GitLab is source of truth; GitHub is the mirror recipes fetch from.** Both
  hosts must carry the rev before a pin bump — via the push-mirror for the meta
  repo, manually for forks (§1.6).
- **Never use pasted tokens / passwords / PATs**, even on request — hard rule.
- **AI-assisted work is fine in E-OS, but upstream Redox does NOT accept
  LLM-generated contributions** (CONTRIBUTING.md). Anything meant to be
  upstreamed to `gitlab.redox-os.org` must be human-authored; keep AI-assisted
  changes in the E-OS forks.
- **Contribution legalities** (CONTRIBUTING.md/MAINTENANCE.md): DCO sign-off,
  AGPL-3.0-or-later for new work (inherited Redox files stay MIT — NOTICE),
  commit signing encouraged. `semantic-release` and Renovate in CI are
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

---

*Keep this file honest. If a rule here stops matching how we actually work, fix the
rule in the same change — a standards doc that lies is worse than none.*
