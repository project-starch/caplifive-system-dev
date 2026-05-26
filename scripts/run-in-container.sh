#!/usr/bin/env bash
# Usage: scripts/run-in-container.sh <command> [args...]
# Runs the given command inside the caplifive-build container with the repo
# mounted at /workspace.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <command> [args...]" >&2
    exit 1
fi

podman run --rm -it \
    -v caplifive-opam:/root/.opam \
    -v "$REPO_ROOT":/workspace:Z \
    -e CAPSTONE_CC_PATH=/workspace/sw/capstone-c \
    caplifive-build:latest \
    bash -c "cd /workspace && $*"
