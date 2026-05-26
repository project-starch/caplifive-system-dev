#!/usr/bin/env bash
# Build the Caplifive-QEMU emulator and install it into hw/qemu/installation/.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT/hw/qemu"

sh configure.sh
make -C build install -j"$(nproc)"

# Point qemu-args.txt at the buildroot tree inside this repo.
sed -i 's:caplifive-buildroot:../sw/buildroot:' qemu-args.txt

echo "QEMU build complete: hw/qemu/installation/bin/qemu-system-riscv64"
