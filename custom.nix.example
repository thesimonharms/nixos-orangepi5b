# Custom configuration for Orange Pi 5B NixOS Image
# Edit this file to add packages, services, users, Wi-Fi credentials, or custom settings.
# Changes in this file will automatically be included when running `./build.sh`.

{ pkgs, lib, ... }:

{
  # ----------------------------------------------------------------------------
  # 1. Hostname & Network Configuration
  # ----------------------------------------------------------------------------
  # networking.hostName = "orangepi-embedded";

  # Pre-configure Wi-Fi networks for headless auto-connection on boot
  # networking.networkmanager.ensureProfiles.profiles = {
  #   "Home-WiFi" = {
  #     connection = {
  #       id = "Home-WiFi";
  #       type = "wifi";
  #       autoconnect = "true";
  #     };
  #     wifi = {
  #       mode = "infrastructure";
  #       ssid = "MyHomeNetwork";
  #     };
  #     wifi-security = {
  #       key-mgmt = "wpa-psk";
  #       psk = "MySecretPassword123";
  #     };
  #   };
  # };

  # ----------------------------------------------------------------------------
  # 2. SSH Keys & Authentication
  # ----------------------------------------------------------------------------
  # Pre-load your SSH public key for passwordless login on first boot
  # users.users.nixos.openssh.authorizedKeys.keys = [
  #   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..."
  # ];
  # users.users.root.openssh.authorizedKeys.keys = [
  #   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..."
  # ];

  # ----------------------------------------------------------------------------
  # 3. Additional Packages
  # ----------------------------------------------------------------------------
  # environment.systemPackages = with pkgs; [
  #   tmux
  #   rsync
  #   jq
  #   python3
  # ];

  # ----------------------------------------------------------------------------
  # 4. Custom Embedded Services / Startup Scripts
  # ----------------------------------------------------------------------------
  # systemd.services.sensor-logger = {
  #   description = "Embedded Sensor Logging Service";
  #   wantedBy = [ "multi-user.target" ];
  #   after = [ "network.target" ];
  #   serviceConfig = {
  #     Type = "simple";
  #     User = "nixos";
  #     Restart = "always";
  #     RestartSec = "5s";
  #     ExecStart = "${pkgs.python3}/bin/python -u -c 'import time; print(\"Embedded sensor started\"); time.sleep(99999)'";
  #   };
  # };
}
