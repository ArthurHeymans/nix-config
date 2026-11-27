{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.my.specialisations.lts.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Include an alternative LTS kernel boot specialisation.";
  };

  imports = [
    ./base.nix
    ./bluetooth.nix
    ./desktop.nix
    ./fonts.nix
    ./geoclue.nix
    ./gvfs.nix
    ./networking.nix
    ./graphics.nix
    ./packages.nix
    ./printing.nix
    ./security.nix
    ./sound.nix
    ./udev.nix
    ./virtualisation.nix
  ];

  config = {
    # Avoid binding CH341A SPI adapters to the kernel SPI driver; userspace
    # flashrom/libusb access should claim the device instead.
    boot.blacklistedKernelModules = [ "spi_ch341" ];

    # Provide LTS kernel (optional) and relaxed /dev/mem access as alternate boot entries.
    specialisation =
      lib.optionalAttrs config.my.specialisations.lts.enable {
        lts.configuration = {
          boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
        };
      }
      // {
        "iomem-relaxed".configuration = {
          boot.kernelParams = [ "iomem=relaxed" ];
        };
      };

    nix.settings = {
      extra-trusted-public-keys = [
        "gmktec-k11:KaYkTTAvAv5cfwrsglqcsnyGKBUU1qzEXWB68BasinA="
      ];
    };
  };
}
