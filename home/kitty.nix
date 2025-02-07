{...}: {
  programs.kitty = {
    enable = true;
    settings = {
      background_opacity = 0.85;
      scrollback_lines = 10000;
    };
  };
}
