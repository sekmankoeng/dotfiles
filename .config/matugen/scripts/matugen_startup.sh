#!/usr/bin/env bash
set -euo pipefail

has_waybar_block_inhibit() {
    systemd-inhibit --list | awk '
        NR <= 2 { next }
        $1 == "waybar" && $NF == "block" { exit 1 }
    '
}

if ! has_waybar_block_inhibit; then
    # 存在waybar block抑制，直接退出，不切换主题
    exit 0
fi

# 无抑制，执行matugen
WALLPAPER=$(find /home/swq/Pictures/Wallpapers -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | shuf -n 1)
matugen --config "/home/swq/.config/matugen/config.toml" --prefer lightness image "$WALLPAPER"
