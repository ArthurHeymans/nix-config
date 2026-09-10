{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hyprpaper.nix
    ./wlogout.nix
    ./hyprlock.nix
    ./hypridle.nix
    ./hyprsunset.nix
  ];

  home.packages = with pkgs; [
    hyprpolkitagent
    pkgs.awww
  ];

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
      };
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    configType = "lua";
    systemd.enable = false;

    # Every attribute below maps to an `hl.<name>(...)` call in
    # ~/.config/hypr/hyprland.lua. See `src/config/lua/bindings/` in the
    # Hyprland source for the exact API of Hyprland 0.56.
    settings =
      let
        grim = "${pkgs.grim}/bin/grim";
        slurp = "${pkgs.slurp}/bin/slurp";
        screenshotLocation = "~/Pictures/Screenshots/scrn-$(date +'%Y-%m-%d-%H-%M-%S.png')";

        lua = lib.generators.mkLuaInline;
        luaStr = lib.generators.toLua { };

        # "mod + <suffix>" as a Lua expression (mod is a Lua local, see below).
        modKey = suffix: lua ''mod .. " + ${suffix}"'';
        # Dispatcher that runs a shell command, with Lua string escaping.
        execDsp = cmd: ''hl.dsp.exec_cmd(${luaStr cmd})'';

        bind = key: dsp: {
          _args = [
            key
            (lua dsp)
          ];
        };
        bindOpts = key: dsp: opts: {
          _args = [
            key
            (lua dsp)
            opts
          ];
        };

        # Old `exec-once`: runs a single `hl.on("hyprland.start", ...)` hook.
        startupCommands = [
          "waybar"
          "awww-daemon"
          "wl-paste --type text --watch cliphist store"
          "wl-paste --type image --watch cliphist store"
          # "netbird-ui"
          "nm-applet"
          "kdeconnect-indicator"
        ];
      in
      {
        mod = {
          _var = "SUPER";
        };
        terminal = {
          _var = "kitty";
        };
        menu = {
          _var = "rofi -show drun -show-icons";
        };

        # `hl.config({...})`: nested tables map to dotted category keys.
        # https://wiki.hypr.land/Configuring/Basics/Variables/
        config = {
          # https://wiki.hypr.land/Configuring/Basics/Variables/#general
          general = {
            gaps_in = 5;
            gaps_out = 10;

            border_size = 2;

            # https://wiki.hypr.land/Configuring/Basics/Variables/#variable-types for info about colors
            col = {
              active_border = "rgba(33ccffee) rgba(00ff99ee) 45deg";
              inactive_border = "rgba(595959aa)";
            };

            # Set to true enable resizing windows by clicking and dragging on borders and gaps
            resize_on_border = false;

            # Please see https://wiki.hypr.land/Configuring/Tearing/ before you turn this on
            allow_tearing = false;

            layout = "dwindle";
          };
          # https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
          decoration = {
            rounding = 10;

            # Change transparency of focused and unfocused windows
            active_opacity = 1.0;
            inactive_opacity = 1.0;

            # https://wiki.hypr.land/Configuring/Basics/Variables/#blur
            blur = {
              enabled = true;
              size = 3;
              passes = 1;

              vibrancy = 0.1696;
            };
          };

          # https://wiki.hypr.land/Configuring/Animations/
          animations = {
            enabled = true;

            # first_launch_animation = true;
          };
          # See https://wiki.hypr.land/Configuring/Dwindle-Layout/ for more
          dwindle = {
            preserve_split = true; # You probably want this
          };
          # See https://wiki.hypr.land/Configuring/Master-Layout/ for more
          master = {
            new_status = "master";
          };
          # https://wiki.hypr.land/Configuring/Basics/Variables/#misc
          misc = {
            force_default_wallpaper = -1; # Set to 0 or 1 to disable the anime mascot wallpapers
            disable_hyprland_logo = false; # If true disables the random hyprland logo / anime girl background. :(
          };
          #############
          ### INPUT ###
          #############

          # https://wiki.hypr.land/Configuring/Basics/Variables/#input
          input = {
            kb_layout = "us";
            kb_options = "caps:ctrl_modifier";

            follow_mouse = 1;

            touchpad = {
              natural_scroll = false;
            };
          };
        };

        # https://wiki.hypr.land/Configuring/Basics/Monitors/
        monitor = [
          {
            output = "";
            mode = "preferred";
            position = "auto";
            scale = "1";
          }
          {
            output = "desc:Dell Inc. DELL U2312HM KF87Y31VC5AL";
            mode = "preferred";
            position = "1920x0";
            scale = "1";
            transform = 1;
          }
          {
            output = "desc:Dell Inc. DELL P3424WE 7DJF6T3";
            mode = "preferred";
            position = "3000x0";
            scale = "1";
          }
        ];

        env = [
          { _args = [ "XCURSOR_SIZE" "24" ]; }
          { _args = [ "HYPRCURSOR_SIZE" "24" ]; }
        ];

        # Old `exec`: runs on every config (re)load via top-level hl.exec_cmd.
        exec_cmd = [
          "bash -c 'if grep -q closed /proc/acpi/button/lid/*/state; then hyprctl keyword monitor \"LVDS-1, disable\"; hyprctl keyword monitor \"eDP-1, disable\"; fi'"
        ];

        on = {
          _args = [
            "hyprland.start"
            (lua ''
              function()
              ${lib.concatMapStringsSep "\n" (cmd: "  hl.exec_cmd(${luaStr cmd})") startupCommands}
              end'')
          ];
        };

        # Default animations, see https://wiki.hypr.land/Configuring/Animations/ for more.
        # Old format was "leaf, enabled, speed, bezier[, style]".
        animation = [
          {
            leaf = "global";
            enabled = true;
            speed = 10;
            bezier = "default";
          }
          {
            leaf = "border";
            enabled = true;
            speed = 5;
            bezier = "default";
          }
          {
            leaf = "windows";
            enabled = true;
            speed = 3;
            bezier = "default";
            style = "popin 80%";
          }
          {
            leaf = "fade";
            enabled = true;
            speed = 10;
            bezier = "default";
          }
          {
            leaf = "workspaces";
            enabled = true;
            speed = 3;
            bezier = "default";
            style = "slide";
          }
        ];

        bind =
          [
            (bind (modKey "Return") "hl.dsp.exec_cmd(terminal)")
            (bind (modKey "SHIFT + Q") "hl.dsp.window.kill()")
            (bind (modKey "SHIFT + E") "hl.dsp.exit()")
            (bind (modKey "V") ''hl.dsp.window.float({ action = "toggle" })'')
            (bind (modKey "D") "hl.dsp.exec_cmd(menu)")
            (bind (modKey "Y") (execDsp "cliphist list | rofi -dmenu | cliphist decode | wl-copy"))
            (bind (modKey "P") "hl.dsp.window.pseudo()") # dwindle
            (bind (modKey "J") ''hl.dsp.layout("togglesplit")'') # dwindle
            (bind (modKey "F") "hl.dsp.window.fullscreen()")

            # Move focus with mainMod + arrow keys
            (bind (modKey "left") ''hl.dsp.focus({ direction = "left" })'')
            (bind (modKey "right") ''hl.dsp.focus({ direction = "right" })'')
            (bind (modKey "up") ''hl.dsp.focus({ direction = "up" })'')
            (bind (modKey "down") ''hl.dsp.focus({ direction = "down" })'')

            # Move windows with mainMod + SHIFT + arrow keys
            (bind (modKey "SHIFT + left") ''hl.dsp.window.move({ direction = "left" })'')
            (bind (modKey "SHIFT + right") ''hl.dsp.window.move({ direction = "right" })'')
            (bind (modKey "SHIFT + up") ''hl.dsp.window.move({ direction = "up" })'')
            (bind (modKey "SHIFT + down") ''hl.dsp.window.move({ direction = "down" })'')

            # Move the focused workspace
            (bind (modKey "SHIFT + CTRL + left") ''hl.dsp.workspace.move({ monitor = "l" })'')
            (bind (modKey "SHIFT + CTRL + right") ''hl.dsp.workspace.move({ monitor = "r" })'')

            # Notifications
            (bind (lua ''"CTRL + SHIFT + Space"'') (execDsp "makoctl dismiss --all"))

            # Voxtype push-to-talk (hold to record, release to stop)
            (bind (modKey "semicolon") (execDsp "voxtype record start"))

            # Screenshots
            (bind (modKey "Print") (execDsp "${grim} ${screenshotLocation}"))
            (bind (modKey "SHIFT + Print") (execDsp "${slurp} | ${grim} -g - ${screenshotLocation}"))

            # Old `bindr`: release to stop voxtype recording.
            (bindOpts (modKey "semicolon") (execDsp "voxtype record stop") { release = true; })

            # Old `bindm`: mouse drag to move/resize windows.
            (bind (modKey "mouse:272") "hl.dsp.window.drag()")
            (bind (modKey "mouse:273") "hl.dsp.window.resize()")

            # Old `bindel`: repeat while held + works on lockscreen.
            (bindOpts "XF86AudioRaiseVolume"
              (execDsp "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+")
              {
                repeating = true;
                locked = true;
              })
            (bindOpts "XF86AudioLowerVolume"
              (execDsp "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")
              {
                repeating = true;
                locked = true;
              })
            (bindOpts "XF86AudioMute"
              (execDsp "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
              {
                repeating = true;
                locked = true;
              })
            (bindOpts "XF86AudioMicMute"
              (execDsp "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")
              {
                repeating = true;
                locked = true;
              })
            (bindOpts "XF86MonBrightnessUp"
              (execDsp "brightnessctl s 10%+")
              {
                repeating = true;
                locked = true;
              })
            (bindOpts "XF86MonBrightnessDown"
              (execDsp "brightnessctl s 10%-")
              {
                repeating = true;
                locked = true;
              })

            # Old `bindl`: works on lockscreen. Requires playerctl.
            (bindOpts "XF86AudioNext" (execDsp "playerctl next") { locked = true; })
            (bindOpts "XF86AudioPause" (execDsp "playerctl play-pause") { locked = true; })
            (bindOpts "XF86AudioPlay" (execDsp "playerctl play-pause") { locked = true; })
            (bindOpts "XF86AudioPrev" (execDsp "playerctl previous") { locked = true; })

            (bindOpts "switch:on:Lid Switch"
              (execDsp ''hyprctl keyword monitor "LVDS-1, disable"; hyprctl keyword monitor "eDP-1, disable"'')
              { locked = true; })
            (bindOpts "switch:off:Lid Switch"
              (execDsp ''hyprctl keyword monitor "LVDS-1, enable"; hyprctl keyword monitor "eDP-1, enable"'')
              { locked = true; })
          ]
          ++ (
            # workspaces
            # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
            builtins.concatLists (
              builtins.genList (
                i:
                let
                  ws = i + 1;
                in
                [
                  (bind (modKey "code:1${toString i}")
                    ''hl.dsp.focus({ workspace = "${toString ws}" })'')
                  (bind (modKey "SHIFT + code:1${toString i}")
                    ''hl.dsp.window.move({ workspace = "${toString ws}", follow = false })'')
                ]
              ) 9
            )
          )
          ++ [
            (bind (modKey "code:19") ''hl.dsp.focus({ workspace = "10" })'')
            (bind (modKey "SHIFT + code:19")
              ''hl.dsp.window.move({ workspace = "10", follow = false })'')
          ];

        window_rule = [
          # Ignore maximize requests from apps. You'll probably like this.
          {
            suppress_event = "maximize";
            match.class = ".*";
          }
          # Fix some dragging issues with XWayland
          {
            no_focus = true;
            match = {
              class = "^$";
              title = "^$";
              xwayland = 1;
              float = 1;
              fullscreen = 0;
              pin = 0;
            };
          }
          # Make other-frame work
          {
            workspace = "unset";
            focus_on_activate = true;
            match.class = "^(emacs)$";
          }
        ];

        # device specific settings
        device = [
          {
            name = "synps/2-synaptics-touchpad";
            enabled = false;
          }
          {
            name = "ergo-k860-keyboard";
            kb_options = "ctrl:swap_lwin_lctl,caps:ctrl_modifier";
            numlock_by_default = true;
          }
          {
            name = "tpps/2-ibm-trackpoint";
            sensitivity = config.my.pointer.accel; # -1.0 - 1.0, 0 means no modification.
          }
        ];
      };
  };
}
