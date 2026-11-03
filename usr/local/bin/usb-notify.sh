#!/usr/bin/env bash

set -euo pipefail

RAW="$1"
ACTION="${RAW%%:*}"   # %% 从尾部删掉最短匹配，拿到 add / remove
DEVNAME="${RAW#*:}"   # # 从头部删掉最短匹配，拿到 LABEL/DEVNAME

# flock防抖
LOCK="/tmp/usb-notify.lock"

echo $$ > "${LOCK}"
exec 200>"${LOCK}"
if ! flock -n 200; then
    exit 0
fi

if [[ "${ACTION}" == "add" ]]; then
    notify-send -a "udev" -u normal "USB Block Device" "Udisk: ${DEVNAME} has been inserted"
elif [[ "${ACTION}" == "remove" ]]; then
    notify-send -a "udev" -u normal "USB Block Device" "Udisk: ${DEVNAME} has been removed"
elif [[ "${ACTION}" == "change" ]]; then
    notify-send -a "udev" -u normal "USB Block Device" "Udisk: ${DEVNAME} has been ejected"
fi
