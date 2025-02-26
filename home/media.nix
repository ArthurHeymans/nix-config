{pkgs, ...}: {
  home.packages = with pkgs; [
    vlc
    spotify
    mpv
    evince
    nautilus
    mullvad-vpn
  ];

  xdg.userDirs.enable = true;
  xdg.userDirs.createDirectories = true;
}
