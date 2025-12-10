# ZBT Z8102AX-V2 eMMC 改装版 OpenWrt/ImmortalWrt 配置

为 ZBT Z8102AX-V2 eMMC 改装版编译 OpenWrt、ImmortalWrt 固件的完整配置文件。

## 设备信息

- **设备型号**: ZBT Z8102AX-V2 (eMMC 改装版)
- **SoC**: MediaTek MT7981B (双核 ARM Cortex-A53 @ 1.3GHz)
- **存储**: 128GB eMMC
- **内存**: 1GB DDR4 (实际配置可能不同)
- **无线**: MediaTek MT7981 (2.4GHz + 5GHz, WiFi 6)
- **以太网**: 
  - 1x 2.5GbE WAN/LAN
  - 4x 1GbE LAN
  - 集成 MediaTek MT7531 交换芯片
- **USB**: 2x USB 3.0
- **按键**: Reset, Mesh/WPS
- **LED**: 状态指示灯 (红/绿/蓝)、4G 指示灯
- **其他**: 4/5G LTE 模块支持 (可选)

## 分区布局

```
Disklabel type: gpt
Device            Start       End   Sectors  Size Type
/dev/mmcblk0p1        0        33        34   17K Linux filesystem (GPT/Preloader)
/dev/mmcblk0p2     8192      9215      1024  512K ARM Trusted Firmware (BL2)
/dev/mmcblk0p3     9216     13311      4096    2M U-Boot Environment
/dev/mmcblk0p4    13312     17407      4096    2M Factory Data (Calibration)
/dev/mmcblk0p5    17408     82943     65536   32M FIP (U-Boot + BL31)
/dev/mmcblk0p6    82944  14680064  14597121    7G System (UBI/SquashFS)
/dev/mmcblk0p7 14680065 234881024 220200960  105G User Data (ext4/f2fs)
```

详细分区说明请参考：[分区布局文档](docs/PARTITION_LAYOUT.md)

## 快速开始

### 1. 获取 OpenWrt/ImmortalWrt 源码

```bash
# OpenWrt 官方版本
git clone https://git.openwrt.org/openwrt/openwrt.git
cd openwrt

# 或 ImmortalWrt
git clone https://github.com/immortalwrt/immortalwrt.git
cd immortalwrt
```

### 2. 应用设备配置

```bash
# 克隆本仓库
git clone https://github.com/xyzy12345/Z8102AX-V2-emmc.git

# 复制 DTS 文件
cp Z8102AX-V2-emmc/target/linux/mediatek/dts/mt7981b-zbt-z8102ax-emmc.dts \
   openwrt/target/linux/mediatek/dts/

# 追加设备定义到 filogic.mk
cat Z8102AX-V2-emmc/target/linux/mediatek/image/filogic.mk \
    >> openwrt/target/linux/mediatek/image/filogic.mk
```

### 3. 配置和编译

```bash
cd openwrt

# 更新 feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 配置编译选项
make menuconfig

# 在 menuconfig 中选择:
# Target System: MediaTek Ralink ARM
# Subtarget: Filogic 8x0 (MT798x)
# Target Profile: ZBT Z8102AX-V2 (eMMC)

# 开始编译
make download -j$(nproc)
make -j$(nproc) || make -j1 V=s
```

完整编译指南请参考：[编译指南](docs/BUILD_GUIDE.md)

## 刷机方法

### 方法 1: Sysupgrade (推荐，用于升级)

```bash
# 上传固件到设备
scp openwrt-*-sysupgrade.bin root@192.168.1.1:/tmp/

# 执行升级
ssh root@192.168.1.1
sysupgrade -v /tmp/openwrt-*-sysupgrade.bin
```

### 方法 2: U-Boot 网络刷机

通过串口进入 U-Boot，使用 TFTP 下载并刷写固件。详见 [编译指南](docs/BUILD_GUIDE.md#方法-2-u-boot-网络刷机)。

### 方法 3: MTK 烧录工具

用于首次刷机或救砖，需要专用 USB 线缆和 SP Flash Tool。

## 固件特性

### 已集成软件包

- **WiFi 驱动**: kmod-mt7915e, mt7981-firmware
- **USB 支持**: kmod-usb3, kmod-usb2
- **文件系统**: ext4, f2fs
- **性能优化**: MTK PPE 硬件加速
- **监控工具**: hwmon-pwmfan (风扇控制)

### 推荐额外安装

- **Docker**: 容器化应用支持（利用 105GB 数据分区）
- **LuCI**: Web 管理界面
- **VPN**: OpenVPN, WireGuard, Tailscale
- **网络工具**: tcpdump, iperf3, mtr

## 首次启动配置

### 1. 网络连接

- **默认 IP**: 192.168.1.1
- **用户名**: root
- **密码**: 无（首次登录需设置）

### 2. 挂载数据分区

```bash
# 格式化 105GB 数据分区
mkfs.ext4 /dev/mmcblk0p7

# 创建挂载点并挂载
mkdir -p /opt
mount /dev/mmcblk0p7 /opt

# 添加到 fstab
echo "/dev/mmcblk0p7 /opt ext4 defaults 0 0" >> /etc/fstab
```

### 3. 配置无线

通过 LuCI (http://192.168.1.1) 或编辑 `/etc/config/wireless` 配置 WiFi。

## 文档

- [分区布局说明](docs/PARTITION_LAYOUT.md) - 详细的 GPT 分区表和 DTS 配置说明
- [编译指南](docs/BUILD_GUIDE.md) - 完整的编译和刷机指南
- [故障排除](docs/BUILD_GUIDE.md#故障排除) - 常见问题解决方案

## 文件结构

```
Z8102AX-V2-emmc/
├── README.md                                    # 本文件
├── docs/
│   ├── PARTITION_LAYOUT.md                     # 分区布局说明
│   └── BUILD_GUIDE.md                          # 编译指南
└── target/
    └── linux/
        └── mediatek/
            ├── dts/
            │   └── mt7981b-zbt-z8102ax-emmc.dts  # 设备树源文件
            └── image/
                └── filogic.mk                     # 设备定义 (Makefile)
```

## 技术特点

### 固定分区表设计

本配置使用 Device Tree 的 `fixed-partitions` 定义分区表，而非动态生成 GPT。

**优势**:
- ✅ 支持非标准分区布局
- ✅ 与原厂固件兼容
- ✅ 支持超大分区 (>4GB)
- ✅ 灵活可定制

**与标准方案的区别**:
- ❌ 不使用 `mt798x-gpt` 生成器
- ❌ 无 Recovery 分区
- ✅ 7GB 系统分区（标准通常 <256MB）
- ✅ 105GB 数据分区（适合 Docker/容器应用）

### eMMC 性能优化

- 使用 HS200 模式 (200MHz)
- 8-bit 总线宽度
- 支持硬件 ECC
- 完整的电源管理

## 开发资源

### 参考设备

本配置参考了以下 OpenWrt 设备实现：
- glinet_gl-x3000
- glinet_gl-xe3000
- huasifei_wh3000
- unielec_u7981-01-emmc

### 相关项目

- [OpenWrt 官方](https://openwrt.org/)
- [ImmortalWrt](https://github.com/immortalwrt/immortalwrt)
- [MediaTek Filogic SDK](https://www.mediatek.com/)

### 社区讨论

- [OpenWrt Forum - ZBT Z8102AX](https://forum.openwrt.org/t/adding-openwrt-support-for-zbt-z8102ax/171248)
- [OpenMPTCProuter - eMMC 支持讨论](https://github.com/Ysurac/openmptcprouter/discussions/3698)

## 注意事项

### ⚠️ 重要提醒

1. **备份 Factory 分区**: 首次刷机前务必备份 factory 分区（包含 MAC 地址和 WiFi 校准数据）
   ```bash
   dd if=/dev/mmcblk0p4 of=/tmp/factory.bin bs=512
   ```

2. **不要使用标准 GPT 生成器**: 本设备使用固定分区表，与 OpenWrt 标准 MT7981 布局不兼容

3. **数据分区格式化**: 首次使用需手动格式化和挂载 105GB 数据分区

4. **串口访问**: 建议准备 USB 转 TTL 线缆以便调试和救砖

### ✅ 兼容性

- ✅ OpenWrt 23.05 及更新版本
- ✅ ImmortalWrt 23.05 及更新版本
- ✅ OpenWrt Snapshot (主分支)

## 贡献

欢迎提交 Issue 和 Pull Request！

### 如何贡献

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 开启 Pull Request

## 许可证

本项目采用 GPL-2.0 许可证，与 OpenWrt/ImmortalWrt 保持一致。

## 致谢

-by 信仰之跃提供dts原始验证文件
- OpenWrt 和 ImmortalWrt 社区
- MediaTek 提供的 Filogic SDK
- 所有为 ZBT 设备支持做出贡献的开发者

## 更新日志

### 2025-12-10
- 初始版本发布
- 添加 MT7981B ZBT Z8102AX-V2 eMMC 设备支持
- 完整的 DTS 配置和分区布局
- 详细的编译和刷机文档

---

**免责声明**: 刷机有风险，操作需谨慎。请确保理解每个步骤的含义，并做好备份工作。本项目作者不对任何因使用本配置导致的设备损坏负责。
