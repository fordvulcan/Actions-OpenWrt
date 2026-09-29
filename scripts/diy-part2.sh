#!/usr/bin/env bash
# diy-part2.sh
# 在 feeds 安装后执行：应用仓库内 files/ 自定义 overlay（默认配置、首次启动脚本等）。
# 需要继续追加软件包时，建议直接修改 configs/tr3000.config。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${GITHUB_WORKSPACE:-$(dirname "${SCRIPT_DIR}")}"
CUSTOM_FILES="${WORKSPACE_DIR}/files"

log() { echo "[diy-part2] $*"; }

# 将仓库 files/ 目录内容覆盖到 OpenWrt 源码根目录（编译时自动打包进固件）
if [ -d "${CUSTOM_FILES}" ]; then
    cp -rv "${CUSTOM_FILES}/." ./
    log "已应用自定义文件 overlay"
else
    log "未找到 files/ 目录，跳过"
fi

log "完成"
