#!/usr/bin/env bash
set -euo pipefail

# 1. 触发WiFi扫描
nmcli device wifi rescan >/dev/null 2>&1

# 2. 获取可用WiFi列表：SSID,信号(0‑100),安全类型
# nmcli -t -f BARS在命令行执行时，输出的信号强度是以图形条的形式，但在脚本中就会显示成星号*，
# 这里不再使用BARS参数，而是直接使用SIGNAL参数获取信号强度的数值(0-100)，然后在脚本中根据数值生成图形条。
wifi_list=$(nmcli -t -f SECURITY,SIGNAL,SSID device wifi list \
  | sort -t: -k2,2 -nr \
  | uniq \
  | awk -F':' '
      {
          sec=$1; sig=$2+0; ssid=$3;
          sec_icon = (sec=="") ? "🔓" : "🔒";
          if (sig >= 80)      strength_icon="󰤨";
          else if (sig >= 60) strength_icon="󰤥";
          else if (sig >= 40) strength_icon="󰤢";
          else if (sig >= 20) strength_icon="󰤟";
          else                strength_icon="󰤯";
          printf "%s | %s\t%d%% | %s\n", sec_icon, strength_icon, sig, ssid
      }'
)

if [[ -z "$wifi_list" ]]; then
  notify-send "WiFi" "未扫描到WiFi网络"
  exit 1
fi

# 3. 选择wifi
CHOSEN=$(echo "$wifi_list" | fuzzel --dmenu)
[[ -z "$CHOSEN" ]] && exit 0

# 4. 判断是新填写的隐藏SSID还是选择的已扫描到的SSID
RE='^(🔒|🔓)[[:space:]]+\|[[:space:]]+([^|]+)[[:space:]]([0-9]{1,3})%[[:space:]]+\|[[:space:]]+(.*)$'
if [[ "$CHOSEN" =~ $RE ]]; then
  ICON="${BASH_REMATCH[1]}"
  SSID="${BASH_REMATCH[4]}"
else
  SSID="$CHOSEN"
fi

# 尝试连接：已保存过的网络直接连接
if nmcli connection show "$SSID" >/dev/null 2>&1; then
  if ! nmcli connection up "$SSID"; then
    notify-send -a "waybar" -u normal "WiFi" "无限网络连接失败：$SSID，该连接配置异常，请尝试删除后重新连接"
    exit 1
  fi
  notify-send -a "waybar" -u normal "WiFi" "无线网络连接成功：$SSID"
  exit 0
fi

# 5. 分支：连接无密码的开放WiFi
if [[ "$ICON" == "🔓" ]]; then
    if nmcli device wifi connect "$SSID"; then
        notify-send -a "waybar" -u normal "WiFi" "连接成功：$SSID"
    else
        # 连接失败时，可能是nmcli新建的连接配置异常，需要清除nmcli新建的连接配置，否则下次连接同一SSID时会直接使用异常的配置尝试连接，导致连接失败。
        if [[ -n "$SSID" ]]; then
            nmcli connection delete "$SSID" >/dev/null 2>&1 || true
        fi
        notify-send -a "waybar" -u normal "WiFi" "连接失败：$SSID"
        exit 1
    fi
    exit 0
fi

# 6. 分支：连接加密WiFi
SSID_HINT="<span color='#82aaff'>💡即将连接：${SSID}</span>"
HIDE_HINT="<span color='#82aaff'>⚠️隐藏SSID无法自动连接</span>"

HINT_LIST=$( printf "%s\n%s" "$SSID_HINT" "$HIDE_HINT" )
# PASSWORD=$(echo "${HINT_LIST}" | wofi --style=${HOME}/.config/wofi/wifi_auth.css --dmenu --height=200 --password --prompt="🔑 请输入WiFi密码")
PASSWORD=$(fuzzel --dmenu --prompt-only="WiFi密码: " --password --placeholder="请输入WiFi密码")
if [[ -z "$PASSWORD" ]]; then
  notify-send -a "waybar" -u normal "WiFi" "无限网络连接失败：$SSID，无效密码"
  exit 1
fi

# nmcli新建连接并连接
if nmcli device wifi connect "$SSID" password "$PASSWORD";then
  notify-send -a "waybar" -u normal "WiFi" "无限网络连接成功：$SSID"
else
  # 密码错误时，需要清除nmcli新建的连接配置，否则下次连接同一SSID时会直接使用错误的密码尝试连接，导致连接失败。
  nmcli connection delete "$SSID" >/dev/null 2>&1 || true
  notify-send -a "waybar" -u normal "WiFi" "无限网络连接失败：$SSID，密码错误或无法接入"
  exit 1
fi
