# Example: Embedded HDMI Kiosk Display
# Runs Chromium in kiosk mode over Cage (lightweight Wayland compositor)
# Copy this into custom.nix or build with `./build.sh --custom examples/kiosk-display.nix`

{ pkgs, ... }:

{
  networking.hostName = "orangepi-kiosk";

  # Enable graphics
  hardware.graphics.enable = true;

  # Auto-start cage with fullscreen browser on boot
  services.cage = {
    enable = true;
    user = "nixos";
    program = "${pkgs.chromium}/bin/chromium --noerrdialogs --disable-infobars --kiosk --incognito https://grafana.com";
  };

  # Prevent screen blanking / power saving
  systemd.user.services.cage.environment = {
    WLR_DRM_NO_MODIFIERS = "1";
  };
}
