# Example: Fully Headless Out-of-the-Box Provisioning
# Pre-configures Wi-Fi credentials and SSH public keys for immediate headless access.
# Copy this into custom.nix or build with `./build.sh --custom examples/headless-provisioning.nix`

{ pkgs, ... }:

{
  networking.hostName = "orangepi-edge-01";

  # Pre-configure Wi-Fi network profile
  networking.networkmanager.ensureProfiles.profiles = {
    "Embedded-WiFi" = {
      connection = {
        id = "Embedded-WiFi";
        type = "wifi";
        autoconnect = "true";
      };
      wifi = {
        mode = "infrastructure";
        ssid = "YourWiFiNetworkName";
      };
      wifi-security = {
        key-mgmt = "wpa-psk";
        psk = "YourWiFiPassword";
      };
    };
  };

  # Embed SSH public keys for user 'nixos' and 'root'
  users.users.nixos.openssh.authorizedKeys.keys = [
    # Replace with your actual public key (e.g. from ~/.ssh/id_ed25519.pub):
    # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExamplePublicKey"
  ];
  users.users.root.openssh.authorizedKeys.keys = [
    # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExamplePublicKey"
  ];

  # Extra utilities for remote management
  environment.systemPackages = with pkgs; [
    tmux
    rsync
    tailscale
  ];

  # Enable Tailscale VPN for secure remote access without port forwarding
  services.tailscale.enable = true;
}
