# ZBT Z8102AX-V2 eMMC OpenWrt/ImmortalWrt 编译指南

## 目录

- [准备工作](#准备工作)
- [获取源代码](#获取源代码)
- [应用设备配置](#应用设备配置)
- [配置编译选项](#配置编译选项)
- [开始编译](#开始编译)
- [刷机指南](#刷机指南)
- [故障排除](#故障排除)

## 准备工作

### 系统要求

- **操作系统**: Ubuntu 20.04/22.04 LTS、Debian 11/12 或其他 Linux 发行版
- **磁盘空间**: 至少 60GB 可用空间
- **内存**: 建议 8GB 或以上
- **网络**: 稳定的互联网连接

### 安装依赖

#### Ubuntu/Debian

```bash
sudo apt update
sudo apt install -y build-essential clang flex bison g++ gawk \
  gcc-multilib g++-multilib gettext git libncurses5-dev libssl-dev \
  python3-distutils rsync unzip zlib1g-dev file wget
```

#### Arch Linux

```bash
sudo pacman -S --needed base-devel ncurses zlib gawk git gettext \
  openssl libxslt wget unzip python
```

## 获取源代码

### 选项 1: OpenWrt 官方版本

```bash
# 克隆 OpenWrt 源代码（主分支）
git clone https://git.openwrt.org/openwrt/openwrt.git
cd openwrt

# 或者克隆特定版本（例如 23.05）
git clone -b openwrt-23.05 https://git.openwrt.org/openwrt/openwrt.git
cd openwrt
```

### 选项 2: ImmortalWrt

```bash
# 克隆 ImmortalWrt 源代码
git clone https://github.com/immortalwrt/immortalwrt.git
cd immortalwrt

# 或者克隆特定版本
git clone -b openwrt-23.05 https://github.com/immortalwrt/immortalwrt.git
cd immortalwrt
```

### 更新 Feeds

```bash
# 更新 feeds 列表
./scripts/feeds update -a

# 安装所有 feeds
./scripts/feeds install -a
```

## 应用设备配置

### 方法 1: 手动复制文件

从本仓库复制配置文件到 OpenWrt/ImmortalWrt 源码目录：

```bash
# 假设本仓库克隆在 ~/Z8102AX-V2-emmc
# OpenWrt 源码在 ~/openwrt

# 复制 DTS 文件
cp ~/Z8102AX-V2-emmc/target/linux/mediatek/dts/mt7981b-zbt-z8102ax-emmc.dts \
   ~/openwrt/target/linux/mediatek/dts/

# 将设备定义追加到 filogic.mk
cat ~/Z8102AX-V2-emmc/target/linux/mediatek/image/filogic.mk \
    >> ~/openwrt/target/linux/mediatek/image/filogic.mk
```

### 方法 2: 使用补丁

```bash
cd ~/openwrt

# 创建补丁文件
cat > /tmp/z8102ax-v2-emmc.patch << 'EOF'
--- /dev/null
+++ b/target/linux/mediatek/dts/mt7981b-zbt-z8102ax-emmc.dts
@@ -0,0 +1,XXX @@
+// (DTS 文件内容)
--- a/target/linux/mediatek/image/filogic.mk
+++ b/target/linux/mediatek/image/filogic.mk
@@ -XXX,X +XXX,XX @@
+(Makefile 新增内容)
EOF

# 应用补丁
patch -p1 < /tmp/z8102ax-v2-emmc.patch
```

### 方法 3: 使用脚本自动配置

创建一个自动化脚本：

```bash
#!/bin/bash
# setup-z8102ax.sh

set -e

OPENWRT_DIR=${1:-$(pwd)}
REPO_DIR="$(dirname "$(readlink -f "$0")")"

echo "OpenWrt 目录: $OPENWRT_DIR"
echo "配置仓库目录: $REPO_DIR"

# 检查目录是否存在
if [ ! -d "$OPENWRT_DIR/target/linux/mediatek" ]; then
    echo "错误: 不是有效的 OpenWrt 源码目录"
    exit 1
fi

# 复制 DTS 文件
echo "复制 DTS 文件..."
cp "$REPO_DIR/target/linux/mediatek/dts/mt7981b-zbt-z8102ax-emmc.dts" \
   "$OPENWRT_DIR/target/linux/mediatek/dts/"

# 追加设备定义
echo "添加设备定义..."
cat "$REPO_DIR/target/linux/mediatek/image/filogic.mk" \
    >> "$OPENWRT_DIR/target/linux/mediatek/image/filogic.mk"

echo "配置完成！"
echo "下一步: cd $OPENWRT_DIR && make menuconfig"
```

## 配置编译选项

```bash
cd ~/openwrt  # 或 ~/immortalwrt

# 进入配置菜单
make menuconfig
```

### 必选配置

在 menuconfig 界面中进行以下配置：

1. **目标平台选择**:
   ```
   Target System (MediaTek Ralink ARM)  --->
   Subtarget (Filogic 8x0 (MT798x))  --->
   Target Profile (ZBT Z8102AX-V2 (eMMC))  --->
   ```

2. **基础软件包** (已在设备定义中包含):
   - ✅ kmod-mt7915e (WiFi 驱动)
   - ✅ kmod-mt7981-firmware
   - ✅ kmod-usb3, kmod-usb2
   - ✅ kmod-mmc-mtk
   - ✅ kmod-fs-ext4, kmod-fs-f2fs

3. **额外推荐软件包**:
   ```
   Languages --->
       <*> python3
   
   LuCI --->
       Collections --->
           <*> luci
           <*> luci-ssl
       Applications --->
           <*> luci-app-firewall
           <*> luci-app-opkg
           <*> luci-app-dockerman (如需 Docker)
   
   Utilities --->
       <*> htop
       <*> fdisk
       <*> lsblk
       <*> parted
   
   Virtualization (如需容器支持) --->
       <*> docker
       <*> dockerd
       <*> docker-compose
   ```

### 保存配置

配置完成后：
- 按 `ESC` 键退出
- 选择 `Yes` 保存配置

配置会保存在 `.config` 文件中。

### 可选: 保存配置模板

```bash
# 将当前配置保存为 diffconfig
./scripts/diffconfig.sh > configs/z8102ax-v2-emmc.config

# 下次使用配置
cp configs/z8102ax-v2-emmc.config .config
make defconfig
```

## 开始编译

### 首次编译

```bash
# 下载所有依赖包（首次编译需要）
make download -j$(nproc)

# 开始编译（使用所有 CPU 核心）
make -j$(nproc) || make -j1 V=s
```

**说明**:
- `-j$(nproc)`: 使用所有 CPU 核心并行编译
- 如果出错，使用 `make -j1 V=s` 单线程编译并显示详细输出

### 编译时间

- **首次编译**: 2-6 小时（取决于硬件配置和网络速度）
- **后续编译**: 30 分钟 - 2 小时

### 仅编译固件（增量编译）

```bash
# 仅编译内核和固件
make target/linux/compile -j$(nproc)
make package/index
make package/install -j$(nproc)
make target/install -j$(nproc)
```

## 编译产物

编译完成后，固件文件位于：

```
bin/targets/mediatek/filogic/
├── openwrt-mediatek-filogic-zbtlink_z8102ax-v2-emmc-squashfs-sysupgrade.bin
├── mt7981-zbtlink_z8102ax-v2-emmc-emmc-preloader.bin
├── mt7981-zbtlink_z8102ax-v2-emmc-emmc-bl31-uboot.fip
├── sha256sums
└── (其他文件)
```

### 文件说明

| 文件 | 用途 | 使用场景 |
|------|------|---------|
| `*-sysupgrade.bin` | 系统升级固件 | 从 OpenWrt 升级到新版本 |
| `*-emmc-preloader.bin` | BL2 预加载器 | 首次刷机或救砖 |
| `*-emmc-bl31-uboot.fip` | U-Boot + BL31 | 首次刷机或救砖 |

## 刷机指南

### 方法 1: Sysupgrade (推荐，用于升级)

如果设备已经运行 OpenWrt/ImmortalWrt：

```bash
# 通过 SCP 上传固件到路由器
scp openwrt-*-sysupgrade.bin root@192.168.1.1:/tmp/

# SSH 登录到路由器
ssh root@192.168.1.1

# 执行升级
sysupgrade -v /tmp/openwrt-*-sysupgrade.bin
```

或通过 LuCI Web 界面：
1. 登录 LuCI (http://192.168.1.1)
2. 进入 `系统` → `备份/升级`
3. 上传 sysupgrade.bin 固件
4. 取消勾选 "保留配置"（首次刷机建议）
5. 点击 "刷写固件"

### 方法 2: U-Boot 网络刷机

1. **连接串口**:
   - 波特率: 115200
   - 数据位: 8
   - 停止位: 1
   - 无校验

2. **进入 U-Boot**:
   - 上电后按任意键进入 U-Boot 命令行

3. **配置网络**:
   ```
   setenv ipaddr 192.168.1.1
   setenv serverip 192.168.1.100
   ```

4. **通过 TFTP 下载固件**:
   ```
   # 确保 TFTP 服务器运行在 192.168.1.100
   tftpboot 0x46000000 openwrt-mediatek-filogic-zbtlink_z8102ax-v2-emmc-squashfs-sysupgrade.bin
   ```

5. **写入 eMMC**:
   ```
   mmc dev 0
   mmc write 0x46000000 0xa200 0x10000
   ```

6. **重启**:
   ```
   reset
   ```

### 方法 3: MTK 烧录工具（完全刷机）

用于首次刷机或救砖，需要：
- MTK Flash Tool (SP Flash Tool)
- 专用 USB 线缆
- Preloader 和 FIP 文件

详细步骤请参考 [MTK Flash Tool 使用指南](https://openwrt.org/docs/techref/hardware/soc/soc.mediatek.mtk)。

## 首次启动配置

### 1. 连接设备

刷机完成后，设备会自动重启：
- **默认 IP**: 192.168.1.1
- **用户名**: root
- **密码**: (无密码，首次登录会提示设置)

### 2. 挂载数据分区 (mmcblk0p7)

```bash
# SSH 登录到路由器
ssh root@192.168.1.1

# 格式化数据分区（仅首次）
mkfs.ext4 /dev/mmcblk0p7

# 创建挂载点
mkdir -p /opt

# 挂载分区
mount /dev/mmcblk0p7 /opt

# 添加到 fstab 实现自动挂载
echo "/dev/mmcblk0p7 /opt ext4 defaults 0 0" >> /etc/fstab

# 验证挂载
df -h /opt
```

### 3. 网络配置

编辑 `/etc/config/network`:

```bash
vi /etc/config/network
```

根据需要修改 LAN/WAN 配置。

### 4. 无线配置

```bash
# 编辑无线配置
vi /etc/config/wireless

# 或通过 LuCI 界面配置
```

## 故障排除

### 编译错误

#### 下载失败

```bash
# 清理下载缓存
rm -rf dl/*

# 重新下载
make download -j1 V=s
```

#### 编译失败

```bash
# 清理编译缓存
make clean

# 或完全清理（包括工具链）
make dirclean

# 重新编译
make -j1 V=s
```

### 刷机问题

#### 设备无法启动

1. 检查串口输出，确认错误信息
2. 尝试进入 U-Boot 修复
3. 使用 MTK Flash Tool 重新刷写 Preloader 和 FIP

#### 无法进入系统

1. 检查分区是否正确
2. 确认 factory 分区未损坏
3. 重新刷写完整固件

#### 网络无法连接

1. 检查网线连接
2. 确认 VLAN 配置正确
3. 查看 `/etc/config/network` 配置

### 常见问题

#### Q: 编译时提示 "No rule to make target"

A: 运行 `make defconfig` 重新生成配置。

#### Q: WiFi 无法使用

A: 确保已安装：
- kmod-mt7915e
- kmod-mt7981-firmware
- mt7981-wo-firmware

#### Q: USB 设备无法识别

A: 检查是否安装：
- kmod-usb3
- kmod-usb2
- kmod-usb-storage

#### Q: Docker 容器无法启动

A: 确保：
1. 已挂载大容量数据分区 (/opt)
2. 安装了 dockerd 和相关依赖
3. 内核支持必要的 cgroup 功能

## 进阶使用

### 自定义软件包

```bash
# 添加自定义 feed
echo "src-git custom https://github.com/your/custom-feed.git" >> feeds.conf.default
./scripts/feeds update custom
./scripts/feeds install -a -p custom
```

### 修改内核配置

```bash
make kernel_menuconfig
```

### 创建自定义镜像

```bash
# 使用 Image Builder
make image PROFILE=zbtlink_z8102ax-v2-emmc \
    PACKAGES="package1 package2 -package3"
```

## 参考资料

- [OpenWrt 官方文档](https://openwrt.org/docs/start)
- [ImmortalWrt 文档](https://github.com/immortalwrt/immortalwrt)
- [MediaTek MT7981 技术规格](https://www.mediatek.com/)
- [本仓库分区布局说明](docs/PARTITION_LAYOUT.md)

## 社区支持

- OpenWrt 论坛: https://forum.openwrt.org/
- ImmortalWrt 讨论组: https://github.com/immortalwrt/immortalwrt/discussions
- ZBT 设备讨论: https://github.com/xyzy12345/Z8102AX-V2-emmc/issues

## 许可证

本配置文件遵循 GPL-2.0 许可证，与 OpenWrt/ImmortalWrt 项目保持一致。
