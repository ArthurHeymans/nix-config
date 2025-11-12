{inputs, ...}: {
  imports = [
    ../../modules/system.nix
    ./hardware-configuration.nix
    inputs.disko.nixosModules.disko
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t480
    ./disk-config.nix
  ];
}
