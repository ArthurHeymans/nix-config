{pkgs, ...}: {
  programs.dconf.enable = true;

  # greetd with tuigreet
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  environment.etc."greetd/environments".text = ''
    niri
    sway
    Hyprland
    bash
  '';

  services.dbus.packages = [pkgs.gcr];

  programs.uwsm = {
    enable = true;
    waylandCompositors = {
      niri = {
        prettyName = "Niri (UWSM)";
        comment = "Niri compositor managed by UWSM";
        binPath = "/run/current-system/sw/bin/niri-session";
      };
    };
  };
  programs.hyprland.withUWSM = true;

  programs.hyprland.enable = true;
  programs.niri.enable = true;
}
