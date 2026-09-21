#!/usr/bin/env bash

# 获取颜色
COLOR=$(awk 'BEGIN{FS="[[:space:];]+"} $3 == "on_surface" {print $4}' $HOME/.config/waybar/colors.css)
# 替换svg的填充颜色fill=
if [ -n "$COLOR" ]; then
  sed -i -E "s/fill=\"#[0-9a-fA-F]+\"/fill=\"$COLOR\"/g" $HOME/.config/waybar/icons/peach-round-dark.svg;
fi

# 修改这里：用 systemd-run --user --scope 启动，脱离当前service cgroup
reload_waybar() {
  local bar_id="$1"
  # 查找对应waybar进程，先杀掉旧实例
  local CONFIG_FILE="${HOME}/.config/waybar/${bar_id}.jsonc"
  local WAYBAR_ARGS=("-b" "${bar_id}" "-c" "${CONFIG_FILE}")
  if pgrep -f "waybar ${WAYBAR_ARGS[*]}" > /dev/null; then
    pkill -SIGTERM -f "waybar ${WAYBAR_ARGS[*]}"
  fi
  # 重点：systemd-run --user --scope，新进程归属独立scope，不再属于theme_rotate.service
  systemd-run --user --scope waybar "${WAYBAR_ARGS[@]}" >/dev/null 2>&1 &
}

reload_waybar topbar
#reload_waybar dock