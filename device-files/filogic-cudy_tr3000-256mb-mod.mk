# Cudy TR3000 256M 大分区固件 (U-Boot mod, 240M)
# 由 scripts/diy-part1.sh 幂等注入到 target/linux/mediatek/image/filogic.mk
# SUPPORTED_DEVICES 允许从 256M 标准版系统直接 sysupgrade 刷入本固件
# 内置插件（PassWall2/OpenClash 等）由 diy-part1.sh 的 TR3000_PLUGINS 统一追加到 DEVICE_PACKAGES
define Device/cudy_tr3000-256mb-mod
  DEVICE_VENDOR := Cudy
  DEVICE_MODEL := TR3000
  DEVICE_VARIANT := 256mb (U-Boot mod 240M)
  DEVICE_DTS := mt7981b-cudy-tr3000-256mb-mod
  DEVICE_DTS_DIR := ../dts
  SUPPORTED_DEVICES += cudy_tr3000-256mb-v1
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 245760k
  KERNEL_IN_UBI := 1
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  DEVICE_PACKAGES := kmod-usb3 kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware
endef
TARGET_DEVICES += cudy_tr3000-256mb-mod
