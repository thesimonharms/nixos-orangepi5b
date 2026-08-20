{ pkgs, config, lib, ... }:

{
  # Enable modern kernel with RK3588/RK3588S upstream support
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  # Disable ZFS filesystem module which is incompatible with latest kernel
  boot.supportedFilesystems.zfs = lib.mkForce false;
  boot.zfs.forceImportRoot = false;

  # Hardware device tree for Orange Pi 5B
  hardware.deviceTree.enable = true;
  hardware.deviceTree.name = "rockchip/rk3588s-orangepi-5b.dtb";
  hardware.enableRedistributableFirmware = true;

  # Bootloader configuration
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # Serial and HDMI console parameters for Orange Pi 5/5B
  boot.kernelParams = [
    "console=ttyS2,1500000n8"
    "console=tty1"
    "earlycon=uart8250,mmio32,0xfeb50000,1500000"
  ];

  # SD Image build settings
  image.baseName = lib.mkDefault "nixos-orangepi5b";
  sdImage = {
    # Leave at least 32 MiB before partition 1 so u-boot-rockchip.bin (9.5MB) doesn't overlap
    firmwarePartitionOffset = 32;
    # Embed the Rockchip U-Boot binary at sector 64 (32 KiB offset)
    postBuildCommands = ''
      ${pkgs.coreutils}/bin/dd if=${pkgs.ubootOrangePi5}/u-boot-rockchip.bin of=$img seek=64 conv=notrunc
    '';
    compressImage = lib.mkDefault true;
  };

  # Embedded Hardware & Peripherals: Groups & Udev Rules for GPIO, I2C, SPI, UART
  users.groups.gpio = {};
  users.groups.i2c = {};
  users.groups.spi = {};

  services.udev.extraRules = ''
    # GPIO pin access for non-root users
    SUBSYSTEM=="gpio", GROUP="gpio", MODE="0660"
    SUBSYSTEM=="gpiochip*", GROUP="gpio", MODE="0660"

    # I2C bus access
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"

    # SPI bus access
    KERNEL=="spidev*", GROUP="spi", MODE="0660"

    # Serial / UART access
    KERNEL=="ttyS[0-9]*|ttyUSB[0-9]*|ttyACM[0-9]*", GROUP="dialout", MODE="0660"
  '';
}
