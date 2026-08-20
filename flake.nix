{
  description = "NixOS configuration and flashable SD/eMMC image for Orange Pi 5B";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "aarch64-linux";

      # Base builder function for Orange Pi 5B systems
      mkOrangePi5bSystem = { extraModules ? [] }: nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          ./modules/hardware/orangepi5b.nix
          ./modules/base.nix
        ] ++ extraModules;
      };

      customModule = if builtins.pathExists ./custom.nix then [ ./custom.nix ] else [];
    in {
      # Exported NixOS modules for downstream flake reuse
      nixosModules = {
        hardware = import ./modules/hardware/orangepi5b.nix;
        base = import ./modules/base.nix;
        default = { ... }: {
          imports = [
            ./modules/hardware/orangepi5b.nix
            ./modules/base.nix
          ];
        };
      };

      # Library helpers for downstream flakes
      lib = {
        mkSystem = mkOrangePi5bSystem;
        mkImage = { extraModules ? [] }: (mkOrangePi5bSystem { inherit extraModules; }).config.system.build.sdImage;
      };

      # Available NixOS configurations
      nixosConfigurations = {
        # Default / Custom configuration (includes custom.nix)
        orangepi5b = mkOrangePi5bSystem {
          extraModules = customModule;
        };

        # Pre-configured Embedded IoT profile (GPIO, I2C, SPI, Python sensors, MQTT)
        orangepi5b-iot = mkOrangePi5bSystem {
          extraModules = [ ./modules/profiles/iot.nix ] ++ customModule;
        };

        # Docker container host profile
        orangepi5b-docker = mkOrangePi5bSystem {
          extraModules = [ ./modules/profiles/docker.nix ] ++ customModule;
        };

        # Embedded Kiosk / Display profile
        orangepi5b-kiosk = mkOrangePi5bSystem {
          extraModules = [ ./modules/profiles/kiosk.nix ] ++ customModule;
        };

        # Minimal headless profile
        orangepi5b-minimal = mkOrangePi5bSystem {
          extraModules = [ ./modules/profiles/minimal.nix ] ++ customModule;
        };
      };

      # Flashable SD / eMMC image build targets
      images = {
        orangepi5b = self.nixosConfigurations.orangepi5b.config.system.build.sdImage;
        orangepi5b-iot = self.nixosConfigurations.orangepi5b-iot.config.system.build.sdImage;
        orangepi5b-docker = self.nixosConfigurations.orangepi5b-docker.config.system.build.sdImage;
        orangepi5b-kiosk = self.nixosConfigurations.orangepi5b-kiosk.config.system.build.sdImage;
        orangepi5b-minimal = self.nixosConfigurations.orangepi5b-minimal.config.system.build.sdImage;
      };
    };
}
