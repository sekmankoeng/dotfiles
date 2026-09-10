#!/usr/bin/env bash
set -euo pipefail

readarray -t wifi_list < <(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status \
  | awk -F: '$2 == "wifi" {print $1 ":" $3 ":" $4}' || true
)

if [[ "${#wifi_list[@]}" -eq 0 ]]; then
  notify-send -a "waybar" -u normal "Wi-Fi" "无线网络连接当前不存在"
  exit 0
fi

IFS=':' read -r DEVICE STATE SSID <<< "${wifi_list[0]}"

if [[ "connected" == "${STATE}" ]]; then
  nmcli device disconnect "${DEVICE}"
  notify-send -a "waybar" -u normal "Wi-Fi: ${DEVICE}" "无线网络连接已断开：${SSID}"
else
  nmcli device connect "${DEVICE}"
  notify-send -a "waybar" -u normal "Wi-Fi: ${DEVICE}" "无线网络连接成功"
fi
exit 0