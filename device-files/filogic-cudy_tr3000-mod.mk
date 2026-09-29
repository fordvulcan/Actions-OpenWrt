# Cudy TR3000 128M 大分区固件 (U-Boot mod, 112M / mod-112m 方案)
# 由 scripts/diy-part1.sh 幂等注入到 target/linux/mediatek/image/filogic.mk
# 对应社区 "cudy_tr3000-mod" 设备（与 Kwrt / LEDE 定义一致）
# 内置插件（PassWall2/OpenClash 等）由 diy-part1.sh 的 TR3000_PLUGINS 统一追加到 DEVICE_PACKAGES
define Device/cudy_tr3000-mod
  DEVICE_VENDOR := Cudy
  DEVICE_MODEL := TR3000
  DEVICE_VARIANT := (U-Boot mod 112M)
  DEVICE_DTS := mt7981b-cudy-tr3000-mod
  DEVICE_DTS_DIR := ../dts
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 114688k
  KERNEL_IN_UBI := 1
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  DEVICE_PACKAGES := kmod-usb3 kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware
endef
TARGET_DEVICES += cudy_tr3000-mod
