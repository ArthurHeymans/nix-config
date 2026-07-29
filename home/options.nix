{ lib, ... }:
{
  options.my.pointer.accel = lib.mkOption {
    type = lib.types.float;
    default = 0.0;
    description = "Pointer acceleration used by Wayland compositor configurations.";
  };
}
