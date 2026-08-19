{ ... }: {
  programs.kitty = {
    enable = true;
    package = null;
    settings = {
      background_opacity = 0.85;
      scrollback_lines = 10000;
    };
  };
}
