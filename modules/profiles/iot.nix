{ pkgs, ... }:

{
  # Embedded IoT and Hardware Development Profile
  # Includes Python with hardware bus libraries, serial debugging tools, and MQTT utilities

  environment.systemPackages = with pkgs; [
    # Hardware bus and communication utilities
    libgpiod
    i2c-tools
    spi-tools
    can-utils
    socat
    minicom
    screen
    picocom
    mosquitto # includes mosquitto_pub and mosquitto_sub

    # Python 3 environment with common IoT and hardware packages
    (python3.withPackages (ps: with ps; [
      gpiod
      pyserial
      smbus2
      spidev
      paho-mqtt
      requests
      pyyaml
    ]))
  ];
}
