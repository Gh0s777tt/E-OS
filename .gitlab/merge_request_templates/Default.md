<!--
E-OS merge request.

THIS IS NOT THE DEFINITION OF DONE. The complete list is CLAUDE.md §6, and it has 18 items;
what follows is the SHAPE of a description -- the headings a reviewer expects and the boxes
most changes tick. Measured 2026-09-03: this template carried 8 items while claiming to be
"the Definition of Done from CLAUDE.md", CONTRIBUTING.md carried a different 14, and none of
the three referred to the others. A second copy of a rule is a copy that goes stale, and
three copies is three answers to one question (ROADMAP `RH-011`).

Read CLAUDE.md §6 before ticking anything here. Tick what applies; strike through (~~…~~)
what genuinely does not, and say why.
-->

## What & why

<!-- One paragraph: what this changes and the reason. Link the ROADMAP item / issue. -->

## Verification (CLAUDE.md §5.2 — build, tests, linters, types, scanners, integrity gate)

- [ ] **Compiles** — `cargo check` for the target in the build container
- [ ] **Integrates** — `make CI=1 … all` + `scripts/ci-boot-smoke.sh` PASS (if it touches the image)
- [ ] **Runtime-proven** — evidence attached (serial log / `--selftest` marker / pcap / screendump)

## Definition of Done — the frequently-missed items (the full list is CLAUDE.md §6)

- [ ] **Documented (what + why)** — every new function/script/API/technology; docs updated per the map in CLAUDE.md (README / CHANGELOG / ROADMAP / `docs/` + `SUMMARY.md` / HARDWARE / SECURITY as applicable)
- [ ] **Doc-comments** — `//!`/`///` on new public items; an inline `//` "why" on each non-obvious decision
- [ ] **CHANGELOG** — a `[U-NNN]` entry (what + why + how verified)
- [ ] **Pins & mirrors** — if a fork changed: pushed to **GitLab AND GitHub**, then `repos.toml` + recipe bumped, `scripts/eos-repos.sh pins --strict` green
- [ ] **Conventional Commit(s)**, small and self-contained

<!-- If a code change ships no docs on purpose, put `docs: n/a` in this description
     (the docs-currency CI job honours it). -->
