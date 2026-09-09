#!/usr/bin/env bash
set -euo pipefail

CMD=(wlogout -s)
LOCK="/tmp/wlogout.lock"
echo "$$" > "${LOCK}"
# 文件锁：防抖，防止多次快捷键并行执行
exec 200>"${LOCK}"
# -n 非阻塞锁，拿不到锁就直接退出
if ! flock -n 200; then
    exit 0
fi

# 先优雅关闭，在重新启动
if pgrep -f "${CMD[*]}" > /dev/null; then
    pkill -f "${CMD[*]}"
    while pgrep -f "${CMD[*]}" > /dev/null; do
        sleep 0.05
    done
fi

${CMD[@]}