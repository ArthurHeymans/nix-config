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
      package = pkgs.gnome.adwaita-icon-theme;
    };
  };

  imports = [ ./waybar.nix ];

  home.packages = with pkgs; [
    grim
    slurp
    wl-clipboard
    mako

    playerctl
    pavucontrol
    xdg-user-dirs # auto create dirs

    networkmanagerapplet
  ];

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
      menu = "fuzzel";
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
    package = pkgs.gnome.adwaita-icon-theme;
    size = 24;
    x11 = {
      enable = true;
      defaultCursor = "Adwaita";
    };
  };

  #programs.wofi.enable = true;
  programs.fuzzel.enable = true;

  services.gammastep = {
    enable = true;
    provider = "manual";
    latitude = 50.0;
    longitude = 4.0;
    temperature.day = 5700;
    temperature.night = 3500;
    tray = true;
    settings = {
      general.adjustment-method = "wayland";
    };
  };

  services.blueman-applet.enable = true;

  services.mako = {
    enable = true;
    height = 1000;
  };
}
