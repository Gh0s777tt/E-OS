---
title: Test coverage
status: generated
last-reviewed: written by scripts/eos-coverage-report.sh
owner: Gh0s777tt
---

# Test coverage

**Generated — do not edit by hand.** `scripts/eos-coverage-report.sh` writes this file and
fails when a gated crate falls under its floor; the floors live in `coverage-floors.toml`,
so raising one is an ordinary commit and lowering one is visible in a diff (`CLAUDE.md` §5.10).

The asymmetry is deliberate: the vendored `redox_cookbook` is reported without a threshold,
because gating coverage on a tree we do not maintain is re-litigating code we do not own.

A high number is not proof. Coverage says what was **executed**, never what was **checked** —
the mutation score (`TQ-006`) and the security proxies (`TQ-002`) answer the other half.

| crate | lines | gated | floor | state |
|---|---|---|---|---|
| `tools/eos-repo-sign` | 41.06 % | yes | 38 | ok |
| `.` | 6.26 % | no | 0 | advisory — not gated |

Commit: `49bf88274`
