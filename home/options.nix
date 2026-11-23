{ lib, ... }:
{
  options.my = {
    pointer.accel = lib.mkOption {
      type = lib.types.float;
      default = 0.0;
      description = "Pointer acceleration used by Wayland compositor configurations.";
    };

    features = {
      kicad.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install KiCad PCB design tools.";
      };
      calibre.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install Calibre e-book manager.";
      };
      keyboard.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install QMK and Vial keyboard firmware tools.";
      };
      crypto.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install Trezor Suite.";
      };
      dev.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install local development toolchains and reverse-engineering tools.";
      };
    };
  };
}
