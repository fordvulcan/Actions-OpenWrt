#!/usr/bin/env bash
# diy-part1.sh
# 在 feeds 更新前执行：
#   1. 追加 kiddin9(op-packages) 聚合软件源（luci-app-* 插件来源）
#   2. 注入 Cudy TR3000 大分区(mod)设备定义（DTS + filogic.mk）
#   3. 为 112M/240M 大分区版与 256M 标准版追加内置插件（DEVICE_PACKAGES）
# 需要在 OpenWrt 源码根目录下运行（GitHub Actions 通过 working-directory: openwrt 保证）。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${GITHUB_WORKSPACE:-$(dirname "${SCRIPT_DIR}")}"
DEVICE_FILES="${WORKSPACE_DIR}/device-files"

DTS_DIR="target/linux/mediatek/dts"
IMAGE_MK="target/linux/mediatek/image/filogic.mk"
FEEDS_CONF="feeds.conf.default"

# 内置插件包列表（统一提供给 112M/240M 大分区版与 256M 标准版；保持单行便于 sed 注入）
#   - luci-theme-argon 在 configs/tr3000.config 中全局启用，此处仅列设备级插件
#   - PassWall2 设备级安装不会自动捆绑代理内核，显式加入 xray-core
#     （需要 sing-box / hysteria 时在本行追加包名即可）
#   - 末尾 6 个为 USB 存储支持：samba4 / ksmbd / diskman 挂载 U 盘所需
TR3000_PLUGINS="luci-app-passwall2 xray-core luci-app-openclash luci-app-samba4 luci-app-ksmbd luci-app-vsftpd luci-app-webdav luci-app-linkease luci-app-ttyd luci-app-store luci-app-hd-idle luci-app-netdata luci-app-arpbind luci-app-ddns luci-app-ddns-go luci-app-oaf luci-proto-wireguard wireguard-tools luci-app-softethervpn luci-app-diskman kmod-usb-storage kmod-usb-storage-uas block-mount kmod-fs-ext4 kmod-fs-vfat kmod-nls-utf8"

log() { echo "[diy-part1] $*"; }

if [ ! -f "${IMAGE_MK}" ] || [ ! -f "${FEEDS_CONF}" ]; then
    echo "[diy-part1] 错误：未找到 ${IMAGE_MK} 或 ${FEEDS_CONF}，请在 OpenWrt 源码根目录运行本脚本"
    exit 1
fi

# ---- 上游基础设备自检（128M / 256M 标准版依赖上游定义） ----
for base_dev in cudy_tr3000-v1 cudy_tr3000-256mb-v1; do
    if ! grep -q "define Device/${base_dev}$" "${IMAGE_MK}"; then
        log "警告：上游源码中未找到 ${base_dev}，目标分支($(cat .config 2>/dev/null | grep -m1 CONFIG_VERSION_NUMBER || git rev-parse --abbrev-ref HEAD 2>/dev/null))可能不支持该机型"
    fi
done

# ---- 1. 追加 kiddin9 聚合软件源（op-packages，提供 luci-app-* 等插件） ----
if grep -q "kiddin9/op-packages" "${FEEDS_CONF}"; then
    log "kiddin9 软件源已存在，跳过"
else
    echo "src-git kiddin9 https://github.com/kiddin9/op-packages.git" >> "${FEEDS_CONF}"
    log "已追加 kiddin9 软件源到 ${FEEDS_CONF}"
fi

# ---- 2. 复制自定义 DTS（若上游已存在同名文件则不覆盖） ----
for dts in mt7981b-cudy-tr3000-mod.dts mt7981b-cudy-tr3000-256mb-mod.dts; do
    if [ -f "${DTS_DIR}/${dts}" ]; then
        log "DTS ${dts} 已存在，跳过复制"
    else
        cp -v "${DEVICE_FILES}/${dts}" "${DTS_DIR}/"
    fi
done

# ---- 3. 幂等注入设备定义到 filogic.mk ----
inject_device() {
    local dev_name="$1" snippet="$2"
    if grep -q "define Device/${dev_name}$" "${IMAGE_MK}"; then
        log "设备 ${dev_name} 已存在，跳过注入"
    else
        { echo ""; cat "${snippet}"; } >> "${IMAGE_MK}"
        log "已注入设备 ${dev_name}"
    fi
}

inject_device "cudy_tr3000-mod"       "${DEVICE_FILES}/filogic-cudy_tr3000-mod.mk"
inject_device "cudy_tr3000-256mb-mod" "${DEVICE_FILES}/filogic-cudy_tr3000-256mb-mod.mk"

# ---- 4. 为 3 款设备追加内置插件（DEVICE_PACKAGES，单处维护） ----
#   112M 大分区版 / 240M 大分区版 / 256M 标准版内置全部插件；
#   128M 标准版（cudy_tr3000-v1）不追加（可用空间约 45M，装不下插件套件）
for dev in cudy_tr3000-mod cudy_tr3000-256mb-mod cudy_tr3000-256mb-v1; do
    if ! grep -q "^define Device/${dev}$" "${IMAGE_MK}"; then
        log "警告：未找到设备 ${dev} 定义，跳过插件追加"
        continue
    fi
    if sed -n "/^define Device\/${dev}$/,/^endef$/p" "${IMAGE_MK}" | grep -q "luci-app-passwall2"; then
        log "${dev} 已包含插件列表，跳过"
        continue
    fi
    sed -i "/^define Device\/${dev}$/,/^endef$/ s|^  DEVICE_PACKAGES := |&${TR3000_PLUGINS} |" "${IMAGE_MK}"
    if sed -n "/^define Device\/${dev}$/,/^endef$/p" "${IMAGE_MK}" | grep -q "luci-app-passwall2"; then
        log "已为 ${dev} 追加内置插件（DEVICE_PACKAGES）"
    else
        echo "::error::为 ${dev} 追加插件失败（DEVICE_PACKAGES 行结构可能已变化），请检查 ${IMAGE_MK}" >&2
        exit 1
    fi
done

log "完成"
