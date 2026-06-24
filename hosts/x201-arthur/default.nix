{ inputs, ... }: {
  imports = [
    ../../modules/system.nix
    ./hardware-configuration.nix
    inputs.disko.nixosModules.disko
    ./disk-config.nix
  ];

  # Use GRUB instead of systemd-boot. Keep a BIOS GRUB install on the disk
  # for SeaBIOS boots, but let UEFI installs update Boot####/BootOrder for
  # CrabEFI instead of relying on the removable fallback path.
  boot.loader.custom = {
    bootloader = "grub";
    grubDevice = "/dev/disk/by-path/pci-0000:00:1f.2-ata-1.0";
    grubGfxMode = "1280x800";
    grubEfiInstallAsRemovable = false;
  };
}
