#!/usr/bin/env bash
set -euo pipefail

# ========== 配置区 ==========
SESSION_ID="$XDG_SESSION_ID"
SERVICE="org.freedesktop.login1"
MANAGER_PATH="/org/freedesktop/login1"
MANAGER_IFACE="org.freedesktop.login1.Manager"
SESSION_IFACE="org.freedesktop.login1.Session"
SESSION_PATH=$(busctl --system call "$SERVICE" "$MANAGER_PATH" "$MANAGER_IFACE" GetSession s "$SESSION_ID" | awk '{print $2}' | tr -d '"')

SIGNAL_LOCK="Lock"
SIGNAL_UNLOCK="Unlock"

LOCK_SCRIPT="/usr/local/bin/lockscreen.sh"
UNLOCK_SCRIPT=""

LAST_LOCK_TS=0
LAST_UNLOCK_TS=0
DEBOUNCE_MS=500

FIFO_EVT="$XDG_RUNTIME_DIR/login_session_evt.fifo"

# ========== 初始化 ==========
rm -f "$FIFO_EVT"
mkfifo "$FIFO_EVT"
exec 9<> "$FIFO_EVT"

# 查询LockedHint
is_locked() {
    [[ $(loginctl show-session "$SESSION_ID" -p LockedHint --value) == "yes" ]]
}

# 清理钩子
cleanup() {
    echo "cleanup: stopping watchers and cleaning resources"
    [[ -n "${PID_LOCK:-}" ]] && kill "$PID_LOCK" 2>/dev/null 2>&1 || true
    [[ -n "${PID_UNLOCK:-}" ]] && kill "$PID_UNLOCK" 2>/dev/null 2>&1 || true
    rm -f "$FIFO_EVT"
    exit 0
}
trap cleanup SIGINT SIGTERM

if [[ -z "$SESSION_PATH" ]]; then
    echo "ERROR: Cannot get session path for $SESSION_ID" >&2
    exit 1
fi

# ========== 信号监听协程 ==========
watch_lock() {
    while true; do
        if busctl --system wait "$SERVICE" "$SESSION_PATH" "$SESSION_IFACE" "$SIGNAL_LOCK"; then
            echo "LOCK" >&9
        fi
    done
}

watch_unlock() {
    while true; do
        if busctl --system wait "$SERVICE" "$SESSION_PATH" "$SESSION_IFACE" "$SIGNAL_UNLOCK"; then
            echo "UNLOCK" >&9
        fi
    done
}

watch_lock >/dev/null 2>&1 &
PID_LOCK=$!
watch_unlock >/dev/null 2>&1 &
PID_UNLOCK=$!

echo "Started watching session $SESSION_PATH"
echo "PID lock=$PID_LOCK unlock=$PID_UNLOCK"

# ========== 主循环 ==========
while true; do
    if read -r -t 2 -u9 evt; then
        case "$evt" in
            LOCK)
                echo ">> Session Lock signal received"
                if is_locked; then
                    echo "Skip: already locked (LockedHint=yes)"
                    continue
                fi

                LOCK_NOW=$(date +%s%3N)
                if (( LOCK_NOW - LAST_LOCK_TS < DEBOUNCE_MS )); then
                    echo "Debounce skip lock event"
                    continue
                fi
                LAST_LOCK_TS=$LOCK_NOW

                echo "Run lock script: $LOCK_SCRIPT"
                if [[ -n "${LOCK_SCRIPT:-}" && -x "$LOCK_SCRIPT" ]]; then
                    setsid "$LOCK_SCRIPT" </dev/null &
                fi
                ;;
            UNLOCK)
                echo ">> Session Unlock signal received"
                if ! is_locked; then
                    echo "Skip: already unlocked (LockedHint=no)"
                    continue
                fi
                UNLOCK_NOW=$(date +%s%3N)
                if (( UNLOCK_NOW - LAST_UNLOCK_TS < DEBOUNCE_MS )); then
                    echo "Debounce skip unlock event"
                    continue
                fi
                LAST_UNLOCK_TS=$UNLOCK_NOW
                if [[ -n "${UNLOCK_SCRIPT:-}" && -x "$UNLOCK_SCRIPT" ]]; then
                    "$UNLOCK_SCRIPT"
                fi
                ;;
            *)
                echo "Unknown event: $evt"
                ;;
        esac
    fi
done

