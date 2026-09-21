#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 [Bar-ID] [Action]"
    echo "    Bar-ID: [topbar, dock]"
    echo "    Action: [reload, toggle]"
    echo "Example: $0 dock"
    exit 1
fi

bar_id="$1"
action="$2"
SIG=""

if [[ $action == 'reload' ]]; then
    SIG="SIGUSR2"
elif [[ $action == 'toggle' ]]; then
    SIG="SIGUSR1"
else
    echo "Parameter error. Unkown action: ${action}"
    exit 1
fi

CONFIG_FILE="${HOME}/.config/waybar/${bar_id}.jsonc"
WAYBAR_ARGS=("-b" "${bar_id}" "-c" "${CONFIG_FILE}")

if pgrep -f "waybar ${WAYBAR_ARGS[*]}" > /dev/null; then
    pkill -${SIG} -f "waybar ${WAYBAR_ARGS[*]}"
    exit 0
fi

# launch new dock waybar
setsid waybar "${WAYBAR_ARGS[@]}" >/dev/null 2>&1
