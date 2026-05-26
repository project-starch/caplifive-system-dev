#!/usr/bin/env bash
# Build and install the AnvilHDL compiler from hw/anvil.
# Requires opam and OCaml 5.2+ (provided by the container, or install locally).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT/hw/anvil"

opam install . --deps-only --yes
eval "$(opam env)"
dune build --release
opam install . --yes

echo "Anvil installed. Verify with: anvil --version"
