<!--
E-OS merge request. The checklist is the Definition of Done from CLAUDE.md.
Tick what applies; strike through (~~…~~) what genuinely doesn't and say why.
-->

## What & why

<!-- One paragraph: what this changes and the reason. Link the ROADMAP item / issue. -->

## Verification (the three gates — see CLAUDE.md)

- [ ] **Compiles** — `cargo check` for the target in the build container
- [ ] **Integrates** — `make CI=1 … all` + `scripts/ci-boot-smoke.sh` PASS (if it touches the image)
- [ ] **Runtime-proven** — evidence attached (serial log / `--selftest` marker / pcap / screendump)

## Definition of Done

- [ ] **Documented (what + why)** — every new function/script/API/technology; docs updated per the map in CLAUDE.md (README / CHANGELOG / ROADMAP / `docs/` + `SUMMARY.md` / HARDWARE / SECURITY as applicable)
- [ ] **Doc-comments** — `//!`/`///` on new public items; an inline `//` "why" on each non-obvious decision
- [ ] **CHANGELOG** — a `[U-NNN]` entry (what + why + how verified)
- [ ] **Pins & mirrors** — if a fork changed: pushed to **GitLab AND GitHub**, then `repos.toml` + recipe bumped, `scripts/eos-repos.sh pins --strict` green
- [ ] **Conventional Commit(s)**, small and self-contained

<!-- If a code change ships no docs on purpose, put `docs: n/a` in this description
     (the docs-currency CI job honours it). -->
