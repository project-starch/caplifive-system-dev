#!/usr/bin/env bash
# Build the software stack (Linux kernel + OpenSBI + rootfs) via buildroot.
#
# Usage: build-software.sh [--mode qemu|fpga]
#   --mode qemu  (default) Build images for QEMU emulation.
#   --mode fpga           Build boot images for FPGA (includes LINUX_PAYLOAD).
set -euo pipefail

MODE=qemu

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode) MODE="$2"; shift 2 ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BR="$REPO_ROOT/sw/buildroot"

case "$MODE" in
    qemu)
        DEFCONFIG="$BR/configs/qemu_capstone_defconfig"
        cd "$BR"
        make setup DEFCONFIG="$DEFCONFIG"
        make build DEFCONFIG="$DEFCONFIG"
        echo "Software build (QEMU) complete: sw/buildroot/build/images/"
        ;;
    fpga)
        cd "$BR"
        make setup
        make build
        make build LINUX_PAYLOAD=1
        echo "Software build (FPGA) complete: sw/buildroot/build/images/"
        echo "Boot image: sw/buildroot/build/opensbi-custom/build/platform/generic/firmware/fw_payload.bin"
        ;;
    *)
        echo "Unknown mode '$MODE'. Use --mode qemu or --mode fpga." >&2
        exit 1
        ;;
esac
