#!/usr/bin/env bash
# Start the QEMU emulator using the built images.
# Run build-qemu.sh and build-software.sh --mode qemu first.
#
# Usage: run.sh [--container]
#   --container  Run QEMU inside the build container. Use this when the binary
#                was built with run-in-container.sh, to avoid shared library
#                mismatches (e.g. libslirp). Host port 60022 -> guest port 22.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ "${1:-}" == "--container" ]]; then
    podman run --rm -it \
        -v "$REPO_ROOT":/workspace:Z \
        -p 60022:60022 \
        caplifive-build:latest \
        bash -c "cd /workspace/hw/qemu && ./start.sh"
else
    cd "$REPO_ROOT/hw/qemu"
    ./start.sh
fi
