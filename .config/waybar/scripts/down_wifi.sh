#!/usr/bin/env bash
set -euo pipefail

readarray -t active_list < <(
    nmcli -t -f NAME,TYPE connection show --active \
    | grep -E "wifi|wireless" | awk -F: '{print $1}' || true
)

if [[ "${#active_list[@]}" -eq 0 ]]; then
  notify-send "WiFi" "当前已没有Wi-Fi网络连接"
  exit 0
fi

for ssid in "${active_list[@]}"; do
  nmcli connection down "$ssid"
done
notify-send "WiFi" "当前已断开Wi-Fi网络连接"

exit 0