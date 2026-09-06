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
          sec_icon = (sec=="") ? "✅" : "🔒";
          if (sig >= 80)      strength_icon="󰤨";
          else if (sig >= 60) strength_icon="󰤥";
          else if (sig >= 40) strength_icon="󰤢";
          else if (sig >= 20) strength_icon="󰤟";
          else                strength_icon="󰤯";
          printf "%s | %s  %d%% | %s\n", sec_icon, strength_icon, sig, ssid
      }'
)

if [[ -z "$wifi_list" ]]; then
  notify-send "WiFi" "未扫描到WiFi网络"
  exit 0
fi

# 3. wofi选择wifi
CHOSEN=$(echo "$wifi_list" | wofi --dmenu --prompt="💡提示：隐藏SSID直接输入即可尝试连接")
[[ -z "$CHOSEN" ]] && exit 0

# 提取SSID（取前30字符字段）
SSID=$(echo "$CHOSEN" | awk -F' ' '{print $6}')

# 尝试连接：已保存过该网络直接连接
if nmcli connection show "$SSID" >/dev/null 2>&1; then
  nmcli connection up "$SSID"
  notify-send "WiFi" "已连接 $SSID"
  exit 0
fi

# 没有保存配置 → 需要密码，wofi弹窗输入密码
TIPS_ENTRY="<span color='#82aaff'>💡请输入WiFi密码：$SSID</span>"
PASSWORD=$(echo ${TIPS_ENTRY} | wofi --dmenu --password)
[[ -z "$PASSWORD" ]] && exit 0

# nmcli新建连接并连接
nmcli device wifi connect "$SSID" password "$PASSWORD"
if [ $? -eq 0 ];then
  notify-send "WiFi" "成功连接 $SSID"
else
  notify-send -u critical "WiFi连接失败" "SSID:$SSID，密码错误或无法接入"
fi
