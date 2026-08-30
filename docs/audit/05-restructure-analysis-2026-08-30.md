---
title: Pre-restructure analysis
status: awaiting decisions
last-reviewed: 2026-08-30
owner: Gh0s777tt
---

# Pre-restructure analysis

**Nothing has been moved, renamed or deleted.** This document exists because the restructure was
gated on the documentation PRs being reviewed, and they have not been. It delivers the parts of that
brief that are decisions for the owner rather than actions for me: the deletion list, the
large-binary question, the duplication report, and the cross-repository consistency measurement.

**Precondition status:** merge request [`!1`](https://gitlab.com/e-os/e-os/-/merge_requests/1)
(`docs: rebuild project documentation`) is open and **not yet reviewed**. It is the first merge
request in this project's history. The restructure starts after it is reviewed, not before.

---

## 1. Large binaries in git history — measurement and options

The brief says: report the problem, the size cost, and the options, and let the owner decide. Here
they are, measured rather than estimated.

### What is actually in the history

Objects larger than 1 MB across **all refs**:

| Size | Path | Still tracked in HEAD |
|---|---|---|
| 8.3 MB | `recipes/wip/a11y/espeak-ng/espeak-ng-data/ru_dict` | no — history only |
| 2.1 MB | `recipes/smith/root/bin/smith` | no — history only |
| 2.0 MB | `docker/demo.gif` | no — history only |
| 1.6 MB | `assets/screenshots/eos-cosmic-desktop.png` | **yes** — a legitimate asset |
| 1.5 MB | `recipes/wip/a11y/espeak-ng/espeak-ng-data/cmn_dict` | no — history only |
| 1.2 MB | `recipes/sdl2_gears/test.wav` | no — history only |

**Total: 16.7 MB in six objects. 15.1 MB of that is dead weight — reachable only from history.**

Packed history is **39.5 MB**, so the dead binaries are about **38 % of the pack** in relative terms
and **15 MB** in absolute terms.

### The much larger number is not what it looks like

`.git` measures **503 MB** with `du`. That is not history bloat. Measured:

| Quantity | Value |
|---|---|
| Pack file | 46 MB |
| Loose objects, real bytes | 46.4 MB in 223 files |
| Loose objects, space consumed | **457 MB** |
| exFAT allocation block size on this volume | **1 048 576 B (1 MB)** |
| Example: a 7 787-byte object | occupies **1 024 KB** — 134× waste |

A plain `git gc` would pack those 223 loose objects and reclaim roughly **406 MB**. No history
rewrite is involved and nothing is lost.

**This matters for the restructure specifically.** Hundreds of `git mv` operations create hundreds of
new loose objects, each burning a full 1 MB cluster. A restructure performed on this volume without a
`git gc` afterwards would inflate `.git` by several hundred megabytes for no reason.

### Options for the 15.1 MB of dead binaries

| Option | Effect | Cost | Risk |
|---|---|---|---|
| **Leave it** ✅ *recommended* | history stays intact, every clone and every published hash keeps working | 15 MB, permanently | none |
| `git gc --aggressive` | reclaims ~406 MB of exFAT cluster waste; **does not** remove the binaries | minutes | none — no history change |
| `git-filter-repo` | removes the 5 dead blobs; **rewrites every commit hash** | invalidates all clones and the mirror; breaks the three `archive/*` branches and any published reference | high |
| BFG Repo-Cleaner | same as above, simpler interface | same | high |

**Recommendation: leave the binaries, run `git gc`.** Rewriting published history to reclaim 15 MB is
a bad trade at any size, and here the number that looks alarming (503 MB) is a filesystem artefact
that `git gc` fixes without touching a single commit.

> One related item that is not history rewriting and is worth doing: `.git/objects` currently
> contains **90 AppleDouble `._*` files** that git reports as `warning: garbage found`. They are
> created by exFAT on every git operation. `git gc` does not remove them; a `find … -delete` does,
> and it is safe — they are not git objects.

---

## 2. Deletion list — final recommendations

Carried forward from phases 0 and 1, re-checked against the current state. **Nothing here has been
acted on.** Items marked *uncertain* go to `archive/` in a separate commit rather than being deleted,
per the brief.

| # | Target | Recommendation | Justification | Risk |
|---|---|---|---|---|
| D-1 | local branch `docs/honesty-pass-u124-u128` | **delete** | fully merged into `main` — `git rev-list --left-right --count main...branch` → `100 0`; no remote counterpart | none, content is in `main` |
| D-2 | 90 `._*` files in `.git/objects` | **delete** | AppleDouble artefacts of exFAT; git itself reports them as garbage | none, not git objects |
| D-3 | 899 `._*` and 6 `.DS_Store` in the working tree | **delete** | ignored, but they pollute every `find` and search | none, not tracked |
| D-4 | 23 stale branches across 13 forks | **delete** | inherited upstream feature branches, oldest from 2016; 5 of the 28 are already merged | low — they also exist upstream and can be re-fetched |
| D-5 | `ROADMAP-v2.md` | **archive** | content merged into the rebuilt `ROADMAP.md`; keeping two roadmaps is what produced the divergence the audit found | low — it is in git history regardless |
| D-6 | `docs/architecture.md` | **archive** after merging any unique content into `ARCHITECTURE.md` | duplicate scope, mutually cross-linked, no stated entry point | low |
| D-7 | `EOS_BUILD_STATE.md` | **archive** | a checkpoint record from 2026-06-06, superseded by `docs/audit/` | low |
| D-8 | `docs/plan.md`, `docs/plan-do-sprzetu.md`, `docs/roadmap-connectivity.md`, `docs/reality-ledger.md` | **review before deciding** — *uncertain* | overlap with the rebuilt roadmap, but may hold hardware detail that is not recorded elsewhere | medium — read them first |
| D-9 | `cookbook.lock` entries for `eos-guard` and `eos-sysmon` | **remove the two entries** | they declare `fsrule = "source"` for packages that no longer ship; functions consolidated into `eos-control` | low |
| D-10 | `recipes/wip/` (2 932 tracked files, 5.8 GB on disk) | **do NOT delete** | inherited upstream work-in-progress ports; deleting is a product decision, not housekeeping | high |
| D-11 | `config/i586`, `config/riscv64gc` | **do NOT delete** | 20 and 22 references respectively in `build.sh`, `mk/config.mk`, `.cargo/config.toml`; deleting the directories would leave dangling references | high |
| D-12 | junk inside type-B mirrors (~48 MB of disk images, fonts, a compiled ELF) | **do NOT delete** | verified present upstream with HTTP 200; `CLAUDE.md` §12 forbids hand-editing mirrors, and cleaning would create divergence to re-apply at every sync | high |

**Junk patterns have already been added to `.gitignore`** in the documentation PR (commit
`f95b088a8`), covering `._*`, `.DS_Store`, `Thumbs.db`, editor swap files, and a secrets block —
verified not to hide any currently tracked file.

---

## 3. Cross-repository consistency — measured

Every file fetched from every repository's default branch via the GitLab API and hashed.

| File | Present in | Distinct variants | Verdict |
|---|---|---|---|
| `README.md` | **30 / 30** | 30 | present everywhere; ten fork READMEs are the same boilerplate card with the name swapped, and **15 state a pinned revision that no longer matches `repos.toml`** |
| `LICENSE` | 25 / 30 | 17 | **correct** — see below |
| `.gitignore` | 27 / 30 | 17 | inconsistent; the brief asks for one shared file |
| `.gitlab-ci.yml` | 22 / 30 | 22 | each unique; job names differ, so no two pipelines are comparable |
| `CONTRIBUTING.md` | 3 / 30 | 3 | |
| `CHANGELOG.md` | 2 / 30 | 2 | |
| `.editorconfig` | **2 / 30** | 2 | the file itself says *"Keep this identical across all eos-* repos"* and it exists in two |

### Licensing is coherent — my first reading was wrong

Seventeen variants of `LICENSE` looked like a defect. It is not. Classified by actual licence text:

| Licence | Repos | Assessment |
|---|---|---|
| **AGPL-3.0** | 6 — `E-OS`, `eos-control`, `eos-guard`, `eos-notes`, `eos-sysmon`, `eos-ui` | exactly the six type-A E-OS-authored repositories. Correct. |
| **MIT** | 19 — every fork and mirror | each preserves the **original upstream copyright line** (`Jeremy Soller`, `Redox OS`, `The Redox developers`, with their own year ranges). Preserving that notice is an MIT obligation, so the variation is the licence working as intended, not drift. |
| **absent** | 5 — `eos-extrautils`, `eos-netdb`, `eos-orbutils`, `eos-pkg-aarch64`, `eos-pkg-x86_64` | see below |

The five missing files are **not** something E-OS dropped. Verified against upstream:
`redox-os/extrautils`, `redox-os/netdb` and `redox-os/orbutils` all return **HTTP 404** for
`LICENSE` — the gap is inherited. `eos-pkg-*` are artefact repositories (type D) holding published
packages, not code.

**This still needs a decision**, because we redistribute those three publicly under our own
namespace and an unlicensed repository is, strictly, all-rights-reserved. The cheap fix is a
`NOTICE` in each stating that the content is Redox OS under MIT and pointing at the upstream
project, rather than inventing a `LICENSE` file upstream never wrote.

### What "visibly consistent" would require

| Item | Now | Blocker |
|---|---|---|
| `.editorconfig` in every repo | 2 / 30 | **type-B mirrors** — see §5 |
| One shared `.gitignore` base | 17 variants | same |
| Same CI job names | 22 distinct pipelines | none for type A/C; type B blocked |
| Same document set | README everywhere, the rest sparse | same |
| One version scheme | `E-OS` uses SemVer tags; forks carry upstream tags | forks should not be versioned by us at all |
| One release process | only `E-OS` releases | correct as-is |

---

## 4. Duplication and a de-duplication plan

**Not executed.** The brief says to report and propose, not to act.

### Real duplication found

| # | What | Where | Size | Proposal |
|---|---|---|---|---|
| P-1 | **Fork README boilerplate** — the same card, name swapped, and 15 of them state a stale pinned revision | 10+ fork repos | small | **generate** them from `repos.toml` with a script, so the pinned revision can never go stale again. This also fixes the 15 false statements found in the audit |
| P-2 | **`eos-ui` consumed at two different revisions** — `eos-control` and `eos-sysmon` pin `9fb3f3e4a`; `eos-guard` and `eos-notes` pin `c53180d40` | 4 type-A repos | — | pin `eos-ui` in `repos.toml` like every other component and have the four applications take the pinned revision. Today the image can carry two copies of the "shared" backend |
| P-3 | **Shared lint configuration exists but is not shared** — `rustfmt.toml` and `clippy.toml` say "one config, not 24" and live in one repo | 1 of 30 | tiny | publish them from `E-OS` and have each repo reference them, or accept that they apply only here and stop claiming otherwise in the file header |
| P-4 | **`usr/share/ui/LICENSE` in `eos-orbdata` is byte-identical to that repo's root `LICENSE`** | 1 repo | 1 065 B | upstream's own duplication — **leave it**, it is a type-B mirror |
| P-5 | **Three architecture documents** (`ARCHITECTURE.md`, `docs/architecture.md`, `docs/architecture/README.md`) | main repo | — | already addressed: the rebuilt `ARCHITECTURE.md` supersedes them; `docs/architecture.md` is on the archive list (D-6) |

### Not duplication, despite appearances

- **19 MIT `LICENSE` files** — each carries a different upstream copyright holder. Consolidating them
  would strip attribution and breach the licence. **Leave.**
- **`src/` vendored `redox_cookbook`** — this is upstream code carried deliberately (`ADR-0003`), not
  copied from a sibling repository.
- **The 30 distinct `.gitlab-ci.yml` files** — a mirror's pipeline legitimately differs from an
  application's. What should be shared is the **job naming**, not the file.

### Proposed order, if approved

1. **P-2 first** — it is the only item with a runtime consequence: two copies of a shared library in
   one image.
2. **P-1 next** — it removes 15 publicly false statements and prevents their return.
3. **P-3** — cheap, and it stops a file from claiming something untrue about itself.
4. P-4, P-5 need no action beyond what is already planned.

---

## 5. The constraint that shapes this whole phase

The target structure asks for `CHANGELOG.md`, `ROADMAP.md`, `ARCHITECTURE.md`, `CLAUDE.md`,
`CODE_OF_CONDUCT.md`, `SECURITY.md`, `CONTRIBUTING.md`, `.editorconfig`, `tests/`, `examples/` and
`packaging/` **in every repository**.

`scripts/eos-mirror-drift.sh:29` defines what a type-B mirror may contain:

```
README*|*/README*|LICENSE*|*/LICENSE*|COPYING*|.gitlab-ci.yml|.github/*|.gitignore) return 0 ;;
```

**Anything else reclassifies the repository as type C** and the check exits non-zero. That gate is
run by `ci-integrity.sh` check 6 and by the scheduled `mirror-drift` job.

Applying the target structure to the ten type-B mirrors would therefore break the project's own
invariant in ten places at once, and `CLAUDE.md` §12 forbids hand-editing them for a reason that is
still valid: divergence has to be re-applied at **every** upstream sync, and nobody sees it until it
hurts.

### Three ways forward — a decision is needed before any file moves

| Option | What it means | Cost | My assessment |
|---|---|---|---|
| **A. Extend the allowlist** | add the documentation set to `eos-mirror-drift.sh:29`, in its own commit with justification | one line plus a test | **recommended.** The rule's own comment says the allowlist is "obudowa forka, nie kod" — wrapper, not code. Documentation is wrapper by that definition. It does require a code change, which the documentation phase deliberately avoided |
| **B. Reduced set for type B** | mirrors get only `README`, `LICENSE`, `.gitignore`, `.github/` | none | honest and safe, but the repositories will not be "visibly consistent", which the brief explicitly asks for |
| **C. Reclassify the mirrors as type C** | accept that they carry E-OS content | high | wrong. It would remove the distinction that stops unaudited code hiding in a repository described as a mirror |

Type **A** and type **C** repositories (18 of 30) have no such constraint and can take the full
structure whenever the documentation PR is reviewed.

---

## 6. What happens after approval

In order, one PR per repository, `refactor: restructure repository layout`:

1. `git gc` first — otherwise every `git mv` burns a 1 MB exFAT cluster per object.
2. Main repo: `docs/` into the eight-directory tree, `tests/` split into `unit/`, `integration/`,
   `e2e/`, `examples/` created with **runnable** examples, `packaging/` for the image recipes.
3. All moves with `git mv`; every broken path, link and CI reference fixed and **verified by building
   and booting**, with real output in the PR.
4. Type-A repos next, then type C.
5. Type B only after the §5 decision.

Each PR carries a before/after tree and the build + boot-smoke output, as the brief requires.
