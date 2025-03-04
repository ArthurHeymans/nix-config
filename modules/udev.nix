{ pkgs, ... }:

{
  services.udev.packages = [ pkgs.picoprobe-udev-rules ];
}
