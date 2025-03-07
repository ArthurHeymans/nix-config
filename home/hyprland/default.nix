{pkgs, ...}: {
  imports = [
    ./hyprpaper.nix
    ./wlogout.nix
    ./hyprlock.nix
    ./hypridle.nix
  ];

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
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

    settings = {
      exec-once = [
        "waybar"
      ];
      exec = [
        "bash -c 'if grep -q closed /proc/acpi/button/lid/*/state; then hyprctl keyword monitor \"LVDS-1, disable\"; hyprctl keyword monitor \"eDP-1, disable\"; fi'"
      ];
      monitor = [
        ",preferred,auto,1"
      ];
      env = [
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
      ];
      # https://wiki.hyprland.org/Configuring/Variables/#general
      general = {
        gaps_in = 5;
        gaps_out = 10;

        border_size = 2;

        # https://wiki.hyprland.org/Configuring/Variables/#variable-types for info about colors
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";

        # Set to true enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false;

        # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
        allow_tearing = false;

        layout = "dwindle";
      };
      # https://wiki.hyprland.org/Configuring/Variables/#decoration
      decoration = {
        rounding = 10;

        # Change transparency of focused and unfocused windows
        active_opacity = 1.0;
        inactive_opacity = 1.0;

        # shadow {
        #     enabled = true
        #     range = 4
        #     render_power = 3
        #     color = rgba(1a1a1aee)
        # }

        # https://wiki.hyprland.org/Configuring/Variables/#blur
        blur = {
          enabled = true;
          size = 3;
          passes = 1;

          vibrancy = 0.1696;
        };
      };

      # https://wiki.hyprland.org/Configuring/Variables/#animations
      animations = {
        enabled = true;

        first_launch_animation = true;

        # Default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

        animation = [
          "global, 1, 10, default"
          "border, 1, 5, default"
          "windows, 1, 3, default, popin 80%"
          "fade, 1, 10, default"
          "workspaces, 1, 3, default, slide"
        ];
      };
      # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
      dwindle = {
        pseudotile = true; # Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
        preserve_split = true; # You probably want this
      };
      # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
      master = {
        new_status = "master";
      };
      # https://wiki.hyprland.org/Configuring/Variables/#misc
      misc = {
        force_default_wallpaper = "-1"; # Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo = false; # If true disables the random hyprland logo / anime girl background. :(
      };
      #############
      ### INPUT ###
      #############

      # https://wiki.hyprland.org/Configuring/Variables/#input
      input = {
        kb_layout = "us";
        #    kb_variant =
        #    kb_model =
        kb_options = "caps:ctrl_modifier";
        #kb_rules =

        follow_mouse = 1;

        sensitivity = 0; # -1.0 - 1.0, 0 means no modification.

        touchpad = {
          natural_scroll = false;
        };
      };

      # https://wiki.hyprland.org/Configuring/Variables/#gestures
      gestures = {
        workspace_swipe = false;
      };
      "$mod" = "SUPER";
      "$terminal" = "kitty";
      "$menu" = "rofi -show drun -show-icons";
      bind =
        [
          "$mod, Return, exec, $terminal"
          "$mod SHIFT, q, killactive"
          "$mod SHIFT, e, exit"
          "$mod, V, togglefloating"
          "$mod, d, exec, $menu"
          "$mod, P, pseudo" # dwindle
          "$mod, J, togglesplit" # dwindle
          "$mod, F, fullscreen, 0"

          # Move focus with mainMod + arrow keys
          "$mod, left, movefocus, l"
          "$mod, right, movefocus, r"
          "$mod, up, movefocus, u"
          "$mod, down, movefocus, d"

          # Move focus with mainMod + arrow keys
          "$mod SHIFT, left, movewindow, l"
          "$mod SHIFT, right, movewindow, r"
          "$mod SHIFT, up, movewindow, u"
          "$mod SHIFT, down, movewindow, d"

          # Notifications
          "CTRL SHIFT, Space, exec, makoctl dismiss --all"
        ]
        ++ (
          # workspaces
          # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
          builtins.concatLists (builtins.genList (
              i: let
                ws = i + 1;
              in [
                "$mod, code:1${toString i}, workspace, ${toString ws}"
                "$mod SHIFT, code:1${toString i}, movetoworkspacesilent, ${toString ws}"
              ]
            )
            9)
        )
        ++ [
          "$mod, code:19, workspace, 10"
          "$mod SHIFT, code:19, movetoworkspacesilent, 10"
        ];
      # 'm' Mouse
      bindm = [
        # Move/resize windows with mainMod + LMB/RMB and dragging
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # e -> repeat, will repeat when held.
      # l -> locked, will also work when an input inhibitor (e.g. a lockscreen) is active.
      bindel = [
        # Laptop multimedia keys for volume and LCD brightness
        ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ",XF86MonBrightnessUp, exec, brightnessctl s 10%+"
        ",XF86MonBrightnessDown, exec, brightnessctl s 10%-"
      ];

      bindl = [
        # Requires playerctl
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPause, exec, playerctl play-pause"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPrev, exec, playerctl previous"

        ",switch:on:Lid Switch, exec, hyprctl keyword monitor \"LVDS-1, disable\"; hyprctl keyword monitor \"eDP-1, disable\""
        ",switch:off:Lid Switch, exec, hyprctl keyword monitor \"LVDS-1, enable\"; hyprctl keyword monitor \"eDP-1, enable\""
      ];

      windowrulev2 = [
        # Ignore maximize requests from apps. You'll probably like this.
        "suppressevent maximize, class:.*"
        # Fix some dragging issues with XWayland
        "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
      ];

      # device specific settings
      device = [
        {
          name = "synps/2-synaptics-touchpad";
          enabled = "false";
        }
        {
          name = "ergo-k860-keyboard";
          kb_options = "ctrl:swap_lwin_lctl,caps:ctrl_modifier";
          numlock_by_default = "true";
        }
      ];
    };
  };
}
