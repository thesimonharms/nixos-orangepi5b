{ pkgs, lib, ... }:

{
  # Hostname
  networking.hostName = lib.mkDefault "orangepi5b";

  # Networking & SSH
  networking.networkmanager.enable = lib.mkDefault true;
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = lib.mkDefault "yes";
      PasswordAuthentication = lib.mkDefault true;
    };
  };

  # User configuration: user 'nixos' with password 'nixos', sudo without password
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "dialout"
      "gpio"
      "i2c"
      "spi"
    ];
    initialPassword = "nixos";
  };
  users.users.root.initialPassword = "nixos";
  security.sudo.wheelNeedsPassword = false;

  # Serial getty auto-login for convenience on initial boot
  services.getty.autologinUser = lib.mkDefault "nixos";

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # Essential utilities for base embedded development
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
    libgpiod
    dtc
  ];

  system.stateVersion = "25.05";
}
