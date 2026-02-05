{
  config,
  lib,
  pkgs,
  ...
}:
{
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
  };

  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    config = rec {
      modifier = "Mod4";
      terminal = "alacritty";
      window.titlebar = false;
      gaps = {
        inner = 5;
        outer = 2;
        smartBorders = "on";
      };
      #menu = "wofi --show drun -p \"app:\" -L 10";
      #menu = "fuzzel";
      menu = "rofi -show drun -show-icons";
      bars = [ { command = "waybar"; } ];
      keybindings =
        let
          mod = config.wayland.windowManager.sway.config.modifier;
          grim = "${pkgs.grim}/bin/grim";
          slurp = "${pkgs.slurp}/bin/slurp";
          screenshotLocation = "${config.xdg.userDirs.pictures}/Screenshots/scrn-$(date +'%Y-%m-%d-%H-%M-%S.png')";
        in
        #            screenshotSound = "${pkgs.alsa-utils}/bin/aplay ${./camera.wav}";
        lib.mkOptionDefault {
          # Full screen TODO add screenshot sound
          #        "Print" = "exec ${grim} ${screenshotLocation} && ${screenshotSound}";
          "${mod}+Print" = "exec ${grim} ${screenshotLocation}";
          # A region of the screen
          "${mod}+Shift+Print" = "exec ${slurp} | ${grim} -g - ${screenshotLocation}";
          # Volume increase
          "XF86AudioRaiseVolume" = " exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
          # Decrease Volume
          "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
          # Clear notification
          "Control+Shift+Space" = "exec makoctl dismiss --all";
        };
      input = {
        "*" = {
          xkb_options = "caps:ctrl_modifier";
        };
      };
      output = {
        "*" = {
          bg = "${./bg.jpg} fill";
        };
      };
    };
  };

  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    x11 = {
      enable = true;
      defaultCursor = "Adwaita";
    };
  };

  #programs.wofi.enable = true;
  #programs.fuzzel.enable = true;
  programs.rofi = {
    enable = true;
  };

}
