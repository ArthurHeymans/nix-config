{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  niriPackage = config.programs.niri.package;
  syscGreet = inputs.sysc-greet.packages.${pkgs.stdenv.hostPlatform.system}.default;

  footConfig = pkgs.writeText "sysc-greet-foot.ini" ''
    [main]
    font=monospace:size=11
    pad=0x0

    [colors-dark]
    alpha=1.0
  '';

  niriGreeterConfig = pkgs.writeText "x61-niri-greeter-config.kdl" ''
    hotkey-overlay {
        skip-at-startup
    }

    input {
        keyboard {
            xkb {
                layout "us"
            }
            repeat-delay 400
            repeat-rate 40
        }

        touchpad {
            tap
        }
    }

    gestures {
        hot-corners {
            off
        }
    }

    layout {
        gaps 0
        center-focused-column "never"

        focus-ring {
            off
        }

        border {
            off
        }
    }

    animations {
        off
    }

    window-rule {
        match app-id="sysc-greet-foot"
        opacity 1.0
    }

    spawn-sh-at-startup "XDG_CACHE_HOME=/tmp/greeter-cache HOME=/var/lib/greeter ${pkgs.foot}/bin/foot --fullscreen --app-id=sysc-greet-foot --config=${footConfig} ${syscGreet}/bin/sysc-greet; ${niriPackage}/bin/niri msg action quit --skip-confirmation"

    binds {
    }
  '';

  greeterPolkitRule = pkgs.writeText "85-greeter.rules" ''
    polkit.addRule(function(action, subject) {
        if ((action.id == "org.freedesktop.login1.power-off" ||
             action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
             action.id == "org.freedesktop.login1.reboot" ||
             action.id == "org.freedesktop.login1.reboot-multiple-sessions") &&
            subject.user == "greeter") {
            return polkit.Result.YES;
        }
    });
  '';
in {
  imports = [
    ../../modules/system.nix
    ./hardware-configuration.nix
    inputs.disko.nixosModules.disko
    ./disk-config.nix
  ];

  # Install like x201: BIOS GRUB today, with an ESP for future UEFI boot.
  boot.loader.custom = {
    bootloader = "grub";
    grubDevice = "/dev/disk/by-path/pci-0000:00:1f.2-ata-1.0";
    grubGfxMode = "1024x768";
    grubEfiInstallAsRemovable = true;
  };

  services.sysc-greet.enable = lib.mkForce false;

  users.users.greeter = {
    isSystemUser = true;
    group = "greeter";
    home = "/var/lib/greeter";
    createHome = true;
  };
  users.groups.greeter = {};

  environment.pathsToLink = ["/share/wayland-sessions"];
  environment.systemPackages = [
    syscGreet
    pkgs.foot
  ];

  services.greetd = {
    enable = true;
    settings = {
      terminal.vt = 1;
      default_session = {
        command = "${niriPackage}/bin/niri -c /etc/greetd/niri-greeter-config.kdl";
        user = "greeter";
      };
    };
  };

  environment.etc = {
    "greetd/foot.ini".source = footConfig;
    "greetd/niri-greeter-config.kdl".source = niriGreeterConfig;
    "polkit-1/rules.d/85-greeter.rules".source = greeterPolkitRule;
  };

  systemd.tmpfiles.rules = [
    "d /var/cache/sysc-greet 0755 greeter greeter -"
    "L+ /usr/share/sysc-greet - - - - ${syscGreet}/share/sysc-greet"
  ];

  security.polkit.enable = true;
}
