{lib, config, ...}: {
  options.boot.loader.custom = {
    bootloader = lib.mkOption {
      type = lib.types.enum ["systemd-boot" "grub" "none"];
      default = "systemd-boot";
      description = "Which bootloader to use";
    };

    grubDevice = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "GRUB device path (required when using GRUB)";
    };

    grubUseOSProber = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable OS prober for GRUB";
    };

    grubGfxMode = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "GRUB graphics mode (e.g., 1366x768)";
    };

    grubEfiInstallAsRemovable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install GRUB EFI as removable";
    };
  };

  config = lib.mkMerge [
    # systemd-boot configuration
    (lib.mkIf (config.boot.loader.custom.bootloader == "systemd-boot") {
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
    })

    # GRUB configuration
    (lib.mkIf (config.boot.loader.custom.bootloader == "grub") {
      boot.loader.systemd-boot.enable = false;
      boot.loader.efi.canTouchEfiVariables = !config.boot.loader.custom.grubEfiInstallAsRemovable;
      boot.loader.grub = {
        enable = true;
        device = config.boot.loader.custom.grubDevice;
        useOSProber = config.boot.loader.custom.grubUseOSProber;
        efiSupport = true;
        efiInstallAsRemovable = config.boot.loader.custom.grubEfiInstallAsRemovable;
        gfxmodeBios = lib.mkIf (config.boot.loader.custom.grubGfxMode != "") config.boot.loader.custom.grubGfxMode;
      };
    })
  ];
}
