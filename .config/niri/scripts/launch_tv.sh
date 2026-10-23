#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname ${BASH_SOURCE[0]})" &>/dev/null && pwd)
# source接口
source "${SCRIPT_DIR}/lib_spawn_or_focused.sh"

M3U_URL="https://gitee.com/sekmankoeng/iptv/raw/master/iptv_playlist.m3u"

spawn_or_focus "tv" mpv $M3U_URL --title="tv"