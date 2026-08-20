#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# NixOS Image Builder for Orange Pi 5B
# Supports custom modules, embedded profiles, Wi-Fi/SSH injection, and Docker
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

TARGET="orangepi5b"
CUSTOM_FILE=""
WIFI_SPEC=""
SSH_KEY_INPUT=""
HOSTNAME_INPUT=""
EXTRA_PKGS=()
NATIVE_BUILD=false
OUTPUT_DIR="${SCRIPT_DIR}/output"

show_help() {
    cat <<EOF
Usage: ./build.sh [OPTIONS] [PROFILE]

Build flashable NixOS SD/eMMC images for the Orange Pi 5B (RK3588S).
Builds are isolated inside a container by default—no Nix installation required on host!

Profiles:
  orangepi5b        Standard base image + custom.nix (default)
  iot               Embedded IoT profile (Python GPIO/I2C/SPI, MQTT, debugging tools)
  docker            Container host profile (Docker daemon pre-enabled + docker-compose)
  kiosk             Display kiosk profile (Cage Wayland compositor + Chromium kiosk)
  minimal           Minimal headless profile (stripped doc/extra packages for small size)

Customization Options:
  -c, --custom FILE       Use specified .nix file as custom.nix (e.g. examples/gpio-sensor-service.nix)
  -w, --wifi SSID:PASS    Pre-configure Wi-Fi network credentials for headless auto-connect
  -k, --ssh-key KEY/PATH  Pre-configure SSH authorized key (paste key string or path to .pub file)
  -n, --hostname NAME     Set custom system hostname
  -p, --packages "P1 P2"  Add additional packages to custom.nix (space-separated)
  --init                  Generate a fresh custom.nix template from custom.nix.example
  --native                Build directly using host 'nix' instead of Docker container
  -h, --help              Show this help message

Examples:
  ./build.sh                                     # Build default image with custom.nix
  ./build.sh iot                                 # Build with IoT/GPIO/Python profile
  ./build.sh --custom examples/kiosk-display.nix # Build using example configuration
  ./build.sh --wifi "MyHomeWiFi:SecretPass" --ssh-key ~/.ssh/id_ed25519.pub
  ./build.sh iot -n robot-01 -p "htop neofetch"  # Combine profile with custom settings
EOF
}

# Parse positional and flagged arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        --init)
            if [ -f "custom.nix" ]; then
                cp custom.nix "custom.nix.bak.$(date +%s)"
                echo "Backed up existing custom.nix"
            fi
            cp custom.nix.example custom.nix
            echo "Initialized custom.nix from custom.nix.example."
            exit 0
            ;;
        -c|--custom)
            CUSTOM_FILE="$2"
            shift 2
            ;;
        -w|--wifi)
            WIFI_SPEC="$2"
            shift 2
            ;;
        -k|--ssh-key)
            SSH_KEY_INPUT="$2"
            shift 2
            ;;
        -n|--hostname)
            HOSTNAME_INPUT="$2"
            shift 2
            ;;
        -p|--package|--packages)
            IFS=' ' read -r -a EXTRA_PKGS <<< "$2"
            shift 2
            ;;
        --profile)
            TARGET="orangepi5b-$2"
            shift 2
            ;;
        --native)
            NATIVE_BUILD=true
            shift
            ;;
        orangepi5b|iot|docker|kiosk|minimal)
            if [ "$1" = "orangepi5b" ]; then
                TARGET="orangepi5b"
            else
                TARGET="orangepi5b-$1"
            fi
            shift
            ;;
        orangepi5b-*)
            TARGET="$1"
            shift
            ;;
        *)
            echo "Unknown option or profile: $1" >&2
            echo "Run './build.sh --help' for usage." >&2
            exit 1
            ;;
    esac
done

# Ensure custom.nix exists (create empty template if absent)
if [ ! -f "custom.nix" ]; then
    if [ -f "custom.nix.example" ]; then
        cp custom.nix.example custom.nix
    else
        echo "{ pkgs, lib, ... }: {}" > custom.nix
    fi
fi

# Apply custom file if passed
if [ -n "${CUSTOM_FILE}" ]; then
    if [ ! -f "${CUSTOM_FILE}" ]; then
        echo "Error: Custom file '${CUSTOM_FILE}' not found." >&2
        exit 1
    fi
    echo "Applying custom configuration from: ${CUSTOM_FILE}"
    cp "${CUSTOM_FILE}" custom.nix
fi

# Apply CLI overrides into custom.nix if provided
APPLY_OVERRIDES=false
OVERRIDE_NIX="{ pkgs, lib, ... }:\n\n{\n"

if [ -n "${HOSTNAME_INPUT}" ]; then
    APPLY_OVERRIDES=true
    OVERRIDE_NIX+="  networking.hostName = \"${HOSTNAME_INPUT}\";\n"
fi

if [ -n "${WIFI_SPEC}" ]; then
    APPLY_OVERRIDES=true
    WIFI_SSID="${WIFI_SPEC%%:*}"
    WIFI_PASS="${WIFI_SPEC#*:}"
    OVERRIDE_NIX+="  networking.networkmanager.ensureProfiles.profiles.\"AutoWiFi\" = {\n"
    OVERRIDE_NIX+="    connection = { id = \"AutoWiFi\"; type = \"wifi\"; autoconnect = \"true\"; };\n"
    OVERRIDE_NIX+="    wifi = { mode = \"infrastructure\"; ssid = \"${WIFI_SSID}\"; };\n"
    OVERRIDE_NIX+="    wifi-security = { key-mgmt = \"wpa-psk\"; psk = \"${WIFI_PASS}\"; };\n"
    OVERRIDE_NIX+="  };\n"
fi

if [ -n "${SSH_KEY_INPUT}" ]; then
    APPLY_OVERRIDES=true
    SSH_KEY_VAL="${SSH_KEY_INPUT}"
    if [ -f "${SSH_KEY_INPUT}" ]; then
        SSH_KEY_VAL=$(cat "${SSH_KEY_INPUT}")
    fi
    OVERRIDE_NIX+="  users.users.nixos.openssh.authorizedKeys.keys = [ \"${SSH_KEY_VAL}\" ];\n"
    OVERRIDE_NIX+="  users.users.root.openssh.authorizedKeys.keys = [ \"${SSH_KEY_VAL}\" ];\n"
fi

if [ ${#EXTRA_PKGS[@]} -gt 0 ]; then
    APPLY_OVERRIDES=true
    OVERRIDE_NIX+="  environment.systemPackages = with pkgs; [\n"
    for pkg in "${EXTRA_PKGS[@]}"; do
        OVERRIDE_NIX+="    ${pkg}\n"
    done
    OVERRIDE_NIX+="  ];\n"
fi

OVERRIDE_NIX+="}\n"

if [ "${APPLY_OVERRIDES}" = true ]; then
    echo "Writing CLI custom overrides to custom.nix..."
    printf "%b" "${OVERRIDE_NIX}" > custom.nix
fi

# Ensure git tracks new or modified files so Nix flakes include them
if [ -d ".git" ]; then
    git add -N custom.nix modules/ examples/ 2>/dev/null || true
fi

mkdir -p "${OUTPUT_DIR}"

echo "=========================================================="
echo " Building Target: images.${TARGET}"
echo " Configuration:   custom.nix"
echo " Output Dir:      ${OUTPUT_DIR}"
echo "=========================================================="

if [ "${NATIVE_BUILD}" = true ]; then
    if ! command -v nix >/dev/null 2>&1; then
        echo "Error: --native requested but 'nix' command is not available on host." >&2
        exit 1
    fi
    echo "Running native Nix build..."
    nix \
        --extra-experimental-features "nix-command flakes" \
        --extra-platforms "aarch64-linux arm-linux" \
        build \
        --out-link result-sd-image \
        ".#images.${TARGET}"

    cp -f result-sd-image/sd-image/* "${OUTPUT_DIR}/"
else
    # Docker isolated build
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

    echo "Building NixOS SD Image inside isolated Docker container..."
    docker run --rm \
        -v nix-store-cache:/nix \
        -v nix-root-cache:/root \
        -v "${SCRIPT_DIR}":/workspace \
        -w /workspace \
        nixos/nix \
        sh -c "git config --global --add safe.directory '*' && nix --extra-experimental-features 'nix-command flakes' --extra-platforms 'aarch64-linux arm-linux' build --out-link result-sd-image .#images.${TARGET}"

    echo "Copying generated image to ${OUTPUT_DIR}/..."
    docker run --rm \
        -v nix-store-cache:/nix \
        -v "${SCRIPT_DIR}":/workspace \
        alpine:latest \
        sh -c "cp /workspace/result-sd-image/sd-image/* /workspace/output/ && chown -R $(id -u):$(id -g) /workspace/output /workspace/flake.lock 2>/dev/null || true"
fi

echo ""
echo "=========================================================="
echo "==> Build complete! Output image:"
echo "=========================================================="
ls -lh "${OUTPUT_DIR}/"
echo ""
echo "To flash to an SD card or eMMC reader, run:"
echo "  sudo ./flash.sh /dev/sdX"
