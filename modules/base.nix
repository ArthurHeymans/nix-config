{
  lib,
  pkgs,
  hostname,
  username,
  ...
}:
{
  imports = [
    ./bash.nix
    ./boot.nix
    ./firmware.nix
    ./locale.nix
    ./oom.nix
    ./tailscale.nix
    ./users.nix
    ./zswap.nix
  ];

  # Use the newest kernel by default.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Set hostname from flake configuration.
  networking.hostName = hostname;

  # Customise /etc/nix/nix.conf declaratively via `nix.settings`.
  nix.settings = {
    builders-use-substitutes = true;
    experimental-features = [
      "flakes"
      "nix-command"
    ];
    substituters = [
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    trusted-users = [ username ];
  };

  # Replace nix.gc with nh clean: keeps the last 5 generations across all
  # profiles, removes stale gcroots, and runs nix store gc afterwards.
  nix.gc.automatic = lib.mkDefault false;

  systemd.services.nh-clean = {
    description = "Clean old Nix generations with nh";
    startAt = lib.mkDefault "daily";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.nh}/bin/nh clean all --keep 5 --no-ask";
      Nice = 10;
      IOSchedulingClass = "idle";
    };
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    btop
    curl
    dmidecode
    dnsutils
    ethtool
    eza
    git
    htop
    jq
    nh
    lm_sensors
    lsof
    nload
    pciutils
    ripgrep
    rsync
    smartmontools
    sysstat
    tree
    usbutils
    vim
    wget
  ];

  system.autoUpgrade = {
    enable = lib.mkDefault true;
    flake = "github:ArthurHeymans/nix-config";
    dates = lib.mkDefault "04:00";
    allowReboot = lib.mkDefault false;
  };
}
