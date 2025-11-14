{inputs, ...}: {
  imports = [
    ../../modules/system.nix
    ./hardware-configuration.nix
    inputs.disko.nixosModules.disko
    ./disk-config.nix
  ];

  # Use GRUB instead of systemd-boot
  boot.loader.custom = {
    bootloader = "grub";
    grubDevice = "/dev/disk/by-path/pci-0000:00:1f.2-ata-1.0";
    grubGfxMode = "1280x800";
    grubEfiInstallAsRemovable = true;
  };
}
