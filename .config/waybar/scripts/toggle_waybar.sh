#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <Bar-ID>"
    echo "    Bar-ID: Value Range:["topbar", "dock"]"
    echo "Example: $0 dock"
    exit 1
fi

bar_id="$1"

CONFIG_FILE="${HOME}/.config/waybar/${bar_id}.jsonc"
WAYBAR_ARGS=("-b" "${bar_id}" "-c" "${CONFIG_FILE}")

if pgrep -f "waybar ${WAYBAR_ARGS[*]}" > /dev/null; then
    pkill -SIGUSR2 -f "waybar ${WAYBAR_ARGS[*]}"
    exit 0
fi

# launch new dock waybar
setsid waybar "${WAYBAR_ARGS[@]}" >/dev/null 2>&1 &
