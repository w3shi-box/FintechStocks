#!/usr/bin/env bash
set -e

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/fintechstocks"

if [ ! -d "$CACHE" ]; then
    echo "Cache missing."
    exit 1
fi

echo "Cache verified."

exit 0
