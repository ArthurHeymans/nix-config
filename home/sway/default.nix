{
  config,
  hostname,
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
      terminal = "kitty";
      window.titlebar = false;
      gaps = {
        inner = 5;
        outer = 10;
        smartBorders = "on";
      };
      menu = "rofi -show drun -show-icons";
      bars = [ { command = "waybar"; } ];

      colors = {
        focused = {
          border = "#33ccff";
          background = "#285577";
          text = "#ffffff";
          indicator = "#00ff99";
          childBorder = "#33ccff";
        };
        unfocused = {
          border = "#595959";
          background = "#222222";
          text = "#888888";
          indicator = "#595959";
          childBorder = "#595959";
        };
      };

      keybindings =
        let
          mod = config.wayland.windowManager.sway.config.modifier;
          grim = "${pkgs.grim}/bin/grim";
          slurp = "${pkgs.slurp}/bin/slurp";
          screenshotLocation = "${config.xdg.userDirs.pictures}/Screenshots/scrn-$(date +'%Y-%m-%d-%H-%M-%S.png')";
        in
        lib.mkOptionDefault {
          # Terminal
          "${mod}+Return" = "exec ${terminal}";

          # Kill / exit
          "${mod}+Shift+q" = "kill";
          "${mod}+Shift+e" = "exec swaynag -t warning -m 'Exit sway?' -B 'Yes' 'swaymsg exit'";

          # Floating & layout
          "${mod}+v" = "floating toggle";
          "${mod}+f" = "fullscreen toggle";

          # Application launcher
          "${mod}+d" = "exec ${menu}";

          # Clipboard history (matches Hyprland Super+Y)
          "${mod}+y" = "exec cliphist list | rofi -dmenu | cliphist decode | wl-copy";

          # Focus movement (arrow keys)
          "${mod}+Left" = "focus left";
          "${mod}+Right" = "focus right";
          "${mod}+Up" = "focus up";
          "${mod}+Down" = "focus down";

          # Window movement (arrow keys)
          "${mod}+Shift+Left" = "move left";
          "${mod}+Shift+Right" = "move right";
          "${mod}+Shift+Up" = "move up";
          "${mod}+Shift+Down" = "move down";

          # Move workspace to monitor (matches Hyprland Super+Shift+Ctrl+arrow)
          "${mod}+Shift+Control+Left" = "move workspace to output left";
          "${mod}+Shift+Control+Right" = "move workspace to output right";

          # Workspace 10 (matches Hyprland Super+0)
          "${mod}+0" = "workspace number 10";
          "${mod}+Shift+0" = "move container to workspace number 10";

          # Screenshots
          "${mod}+Print" = "exec ${grim} ${screenshotLocation}";
          "${mod}+Shift+Print" = "exec ${slurp} | ${grim} -g - ${screenshotLocation}";

          # Volume (matches Hyprland bindel)
          "XF86AudioRaiseVolume" = "exec wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+";
          "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
          "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          "XF86AudioMicMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";

          # Brightness (matches Hyprland bindel)
          "XF86MonBrightnessUp" = "exec brightnessctl s 10%+";
          "XF86MonBrightnessDown" = "exec brightnessctl s 10%-";

          # Media keys (matches Hyprland bindl)
          "XF86AudioNext" = "exec playerctl next";
          "XF86AudioPause" = "exec playerctl play-pause";
          "XF86AudioPlay" = "exec playerctl play-pause";
          "XF86AudioPrev" = "exec playerctl previous";

          # Dismiss notifications (matches Hyprland Ctrl+Shift+Space)
          "Control+Shift+Space" = "exec makoctl dismiss --all";
        };

      input = {
        "*" = {
          xkb_options = "caps:ctrl_modifier";
        };
        "type:touchpad" = {
          natural_scroll = "disabled";
        };
        "1739:0:Synaptics_TM3276-022" = {
          events = "disabled";
        };
        "1133:45913:ERGO_K860_Keyboard" = {
          xkb_options = "ctrl:swap_lwin_lctl,caps:ctrl_modifier";
          xkb_numlock = "enabled";
        };
        "6127:24814:Lenovo_TrackPoint_Keyboard_II" = {
          pointer_accel = if hostname == "t480-arthur" then "1" else "0";
        };
      };

      output = {
        "*" = {
          bg = "${./bg.jpg} fill";
        };
        "Dell Inc. DELL U2312HM KF87Y31VC5AL" = {
          position = "1920 0";
          transform = "270";
        };
        "Dell Inc. DELL P3424WE 7DJF6T3" = {
          position = "3000 0";
        };
      };

      startup = [
        { command = "wl-paste --type text --watch cliphist store"; }
        { command = "wl-paste --type image --watch cliphist store"; }
      ];
    };

    extraConfig = ''
      # Lid switch handling (matches Hyprland bindl switch)
      bindswitch --reload --locked lid:on output eDP-1 disable, output LVDS-1 disable
      bindswitch --reload --locked lid:off output eDP-1 enable, output LVDS-1 enable

      # Emacs window rules (matches Hyprland windowrulev2)
      for_window [app_id="emacs"] focus
    '';
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

  programs.rofi = {
    enable = true;
  };
}
