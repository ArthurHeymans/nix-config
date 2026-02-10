{
  config,
  pkgs,
  inputs,
  hostname,
  ...
}:

{
  home.packages = [
    inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.awww
  ];

  # Swaylock — lock screen (mirrors hyprlock settings)
  programs.swaylock = {
    enable = true;
    settings = {
      image = "~/Pictures/lock.jpg";
      show-failed-attempts = true;
    };
  };

  # Swayidle — idle management (mirrors hypridle timeouts)
  # Not using services.swayidle because all compositor modules are imported
  # unconditionally; a systemd service would also run under hyprland/sway.
  # Spawning via niri's spawn-at-startup keeps it scoped to niri sessions.

  # niri.nixosModules.niri handles programs.niri.enable, portals, and polkit.
  # It auto-imports homeModules.config, so we only set programs.niri.settings here.
  programs.niri.settings = {
    prefer-no-csd = true;

    # Input configuration (matches hyprland)
    input = {
      keyboard = {
        xkb = {
          layout = "us";
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

      warp-mouse-to-focus.enable = true;
      focus-follows-mouse.enable = true;
    };

    # Layout settings (gaps match hyprland: gaps_in=5, gaps_out=10)
    layout = {
      gaps = 10;
      center-focused-column = "never";

      preset-column-widths = [
        { proportion = 0.33333; }
        { proportion = 0.5; }
        { proportion = 0.66667; }
      ];

      default-column-width = {
        proportion = 0.5;
      };

      focus-ring = {
        enable = true;
        width = 2;
        active.gradient = {
          from = "#33ccff";
          to = "#00ff99";
          angle = 45;
        };
        inactive.color = "#595959";
      };

      border = {
        enable = false;
      };
    };

    # Window rules for rounded corners (matches hyprland rounding = 10)
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
      # Emacs workspace rule (matches hyprland windowrulev2)
      {
        matches = [ { app-id = "^emacs$"; } ];
        open-on-workspace = "emacs";
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

    # Spawn at startup (matches hyprland exec-once)
    spawn-at-startup = [
      { command = [ "waybar" ]; }
      { command = [ "awww-daemon" ]; }
      {
        command = [
          "wl-paste"
          "--type"
          "text"
          "--watch"
          "cliphist"
          "store"
        ];
      }
      {
        command = [
          "wl-paste"
          "--type"
          "image"
          "--watch"
          "cliphist"
          "store"
        ];
      }
      {
        command = [
          "swayidle"
          "-w"
          "timeout"
          "300"
          "loginctl lock-session"
          "timeout"
          "600"
          "niri msg action power-off-monitors"
          "before-sleep"
          "loginctl lock-session"
          "lock"
          "sh -c 'pidof swaylock || swaylock -fF'"
        ];
      }
#      { command = [ "netbird-ui" ]; }
      { command = [ "nm-applet" ]; }
      { command = [ "kdeconnect-indicator" ]; }
      {
        command = [
          "sh"
          "-c"
          "mkdir -p ~/Pictures/Screenshots"
        ];
      }
      {
        command = [
          "swaybg"
          "-i"
          "${../sway/bg.jpg}"
          "-m"
          "fill"
        ];
      }
    ];

    # Monitor configuration (matches hyprland monitor rules)
    outputs = {
      "Dell Inc. DELL U2312HM KF87Y31VC5AL" = {
        position = {
          x = 1920;
          y = 0;
        };
        transform.rotation = 90;
      };

      "Dell Inc. DELL P3424WE 7DJF6T3" = {
        position = {
          x = 3000;
          y = 0;
        };
      };
    };

    # Environment variables (matches hyprland env)
    environment = {
      XCURSOR_SIZE = "24";
      NIXOS_OZONE_WL = "1";
    };

    # Screenshot configuration
    screenshot-path = "~/Pictures/Screenshots/scrn-%Y-%m-%d-%H-%M-%S.png";

    # Keybindings — mirrors hyprland where possible, niri-native otherwise
    binds = with config.lib.niri.actions; {
      # ── Basic window management (same as hyprland) ──────────────
      "Mod+Return".action = spawn "kitty";
      "Mod+Shift+Q".action = close-window;
      "Mod+Shift+E".action = quit;
      "Mod+V".action = toggle-window-floating;
      "Mod+D".action = spawn "rofi" "-show" "drun" "-show-icons";
      "Mod+W".action = spawn "rofi" "-show" "window" "-show-icons";
      "Mod+Y".action = spawn "sh" "-c" "cliphist list | rofi -dmenu | cliphist decode | wl-copy";

      # ── Fullscreen / maximize (niri splits these concepts) ──────
      "Mod+F".action = maximize-column;
      "Mod+Shift+F".action = fullscreen-window;

      # ── Niri-native column management ───────────────────────────
      "Mod+P".action = toggle-column-tabbed-display;
      "Mod+R".action = switch-preset-column-width;
      "Mod+Shift+R".action = switch-preset-window-height;
      "Mod+C".action = center-column;
      "Mod+BracketLeft".action = consume-or-expel-window-left;
      "Mod+BracketRight".action = consume-or-expel-window-right;

      # ── Focus movement (arrow keys — same as hyprland) ──────────
      "Mod+Left".action = focus-column-left;
      "Mod+Right".action = focus-column-right;
      "Mod+Up".action = focus-window-up;
      "Mod+Down".action = focus-window-down;

      # ── Focus movement (vim keys — same as hyprland) ────────────
      "Mod+H".action = focus-column-left;
      "Mod+L".action = focus-column-right;
      "Mod+K".action = focus-window-up;
      "Mod+J".action = focus-window-down;

      # ── Focus monitor ──────────────────────────────────────────
      "Mod+Ctrl+Left".action = focus-monitor-left;
      "Mod+Ctrl+Right".action = focus-monitor-right;
      "Mod+Ctrl+H".action = focus-monitor-left;
      "Mod+Ctrl+L".action = focus-monitor-right;

      # ── Move windows (arrow keys — same as hyprland) ────────────
      "Mod+Shift+Left".action = move-column-left;
      "Mod+Shift+Right".action = move-column-right;
      "Mod+Shift+Up".action = move-window-up;
      "Mod+Shift+Down".action = move-window-down;

      # ── Move windows (vim keys — same as hyprland) ──────────────
      "Mod+Shift+H".action = move-column-left;
      "Mod+Shift+L".action = move-column-right;
      "Mod+Shift+K".action = move-window-up;
      "Mod+Shift+J".action = move-window-down;

      # ── Move column to other monitor (same combo as hyprland) ───
      "Mod+Shift+Ctrl+Left".action = move-column-to-monitor-left;
      "Mod+Shift+Ctrl+Right".action = move-column-to-monitor-right;
      "Mod+Shift+Ctrl+H".action = move-column-to-monitor-left;
      "Mod+Shift+Ctrl+L".action = move-column-to-monitor-right;

      # ── Move workspace between monitors ─────────────────────────
      "Mod+Shift+Ctrl+Up".action = move-workspace-to-monitor-left;
      "Mod+Shift+Ctrl+Down".action = move-workspace-to-monitor-right;

      # ── Workspace navigation ────────────────────────────────────
      "Mod+Page_Down".action = focus-workspace-down;
      "Mod+Page_Up".action = focus-workspace-up;
      "Mod+U".action = focus-workspace-down;
      "Mod+I".action = focus-workspace-up;

      # ── Move columns between workspaces ─────────────────────────
      "Mod+Ctrl+Page_Down".action = move-column-to-workspace-down;
      "Mod+Ctrl+Page_Up".action = move-column-to-workspace-up;
      "Mod+Ctrl+U".action = move-column-to-workspace-down;
      "Mod+Ctrl+I".action = move-column-to-workspace-up;

      # ── Numbered workspaces (same as hyprland Mod+1-0) ──────────
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

      # ── Move to numbered workspaces (same as hyprland Mod+Shift+1-0) ──
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

      # ── Column width / window height adjustments ────────────────
      "Mod+Minus".action = set-column-width "-10%";
      "Mod+Equal".action = set-column-width "+10%";
      "Mod+Shift+Minus".action = set-window-height "-10%";
      "Mod+Shift+Equal".action = set-window-height "+10%";

      # ── Overview (niri-native, no hyprland equivalent) ──────────
      "Mod+O".action = toggle-overview;

      # ── Screenshots ─────────────────────────────────────────────
      "Mod+Print".action.screenshot = [ ];
      "Mod+Shift+Print".action.screenshot-window = [ ];

      # ── Power menu (wlogout, same as hyprland custom/power) ─────
      "Mod+Shift+P".action = spawn "wlogout" "-p" "layer-shell";

      # ── Screen locking ──────────────────────────────────────────
      "Mod+Escape".action = spawn "swaylock";

      # ── Audio controls (allow-when-locked, same as hyprland) ────
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

      # ── Brightness controls (same as hyprland) ──────────────────
      "XF86MonBrightnessUp" = {
        action = spawn "brightnessctl" "s" "10%+";
        allow-when-locked = true;
      };
      "XF86MonBrightnessDown" = {
        action = spawn "brightnessctl" "s" "10%-";
        allow-when-locked = true;
      };

      # ── Media controls (same as hyprland) ───────────────────────
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

      # ── Notification dismissal (same as hyprland) ───────────────
      "Ctrl+Shift+Space".action = spawn "makoctl" "dismiss" "--all";
    };
  };
}
