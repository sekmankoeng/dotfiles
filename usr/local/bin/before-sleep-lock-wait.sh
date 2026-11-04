#!/usr/bin/env bash
set -euo pipefail

# 最长等待握手完成时间
WAIT_MAX=4
POLL_INTERVAL=0.1
SESSION_ID="${XDG_SESSION_ID:?}"

# 查询LockedHint
is_locked() {
    [[ $(loginctl show-session "$SESSION_ID" -p LockedHint --value) == "yes" ]]
}

if is_locked; then
    exit 0
fi
# 两种方案：
# 1.复用防抖+去重入的异步生成-同步消费的DBus/lock-handler 信号队列处理机制
#   属于遵守lock-handler中建议锁（advisory lock）的统一调用入口
#loginctl lock-session
# 2.即将进入suspend状态，则无需考虑DBus/lock-handler 信号队列机制
/usr/local/bin/lockscreen.sh &

# 等待锁屏信号
ELAPSED=0
while ! is_locked && awk -v e="$ELAPSED" -v m="$WAIT_MAX" 'BEGIN{exit !(e < m)}'; do
    sleep "$POLL_INTERVAL"
    ELAPSED=$(awk -v e="$ELAPSED" -v p="$POLL_INTERVAL" 'BEGIN{print e + p}')
done

# 超时处理
if ! is_locked; then
    notify-send -u critical "Suspend lock timeout" "Failed to confirm session lock, suspending anyway"
    exit 0
fi

# LockedHint=yes, 握手完成，session 进入锁屏状态，放行suspend
exit 0
