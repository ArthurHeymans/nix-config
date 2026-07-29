{ username, ... }:
{
  imports = [
    ../../modules/system.nix
    ./hardware-configuration.nix
  ];

  system.stateVersion = "24.05";
  home-manager.users.${username}.home.stateVersion = "24.11";
}
