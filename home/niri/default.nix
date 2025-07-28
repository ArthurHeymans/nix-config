{ config, lib, pkgs, ... }:

{
  programs.niri = {
    enable = true;
    settings = {
      prefer-no-csd = true;

      # Input configuration
      input = {
        keyboard = {
          xkb = {
            options = "caps:ctrl_modifier";
          };
          numlock = true;
        };

        touchpad = {
          natural-scroll = false;
          tap = true;
          dwt = true;
        };

        mouse = {
          accel-speed = 0.0;
        };
      };

      # Layout settings
      layout = {
        gaps = 10;
        center-focused-column = "never";
        background-color = "#1e1e2e";

        preset-column-widths = [
          { proportion = 0.33333; }
          { proportion = 0.5; }
          { proportion = 0.66667; }
        ];

        default-column-width = { proportion = 0.5; };

        focus-ring = {
          enable = true;
          width = 2;
          active.color = "#33ccff";
          inactive.color = "#595959";
        };

        border = {
          enable = false;
        };
      };

      # Window rules for rounded corners (like hyprland rounding = 10)
      window-rules = [
        {
          geometry-corner-radius = {
            top-left = 10.0;
            top-right = 10.0;
            bottom-left = 10.0;
            bottom-right = 10.0;
          };
          clip-to-geometry = true;
        }
      ];

      # Animation settings
      animations = {
        enable = true;

        horizontal-view-movement = {
          kind.easing = {
            duration-ms = 300;
            curve = "ease-out-cubic";
          };
        };

        window-open = {
          kind.easing = {
            duration-ms = 150;
            curve = "ease-out-expo";
          };
        };

        window-close = {
          kind.easing = {
            duration-ms = 150;
            curve = "ease-out-expo";
          };
        };

        workspace-switch = {
          kind.easing = {
            duration-ms = 200;
            curve = "ease-out-cubic";
          };
        };
      };

      # Spawn at startup
      spawn-at-startup = [
        { command = ["waybar"]; }
        { command = ["wl-paste" "--type" "text" "--watch" "cliphist" "store"]; }
        { command = ["wl-paste" "--type" "image" "--watch" "cliphist" "store"]; }
        { command = ["netbird-ui"]; }
        { command = ["sh" "-c" "mkdir -p ~/Pictures/Screenshots"]; }
        { command = ["swaybg" "-i" "${../sway/bg.jpg}" "-m" "fill"]; }
      ];

      # Monitor configuration
      outputs = {
        "Dell Inc. DELL U2312HM KF87Y31VC5AL" = {
          position = { x = 1920; y = 0; };
          transform.rotation = 90;
        };

        "Dell Inc. DELL P3424WE 7DJF6T3" = {
          position = { x = 3000; y = 0; };
        };
      };

      # Environment variables
      environment = {
        XCURSOR_SIZE = "24";
      };

      # Screenshot configuration
      screenshot-path = "~/Pictures/Screenshots/scrn-%Y-%m-%d-%H-%M-%S.png";

      # Keybindings
      binds = with config.lib.niri.actions; {
        # Basic window management
        "Mod+Return".action = spawn "kitty";
        "Mod+Shift+Q".action = close-window;
        "Mod+Shift+E".action = quit;
        "Mod+V".action = toggle-window-floating;
        "Mod+D".action = spawn "rofi" "-show" "drun" "-show-icons";
        "Mod+Y".action = spawn "sh" "-c" "cliphist list | rofi -dmenu | cliphist decode | wl-copy";
        "Mod+P".action = toggle-column-tabbed-display;
        "Mod+F".action = maximize-column;
        "Mod+Shift+F".action = fullscreen-window;

        # Focus movement (arrow keys)
        "Mod+Left".action = focus-column-left;
        "Mod+Right".action = focus-column-right;
        "Mod+Up".action = focus-window-up;
        "Mod+Down".action = focus-window-down;

        # Focus movement (vim-like)
        "Mod+H".action = focus-column-left;
        "Mod+L".action = focus-column-right;
        "Mod+K".action = focus-window-up;
        "Mod+J".action = focus-window-down;

        # Move windows (arrow keys)
        "Mod+Shift+Left".action = move-column-left;
        "Mod+Shift+Right".action = move-column-right;
        "Mod+Shift+Up".action = move-window-up;
        "Mod+Shift+Down".action = move-window-down;

        # Move windows (vim-like)
        "Mod+Shift+H".action = move-column-left;
        "Mod+Shift+L".action = move-column-right;
        "Mod+Shift+K".action = move-window-up;
        "Mod+Shift+J".action = move-window-down;

        # Move workspaces between monitors
        "Mod+Shift+Ctrl+Left".action = move-workspace-to-monitor-left;
        "Mod+Shift+Ctrl+Right".action = move-workspace-to-monitor-right;

        # Column/window manipulation
        "Mod+BracketLeft".action = consume-or-expel-window-left;
        "Mod+BracketRight".action = consume-or-expel-window-right;
        "Mod+R".action = switch-preset-column-width;
        "Mod+Shift+R".action = switch-preset-window-height;
        "Mod+C".action = center-column;

        # Workspace navigation
        "Mod+Page_Down".action = focus-workspace-down;
        "Mod+Page_Up".action = focus-workspace-up;
        "Mod+U".action = focus-workspace-down;
        "Mod+I".action = focus-workspace-up;

        # Move windows between workspaces
        "Mod+Ctrl+Page_Down".action = move-column-to-workspace-down;
        "Mod+Ctrl+Page_Up".action = move-column-to-workspace-up;
        "Mod+Ctrl+U".action = move-column-to-workspace-down;
        "Mod+Ctrl+I".action = move-column-to-workspace-up;

        # Numbered workspaces
        "Mod+1".action = focus-workspace 1;
        "Mod+2".action = focus-workspace 2;
        "Mod+3".action = focus-workspace 3;
        "Mod+4".action = focus-workspace 4;
        "Mod+5".action = focus-workspace 5;
        "Mod+6".action = focus-workspace 6;
        "Mod+7".action = focus-workspace 7;
        "Mod+8".action = focus-workspace 8;
        "Mod+9".action = focus-workspace 9;
        "Mod+0".action = focus-workspace 10;

        # Move to numbered workspaces
        "Mod+Shift+1".action.move-column-to-workspace = 1;
        "Mod+Shift+2".action.move-column-to-workspace = 2;
        "Mod+Shift+3".action.move-column-to-workspace = 3;
        "Mod+Shift+4".action.move-column-to-workspace = 4;
        "Mod+Shift+5".action.move-column-to-workspace = 5;
        "Mod+Shift+6".action.move-column-to-workspace = 6;
        "Mod+Shift+7".action.move-column-to-workspace = 7;
        "Mod+Shift+8".action.move-column-to-workspace = 8;
        "Mod+Shift+9".action.move-column-to-workspace = 9;
        "Mod+Shift+0".action.move-column-to-workspace = 10;

        # Screenshots
        "Mod+Print".action = screenshot;
        "Mod+Shift+Print".action = screenshot-window;

        # Audio controls
        "XF86AudioRaiseVolume" = {
          action = spawn "wpctl" "set-volume" "-l" "1" "@DEFAULT_AUDIO_SINK@" "5%+";
          allow-when-locked = true;
        };
        "XF86AudioLowerVolume" = {
          action = spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-";
          allow-when-locked = true;
        };
        "XF86AudioMute" = {
          action = spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle";
          allow-when-locked = true;
        };
        "XF86AudioMicMute" = {
          action = spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle";
          allow-when-locked = true;
        };

        # Brightness controls
        "XF86MonBrightnessUp" = {
          action = spawn "brightnessctl" "s" "10%+";
          allow-when-locked = true;
        };
        "XF86MonBrightnessDown" = {
          action = spawn "brightnessctl" "s" "10%-";
          allow-when-locked = true;
        };

        # Media controls
        "XF86AudioNext" = {
          action = spawn "playerctl" "next";
          allow-when-locked = true;
        };
        "XF86AudioPause" = {
          action = spawn "playerctl" "play-pause";
          allow-when-locked = true;
        };
        "XF86AudioPlay" = {
          action = spawn "playerctl" "play-pause";
          allow-when-locked = true;
        };
        "XF86AudioPrev" = {
          action = spawn "playerctl" "previous";
          allow-when-locked = true;
        };

        # Notifications
        "Ctrl+Shift+Space".action = spawn "makoctl" "dismiss" "--all";

        # Overview
        "Mod+O".action = toggle-overview;

        # Column width adjustments
        "Mod+Minus".action = set-column-width "-10%";
        "Mod+Equal".action = set-column-width "+10%";

        # Window height adjustments
        "Mod+Shift+Minus".action = set-window-height "-10%";
        "Mod+Shift+Equal".action = set-window-height "+10%";
      };
    };
  };
}
