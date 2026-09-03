#!/usr/bin/env bash
#
# prepare-mrs.sh — stage the three upstream merge requests for the E-OS fixes.
#
# It clones each upstream repo, creates the MR branch, applies the patches from
# this directory with `git am`, optionally re-authors the commits under your
# name, and adds a remote for your gitlab.redox-os.org fork — leaving you one
# `git push` (and a paste of the matching section from MR-DESCRIPTIONS.md) away
# from an open MR.
#
# Prereqs: fork redox-os/{kernel,base,relibc} on https://gitlab.redox-os.org
# (web UI) and have an SSH key registered there.
#
# Usage:
#   ./prepare-mrs.sh <gitlab-username> [workdir] ["Your Name" you@example.com]
#
# Examples:
#   ./prepare-mrs.sh alice
#   ./prepare-mrs.sh alice ~/redox-mrs "Alice Example" alice@example.com
#
set -euo pipefail

GLUSER="${1:?usage: prepare-mrs.sh <gitlab-username> [workdir] [\"Name\" email]}"
WORKDIR="${2:-./mr-prep}"
AUTHOR_NAME="${3:-}"
AUTHOR_EMAIL="${4:-}"

# Resolve this script's directory (the upstream/ folder with the patches).
UPSTREAM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# repo -> MR branch name
REPOS=(kernel base relibc)
declare -A BRANCH=(
    [kernel]=aarch64-boot-fixes
    [base]=aarch64-pcie-intx
    [relibc]=tls-layout-fixes
)

mkdir -p "$WORKDIR"
WORKDIR="$(cd "$WORKDIR" && pwd)"
echo "Workdir: $WORKDIR"
[ -n "$AUTHOR_NAME" ] && echo "Re-authoring commits as: $AUTHOR_NAME <$AUTHOR_EMAIL>"
echo

for repo in "${REPOS[@]}"; do
    patches=("$UPSTREAM_DIR/$repo"/0*.patch)
    if [ ! -e "${patches[0]}" ]; then
        echo "!! no patches for $repo in $UPSTREAM_DIR/$repo — skipping"; continue
    fi

    echo "==================== $repo ===================="
    # `${var:?}` and not `$var`: an empty $repo would make this `rm -rf "$WORKDIR/"` and
    # take the whole work directory with it. SC2115, found the day the lint scope was
    # widened to cover this file at all (ROADMAP `RH-014`).
    rm -rf "${WORKDIR:?}/${repo:?}"
    git clone --quiet "https://gitlab.redox-os.org/redox-os/$repo.git" "$WORKDIR/$repo"
    cd "$WORKDIR/$repo"

    git checkout -q -b "${BRANCH[$repo]}"
    BASE="$(git rev-parse HEAD)"

    echo "  applying $(ls "$UPSTREAM_DIR/$repo"/0*.patch | wc -l) patch(es)…"
    git am "${patches[@]}"

    if [ -n "$AUTHOR_NAME" ]; then
        git config user.name "$AUTHOR_NAME"
        git config user.email "$AUTHOR_EMAIL"
        git rebase -q "$BASE" --exec 'git commit --amend --reset-author --no-edit'
        echo "  re-authored commits under $AUTHOR_NAME"
    fi

    git remote add fork "git@gitlab.redox-os.org:$GLUSER/$repo.git"
    N="$(git rev-list --count "$BASE"..HEAD)"
    echo "  OK: $N commit(s) on branch '${BRANCH[$repo]}', fork remote added."
    cd "$WORKDIR"
    echo
done

cat <<EOF
==================== next steps ====================
For each repo, push the branch and open the MR:

  (cd "$WORKDIR/kernel"  && git push fork ${BRANCH[kernel]})
  (cd "$WORKDIR/base"    && git push fork ${BRANCH[base]})
  (cd "$WORKDIR/relibc"  && git push fork ${BRANCH[relibc]})

GitLab prints an MR link after each push. Paste the matching section
("MR 1 — kernel", "MR 2 — base", "MR 3 — relibc") from
upstream/MR-DESCRIPTIONS.md as the title + description.

All patches are verified to apply onto current mainline; no rebase needed.
EOF
