{pkgs, ...}: {
  programs.dconf.enable = true;

  # greetd with tuigreet
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  environment.etc."greetd/environments".text = ''
    sway
    Hyprland
    bash
  '';

  services.dbus.packages = [pkgs.gcr];

  programs.hyprland.enable = true;
}
