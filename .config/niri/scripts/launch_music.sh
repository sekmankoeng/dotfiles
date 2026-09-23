#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname ${BASH_SOURCE[0]})" &>/dev/null && pwd)
# source接口
source "${SCRIPT_DIR}/lib_spawn_or_focused.sh"

spawn_or_focus "music" kitty --title music --single-instance --session /home/swq/.config/kitty/sessions/music-player.session