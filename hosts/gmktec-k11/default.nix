{
  config,
  lib,
  pkgs,
  inputs,
  username,
  ...
}:
{
  imports = [
    ../../modules/system.nix
    ../../modules/nix-serve.nix
    ../../modules/nix-auto-update.nix
    ../../modules/pi-web.nix
    ../../modules/openrgb.nix
    ./hardware-configuration.nix
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  networking.networkmanager = {
    # Do not let NetworkManager auto-create a competing standalone DHCP
    # profile for eno1; eno1 should be a port of br0 instead.
    settings.main.no-auto-default = "*";

    ensureProfiles.profiles = {
      br0 = {
        connection = {
          id = "br0";
          type = "bridge";
          interface-name = "br0";
          autoconnect = true;
          autoconnect-priority = 100;
          autoconnect-slaves = 1;
        };
        ipv4.method = "auto";
        ipv6.method = "auto";
        bridge = {
          mac-address = "c8:ff:bf:01:c7:4d";
          stp = false;
        };
      };

      "br0-eno1" = {
        connection = {
          id = "br0-eno1";
          type = "ethernet";
          interface-name = "eno1";
          master = "br0";
          slave-type = "bridge";
          autoconnect = true;
          autoconnect-priority = 100;
        };
      };
    };
  };

  environment.systemPackages = [
    pkgs.sbctl
  ];

  services.hardware.openrgb.motherboard = "amd";

  # RTX 3090 (Ampere). Use NVIDIA's open kernel modules with the
  # proprietary userspace driver.
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # lanzaboote replaces systemd
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.custom.bootloader = "none";

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  boot.initrd.systemd.enable = true;

  system.stateVersion = "24.05";
  home-manager.users.${username}.home.stateVersion = "24.11";
}
