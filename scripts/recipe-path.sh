#!/usr/bin/env bash

FIND_RECIPE="find recipes -maxdepth 4 -name"

# "$@" not $* -- unquoted, a recipe name containing a space is split into two.
for recipe in "$@"
do
    ${FIND_RECIPE} "${recipe}"
done
