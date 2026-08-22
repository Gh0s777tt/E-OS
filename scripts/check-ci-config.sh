#!/usr/bin/env bash

set -e

if [ -n "$1" ]
then
    ARCH="$1"
else
    ARCH="x86_64"
fi

make build/fstools

config="config/${ARCH}/ci.toml"

# This used to build a `declare -A` map of recipe -> dir, blank the entries named by the
# config, and print what was left. `declare -A` is bash 4; the E-OS dev host ships
# /bin/bash 3.2 (CLAUDE.md 9), so the script simply did not run there. The job is a set
# difference -- recipes that no config package names -- which says so more directly.
in_config="$(mktemp)"
trap 'rm -f "${in_config}"' EXIT
build/fstools/bin/redox_installer --list-packages -c "${config}" | sort -u > "${in_config}"

echo "Checking for missing packages in ${config}"
printf '%-32s%s\n' "PACKAGE" "RECIPE"
build/fstools/bin/list_recipes | grep -v '^recipes/wip/' | while IFS= read -r recipe_dir
do
    recipe_name="$(basename "${recipe_dir}")"
    if ! grep -qxF "${recipe_name}" "${in_config}"
    then
        printf '%-32s%s\n' "${recipe_name}" "${recipe_dir}"
    fi
done | sort
