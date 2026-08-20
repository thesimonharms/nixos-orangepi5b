{ pkgs, ... }:

{
  # Docker container host profile for Edge Computing
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # Grant default user docker socket permissions
  users.users.nixos.extraGroups = [ "docker" ];

  environment.systemPackages = with pkgs; [
    docker-compose
  ];
}
