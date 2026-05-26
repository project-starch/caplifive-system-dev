#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

podman build \
    -t caplifive-build:latest \
    -f "$REPO_ROOT/scripts/Containerfile" \
    "$REPO_ROOT"

echo "Image built: caplifive-build:latest"

# Seed the opam volume from the image if it is empty or does not yet exist.
# Mounting an empty volume over /root/.opam would shadow the opam state baked
# into the image, so we pre-populate it here. Re-run this script after
# rebuilding the image to refresh the volume (anvil will need to be reinstalled).
podman volume create caplifive-opam 2>/dev/null || true
podman run --rm \
    -v caplifive-opam:/opam-vol \
    caplifive-build:latest \
    bash -c 'if [ -z "$(ls -A /opam-vol 2>/dev/null)" ]; then
        echo "Seeding caplifive-opam volume from image..."
        cp -a /root/.opam/. /opam-vol/
    fi'

echo "Volume ready: caplifive-opam"
