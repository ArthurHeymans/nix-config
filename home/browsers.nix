{pkgs, ...}: {
  home.packages = with pkgs; [
    brave
    ferdium
    firefox
    transmission_4-gtk
  ];

  services.syncthing.enable = true;
}
