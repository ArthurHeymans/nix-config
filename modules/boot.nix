{ lib, config, pkgs, ... }:
let
  cfg = config.boot.loader.custom;
  registerGrubFallback = pkgs.writeShellApplication {
    name = "register-grub-fallback";
    runtimeInputs = with pkgs; [ efibootmgr gnugrep util-linux ];
    text = ''
      export LC_ALL=C
      esp=$1
      loader='\EFI\BOOT\BOOTX64.EFI'

      # The fallback file is sufficient to boot even when efivars are missing
      # or firmware refuses nonvolatile writes.
      if [[ ! -f "$esp/EFI/BOOT/BOOTX64.EFI" ]]; then
        echo "GRUB: no EFI fallback loader at $esp; skipping registration" >&2
        exit 0
      fi
      if ! entries=$(efibootmgr --verbose); then
        echo "GRUB: EFI boot entries unavailable; keeping the fallback loader" >&2
        exit 0
      fi
      if ! partition=$(findmnt --noheadings --output SOURCE --mountpoint "$esp") ||
        ! read -r disk part uuid < <(lsblk --nodeps --noheadings --raw --output PKNAME,PARTN,PARTUUID "$partition") ||
        [[ -z "$disk" || -z "$part" || -z "$uuid" ]]; then
        echo "GRUB: cannot identify the EFI system partition at $esp; skipping registration" >&2
        exit 0
      fi

      # Match the actual partition and loader, not just the display label.
      # Do not reorder an existing entry on each NixOS deployment.
      if grep --fixed-strings --ignore-case "HD($part,GPT,$uuid," <<< "$entries" |
        grep --fixed-strings --ignore-case "File($loader)" >/dev/null; then
        exit 0
      fi
      if ! efibootmgr --create --disk "/dev/$disk" --part "$part" \
        --label 'NixOS' --loader "$loader"; then
        echo "GRUB: firmware refused boot entry registration; keeping the fallback loader" >&2
      fi
    '';
  };
in
{
  options.boot.loader.custom = {
    bootloader = lib.mkOption {
      type = lib.types.enum [
        "systemd-boot"
        "grub"
        "none"
      ];
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

    grubRegisterFallback = lib.mkEnableOption ''
      best-effort registration of the x86-64 GRUB fallback loader in EFI BootOrder
    '';
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
      assertions = [{
        assertion = !cfg.grubRegisterFallback || cfg.grubEfiInstallAsRemovable;
        message = "grubRegisterFallback requires grubEfiInstallAsRemovable.";
      }];
      boot.loader.grub = {
        enable = true;
        extraInstallCommands = lib.mkIf cfg.grubRegisterFallback ''
          ${lib.getExe registerGrubFallback} ${lib.escapeShellArg config.boot.loader.efi.efiSysMountPoint}
        '';
        device = config.boot.loader.custom.grubDevice;
        useOSProber = config.boot.loader.custom.grubUseOSProber;
        efiSupport = true;
        efiInstallAsRemovable = config.boot.loader.custom.grubEfiInstallAsRemovable;
        gfxmodeBios = lib.mkIf (
          config.boot.loader.custom.grubGfxMode != ""
        ) config.boot.loader.custom.grubGfxMode;
      };
    })
  ];
}
