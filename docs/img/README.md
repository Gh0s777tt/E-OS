---
title: docs/img — web-optimized screenshot copies for the docs site
status: current
last-reviewed: 2026-08-30
owner: Gh0s777tt
---

# docs/img — web-optimized screenshot copies for the docs site

**Canonical screenshots live in [`assets/screenshots/`](../../assets/screenshots)**
(full-resolution, as captured from QEMU). mdBook only ships files under `docs/`,
so the handful of images the documentation embeds are kept here as
**web-optimized copies** (≤1100 px wide, 256-colour quantized PNG — ~20× smaller
than the originals, text still crisp).

When you add or refresh a screenshot in the docs:

1. drop the full-resolution capture into `assets/screenshots/` (canonical),
2. regenerate the optimized copy here (Pillow: resize to 1100 px wide,
   `quantize(colors=256)`, `save(optimize=True)` — see `U-115` for the exact
   recipe),
3. embed it from a docs page and list that page in `docs/SUMMARY.md`.

Do not edit files here by hand — they are derived artifacts.
