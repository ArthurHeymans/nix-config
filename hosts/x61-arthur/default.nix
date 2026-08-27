{
  inputs,
  pkgs,
  username,
  ...
}:
let
  syscGreet = inputs.sysc-greet.packages.${pkgs.stdenv.hostPlatform.system}.default;

  footConfig = pkgs.writeText "sysc-greet-foot.ini" ''
    [main]
    font=monospace:size=11
    pad=0x0

    [colors-dark]
    alpha=1.0
  '';

in
{
  imports = [
    ../../modules/system.nix
    ./hardware-configuration.nix
    inputs.disko.nixosModules.disko
    ./disk-config.nix
  ];

  # Keep a BIOS GRUB install on the disk for SeaBIOS boots, but let UEFI
  # installs update Boot####/BootOrder for CrabEFI instead of relying on the
  # removable fallback path.
  boot.loader.custom = {
    bootloader = "grub";
    grubDevice = "/dev/disk/by-path/pci-0000:00:1f.2-ata-1.0";
    grubGfxMode = "1024x768";
    grubEfiInstallAsRemovable = false;
  };

  users.users.greeter = {
    isSystemUser = true;
    group = "greeter";
    home = "/var/lib/greeter";
    createHome = true;
  };
  users.groups.greeter = { };

  environment.pathsToLink = [ "/share/wayland-sessions" ];
  environment.systemPackages = [
    syscGreet
    pkgs.foot
  ];

  services.greetd = {
    enable = true;
    settings = {
      terminal.vt = 1;
      default_session = {
        command = "${pkgs.hyprland}/bin/Hyprland -c /etc/greetd/hyprland-greeter-config.conf";
        user = "greeter";
      };
    };
  };

  environment.etc = {
    "greetd/foot.ini".source = footConfig;
    "greetd/hyprland-greeter-config.conf".source =
      "${syscGreet}/etc/greetd/hyprland-greeter-config.conf";
  };

  systemd.tmpfiles.rules = [
    "d /var/cache/sysc-greet 0755 greeter greeter -"
    "L+ /usr/share/sysc-greet - - - - ${syscGreet}/share/sysc-greet"
  ];

  security.polkit.enable = true;

  system.stateVersion = "24.05";
  home-manager.users.${username}.home.stateVersion = "24.11";
}
