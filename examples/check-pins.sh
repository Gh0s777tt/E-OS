#!/usr/bin/env bash
# Every fork revision pinned in repos.toml must match the head of its published
# branch. Drift here means the build and the manifest disagree about what ships.
set -euo pipefail
echo "== checking every pinned revision against its published branch head =="
bash scripts/eos-repos.sh pins --strict
