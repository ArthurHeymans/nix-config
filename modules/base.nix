{
  lib,
  pkgs,
  hostname,
  username,
  ...
}: {
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
    trusted-users = [username];
  };

  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "monthly";
    options = lib.mkDefault "--delete-older-than 7d";
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
