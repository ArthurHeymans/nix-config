{...}: {
  programs.alacritty = {
    enable = true;
    settings = {
      env = {
        "TERM" = "xterm-256color";
      };

      window = {
        padding.x = 1;
        padding.y = 1;
        #decorations = "buttonless";
        dimensions = {
          columns = 80;
          lines = 24;
        };
        opacity = 0.95;
      };

      font = {
        size = 11.0;
        #        use_thin_strokes = true;

        normal.family = "FiraCode Nerd Font Mono";
        bold.family = "FiraCode Nerd Font Mono";
        italic.family = "FiraCode Nerd Font Mono";
      };

      # cursor.style = "Beam";

      # shell = {
      #   program = "fish";
      #   args = [
      #     "-C"
      #     "neofetch"
      #   ];
      # };

      colors = {
        draw_bold_text_with_bright_colors = true;

        # Default colors
        primary = {
          background = "0x000000";
          foreground = "0xb6b6b6";
        };

        # Normal colors
        normal = {
          black = "0x000000";
          blue = "0x0000b2";
          cyan = "0x00a6b2";
          green = "0x00a600";
          magenta = "0xb200b2";
          red = "0x990000";
          white = "0xbfbfbf";
          yellow = "0x999900";
        };

        # Bright colors
        bright = {
          black = "0x666666";
          blue = "0x0000ff";
          cyan = "0x00e5e5";
          green = "0x00d900";
          magenta = "0xe500e5";
          red = "0xe50000";
          white = "0xe5e5e5";
          yellow = "0xe5e500";
        };
      };
    };
  };
}
