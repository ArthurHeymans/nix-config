{ config, lib, pkgs, ... }:

{
  services.pcscd.enable = true;
  security.polkit.enable = true;
  security.rtkit.enable = true;
}
