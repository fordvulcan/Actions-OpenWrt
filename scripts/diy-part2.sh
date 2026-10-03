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

# ---- per-device rootfs 的 apk add 加 --force-overwrite ----
# image.mk 的 apk_target（per-device rootfs 组装，DEVICE_PACKAGES 安装）不带
# --force-overwrite：apk 3.x 把"不同包包含同一文件"计为错误（打印
# "ERROR: <pkg>: trying to overwrite <file> owned by <pkg>"，跳过该文件，
# 事务继续但退出码非零），第三方源（kiddin9）与官方源出现文件冲突时
# make target-dir-% 即失败。加 --force-overwrite 将冲突降级为 WARNING
# （后装包文件覆盖已装包），构建继续；该开关仅影响冲突分支，依赖解析
# 失败等其他错误仍会硬失败，Verify 防线不受影响。
IMG_MK="include/image.mk"
if [ -f "${IMG_MK}" ] && grep -q -- '--no-scripts' "${IMG_MK}" && ! grep -q -- '--force-overwrite' "${IMG_MK}"; then
    sed -i 's|--no-scripts \\|--no-scripts --force-overwrite \\|' "${IMG_MK}"
    log "已为 per-device rootfs 的 apk add 加上 --force-overwrite（文件冲突降级为警告）"
fi

log "完成"
