{...}: {
  programs.hyprlock = {
    enable = true;
    settings = {
      input-field = {
        monitor = "";
        fade_on_empty = false;

        placeholder_text = "You shall not pass!";
        position = "0, -300%";
      };
      background = {
        path = " ~/Pictures/lock.jpg";
      };
    };
  };
}
