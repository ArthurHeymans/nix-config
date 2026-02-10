{ ... }:
{
  imports = [
    ../../modules/system.nix
    ../../modules/nix-serve.nix
    ../../modules/nix-auto-update.nix
    ./hardware-configuration.nix
  ];
}
