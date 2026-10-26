{
  config,
  inputs,
  lib,
  username,
  ...
}:
{
  imports = [
    ../../modules/system.nix
    inputs.disko.nixosModules.disko
    ./disk-config.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  boot.kernelParams = [
    "console=ttyS0,115200"
    "console=tty0"
    "ignore_loglevel"
  ];

  # A portable USB install must find its root disk on different machines.
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ehci_pci"
    "ohci_pci"
    "uhci_hcd"
    "usb_storage"
    "uas"
    "sd_mod"
    "ahci"
    "nvme"
  ];
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Install both BIOS GRUB and the UEFI removable-media fallback, without
  # changing the firmware boot entries of the machine doing the install.
  boot.loader.custom = {
    bootloader = "grub";
    grubDevice = "/dev/disk/by-id/usb-PHILIPS_USB-0:0";
    grubUseOSProber = false;
    grubEfiInstallAsRemovable = true;
  };
  boot.loader.grub.configurationLimit = 3;

  system.stateVersion = "26.11";
  home-manager.users.${username}.home.stateVersion = "26.11";
}
