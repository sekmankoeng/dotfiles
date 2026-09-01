#!/bin/bash
set -euo pipefail  # 严格模式（兼容macOS/Linux）

# ===================== 配置区 =====================
LINK_ROOT_DIR="${HOME}"  # 软链接根目录（家目录）
BACKUP_SUFFIX=".bak_$(date +%Y%m%d%H%M%S)"
# ===================== 函数定义区 =====================

# 仅输出到标准输出
log() {
    local LEVEL="$1"
    local MSG="$2"
    local TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "[$TIMESTAMP] [$LEVEL] $MSG"
}

# 校验参数
check_params() {
    if [ $# -eq 0 ]; then
        log "ERROR" "未传入任何文件参数！用法：$0 <文件1> <文件2> ..."
        exit 1
    fi
}

# 校验文件存在且为普通文件
check_file_exists() {
    local FILE_PATH="$1"
    if [ ! -e "${FILE_PATH}" ]; then
        log "ERROR" "文件不存在：${FILE_PATH}"
        return 1
    elif [ ! -f "${FILE_PATH}" ] && [ ! -d "${FILE_PATH}" ]; then
        log "ERROR" "不是普通文件或目录（可能是设备文件）：${FILE_PATH}"
        return 1
    fi
    return 0
}

# 跨平台获取文件绝对路径
get_abs_path() {
    local FILE_PATH="$1"
    if [[ "$(uname -s)" == "Darwin" ]]; then
        ABS_PATH=$(python3 -c "import os; print(os.path.realpath('${FILE_PATH}'))" 2>/dev/null)
    else
        ABS_PATH=$(realpath -e "${FILE_PATH}" 2>/dev/null)
    fi
    echo "${ABS_PATH}"
}

# 创建软链接核心逻辑（保留路径层级）
create_symlink() {
    local SRC_FILE="$1"          # 源文件绝对路径
    local REL_PATH="$2"         # 传入的相对路径（如 .config/alacritty/alacritty.toml）
    local LINK_PATH="${LINK_ROOT_DIR}/${REL_PATH}"  # 目标软链接完整路径

    # 1. 创建目标目录（若不存在）
    local LINK_DIR=$(dirname "${LINK_PATH}")
    if [ ! -d "${LINK_DIR}" ]; then
        log "INFO" "创建目标目录：${LINK_DIR}"
        mkdir -p "${LINK_DIR}" || {
            log "ERROR" "创建目录失败：${LINK_DIR}"
            return 1
        }
    fi

    # 2. 覆盖已存在的软链接
    if [ -L "${LINK_PATH}" ]; then
        log "INFO" "发现已存在的软链接，强制覆盖：${LINK_PATH}"
        ln -sf "${SRC_FILE}" "${LINK_PATH}"
        return 0
    fi

    # 3. 备份真实文件/目录
    if [ -f "${LINK_PATH}" ] || [ -d "${LINK_PATH}" ]; then
        local BACKUP_PATH="${LINK_PATH}${BACKUP_SUFFIX}"
        log "WARNING" "目标是真实文件/目录，先备份：${LINK_PATH} → ${BACKUP_PATH}"
        mv "${LINK_PATH}" "${BACKUP_PATH}" || {
            log "ERROR" "备份失败：${LINK_PATH}"
            return 1
        }
    fi

    # 4. 创建软链接
    ln -s "${SRC_FILE}" "${LINK_PATH}" || {
        log "ERROR" "创建软链接失败：${SRC_FILE} → ${LINK_PATH}"
        return 1
    }
    log "SUCCESS" "软链接创建成功：${SRC_FILE} → ${LINK_PATH}"
    return 0
}

# ===================== 主程序 =====================
log "INFO" "脚本启动"

# 校验参数
check_params "$@"

# 遍历文件参数
for REL_FILE in "$@"; do
    # 步骤1：获取源文件绝对路径
    ABS_SRC_FILE=$(get_abs_path "${REL_FILE}")
    if [ -z "${ABS_SRC_FILE}" ]; then
        log "ERROR" "无法获取绝对路径：${REL_FILE}"
        continue
    fi

    # 步骤2：校验源文件合法性
    if ! check_file_exists "${ABS_SRC_FILE}"; then
        continue
    fi

    # 步骤3：保留原始相对路径，创建软链接（核心修改）
    create_symlink "${ABS_SRC_FILE}" "${REL_FILE}"
done

log "INFO" "脚本执行完成"
exit 0
