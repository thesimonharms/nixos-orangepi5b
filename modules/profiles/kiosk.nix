{ pkgs, lib, ... }:

{
  # Embedded Kiosk / Display Profile
  # Runs a lightweight Wayland compositor (Cage) displaying Chromium in kiosk mode

  services.cage = {
    enable = true;
    user = "nixos";
    program = "${pkgs.chromium}/bin/chromium --noerrdialogs --disable-infobars --kiosk http://localhost:8080";
  };

  # Enable graphics and sound support
  hardware.graphics.enable = true;

  environment.systemPackages = with pkgs; [
    chromium
  ];
}
