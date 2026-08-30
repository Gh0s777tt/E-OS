#!/usr/bin/env bash

# This script create and copy the Redox bootable image to an Ventoy-formatted device

set -e

ARCHS=(
    i686
    x86_64
)
CONFIGS=(
    demo
    desktop
)

VENTOY="/media/${USER}/Ventoy"
if [ ! -d "${VENTOY}" ]
then
    echo "Ventoy not mounted" >&2
    exit 1
fi

for ARCH in "${ARCHS[@]}"
do
    for CONFIG_NAME in "${CONFIGS[@]}"
    do
        IMAGE="$(make -s print-installer-medium ARCH="${ARCH}" CONFIG_NAME="${CONFIG_NAME}" PODMAN_BUILD=0)"
        make ARCH="${ARCH}" CONFIG_NAME="${CONFIG_NAME}" "${IMAGE}"
        cp -v "${IMAGE}" "${VENTOY}/redox-${CONFIG_NAME}-${ARCH}.iso"
    done
done

sync

# [*] inside a string, not [@]: [@] inside double quotes expands to separate words and
# echo silently prints only the first of each array (SC2145).
echo "Finished copying configs (${CONFIGS[*]}) for archs (${ARCHS[*]})"
