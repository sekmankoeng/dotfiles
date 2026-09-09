#!/usr/bin/env bash
set -euo pipefail

CMD=(wlogout -s)
LOCK="/tmp/wlogout.lock"

# 文件锁：防抖，防止多次快捷键并行执行
if [[ -f "${LOCK}" ]]; then
    exit 0
fi

touch "${LOCK}"
# 设置脚本退出时自动清理文件锁
trap "rm -f ${LOCK}" EXIT

# 先优雅关闭，在重新启动
if pgrep -f "${CMD[*]}" > /dev/null; then
    pkill -f "${CMD[*]}"
    while pgrep -f "${CMD[*]}" > /dev/null; do
        sleep 0.05
    done
fi

${CMD[@]}