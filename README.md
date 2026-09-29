# Cudy TR3000 OpenWrt 固件自动构建

基于官方 OpenWrt 稳定分支（`openwrt-25.12`）与 GitHub Actions 的全自动固件编译项目：
一次构建同时产出 Cudy TR3000 **128M / 256M** 两种硬件版本的**标准固件**与**大分区固件**，共 4 款。

> 项目思路参考 [Kwrt](https://github.com/kiddin9/Kwrt)（openwrt.ai）与 Actions-OpenWrt：
> 纯净化固件 + 云端自动编译 + 自动发布 Releases。

## 固件清单

| 固件 | 设备名 | 分区方案 | 刷写方式 |
|---|---|---|---|
| 128M 标准版 | `cudy_tr3000-v1` | 原厂布局，ubi 64M（可用约 45M） | 官方过渡固件后 LuCI 刷入 |
| 128M 大分区版 | `cudy_tr3000-mod` | U-Boot mod，ubi **112M**（mod-112m 方案） | 需先写第三方大分区 U-Boot，刷机时选 `mod-112m` 布局 |
| 256M 标准版 | `cudy_tr3000-256mb-v1` | 原厂布局，ubi 230M | 官方 256M 过渡固件后 LuCI 刷入 |
| 256M 大分区版 | `cudy_tr3000-256mb-mod` | U-Boot mod，ubi **240M**（实验性） | 从 256M 标准版系统直接 sysupgrade，重启后自动扩展 |

- **内置主题**：4 款固件均内置 **Argon 主题**并自动设为默认。
- **内置插件**：128M 大分区版 / 256M 大分区版 / 256M 标准版内置 18 款常用插件（详见"内置主题与插件"章节）；
  128M 标准版空间有限（可用约 45M）仅内置主题。

产出的固件文件名（Releases / Artifacts 中）：

```
openwrt-mediatek-filogic-cudy_tr3000-v1-squashfs-sysupgrade.bin
openwrt-mediatek-filogic-cudy_tr3000-mod-squashfs-sysupgrade.bin
openwrt-mediatek-filogic-cudy_tr3000-256mb-v1-squashfs-sysupgrade.bin
openwrt-mediatek-filogic-cudy_tr3000-256mb-mod-squashfs-sysupgrade.bin
```

## 目录结构

```
.
├── .github/workflows/build.yml        # GitHub Actions 自动构建工作流
├── configs/tr3000.config              # 构建配置（目标平台、设备选择、软件包）
├── device-files/                      # 大分区(mod)设备定义（上游源码没有，编译前注入）
│   ├── mt7981b-cudy-tr3000-mod.dts            # 128M：ubi 0x5c0000 + 112MiB
│   ├── mt7981b-cudy-tr3000-256mb-mod.dts      # 256M：ubi 0x5c0000 + 240MiB
│   ├── filogic-cudy_tr3000-mod.mk             # 128M 大分区设备定义
│   └── filogic-cudy_tr3000-256mb-mod.mk       # 256M 大分区设备定义
├── scripts/
│   ├── diy-part1.sh                   # feeds 更新前：追加软件源、注入设备 DTS/定义与内置插件
│   └── diy-part2.sh                   # feeds 安装后：应用 files/ 自定义 overlay
└── files/                             # 自定义文件（编译进固件）
    └── etc/uci-defaults/99-tr3000-defaults
```

## 内置主题与插件

**主题**（4 款固件均内置）

- [luci-theme-argon](https://github.com/jerrykuku/luci-theme-argon)：编译期启用；首次启动由
  `files/etc/uci-defaults/99-tr3000-defaults` 执行 `uci set luci.main.mediaurlbase='/luci-static/argon'`
  将其设为默认主题。

**插件**（128M 大分区版 / 256M 大分区版 / 256M 标准版内置，共 18 款）

| 类别 | 插件 |
|---|---|
| 代理 | PassWall2（含 `xray-core` 内核）、OpenClash |
| 网络共享 | Samba4、ksmbd、vsftpd、WebDAV |
| 云盘 / 终端 | LinkEase（易有云）、ttyd（网页终端）、iStore 应用商店 |
| 存储 | DiskMan、hd-idle（附 USB 存储与 ext4/vfat 内核模块） |
| 网络工具 | DDNS、DDNS-Go、netdata、arpbind |
| VPN | WireGuard（`luci-proto-wireguard` + `wireguard-tools`）、SoftEther VPN |
| 其它 | oaf（应用过滤） |

实现方式与说明：

- 插件清单统一维护在 `scripts/diy-part1.sh` 的 `TR3000_PLUGINS`，通过设备级 `DEVICE_PACKAGES`
  安装（128M 标准版不受影响）：
  - 两个大分区设备：编译前注入定义后统一追加；
  - 256M 标准版（`cudy_tr3000-256mb-v1`）：编译前向官方设备定义追加。
- 插件来自聚合软件源 [kiddin9/op-packages](https://github.com/kiddin9/op-packages)，
  由 `diy-part1.sh` 自动追加到 `feeds.conf.default`。
- OpenClash 依赖 `dnsmasq-full`：`configs/tr3000.config` 已全局替换默认 `dnsmasq`，避免依赖冲突。
- PassWall2 以设备级方式安装时不会自动捆绑代理内核，因此显式内置 `xray-core`；
  如需 `sing-box`（约 19M）或 `hysteria`（约 8M），在 `TR3000_PLUGINS` 中追加包名即可。
- 编译工作流会在 `make defconfig` 后、正式编译前校验以上软件包是否存在，缺包快速失败并提示。

## 使用方法

1. 将本项目推送到 GitHub 仓库（默认分支 `main`）：
   ```bash
   git init -b main
   git add .
   git commit -m "init: TR3000 firmware auto build"
   git remote add origin https://github.com/<你的用户名>/<仓库名>.git
   git push -u origin main
   ```
2. 首次构建建议手动触发：仓库 **Actions → Build Cudy TR3000 Firmware → Run workflow**，
   勾选 “构建完成后发布到 GitHub Releases”（默认开启）。
3. 构建约需 2~4 小时。完成后：
   - Artifacts：Actions 页面下载 `cudy-tr3000-firmware-*`；
   - Releases：自动创建 `tr3000-日期-r版本号` 的发布页（包含 4 款固件与 SHA256 校验）。
4. 自动构建时机：推送代码、每周日 22:30（UTC）定时、手动触发。

## 自定义

| 需求 | 修改位置 |
|---|---|
| 增删内置插件 | `scripts/diy-part1.sh` 的 `TR3000_PLUGINS`（大分区版 + 256M 标准版；须保持单行）或 `configs/tr3000.config`（全部机型，添加 `CONFIG_PACKAGE_xxx=y`） |
| 更换/追加主题 | `configs/tr3000.config` 启用主题包 + `files/etc/uci-defaults/99-tr3000-defaults` 修改 `mediaurlbase` |
| 默认主机名/时区/关闭 WiFi 等 | `files/etc/uci-defaults/99-tr3000-defaults` |
| 调整大分区大小 | `device-files/*-mod.dts` 中 `&ubi { reg = <起始 大小>; }`，并同步 `device-files/*-mod.mk` 的 `IMAGE_SIZE` |
| 更换源码分支/版本 | `.github/workflows/build.yml` 中 `git clone --branch openwrt-25.12` |
| 编译内核版本 | 默认跟随分支；可在 config 中调整内核相关配置 |

## 刷机说明（重要）

> 改 U-Boot / 分区有变砖风险。刷机前务必备份全部分区（至少 BL2、FIP、factory），风险自负。

**128M 标准版 / 256M 标准版（原厂布局）**

1. 原厂系统刷入 Cudy 官方 OpenWrt 中间固件（128M 与 256M 版本不可混用）；
2. 登录 192.168.1.1（过渡系统的 LuCI），在“系统 → 备份与升级”中刷入对应标准版固件即可。

**128M 大分区版（112M / mod-112m）**

1. 原厂过渡固件中先备份 FIP，并写入第三方大分区 U-Boot（社区“中文三分区 uboot”等方案）；
2. 进入 U-Boot Web 刷机页（192.168.1.1），选择 **mod-112m** 分区布局；
3. 刷入 `cudy_tr3000-mod` 大分区固件。后续升级直接刷新的同布局 sysupgrade 即可。

**256M 大分区版（240M，实验性）**

1. 先将机器刷到 **256M 标准版** 固件并正常运行；
2. 在 LuCI 中直接 sysupgrade 刷入 `cudy_tr3000-256mb-mod` 固件（不勾选保留配置亦可）；
3. 重启后 ubi 分区自动由 230M 扩展到 240M（可 SSH 执行 `ubinfo -a` 确认）；
4. 如需回退：直接 sysupgrade 刷回 256M 标准版固件。

## 注意事项

- **新 Flash 批次（SN 2544 及以后，2025 年 11 月后生产）**：必须使用新版官方中间固件与新版固件；
  旧版中间固件、旧 FIP 破解包不兼容新 Flash（F50L1G41LC），切勿混刷。
- 大分区固件的可用空间除分区大小外，还取决于固件本身体积；内置插件会显著增大固件体积，
  3 款含插件固件的剩余 overlay 空间相应变小，如空间不足可精简 `TR3000_PLUGINS` 或将插件装到 U 盘。
- 定时构建跟随时上游分支更新（`git clone --depth=1`），上游代码变更可能偶发构建失败，
  重新触发即可；修复类改动欢迎提交 PR。

## 参考资料与致谢

- [OpenWrt 官方仓库](https://github.com/openwrt/openwrt)（mediatek/filogic 目标与 cudy_tr3000 设备定义）
- [Kwrt (openwrt.ai)](https://github.com/kiddin9/Kwrt)：项目思路来源
- [kiddin9/op-packages](https://github.com/kiddin9/op-packages)：聚合插件软件源（本项目内置插件来源）
- [OpenWrt Wiki: Cudy TR3000](https://openwrt.org/toh/cudy/tr3000)：机型与刷机参考
- 恩山/社区关于 mod-112m 大分区方案的公开教程

## 免责声明

本项目仅提供固件编译流程，刷机造成的一切后果由使用者自行承担。
