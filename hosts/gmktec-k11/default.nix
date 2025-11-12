{...}: {
  imports = [
    ../../modules/system.nix
    ../../modules/nix-serve.nix
    ./hardware-configuration.nix
  ];
}
