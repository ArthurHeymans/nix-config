{pkgs, ...}: {
  home.packages = with pkgs; [
    brave
    ferdium
  ];

  services.syncthing.enable = true;
}
