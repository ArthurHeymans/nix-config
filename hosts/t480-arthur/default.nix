{lib, pkgs, inputs, ...}: {
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
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.custom.bootloader = "none";

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  boot.initrd.systemd.enable = true;
}
