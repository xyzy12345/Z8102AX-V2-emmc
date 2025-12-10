# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2024 OpenWrt.org

# Device definition for ZBT Z8102AX-V2 eMMC
# This file should be included or appended to the main filogic.mk in OpenWrt/ImmortalWrt

define Device/zbtlink_z8102ax-v2-emmc
  DEVICE_VENDOR := ZBT
  DEVICE_MODEL := Z8102AX-V2
  DEVICE_VARIANT := eMMC
  DEVICE_DTS := mt7981b-zbt-z8102ax-emmc
  DEVICE_DTS_DIR := ../dts
  SUPPORTED_DEVICES := zbtlink,z8102ax-v2-emmc
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 7340032k
  KERNEL_IN_UBI := 1
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware \
    kmod-usb3 kmod-usb2 kmod-mmc-mtk \
    kmod-fs-ext4 kmod-fs-f2fs e2fsprogs f2fsck mkf2fs \
    kmod-mtk-ppe kmod-hwmon-pwmfan
  IMAGES := sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  # Artifacts for initial flash
  ARTIFACTS := emmc-preloader.bin emmc-bl31-uboot.fip
  ARTIFACT/emmc-preloader.bin := mt7981-bl2 emmc-ddr4
  ARTIFACT/emmc-bl31-uboot.fip := mt7981-bl31-uboot zbtlink_z8102ax-v2-emmc
endef
TARGET_DEVICES += zbtlink_z8102ax-v2-emmc
