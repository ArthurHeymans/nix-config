{
  inputs,
  username,
  ...
}:
{
  imports = [
    ../../modules/coding-server.nix
    inputs.disko.nixosModules.disko
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  # Keep a bootable EFI fallback even when CrabEFI cannot save BootOrder.
  boot.loader.custom = {
    bootloader = "grub";
    grubDevice = "nodev";
    grubUseOSProber = false;
    grubEfiInstallAsRemovable = true;
    grubRegisterFallback = true;
  };
  boot.loader.grub.configurationLimit = 5;

  home-manager.users.${username}.home.stateVersion = "26.11";
  system.stateVersion = "26.11";
}
