#!/bin/bash
# Setup script for ZBT Z8102AX-V2 eMMC OpenWrt/ImmortalWrt configuration
# Usage: ./setup.sh <path-to-openwrt-source>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Target OpenWrt/ImmortalWrt directory
OPENWRT_DIR="${1:-}"

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    cat << EOF
ZBT Z8102AX-V2 eMMC OpenWrt Configuration Setup Script

Usage: $0 <path-to-openwrt-source>

Arguments:
  path-to-openwrt-source    Path to your OpenWrt/ImmortalWrt source directory

Examples:
  $0 ~/openwrt
  $0 ~/immortalwrt

This script will:
  1. Validate the OpenWrt/ImmortalWrt source directory
  2. Copy the device tree (DTS) file
  3. Append the device configuration to filogic.mk
  4. Create a backup of modified files

For more information, see docs/BUILD_GUIDE.md
EOF
}

# Check if help is requested
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]] || [[ -z "$1" ]]; then
    show_usage
    exit 0
fi

# Validate OpenWrt directory
if [ ! -d "$OPENWRT_DIR" ]; then
    print_error "Directory does not exist: $OPENWRT_DIR"
    exit 1
fi

if [ ! -d "$OPENWRT_DIR/target/linux/mediatek" ]; then
    print_error "Not a valid OpenWrt/ImmortalWrt source directory"
    print_error "Missing: $OPENWRT_DIR/target/linux/mediatek"
    exit 1
fi

print_info "OpenWrt/ImmortalWrt directory: $OPENWRT_DIR"
print_info "Configuration repository: $SCRIPT_DIR"

# Create backup directory
BACKUP_DIR="$OPENWRT_DIR/.z8102ax-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
print_info "Backup directory: $BACKUP_DIR"

# Copy DTS file
DTS_SOURCE="$SCRIPT_DIR/target/linux/mediatek/dts/mt7981b-zbt-z8102ax-emmc.dts"
DTS_TARGET="$OPENWRT_DIR/target/linux/mediatek/dts/mt7981b-zbt-z8102ax-emmc.dts"

print_info "Copying DTS file..."

if [ ! -f "$DTS_SOURCE" ]; then
    print_error "DTS file not found: $DTS_SOURCE"
    exit 1
fi

# Backup existing DTS if it exists
if [ -f "$DTS_TARGET" ]; then
    print_warning "DTS file already exists, creating backup..."
    cp "$DTS_TARGET" "$BACKUP_DIR/mt7981b-zbt-z8102ax-emmc.dts.bak"
fi

cp "$DTS_SOURCE" "$DTS_TARGET"
print_info "✓ DTS file copied successfully"

# Append device definition to filogic.mk
MAKEFILE_SOURCE="$SCRIPT_DIR/target/linux/mediatek/image/filogic.mk"
MAKEFILE_TARGET="$OPENWRT_DIR/target/linux/mediatek/image/filogic.mk"

print_info "Adding device definition to filogic.mk..."

if [ ! -f "$MAKEFILE_SOURCE" ]; then
    print_error "Device configuration not found: $MAKEFILE_SOURCE"
    exit 1
fi

if [ ! -f "$MAKEFILE_TARGET" ]; then
    print_error "Target Makefile not found: $MAKEFILE_TARGET"
    exit 1
fi

# Backup Makefile
print_info "Creating backup of filogic.mk..."
cp "$MAKEFILE_TARGET" "$BACKUP_DIR/filogic.mk.bak"

# Check if device is already defined
if grep -q "zbtlink_z8102ax-v2-emmc" "$MAKEFILE_TARGET"; then
    print_warning "Device definition already exists in filogic.mk"
    print_warning "Skipping device definition to avoid duplication"
else
    # Append device definition
    echo "" >> "$MAKEFILE_TARGET"
    echo "# ZBT Z8102AX-V2 eMMC - Added by setup script" >> "$MAKEFILE_TARGET"
    cat "$MAKEFILE_SOURCE" >> "$MAKEFILE_TARGET"
    print_info "✓ Device definition added successfully"
fi

# Summary
cat << EOF

${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}
${GREEN}Setup completed successfully!${NC}
${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}

Files modified:
  1. $DTS_TARGET
  2. $MAKEFILE_TARGET

Backups created in: $BACKUP_DIR

${YELLOW}Next steps:${NC}
  1. cd $OPENWRT_DIR
  2. Update feeds:
     ./scripts/feeds update -a
     ./scripts/feeds install -a
  3. Configure build:
     make menuconfig
     -> Target System: MediaTek Ralink ARM
     -> Subtarget: Filogic 8x0 (MT798x)
     -> Target Profile: ZBT Z8102AX-V2 (eMMC)
  4. Build:
     make download -j\$(nproc)
     make -j\$(nproc) || make -j1 V=s

${YELLOW}Documentation:${NC}
  - Build guide: $SCRIPT_DIR/docs/BUILD_GUIDE.md
  - Partition layout: $SCRIPT_DIR/docs/PARTITION_LAYOUT.md

${YELLOW}Support:${NC}
  - Issues: https://github.com/xyzy12345/Z8102AX-V2-emmc/issues
  - OpenWrt Forum: https://forum.openwrt.org/

${GREEN}Happy building! 🚀${NC}

EOF
