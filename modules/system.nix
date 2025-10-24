{ lib, inputs, ... }: {
  imports = [
    # Determinate Nix/Nixd NixOS module (manages nix.conf via nix.custom.conf)
    inputs.determinate.nixosModules.default

    ./bash.nix
    ./bluetooth.nix
    ./desktop.nix
    ./firmware.nix
    ./fonts.nix
    ./geoclue.nix
    ./gvfs.nix
    #./llm.nix
    ./locale.nix
    ./networking.nix
    ./graphics.nix
    ./packages.nix
    ./printing.nix
    ./security.nix
    ./tailscale.nix
    ./netbird.nix
    ./sound.nix
    ./udev.nix
    ./users.nix
    ./virtualisation.nix
    ./zswap.nix
  ];

  # customise /etc/nix/nix.conf declaratively via `nix.settings`
  nix.settings = {
    # enable flakes globally
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    substituters = [
      # cache mirror located in China
      # status: https://mirror.sjtu.edu.cn/
      # "https://mirror.sjtu.edu.cn/nix-channels/store"
      # status: https://mirrors.ustc.edu.cn/status/
      # "https://mirrors.ustc.edu.cn/nix-channels/store"

      "https://cache.nixos.org"
    ];

    trusted-public-keys = ["cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="];

    # extra-substituters = [
    #   "https://niri.cachix.org"
    # ];

    # extra-trusted-public-keys = [
    #   "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
    # ];

    builders-use-substitutes = true;
  };

  # do garbage collection weekly to keep disk usage low
  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "monthly";
    options = lib.mkDefault "--delete-older-than 7d";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
}
