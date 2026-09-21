#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 [Bar-ID] [Action]"
    echo "    Bar-ID: [topbar, dock]"
    echo "    Action: [reload, toggle]"
    echo "Example: $0 dock reload"
    exit 1
fi

bar_id="$1"
action="$2"
SIG=""

if [[ $action == 'reload' ]]; then
    # Bug: 两个waybar实例场景，后一个启动的waybar会在reload时，由于DBus注册冲突直接断言退出。
    # 这里更改方案，使用SIGTERM来直接终结进程，并重新拉起进程
    #SIG="SIGUSR2"
    SIG="SIGTERM"
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
    if [[ $action == 'toggle' ]]; then
        exit 0
    fi
fi

# launch new dock waybar
setsid waybar "${WAYBAR_ARGS[@]}" >/dev/null 2>&1 &