{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./base.nix
    ./bluetooth.nix
    ./desktop.nix
    ./fonts.nix
    ./geoclue.nix
    ./gvfs.nix
    #./llm.nix
    ./networking.nix
    ./graphics.nix
    ./packages.nix
    ./printing.nix
    ./security.nix
    #./netbird.nix
    ./sound.nix
    ./udev.nix
    ./virtualisation.nix
  ];

  # Avoid binding CH341A SPI adapters to the kernel SPI driver; userspace
  # flashrom/libusb access should claim the device instead.
  boot.blacklistedKernelModules = ["spi_ch341"];

  # Provide LTS kernel as an alternative boot entry.
  specialisation.lts.configuration = {
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
  };

  nix.settings = {
    extra-substituters = [
      "https://niri.cachix.org"
    ];

    extra-trusted-public-keys = [
      "gmktec-k11:KaYkTTAvAv5cfwrsglqcsnyGKBUU1qzEXWB68BasinA="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
    ];
  };

  # Auto-upgrade is scheduled after the nightly build on gmktec-k11 (03:00)
  # so the cache is warm.
  system.autoUpgrade = {
    enable = true;
    dates = "04:00";
    allowReboot = false;
  };

  # Default stateVersion for most systems.
  system.stateVersion = lib.mkDefault "24.05";
}
