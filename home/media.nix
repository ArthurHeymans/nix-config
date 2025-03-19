{pkgs, ...}: {
  home.packages = with pkgs; [
    vlc
    spotify
    mpv
    evince
    nautilus
    mullvad-vpn
    signal-desktop
    calibre
  ];

  xdg.userDirs.enable = true;
  xdg.userDirs.createDirectories = true;
}
