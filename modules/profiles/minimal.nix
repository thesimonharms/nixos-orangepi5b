{ lib, ... }:

{
  # Minimal Footprint Profile
  # Optimizes image size and build time by disabling documentation and unnecessary packages

  documentation.enable = lib.mkForce false;
  documentation.man.enable = lib.mkForce false;
  documentation.doc.enable = lib.mkForce false;
  documentation.info.enable = lib.mkForce false;
  documentation.nixos.enable = lib.mkForce false;

  environment.defaultPackages = lib.mkForce [];
}
