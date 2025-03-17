{pkgs, ...}: {
  home.packages = with pkgs; [
    brave
    ferdium
    firefox
  ];

  services.syncthing.enable = true;
}
