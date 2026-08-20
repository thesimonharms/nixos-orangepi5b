#!/usr/bin/env bash
set -euo pipefail

# Script to build NixOS image for Orange Pi 5B using isolated Docker environment
# (No Nix or build packages required on the host system)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

# Ensure Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "Error: Docker daemon is not running or current user lacks permissions." >&2
    exit 1
fi

# Ensure binfmt for aarch64 is registered
if [ ! -f /proc/sys/fs/binfmt_misc/qemu-aarch64 ]; then
    echo "Setting up QEMU aarch64 binfmt..."
    docker run --rm --privileged tonistiigi/binfmt --install arm64 >/dev/null
fi

# Ensure persistent Docker volumes for nix store and evaluation cache
docker volume create nix-store-cache >/dev/null
docker volume create nix-root-cache >/dev/null

mkdir -p "${SCRIPT_DIR}/output"

echo "Building NixOS SD Image for Orange Pi 5B in isolated container..."
docker run --rm \
    -v nix-store-cache:/nix \
    -v nix-root-cache:/root \
    -v "${SCRIPT_DIR}":/workspace \
    -w /workspace \
    nixos/nix \
    nix \
    --extra-experimental-features "nix-command flakes" \
    --extra-platforms "aarch64-linux arm-linux" \
    build \
    --out-link result-sd-image \
    .#images.orangepi5b

echo "Copying generated image to output/ directory..."
docker run --rm \
    -v nix-store-cache:/nix \
    -v "${SCRIPT_DIR}":/workspace \
    alpine:latest \
    sh -c "cp /workspace/result-sd-image/sd-image/* /workspace/output/ && chown -R $(id -u):$(id -g) /workspace/output /workspace/flake.lock"

echo "==> Build complete! Output image:"
ls -lh "${SCRIPT_DIR}/output/"
