{pkgs, ...}:
let
  jay-git = pkgs.callPackage pkgs.jay.override {
    rustPlatform = pkgs.rustPlatform // {
      buildRustPackage = args: pkgs.rustPlatform.buildRustPackage (args // {
        src = pkgs.fetchFromGitHub {
          owner = "mahkoh";
          repo = "jay";
          rev = "a2e21cb926664cfc1980f8a38ec1aa34a7792c19";
          hash = "sha256-uhTi2CWSuLq+mgclcZwTSp1i2BKAqs7vt2wL9MJH+UE=";
        };
        cargoHash = "sha256-+5+jS4dCFE8hkkHAA4BcB+xtr4UF+px9iVPuQAIijwk=";
      });
    };
  };
in
{
  programs.dconf.enable = true;

  # greetd with tuigreet
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
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

  services.dbus.packages = [pkgs.gcr];

  programs.sway.enable = true;

  environment.systemPackages = with pkgs; [
    jay-git
    ];

  # services.displayManager.sessionPackages = [ pkgs.jay ];
   # Create a session file for Jay
  environment.etc."wayland-sessions/jay.desktop".text = ''
    [Desktop Entry]
    Name=Jay
    Comment=Jay Wayland Compositor
    Exec=jay
    Type=Application
  '';

  programs.uwsm = {
    enable = true;
    waylandCompositors = {
      niri = {
        prettyName = "Niri (UWSM)";
        comment = "Niri compositor managed by UWSM";
        binPath = "/run/current-system/sw/bin/niri-session";
      };
    };
  };
  programs.hyprland.withUWSM = true;

  programs.hyprland.enable = true;
  programs.niri.enable = true;
}
