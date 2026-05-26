#!/usr/bin/env bash
# Run RTL synthesis to produce the FPGA bitstream.
# Requires VIVADO_HOME to point to a Vivado installation with a valid licence.
#
# Usage: build-rtl.sh [--container]
#   --container  Run synthesis inside the build container. Vivado is
#                bind-mounted so that anvil and Vivado share the same
#                environment. Use this when anvil was built with
#                run-in-container.sh / build-anvil.sh.
#                Without the flag, anvil and Vivado must be on the host PATH.
set -euo pipefail

if [[ -z "${VIVADO_HOME:-}" ]]; then
    echo "Error: VIVADO_HOME is not set." >&2
    echo "Export it before running this script:" >&2
    echo "  export VIVADO_HOME=/path/to/vivado" >&2
    exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ "${1:-}" == "--container" ]]; then
    podman run --rm -it \
        -v caplifive-opam:/root/.opam \
        -v "$REPO_ROOT":/workspace:Z \
        -v "$VIVADO_HOME":"$VIVADO_HOME":ro \
        -e VIVADO_HOME="$VIVADO_HOME" \
        caplifive-build:latest \
        bash -c "cd /workspace/hw/rtl && bash run-synthesis.sh"
else
    cd "$REPO_ROOT/hw/rtl"
    bash run-synthesis.sh
fi

echo "Synthesis complete. Bitstream: hw/rtl/corev_apu/fpga/work-fpga/ariane_xilinx.bit"
