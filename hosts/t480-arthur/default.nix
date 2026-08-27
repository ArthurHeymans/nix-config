{
  pkgs,
  inputs,
  username,
  ...
}:
{
  imports = [
    ../../modules/system.nix
    ./hardware-configuration.nix
    inputs.disko.nixosModules.disko
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t480
    inputs.lanzaboote.nixosModules.lanzaboote
    ./disk-config.nix
  ];

  environment.systemPackages = [
    pkgs.sbctl
  ];

  # lanzaboote replaces systemd
  boot.loader.custom.bootloader = "none";

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  boot.initrd.systemd.enable = true;

  system.stateVersion = "24.05";
  home-manager.users.${username} = {
    home.stateVersion = "24.11";
    my.pointer.accel = 1.0;
  };
}
