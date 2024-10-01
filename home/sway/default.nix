{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    grim
    slurp
    wl-clipboard
    mako

    xdg-user-dirs # auto create dirs
  ];

  wayland.windowManager.sway = {
    enable = true;
    config = rec {
      modifier = "Mod4";
      terminal = "alacritty";
      window.titlebar = false;
      keybindings = let
        mod = config.wayland.windowManager.sway.config.modifier;
        grim = "${pkgs.grim}/bin/grim";
        slurp = "${pkgs.slurp}/bin/slurp";
        screenshotLocation = "${config.xdg.userDirs.pictures}/Screenshots/scrn-$(date +'%Y-%m-%d-%H-%M-%S.png')";
        #            screenshotSound = "${pkgs.alsa-utils}/bin/aplay ${./camera.wav}";
      in lib.mkOptionDefault {
        # Full screen
#        "Print" = "exec ${grim} ${screenshotLocation} && ${screenshotSound}";
        "${mod}+Print" = "exec ${grim} ${screenshotLocation}";
        # A region of the screen
        "${mod}+Shift+Print" = "exec ${slurp} | ${grim} -g - ${screenshotLocation}";
      };
    };
  };
}
