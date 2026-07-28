{ pkgs, username, ... }:
{
  # OpenRGB: control RGB lighting of motherboard, RAM, GPU and peripherals.
  # The NixOS module installs the udev rules, loads i2c-dev (plus the
  # motherboard SMBus driver) and runs the SDK server on port 6742.
  services.hardware.openrgb = {
    enable = true;
    package = pkgs.openrgb-with-all-plugins;
  };

  # NVIDIA GPUs (e.g. the RTX 3090) expose their RGB controller on an I2C bus
  # created by the nvidia kernel driver. i2c-dev is what makes those buses
  # visible as /dev/i2c-* to userspace; hardware.i2c also adds a udev rule
  # granting the locally logged-in user (uaccess) and the "i2c" group access,
  # so the OpenRGB GUI works without root, not just the system service.
  hardware.i2c.enable = true;

  # uaccess only covers a locally logged-in session; the group membership also
  # allows driving the GPU lighting over ssh.
  users.users.${username}.extraGroups = [ "i2c" ];

  # i2cdetect / i2cdump for debugging which bus the GPU controller sits on.
  environment.systemPackages = [ pkgs.i2c-tools ];
}
