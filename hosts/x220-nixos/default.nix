{...}: {
  imports = [
    ../../modules/system.nix
    ./hardware-configuration.nix
  ];

  # Use GRUB instead of systemd-boot
  boot.loader.custom = {
    bootloader = "grub";
    grubDevice = "/dev/disk/by-path/pci-0000:00:1f.2-ata-3.0";
    grubGfxMode = "1366x768";
    grubEfiInstallAsRemovable = true;
  };
}
