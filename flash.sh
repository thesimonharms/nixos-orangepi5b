#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Flashing helper script for Orange Pi 5B NixOS images
# Flashes built .img or .img.zst directly to an SD card or eMMC reader
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: sudo $0 /dev/sdX [IMAGE_PATH]"
    echo ""
    echo "Arguments:"
    echo "  /dev/sdX    Target SD card or eMMC block device (e.g. /dev/sdb, /dev/mmcblk0)"
    echo "  IMAGE_PATH  (Optional) Path to specific .img or .img.zst image to flash"
    echo ""
    echo "Available block devices on your system:"
    lsblk -d -o NAME,SIZE,TYPE,TRAN,MODEL 2>/dev/null || true
    exit 1
fi

TARGET_DEV="$1"
IMG_FILE="${2:-}"

# Auto-detect image if not specified
if [ -z "${IMG_FILE}" ]; then
    if [ -d "${SCRIPT_DIR}/output" ]; then
        # Pick latest modified image in output/
        IMG_FILE=$(find "${SCRIPT_DIR}/output" -type f \( -name "*.img" -o -name "*.img.zst" \) -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n 1 | awk '{print $2}')
    fi

    if [ -z "${IMG_FILE}" ] && [ -d "${SCRIPT_DIR}/result-sd-image/sd-image" ]; then
        IMG_FILE=$(find "${SCRIPT_DIR}/result-sd-image/sd-image" -type f \( -name "*.img" -o -name "*.img.zst" \) | head -n 1)
    fi
fi

if [ -z "${IMG_FILE}" ] || [ ! -f "${IMG_FILE}" ]; then
    echo "Error: No .img or .img.zst file found. Please run ./build.sh first or provide image path." >&2
    exit 1
fi

if [ ! -b "${TARGET_DEV}" ]; then
    echo "Error: '${TARGET_DEV}' is not a valid block device." >&2
    exit 1
fi

echo "========================================================="
echo " Target Device: ${TARGET_DEV}"
echo " Source Image:  ${IMG_FILE}"
echo " Size:          $(ls -lh "${IMG_FILE}" | awk '{print $5}')"
echo "========================================================="
echo "WARNING: ALL EXISTING DATA ON ${TARGET_DEV} WILL BE COMPLETELY OVERWRITTEN!"
read -p "Are you sure you want to proceed? [y/N] " -r CONFIRM
if [[ ! "${CONFIRM}" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo "Flashing image to ${TARGET_DEV}..."

if [[ "${IMG_FILE}" == *.zst ]]; then
    if command -v zstdcat >/dev/null 2>&1; then
        zstdcat "${IMG_FILE}" | dd of="${TARGET_DEV}" bs=4M status=progress conv=fsync
    elif command -v zstd >/dev/null 2>&1; then
        zstd -dc "${IMG_FILE}" | dd of="${TARGET_DEV}" bs=4M status=progress conv=fsync
    else
        echo "zstd not found on host, decompressing via container..."
        IMG_DIR=$(dirname "${IMG_FILE}")
        IMG_BASE=$(basename "${IMG_FILE}")
        docker run --rm -v "${IMG_DIR}:/workspace" alpine:latest sh -c "apk add --no-cache zstd >/dev/null 2>&1 && zstdcat /workspace/${IMG_BASE}" | dd of="${TARGET_DEV}" bs=4M status=progress conv=fsync
    fi
else
    dd if="${IMG_FILE}" of="${TARGET_DEV}" bs=4M status=progress conv=fsync
fi

sync
echo "==> Flashing complete! You can now safely remove and insert the SD card into your Orange Pi 5B."
