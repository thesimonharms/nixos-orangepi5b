# Example: Embedded GPIO / I2C Sensor Service with MQTT Publishing
# Copy this into custom.nix or build with `./build.sh --custom examples/gpio-sensor-service.nix`

{ pkgs, ... }:

let
  sensorScript = pkgs.writeScriptBin "sensor-daemon" ''
    #!${pkgs.python3.withPackages (ps: with ps; [ gpiod paho-mqtt requests ])}/bin/python3
    import time
    import sys

    print("Embedded Sensor Daemon starting...", flush=True)
    while True:
        # Example sensor loop: reading GPIO / I2C and logging/publishing
        print("Sensor reading: OK (uptime: {}s)".format(int(time.time())), flush=True)
        time.sleep(10)
  '';
in
{
  networking.hostName = "orangepi-sensor-node";

  # Install sensor daemon and hardware debugging tools
  environment.systemPackages = with pkgs; [
    sensorScript
    libgpiod
    i2c-tools
    mosquitto
  ];

  # Run sensor service automatically on boot
  systemd.services.sensor-daemon = {
    description = "Embedded Sensor Daemon";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = "${sensorScript}/bin/sensor-daemon";
      Restart = "always";
      RestartSec = "5s";
      User = "nixos";
    };
  };
}
