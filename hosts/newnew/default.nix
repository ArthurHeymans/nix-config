{inputs, ...}: {
  imports = [
    ../../modules/system.nix
    ./hardware-configuration.nix
    inputs.disko.nixosModules.disko
    ./disk-config.nix
  ];
}
