{ config, lib, pkgs, ... }:

{
  imports = [
    ./waybar.nix
  ];

  home.packages = with pkgs; [
    grim
    slurp
    wl-clipboard
    mako

    playerctl
    pavucontrol
    xdg-user-dirs # auto create dirs
  ];

  wayland.windowManager.sway = {
    enable = true;
    config = rec {
      modifier = "Mod4";
      terminal = "alacritty";
      window.titlebar = false;
      gaps = {
        inner = 5;
        outer = 10;
        smartBorders = "on";
      };
      menu = "wofi --show drun -p \"app:\" -L 10";
      bars = [];
      keybindings = let
        mod = config.wayland.windowManager.sway.config.modifier;
        grim = "${pkgs.grim}/bin/grim";
        slurp = "${pkgs.slurp}/bin/slurp";
        screenshotLocation = "${config.xdg.userDirs.pictures}/Screenshots/scrn-$(date +'%Y-%m-%d-%H-%M-%S.png')";
        #            screenshotSound = "${pkgs.alsa-utils}/bin/aplay ${./camera.wav}";
      in lib.mkOptionDefault {
        # Full screen TODO add screenshot sound
#        "Print" = "exec ${grim} ${screenshotLocation} && ${screenshotSound}";
        "${mod}+Print" = "exec ${grim} ${screenshotLocation}";
        # A region of the screen
        "${mod}+Shift+Print" = "exec ${slurp} | ${grim} -g - ${screenshotLocation}";
        # Volume increase
        "XF86AudioRaiseVolume" = " exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
        # Decrease Volume
        "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
      };
      input = {
        "*" = {
          xkb_options = "caps:ctrl_modifier";
        };
      };
    };
  };

  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.gnome.adwaita-icon-theme;
    size = 24;
    x11 = {
      enable = true;
      defaultCursor = "Adwaita";
    };
  };

  programs.wofi.enable = true;
}
