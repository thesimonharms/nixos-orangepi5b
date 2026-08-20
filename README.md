# NixOS for Orange Pi 5B (Rockchip RK3588S)

This repository contains the Nix flake configuration and build scripts to generate a bootable, flashable SD card / eMMC image running NixOS on the **Orange Pi 5B**.

All builds are performed in an isolated container/chroot environment (using Docker with QEMU ARM64 binfmt and persistent cache volumes) so that **no Nix packages or tools need to be installed on the host system**.

---

## Hardware Specifications & Compatibility

* **Board:** Orange Pi 5B
* **SoC:** Rockchip RK3588S (Octa-core 4x Cortex-A76 + 4x Cortex-A55, Mali-G610 GPU, 6 TOPS NPU)
* **Bootloader:** Upstream U-Boot (`orangepi-5-rk3588s_defconfig` with Rockchip DDR & TF-A BL31 firmware), embedded at sector 64 (32 KiB offset)
* **Kernel:** Linux 7.2+ (`linuxPackages_latest`) with mainline RK3588 / RK3588S SoC support
* **Device Tree:** `rockchip/rk3588s-orangepi-5b.dtb`
* **Storage:** MicroSD card & onboard eMMC supported
* **Connectivity:** Gigabit Ethernet, Onboard WiFi 6 & Bluetooth 5.0 (AP6275P firmware enabled)

---

## Default System Credentials & Access

* **Default User:** `nixos`
  * **Password:** `nixos`
  * **Sudo:** Passwordless sudo enabled (`wheel` group)
* **Root User:**
  * **Password:** `nixos`
  * **SSH Root Login:** Enabled (`PermitRootLogin yes`)
* **Serial Debug Console:** UART2 on standard pin header (Baud rate: `1500000 8N1`)
* **HDMI Output:** Enabled (`console=tty1`) with auto-login on tty1 for convenience
* **Network:** NetworkManager enabled (auto-DHCP for Ethernet, `nmcli` for WiFi)

---

## How to Build the Image

Run the provided build script:

```bash
./build.sh
```

This will:
1. Ensure `qemu-aarch64` binfmt is registered.
2. Initialize persistent Docker cache volumes (`nix-store-cache` and `nix-root-cache`).
3. Build the NixOS aarch64 image inside the official `nixos/nix` container.
4. Output the compressed image to `./result-sd-image/sd-image/`.

---

## How to Flash the Image

Use the included flashing helper script:

```bash
# Example: Flash to /dev/sdb or /dev/mmcblk0
sudo ./flash.sh /dev/sdX
```

Or flash manually using `dd`:

```bash
# Decompress and write to SD card
zstd -dc result-sd-image/sd-image/nixos-orangepi5b-*.img.zst | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
```

*(Replace `/dev/sdX` with your actual SD card block device name!)*

---

## Connecting to Wi-Fi on First Boot

Once booted, you can log in via serial console, HDMI keyboard/monitor, or SSH over Ethernet:

```bash
# Connect to your Wi-Fi network:
sudo nmcli device wifi connect "SSID" password "PASSWORD"
```

---

## Customizing the Configuration

To add packages, change users, or configure additional services:
1. Edit [flake.nix](file:///home/simon/Projects/nixos-orangepi5b/flake.nix).
2. Re-run `./build.sh` to generate an updated flashable image.
3. Once running on the Orange Pi 5B, you can manage the system directly with standard `nixos-rebuild switch --flake .#orangepi5b`.
