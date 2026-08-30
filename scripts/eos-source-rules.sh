#!/usr/bin/env bash
# eos-source-rules.sh — make sure every recipe whose source is an E-OS fork is BUILT from
# that source, instead of being downloaded as an upstream prebuilt package.
#
# WHY THIS EXISTS (R-F20, U-163/U-164). Two untracked files decide what actually goes into
# an image, and neither is visible to anyone reading this repository:
#
#   .config         sets REPO_BINARY?=1, which makes cookbook's default rule "binary" --
#                   i.e. fetch <recipe>.pkgar from static.redox-os.org rather than compile.
#   cookbook.lock   carries per-recipe `fsrule = "source"` overrides that opt individual
#                   recipes back into being built. It is generated, and gitignored.
#
# The overrides were added by hand over time, so recipes added later were simply missed.
# The measured consequence: `pkg-lib`'s manifest-signature verification -- R-703's client
# half, which docs/security/index.md calls implemented -- is **not in the image at all**, because
# `pkgutils` was downloaded from upstream. `pins --strict` stayed green throughout: the pin
# was real, its relationship to the artefact was not.
#
# This script derives the list from the tree rather than restating it: any recipe whose
# recipe.toml points at an E-OS fork is E-OS-owned and must be built.
#
# Both hosts are matched deliberately. GitLab is the source of truth (ADR-0001) and recipes now
# fetch from it, but the GitHub mirror URL stayed valid for a long time and may reappear in a
# rebase or an older branch. Matching only one host would silently stop detecting forks the day
# they were repointed -- which is exactly what happened when the recipes moved to GitLab and this
# check went from a verdict to an instrument failure.
#
#   scripts/eos-source-rules.sh              # report what is missing (default)
#   scripts/eos-source-rules.sh --apply      # set fsrule = "source" for them
#
# Run it inside the build container, where cookbook.lock lives.
set -uo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$0")")" || exit 1
APPLY=0; [ "${1:-}" = "--apply" ] && APPLY=1
LOCK="cookbook.lock"

[ -d recipes ] || { echo "source-rules: no recipes/ here — run this in the build tree"; exit 1; }

# Every recipe whose source is an E-OS fork.
owned=$(grep -rlE "gitlab\.com/e-os/eos-|Gh0s777tt/eos-" recipes/*/*/recipe.toml 2>/dev/null \
        | while IFS= read -r f; do basename "$(dirname "$f")"; done | sort -u)
[ -n "$owned" ] || { echo "source-rules: found no E-OS-forked recipes — that is itself wrong"; exit 1; }

missing=""
for r in $owned; do
  # A recipe is covered when the lock names it with a source rule.
  if ! awk -v r="$r" '
        $0 == "[recipes." r "]" { inblk = 1; next }
        /^\[/                   { inblk = 0 }
        inblk && /fsrule[[:space:]]*=[[:space:]]*"source"/ { found = 1 }
        END { exit(found ? 0 : 1) }' "$LOCK" 2>/dev/null; then
    missing="$missing $r"
  fi
done

total=$(echo "$owned" | wc -w | tr -d ' ')
if [ -z "${missing# }" ]; then
  echo "source-rules: OK — all $total E-OS-forked recipes are set to build from source"
  exit 0
fi

echo "source-rules: $(echo "$missing" | wc -w | tr -d ' ') of $total E-OS-forked recipes are NOT pinned to source:"
for r in $missing; do echo "    $r"; done

if [ "$APPLY" = "0" ]; then
  echo "source-rules: re-run with --apply to set them (they are downloaded as upstream binaries until you do)"
  exit 1
fi

# shellcheck disable=SC2086  # deliberate: the recipe list is a whitespace-separated set
./target/release/repo change-rule --set-rule=source $missing \
  || { echo "source-rules: change-rule failed"; exit 1; }
echo "source-rules: applied. Rebuild those recipes for it to take effect."
