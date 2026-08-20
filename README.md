# NixOS for Orange Pi 5B (Rockchip RK3588S)

This repository provides a modular Nix flake and streamlined toolchain to build flashable, production-ready NixOS SD card / eMMC images for the **Orange Pi 5B**.

All builds can run directly in an isolated Docker container with QEMU aarch64 binfmt emulation and persistent cache volumes, meaning **no Nix installation or tools are required on the host system**.

---

## Key Features for Embedded Projects

- **Modular NixOS Architecture:** Hardware support, base system, profiles, and user customizations are cleanly separated.
- **Easy Custom Builds:** Edit `custom.nix` or use simple CLI flags (`--wifi`, `--ssh-key`, `--hostname`, `--packages`) without touching core board logic.
- **Embedded Bus & Peripheral Access:** Automatic udev rules and user groups for non-root access to GPIO (`/dev/gpiochip*`), I2C (`/dev/i2c-*`), SPI (`/dev/spidev*`), and Serial/UART.
- **Pre-configured Embedded Profiles:**
  - `iot`: Python 3 environment (libgpiod, pyserial, smbus2, spidev, paho-mqtt), bus utilities, MQTT clients.
  - `docker`: Pre-enabled Docker engine + compose for edge container workloads.
  - `kiosk`: Wayland cage compositor + Chromium in kiosk mode for touchscreen or display dashboards.
  - `minimal`: Stripped down footprint for resource-constrained or headless deployments.
- **Reusable Flake Library:** Exported NixOS modules and `lib.mkImage` function to use this repo as a base for downstream embedded project flakes.

---

## Hardware Specifications

* **Board:** Orange Pi 5B
* **SoC:** Rockchip RK3588S (Octa-core 4x Cortex-A76 + 4x Cortex-A55, Mali-G610 GPU, 6 TOPS NPU)
* **Bootloader:** Upstream U-Boot (`orangepi-5-rk3588s_defconfig` with TF-A BL31 & DDR firmware), flashed at sector 64 (32 KiB offset)
* **Kernel:** Upstream Linux 7.2+ (`linuxPackages_latest`) with mainline RK3588S SoC support
* **Device Tree:** `rockchip/rk3588s-orangepi-5b.dtb`
* **Storage:** MicroSD card & onboard eMMC
* **Connectivity:** Gigabit Ethernet, Onboard WiFi 6 & Bluetooth 5.0 (AP6275P firmware enabled)

---

## Default System Credentials

* **Default User:** `nixos`
  * **Password:** `nixos`
  * **Groups:** `wheel`, `networkmanager`, `video`, `audio`, `dialout`, `gpio`, `i2c`, `spi`
  * **Sudo:** Passwordless sudo enabled
* **Root User:**
  * **Password:** `nixos`
  * **SSH Root Login:** Enabled (`PermitRootLogin yes`)
* **Serial Debug Console:** UART2 on standard pin header (Baud rate: `1500000 8N1`)
* **HDMI Output:** Enabled (`console=tty1`) with auto-login on tty1
* **Network:** NetworkManager enabled (auto-DHCP for Ethernet)

---

## Quick Start: Building Custom Images

### 1. Build the Default Image
```bash
./build.sh
```

### 2. Build with an Embedded Profile
```bash
# Embedded IoT & Hardware Bus profile
./build.sh iot

# Docker Edge Host profile
./build.sh docker

# HDMI Display / Kiosk profile
./build.sh kiosk

# Minimal lightweight profile
./build.sh minimal
```

### 3. Quick Headless Customization via CLI Flags
You can bake Wi-Fi credentials, SSH keys, hostname, and packages directly without manually editing files:

```bash
./build.sh \
  --hostname robot-controller \
  --wifi "MyWiFiSSID:MySecretPassword" \
  --ssh-key ~/.ssh/id_ed25519.pub \
  --packages "neofetch tmux rsync"
```

### 4. Customizing via `custom.nix`
Edit `custom.nix` to declare any custom NixOS options, packages, or services:

```nix
{ pkgs, ... }:

{
  networking.hostName = "orangepi-sensor-node";

  # Add extra packages
  environment.systemPackages = with pkgs; [
    tmux
    rsync
    python3
  ];

  # Pre-load your SSH key for headless access
  users.users.nixos.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..."
  ];

  # Run a custom systemd service on boot
  systemd.services.my-app = {
    description = "Custom Embedded Application";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python3 -u /home/nixos/app.py";
      Restart = "always";
      User = "nixos";
    };
  };
}
```

Then simply build:
```bash
./build.sh
```

### 5. Build from an Example Template
Pre-made templates are available in `examples/`:
```bash
# Build GPIO/Sensor MQTT service example
./build.sh --custom examples/gpio-sensor-service.nix

# Build HDMI Kiosk Display example
./build.sh --custom examples/kiosk-display.nix

# Build Headless Provisioning example
./build.sh --custom examples/headless-provisioning.nix
```

---

## Build Script CLI Reference

```
Usage: ./build.sh [OPTIONS] [PROFILE]

Profiles:
  orangepi5b        Standard base image + custom.nix (default)
  iot               Embedded IoT profile (Python GPIO/I2C/SPI, MQTT, debugging tools)
  docker            Container host profile (Docker daemon pre-enabled + docker-compose)
  kiosk             Display kiosk profile (Cage Wayland compositor + Chromium kiosk)
  minimal           Minimal headless profile (stripped doc/extra packages for small size)

Customization Options:
  -c, --custom FILE       Use specified .nix file as custom.nix (e.g. examples/gpio-sensor-service.nix)
  -w, --wifi SSID:PASS    Pre-configure Wi-Fi network credentials for headless auto-connect
  -k, --ssh-key KEY/PATH  Pre-configure SSH authorized key (key string or path to .pub file)
  -n, --hostname NAME     Set custom system hostname
  -p, --packages "P1 P2"  Add additional packages to custom.nix (space-separated)
  --init                  Generate a fresh custom.nix template from custom.nix.example
  --native                Build directly using host 'nix' instead of Docker container
  -h, --help              Show help message
```

---

## Flashing the Image

Use the included helper script to flash to your SD card or eMMC reader:

```bash
# Automatically finds the latest generated image in output/
sudo ./flash.sh /dev/sdX

# Or specify an image explicitly
sudo ./flash.sh /dev/sdX output/nixos-orangepi5b.img.zst
```

---

## Using as a Downstream Flake Dependency

You can use this repository as a base module in your own project's `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-orangepi5b.url = "github:thesimonharms/nixos-orangepi5b";
  };

  outputs = { self, nixpkgs, nixos-orangepi5b }: {
    images.my-robot = nixos-orangepi5b.lib.mkImage {
      extraModules = [
        ({ pkgs, ... }: {
          networking.hostName = "robot-01";
          environment.systemPackages = [ pkgs.ros2-humble-desktop ];
        })
      ];
    };
  };
}
```

---

## Repository Structure

```
.
├── build.sh                      # Unified build script with profile & custom options
├── flash.sh                      # Flashing helper script
├── custom.nix                    # User customization configuration (auto-imported)
├── custom.nix.example            # Annotated template for customizations
├── flake.nix                     # Flake definition, targets, module exports, and helper library
├── modules/
│   ├── hardware/
│   │   └── orangepi5b.nix        # Orange Pi 5B hardware, kernel, bootloader, udev rules
│   ├── base.nix                  # Base OS, users, network, serial console, essential tools
│   └── profiles/
│       ├── iot.nix               # Embedded IoT profile (Python GPIO/I2C/SPI, MQTT)
│       ├── docker.nix            # Docker edge container host profile
│       ├── kiosk.nix             # Cage Wayland / Chromium kiosk display profile
│       └── minimal.nix           # Minimal lightweight profile
└── examples/
    ├── gpio-sensor-service.nix   # Python sensor background service
    ├── kiosk-display.nix         # HDMI kiosk dashboard configuration
    └── headless-provisioning.nix # Wi-Fi and SSH headless provisioning
```
