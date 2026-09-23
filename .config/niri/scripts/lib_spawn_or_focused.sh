#!/usr/bin/env bash
# lib_spawn_or_focus.sh
# 依赖：niri, jq
# 函数：spawn_or_focus
# 参数1：窗口标题（精准匹配）
# 参数2及以后：需要niri spawn的完整命令

spawn_or_focus() {
    WIN_TITLE="$1"
    shift
    CMD=("$@")

    WIN_ID=$(niri msg --json windows | jq -r --arg t "$WIN_TITLE" '.[] | select(.title == $t) | .id // empty')

    if [[ -n "$WIN_ID" ]]; then
        FOCUSED_ID=$(niri msg --json windows | jq -r '.[] | select(.is_focused) | .id')
        if [[ "$FOCUSED_ID" == "$WIN_ID" ]]; then
            niri msg action focus-window-previous
        else
            niri msg action focus-window --id "$WIN_ID"
        fi
    else
        niri msg action spawn -- "${CMD[@]}"
    fi
}