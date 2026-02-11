{ pkgs, inputs, ... }:
let
  # jay-git = pkgs.callPackage pkgs.jay.override {
  #   rustPlatform = pkgs.rustPlatform // {
  #     buildRustPackage =
  #       args:
  #       pkgs.rustPlatform.buildRustPackage (
  #         args
  #         // {
  #           src = pkgs.fetchFromGitHub {
  #             owner = "mahkoh";
  #             repo = "jay";
  #             rev = "c6cebc754681eebb042a020e73aab2d6f71cc857";
  #             hash = "sha256-i0ZtruAtpYDqdZrYa+FY+g9bZPDzFMfxJtfiMPnYLL0=";
  #           };
  #           cargoHash = "sha256-+5+jS4dCFE8hkkHAA4BcB+xtr4UF+px9iVPuQAIijwk=";
  #         }
  #       );
  #   };
  # };
in
{
  programs.dconf.enable = true;

  # greetd with tuigreet
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd 'niri-session'";
        user = "greeter";
      };
    };
  };

  environment.etc."greetd/environments".text = ''
    niri
    sway
    Hyprland
    bash
  '';

  services.dbus.packages = [ pkgs.gcr ];

  programs.sway.enable = true;

  #environment.systemPackages = with pkgs; [
  #  jay-git
  #];

  programs.uwsm = {
    enable = true;
    waylandCompositors = {
      niri = {
        prettyName = "Niri (UWSM)";
        comment = "Niri compositor managed by UWSM";
        binPath = "/run/current-system/sw/bin/niri-session";
      };
      # jay = {
      #   prettyName = "Jay";
      #   binPath = "/run/current-system/sw/bin/jay";
      #   extraArgs = [ "run" ];
      # };
    };
  };
  programs.hyprland.withUWSM = true;

  programs.hyprland.enable = true;
  programs.niri.enable = true;
  programs.niri.package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable; # recent-windows requires 25.11+
}
