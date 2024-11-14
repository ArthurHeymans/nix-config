{pkgs, ...}: {
  programs.dconf.enable = true;

  # greetd with tuigreet
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd sway";
        user = "greeter";
      };
    };
  };

  environment.etc."greetd/environments".text = ''
    sway
    hyprland
    bash
  '';

  services.dbus.packages = [pkgs.gcr];
}
