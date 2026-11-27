{
  inputs,
  username,
  ...
}:
{
  imports = [
    ../../modules/system.nix
    ./hardware-configuration.nix
    inputs.disko.nixosModules.disko
    ./disk-config.nix
  ];

  # Keep both BIOS GRUB and the UEFI fallback; neither depends on a saved BootOrder.
  boot.loader.custom = {
    bootloader = "grub";
    grubDevice = "/dev/disk/by-id/ata-KINGSTON_SNS4151S332G_50026B724409A6A6";
    grubUseOSProber = false;
    grubEfiInstallAsRemovable = true;
    grubRegisterFallback = true;
  };
  boot.loader.grub.configurationLimit = 3;

  # Trim heavy system components for the 32 GB internal SATA SSD.
  my.virtualisation.enable = false;
  my.fonts.includeIosevka = false;
  my.specialisations.lts.enable = false;
  my.nix.keepGenerations = 2;

  system.stateVersion = "26.11";
  home-manager.users.${username} = {
    home.stateVersion = "26.11";
    my.features = {
      kicad.enable = false;
      calibre.enable = false;
      keyboard.enable = false;
      crypto.enable = false;
      dev.enable = false;
    };
  };
}
