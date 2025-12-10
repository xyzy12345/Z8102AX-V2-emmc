# ZBT Z8102AX-V2 eMMC 分区布局说明

## 设备信息

- **设备型号**: ZBT Z8102AX-V2 (eMMC 改装版)
- **SoC**: MediaTek MT7981B
- **eMMC 容量**: 128GB
- **分区表类型**: GPT (GUID Partition Table)
- **扇区大小**: 512 bytes

## GPT 分区布局

基于用户提供的分区表：

```
Disklabel type: gpt
Device            Start       End   Sectors  Size Type
/dev/mmcblk0p1        0        33        34   17K Linux filesystem
/dev/mmcblk0p2     8192      9215      1024  512K 
/dev/mmcblk0p3     9216     13311      4096    2M 
/dev/mmcblk0p4    13312     17407      4096    2M 
/dev/mmcblk0p5    17408     82943     65536   32M 
/dev/mmcblk0p6    82944  14680064  14597121    7G 
/dev/mmcblk0p7 14680065 234881024 220200960  105G 
```

## 分区功能说明

| 分区 | 起始扇区 | 结束扇区 | 大小 | 用途 | DTS 标签 | 只读 |
|------|---------|---------|------|------|----------|------|
| mmcblk0p1 | 0 | 33 | 17K | GPT 分区表头/预加载器 | gpt | 是 |
| mmcblk0p2 | 8192 | 9215 | 512K | ARM Trusted Firmware (BL2) | bl2 | 是 |
| mmcblk0p3 | 9216 | 13311 | 2M | U-Boot 环境变量 | u-boot-env | 否 |
| mmcblk0p4 | 13312 | 17407 | 2M | 工厂数据/校准数据 | factory | 是 |
| mmcblk0p5 | 17408 | 82943 | 32M | FIP (固件接口包) | fip | 是 |
| mmcblk0p6 | 82944 | 14680064 | 7GB | 系统分区 (UBI/SquashFS) | ubi | 否 |
| mmcblk0p7 | 14680065 | 234881024 | 105GB | 用户数据分区 | opt | 否 |

## 分区详细说明

### P1: GPT / Preloader (17KB)
- **用途**: 存储 GPT 分区表头和预加载器
- **重要性**: 引导系统的第一步
- **刷机**: 通常由 MTK 烧录工具写入

### P2: BL2 / ATF (512KB)
- **用途**: ARM Trusted Firmware BL2 (启动加载器第2阶段)
- **内容**: 
  - 初始化 DDR 内存
  - 加载并验证下一阶段固件
- **文件**: `emmc-preloader.bin`

### P3: U-Boot Environment (2MB)
- **用途**: 存储 U-Boot 环境变量
- **内容**:
  - 启动参数
  - 网络配置
  - 自定义启动脚本
- **可修改**: 是（通过 U-Boot 命令行）

### P4: Factory (2MB)
- **用途**: 工厂校准数据
- **内容**:
  - WiFi EEPROM 数据
  - MAC 地址
  - RF 校准参数
- **重要性**: 包含设备唯一数据，**不可覆盖**

### P5: FIP (32MB)
- **用途**: 固件接口包 (Firmware Interface Package)
- **内容**:
  - BL31 (ARM Trusted Firmware)
  - U-Boot
  - 设备树 Blob (DTB)
- **文件**: `emmc-bl31-uboot.fip`

### P6: UBI / System (7GB)
- **用途**: 主系统分区
- **文件系统**: UBI + SquashFS + overlay
- **内容**:
  - Linux 内核
  - Root 文件系统
  - OpenWrt/ImmortalWrt 系统
- **挂载点**: `/`

### P7: Opt / Data (105GB)
- **用途**: 用户数据分区
- **建议文件系统**: ext4 或 f2fs
- **用途建议**:
  - Docker 容器存储
  - 用户文件
  - 应用程序数据
  - 日志文件
- **挂载点**: `/opt` 或 `/mnt/data`

## DTS 分区定义方式

本设备使用 **固定分区表** (fixed-partitions) 而非动态生成 GPT：

```dts
&mmc0 {
    partitions {
        compatible = "fixed-partitions";
        #address-cells = <2>;
        #size-cells = <2>;
        
        partition@0 {
            label = "gpt";
            reg = <0x0 0x0 0x0 0x4400>;
            read-only;
        };
        
        partition@1 {
            label = "bl2";
            reg = <0x0 0x100000 0x0 0x80000>;
            read-only;
        };
        
        /* ... 其他分区 ... */
    };
};
```

### 为什么使用固定分区表？

1. **灵活性**: 可以自定义非标准分区布局
2. **兼容性**: 与原厂固件分区布局保持一致
3. **大容量支持**: 支持超过 4GB 的分区（使用 2-cell 地址）
4. **无需 GPT 生成**: 内核直接从 DTS 读取分区信息

### 地址计算公式

DTS 中的 `reg` 属性使用字节地址：

```
字节地址 = 扇区号 × 512
字节大小 = 扇区数 × 512
```

例如，mmcblk0p6:
- 起始: 82944 × 512 = 0xa200000
- 大小: 14597121 × 512 = 0x1bd800200

## 与标准 OpenWrt MT7981 布局的差异

标准 OpenWrt MT7981 eMMC 布局通常包含：
- Recovery 分区 (32MB @ 12MB)
- 较小的系统分区 (通常 < 256MB)

本设备特点：
- ❌ **无 Recovery 分区**
- ✅ **大容量系统分区** (7GB)
- ✅ **超大数据分区** (105GB)
- ✅ **适合运行容器化应用**

## 注意事项

### ⚠️ 备份 Factory 分区

在首次刷机前，务必备份 factory 分区：

```bash
# 在原厂固件下执行
dd if=/dev/mmcblk0p4 of=/tmp/factory.bin bs=512
# 将 factory.bin 保存到安全位置
```

### ⚠️ 不要使用标准 MT798x GPT 生成

OpenWrt 的 `mt798x-gpt emmc` 会生成包含 recovery 分区的标准布局，与本设备不兼容。

### ✅ 正确的构建方法

使用 DTS 固定分区表 + sysupgrade-tar 格式：

```makefile
IMAGES := sysupgrade.bin
IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
```

## 参考资料

- [OpenWrt MediaTek Filogic 目标](https://openwrt.org/docs/techref/targets/mediatek)
- [Device Tree 固定分区](https://www.kernel.org/doc/Documentation/devicetree/bindings/mtd/partition.txt)
- [MediaTek MT7981 数据手册](https://www.mediatek.com/)
