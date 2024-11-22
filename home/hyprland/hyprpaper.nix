{...}: {
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      preload = ["~/Pictures/lsd3.jpg"];
      wallpaper = [",~/Pictures/lsd3.jpg"];
    };
  };
}
