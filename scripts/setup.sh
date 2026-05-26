#!/usr/bin/env bash
# Initialise all submodules. Run once after cloning.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

git submodule update --init --recursive

# Source Rust environment if available outside the container.
if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
fi
