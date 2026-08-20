{
  description = "NixOS configuration and flashable SD/eMMC image for Orange Pi 5B";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations.orangepi5b = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
        ({ pkgs, config, lib, ... }: {
          # Hostname
          networking.hostName = "orangepi5b";

          # Enable modern kernel with RK3588/RK3588S upstream support
          boot.kernelPackages = pkgs.linuxPackages_latest;

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
          image.baseName = "nixos-orangepi5b";
          sdImage = {
            # Leave at least 32 MiB before partition 1 so u-boot-rockchip.bin (9.5MB) doesn't overlap
            firmwarePartitionOffset = 32;
            # Embed the Rockchip U-Boot binary at sector 64 (32 KiB offset)
            postBuildCommands = ''
              ${pkgs.coreutils}/bin/dd if=${pkgs.ubootOrangePi5}/u-boot-rockchip.bin of=$img seek=64 conv=notrunc
            '';
            compressImage = true;
          };

          # Networking & SSH
          networking.networkmanager.enable = true;
          services.openssh = {
            enable = true;
            settings = {
              PermitRootLogin = "yes";
              PasswordAuthentication = true;
            };
          };

          # User configuration: user 'nixos' with password 'nixos', sudo without password
          users.users.nixos = {
            isNormalUser = true;
            extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
            initialPassword = "nixos";
          };
          users.users.root.initialPassword = "nixos";
          security.sudo.wheelNeedsPassword = false;

          # Serial getty auto-login for convenience on initial boot
          services.getty.autologinUser = "nixos";

          # Nix settings
          nix.settings.experimental-features = [ "nix-command" "flakes" ];
          nixpkgs.config.allowUnfree = true;

          # Essential utilities
          environment.systemPackages = with pkgs; [
            vim
            wget
            curl
            git
            htop
            pciutils
            usbutils
            ethtool
            i2c-tools
            dtc
          ];

          system.stateVersion = "25.05";
        })
      ];
    };

    # Convenient shortcut
    images.orangepi5b = self.nixosConfigurations.orangepi5b.config.system.build.sdImage;
  };
}
