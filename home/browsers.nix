{pkgs, ...}: {
  home.packages = with pkgs; [
    brave
    ferdium
    firefox
    transmission_4-gtk
    nyxt
  ];

  services.syncthing.enable = true;
}
